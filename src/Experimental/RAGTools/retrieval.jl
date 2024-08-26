### Types for Retrieval

"""
    NoRephraser <: AbstractRephraser

No-op implementation for `rephrase`, which simply passes the question through.
"""
struct NoRephraser <: AbstractRephraser end

"""
    SimpleRephraser <: AbstractRephraser

Rephraser implemented using the provided AI Template (eg, `...`) and standard chat model. A method for `rephrase`.
"""
struct SimpleRephraser <: AbstractRephraser end

"""
    HyDERephraser <: AbstractRephraser

Rephraser implemented using the provided AI Template (eg, `...`) and standard chat model. A method for `rephrase`.

It uses a prompt-based rephrasing method called HyDE (Hypothetical Document Embedding), where instead of looking for an embedding of the question, 
we look for the documents most similar to a synthetic passage that _would be_ a good answer to our question.

Reference: [Arxiv paper](https://arxiv.org/abs/2212.10496).
"""
struct HyDERephraser <: AbstractRephraser end

"""
    CosineSimilarity <: AbstractSimilarityFinder

Finds the closest chunks to a query embedding by measuring the cosine similarity between the query and the chunks' embeddings. A method for `find_closest` (see the docstring for more details and usage example).
"""
struct CosineSimilarity <: AbstractSimilarityFinder end

"""
    BinaryCosineSimilarity <: AbstractSimilarityFinder

Finds the closest chunks to a query embedding by measuring the Hamming distance AND cosine similarity between the query and the chunks' embeddings in binary form. A method for `find_closest`.

It follows the two-pass approach:
- First pass: Hamming distance in binary form to get the `top_k * rescore_multiplier` (ie, more than top_k) candidates.
- Second pass: Rescore the candidates with float embeddings and return the top_k.

Reference: [HuggingFace: Embedding Quantization](https://huggingface.co/blog/embedding-quantization#binary-quantization-in-vector-databases).
"""
struct BinaryCosineSimilarity <: AbstractSimilarityFinder end

"""
    BitPackedCosineSimilarity <: AbstractSimilarityFinder

Finds the closest chunks to a query embedding by measuring the Hamming distance AND cosine similarity between the query and the chunks' embeddings in binary form. A method for `find_closest`.

The difference to `BinaryCosineSimilarity` is that the binary values are packed into UInt64, which is more efficient.

Reference: [HuggingFace: Embedding Quantization](https://huggingface.co/blog/embedding-quantization#binary-quantization-in-vector-databases).
Implementation of `hamming_distance` is based on [TinyRAG](https://github.com/domluna/tinyrag/blob/main/README.md).
"""
struct BitPackedCosineSimilarity <: AbstractSimilarityFinder end

"""
    BM25Similarity <: AbstractSimilarityFinder

Finds the closest chunks to a query embedding by measuring the BM25 similarity between the query and the chunks' embeddings in binary form. A method for `find_closest`.

Reference: [Wikipedia: BM25](https://en.wikipedia.org/wiki/Okapi_BM25).
Implementation follows: [The Next Generation of Lucene Relevance](https://opensourceconnections.com/blog/2015/10/16/bm25-the-next-generation-of-lucene-relevation/).
"""
struct BM25Similarity <: AbstractSimilarityFinder end

"""
    MultiFinder <: AbstractSimilarityFinder 

Composite finder for `MultiIndex` where we want to set multiple finders for each index. A method for `find_closest`.
Positions correspond to `indexes(::MultiIndex)`.
"""
struct MultiFinder <: AbstractSimilarityFinder
    finders::AbstractVector{<:AbstractSimilarityFinder}
end
Base.getindex(finder::MultiFinder, index::Int) = finder.finders[index]
Base.length(finder::MultiFinder) = length(finder.finders)

"""
    NoTagFilter <: AbstractTagFilter


No-op implementation for `find_tags`, which simply returns all chunks.
"""
struct NoTagFilter <: AbstractTagFilter end

"""
    AnyTagFilter <: AbstractTagFilter

Finds the chunks that have ANY OF the specified tag(s). A method for `find_tags`.
"""
struct AnyTagFilter <: AbstractTagFilter end

"""
    AllTagFilter <: AbstractTagFilter

Finds the chunks that have ALL OF the specified tag(s). A method for `find_tags`.
"""
struct AllTagFilter <: AbstractTagFilter end

### Functions
function rephrase(rephraser::AbstractRephraser, question::AbstractString; kwargs...)
    throw(ArgumentError("Not implemented yet for type $(typeof(rephraser))"))
end

"""
    rephrase(rephraser::NoRephraser, question::AbstractString; kwargs...)

No-op, simple passthrough.
"""
function rephrase(rephraser::NoRephraser, question::AbstractString; kwargs...)
    return [question]
end

"""
    rephrase(rephraser::SimpleRephraser, question::AbstractString;
        verbose::Bool = true,
        model::String = PT.MODEL_CHAT, template::Symbol = :RAGQueryOptimizer,
        cost_tracker = Threads.Atomic{Float64}(0.0), kwargs...)

Rephrases the `question` using the provided rephraser `template`.

Returns both the original and the rephrased question.

# Arguments
- `rephraser`: Type that dictates the logic of rephrasing step.
- `question`: The question to be rephrased.
- `model`: The model to use for rephrasing. Default is `PT.MODEL_CHAT`.
- `template`: The rephrasing template to use. Default is `:RAGQueryOptimizer`. Find more with `aitemplates("rephrase")`.
- `verbose`: A boolean flag indicating whether to print verbose logging. Default is `true`.
"""
function rephrase(rephraser::SimpleRephraser, question::AbstractString;
        verbose::Bool = true,
        model::String = PT.MODEL_CHAT, template::Symbol = :RAGQueryOptimizer,
        cost_tracker = Threads.Atomic{Float64}(0.0), kwargs...)
    ## checks
    placeholders = only(aitemplates(template)).variables # only one template should be found
    @assert (:query in placeholders) "Provided RAG Template $(template) is not suitable. It must have a placeholder: `query`."

    msg = aigenerate(template; query = question, verbose, model, kwargs...)
    Threads.atomic_add!(cost_tracker, msg.cost)
    new_question = strip(msg.content)
    return [question, new_question]
end

"""
    rephrase(rephraser::SimpleRephraser, question::AbstractString;
        verbose::Bool = true,
        model::String = PT.MODEL_CHAT, template::Symbol = :RAGQueryHyDE,
        cost_tracker = Threads.Atomic{Float64}(0.0))

Rephrases the `question` using the provided rephraser `template = RAGQueryHyDE`.

Special flavor of rephrasing using HyDE (Hypothetical Document Embedding) method, 
which aims to find the documents most similar to a synthetic passage that _would be_ a good answer to our question.

Returns both the original and the rephrased question.

# Arguments
- `rephraser`: Type that dictates the logic of rephrasing step.
- `question`: The question to be rephrased.
- `model`: The model to use for rephrasing. Default is `PT.MODEL_CHAT`.
- `template`: The rephrasing template to use. Default is `:RAGQueryHyDE`. Find more with `aitemplates("rephrase")`.
- `verbose`: A boolean flag indicating whether to print verbose logging. Default is `true`.
"""
function rephrase(rephraser::HyDERephraser, question::AbstractString;
        verbose::Bool = true,
        model::String = PT.MODEL_CHAT, template::Symbol = :RAGQueryHyDE,
        cost_tracker = Threads.Atomic{Float64}(0.0), kwargs...)
    rephrase(SimpleRephraser(), question; verbose, model, template, cost_tracker, kwargs...)
end

# General fallback
function find_closest(
        finder::AbstractSimilarityFinder, emb::AbstractMatrix{<:Real},
        query_emb::AbstractVector{<:Real}, query_tokens::AbstractVector{<:AbstractString} = String[];
        kwargs...)
    throw(ArgumentError("Not implemented yet for type $(typeof(finder))"))
