# stub to be replaced within the package extension
function _normalize end

"""
    build_context(index::AbstractChunkIndex, reranked_candidates::CandidateChunks; chunks_window_margin::Tuple{Int, Int}) -> Vector{String}

Build context strings for each position in `reranked_candidates` considering a window margin around each position.

# Arguments
- `reranked_candidates::CandidateChunks`: Candidate chunks which contain positions to extract context from.
- `index::ChunkIndex`: The index containing chunks and sources.
- `chunks_window_margin::Tuple{Int, Int}`: A tuple indicating the margin (before, after) around each position to include in the context. 
  Defaults to `(1,1)`, which means 1 preceding and 1 suceeding chunk will be included. With `(0,0)`, only the matching chunks will be included.

# Returns
- `Vector{String}`: A vector of context strings, each corresponding to a position in `reranked_candidates`.

# Examples
```julia
index = ChunkIndex(...)  # Assuming a proper index is defined
candidates = CandidateChunks(index.id, [2, 4], [0.1, 0.2])
context = build_context(index, candidates; chunks_window_margin=(0, 1)) # include only one following chunk for each matching chunk
```
"""
function build_context(index::AbstractChunkIndex, reranked_candidates::CandidateChunks;
        chunks_window_margin::Tuple{Int, Int} = (1, 1))
    @assert chunks_window_margin[1] >= 0&&chunks_window_margin[2] >= 0 "Both `chunks_window_margin` values must be non-negative"
    context = String[]
    for (i, position) in enumerate(reranked_candidates.positions)
        chunks_ = chunks(index)[max(1, position - chunks_window_margin[1]):min(end,
            position + chunks_window_margin[2])]
        is_same_source = sources(index)[max(1, position - chunks_window_margin[1]):min(end,
            position + chunks_window_margin[2])] .== sources(index)[position]
        push!(context, "$(i). $(join(chunks_[is_same_source], "\n"))")
    end
    return context
end

