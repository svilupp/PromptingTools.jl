### Types for Retrieval

"""
    NoRephraser <: AbstractRephraser

No-op implementation for `rephrase`, which simply passes the question through.
"""
struct NoRephraser <: AbstractRephraser end

"""
    SimpleRephraser <: AbstractRephraser

Rephraser implemented using the provided AI Template (eg, `...`) and standard chat model.
"""
struct SimpleRephraser <: AbstractRephraser end

"""
    HyDERephraser <: AbstractRephraser

Rephraser implemented using the provided AI Template (eg, `...`) and standard chat model.

It uses a prompt-based rephrasing method called HyDE (Hypothetical Document Embedding), where instead of looking for an embedding of the question, 
we look for the documents most similar to a synthetic passage that _would be_ a good answer to our question.

Reference: [Arxiv paper](https://arxiv.org/abs/2212.10496).
"""
struct HyDERephraser <: AbstractRephraser end

"""
    CosineSimilarity <: AbstractSimilarityFinder

Finds the closest chunks to a query embedding by measuring the cosine similarity between the query and the chunks' embeddings.
"""
struct CosineSimilarity <: AbstractSimilarityFinder end

"""
    BinaryCosineSimilarity <: AbstractSimilarityFinder

Finds the closest chunks to a query embedding by measuring the Hamming distance AND cosine similarity between the query and the chunks' embeddings in binary form.

It follows the two-pass approach:
- First pass: Hamming distance in binary form to get the `top_k * rescore_multiplier` (ie, more than top_k) candidates.
- Second pass: Rescore the candidates with float embeddings and return the top_k.

Reference: [HuggingFace: Embedding Quantization](https://huggingface.co/blog/embedding-quantization#binary-quantization-in-vector-databases).
"""
struct BinaryCosineSimilarity <: AbstractSimilarityFinder end

"""
    BitPackedCosineSimilarity <: AbstractSimilarityFinder

Finds the closest chunks to a query embedding by measuring the Hamming distance AND cosine similarity between the query and the chunks' embeddings in binary form.

The difference to `BinaryCosineSimilarity` is that the binary values are packed into UInt64, which is more efficient.

Reference: [HuggingFace: Embedding Quantization](https://huggingface.co/blog/embedding-quantization#binary-quantization-in-vector-databases).
Implementation of `hamming_distance` is based on [TinyRAG](https://github.com/domluna/tinyrag/blob/main/README.md).
"""
struct BitPackedCosineSimilarity <: AbstractSimilarityFinder end

"""
    NoTagFilter <: AbstractTagFilter


No-op implementation for `find_tags`, which simply returns all chunks.
"""
struct NoTagFilter <: AbstractTagFilter end

"""
    AnyTagFilter <: AbstractTagFilter

Finds the chunks that have ANY OF the specified tag(s).
"""
struct AnyTagFilter <: AbstractTagFilter end

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
        query_emb::AbstractVector{<:Real}; kwargs...)
    throw(ArgumentError("Not implemented yet for type $(typeof(finder))"))
end

"""
    find_closest(finder::CosineSimilarity, emb::AbstractMatrix{<:Real},
        query_emb::AbstractVector{<:Real};
        top_k::Int = 100, minimum_similarity::AbstractFloat = -1.0, kwargs...)

Finds the indices of chunks (represented by embeddings in `emb`) that are closest (in cosine similarity for `CosineSimilarity()`) to query embedding (`query_emb`). 

`finder` is the logic used for the similarity search. Default is `CosineSimilarity`.

If `minimum_similarity` is provided, only indices with similarity greater than or equal to it are returned. 
Similarity can be between -1 and 1 (-1 = completely opposite, 1 = exactly the same).

Returns only `top_k` closest indices.
"""
function find_closest(
        finder::CosineSimilarity, emb::AbstractMatrix{<:Real},
        query_emb::AbstractVector{<:Real};
        top_k::Int = 100, minimum_similarity::AbstractFloat = -1.0, kwargs...)
    # emb is an embedding matrix where the first dimension is the embedding dimension
    scores = query_emb' * emb |> vec
    positions = scores |> sortperm |> reverse |> x -> first(x, top_k)
    if minimum_similarity > -1.0
        mask = scores[positions] .>= minimum_similarity
        positions = positions[mask]
    end
    return positions, scores[positions]
end

"""
    find_closest(
        finder::AbstractSimilarityFinder, index::AbstractChunkIndex,
        query_emb::AbstractVector{<:Real};
        top_k::Int = 100, kwargs...)

Finds the indices of chunks (represented by embeddings in `index`) that are closest to query embedding (`query_emb`).

Returns only `top_k` closest indices.
"""
function find_closest(
        finder::AbstractSimilarityFinder, index::AbstractChunkIndex,
        query_emb::AbstractVector{<:Real};
        top_k::Int = 100, kwargs...)
    isnothing(embeddings(index)) && return CandidateChunks(; index_id = index.id)
    positions, scores = find_closest(finder, embeddings(index),
        query_emb;
        top_k, kwargs...)
    return CandidateChunks(index.id, positions, Float32.(scores))
end