end

"""
    find_closest(
        finder::CosineSimilarity, emb::AbstractMatrix{<:Real},
        query_emb::AbstractVector{<:Real}, query_tokens::AbstractVector{<:AbstractString} = String[];
        top_k::Int = 100, minimum_similarity::AbstractFloat = -1.0, kwargs...)

Finds the indices of chunks (represented by embeddings in `emb`) that are closest (in cosine similarity for `CosineSimilarity()`) to query embedding (`query_emb`). 

`finder` is the logic used for the similarity search. Default is `CosineSimilarity`.

If `minimum_similarity` is provided, only indices with similarity greater than or equal to it are returned. 
Similarity can be between -1 and 1 (-1 = completely opposite, 1 = exactly the same).

Returns only `top_k` closest indices.
"""
function find_closest(
        finder::CosineSimilarity, emb::AbstractMatrix{<:Real},
        query_emb::AbstractVector{<:Real}, query_tokens::AbstractVector{<:AbstractString} = String[];
        top_k::Int = 100, minimum_similarity::AbstractFloat = -1.0, kwargs...)
    # emb is an embedding matrix where the first dimension is the embedding dimension
    scores = query_emb' * emb |> vec
    top_k_min = min(top_k, length(scores))
    ## Take the top_k largest because larger is better in Cosine similarity (=1 is the best)
    positions = partialsortperm(scores, 1:top_k_min, rev = true)
    if minimum_similarity > -1.0
        mask = @view(scores[positions]) .>= minimum_similarity
        positions = positions[mask]
    else
        ## we want to materialize the view
        positions = collect(positions)
    end
    return positions, scores[positions]
end

"""
    find_closest(
        finder::AbstractSimilarityFinder, index::AbstractChunkIndex,
        query_emb::AbstractVector{<:Real}, query_tokens::AbstractVector{<:AbstractString} = String[];
        top_k::Int = 100, kwargs...)

Finds the indices of chunks (represented by embeddings in `index`) that are closest to query embedding (`query_emb`).

Returns only `top_k` closest indices.
"""
function find_closest(
        finder::AbstractSimilarityFinder, index::AbstractChunkIndex,
        query_emb::AbstractVector{<:Real}, query_tokens::AbstractVector{<:AbstractString} = String[];
        top_k::Int = 100, kwargs...)
    if isnothing(chunkdata(parent(index)))
        return CandidateChunks(; index_id = indexid(index))
    end
    positions, scores = find_closest(finder, chunkdata(index),
        query_emb, query_tokens;
        top_k, kwargs...)
    ## translate positions to original indices
    positions = translate_positions_to_parent(index, positions)
    return CandidateChunks(indexid(index), positions, Float32.(scores))
end

function find_closest(
        finder::AbstractSimilarityFinder, index::PineconeIndex,
        query_emb::AbstractVector{<:Real}, query_tokens::AbstractVector{<:AbstractString} = String[];
        top_n::Int = 10, kwargs...)
    # get Pinecone info
    pinecone_context = index.context
    pinecone_index = index.index
    pinecone_namespace = index.namespace

    # query candidates
    pinecone_results = Pinecone.query(pinecone_context, pinecone_index,
        Vector{Float32}(query_emb), top_n, pinecone_namespace, false, true)
    pinecone_results_json = JSON3.read(pinecone_results)
    matches = pinecone_results_json.matches

    # get the chunks / metadata / sources / scores
    positions = [1 for _ in matches]  # TODO: change this
    scores = [m.score for m in matches]
    chunks = [m.metadata.content for m in matches]
    metadata = [JSON3.read(JSON3.write(m.metadata), Dict{String, Any}) for m in matches]
    sources = [m.metadata.source for m in matches]

    return CandidateWithChunks(
        index_id = index.id,
        positions = positions,
        scores = Vector{Float32}(scores),
        chunks = Vector{String}(chunks),
        metadata = metadata,
        sources = Vector{String}(sources))
end

function find_closest(
        finder::AbstractSimilarityFinder, index::PineconeIndex,
        query_emb::AbstractMatrix{<:Real}, query_tokens::AbstractVector{<:AbstractVector{<:AbstractString}} = Vector{Vector{String}}();
        top_k::Int = 100, top_n::Int = 10,
        kwargs...)
    ## reduce top_k since we have more than one query
    top_k_ = top_k ÷ size(query_emb, 2)
    ## simply vcat together (gets sorted from the highest similarity to the lowest)
    if isempty(query_tokens)
        mapreduce(
            c -> find_closest(finder, index, c; top_k = top_k_, top_n = top_n, kwargs...), vcat, eachcol(query_emb))
    else
        @assert length(query_tokens)==size(query_emb, 2) "Length of `query_tokens` must be equal to the number of columns in `query_emb`."
        mapreduce(
            (emb, tok) -> find_closest(finder, index, emb, tok; top_k = top_k_, top_n = top_n, kwargs...), vcat, eachcol(query_emb), query_tokens)
    end
end

# Dispatch to find scores for multiple embeddings
function find_closest(
        finder::AbstractSimilarityFinder, index::AbstractChunkIndex,
        query_emb::AbstractMatrix{<:Real}, query_tokens::AbstractVector{<:AbstractVector{<:AbstractString}} = Vector{Vector{String}}();
        top_k::Int = 100, kwargs...)
    if isnothing(chunkdata(parent(index)))
        return CandidateChunks(; index_id = indexid(index))
    end
    ## reduce top_k since we have more than one query
    top_k_ = top_k ÷ size(query_emb, 2)
    ## simply vcat together (gets sorted from the highest similarity to the lowest)
    if isempty(query_tokens)
        mapreduce(
            c -> find_closest(finder, index, c; top_k = top_k_, kwargs...), vcat, eachcol(query_emb))
    else
        @assert length(query_tokens)==size(query_emb, 2) "Length of `query_tokens` must be equal to the number of columns in `query_emb`."
        mapreduce(
            (emb, tok) -> find_closest(finder, index, emb, tok; top_k = top_k_, kwargs...), vcat, eachcol(query_emb), query_tokens)
    end
end

### For MultiIndex
function find_closest(
        finder::MultiFinder, index::AbstractMultiIndex,
        query_emb::AbstractVector{<:Real}, query_tokens::AbstractVector{<:AbstractString} = String[];
        top_k::Int = 100, kwargs...)
    all_indexes = indexes(index)
    all(isnothing(chunkdata(index)) for index in all_indexes) &&
        return MultiCandidateChunks(; index_ids = Symbol[])

    ## Get more than top_k candidates, then pick the top 100 by score
    top_k_shard = ceil(Int, top_k / length(all_indexes))
    index_ids = Symbol[]
    positions = Int[]
    scores = Float32[]
    for i in eachindex(all_indexes, finder.finders)
        positions_, scores_ = find_closest(finder[i], chunkdata(all_indexes[i]),
            query_emb, query_tokens;
            top_k = top_k_shard, kwargs...)
        ## translate positions to original indices
        positions_ = translate_positions_to_parent(all_indexes[i], positions_)
        append!(index_ids, fill(indexid(all_indexes[i]), length(positions_)))
        append!(positions, positions_)
        append!(scores, scores_)
    end
    ## Take the top_k largest because larger is better in Cosine similarity (=1 is the best)
    ## Do direct sortperm because it's unlikely to be too much larger (top_k * number of shards)
    idxs = sortperm(scores, rev = true) |> Base.Fix2(first, top_k)
    return MultiCandidateChunks(index_ids[idxs], positions[idxs], scores[idxs])
end

