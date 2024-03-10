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
    TagFilter <: AbstractTagFilter

Finds the chunks that have the specified tag(s).
"""
struct TagFilter <: AbstractTagFilter end

### Functions

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

"""
    find_closest(finder::CosineSimilarity, emb::AbstractMatrix{<:Real},
        query_emb::AbstractVector{<:Real};
        top_k::Int = 100, minimum_similarity::AbstractFloat = -1.0)

Finds the indices of chunks (represented by embeddings in `emb`) that are closest (in cosine similarity for `CosineSimilarity()`) to query embedding (`query_emb`). 

If `minimum_similarity` is provided, only indices with similarity greater than or equal to it are returned. 
Similarity can be between -1 and 1 (-1 = completely opposite, 1 = exactly the same).

`finder` is the logic used for the similarity search. Default is `CosineSimilarity`.

Returns only `top_k` closest indices.
"""
function find_closest(
        finder::CosineSimilarity, emb::AbstractMatrix{<:Real},
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

function find_closest(
        finder::AbstractSimilarityFinder, index::AbstractChunkIndex,
        query_emb::AbstractVector{<:Real};
        top_k::Int = 100, minimum_similarity::AbstractFloat = -1.0)
    isnothing(embeddings(index)) && CandidateChunks(; index_id = index.id)
    positions, distances = find_closest(finder, embeddings(index),
        query_emb;
        top_k,
        minimum_similarity)
    return CandidateChunks(index.id, positions, Float32.(distances))
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

"""
    find_tags(method::AbstractTagFilter = TagFilter(), index::AbstractChunkIndex,
        tag::Union{AbstractString, Regex})

    find_tags(method::AbstractTagMatcher, index::AbstractChunkIndex,
        tags::Vector{<:AbstractString})

Finds the indices of chunks (represented by tags in `index`) that have the specified `tag` or `tags`.
"""
function find_tags(method::AbstractTagFilter, index::AbstractChunkIndex,
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

function find_tags(method::AbstractTagFilter, index::AbstractChunkIndex,
        tags::Vector{<:AbstractString})
    pos = [find_tags(method, index, tag).positions for tag in tags] |>
          Base.Splat(vcat) |> unique |> x -> convert(Vector{Int}, x)
    return CandidateChunks(index.id, pos, ones(Float32, length(pos)))
end

function find_tags(method::NoTagFilter, index::AbstractChunkIndex,
        tags)
    return CandidateChunks(
        index.id, 1:length(index.chunks), ones(Float32, length(index.chunks)))
end

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
        index::AbstractDocumentIndex, args...; kwargs...)
    throw(ArgumentError("Not implemented yet"))
end

function rerank(reranker::NoReranker,
        index,
        question,
        candidate_chunks;
        top_n::Integer = length(candidate_chunks),
        kwargs...)
    # Since this is a Passthrough strategy, it returns the candidate_chunks unchanged
    return first(candidate_chunks, top_n)
end

"""
    rerank(reranker::CohereReranker, index::AbstractChunkIndex, question,
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
function rerank(reranker::CohereReranker, index::AbstractChunkIndex, question,
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

### Overall types for `retrieve`
"""
    SimpleRetriever <: AbstractRetriever

Default implementation for `retrieve`. It does a simple similarity search via `CosineSimilarity` and returns the results.

It uses `NoRephraser`, `CosineSimilarity`, `NoTagFilter` and `NoReranker` as default `rephraser`, `finder`, `filter`, and `reranker`.
"""
@kwdef mutable struct SimpleRetriever <: AbstractRetriever
    rephraser::AbstractRephraser = NoRephraser()
    finder::AbstractSimilarityFinder = CosineSimilarity()
    filter::AbstractTagFilter = NoTagFilter()
    reranker::AbstractReranker = NoReranker()
end

"""
    AdvancedRetriever <: AbstractRetriever

Dispatch for `retrieve` with advanced retrieval methods to improve result quality.
Compared to SimpleRetriever, it adds rephrasing the query and reranking the results.

It uses `NoRephraser`, `CosineSimilarity`, `NoTagFilter` and `NoReranker` as default `rephraser`, `finder`, `filter`, and `reranker`.
"""
@kwdef mutable struct AdvancedRetriever <: AbstractRetriever
    rephraser::AbstractRephraser = SimpleRephraser()
    finder::AbstractSimilarityFinder = CosineSimilarity()
    filter::AbstractTagFilter = NoTagFilter()
    reranker::AbstractReranker = CohereReranker()
end

function retrieve(retriever::AbstractRetriever,
        index::AbstractChunkIndex,
        question::AbstractString;
        top_k::Integer = 100,
        tag_filter::Union{Nothing, AbstractVector{<:AbstractString}} = nothing,
        verbose::Bool = false,
        kwargs...)
    ## Rephrase
    rephrased_questions = rephrase(retriever.rephraser, question)
    verbose && @info "Rephrased questions: $(rephrased_questions)"
    ## Embed
    # TODO: handle multiple rephrased questions as output
    emb_candidates = CandidateChunks[]
    for rq in rephrased_questions
        emb_candidates = vcat(emb_candidates,
            find_closest(retriever.similarity_searcher, index, rq;
                top_k = top_k, kwargs...))
    end
    verbose && @info "Emb candidates: $(emb_candidates)"
    ## Tag
    tag_candidates = if isnothing(tag_filter)
        nothing
    else
        find_tags(retriever.tag_matcher, index, tag_filter)
    end
    verbose && @info "Tag candidates: $(tag_candidates)"
    ## Filter
    filtered_candidates = if isnothing(tag_candidates)
        emb_candidates
    else
        filter_candidates(emb_candidates, tag_candidates)
    end
    verbose && @info "Filtered candidates: $(filtered_candidates)"
    return filtered_candidates
end
