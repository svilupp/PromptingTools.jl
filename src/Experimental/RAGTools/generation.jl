
"""
    ContextEnumerator <: AbstractContextBuilder

Default method for `build_context!` method. It simply enumerates the context snippets around each position in `candidates`. When possibly, it will add surrounding chunks (from the same source).
"""
struct ContextEnumerator <: AbstractContextBuilder end

"""
    build_context(contexter::ContextEnumerator,
        index::AbstractChunkIndex, candidates::CandidateChunks;
        verbose::Bool = true,
        chunks_window_margin::Tuple{Int, Int} = (1, 1), kwargs...)

        build_context!(contexter::ContextEnumerator,
        index::AbstractChunkIndex, result::AbstractRAGResult; kwargs...)

Build context strings for each position in `candidates` considering a window margin around each position.
If mutating version is used (`build_context!`), it will use `result.reranked_candidates` to update the `result.context` field.

# Arguments
- `contexter::ContextEnumerator`: The method to use for building the context. Enumerates the snippets.
- `index::ChunkIndex`: The index containing chunks and sources.
- `candidates::CandidateChunks`: Candidate chunks which contain positions to extract context from.
- `verbose::Bool`: If `true`, enables verbose logging.
- `chunks_window_margin::Tuple{Int, Int}`: A tuple indicating the margin (before, after) around each position to include in the context. 
  Defaults to `(1,1)`, which means 1 preceding and 1 suceeding chunk will be included. With `(0,0)`, only the matching chunks will be included.

# Returns
- `Vector{String}`: A vector of context strings, each corresponding to a position in `reranked_candidates`.

# Examples
```julia
index = ChunkIndex(...)  # Assuming a proper index is defined
candidates = CandidateChunks(index.id, [2, 4], [0.1, 0.2])
context = build_context(ContextEnumerator(), index, candidates; chunks_window_margin=(0, 1)) # include only one following chunk for each matching chunk
```
"""
function build_context(contexter::ContextEnumerator,
        index::AbstractChunkIndex, candidates::CandidateChunks;
        verbose::Bool = true,
        chunks_window_margin::Tuple{Int, Int} = (1, 1), kwargs...)
    ## Checks
    @assert chunks_window_margin[1] >= 0&&chunks_window_margin[2] >= 0 "Both `chunks_window_margin` values must be non-negative"

    context = String[]
    for (i, position) in enumerate(candidates.positions)
        chunks_ = chunks(index)[max(1, position - chunks_window_margin[1]):min(end,
            position + chunks_window_margin[2])]
        ## Check if surrounding chunks are from the same source
        is_same_source = sources(index)[max(1, position - chunks_window_margin[1]):min(end,
            position + chunks_window_margin[2])] .== sources(index)[position]
        push!(context, "$(i). $(join(chunks_[is_same_source], "\n"))")
    end
    return context
end

function build_context!(contexter::AbstractContextBuilder,
        index::AbstractChunkIndex, result::AbstractRAGResult; kwargs...)
    throw(ArgumentError("Contexter $(typeof(contexter)) not implemented"))
end

# Mutating version that dispatches on the result to the underlying implementation
function build_context!(contexter::ContextEnumerator,
        index::AbstractChunkIndex, result::AbstractRAGResult; kwargs...)
    result.context = build_context(contexter, index, result.reranked_candidates; kwargs...)
    return result
end

## First step: Answerer

"""
    SimpleAnswerer <: AbstractAnswerer

Default method for `answer!` method. Generates an answer using the `aigenerate` function with the provided context and question.
"""
struct SimpleAnswerer <: AbstractAnswerer end

function answer!(
        answerer::AbstractAnswerer, index::AbstractChunkIndex, result::AbstractRAGResult;
        kwargs...)
    throw(ArgumentError("Answerer $(typeof(answerer)) not implemented"))
end