# If we have multi-index, convert to MultiFinder first
function find_closest(
        finder::AbstractSimilarityFinder, index::AbstractMultiIndex,
        query_emb::AbstractVector{<:Real}, query_tokens::AbstractVector{<:AbstractString} = String[];
        kwargs...)
    new_finder = MultiFinder(fill(finder, length(indexes(index))))
    find_closest(new_finder, index, query_emb, query_tokens; kwargs...)
end

# Method for multiple-queries at once (for rephrased queries)
function find_closest(
        finder::AbstractSimilarityFinder, index::AbstractMultiIndex,
        query_emb::AbstractMatrix{<:Real}, query_tokens::AbstractVector{<:AbstractVector{<:AbstractString}} = Vector{Vector{String}}();
        top_k::Int = 100, kwargs...)
    all_indexes = indexes(index)
    all(isnothing(chunkdata(index)) for index in all_indexes) &&
        return MultiCandidateChunks(; index_ids = Symbol[])
    ## reduce top_k since we have more than one query
    top_k_ = top_k ÷ max(size(query_emb, 2), length(query_tokens))
    ## simply vcat together (gets sorted from the highest similarity to the lowest)
    if isempty(query_tokens)
        mapreduce(
            c -> find_closest(finder, index, c; top_k = top_k_, kwargs...), vcat, eachcol(query_emb))
    else
        @assert length(query_tokens)==size(query_emb, 2) "Length of `query_tokens` must be equal to the number of columns in `query_emb`. Provided: $(length(query_tokens)) vs $(size(query_emb, 2))"
        mapreduce(
            (emb, tok) -> find_closest(finder, index, emb, tok; top_k = top_k_, kwargs...), vcat, eachcol(query_emb), query_tokens)
    end
end

#### For binary embeddings
## Source: https://github.com/domluna/tinyrag/blob/main/README.md
## With minor modifications to the signatures

@inline function hamming_distance(x1::T, x2::T)::Int where {T <: Integer}
    return Int(count_ones(x1 ⊻ x2))
end
@inline function hamming_distance(x1::T, x2::T)::Int where {T <: Bool}
    return Int(x1 ⊻ x2)
end
@inline function hamming_distance(
        x1::AbstractVector{T}, x2::AbstractVector{T})::Int where {T <: Integer}
    s = 0
    @inbounds @simd for i in eachindex(x1, x2)
        s += hamming_distance(x1[i], x2[i])
    end
    s
end

"""
    hamming_distance(
        mat::AbstractMatrix{T}, query::AbstractVector{T})::Vector{Int} where {T <: Integer}

Calculates the column-wise Hamming distance between a matrix of binary vectors `mat` and a single binary vector `vect`.

This is the first-pass ranking for `BinaryCosineSimilarity` method.

Implementation from [**domluna's tinyRAG**](https://github.com/domluna/tinyRAG).
"""
@inline function hamming_distance(
        mat::AbstractMatrix{T}, query::AbstractVector{T})::Vector{Int} where {T <: Integer}
    # Check if the number of rows matches
    if size(mat, 1) != length(query)
        throw(ArgumentError("Matrix must have the same number of rows as the length of the Vector (provided: $(size(mat, 1)) vs $(length(query)))"))
    end
    dists = zeros(Int, size(mat, 2))
    @inbounds @simd for i in axes(mat, 2)
        dists[i] = hamming_distance(@view(mat[:, i]), query)
    end
    dists
end

"""
    find_closest(
        finder::BinaryCosineSimilarity, emb::AbstractMatrix{<:Bool},
        query_emb::AbstractVector{<:Real}, query_tokens::AbstractVector{<:AbstractString} = String[];
        top_k::Int = 100, rescore_multiplier::Int = 4, minimum_similarity::AbstractFloat = -1.0, kwargs...)

Finds the indices of chunks (represented by embeddings in `emb`) that are closest to query embedding (`query_emb`) using binary embeddings (in the index).

This is a two-pass approach:
- First pass: Hamming distance in binary form to get the `top_k * rescore_multiplier` (ie, more than top_k) candidates.
- Second pass: Rescore the candidates with float embeddings and return the top_k.

Returns only `top_k` closest indices.

Reference: [HuggingFace: Embedding Quantization](https://huggingface.co/blog/embedding-quantization#binary-quantization-in-vector-databases).

# Examples

Convert any Float embeddings to binary like this:
```julia
binary_emb = map(>(0), emb)
```
"""
function find_closest(
        finder::BinaryCosineSimilarity, emb::AbstractMatrix{<:Bool},
        query_emb::AbstractVector{<:Real}, query_tokens::AbstractVector{<:AbstractString} = String[];
        top_k::Int = 100, rescore_multiplier::Int = 4, minimum_similarity::AbstractFloat = -1.0, kwargs...)
    # emb is an embedding matrix where the first dimension is the embedding dimension

    ## First pass, both in binary with Hamming, get rescore_multiplier times top_k
    binary_query_emb = map(>(0), query_emb)
    scores = hamming_distance(emb, binary_query_emb)
    num_candidates = min(top_k * rescore_multiplier, length(scores))
    ## Take the top_k smallest because smaller is better in Hamming distance
    positions = partialsortperm(scores, 1:num_candidates)

    ## Second pass, rescore with float embeddings and return top_k
    new_positions, scores = find_closest(CosineSimilarity(), @view(emb[:, positions]),
        query_emb; top_k, minimum_similarity, kwargs...)

    ## translate to original indices
    return positions[new_positions], scores
end

"""
    find_closest(
        finder::BitPackedCosineSimilarity, emb::AbstractMatrix{<:Bool},
        query_emb::AbstractVector{<:Real}, query_tokens::AbstractVector{<:AbstractString} = String[];
        top_k::Int = 100, rescore_multiplier::Int = 4, minimum_similarity::AbstractFloat = -1.0, kwargs...)

Finds the indices of chunks (represented by embeddings in `emb`) that are closest to query embedding (`query_emb`) using bit-packed binary embeddings (in the index).

This is a two-pass approach:
- First pass: Hamming distance in bit-packed binary form to get the `top_k * rescore_multiplier` (i.e., more than top_k) candidates.
- Second pass: Rescore the candidates with float embeddings and return the top_k.

Returns only `top_k` closest indices.

Reference: [HuggingFace: Embedding Quantization](https://huggingface.co/blog/embedding-quantization#binary-quantization-in-vector-databases).

# Examples
Convert any Float embeddings to bit-packed binary like this:
```julia
bitpacked_emb = pack_bits(emb.>0)
```
"""
function find_closest(
        finder::BitPackedCosineSimilarity, emb::AbstractMatrix{<:Integer},
        query_emb::AbstractVector{<:Real}, query_tokens::AbstractVector{<:AbstractString} = String[];
        top_k::Int = 100, rescore_multiplier::Int = 4, minimum_similarity::AbstractFloat = -1.0, kwargs...)
    # emb is an embedding matrix where the first dimension is the embedding dimension

    ## First pass, both in binary with Hamming, get rescore_multiplier times top_k
    bit_query_emb = pack_bits(query_emb .> 0)
    scores = hamming_distance(emb, bit_query_emb)
    num_candidates = min(top_k * rescore_multiplier, length(scores))
    ## Take the top_k smallest because smaller is better in Hamming distance
    positions = partialsortperm(scores, 1:num_candidates)

    ## Second pass, rescore with float embeddings and return top_k
    unpacked_emb = unpack_bits(@view(emb[:, positions]))
    new_positions, scores = find_closest(CosineSimilarity(), unpacked_emb,
        query_emb; top_k, minimum_similarity, kwargs...)

    ## translate to original indices
    return positions[new_positions], scores
end

