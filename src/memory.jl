"""
    ConversationMemory

A structured container for managing conversation history. It has only one field `:conversation`
which is a vector of `AbstractMessage`s. It's built to support intelligent truncation and caching
behavior (`get_last`).

You can also use it as a functor to have extended conversations (easier than constantly passing `conversation` kwarg)

# Examples

Basic usage
```julia
mem = ConversationMemory()
push!(mem, SystemMessage("You are a helpful assistant"))
push!(mem, UserMessage("Hello!"))
push!(mem, AIMessage("Hi there!"))

# or simply
mem = ConversationMemory(conv)
```

Check memory stats
```julia
println(mem)  # ConversationMemory(2 messages) - doesn't count system message
@show length(mem)  # 3 - counts all messages
@show last_message(mem)  # gets last message
@show last_output(mem)   # gets last content
```

Get recent messages with different options (System message, User message, ... + the most recent)
```julia
recent = get_last(mem, 5)  # get last 5 messages (including system)
recent = get_last(mem, 20, batch_size=10)  # align to batches of 10 for caching
recent = get_last(mem, 5, explain=true)    # adds truncation explanation
recent = get_last(mem, 5, verbose=true)    # prints truncation info
```

Append multiple messages at once (with deduplication to keep the memory complete)
```julia
msgs = [
    UserMessage("How are you?"),
    AIMessage("I'm good!"; run_id=1),
    UserMessage("Great!"),
    AIMessage("Indeed!"; run_id=2)
]
append!(mem, msgs)  # Will only append new messages based on run_ids etc.
```

Use for AI conversations (easier to manage conversations)
```julia
response = mem("Tell me a joke"; model="gpt4o")  # Automatically manages context
response = mem("Another one"; last=3, model="gpt4o")  # Use only last 3 messages (uses `get_last`)

# Direct generation from the memory
result = aigenerate(mem)  # Generate using full context
```
"""
Base.@kwdef mutable struct ConversationMemory
    conversation::Vector{AbstractMessage} = AbstractMessage[]
end

"""
    show(io::IO, mem::ConversationMemory)

Display the number of non-system/non-annotation messages in the conversation memory.
"""
function Base.show(io::IO, mem::ConversationMemory)
    n_msgs = count(
        x -> !issystemmessage(x) && !isabstractannotationmessage(x), mem.conversation)
    print(io, "ConversationMemory($(n_msgs) messages)")
end

"""
    length(mem::ConversationMemory)

Return the number of messages. All of them.
"""
function Base.length(mem::ConversationMemory)
    length(mem.conversation)
end

"""
    last_message(mem::ConversationMemory)

Get the last message in the conversation.
"""
function last_message(mem::ConversationMemory)
    last_message(mem.conversation)
end

"""
    last_output(mem::ConversationMemory)

Get the last AI message in the conversation.
"""
function last_output(mem::ConversationMemory)
    last_output(mem.conversation)
end

function pprint(
        io::IO, mem::ConversationMemory;
        text_width::Int = displaysize(io)[2])
    pprint(io, mem.conversation; text_width)
end

"""
    get_last(mem::ConversationMemory, n::Integer=20;
             batch_size::Union{Nothing,Integer}=nothing,
             verbose::Bool=false,
             explain::Bool=false)

Get the last n messages (but including system message) with intelligent batching to preserve caching.

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

Once you get your full conversation back, you can use `append!(mem, conversation)` to merge the new messages into the memory.

# Examples:
```julia
# Basic usage - get last 3 messages
mem = ConversationMemory()
push!(mem, SystemMessage("You are helpful"))
push!(mem, UserMessage("Hello"))
push!(mem, AIMessage("Hi!"))
push!(mem, UserMessage("How are you?"))
push!(mem, AIMessage("I'm good!"))
messages = get_last(mem, 3)

# Using batch_size for caching efficiency
messages = get_last(mem, 10; batch_size=5)  # Aligns to 5-message batches for caching

# Add explanation about truncation
messages = get_last(mem, 3; explain=true)  # Adds truncation note to first AI message so the model knows it's truncated

# Get verbose output about truncation
messages = get_last(mem, 3; verbose=true)  # Prints info about truncation
```
"""
function get_last(mem::ConversationMemory, n::Integer = 20;
        batch_size::Union{Nothing, Integer} = nothing,
        verbose::Bool = false,
        explain::Bool = false)
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

    # Calculate remaining message budget
    remaining_budget = n - length(result)
    visible_messages = findall(
        x -> !issystemmessage(x) && !isabstractannotationmessage(x), messages)

    if remaining_budget > 0
        default_start_idx = max(1, length(visible_messages) - remaining_budget + 1)
        start_idx = !isnothing(batch_size) ?
                    batch_start_index(
            length(visible_messages), remaining_budget, batch_size) : default_start_idx
        ## find first AIMessage after that (it must be aligned to follow after UserMessage)
        valid_idxs = @view(visible_messages[start_idx:end])
        ai_msg_idx = findfirst(isaimessage, @view(messages[valid_idxs]))
        !isnothing(ai_msg_idx) &&
            append!(result, messages[@view(valid_idxs[ai_msg_idx:end])])
    end

    verbose &&
        @info "ConversationMemory truncated to $(length(result))/$(length(messages)) messages"

    # Add explanation if requested and we truncated messages
    if explain && (length(visible_messages) + 1) > length(result)
        # Find first AI message in result after required messages
        ai_msg_idx = findfirst(x -> isaimessage(x) || isaitoolrequest(x), result)
        trunc_count = length(visible_messages) + 1 - length(result)
        if !isnothing(ai_msg_idx)
            ai_msg = result[ai_msg_idx]
            orig_content = ai_msg.content
            explanation = "[This is an automatically added explanation to inform you that for efficiency reasons, the user has truncated the preceding $(trunc_count) messages.]\n\n$orig_content"
            ai_msg_type = typeof(ai_msg)
            result[ai_msg_idx] = ai_msg_type(;
                [f => getfield(ai_msg, f)
                 for f in fieldnames(ai_msg_type) if f != :content]...,
                content = explanation)
        end
    end

    return result
