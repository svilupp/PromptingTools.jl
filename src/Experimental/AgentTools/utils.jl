"Removes the kwargs that have already been used in the conversation. Returns NamedTuple."
function remove_used_kwargs(kwargs::NamedTuple,
        conversation::AbstractVector{<:PT.AbstractMessage})
    used_kwargs = Set{Symbol}()
    for message in conversation
        if hasproperty(message, :variables)
            union!(used_kwargs, message.variables)
        end
    end
    return filter(pair -> !(pair.first in used_kwargs), pairs(kwargs)) |> NamedTuple
end

"""
    truncate_conversation(conversation::AbstractVector{<:PT.AbstractMessage};
        max_conversation_length::Int = 32000)

Truncates a given conversation to a `max_conversation_length` characters by removing messages "in the middle".
It tries to retain the original system+user message and also the most recent messages.

Practically, if a conversation is too long, it will start by removing the most recent message EXCEPT for the last two (assumed to be the last AIMessage with the code and UserMessage with the feedback

# Arguments
`max_conversation_length` is in characters; assume c. 2-3 characters per LLM token, so 32000 should correspond to 16K context window.
"""
function truncate_conversation(conversation::AbstractVector{<:PT.AbstractMessage};
        max_conversation_length::Int = 32000)
    @assert max_conversation_length>0 "max_conversation_length must be positive (provided: $max_conversation_length)"
    total_length = sum(length.(getproperty.(conversation, :content)); init = 0)
    # Truncate the conversation to the max length
    new_conversation = if total_length > max_conversation_length &&
                          length(conversation) > 2
        # start with the last two messages' length (always included)
        new_conversation = similar(conversation) |> empty!
        current_length = sum(length.(getproperty.(conversation[(end - 1):end],
                :content)); init = 0)
        for i in eachindex(conversation[begin:(end - 2)])
            length_ = length(conversation[i].content)
            if current_length + length_ <= max_conversation_length
                push!(new_conversation, conversation[i])
                current_length += length_
            end
        end
        # add the last two messages
        append!(new_conversation, conversation[(end - 1):end])
        new_conversation
    else
        conversation
    end
    return new_conversation
end
