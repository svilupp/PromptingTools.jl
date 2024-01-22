"""
    find_closest(emb::AbstractMatrix{<:Real},
        query_emb::AbstractVector{<:Real};
        top_k::Int = 100, minimum_similarity::AbstractFloat = -1.0)

Finds the indices of chunks (represented by embeddings in `emb`) that are closest (cosine similarity) to query embedding (`query_emb`). 

If `minimum_similarity` is provided, only indices with similarity greater than or equal to it are returned. 
Similarity can be between -1 and 1 (-1 = completely opposite, 1 = exactly the same).

Returns only `top_k` closest indices.
"""
function find_closest(emb::AbstractMatrix{<:Real},
        query_emb::AbstractVector{<:Real};
        top_k::Int = 100, minimum_similarity::AbstractFloat = -1.0)
    # emb is an embedding matrix where the first dimension is the embedding dimension
    distances = query_emb' * emb |> vec
    positions = distances |> sortperm |> reverse |> x -> first(x, top_k)
    if minimum_similarity > -1.0
        mask = distances[positions] .>= minimum_similarity
        positions = positions[mask]
    end
    return positions, distances[positions]
end
function find_closest(index::AbstractChunkIndex,
        query_emb::AbstractVector{<:Real};
        top_k::Int = 100, minimum_similarity::AbstractFloat = -1.0)
    isnothing(embeddings(index)) && CandidateChunks(; index_id = index.id)
    positions, distances = find_closest(embeddings(index),
        query_emb;
        top_k,
        minimum_similarity)
    return CandidateChunks(index.id, positions, Float32.(distances))
end
function find_closest(index::AbstractMultiIndex,
        query_emb::AbstractVector{<:Real};
        top_k::Int = 100, minimum_similarity::AbstractFloat = -1.0)
    all_candidates = CandidateChunks[]
    for idxs in indexes(index)
        candidates = find_closest(idxs, query_emb;
            top_k,
            minimum_similarity)
        if !isempty(candidates.positions)
            push!(all_candidates, candidates)
        end
    end
    ## build vector of all distances and pick top_k
    all_distances = mapreduce(x -> x.distances, vcat, all_candidates)
    top_k_order = all_distances |> sortperm |> x -> last(x, top_k)
    return CandidateChunks(index.id,
        all_candidates[top_k_order],
        all_distances[top_k_order])
end

function find_tags(index::AbstractChunkIndex,
        tag::Union{AbstractString, Regex})
    isnothing(tags(index)) && CandidateChunks(; index_id = index.id)
    tag_idx = if tag isa AbstractString
        findall(tags_vocab(index) .== tag)
    else # assume it's a regex
        findall(occursin.(tag, tags_vocab(index)))
    end
    # getindex.(x, 1) is to get the first dimension in each CartesianIndex
    match_row_idx = @view(tags(index)[:, tag_idx]) |> findall |>
                    x -> getindex.(x, 1) |> unique
    return CandidateChunks(index.id, match_row_idx, ones(Float32, length(match_row_idx)))
end
function find_tags(index::AbstractChunkIndex,
        tags::Vector{<:AbstractString})
    pos = [find_tags(index, tag).positions for tag in tags] |>
          Base.Splat(vcat) |> unique |> x -> convert(Vector{Int}, x)
    return CandidateChunks(index.id, pos, ones(Float32, length(pos)))
end

# Assuming the rerank and strategy definitions are in the Main module or relevant module
abstract type RerankingStrategy end

struct Passthrough <: RerankingStrategy end
struct CohereRerank <: RerankingStrategy end

function rerank(strategy::Passthrough,
        index,
        question,
        candidate_chunks;
        top_n::Integer = length(candidate_chunks),
        kwargs...)
    # Since this is a Passthrough strategy, it returns the candidate_chunks unchanged
    return first(candidate_chunks, top_n)
end

function rerank(strategy::CohereRerank,
        index::AbstractDocumentIndex, args...; kwargs...)
    throw(ArgumentError("Not implemented yet"))
end

"""
    rerank(strategy::CohereRerank, index::AbstractChunkIndex, question,
        candidate_chunks;
        verbose::Bool = false,
        api_key::AbstractString = PT.COHERE_API_KEY,
        top_n::Integer = length(candidate_chunks.distances),
        model::AbstractString = "rerank-english-v2.0",
        return_documents::Bool = false,
        kwargs...)

Re-ranks a list of candidate chunks using the Cohere Rerank API. See https://cohere.com/rerank for more details. 

# Arguments
- `query`: The query to be used for the search.
- `documents`: A vector of documents to be reranked. 
    The total max chunks (`length of documents * max_chunks_per_doc`) must be less than 10000. We recommend less than 1000 documents for optimal performance.
- `top_n`: The number of most relevant documents to return. Default is `length(documents)`.
- `model`: The model to use for reranking. Default is `rerank-english-v2.0`.
- `return_documents`: A boolean flag indicating whether to return the reranked documents in the response. Default is `false`.
- `max_chunks_per_doc`: The maximum number of chunks to use per document. Default is `10`.
- `verbose`: A boolean flag indicating whether to print verbose logging. Default is `false`.
    
"""
function rerank(strategy::CohereRerank, index::AbstractChunkIndex, question,
        candidate_chunks;
        verbose::Bool = false,
        api_key::AbstractString = PT.COHERE_API_KEY,
        top_n::Integer = length(candidate_chunks.distances),
        model::AbstractString = "rerank-english-v2.0",
        return_documents::Bool = false,
        kwargs...)
    @assert top_n>0 "top_n must be a positive integer."
    @assert index.id==candidate_chunks.index_id "The index id of the index and candidate_chunks must match."

    ## Call the API
    documents = index[candidate_chunks, :chunks]
    verbose &&
        @info "Calling Cohere Rerank API with $(length(documents)) candidate chunks..."
    r = cohere_api(;
        api_key,
        endpoint = "rerank",
        query = question,
        documents,
        top_n,
        model,
        return_documents,
        kwargs...)

    ## Unwrap re-ranked positions
    positions = Vector{Int}(undef, length(r.response[:results]))
    distances = Vector{Float32}(undef, length(r.response[:results]))
    for i in eachindex(r.response[:results])
        doc = r.response[:results][i]
        positions[i] = candidate_chunks.positions[doc[:index] + 1]
        distances[i] = doc[:relevance_score]
    end

    ## Check the cost
    search_units_str = if haskey(r.response, :meta) &&
                          haskey(r.response[:meta], :billed_units) &&
                          haskey(r.response[:meta][:billed_units], :search_units)
        units = r.response[:meta][:billed_units][:search_units]
        "Charged $(units) search units."
    else
        ""
    end
    verbose && @info "Reranking done. $search_units_str"

    return CandidateChunks(index.id, positions, distances)
end