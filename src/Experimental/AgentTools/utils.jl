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

"Unwraps the arguments for AICall and returns the schema and conversation (if provided). Expands any provided AITemplate."
function unwrap_aicall_args(args)
    @assert length(args)<=2 "AICall takes at most 2 positional arguments (provided: $(length(args)))"
    schema = nothing
    conversation = Vector{PT.AbstractMessage}()
    for arg in args
        if isa(arg, PT.AbstractPromptSchema)
            schema = arg
        elseif isa(arg, Vector{<:PT.AbstractMessage})
            conversation = arg
        elseif isa(arg, AbstractString) && isempty(conversation)
            ## User Prompt -- create a UserMessage
            push!(conversation, PT.UserMessage(arg))
        elseif isa(arg, Symbol) && isempty(conversation)
            conversation = PT.render(schema, AITemplate(arg))
        elseif isa(arg, AITemplate) && isempty(conversation)
            conversation = PT.render(schema, arg)
        else
            error("Invalid argument type: $(typeof(arg))")
        end
    end
    return schema, conversation
end

"Extracts `config::RetryConfig` from kwargs and returns the rest of the kwargs."
function extract_config(kwargs, default_config::T) where {T}
    new_kwargs = []
    config = default_config
    for (key, val) in Base.pairs(kwargs)
        if key == :config && val isa T
            config = val
        else
            push!(new_kwargs, (key => val))
        end
    end
    return NamedTuple(new_kwargs), config
end

"If the conversation has multiple AIMessage samples, split them into separate conversations with the common past."
function split_multi_samples(conv)
    ## shortcircuit if the conversation is too short, has no AIMessage or has no integer sample_id
    if length(conv) <= 1 || !(last(conv) isa PT.AIMessage) ||
       isnothing(last(conv).sample_id)
        return [conv]
    end

    split_convos = typeof(conv)[]
    run_id = last(conv).run_id
    ## Extract the common history for all new samples
    past_conv = filter(x -> !PT.isaimessage(x) || x.run_id != run_id, conv)
    for i in eachindex(conv)
        if PT.isaimessage(conv[i]) && conv[i].run_id == run_id
            push!(split_convos, vcat(copy(past_conv)..., conv[i]))
        end
    end
    return split_convos
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
        current_length = sum(
            length.(getproperty.(conversation[(end - 1):end],
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

"""
    gamma_sample(α::Real, θ::Real)

Approximates a sample from the Gamma distribution using the Marsaglia and Tsang method.
"""
function gamma_sample(α::Real, θ::Real)
    if α < 1
        return gamma_sample(1.0 + α, θ) * (rand()^(1 / α))
    end
    d = α - 1.0 / 3
    c = 1.0 / sqrt(9d)
    while true
        x = randn()
        v = 1.0 + c * x
        while v <= 0
            x = randn()
            v = 1.0 + c * x
        end
        v = v^3
        u = rand()
        if u < 1 - 0.0331 * (x^4) || log(u) < 0.5 * x^2 + d * (1 - v + log(v))
            return d * v * θ
        end
    end
end

"""
    beta_sample(α::Real, β::Real)

Approximates a sample from the Beta distribution by generating two independent Gamma distributed samples and using their ratio.
"""
function beta_sample(α::Real, β::Real)
    x = gamma_sample(α, 1.0)
    y = gamma_sample(β, 1.0)
    return x / (x + y)
end