"""
    answer!(
        answerer::SimpleAnswerer, index::AbstractChunkIndex, result::AbstractRAGResult;
        model::AbstractString = PT.MODEL_CHAT, verbose::Bool = true,
        template::Symbol = :RAGAnswerFromContext,
        cost_tracker = Threads.Atomic{Float64}(0.0),
        kwargs...)

Generates an answer using the `aigenerate` function with the provided `result.context` and `result.question`.

# Returns
- Mutated `result` with `result.answer` and the full conversation saved in `result.conversations[:answer]`

# Arguments
- `answerer::SimpleAnswerer`: The method to use for generating the answer. Uses `aigenerate`.
- `index::AbstractChunkIndex`: The index containing chunks and sources.
- `result::AbstractRAGResult`: The result containing the context and question to generate the answer for.
- `model::AbstractString`: The model to use for generating the answer. Defaults to `PT.MODEL_CHAT`.
- `verbose::Bool`: If `true`, enables verbose logging.
- `template::Symbol`: The template to use for the `aigenerate` function. Defaults to `:RAGAnswerFromContext`.
- `cost_tracker`: An atomic counter to track the cost of the operation.

"""
function answer!(
        answerer::SimpleAnswerer, index::AbstractChunkIndex, result::AbstractRAGResult;
        model::AbstractString = PT.MODEL_CHAT, verbose::Bool = true,
        template::Symbol = :RAGAnswerFromContext,
        cost_tracker = Threads.Atomic{Float64}(0.0),
        kwargs...)
    ## Checks
    placeholders = only(aitemplates(template)).variables # only one template should be found
    @assert (:question in placeholders)&&(:context in placeholders) "Provided RAG Template $(template) is not suitable. It must have placeholders: `question` and `context`."
    ##
    (; context, question) = result
    conv = aigenerate(template; question,
        context = join(context, "\n\n"), model, verbose = false,
        return_all = true,
        kwargs_...)
    msg = conv[end]
    result.answer = msg.content
    result.conversation[:answer] = conv
    ## Increment the cost tracker
    Threads.atomic_add!(cost_tracker, msg.cost)
    verbose &&
        @info "Done generating the answer. Cost: \$$(round(msg.cost,digits=3))"

    return result
end

## Refine
"""
    NoRefiner <: AbstractRefiner

Default method for `refine!` method. A passthrough option that returns the `result.answer` without any changes.
"""
struct NoRefiner <: AbstractRefiner end

"""
    SimpleRefiner <: AbstractRefiner

Refines the answer using the same context previously provided via the provided prompt template.
"""
struct SimpleRefiner <: AbstractRefiner end

function refine!(
        refiner::AbstractRefiner, index::AbstractChunkIndex, result::AbstractRAGResult;
        kwargs...)
    throw(ArgumentError("Refiner $(typeof(refiner)) not implemented"))
end

"""
    refine!(
        refiner::NoRefiner, index::AbstractChunkIndex, result::AbstractRAGResult;
        kwargs...)
    
Simple no-op function for `refine`. It simply copies the `result.answer` and `result.conversations[:answer]` without any changes.
"""
function refine!(
        refiner::NoRefiner, index::AbstractChunkIndex, result::AbstractRAGResult;
        kwargs...)
    result.refined_answer = result.answer
    if haskey(result.conversations, :answer)
        result.conversations[:refined_answer] = result.conversations[:answer]
    end
    return result
end