end

"""
    batch_start_index(array_length::Integer, n::Integer, batch_size::Integer) -> Integer

Compute the starting index for retrieving the most recent data, adjusting in blocks of `batch_size`.
The function accumulates messages until hitting a batch boundary, then jumps to the next batch.

For example, with n=20 and batch_size=10:
- At length 90-99: returns 80 (allowing accumulation of 11-20 messages)
- At length 100-109: returns 90 (allowing accumulation of 11-20 messages)
- At length 110: returns 100 (resetting to 11 messages)
"""
function batch_start_index(array_length::Integer, n::Integer, batch_size::Integer)::Integer
    @assert n>=batch_size "n must be >= batch_size"
    # Calculate which batch we're in
    batch_number = (array_length - (n - batch_size)) ÷ batch_size
    # Calculate the start of the current batch
    batch_start = batch_number * batch_size

    # Ensure we don't go before the first element
    return max(1, batch_start)
end

"""
    append!(mem::ConversationMemory, msgs::Vector{<:AbstractMessage})

Smart append that handles duplicate messages based on run IDs.
Only appends messages that are newer than the latest matching message in memory.
"""
function Base.append!(mem::ConversationMemory, msgs::Vector{<:AbstractMessage})
    isempty(msgs) && return mem
    isempty(mem.conversation) && return append!(mem.conversation, msgs)

    # get all messages in mem.conversation with run_id
    run_id_indices = findall(x -> hasproperty(x, :run_id), mem.conversation)

    # Search backwards through messages to find matching point
    for idx in reverse(eachindex(msgs))
        msg = msgs[idx]

        # Find matching message in memory based on run_id if present
        match_idx = if hasproperty(msg, :run_id)
            findlast(
                m -> hasproperty(m, :run_id) && m.run_id == msg.run_id, @view(mem.conversation[run_id_indices]))
        else
            findlast(m -> m == msg, mem.conversation)
        end

        if !isnothing(match_idx)
            # Found match - append everything after this message
            (idx + 1 <= length(msgs)) && append!(mem.conversation, msgs[(idx + 1):end])
            return mem
        end
    end

    @warn "No matching messages found in memory, appending all"
    return append!(mem.conversation, msgs)
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
    (mem::ConversationMemory)(prompt::AbstractString; last::Union{Nothing,Integer}=nothing, kwargs...)

Functor interface for direct generation using the conversation memory.
Optionally, specify the number of last messages to include in the context (uses `get_last`).
"""
function (mem::ConversationMemory)(
        prompt::AbstractString; last::Union{Nothing, Integer} = nothing, kwargs...)
    # Get conversation context
    context = isnothing(last) ? mem.conversation : get_last(mem, last)

    # Add user message to memory first
    user_msg = UserMessage(prompt)
    push!(mem, user_msg)

    # Generate response with context
    response = aigenerate(context; return_all = true, kwargs...)
    append!(mem, response)
    return last_message(response)
end

"""
    aigenerate(schema::AbstractPromptSchema,
        mem::ConversationMemory; kwargs...)

Generate a response using the conversation memory context.
"""
function aigenerate(schema::AbstractPromptSchema,
        mem::ConversationMemory; kwargs...)
    aigenerate(schema, mem.conversation; kwargs...)
end
