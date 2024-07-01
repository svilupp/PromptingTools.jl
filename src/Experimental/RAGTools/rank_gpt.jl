# Implementation of RankGPT
# Is ChatGPT Good at Search? Investigating Large Language Models as Re-Ranking Agents by W. Sun et al. // https://arxiv.org/abs/2304.09542
# https://github.com/sunnweiwei/RankGPT

"""
    RankGPTResult

Results from the RankGPT algorithm.

# Fields
- `question::String`: The question that was asked.
- `chunks::AbstractVector{T}`: The chunks that were ranked (=context).
- `positions::Vector{Int}`: The ranking of the chunks (referring to the `chunks`).
- `elapsed::Float64`: The time it took to rank the chunks.
- `cost::Float64`: The cumulative cost of the ranking.
- `tokens::Int`: The cumulative number of tokens used in the ranking.
"""
@kwdef mutable struct RankGPTResult{T <: AbstractString}
    question::String
    chunks::AbstractVector{T}
    positions::Vector{Int} = collect(1:length(chunks))
    elapsed::Float64 = 0.0
    cost::Float64 = 0.0
    tokens::Int = 0
end
Base.show(io::IO, result::RankGPTResult) = dump(io, result; maxdepth = 1)

"""
    create_permutation_instruction(
        context::AbstractVector{<:AbstractString}; rank_start::Integer = 1,
        rank_end::Integer = 100, max_length::Integer = 512, template::Symbol = :RAGRankGPT)

Creates rendered template with injected `context` passages.
"""
function create_permutation_instruction(
        context::AbstractVector{<:AbstractString}; rank_start::Integer = 1,
        rank_end::Integer = 100, max_length::Integer = 512, template::Symbol = :RAGRankGPT)
    ## 
    rank_end_adj = min(rank_end, length(context))
    num = rank_end_adj - rank_start + 1

    messages = PT.render(PT.AITemplate(template))
    last_msg = pop!(messages)
    rank = 0
    for ctx in context[rank_start:rank_end_adj]
        rank += 1
        push!(messages, PT.UserMessage("[$rank] $(strip(ctx)[1:min(end, max_length)])"))
        push!(messages, PT.AIMessage("Received passage [$rank]."))
    end
    push!(messages, last_msg)

    return messages, num
end

"""
    extract_ranking(str::AbstractString)

Extracts the ranking from the response into a sorted array of integers.
"""
function extract_ranking(str::AbstractString)
    nums = replace(str, r"[^0-9]" => " ") |> strip |> split
    nums = parse.(Int, nums)
    unique_idxs = unique(i -> nums[i], eachindex(nums))
    return nums[unique_idxs]
end

"""
    receive_permutation!(
        curr_rank::AbstractVector{<:Integer}, response::AbstractString;
        rank_start::Integer = 1, rank_end::Integer = 100)

Extracts and heals the permutation to contain all ranking positions.
"""
function receive_permutation!(
        curr_rank::AbstractVector{<:Integer}, response::AbstractString;
        rank_start::Integer = 1, rank_end::Integer = 100)
    @assert rank_start>=1 "rank_start must be greater than or equal to 1"
    @assert rank_end>=rank_start "rank_end must be greater than or equal to rank_start"
    new_rank = extract_ranking(response)
    copied_rank = curr_rank[rank_start:min(end, rank_end)] |> copy
    orig_rank = 1:length(copied_rank)
    new_rank = vcat(
        [r for r in new_rank if r in orig_rank], [r for r in orig_rank if r ∉ new_rank])
    for (j, rnk) in enumerate(new_rank)
        curr_rank[rank_start + j - 1] = copied_rank[rnk]
    end
    return curr_rank
end