"""
    find_closest(
        finder::BM25Similarity, dtm::AbstractDocumentTermMatrix,
        query_emb::AbstractVector{<:Real}, query_tokens::AbstractVector{<:AbstractString} = String[];
        top_k::Int = 100, minimum_similarity::AbstractFloat = -1.0, kwargs...)

Finds the indices of chunks (represented by DocumentTermMatrix in `dtm`) that are closest to query tokens (`query_tokens`) using BM25.

Reference: [Wikipedia: BM25](https://en.wikipedia.org/wiki/Okapi_BM25).
Implementation follows: [The Next Generation of Lucene Relevance](https://opensourceconnections.com/blog/2015/10/16/bm25-the-next-generation-of-lucene-relevation/).
"""
function find_closest(
        finder::BM25Similarity, dtm::AbstractDocumentTermMatrix,
        query_emb::AbstractVector{<:Real}, query_tokens::AbstractVector{<:AbstractString} = String[];
        top_k::Int = 100, minimum_similarity::AbstractFloat = -1.0, kwargs...)
    scores = bm25(dtm, query_tokens)
    top_k_min = min(top_k, length(scores))
    ## Take the top_k largest because higher is better in BM25
    ## BM25 score are non-negative but unbounded (grows with number of keywords)
    positions = partialsortperm(scores, 1:top_k_min, rev = true)

    if minimum_similarity > -1.0
        mask = @view(scores[positions]) .>= minimum_similarity
        positions = positions[mask]
    else
        # materialize the vector
        positions = positions |> collect
    end
    return positions, scores[positions]
end

### TAG Filtering

function find_tags(::AbstractTagFilter, index::AbstractDocumentIndex,
        tag::Union{T, AbstractVector{<:T}}; kwargs...) where {T <:
                                                              Union{
        AbstractString, Regex, Nothing}}
    throw(ArgumentError("Not implemented yet for type $(typeof(filter)) and index $(typeof(index))"))
end

"""
    find_tags(method::AnyTagFilter, index::AbstractChunkIndex,
        tag::Union{AbstractString, Regex}; kwargs...)

    find_tags(method::AnyTagFilter, index::AbstractChunkIndex,
        tags::Vector{T}; kwargs...) where {T <: Union{AbstractString, Regex}}

Finds the indices of chunks (represented by tags in `index`) that have ANY OF the specified `tag` or `tags`.
"""
function find_tags(method::AnyTagFilter, index::AbstractChunkIndex,
        tag::Union{AbstractString, Regex}; kwargs...)
    isnothing(tags(index)) && CandidateChunks(; index_id = indexid(index))
    tag_idx = if tag isa AbstractString
        findall(tags_vocab(index) .== tag)
    else # assume it's a regex
        findall(occursin.(tag, tags_vocab(index)))
    end
    # getindex.(x, 1) is to get the first dimension in each CartesianIndex
    match_row_idx = @view(tags(index)[:, tag_idx]) |> findall .|> Base.Fix2(getindex, 1) |>
                    unique
    ## Index can be a SubChunkIndex, so we need to convert to the original indices
    match_row_idx = translate_positions_to_parent(index, match_row_idx)
    return CandidateChunks(
        indexid(index), match_row_idx, ones(Float32, length(match_row_idx)))
end

# Method for multiple tags
function find_tags(method::AnyTagFilter, index::AbstractChunkIndex,
        tags::Vector{T}; kwargs...) where {T <: Union{AbstractString, Regex}}
    pos = [positions(find_tags(method, index, tag)) for tag in tags] |>
          Base.Splat(vcat) |> unique |> x -> convert(Vector{Int}, x)
    return CandidateChunks(indexid(index), pos, ones(Float32, length(pos)))
end

"""
    find_tags(method::AllTagFilter, index::AbstractChunkIndex,
        tag::Union{AbstractString, Regex}; kwargs...)

    find_tags(method::AllTagFilter, index::AbstractChunkIndex,
        tags::Vector{T}; kwargs...) where {T <: Union{AbstractString, Regex}}

Finds the indices of chunks (represented by tags in `index`) that have ALL OF the specified `tag` or `tags`.
"""
function find_tags(method::AllTagFilter, index::AbstractChunkIndex,
        tags_vec::Vector{T}; kwargs...) where {T <: Union{AbstractString, Regex}}
    isnothing(tags(index)) && CandidateChunks(; index_id = indexid(index))
    tag_idx = Int[]
    for tag in tags_vec
        if tag isa AbstractString
            append!(tag_idx, findall(tags_vocab(index) .== tag))
        else # assume it's a regex
            append!(tag_idx, findall(occursin.(Ref(tag), tags_vocab(index))))
        end
    end
    ## get rows with all values true
    match_row_idx = if length(tag_idx) > 0
        reduce(.&, eachcol(@view(tags(index)[:, tag_idx]))) |> findall
    else
        Int[]
    end
    ## translate to original indices
    match_row_idx = translate_positions_to_parent(index, match_row_idx)
    return CandidateChunks(
        indexid(index), match_row_idx, ones(Float32, length(match_row_idx)))
end
function find_tags(method::AllTagFilter, index::AbstractChunkIndex,
        tag::Union{AbstractString, Regex}; kwargs...)
    find_tags(method, index, [tag]; kwargs...)
end

"""
    find_tags(method::NoTagFilter, index::AbstractChunkIndex,
        tags::Union{T, AbstractVector{<:T}}; kwargs...) where {T <:
                                                               Union{
        AbstractString, Regex, Nothing}}
        tags; kwargs...)

Returns all chunks in the index, ie, no filtering, so we simply return `nothing` (easier for dispatch).
"""
# function find_tags(method::NoTagFilter, index::AbstractChunkIndex,
#         tags::Union{T, AbstractVector{<:T}}; kwargs...) where {T <:
#                                                                Union{
#         AbstractString, Regex, Nothing}}
#     return nothing
# end
function find_tags(
        method::NoTagFilter, index::Union{AbstractChunkIndex,
            AbstractManagedIndex},
        tags::Union{T, AbstractVector{<:T}};
        kwargs...) where {T <:
                          Union{
        AbstractString, Regex, Nothing}}
    return nothing
end

## Multi-index implementation -- logic differs within each index and then we simply vcat them together
function find_tags(method::Union{AnyTagFilter, AllTagFilter}, index::AbstractMultiIndex,
        tag::Union{T, AbstractVector{<:T}}; kwargs...) where {T <:
                                                              Union{AbstractString, Regex}}
    all_indexes = indexes(index)
    all(isnothing(tags(index)) for index in all_indexes) &&
        return MultiCandidateChunks(; index_ids = Symbol[])

    index_ids = Symbol[]
    positions_ = Int[]
    scores_ = Float32[]
    for i in eachindex(all_indexes)
        if isnothing(tags(all_indexes[i]))
            continue
        end
        cc = find_tags(method, all_indexes[i], tag; kwargs...)
        if !isempty(positions(cc))
            append!(index_ids, fill(indexid(cc), length(positions(cc))))
            append!(positions_, positions(cc))
            append!(scores_, scores(cc))
        end
    end
    idxs = sortperm(scores_, rev = true)
    return MultiCandidateChunks(index_ids[idxs], positions_[idxs], scores_[idxs])
end

function find_tags(method::NoTagFilter, index::AbstractMultiIndex,
        tags::Union{T, AbstractVector{<:T}}; kwargs...) where {T <:
                                                               Union{
        AbstractString, Regex, Nothing}}
    return nothing
end

### Reranking

"""
    NoReranker <: AbstractReranker

No-op implementation for `rerank`, which simply passes the candidate chunks through.
"""
struct NoReranker <: AbstractReranker end

"""
    CohereReranker <: AbstractReranker

Rerank strategy using the Cohere Rerank API. Requires an API key. A method for `rerank`.
"""
struct CohereReranker <: AbstractReranker end