"""
    refine!(
        refiner::SimpleRefiner, index::AbstractChunkIndex, result::AbstractRAGResult;
        kwargs...)
    
Give model a chance to refine the answer (using the same context previously provided).

# Returns
- Mutated `result` with `result.refined_answer` and the full conversation saved in `result.conversations[:refined_answer]`

# Arguments
- `refiner::SimpleRefiner`: The method to use for refining the answer. Uses `aigenerate`.
- `index::AbstractChunkIndex`: The index containing chunks and sources.
- `result::AbstractRAGResult`: The result containing the context and question to generate the answer for.
- `model::AbstractString`: The model to use for generating the answer. Defaults to `PT.MODEL_CHAT`.
- `verbose::Bool`: If `true`, enables verbose logging.
- `template::Symbol`: The template to use for the `aigenerate` function. Defaults to `:RAGExtractMetadataShort`.
- `cost_tracker`: An atomic counter to track the cost of the operation.
"""
function refine!(
        refiner::SimpleRefiner, index::AbstractChunkIndex, result::AbstractRAGResult;
        verbose::Bool = true,
        model::AbstractString = PT.MODEL_CHAT,
        template::Symbol = :RAGExtractMetadataShort,
        cost_tracker = Threads.Atomic{Float64}(0.0),
        kwargs...)
    ##
    (; answer, question, context) = result
    # TODO: add a template
    conv = aigenerate(template; question,
        context = join(context, "\n\n"), answer, model, verbose = false,
        return_all = true,
        kwargs...)
    msg = conv[end]
    result.refined_answer = msg.content
    result.conversations[:refined_answer] = conv

    ## Increment the cost
    Threads.atomic_add!(cost_tracker, msg.cost)
    verbose &&
        @info "Done refining the answer. Cost: \$$(round(msg.cost,digits=3))"

    return result
end

"""
    NoPostprocessor <: AbstractPostprocessor

Default method for `postprocess!` method. A passthrough option that returns the `result` without any changes.

Overload this method to add custom postprocessing steps, eg, logging, saving conversations, etc.
"""
struct NoPostprocessor <: AbstractPostprocessor end

function postprocess!(::AbstractPostprocessor, index::AbstractChunkIndex,
        result::AbstractRAGResult; kwargs...)
    throw(ArgumentError("Postprocessor $(typeof(postprocessor)) not implemented"))
end

function postprocess!(
        ::NoPostprocessor, index::AbstractChunkIndex, result::AbstractRAGResult; kwargs...)
    return result
end

### Overall types for `generate`
"""
    SimpleGenerator <: AbstractGenerator

Default implementation for `generate`. It simply enumerates context snippets and runs `aigenerate` (no refinement).

It uses `ContextEnumerator`, `SimpleAnswerer`, `NoRefiner`, and `NoPostprocessor` as default `contexter`, `answerer`, `refiner`, and `postprocessor`.
"""
@kwdef mutable struct SimpleGenerator <: AbstractGenerator
    contexter::AbstractContextBuilder = ContextEnumerator()
    answerer::AbstractAnswerer = SimpleAnswerer()
    refiner::AbstractRefiner = NoRefiner()
    postprocessor::AbstractPostprocessor = NoPostprocessor()
end

"""
    AdvancedGenerator <: AbstractGenerator

Default implementation for `generate!`. It simply enumerates context snippets and runs `aigenerate` (no refinement).

It uses `ContextEnumerator`, `SimpleAnswerer`, `SimpleRefiner`, and `NoPostprocessor` as default `contexter`, `answerer`, `refiner`, and `postprocessor`.
"""
@kwdef mutable struct AdvancedGenerator <: AbstractGenerator
    contexter::AbstractContextBuilder = ContextEnumerator()
    answerer::AbstractAnswerer = SimpleAnswerer()
    refiner::AbstractRefiner = SimpleRefiner()
    postprocessor::AbstractPostprocessor = NoPostprocessor()
end

