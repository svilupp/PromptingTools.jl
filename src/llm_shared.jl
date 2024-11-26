# Reusable functionality across different schemas
function role4render(schema::AbstractPromptSchema, msg::AbstractMessage)
    throw(ArgumentError("Function `role4render` is not implemented for the provided schema ($(typeof(schema))) and $(typeof(msg))."))
end
role4render(schema::AbstractPromptSchema, msg::SystemMessage) = "system"
role4render(schema::AbstractPromptSchema, msg::UserMessage) = "user"
role4render(schema::AbstractPromptSchema, msg::UserMessageWithImages) = "user"
role4render(schema::AbstractPromptSchema, msg::AIMessage) = "assistant"
role4render(schema::AbstractPromptSchema, msg::AIToolRequest) = "assistant"
role4render(schema::AbstractPromptSchema, msg::ToolMessage) = "tool"
role4render(schema::AbstractPromptSchema, msg::AbstractAnnotationMessage) = "annotation"
"""
    render(schema::NoSchema,
        messages::Vector{<:AbstractMessage};
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        no_system_message::Bool = false,
        replacement_kwargs...)

Renders a conversation history from a vector of messages with all replacement variables specified in `replacement_kwargs`.

It is the first pass of the prompt rendering system, and is used by all other schemas.

# Keyword Arguments
- `image_detail`: Only for `UserMessageWithImages`. It represents the level of detail to include for images. Can be `"auto"`, `"high"`, or `"low"`.
- `conversation`: An optional vector of `AbstractMessage` objects representing the conversation history. If not provided, it is initialized as an empty vector.
- `no_system_message`: If `true`, do not include the default system message in the conversation history OR convert any provided system message to a user message.

# Notes
- All unspecified kwargs are passed as replacements such that `{{key}}=>value` in the template.
- If a SystemMessage is missing, we inject a default one at the beginning of the conversation.
- Only one SystemMessage is allowed (ie, cannot mix two conversations different system prompts).
"""
function render(schema::NoSchema,
        messages::Vector{<:AbstractMessage};
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        no_system_message::Bool = false,
        replacement_kwargs...)
    ## copy the conversation to avoid mutating the original
    conversation = copy(conversation)
    count_system_msg = count(issystemmessage, conversation)
    # TODO: concat multiple system messages together (2nd pass)

    # Filter out annotation messages from input messages
    messages = filter(!isabstractannotationmessage, messages)

    # replace any handlebar variables in the messages
    for msg in messages
        if issystemmessage(msg) || isusermessage(msg) || isusermessagewithimages(msg)
            replacements = ["{{$(key)}}" => value
                            for (key, value) in pairs(replacement_kwargs)
                            if key in msg.variables]
            ## Force System message to UserMessage if no_system_message=true
            ## TODO: fix to support TracerMessage -- it would temporarily drop the tracing
            MSGTYPE = no_system_message && issystemmessage(msg) ? UserMessage : typeof(msg)
            # Rebuild the message with the replaced content
            new_msg = if istracermessage(msg)
                ## No updating if it's already traced (=past message)
                msg
            else
                MSGTYPE(;
                    # unpack the type to replace only the content field
                    [(field, getfield(msg, field)) for field in fieldnames(typeof(msg))]...,
                    content = replace(msg.content, replacements...))
            end
            if issystemmessage(msg)
                count_system_msg += 1
                # move to the front
                pushfirst!(conversation, new_msg)
            else
                push!(conversation, new_msg)
            end
        elseif isaimessage(msg) || isaitoolrequest(msg) || istoolmessage(msg)
            # no replacements
            push!(conversation, msg)
        elseif istracermessage(msg) && issystemmessage(msg.object)
            # Look for tracers
            count_system_msg += 1
            # move to the front
            pushfirst!(conversation, msg)
        elseif isabstractannotationmessage(msg)
            # Ignore annotation messages
            continue
        else
            # Note: Ignores any DataMessage or other types for the prompt/conversation history
            @warn "Unexpected message type: $(typeof(msg)). Skipping."
        end
    end
    ## Multiple system prompts are not allowed
    (count_system_msg > 1) && throw(ArgumentError("Only one system message is allowed."))
    ## Add default system prompt if not provided
    if (count_system_msg == 0) && !no_system_message
        pushfirst!(conversation,
            SystemMessage("Act as a helpful AI assistant"))
    end

    return conversation
end

function render(schema::AbstractPromptSchema,
        tools::AbstractVector{<:AbstractTool};
        kwargs...)
    throw(ArgumentError("Function `render` is not implemented for the provided schema ($(typeof(schema))) and $(typeof(tools))."))
end
function render(schema::AbstractPromptSchema,
        tools::AbstractDict{String, <:AbstractTool};
        kwargs...)
    render(schema, collect(values(tools)); kwargs...)
end
# For ToolRef
function render(schema::AbstractPromptSchema,
        tool::AbstractTool;
        kwargs...)
    throw(ArgumentError("Function `render` is not implemented for the provided schema ($(typeof(schema))) and $(typeof(tool))."))
end

"""
    finalize_outputs(prompt::ALLOWED_PROMPT_TYPE, conv_rendered::Any,
        msg::Union{Nothing, AbstractMessage, AbstractVector{<:AbstractMessage}};
        return_all::Bool = false,
        dry_run::Bool = false,
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        no_system_message::Bool = false,
        kwargs...)

Finalizes the outputs of the ai* functions by either returning the conversation history or the last message.

# Keyword arguments
- `return_all::Bool=false`: If true, returns the entire conversation history, otherwise returns only the last message (the `AIMessage`).
- `dry_run::Bool=false`: If true, does not send the messages to the model, but only renders the prompt with the given schema and replacement variables.
  Useful for debugging when you want to check the specific schema rendering. 
- `conversation::AbstractVector{<:AbstractMessage}=[]`: An optional vector of `AbstractMessage` objects representing the conversation history. If not provided, it is initialized as an empty vector.
- `kwargs...`: Variables to replace in the prompt template.
- `no_system_message::Bool=false`: If true, the default system message is not included in the conversation history. Any existing system message is converted to a `UserMessage`.
"""
function finalize_outputs(prompt::ALLOWED_PROMPT_TYPE, conv_rendered::Any,
        msg::Union{Nothing, AbstractMessage, AbstractVector{<:AbstractMessage}};
        return_all::Bool = false,
        dry_run::Bool = false,
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        no_system_message::Bool = false,
        kwargs...)
    if return_all
        if !dry_run
            # If not a dry_run, re-create the messages sent to the model before schema application
            # This is a duplication of work, as we already have the rendered messages in conv_rendered,
            # but we prioritize the user's experience over performance here (ie, render(OpenAISchema,msgs) does everything under the hood)
            output = render(NoSchema(), prompt; conversation, no_system_message, kwargs...)
            if msg isa AbstractVector
                ## handle multiple messages (multi-sample)
                append!(output, msg)
            else
                push!(output, msg)
            end
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
function decode_choices(schema::AbstractPromptSchema, choices, conv; kwargs...)
    throw(ArgumentError("Function `decode_choices` is not implemented for the provided schema ($schema) and $(choices)."))
end
function decode_choices(schema::AbstractPromptSchema, choices, conv::Nothing; kwargs...)
    nothing
end