"""
    FlashRanker <: AbstractReranker

Rerank strategy using the package FlashRank.jl and local models. A method for `rerank`.

You must first import the FlashRank.jl package.
To automatically download any required models, set your 
`ENV["DATADEPS_ALWAYS_ACCEPT"] = true` (see [DataDeps](https://www.oxinabox.net/DataDeps.jl/dev/z10-for-end-users/) for more details).

# Example
```julia
using FlashRank

# Wrap the model to be a valid Ranker recognized by RAGTools
# It will be provided to the airag/rerank function to avoid instantiating it on every call
reranker = FlashRank.RankerModel(:mini) |> FlashRanker
# You can choose :tiny or :mini

## Apply to the pipeline configuration, eg, 
cfg = RAGConfig(; retriever = AdvancedRetriever(; reranker))

# Ask a question (assumes you have some `index`)
question = "What are the best practices for parallel computing in Julia?"
result = airag(cfg, index; question, return_all = true)
```
"""
struct FlashRanker{T} <: AbstractReranker
    model::T
end

"""
    RankGPTReranker <: AbstractReranker

Rerank strategy using the RankGPT algorithm (calling LLMs). A method for `rerank`.

# Reference
[1] [Is ChatGPT Good at Search? Investigating Large Language Models as Re-Ranking Agents by W. Sun et al.](https://arxiv.org/abs/2304.09542)
[2] [RankGPT Github](https://github.com/sunnweiwei/RankGPT)
"""
struct RankGPTReranker <: AbstractReranker end

function rerank(reranker::AbstractReranker,
        index::AbstractDocumentIndex, question::AbstractString, candidates::AbstractCandidateChunks; kwargs...)
    throw(ArgumentError("Not implemented yet"))
end

function rerank(reranker::NoReranker,
        index::AbstractDocumentIndex,
        question::AbstractString,
        candidates::AbstractCandidateChunks;
        top_n::Integer = length(candidates),
        kwargs...)
    # Since this is almost a passthrough strategy, it returns the candidate_chunks unchanged
    # but it truncates to `top_n` if necessary
    return first(candidates, top_n)
end

function rerank(reranker::NoReranker,
        index::AbstractManagedIndex,
        question::AbstractString,
        candidates::AbstractCandidateWithChunks;
        top_n::Integer = length(candidates),
        kwargs...)
    # Since this is almost a passthrough strategy, it returns the candidate_chunks unchanged
    # but it truncates to `top_n` if necessary
    return first(candidates, top_n)
end

"""
    rerank(
        reranker::CohereReranker, index::AbstractDocumentIndex, question::AbstractString,
        candidates::AbstractCandidateChunks;
        verbose::Bool = false,
        api_key::AbstractString = PT.COHERE_API_KEY,
        top_n::Integer = length(candidates.scores),
        model::AbstractString = "rerank-english-v3.0",
        return_documents::Bool = false,
        cost_tracker = Threads.Atomic{Float64}(0.0),
        kwargs...)


Re-ranks a list of candidate chunks using the Cohere Rerank API. See https://cohere.com/rerank for more details. 

# Arguments
- `reranker`: Using Cohere API
- `index`: The index that holds the underlying chunks to be re-ranked.
- `question`: The query to be used for the search.
- `candidates`: The candidate chunks to be re-ranked.
- `top_n`: The number of most relevant documents to return. Default is `length(documents)`.
- `model`: The model to use for reranking. Default is `rerank-english-v3.0`.
- `return_documents`: A boolean flag indicating whether to return the reranked documents in the response. Default is `false`.
- `verbose`: A boolean flag indicating whether to print verbose logging. Default is `false`.
- `cost_tracker`: An atomic counter to track the cost of the retrieval. Not implemented /tracked (cost unclear). Provided for consistency.
    
"""
function rerank(
        reranker::CohereReranker, index::AbstractDocumentIndex, question::AbstractString,
        candidates::AbstractCandidateChunks;
        verbose::Bool = false,
        api_key::AbstractString = PT.COHERE_API_KEY,
        top_n::Integer = length(candidates.scores),
        model::AbstractString = "rerank-english-v3.0",
        return_documents::Bool = false,
        cost_tracker = Threads.Atomic{Float64}(0.0),
        kwargs...)
    @assert top_n>0 "top_n must be a positive integer."

    ## Call the API
    documents = index[candidates, :chunks]
    @assert !(isempty(documents)) "The candidate chunks must not be empty for Cohere Reranker! Check the index IDs."

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
    is_multi_cand = candidates isa MultiCandidateChunks
    index_ids = Vector{Symbol}(undef, length(r.response[:results]))
    positions_ = Vector{Int}(undef, length(r.response[:results]))
    scores_ = Vector{Float32}(undef, length(r.response[:results]))
    for i in eachindex(r.response[:results])
        doc = r.response[:results][i]
        positions_[i] = positions(candidates)[doc[:index] + 1]
        scores_[i] = doc[:relevance_score]
        index_ids[i] = if is_multi_cand
            indexids(candidates)[doc[:index] + 1]
        else
            indexid(candidates)
        end
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

    return is_multi_cand ?
           MultiCandidateChunks(index_ids, positions_, scores_) :
           CandidateChunks(index_ids[1], positions_, scores_)
end

"""
    rerank(
        reranker::RankGPTReranker, index::AbstractDocumentIndex, question::AbstractString,
        candidates::AbstractCandidateChunks;
        api_key::AbstractString = PT.OPENAI_API_KEY,
        model::AbstractString = PT.MODEL_CHAT,
        verbose::Bool = false,
        top_n::Integer = length(candidates.scores),
        unique_chunks::Bool = true,
        cost_tracker = Threads.Atomic{Float64}(0.0),
        kwargs...)

Re-ranks a list of candidate chunks using the RankGPT algorithm. See https://github.com/sunnweiwei/RankGPT for more details. 

It uses LLM calls to rank the candidate chunks.

# Arguments
- `reranker`: Using Cohere API
- `index`: The index that holds the underlying chunks to be re-ranked.
- `question`: The query to be used for the search.
- `candidates`: The candidate chunks to be re-ranked.
- `top_n`: The number of most relevant documents to return. Default is `length(documents)`.
- `model`: The model to use for reranking. Default is `rerank-english-v3.0`.
- `verbose`: A boolean flag indicating whether to print verbose logging. Default is `1`.
- `unique_chunks`: A boolean flag indicating whether to remove duplicates from the candidate chunks prior to reranking (saves compute time). Default is `true`.

# Examples

```julia
index = <some index>
question = "What are the best practices for parallel computing in Julia?"

cfg = RAGConfig(; retriever = SimpleRetriever(; reranker = RT.RankGPTReranker()))
msg = airag(cfg, index; question, return_all = true)
```
To get full verbosity of logs, set `verbose = 5` (anything higher than 3).
```julia
msg = airag(cfg, index; question, return_all = true, verbose = 5)
```


# Reference
[1] [Is ChatGPT Good at Search? Investigating Large Language Models as Re-Ranking Agents by W. Sun et al.](https://arxiv.org/abs/2304.09542)
[2] [RankGPT Github](https://github.com/sunnweiwei/RankGPT)
"""
function rerank(
        reranker::RankGPTReranker, index::AbstractDocumentIndex, question::AbstractString,
        candidates::AbstractCandidateChunks;
        api_key::AbstractString = PT.OPENAI_API_KEY,
        model::AbstractString = PT.MODEL_CHAT,
        verbose::Bool = false,
        top_n::Integer = length(candidates.scores),
        unique_chunks::Bool = true,
        cost_tracker = Threads.Atomic{Float64}(0.0),
        kwargs...)
    @assert top_n>0 "top_n must be a positive integer."
    documents = index[candidates, :chunks]
    @assert !(isempty(documents)) "The candidate chunks must not be empty! Check the index IDs."

    is_multi_cand = candidates isa MultiCandidateChunks
    index_ids = is_multi_cand ? indexids(candidates) : indexid(candidates)
    positions_ = positions(candidates)
    ## Find unique only items
    if unique_chunks
        verbose && @info "Removing duplicates from candidate chunks prior to reranking"
        unique_idxs = PT.unique_permutation(documents)
        documents = documents[unique_idxs]
        positions_ = positions_[unique_idxs]
        index_ids = is_multi_cand ? index_ids[unique_idxs] : index_ids
    end

    ## Run re-ranker via RankGPT
    rank_end = max(get(kwargs, :rank_end, length(documents)), length(documents))
    step = min(get(kwargs, :step, top_n), top_n, rank_end)
    window_size = max(min(get(kwargs, :window_size, 20), rank_end), step)
    verbose &&
        @info "RankGPT parameters: rank_end = $rank_end, step = $step, window_size = $window_size"
    result = rank_gpt(
        documents, question; verbose = verbose * 3, api_key,
        model, kwargs..., rank_end, step, window_size)

    ## Unwrap re-ranked positions
    ranked_positions = first(result.positions, top_n)
    positions_ = positions_[ranked_positions]
    ## TODO: add reciprocal rank fusion and multiple passes
    scores_ = ones(Float32, length(positions_)) # no scores available

    verbose && @info "Reranking done in $(round(result.elapsed; digits=1)) seconds."
    Threads.atomic_add!(cost_tracker, result.cost)

    return is_multi_cand ?
           MultiCandidateChunks(index_ids[ranked_positions], positions_, scores_) :
           CandidateChunks(index_ids, positions_, scores_)