"""
    generate!(
        generator::AbstractGenerator, index::AbstractChunkIndex, result::AbstractRAGResult;
        verbose::Integer = 1,
        api_kwargs::NamedTuple = NamedTuple(),
        contexter::AbstractContextBuilder = generator.contexter,
        contexter_kwargs::NamedTuple = NamedTuple(),
        answerer::AbstractAnswerer = generator.answerer,
        answerer_kwargs::NamedTuple = NamedTuple(),
        refiner::AbstractRefiner = generator.refiner,
        refiner_kwargs::NamedTuple = NamedTuple(),
        postprocessor::AbstractPostprocessor = generator.postprocessor,
        postprocessor_kwargs::NamedTuple = NamedTuple(),
        cost_tracker = Threads.Atomic{Float64}(0.0),
        kwargs...)

Generate the response using the provided `generator` and the `index` and `result`.

Returns the mutated `result` with the `result.refined_answer` and the full conversation saved in `result.conversations[:refined_answer]`.

`refiner` step allows the LLM to critique itself and refine its own answer.
`postprocessor` step allows for additional processing of the answer, eg, logging, saving conversations, etc.

# Arguments
- `generator::AbstractGenerator`: The generator to use for generating the answer. Uses `aigenerate`.
- `index::AbstractChunkIndex`: The index containing chunks and sources.
- `result::AbstractRAGResult`: The result containing the context and question to generate the answer for.
- `verbose::Integer`: If >0, enables verbose logging.
- `api_kwargs::NamedTuple`: API parameters that will be forwarded to ALL of the API calls (`aiembed`, `aigenerate`, and `aiextract`).
- `contexter::AbstractContextBuilder`: The method to use for building the context. Defaults to `generator.contexter`.
- `contexter_kwargs::NamedTuple`: API parameters that will be forwarded to the `contexter` call.
- `answerer::AbstractAnswerer`: The method to use for generating the answer. Defaults to `generator.answerer`.
- `answerer_kwargs::NamedTuple`: API parameters that will be forwarded to the `answerer` call. Examples:
   - `model`: The model to use for generating the answer. Defaults to `PT.MODEL_CHAT`.
   - `template`: The template to use for the `aigenerate` function. Defaults to `:RAGAnswerFromContext`.
- `refiner::AbstractRefiner`: The method to use for refining the answer. Defaults to `generator.refiner`.
- `refiner_kwargs::NamedTuple`: API parameters that will be forwarded to the `refiner` call.
- `postprocessor::AbstractPostprocessor`: The method to use for postprocessing the answer. Defaults to `generator.postprocessor`.
- `postprocessor_kwargs::NamedTuple`: API parameters that will be forwarded to the `postprocessor` call.
- `cost_tracker`: An atomic counter to track the total cost of the operations.

"""
function generate!(
        generator::AbstractGenerator, index::AbstractChunkIndex, result::AbstractRAGResult;
        verbose::Integer = 1,
        api_kwargs::NamedTuple = NamedTuple(),
        contexter::AbstractContextBuilder = generator.contexter,
        contexter_kwargs::NamedTuple = NamedTuple(),
        answerer::AbstractAnswerer = generator.answerer,
        answerer_kwargs::NamedTuple = NamedTuple(),
        refiner::AbstractRefiner = generator.refiner,
        refiner_kwargs::NamedTuple = NamedTuple(),
        postprocessor::AbstractPostprocessor = generator.postprocessor,
        postprocessor_kwargs::NamedTuple = NamedTuple(),
        cost_tracker = Threads.Atomic{Float64}(0.0),
        kwargs...)

    ## Build the context
    contexter_kwargs_ = isempty(api_kwargs) ? contexter_kwargs :
                        merge(contexter_kwargs, (; api_kwargs))
    result = build_context!(contexter,
        index, result; verbose = (verbose > 1), cost_tracker, contexter_kwargs_...)

    ## LLM call to answer
    answerer_kwargs_ = isempty(api_kwargs) ? answerer_kwargs :
                       merge(answerer_kwargs, (; api_kwargs))
    result = answer!(
        answerer, index, result; verbose = (verbose > 1), cost_tracker, answerer_kwargs_...)

    ## Refine the answer
    refiner_kwargs_ = isempty(api_kwargs) ? refiner_kwargs :
                      merge(refiner_kwargs, (; api_kwargs))
    result = refine!(
        refiner, index, result; verbose = (verbose > 1), cost_tracker, refiner_kwargs_...)

    ## Postprocessing
    postprocessor_kwargs_ = isempty(api_kwargs) ? postprocessor_kwargs :
                            merge(postprocessor_kwargs, (; api_kwargs))
    result = postprocess!(postprocessor, index, result; verbose = (verbose > 1),
        cost_tracker, postprocessor_kwargs_...)

    return result # mutated result
