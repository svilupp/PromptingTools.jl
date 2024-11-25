# Conversation Memory Implementation
import PromptingTools: AbstractMessage, SystemMessage, AIMessage, UserMessage
import PromptingTools: issystemmessage, isusermessage, isaimessage
import PromptingTools: aigenerate, last_message, last_output

"""
    ConversationMemory

A structured container for managing conversation history with intelligent truncation
and caching capabilities.

The memory supports batched retrieval with deterministic truncation points for optimal
caching behavior.
"""
Base.@kwdef mutable struct ConversationMemory
    conversation::Vector{AbstractMessage} = AbstractMessage[]
end

# Basic interface extensions
import Base: show, push!, append!, length

"""
    show(io::IO, mem::ConversationMemory)

Display the number of non-system messages in the conversation memory.
"""
function Base.show(io::IO, mem::ConversationMemory)
    n_msgs = count(!issystemmessage, mem.conversation)
    print(io, "ConversationMemory($(n_msgs) messages)")
end

"""
    length(mem::ConversationMemory)

Return the number of messages, excluding system messages.
"""
function Base.length(mem::ConversationMemory)
    count(!issystemmessage, mem.conversation)
end

"""
    last_message(mem::ConversationMemory)

Get the last message in the conversation, delegating to PromptingTools.last_message.
"""
function last_message(mem::ConversationMemory)
    PromptingTools.last_message(mem.conversation)
end

"""
    last_output(mem::ConversationMemory)

Get the last AI message in the conversation, delegating to PromptingTools.last_output.
"""
function last_output(mem::ConversationMemory)
    PromptingTools.last_output(mem.conversation)
end

"""
    get_last(mem::ConversationMemory, n::Integer=20;
             batch_size::Union{Nothing,Integer}=nothing,
             verbose::Bool=false,
             explain::Bool=false)

Get the last n messages with intelligent batching and caching support.

Arguments:
- n::Integer: Maximum number of messages to return (default: 20)
- batch_size::Union{Nothing,Integer}: If provided, ensures messages are truncated in fixed batches
- verbose::Bool: Print detailed information about truncation
- explain::Bool: Add explanation about truncation in the response

Returns:
Vector{AbstractMessage} with the selected messages, always including:
1. The system message (if present)
2. First user message
3. Messages up to n, respecting batch_size boundaries
"""
function get_last(mem::ConversationMemory, n::Integer=20;
                 batch_size::Union{Nothing,Integer}=nothing,
                 verbose::Bool=false,
                 explain::Bool=false)
    messages = mem.conversation
    isempty(messages) && return AbstractMessage[]

    # Always include system message and first user message
    system_idx = findfirst(issystemmessage, messages)
    first_user_idx = findfirst(isusermessage, messages)

    # Initialize result with required messages
    result = AbstractMessage[]
    if !isnothing(system_idx)
        push!(result, messages[system_idx])
    end
    if !isnothing(first_user_idx)
        push!(result, messages[first_user_idx])
    end

    # Get remaining messages excluding system and first user
    exclude_indices = filter(!isnothing, [system_idx, first_user_idx])
    remaining_msgs = messages[setdiff(1:length(messages), exclude_indices)]

    # Calculate how many messages to include based on batch size
    if !isnothing(batch_size)
        # When batch_size=10, should return between 11-20 messages
        total_msgs = length(remaining_msgs)
        num_batches = ceil(Int, total_msgs / batch_size)

        # Calculate target size (between batch_size+1 and 2*batch_size)
        target_size = if num_batches * batch_size > n
            batch_size + 1  # Reset to minimum (11 for batch_size=10)
        else
            min(num_batches * batch_size, n - length(result))
        end

        # Get messages to append
        if !isempty(remaining_msgs)
            start_idx = max(1, length(remaining_msgs) - target_size + 1)
            append!(result, remaining_msgs[start_idx:end])
        end
    else
        # Without batch size, just get the last n-length(result) messages
        if !isempty(remaining_msgs)
            start_idx = max(1, length(remaining_msgs) - (n - length(result)) + 1)
            append!(result, remaining_msgs[start_idx:end])
        end
    end

    if verbose
        println("Total messages: ", length(messages))
        println("Keeping: ", length(result))
        println("Required messages: ", count(m -> issystemmessage(m) || m === messages[first_user_idx], result))
        if !isnothing(batch_size)
            println("Using batch size: ", batch_size)
        end
    end

    # Add explanation if requested and we truncated messages
    if explain && length(messages) > length(result)
        # Find first AI message in result after required messages
        ai_msg_idx = findfirst(m -> isaimessage(m) && !(m in result[1:length(exclude_indices)]), result)
        if !isnothing(ai_msg_idx)
            orig_content = result[ai_msg_idx].content
            explanation = "For efficiency reasons, we have truncated the preceding $(length(messages) - length(result)) messages.\n\n$orig_content"
            result[ai_msg_idx] = AIMessage(explanation)
        end
    end

    return result
end

"""
    append!(mem::ConversationMemory, msgs::Vector{<:AbstractMessage})

Smart append that handles duplicate messages based on run IDs.
Only appends messages that are newer than the latest matching message in memory.
"""
function Base.append!(mem::ConversationMemory, msgs::Vector{<:AbstractMessage})
    isempty(msgs) && return mem

    if isempty(mem.conversation)
        append!(mem.conversation, msgs)
        return mem
    end

    # Find latest run_id in memory
    latest_run_id = 0
    for msg in mem.conversation
        if isdefined(msg, :run_id)
            latest_run_id = max(latest_run_id, msg.run_id)
        end
    end

    # Keep messages that either don't have a run_id or have a higher run_id
    new_msgs = filter(msgs) do msg
        !isdefined(msg, :run_id) || msg.run_id > latest_run_id
    end

    append!(mem.conversation, new_msgs)
    return mem
end

"""
    push!(mem::ConversationMemory, msg::AbstractMessage)

Add a single message to the conversation memory.
"""
function Base.push!(mem::ConversationMemory, msg::AbstractMessage)
    push!(mem.conversation, msg)
    return mem
end

"""
    (mem::ConversationMemory)(prompt::String; last::Union{Nothing,Integer}=nothing, kwargs...)

Functor interface for direct generation using the conversation memory.
"""
function (mem::ConversationMemory)(prompt::String; last::Union{Nothing,Integer}=nothing, kwargs...)
    # Get conversation context
    context = if isnothing(last)
        mem.conversation
    else
        get_last(mem, last)
    end

    # Add user message to memory first
    user_msg = UserMessage(prompt)
    push!(mem.conversation, user_msg)

    # Generate response with context
    response = aigenerate(context, prompt; kwargs...)
    push!(mem.conversation, response)
    return response
end

"""
    aigenerate(mem::ConversationMemory, prompt::String; kwargs...)

Generate a response using the conversation memory context.
"""
function PromptingTools.aigenerate(messages::Vector{<:AbstractMessage}, prompt::String; kwargs...)
    schema = get(kwargs, :schema, OpenAISchema())
    aigenerate(schema, [messages..., UserMessage(prompt)]; kwargs...)
end
