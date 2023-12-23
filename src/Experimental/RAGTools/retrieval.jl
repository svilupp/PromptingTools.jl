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

function rerank(strategy::Passthrough, index, question, candidate_chunks; kwargs...)
    # Since this is a Passthrough strategy, it returns the candidate_chunks unchanged
    return candidate_chunks
end