# Reusable functionality across different schemas
"""
    render(schema::NoSchema,
        messages::Vector{<:AbstractMessage};
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        replacement_kwargs...)

Renders a conversation history from a vector of messages with all replacement variables specified in `replacement_kwargs`.

It is the first pass of the prompt rendering system, and is used by all other schemas.

# Keyword Arguments
- `image_detail`: Only for `UserMessageWithImages`. It represents the level of detail to include for images. Can be `"auto"`, `"high"`, or `"low"`.
- `conversation`: An optional vector of `AbstractMessage` objects representing the conversation history. If not provided, it is initialized as an empty vector.

# Notes
- All unspecified kwargs are passed as replacements such that `{{key}}=>value` in the template.
- If a SystemMessage is missing, we inject a default one at the beginning of the conversation.
- Only one SystemMessage is allowed (ie, cannot mix two conversations different system prompts).
"""
function render(schema::NoSchema,
        messages::Vector{<:AbstractMessage};
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        replacement_kwargs...)
    ## copy the conversation to avoid mutating the original
    conversation = copy(conversation)
    count_system_msg = count(issystemmessage, conversation)
    # TODO: concat multiple system messages together (2nd pass)

    # replace any handlebar variables in the messages
    for msg in messages
        if msg isa Union{SystemMessage, UserMessage, UserMessageWithImages}
            replacements = ["{{$(key)}}" => value
                            for (key, value) in pairs(replacement_kwargs)
                                if key in msg.variables]
            # Rebuild the message with the replaced content
            MSGTYPE = typeof(msg)
            new_msg = MSGTYPE(;
                # unpack the type to replace only the content field
                [(field, getfield(msg, field)) for field in fieldnames(typeof(msg))]...,
                content = replace(msg.content, replacements...))
            if msg isa SystemMessage
                count_system_msg += 1
                # move to the front
                pushfirst!(conversation, new_msg)
            else
                push!(conversation, new_msg)
            end
        elseif msg isa AIMessage
            # no replacements
            push!(conversation, msg)
        else
            # Note: Ignores any DataMessage or other types for the prompt/conversation history
            @warn "Unexpected message type: $(typeof(msg)). Skipping."
        end
    end
    ## Multiple system prompts are not allowed
    (count_system_msg > 1) && throw(ArgumentError("Only one system message is allowed."))
    ## Add default system prompt if not provided
    (count_system_msg == 0) && pushfirst!(conversation,
        SystemMessage("Act as a helpful AI assistant"))

    return conversation
end

"""
    finalize_outputs(prompt::ALLOWED_PROMPT_TYPE, conv_rendered::Any,
        msg::Union{Nothing, AbstractMessage};
        return_all::Bool = false,
        dry_run::Bool = false,
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        kwargs...)

Finalizes the outputs of the ai* functions by either returning the conversation history or the last message.

# Keyword arguments
- `return_all::Bool=false`: If true, returns the entire conversation history, otherwise returns only the last message (the `AIMessage`).
- `dry_run::Bool=false`: If true, does not send the messages to the model, but only renders the prompt with the given schema and replacement variables.
  Useful for debugging when you want to check the specific schema rendering. 
- `conversation::AbstractVector{<:AbstractMessage}=[]`: An optional vector of `AbstractMessage` objects representing the conversation history. If not provided, it is initialized as an empty vector.
- `kwargs...`: Variables to replace in the prompt template.
"""
function finalize_outputs(prompt::ALLOWED_PROMPT_TYPE, conv_rendered::Any,
        msg::Union{Nothing, AbstractMessage};
        return_all::Bool = false,
        dry_run::Bool = false,
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        kwargs...)
    if return_all
        if !dry_run
            # If not a dry_run, re-create the messages sent to the model before schema application
            # This is a duplication of work, as we already have the rendered messages in conv_rendered,
            # but we prioritize the user's experience over performance here (ie, render(OpenAISchema,msgs) does everything under the hood)
            output = render(NoSchema(), prompt; conversation, kwargs...)
            push!(output, msg)
        else
            output = conv_rendered
        end
        return output
    else
        return msg
    end
end

## Helpers for aiclassify -> they encode the choice list to create the prompt and then extract the original choice category
function encode_choices(schema::AbstractPromptSchema,
        choices;
        kwargs...)
    throw(ArgumentError("Function `encode_choices` is not implemented for the provided schema ($schema) and $(choices)."))
end
function decode_choices(schema::AbstractPromptSchema, choices, conv)
    throw(ArgumentError("Function `decode_choices` is not implemented for the provided schema ($schema) and $(choices)."))
end