end

### Overall types for `retrieve`
"""
    SimpleRetriever <: AbstractRetriever

Default implementation for `retrieve` function. It does a simple similarity search via `CosineSimilarity` and returns the results.

Make sure to use consistent `embedder` and `tagger` with the Preparation Stage (`build_index`)!

# Fields
- `rephraser::AbstractRephraser`: the rephrasing method, dispatching `rephrase` - uses `NoRephraser`
- `embedder::AbstractEmbedder`: the embedding method, dispatching `get_embeddings` (see Preparation Stage for more details) - uses `BatchEmbedder`
- `processor::AbstractProcessor`: the processor method, dispatching `get_keywords` (see Preparation Stage for more details) - uses `NoProcessor`
- `finder::AbstractSimilarityFinder`: the similarity search method, dispatching `find_closest` - uses `CosineSimilarity`
- `tagger::AbstractTagger`: the tag generating method, dispatching `get_tags` (see Preparation Stage for more details) - uses `NoTagger`
- `filter::AbstractTagFilter`: the tag matching method, dispatching `find_tags` - uses `NoTagFilter`
- `reranker::AbstractReranker`: the reranking method, dispatching `rerank` - uses `NoReranker`
"""
@kwdef mutable struct SimpleRetriever <: AbstractRetriever
    rephraser::AbstractRephraser = NoRephraser()
    embedder::AbstractEmbedder = BatchEmbedder()
    processor::AbstractProcessor = NoProcessor()
    finder::AbstractSimilarityFinder = CosineSimilarity()
    tagger::AbstractTagger = NoTagger()
    filter::AbstractTagFilter = NoTagFilter()
    reranker::AbstractReranker = NoReranker()
end

"""
    SimpleBM25Retriever <: AbstractRetriever

Keyword-based implementation for `retrieve`. It does a simple similarity search via `BM25Similarity` and returns the results.

Make sure to use consistent `processor` and `tagger` with the Preparation Stage (`build_index`)!

# Fields
- `rephraser::AbstractRephraser`: the rephrasing method, dispatching `rephrase` - uses `NoRephraser`
- `embedder::AbstractEmbedder`: the embedding method, dispatching `get_embeddings` (see Preparation Stage for more details) - uses `NoEmbedder`
- `processor::AbstractProcessor`: the processor method, dispatching `get_keywords` (see Preparation Stage for more details) - uses `KeywordsProcessor`
- `finder::AbstractSimilarityFinder`: the similarity search method, dispatching `find_closest` - uses `CosineSimilarity`
- `tagger::AbstractTagger`: the tag generating method, dispatching `get_tags` (see Preparation Stage for more details) - uses `NoTagger`
- `filter::AbstractTagFilter`: the tag matching method, dispatching `find_tags` - uses `NoTagFilter`
- `reranker::AbstractReranker`: the reranking method, dispatching `rerank` - uses `NoReranker`
"""
@kwdef mutable struct SimpleBM25Retriever <: AbstractRetriever
    rephraser::AbstractRephraser = NoRephraser()
    embedder::AbstractEmbedder = NoEmbedder()
    processor::AbstractProcessor = KeywordsProcessor()
    finder::AbstractSimilarityFinder = BM25Similarity()
    tagger::AbstractTagger = NoTagger()
    filter::AbstractTagFilter = NoTagFilter()
    reranker::AbstractReranker = NoReranker()
end

"""
    AdvancedRetriever <: AbstractRetriever

Dispatch for `retrieve` with advanced retrieval methods to improve result quality.
Compared to SimpleRetriever, it adds rephrasing the query and reranking the results.

# Fields
- `rephraser::AbstractRephraser`: the rephrasing method, dispatching `rephrase` - uses `HyDERephraser`
- `embedder::AbstractEmbedder`: the embedding method, dispatching `get_embeddings` (see Preparation Stage for more details) - uses `BatchEmbedder`
- `processor::AbstractProcessor`: the processor method, dispatching `get_keywords` (see Preparation Stage for more details) - uses `NoProcessor`
- `finder::AbstractSimilarityFinder`: the similarity search method, dispatching `find_closest` - uses `CosineSimilarity`
- `tagger::AbstractTagger`: the tag generating method, dispatching `get_tags` (see Preparation Stage for more details) - uses `NoTagger`
- `filter::AbstractTagFilter`: the tag matching method, dispatching `find_tags` - uses `NoTagFilter`
- `reranker::AbstractReranker`: the reranking method, dispatching `rerank` - uses `CohereReranker`
"""
@kwdef mutable struct AdvancedRetriever <: AbstractRetriever
    rephraser::AbstractRephraser = HyDERephraser()
    embedder::AbstractEmbedder = BatchEmbedder()
    processor::AbstractProcessor = NoProcessor()
    finder::AbstractSimilarityFinder = CosineSimilarity()
    tagger::AbstractTagger = NoTagger()
    filter::AbstractTagFilter = NoTagFilter()
    reranker::AbstractReranker = CohereReranker()
end

"""
    PineconeRetriever <: AbstractRetriever

Dispatch for `retrieve` for Pinecone.
"""
@kwdef mutable struct PineconeRetriever <: AbstractRetriever
    rephraser::AbstractRephraser = NoRephraser()
    embedder::AbstractEmbedder = SimpleEmbedder()
    processor::AbstractProcessor = NoProcessor()
    finder::AbstractSimilarityFinder = CosineSimilarity()
    tagger::AbstractTagger = NoTagger()
    filter::AbstractTagFilter = NoTagFilter()
    reranker::AbstractReranker = NoReranker()
end