"""
    airag(index::AbstractChunkIndex, rag_template::Symbol = :RAGAnswerFromContext;
        question::AbstractString,
        top_k::Int = 100, top_n::Int = 5, minimum_similarity::AbstractFloat = -1.0,
        tag_filter::Union{Symbol, Vector{String}, Regex, Nothing} = :auto,
        rerank_strategy::RerankingStrategy = Passthrough(),
        model_embedding::String = PT.MODEL_EMBEDDING, model_chat::String = PT.MODEL_CHAT,
        model_metadata::String = PT.MODEL_CHAT,
        metadata_template::Symbol = :RAGExtractMetadataShort,
        chunks_window_margin::Tuple{Int, Int} = (1, 1),
        return_context::Bool = false, verbose::Bool = true,
        rerank_kwargs::NamedTuple = NamedTuple(),
        api_kwargs::NamedTuple = NamedTuple(),
        kwargs...)

Generates a response for a given question using a Retrieval-Augmented Generation (RAG) approach. 

The function selects relevant chunks from an `ChunkIndex`, optionally filters them based on metadata tags, reranks them, and then uses these chunks to construct a context for generating a response.

# Arguments
- `index::AbstractChunkIndex`: The chunk index to search for relevant text.
- `rag_template::Symbol`: Template for the RAG model, defaults to `:RAGAnswerFromContext`.
- `question::AbstractString`: The question to be answered.
- `top_k::Int`: Number of top candidates to retrieve based on embedding similarity.
- `top_n::Int`: Number of candidates to return after reranking.
- `minimum_similarity::AbstractFloat`: Minimum similarity threshold (between -1 and 1) for filtering chunks based on embedding similarity. Defaults to -1.0.
- `tag_filter::Union{Symbol, Vector{String}, Regex}`: Mechanism for filtering chunks based on tags (either automatically detected, specific tags, or a regex pattern). Disabled by setting to `nothing`.
- `rerank_strategy::RerankingStrategy`: Strategy for reranking the retrieved chunks. Defaults to `Passthrough()`. Use `CohereRerank` for better results (requires `COHERE_API_KEY` to be set)
- `model_embedding::String`: Model used for embedding the question, default is `PT.MODEL_EMBEDDING`.
- `model_chat::String`: Model used for generating the final response, default is `PT.MODEL_CHAT`.
- `model_metadata::String`: Model used for extracting metadata, default is `PT.MODEL_CHAT`.
- `metadata_template::Symbol`: Template for the metadata extraction process from the question, defaults to: `:RAGExtractMetadataShort`
- `chunks_window_margin::Tuple{Int,Int}`: The window size around each chunk to consider for context building. See `?build_context` for more information.
- `return_context::Bool`: If `true`, returns the context used for RAG along with the response.
- `verbose::Bool`: If `true`, enables verbose logging.
- `api_kwargs`: API parameters that will be forwarded to the API calls

# Returns
- If `return_context` is `false`, returns the generated message (`msg`).
- If `return_context` is `true`, returns a tuple of the generated message (`msg`) and the RAG context (`rag_context`).

# Notes
- The function first finds the closest chunks to the question embedding, then optionally filters these based on tags. After that, it reranks the candidates and builds a context for the RAG model.
- The `tag_filter` can be used to refine the search. If set to `:auto`, it attempts to automatically determine relevant tags (if `index` has them available).
- The `chunks_window_margin` allows including surrounding chunks for richer context, considering they are from the same source.
- The function currently supports only single `ChunkIndex`. 

# Examples

Using `airag` to get a response for a question:
```julia
index = build_index(...)  # create an index
question = "How to make a barplot in Makie.jl?"
msg = airag(index, :RAGAnswerFromContext; question)

# or simply
msg = airag(index; question)
```

See also `build_index`, `build_context`, `CandidateChunks`, `find_closest`, `find_tags`, `rerank`
"""
function airag(index::AbstractChunkIndex, rag_template::Symbol = :RAGAnswerFromContext;
        question::AbstractString,
        top_k::Int = 100, top_n::Int = 5, minimum_similarity::AbstractFloat = -1.0,
        tag_filter::Union{Symbol, Vector{String}, Regex, Nothing} = :auto,
        rerank_strategy::RerankingStrategy = Passthrough(),
        model_embedding::String = PT.MODEL_EMBEDDING, model_chat::String = PT.MODEL_CHAT,
        model_metadata::String = PT.MODEL_CHAT,
        metadata_template::Symbol = :RAGExtractMetadataShort,
        chunks_window_margin::Tuple{Int, Int} = (1, 1),
        return_context::Bool = false, verbose::Bool = true,
        rerank_kwargs::NamedTuple = NamedTuple(),
        api_kwargs::NamedTuple = NamedTuple(),
        kwargs...)
    ## Note: Supports only single ChunkIndex for now
    ## Checks
    @assert !(tag_filter isa Symbol && tag_filter != :auto) "Only `:auto`, `Vector{String}`, or `Regex` are supported for `tag_filter`"
    @assert chunks_window_margin[1] >= 0&&chunks_window_margin[2] >= 0 "Both `chunks_window_margin` values must be non-negative"
    placeholders = only(aitemplates(rag_template)).variables # only one template should be found
    @assert (:question in placeholders)&&(:context in placeholders) "Provided RAG Template $(rag_template) is not suitable. It must have placeholders: `question` and `context`."

    question_emb = aiembed(question,
        _normalize;
        model = model_embedding,
        verbose, api_kwargs).content .|> Float32 # no need for Float64
    emb_candidates = find_closest(index, question_emb; top_k, minimum_similarity)

    tag_candidates = if tag_filter == :auto && !isnothing(tags(index)) &&
                        !isempty(model_metadata)
        _check_aiextract_capability(model_metadata)
        # extract metadata via LLM call
        metadata_ = try
            msg = aiextract(metadata_template; return_type = MaybeMetadataItems,
                text = question,
                instructions = "In addition to extracted items, suggest 2-3 filter keywords that could be relevant to answer this question.",
                verbose, model = model_metadata, api_kwargs)
            ## eg, ["software:::pandas", "language:::python", "julia_package:::dataframes"]
            ## we split it and take only the keyword, not the category
            metadata_extract(msg.content.items) |>
            x -> split.(x, ":::") |> x -> getindex.(x, 2)
        catch e
            String[]
        end
        find_tags(index, metadata_)
    elseif tag_filter isa Union{Vector{String}, Regex}
        find_tags(index, tag_filter)
    elseif isnothing(tag_filter)
        nothing
    else
        ## not filtering -- use all rows and ignore this
        nothing
    end

    filtered_candidates = isnothing(tag_candidates) ? emb_candidates :
                          (emb_candidates & tag_candidates)
    reranked_candidates = rerank(rerank_strategy,
        index,
        question,
        filtered_candidates;
        top_n,
        verbose = false, rerank_kwargs...)

    ## Build the context
    context = build_context(index, reranked_candidates; chunks_window_margin)

    ## LLM call
    msg = aigenerate(rag_template; question,
        context = join(context, "\n\n"), model = model_chat, verbose,
        api_kwargs,
        kwargs...)

    if return_context # for evaluation
        rag_context = RAGContext(;
            question,
            answer = msg.content,
            context,
            sources = sources(index)[reranked_candidates.positions],
            emb_candidates,
            tag_candidates,
            filtered_candidates,
            reranked_candidates)
        return msg, rag_context
    else
        return msg
    end
end