# Dispatch to find scores for multiple embeddings
function find_closest(
        finder::AbstractSimilarityFinder, index::AbstractChunkIndex,
        query_emb::AbstractMatrix{<:Real};
        top_k::Int = 100, kwargs...)
    isnothing(embeddings(index)) && CandidateChunks(; index_id = index.id)
    ## reduce top_k since we have more than one query
    top_k_ = top_k ÷ size(query_emb, 2)
    ## simply vcat together (gets sorted from the highest similarity to the lowest)
    mapreduce(
        c -> find_closest(finder, index, c; top_k = top_k_, kwargs...), vcat, eachcol(query_emb))
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
        query_emb::AbstractVector{<:Real};
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
        query_emb::AbstractVector{<:Real};
        top_k::Int = 100, rescore_multiplier::Int = 4, minimum_similarity::AbstractFloat = -1.0, kwargs...)
    # emb is an embedding matrix where the first dimension is the embedding dimension

    ## First pass, both in binary with Hamming, get rescore_multiplier times top_k
    binary_query_emb = map(>(0), query_emb)
    scores = hamming_distance(emb, binary_query_emb)
    positions = scores |> sortperm |> x -> first(x, top_k * rescore_multiplier)

    ## Second pass, rescore with float embeddings and return top_k
    new_positions, scores = find_closest(CosineSimilarity(), @view(emb[:, positions]),
        query_emb; top_k, minimum_similarity, kwargs...)

    ## translate to original indices
    return positions[new_positions], scores
end

"""
    find_closest(
        finder::BitPackedCosineSimilarity, emb::AbstractMatrix{<:Bool},
        query_emb::AbstractVector{<:Real};
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
        query_emb::AbstractVector{<:Real};
        top_k::Int = 100, rescore_multiplier::Int = 4, minimum_similarity::AbstractFloat = -1.0, kwargs...)
    # emb is an embedding matrix where the first dimension is the embedding dimension

    ## First pass, both in binary with Hamming, get rescore_multiplier times top_k
    bit_query_emb = pack_bits(query_emb .> 0)
    scores = hamming_distance(emb, bit_query_emb)
    positions = scores |> sortperm |> x -> first(x, top_k * rescore_multiplier)

    ## Second pass, rescore with float embeddings and return top_k
    unpacked_emb = unpack_bits(@view(emb[:, positions]))
    new_positions, scores = find_closest(CosineSimilarity(), unpacked_emb,
        query_emb; top_k, minimum_similarity, kwargs...)

    ## translate to original indices
    return positions[new_positions], scores
end

## TODO: Implement for MultiIndex
## function find_closest(index::AbstractMultiIndex,
##         query_emb::AbstractVector{<:Real};
##         top_k::Int = 100, minimum_similarity::AbstractFloat = -1.0)
##     all_candidates = CandidateChunks[]
##     for idxs in indexes(index)
##         candidates = find_closest(idxs, query_emb;
##             top_k,
##             minimum_similarity)
##         if !isempty(candidates.positions)
##             push!(all_candidates, candidates)
##         end
##     end
##     ## build vector of all distances and pick top_k
##     all_distances = mapreduce(x -> x.distances, vcat, all_candidates)
##     top_k_order = all_distances |> sortperm |> x -> last(x, top_k)
##     return CandidateChunks(index.id,
##         all_candidates[top_k_order],
##         all_distances[top_k_order])
## end

### TAG Filtering

function find_tags(::AbstractTagFilter, index::AbstractChunkIndex,
        tag::Union{T, AbstractVector{<:T}}; kwargs...) where {T <:
                                                              Union{AbstractString, Regex}}
    throw(ArgumentError("Not implemented yet for type $(typeof(filter))"))
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

# Method for multiple tags
function find_tags(method::AnyTagFilter, index::AbstractChunkIndex,
        tags::Vector{T}; kwargs...) where {T <: Union{AbstractString, Regex}}
    pos = [find_tags(method, index, tag).positions for tag in tags] |>
          Base.Splat(vcat) |> unique |> x -> convert(Vector{Int}, x)
    return CandidateChunks(index.id, pos, ones(Float32, length(pos)))
end

"""
    find_tags(method::NoTagFilter, index::AbstractChunkIndex,
        tags; kwargs...)

Returns all chunks in the index, ie, no filtering.
"""
function find_tags(method::NoTagFilter, index::AbstractChunkIndex,
        tags::Union{T, AbstractVector{<:T}}; kwargs...) where {T <:
                                                               Union{
        AbstractString, Regex}}
    return CandidateChunks(
        index.id, collect(1:length(index.chunks)), zeros(Float32, length(index.chunks)))
end
function find_tags(method::NoTagFilter, index::AbstractChunkIndex,
        tags::Nothing; kwargs...)
    return CandidateChunks(
        index.id, collect(1:length(index.chunks)), zeros(Float32, length(index.chunks)))
end

### Reranking

"""
    NoReranker <: AbstractReranker

No-op implementation for `rerank`, which simply passes the candidate chunks through.
"""
struct NoReranker <: AbstractReranker end

"""
    CohereReranker <: AbstractReranker

