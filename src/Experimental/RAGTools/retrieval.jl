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
    CosineSimilarity <: AbstractSimilarityFinder

Finds the closest chunks to a query embedding by measuring the cosine similarity between the query and the chunks' embeddings.
"""
struct CosineSimilarity <: AbstractSimilarityFinder end

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
function rephrase(::AbstractRephraser, question::AbstractString; kwargs...)
    throw(ArgumentError("Not implemented yet for type $(typeof(rephraser))"))
end

# No-op, simple passthrough
function rephrase(rephraser::NoRephraser, question::AbstractString; kwargs...)
    return [question]
end

"""
    rephrase(rephraser::SimpleRephraser, question::AbstractString;
        model::String = PT.MODEL_CHAT, template::Symbol = :SimpleQuestionRephraser)

Rephrases the `question` using the provided rephraser `template`.
"""
function rephrase(rephraser::SimpleRephraser, question::AbstractString;
        verbose::Bool = true,
        model::String = PT.MODEL_CHAT, template::Symbol = :SimpleQuestionRephraser,
        cost_tracker = Threads.Atomic{Float64}(0.0))
    # TODO: Implement rephrasing, add template
    msg = aigenerate(template; question, verbose, model)
    Threads.atomic_add!(cost_tracker, msg.cost)
    # TODO: add clean up
    new_question = msg.content
    return [question, new_question]
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
    isnothing(embeddings(index)) && CandidateChunks(; index_id = index.id)
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
    ## simply vcat together (gets sorted from the highest similarity to the lowest)
    mapreduce(
        c -> find_closest(finder, index, c; top_k, kwargs...), vcat, eachcol(query_emb))
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
        tag::Union{AbstractString, Regex}; kwargs...)
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
        tags; kwargs...)
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
        model::AbstractString = "rerank-english-v2.0",
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
- `model`: The model to use for reranking. Default is `rerank-english-v2.0`.
- `return_documents`: A boolean flag indicating whether to return the reranked documents in the response. Default is `false`.
- `verbose`: A boolean flag indicating whether to print verbose logging. Default is `false`.
- `cost_tracker`: An atomic counter to track the cost of the retrieval. Default is `Threads.Atomic{Float64}(0.0)`. Not currently tracked (cost unclear).
    
"""
function rerank(
        reranker::CohereReranker, index::AbstractChunkIndex, question::AbstractString,
        candidates::AbstractCandidateChunks;
        verbose::Bool = false,
        api_key::AbstractString = PT.COHERE_API_KEY,
        top_n::Integer = length(candidates.scores),
        model::AbstractString = "rerank-english-v2.0",
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
- `rephraser::AbstractRephraser`: the rephrasing method, dispatching `rephrase`
- `embedder::AbstractEmbedder`: the embedding method, dispatching `get_embeddings` (see Preparation Stage for more details)
- `finder::AbstractSimilarityFinder`: the similarity search method, dispatching `find_closest`
- `tagger::AbstractTagger`: the tag generating method, dispatching `get_tags` (see Preparation Stage for more details)
- `filter::AbstractTagFilter`: the tag matching method, dispatching `find_tags`
- `reranker::AbstractReranker`: the reranking method, dispatching `rerank`
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
- `rephraser::AbstractRephraser`: the rephrasing method, dispatching `rephrase`
- `embedder::AbstractEmbedder`: the embedding method, dispatching `get_embeddings` (see Preparation Stage for more details)
- `finder::AbstractSimilarityFinder`: the similarity search method, dispatching `find_closest`
- `tagger::AbstractTagger`: the tag generating method, dispatching `get_tags` (see Preparation Stage for more details)
- `filter::AbstractTagFilter`: the tag matching method, dispatching `find_tags`
- `reranker::AbstractReranker`: the reranking method, dispatching `rerank`
"""
@kwdef mutable struct AdvancedRetriever <: AbstractRetriever
    rephraser::AbstractRephraser = SimpleRephraser()
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


# Arguments
- `retriever`: The retrieval method to use. Default is `SimpleRetriever`.
- `index`: The index that holds the chunks and sources to be retrieved from.
- `question`: The question to be used for the retrieval.
- `verbose`: If `>0`, it prints out verbose logging. Default is `1`.
- `top_k`: The TOTAL number of closest chunks to return from `find_closest`. Default is `100`.
   If there are multiple rephrased questions, the number of chunks per each item will be `top_k ÷ number_of_rephrased_questions`.
- `top_n`: The TOTAL number of most relevant chunks to return for the context (from `rerank` step). Default is `5`.
- `api_kwargs`: Additional keyword arguments to be passed to the API calls (shared by all `ai*` calls).
- `rephraser`: Transform the question into one or more questions. Default is `retriever.rephraser`.
- `rephraser_kwargs`: Additional keyword arguments to be passed to the rephraser.
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
- `cost_tracker`: An atomic counter to track the cost of the retrieval. Default is `Threads.Atomic{Float64}(0.0)`.
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
        top_k, finder_kwargs_...)

    ## Tagging - if you provide them explicitly, use tagger `PassthroughTagger` and `tagger_kwargs = (;tags = ...)`
    tagger_kwargs_ = isempty(api_kwargs) ? tagger_kwargs :
                     merge(tagger_kwargs, (; api_kwargs))
    tags = get_tags(tagger, rephrased_questions; verbose = (verbose > 1),
        cost_tracker, tagger_kwargs_...)

    filter_kwargs_ = isempty(api_kwargs) ? filter_kwargs :
                     merge(filter_kwargs, (; api_kwargs))
    tag_candidates = find_tags(filter, index, tags; filter_kwargs_...)

    ## Combine the two sets of candidates, looks for intersection (hard filter)!
    filtered_candidates = isnothing(tag_candidates) ? emb_candidates :
                          (emb_candidates & tag_candidates)

    ## Reranking
    reranker_kwargs_ = isempty(api_kwargs) ? reranker_kwargs :
                       merge(reranker_kwargs, (; api_kwargs))
    reranked_candidates = rerank(reranker, index, question, filtered_candidates;
        top_n, verbose = (verbose > 1), cost_tracker, reranker_kwargs_...)

    ## Return
    result = RAGResult(;
        question,
        answer = nothing,
        rephrased_questions,
        refined_answer = nothing,
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