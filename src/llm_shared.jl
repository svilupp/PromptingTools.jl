# Reusable functionality across different schemas
"""
    render(schema::NoSchema,
        messages::Vector{<:AbstractMessage};
        replacement_kwargs...)

Renders a conversation history from a vector of messages with all replacement variables specified in `replacement_kwargs`.

It is the first pass of the prompt rendering system, and is used by all other schemas.

# Notes
- All unspecified kwargs are passed as replacements such that `{{key}}=>value` in the template.
- If a SystemMessage is missing, we inject a default one at the beginning of the conversation.
"""
function render(schema::NoSchema,
        messages::Vector{<:AbstractMessage};
        replacement_kwargs...)
    ##
    conversation = AbstractMessage[]
    has_system_msg = false
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
                has_system_msg = true
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
    ## Add default system prompt if not provided
    !has_system_msg && pushfirst!(conversation,
        SystemMessage("Act as a helpful AI assistant"))

    return conversation
end

"""
    finalize_outputs(prompt::ALLOWED_PROMPT_TYPE, conversation::AbstractVector,
        msg::AbstractMessage;
        return_all::Bool = false,
        dry_run::Bool = false,
        kwargs...)

Finalizes the outputs of the ai* functions by either returning the conversation history or the last message.

# Keyword arguments
- `return_all::Bool=false`: If true, returns the entire conversation history, otherwise returns only the last message (the `AIMessage`).
- `dry_run::Bool=false`: If true, does not send the messages to the model, but only renders the prompt with the given schema and replacement variables.
  Useful for debugging when you want to check the specific schema rendering. 
- `kwargs...`: Variables to replace in the prompt template.
"""
function finalize_outputs(prompt::ALLOWED_PROMPT_TYPE, conversation::AbstractVector,
        msg::AbstractMessage;
        return_all::Bool = false,
        dry_run::Bool = false,
        kwargs...)
    if return_all
        if !dry_run
            # If not a dry_run, re-create the messages sent to the model before schema application
            conversation = render(NoSchema(), prompt; kwargs...)
            push!(conversation, msg)
        end
        return conversation
    else
        return msg
    end
end