end

# Set default behavior
DEFAULT_GENERATOR = SimpleGenerator()
function generate!(index::AbstractChunkIndex, result::AbstractRAGResult; kwargs...)
    return generate!(DEFAULT_GENERATOR, index, result; kwargs...)
end

### Overarching

"""
    RAGConfig <: AbstractRAGConfig

Default configuration for RAG. It uses `SimpleIndexer`, `SimpleRetriever`, and `SimpleGenerator` as default components.

To customize the components, replace corresponding fields for each step of the RAG pipeline (eg, use `subtypes(AbstractIndexBuilder)` to find the available options).
"""
@kwdef mutable struct RAGConfig <: AbstractRAGConfig
    indexer::AbstractIndexBuilder = SimpleIndexer()
    retriever::AbstractRetriever = SimpleRetriever()
    generator::AbstractGenerator = SimpleGenerator()
end

"""
    airag(index::AbstractChunkIndex, rag_template::Symbol = :RAGAnswerFromContext;
        question::AbstractString,
        top_k::Int = 100, top_n::Int = 5, minimum_similarity::AbstractFloat = -1.0,
        tag_filter::Union{Symbol, Vector{String}, Regex, Nothing} = :auto,
        rerank_strategy::AbstractReranker = Passthrough(),
        model_embedding::String = PT.MODEL_EMBEDDING, model_chat::String = PT.MODEL_CHAT,
        model_metadata::String = PT.MODEL_CHAT,
        metadata_template::Symbol = :RAGExtractMetadataShort,
        chunks_window_margin::Tuple{Int, Int} = (1, 1),
        return_details::Bool = false, verbose::Bool = true,
        rerank_kwargs::NamedTuple = NamedTuple(),
        api_kwargs::NamedTuple = NamedTuple(),
        aiembed_kwargs::NamedTuple = NamedTuple(),
        aigenerate_kwargs::NamedTuple = NamedTuple(),
        aiextract_kwargs::NamedTuple = NamedTuple(),
        kwargs...)

Lightweight wrapper around functions `retrieve` and `generate` to perform Retrieval-Augmented Generation (RAG).

It means it first finds the relevant chunks in `index` for the `question` and then sends these chunks to the AI model to help with generating a response to the `question`.

To customize the components, replace the types (`retriever`, `generator`) of the corresponding step of the RAG pipeline.

Eg, use `subtypes(AbstractRetriever)` to find the available options.

The function selects relevant chunks from an `ChunkIndex`, optionally filters them based on metadata tags, reranks them, and then uses these chunks to construct a context for generating a response.

# Arguments
- `index::AbstractChunkIndex`: The chunk index to search for relevant text.
- `rag_template::Symbol`: Template for the RAG model, defaults to `:RAGAnswerFromContext`.
- `question::AbstractString`: The question to be answered.
- `top_k::Int`: Number of top candidates to retrieve based on embedding similarity.
- `top_n::Int`: Number of candidates to return after reranking.
- `minimum_similarity::AbstractFloat`: Minimum similarity threshold (between -1 and 1) for filtering chunks based on embedding similarity. Defaults to -1.0.
- `tag_filter::Union{Symbol, Vector{String}, Regex}`: Mechanism for filtering chunks based on tags (either automatically detected, specific tags, or a regex pattern). Disabled by setting to `nothing`.
- `rerank_strategy::AbstractReranker`: Strategy for reranking the retrieved chunks. Defaults to `Passthrough()`. Use `CohereRerank` for better results (requires `COHERE_API_KEY` to be set)
- `model_embedding::String`: Model used for embedding the question, default is `PT.MODEL_EMBEDDING`.
- `model_chat::String`: Model used for generating the final response, default is `PT.MODEL_CHAT`.
- `model_metadata::String`: Model used for extracting metadata, default is `PT.MODEL_CHAT`.
- `metadata_template::Symbol`: Template for the metadata extraction process from the question, defaults to: `:RAGExtractMetadataShort`
- `chunks_window_margin::Tuple{Int,Int}`: The window size around each chunk to consider for context building. See `?build_context` for more information.
- `return_details::Bool`: If `true`, returns the details used for RAG along with the response.
- `verbose::Bool`: If `true`, enables verbose logging.
- `api_kwargs`: API parameters that will be forwarded to ALL of the API calls (`aiembed`, `aigenerate`, and `aiextract`).
- `aiembed_kwargs`: API parameters that will be forwarded to the `aiembed` call. If you need to provide `api_kwargs` only to this function, simply add them as a keyword argument, eg, `aiembed_kwargs = (; api_kwargs = (; x=1))`.
- `aigenerate_kwargs`: API parameters that will be forwarded to the `aigenerate` call. If you need to provide `api_kwargs` only to this function, simply add them as a keyword argument, eg, `aigenerate_kwargs = (; api_kwargs = (; temperature=0.3))`.
- `aiextract_kwargs`: API parameters that will be forwarded to the `aiextract` call for the metadata extraction.

# Returns
- If `return_details` is `false`, returns the generated message (`msg`).
- If `return_details` is `true`, returns a tuple of the generated message (`msg`) and the `RAGDetails` for context (`rag_details`).

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

To understand the details of the RAG process, use `return_details=true`
```julia
msg, details = airag(index; question, return_details = true)
# details is a RAGDetails object with all the internal steps of the `airag` function
```

You can also pretty-print `details` to highlight generated text vs text that is supported by context.
It also includes annotations of which context was used for each part of the response (where available).
```julia
PT.pprint(details)
```

See also `build_index`, `build_context`, `CandidateChunks`, `find_closest`, `find_tags`, `rerank`, `annotate_support`
"""
function airag(cfg::AbstractRAGConfig, index::AbstractChunkIndex;
        question::AbstractString,
        verbose::Integer = 1, return_all::Bool = false,
        api_kwargs::NamedTuple = NamedTuple(),
        retriever::AbstractRetriever = cfg.retriever,
        retriever_kwargs::NamedTuple = NamedTuple(),
        generator::AbstractGenerator = cfg.generator,
        generator_kwargs::NamedTuple = NamedTuple(),
        cost_tracker = Threads.Atomic{Float64}(0.0))

    ## Retrieve top context
    retriever_kwargs_ = isempty(api_kwargs) ? retriever_kwargs :
                        merge(retriever_kwargs, (; api_kwargs))
    result = retrieve(
        retriever, index, question; verbose, cost_tracker, retriever_kwargs_...)

    ## Generate the response
    generator_kwargs_ = isempty(api_kwargs) ? generator_kwargs :
                        merge(generator_kwargs, (; api_kwargs))
    result = generate!(generator, index, result; verbose, cost_tracker,
        generator_kwargs_...)

    verbose > 0 &&
        @info "Done with RAG. Total cost: \$$(round(cost_tracker[], digits=3))"

    ## Return `RAGResult` or more user-friendly `AIMessage`
    output = if return_all
        result
    elseif haskey(result.conversations, :refined_answer) &&
           !isempty(result.conversations[:refined_answer])
        result.conversations[:refined_answer][end]
    elseif haskey(result.conversations, :answer) &&
           !isempty(result.conversations[:answer])
        result.conversations[:answer][end]
    else
        throw(ArgumentError("No conversation found in the result"))
    end
    return output
end

# Default behavior
const DEFAULT_RAG_CONFIG = RAGConfig()
function airag(index::AbstractChunkIndex; question::AbstractString, kwargs...)
    return airag(DEFAULT_RAG_CONFIG, index; question, kwargs...)
end

# Special method to pretty-print the airag results
function PT.pprint(io::IO, airag_result::Tuple{PT.AIMessage, AbstractRAGResult},
        text_width::Int = displaysize(io)[2])
    rag_details = airag_result[2]
    pprint(io, rag_details; text_width)
end