"""
    retrieve(retriever::AbstractRetriever,
        index::AbstractChunkIndex,
        question::AbstractString;
        verbose::Integer = 1,
        top_k::Integer = 100,
        top_n::Integer = 5,
        api_kwargs::NamedTuple = NamedTuple(),
        rephraser::AbstractRephraser = retriever.rephraser,
        rephraser_kwargs::NamedTuple = NamedTuple(),
        embedder::AbstractEmbedder = retriever.embedder,
        embedder_kwargs::NamedTuple = NamedTuple(),
        processor::AbstractProcessor = retriever.processor,
        processor_kwargs::NamedTuple = NamedTuple(),
        finder::AbstractSimilarityFinder = retriever.finder,
        finder_kwargs::NamedTuple = NamedTuple(),
        tagger::AbstractTagger = retriever.tagger,
        tagger_kwargs::NamedTuple = NamedTuple(),
        filter::AbstractTagFilter = retriever.filter,
        filter_kwargs::NamedTuple = NamedTuple(),
        reranker::AbstractReranker = retriever.reranker,
        reranker_kwargs::NamedTuple = NamedTuple(),
        cost_tracker = Threads.Atomic{Float64}(0.0),
        kwargs...)

Retrieves the most relevant chunks from the index for the given question and returns them in the `RAGResult` object.

This is the main entry point for the retrieval stage of the RAG pipeline. It is often followed by `generate!` step.

Notes:
- The default flow is `build_context!` -> `answer!` -> `refine!` -> `postprocess!`.

The arguments correspond to the steps of the retrieval process (rephrasing, embedding, finding similar docs, tagging, filtering by tags, reranking).
You can customize each step by providing a new custom type that dispatches the corresponding function, 
    eg, create your own type `struct MyReranker<:AbstractReranker end` and define the custom method for it `rerank(::MyReranker,...) = ...`.

Note: Discover available retrieval sub-types for each step with `subtypes(AbstractRephraser)` and similar for other abstract types.

If you're using locally-hosted models, you can pass the `api_kwargs` with the `url` field set to the model's URL and make sure to provide corresponding 
    `model` kwargs to `rephraser`, `embedder`, and `tagger` to use the custom models (they make AI calls).

# Arguments
- `retriever`: The retrieval method to use. Default is `SimpleRetriever` but could be `AdvancedRetriever` for more advanced retrieval.
- `index`: The index that holds the chunks and sources to be retrieved from.
- `question`: The question to be used for the retrieval.
- `verbose`: If `>0`, it prints out verbose logging. Default is `1`. If you set it to `2`, it will print out logs for each sub-function.
- `top_k`: The TOTAL number of closest chunks to return from `find_closest`. Default is `100`.
   If there are multiple rephrased questions, the number of chunks per each item will be `top_k ÷ number_of_rephrased_questions`.
- `top_n`: The TOTAL number of most relevant chunks to return for the context (from `rerank` step). Default is `5`.
- `api_kwargs`: Additional keyword arguments to be passed to the API calls (shared by all `ai*` calls).
- `rephraser`: Transform the question into one or more questions. Default is `retriever.rephraser`.
- `rephraser_kwargs`: Additional keyword arguments to be passed to the rephraser.
    - `model`: The model to use for rephrasing. Default is `PT.MODEL_CHAT`.
    - `template`: The rephrasing template to use. Default is `:RAGQueryOptimizer` or `:RAGQueryHyDE` (depending on the `rephraser` selected).
- `embedder`: The embedding method to use. Default is `retriever.embedder`.
- `embedder_kwargs`: Additional keyword arguments to be passed to the embedder.
- `processor`: The processor method to use when using Keyword-based index. Default is `retriever.processor`.
- `processor_kwargs`: Additional keyword arguments to be passed to the processor.
- `finder`: The similarity search method to use. Default is `retriever.finder`, often `CosineSimilarity`.
- `finder_kwargs`: Additional keyword arguments to be passed to the similarity finder.
- `tagger`: The tag generating method to use. Default is `retriever.tagger`.
- `tagger_kwargs`: Additional keyword arguments to be passed to the tagger. Noteworthy arguments:
    - `tags`: Directly provide the tags to use for filtering (can be String, Regex, or Vector{String}). Useful for `tagger = PassthroughTagger`.
- `filter`: The tag matching method to use. Default is `retriever.filter`.
- `filter_kwargs`: Additional keyword arguments to be passed to the tag filter.
- `reranker`: The reranking method to use. Default is `retriever.reranker`.
- `reranker_kwargs`: Additional keyword arguments to be passed to the reranker.
    - `model`: The model to use for reranking. Default is `rerank-english-v2.0` if you use `reranker = CohereReranker()`.
- `cost_tracker`: An atomic counter to track the cost of the retrieval. Default is `Threads.Atomic{Float64}(0.0)`.

See also: `SimpleRetriever`, `AdvancedRetriever`, `build_index`, `rephrase`, `get_embeddings`, `get_keywords`, `find_closest`, `get_tags`, `find_tags`, `rerank`, `RAGResult`.

# Examples

Find the 5 most relevant chunks from the index for the given question.
```julia
# assumes you have an existing index `index`
retriever = SimpleRetriever()

result = retrieve(retriever,
    index,
    "What is the capital of France?",
    top_n = 5)

# or use the default retriever (same as above)
result = retrieve(retriever,
    index,
    "What is the capital of France?",
    top_n = 5)
```

Apply more advanced retrieval with question rephrasing and reranking (requires `COHERE_API_KEY`).
We will obtain top 100 chunks from embeddings (`top_k`) and top 5 chunks from reranking (`top_n`).

```julia
retriever = AdvancedRetriever()

result = retrieve(retriever, index, question; top_k=100, top_n=5)
```

You can use the `retriever` to customize your retrieval strategy or directly change the strategy types in the `retrieve` kwargs!

Example of using locally-hosted model hosted on `localhost:8080`:
```julia
retriever = SimpleRetriever()
result = retrieve(retriever, index, question;
    rephraser_kwargs = (; model = "custom"),
    embedder_kwargs = (; model = "custom"),
    tagger_kwargs = (; model = "custom"), api_kwargs = (;
        url = "http://localhost:8080"))
```
"""
function retrieve(retriever::AbstractRetriever,
        index::AbstractDocumentIndex,
        question::AbstractString;
        verbose::Integer = 1,
        top_k::Integer = 100,
        top_n::Integer = 5,
        api_kwargs::NamedTuple = NamedTuple(),
        rephraser::AbstractRephraser = retriever.rephraser,
        rephraser_kwargs::NamedTuple = NamedTuple(),
        embedder::AbstractEmbedder = retriever.embedder,
        embedder_kwargs::NamedTuple = NamedTuple(),
        processor::AbstractProcessor = retriever.processor,
        processor_kwargs::NamedTuple = NamedTuple(),
        finder::AbstractSimilarityFinder = retriever.finder,
        finder_kwargs::NamedTuple = NamedTuple(),
        tagger::AbstractTagger = retriever.tagger,
        tagger_kwargs::NamedTuple = NamedTuple(),
        filter::AbstractTagFilter = retriever.filter,
        filter_kwargs::NamedTuple = NamedTuple(),
        reranker::AbstractReranker = retriever.reranker,
        reranker_kwargs::NamedTuple = NamedTuple(),
        cost_tracker = Threads.Atomic{Float64}(0.0),
        kwargs...)
    ## Rephrase into one or more questions
    rephraser_kwargs_ = isempty(api_kwargs) ? rephraser_kwargs :
                        merge(rephraser_kwargs, (; api_kwargs))
    rephrased_questions = rephrase(
        rephraser, question; verbose = (verbose > 1), cost_tracker, rephraser_kwargs_...)

    ## Embed one or more rephrased questions
    embeddings = if HasEmbeddings(index)
        embedder_kwargs_ = isempty(api_kwargs) ? embedder_kwargs :
                           merge(embedder_kwargs, (; api_kwargs))
        embeddings = get_embeddings(embedder, rephrased_questions;
            verbose = (verbose > 1), cost_tracker, embedder_kwargs_...)
    else
        embeddings = hcat([Float32[] for x in rephrased_questions]...)
    end

    ## Preprocess into keyword tokens if we're running BM25 
    keywords = if HasKeywords(index)
        ## Return only keywords, not DTM
        keywords = get_keywords(processor, rephrased_questions;
            verbose = (verbose > 1), processor_kwargs..., return_keywords = true)
        ## Send warning for common error
        verbose >= 1 && (keywords isa AbstractVector{<:AbstractVector{<:AbstractString}} ||
         @warn "Processed Keywords is not a vector of tokenized queries. Have you used the correct processor? (provided: $(typeof(processor))).")
        keywords
    else
        [String[] for x in rephrased_questions]
    end

    finder_kwargs_ = isempty(api_kwargs) ? finder_kwargs :
                     merge(finder_kwargs, (; api_kwargs))
    emb_candidates = find_closest(finder, index, embeddings, keywords;
        verbose = (verbose > 1), top_k, finder_kwargs_...)

    ## Tagging - if you provide them explicitly, use tagger `PassthroughTagger` and `tagger_kwargs = (;tags = ...)`
    tagger_kwargs_ = isempty(api_kwargs) ? tagger_kwargs :
                     merge(tagger_kwargs, (; api_kwargs))
    tags = get_tags(tagger, rephrased_questions; verbose = (verbose > 1),
        cost_tracker, tagger_kwargs_...)

    filter_kwargs_ = isempty(api_kwargs) ? filter_kwargs :
                     merge(filter_kwargs, (; api_kwargs))
    tag_candidates = find_tags(
        filter, index, tags; verbose = (verbose > 1), filter_kwargs_...)

    ## Combine the two sets of candidates, looks for intersection (hard filter)!
    # With tagger=NoTagger() get_tags returns `nothing` find_tags simply passes it through to skip the intersection
    filtered_candidates = isnothing(tag_candidates) ? emb_candidates :
                          (emb_candidates & tag_candidates)
    ## TODO: Future implementation should be to apply tag filtering BEFORE the find_closest,
    ## but that requires implementing `view(::Index,...)` to provide only a subset of the embeddings to the subsequent functionality.
    ## Also, find_closest is so fast & cheap that it doesn't matter at current scale/maturity of the use cases

    ## Reranking
    reranker_kwargs_ = isempty(api_kwargs) ? reranker_kwargs :
                       merge(reranker_kwargs, (; api_kwargs))
    reranked_candidates = rerank(reranker, index, question, filtered_candidates;
        top_n, verbose = (verbose > 1), cost_tracker, reranker_kwargs_...)

    verbose > 0 &&
        @info "Retrieval done. Identified $(length(positions(reranked_candidates))) chunks, total cost: \$$(round(cost_tracker[], digits=2))."

    ## Return
    result = RAGResult(;
        question,
        answer = nothing,
        rephrased_questions,
        final_answer = nothing,
        ## Ensure chunks and sources are sorted
        context = collect(index[reranked_candidates, :chunks, sorted = true]),
        sources = collect(index[reranked_candidates, :sources, sorted = true]),
        emb_candidates,
        tag_candidates,
        filtered_candidates,
        reranked_candidates)

    return result
