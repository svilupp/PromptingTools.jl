# stub to be replaced within the package extension
function _normalize end

"""
    airag(index::AbstractChunkIndex, rag_template::Symbol = :RAGAnswerFromContext;
        question::AbstractString,
        top_k::Int = 3,
        tag_filter::Union{Symbol, Vector{String}, Regex, Nothing} = :auto,
        rerank_strategy::RerankingStrategy = Passthrough(),
        model_embedding::String = PT.MODEL_EMBEDDING, model_chat::String = PT.MODEL_CHAT,
        model_metadata::String = PT.MODEL_CHAT,
        metadata_template::Symbol = :RAGExtractMetadataShort,
        chunks_window_margin::Tuple{Int, Int} = (1, 1),
        return_context::Bool = false, verbose::Bool = true,
        api_kwargs::NamedTuple = NamedTuple(),
        kwargs...)

Generates a response for a given question using a Retrieval-Augmented Generation (RAG) approach. 

The function selects relevant chunks from an `ChunkIndex`, optionally filters them based on metadata tags, reranks them, and then uses these chunks to construct a context for generating a response.

# Arguments
- `index::AbstractChunkIndex`: The chunk index to search for relevant text.
- `rag_template::Symbol`: Template for the RAG model, defaults to `:RAGAnswerFromContext`.
- `question::AbstractString`: The question to be answered.
- `top_k::Int`: Number of top candidates to retrieve based on embedding similarity.
- `tag_filter::Union{Symbol, Vector{String}, Regex}`: Mechanism for filtering chunks based on tags (either automatically detected, specific tags, or a regex pattern). Disabled by setting to `nothing`.
- `rerank_strategy::RerankingStrategy`: Strategy for reranking the retrieved chunks.
- `model_embedding::String`: Model used for embedding the question, default is `PT.MODEL_EMBEDDING`.
- `model_chat::String`: Model used for generating the final response, default is `PT.MODEL_CHAT`.
- `model_metadata::String`: Model used for extracting metadata, default is `PT.MODEL_CHAT`.
- `metadata_template::Symbol`: Template for the metadata extraction process from the question, defaults to: `:RAGExtractMetadataShort`
- `chunks_window_margin::Tuple{Int,Int}`: The window size around each chunk to consider for context building.
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
"""
function airag(index::AbstractChunkIndex, rag_template::Symbol = :RAGAnswerFromContext;
        question::AbstractString,
        top_k::Int = 3,
        tag_filter::Union{Symbol, Vector{String}, Regex, Nothing} = :auto,
        rerank_strategy::RerankingStrategy = Passthrough(),
        model_embedding::String = PT.MODEL_EMBEDDING, model_chat::String = PT.MODEL_CHAT,
        model_metadata::String = PT.MODEL_CHAT,
        metadata_template::Symbol = :RAGExtractMetadataShort,
        chunks_window_margin::Tuple{Int, Int} = (1, 1),
        return_context::Bool = false, verbose::Bool = true,
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
    emb_candidates = find_closest(index, question_emb; top_k)

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
    reranked_candidates = rerank(rerank_strategy, index, question, filtered_candidates)

    ## Build the context
    context = String[]
    for (i, position) in enumerate(reranked_candidates.positions)
        ## Add surrounding chunks if they are from the same source (from `chunks_window_margin`)
        chunks_ = chunks(index)[max(1, position - chunks_window_margin[1]):min(end,
            position + chunks_window_margin[2])]
        is_same_source = sources(index)[max(1, position - chunks_window_margin[1]):min(end,
            position + chunks_window_margin[2])] .== sources(index)[position]
        # add the ranking number, eg, 1. Context #1
        push!(context, "$(i). $(join(chunks_[is_same_source], "\n"))")
    end
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