"""
    permutation_step!(
        result::RankGPTResult; rank_start::Integer = 1, rank_end::Integer = 100, kwargs...)

One sub-step of the RankGPT algorithm permutation ranking within the window of chunks defined by `rank_start` and `rank_end` positions.
"""
function permutation_step!(
        result::RankGPTResult; rank_start::Integer = 1, rank_end::Integer = 100, kwargs...)
    (; positions, chunks, question) = result
    tpl, num = create_permutation_instruction(chunks; rank_start, rank_end)
    msg = aigenerate(tpl; question, num, kwargs...)
    result.positions = receive_permutation!(
        positions, PT.last_output(msg); rank_start, rank_end)
    result.cost += msg.cost
    result.tokens += sum(msg.tokens)
    result.elapsed += msg.elapsed
    return result
end

"""
    rank_sliding_window!(
        result::RankGPTResult; verbose::Int = 1, rank_start = 1, rank_end = 100,
        window_size = 20, step = 10, model::String = "gpt4o", kwargs...)

One single pass of the RankGPT algorithm permutation ranking across all positions between `rank_start` and `rank_end`.
"""
function rank_sliding_window!(
        result::RankGPTResult; verbose::Int = 1, rank_start = 1, rank_end = 100,
        window_size = 20, step = 10, model::String = "gpt4o", kwargs...)
    @assert rank_start>=0 "rank_start must be greater than or equal to 0 (Provided: rank_start=$rank_start)"
    @assert rank_end>=rank_start "rank_end must be greater than or equal to rank_start (Provided: rank_end=$rank_end, rank_start=$rank_start)"
    @assert rank_end>=window_size>=step "rank_end must be greater than or equal to window_size, which must be greater than or equal to step (Provided: rank_end=$rank_end, window_size=$window_size, step=$step)"
    end_pos = min(rank_end, length(result.chunks))
    start_pos = max(end_pos - window_size, 1)
    while start_pos >= rank_start
        (verbose >= 1) && @info "Ranking chunks in positions $start_pos to $end_pos"
        permutation_step!(result; rank_start = start_pos, rank_end = end_pos,
            model, verbose = (verbose >= 1), kwargs...)
        (verbose >= 2) && @info "Current ranking: $(result.positions)"
        end_pos -= step
        start_pos -= step
    end
    return result
end

"""
    rank_gpt(chunks::AbstractVector{<:AbstractString}, question::AbstractString;
        verbose::Int = 1, rank_start::Integer = 1, rank_end::Integer = 100,
        window_size::Integer = 20, step::Integer = 10,
        num_rounds::Integer = 1, model::String = "gpt4o", kwargs...)

Ranks the `chunks` based on their relevance for `question`. Returns the ranking permutation of the chunks in the order they are most relevant to the question (the first is the most relevant).

# Example
```julia
result = rank_gpt(chunks, question; rank_start=1, rank_end=25, window_size=8, step=4, num_rounds=3, model="gpt4o")
```

# Reference
[1] [Is ChatGPT Good at Search? Investigating Large Language Models as Re-Ranking Agents by W. Sun et al.](https://arxiv.org/abs/2304.09542)
[2] [RankGPT Github](https://github.com/sunnweiwei/RankGPT)
"""
function rank_gpt(chunks::AbstractVector{<:AbstractString}, question::AbstractString;
        verbose::Int = 1, rank_start::Integer = 1, rank_end::Integer = 100,
        window_size::Integer = 20, step::Integer = 10,
        num_rounds::Integer = 1, model::String = "gpt4o", kwargs...)
    result = RankGPTResult(; question, chunks)
    for i in 1:num_rounds
        (verbose >= 1) && @info "Round $i of $num_rounds of ranking process."
        result = rank_sliding_window!(
            result; verbose = verbose - 1, rank_start, rank_end,
            window_size, step, model, kwargs...)
    end
    (verbose >= 1) &&
        @info "Final ranking done. Tokens: $(result.tokens), Cost: $(round(result.cost, digits=2)), Time: $(round(result.elapsed, digits=1))s"
    return result
end