end

function retrieve(retriever::PineconeRetriever,
        index::PineconeIndex,
        question::AbstractString;
        verbose::Integer = 1,
        top_k::Integer = 100,
        top_n::Integer = 10,
        api_kwargs::NamedTuple = NamedTuple(),
        rephraser::AbstractRephraser = retriever.rephraser,
        rephraser_kwargs::NamedTuple = NamedTuple(),
        embedder::AbstractEmbedder = retriever.embedder,
        embedder_kwargs::NamedTuple = NamedTuple(),
        processor::AbstractProcessor = retriever.processor,
        processor_kwargs::NamedTuple = NamedTuple(),
        finder::AbstractSimilarityFinder = retriever.finder,
        finder_kwargs::NamedTuple = NamedTuple(),
        tagger::AbstractTagger = retriever.tagger,
        tagger_kwargs::NamedTuple = NamedTuple(),
        filter::AbstractTagFilter = retriever.filter,
        filter_kwargs::NamedTuple = NamedTuple(),
        reranker::AbstractReranker = retriever.reranker,
        reranker_kwargs::NamedTuple = NamedTuple(),
        cost_tracker = Threads.Atomic{Float64}(0.0),
        kwargs...)
    ## Rephrase into one or more questions
    rephraser_kwargs_ = isempty(api_kwargs) ? rephraser_kwargs :
                        merge(rephraser_kwargs, (; api_kwargs))
    rephrased_questions = rephrase(
        rephraser, question; verbose = (verbose > 1), cost_tracker, rephraser_kwargs_...)

    ## Embed one or more rephrased questions
    embeddings = if HasEmbeddings(index)
        embedder_kwargs_ = isempty(api_kwargs) ? embedder_kwargs :
                           merge(embedder_kwargs, (; api_kwargs))
        embeddings = get_embeddings(embedder, rephrased_questions;
            verbose = (verbose > 1), cost_tracker, embedder_kwargs_...)
    else
        embeddings = hcat([Float32[] for _ in rephrased_questions]...)
    end

    ## Preprocess into keyword tokens if we're running BM25 
    keywords = if HasKeywords(index)
        ## Return only keywords, not DTM
        keywords = get_keywords(processor, rephrased_questions;
            verbose = (verbose > 1), processor_kwargs..., return_keywords = true)
        ## Send warning for common error
        verbose >= 1 && (keywords isa AbstractVector{<:AbstractVector{<:AbstractString}} ||
         @warn "Processed Keywords is not a vector of tokenized queries. Have you used the correct processor? (provided: $(typeof(processor))).")
        keywords
    else
        [String[] for _ in rephrased_questions]
    end

    finder_kwargs_ = isempty(api_kwargs) ? finder_kwargs :
                     merge(finder_kwargs, (; api_kwargs))
    emb_candidates = find_closest(finder, index, embeddings, keywords;
        verbose = (verbose > 1), top_k, top_n, finder_kwargs_...)

    ## Tagging - if you provide them explicitly, use tagger `PassthroughTagger` and `tagger_kwargs = (;tags = ...)`
    tagger_kwargs_ = isempty(api_kwargs) ? tagger_kwargs :
                     merge(tagger_kwargs, (; api_kwargs))
    tags = get_tags(tagger, rephrased_questions; verbose = (verbose > 1),
        cost_tracker, tagger_kwargs_...)

    filter_kwargs_ = isempty(api_kwargs) ? filter_kwargs :
                     merge(filter_kwargs, (; api_kwargs))
    tag_candidates = find_tags(
        filter, index, tags; verbose = (verbose > 1), filter_kwargs_...)

    ## Combine the two sets of candidates, looks for intersection (hard filter)!
    # With tagger=NoTagger() get_tags returns `nothing` find_tags simply passes it through to skip the intersection
    filtered_candidates = isnothing(tag_candidates) ? emb_candidates :
                          (emb_candidates & tag_candidates)
    ## TODO: Future implementation should be to apply tag filtering BEFORE the find_closest,
    ## but that requires implementing `view(::Index,...)` to provide only a subset of the embeddings to the subsequent functionality.
    ## Also, find_closest is so fast & cheap that it doesn't matter at current scale/maturity of the use cases

    ## Reranking
    reranker_kwargs_ = isempty(api_kwargs) ? reranker_kwargs :
                       merge(reranker_kwargs, (; api_kwargs))
    reranked_candidates = rerank(reranker, index, question, filtered_candidates;
        top_n, verbose = (verbose > 1), cost_tracker, reranker_kwargs_...)

    verbose > 0 &&
        @info "Retrieval done. Total cost: \$$(round(cost_tracker[], digits=2))."

    result = RAGResult(;
        question,
        answer = nothing,
        rephrased_questions,
        final_answer = nothing,
        ## Ensure chunks and sources are sorted
        context = collect(index[reranked_candidates, :chunks, sorted = true]),
        sources = collect(index[reranked_candidates, :sources, sorted = true]),
        emb_candidates,
        tag_candidates,
        filtered_candidates,
        reranked_candidates)

    return result
end

# Set default behavior
DEFAULT_RETRIEVER = SimpleRetriever()
function retrieve(index::AbstractChunkIndex, question::AbstractString;
        kwargs...)
    return retrieve(DEFAULT_RETRIEVER, index, question;
        kwargs...)
end