Rerank strategy using the Cohere Rerank API. Requires an API key.
"""
struct CohereReranker <: AbstractReranker end

function rerank(reranker::AbstractReranker,
        index::AbstractDocumentIndex, question::AbstractString, candidates::AbstractCandidateChunks; kwargs...)
    throw(ArgumentError("Not implemented yet"))
end

function rerank(reranker::NoReranker,
        index::AbstractChunkIndex,
        question::AbstractString,
        candidates::AbstractCandidateChunks;
        top_n::Integer = length(candidates),
        kwargs...)
    # Since this is almost a passthrough strategy, it returns the candidate_chunks unchanged
    # but it truncates to `top_n` if necessary
    return first(candidates, top_n)
end

"""
    rerank(
        reranker::CohereReranker, index::AbstractChunkIndex, question::AbstractString,
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
        reranker::CohereReranker, index::AbstractChunkIndex, question::AbstractString,
        candidates::AbstractCandidateChunks;
        verbose::Bool = false,
        api_key::AbstractString = PT.COHERE_API_KEY,
        top_n::Integer = length(candidates.scores),
        model::AbstractString = "rerank-english-v3.0",
        return_documents::Bool = false,
        cost_tracker = Threads.Atomic{Float64}(0.0),
        kwargs...)
    @assert top_n>0 "top_n must be a positive integer."
    @assert index.id==candidates.index_id "The index id of the index and `candidates` must match."

    ## Call the API
    documents = index[candidates, :chunks]
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
    scores = Vector{Float32}(undef, length(r.response[:results]))
    for i in eachindex(r.response[:results])
        doc = r.response[:results][i]
        positions[i] = candidates.positions[doc[:index] + 1]
        scores[i] = doc[:relevance_score]
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

    return CandidateChunks(index.id, positions, scores)
end

### Overall types for `retrieve`
"""
    SimpleRetriever <: AbstractRetriever

Default implementation for `retrieve`. It does a simple similarity search via `CosineSimilarity` and returns the results.

Make sure to use consistent `embedder` and `tagger` with the Preparation Stage (`build_index`)!

# Fields
- `rephraser::AbstractRephraser`: the rephrasing method, dispatching `rephrase` - uses `NoRephraser`
- `embedder::AbstractEmbedder`: the embedding method, dispatching `get_embeddings` (see Preparation Stage for more details) - uses `BatchEmbedder`
- `finder::AbstractSimilarityFinder`: the similarity search method, dispatching `find_closest` - uses `CosineSimilarity`
- `tagger::AbstractTagger`: the tag generating method, dispatching `get_tags` (see Preparation Stage for more details) - uses `NoTagger`
- `filter::AbstractTagFilter`: the tag matching method, dispatching `find_tags` - uses `NoTagFilter`
- `reranker::AbstractReranker`: the reranking method, dispatching `rerank` - uses `NoReranker`
"""
@kwdef mutable struct SimpleRetriever <: AbstractRetriever
    rephraser::AbstractRephraser = NoRephraser()
    embedder::AbstractEmbedder = BatchEmbedder()
    finder::AbstractSimilarityFinder = CosineSimilarity()
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
- `finder::AbstractSimilarityFinder`: the similarity search method, dispatching `find_closest` - uses `CosineSimilarity`
- `tagger::AbstractTagger`: the tag generating method, dispatching `get_tags` (see Preparation Stage for more details) - uses `NoTagger`
- `filter::AbstractTagFilter`: the tag matching method, dispatching `find_tags` - uses `NoTagFilter`
- `reranker::AbstractReranker`: the reranking method, dispatching `rerank` - uses `CohereReranker`
"""
@kwdef mutable struct AdvancedRetriever <: AbstractRetriever
    rephraser::AbstractRephraser = HyDERephraser()
    embedder::AbstractEmbedder = BatchEmbedder()
    finder::AbstractSimilarityFinder = CosineSimilarity()
    tagger::AbstractTagger = NoTagger()
    filter::AbstractTagFilter = NoTagFilter()
    reranker::AbstractReranker = CohereReranker()
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

See also: `SimpleRetriever`, `AdvancedRetriever`, `build_index`, `rephrase`, `get_embeddings`, `find_closest`, `get_tags`, `find_tags`, `rerank`, `RAGResult`.

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
    embedder_kwargs_ = isempty(api_kwargs) ? embedder_kwargs :
                       merge(embedder_kwargs, (; api_kwargs))
    embeddings = get_embeddings(embedder, rephrased_questions;
        verbose = (verbose > 1), cost_tracker, embedder_kwargs_...)

    finder_kwargs_ = isempty(api_kwargs) ? finder_kwargs :
                     merge(finder_kwargs, (; api_kwargs))
    emb_candidates = find_closest(finder, index, embeddings;
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
        @info "Retrieval done. Identified $(length(reranked_candidates.positions)) chunks, total cost: \$$(cost_tracker[])."

    ## Return
    result = RAGResult(;
        question,
        answer = nothing,
        rephrased_questions,
        final_answer = nothing,
        context = chunks(index)[reranked_candidates.positions],
        sources = sources(index)[reranked_candidates.positions],
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
