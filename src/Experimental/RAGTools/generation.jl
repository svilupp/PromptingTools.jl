
"""
    ContextEnumerator <: AbstractContextBuilder

Default method for `build_context!` method. It simply enumerates the context snippets around each position in `candidates`. When possibly, it will add surrounding chunks (from the same source).
"""
struct ContextEnumerator <: AbstractContextBuilder end

"""
    build_context(contexter::ContextEnumerator,
        index::AbstractDocumentIndex, candidates::AbstractCandidateChunks;
        verbose::Bool = true,
        chunks_window_margin::Tuple{Int, Int} = (1, 1), kwargs...)

        build_context!(contexter::ContextEnumerator,
        index::AbstractDocumentIndex, result::AbstractRAGResult; kwargs...)

Build context strings for each position in `candidates` considering a window margin around each position.
If mutating version is used (`build_context!`), it will use `result.reranked_candidates` to update the `result.context` field.

# Arguments
- `contexter::ContextEnumerator`: The method to use for building the context. Enumerates the snippets.
- `index::AbstractDocumentIndex`: The index containing chunks and sources.
- `candidates::AbstractCandidateChunks`: Candidate chunks which contain positions to extract context from.
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
        index::AbstractDocumentIndex,
        candidates::AbstractCandidateChunks;
        verbose::Bool = true,
        chunks_window_margin::Tuple{Int, Int} = (1, 1), kwargs...)
    ## Checks
    @assert chunks_window_margin[1] >= 0&&chunks_window_margin[2] >= 0 "Both `chunks_window_margin` values must be non-negative"

    context = String[]
    for (i, position) in enumerate(positions(candidates))
        ## select the right index
        id = candidates isa MultiCandidateChunks ? candidates.index_ids[i] :
             candidates.index_id
        index_ = index isa AbstractChunkIndex ? index : index[id]
        isnothing(index_) && continue
        ## Refer to parent in case index is a SubChunkIndex (bc positions refer to the underlying parent chunks)
        chunks_ = chunks(parent(index_))[
            max(1, position - chunks_window_margin[1]):min(end,
            position + chunks_window_margin[2])]
        ## Check if surrounding chunks are from the same source
        is_same_source = sources(parent(index_))[
            max(1, position - chunks_window_margin[1]):min(end,
            position + chunks_window_margin[2])] .== sources(parent(index_))[position]
        push!(context, "$(i). $(join(chunks_[is_same_source], "\n"))")
    end
    return context
end

function build_context(contexter::ContextEnumerator,
        index::AbstractManagedIndex,
        candidates::AbstractCandidateWithChunks;
        verbose::Bool = true,
        chunks_window_margin::Tuple{Int, Int} = (1, 1), kwargs...)
    ## Checks
    @assert chunks_window_margin[1] >= 0&&chunks_window_margin[2] >= 0 "Both `chunks_window_margin` values must be non-negative"

    context = String[]
    for (i, position) in enumerate(positions(candidates))
        ## select the right index
        id = candidates isa MultiCandidateChunks ? candidates.index_ids[i] :
             candidates.index_id
        index_ = index isa AbstractChunkIndex ? index : index[id]
        isnothing(index_) && continue

        chunks_ = chunks(candidates)[
            max(1, position - chunks_window_margin[1]):min(end,
            position + chunks_window_margin[2])]
        ## Check if surrounding chunks are from the same source
        is_same_source = sources(candidates)[
            max(1, position - chunks_window_margin[1]):min(end,
            position + chunks_window_margin[2])] .== sources(candidates)[position]
        push!(context, "$(i). $(join(chunks_[is_same_source], "\n"))")
    end
    return context
end

function build_context!(contexter::AbstractContextBuilder,
        index::AbstractDocumentIndex, result::AbstractRAGResult; kwargs...)
    throw(ArgumentError("Contexter $(typeof(contexter)) not implemented"))
end

# Mutating version that dispatches on the result to the underlying implementation
function build_context!(contexter::ContextEnumerator,
        index::AbstractDocumentIndex, result::AbstractRAGResult; kwargs...)
    result.context = build_context(contexter, index, result.reranked_candidates; kwargs...)
    return result
end
function build_context!(contexter::ContextEnumerator,
        index::AbstractManagedIndex, result::AbstractRAGResult; kwargs...)
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
        answerer::AbstractAnswerer, index::AbstractDocumentIndex, result::AbstractRAGResult;
        kwargs...)
    throw(ArgumentError("Answerer $(typeof(answerer)) not implemented"))
end

# TODO: update docs signature
"""
    answer!(
        answerer::SimpleAnswerer, index::AbstractDocumentIndex, result::AbstractRAGResult;
        model::AbstractString = PT.MODEL_CHAT, verbose::Bool = true,
        template::Symbol = :RAGAnswerFromContext,
        cost_tracker = Threads.Atomic{Float64}(0.0),
        kwargs...)

Generates an answer using the `aigenerate` function with the provided `result.context` and `result.question`.

# Returns
- Mutated `result` with `result.answer` and the full conversation saved in `result.conversations[:answer]`

# Arguments
- `answerer::SimpleAnswerer`: The method to use for generating the answer. Uses `aigenerate`.
- `index::AbstractDocumentIndex`: The index containing chunks and sources.
- `result::AbstractRAGResult`: The result containing the context and question to generate the answer for.
- `model::AbstractString`: The model to use for generating the answer. Defaults to `PT.MODEL_CHAT`.
- `verbose::Bool`: If `true`, enables verbose logging.
- `template::Symbol`: The template to use for the `aigenerate` function. Defaults to `:RAGAnswerFromContext`.
- `cost_tracker`: An atomic counter to track the cost of the operation.

"""
function answer!(
        answerer::SimpleAnswerer, index::AbstractDocumentIndex, result::AbstractRAGResult;
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
        kwargs...)
    msg = conv[end]
    result.answer = strip(msg.content)
    result.conversations[:answer] = conv
    ## Increment the cost tracker
    Threads.atomic_add!(cost_tracker, msg.cost)
    verbose &&
        @info "Done generating the answer. Cost: \$$(round(msg.cost,digits=3))"

    return result
end
function answer!(
        answerer::SimpleAnswerer, index::AbstractManagedIndex, result::AbstractRAGResult;
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
        kwargs...)
    msg = conv[end]
    result.answer = strip(msg.content)
    result.conversations[:answer] = conv
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

Refines the answer using the same context previously provided via the provided prompt template. A method for `refine!`.
"""
struct SimpleRefiner <: AbstractRefiner end

"""
    TavilySearchRefiner <: AbstractRefiner

Refines the answer by executing a web search using the Tavily API. This method aims to enhance the answer's accuracy and relevance by incorporating information retrieved from the web. A method for `refine!`.
"""
struct TavilySearchRefiner <: AbstractRefiner end

function refine!(
        refiner::AbstractRefiner, index::Union{AbstractDocumentIndex, AbstractManagedIndex}, result::AbstractRAGResult;
        kwargs...)
    throw(ArgumentError("Refiner $(typeof(refiner)) not implemented"))
end


# TODO: update docs signature
"""
    refine!(
        refiner::NoRefiner, index::AbstractChunkIndex, result::AbstractRAGResult;
        kwargs...)
    
Simple no-op function for `refine!`. It simply copies the `result.answer` and `result.conversations[:answer]` without any changes.
"""
function refine!(
        refiner::NoRefiner, index::Union{AbstractDocumentIndex, AbstractManagedIndex}, result::AbstractRAGResult;
        kwargs...)
    result.final_answer = result.answer
    if haskey(result.conversations, :answer)
        result.conversations[:final_answer] = result.conversations[:answer]
    end
    return result
end


# TODO: update docs signature
"""
    refine!(
        refiner::SimpleRefiner, index::AbstractDocumentIndex, result::AbstractRAGResult;
        verbose::Bool = true,
        model::AbstractString = PT.MODEL_CHAT,
        template::Symbol = :RAGAnswerRefiner,
        cost_tracker = Threads.Atomic{Float64}(0.0),
        kwargs...)
    
Give model a chance to refine the answer (using the same or different context than previously provided).

This method uses the same context as the original answer, however, it can be modified to do additional retrieval and use a different context.

# Returns
- Mutated `result` with `result.final_answer` and the full conversation saved in `result.conversations[:final_answer]`

# Arguments
- `refiner::SimpleRefiner`: The method to use for refining the answer. Uses `aigenerate`.
- `index::AbstractDocumentIndex`: The index containing chunks and sources.
- `result::AbstractRAGResult`: The result containing the context and question to generate the answer for.
- `model::AbstractString`: The model to use for generating the answer. Defaults to `PT.MODEL_CHAT`.
- `verbose::Bool`: If `true`, enables verbose logging.
- `template::Symbol`: The template to use for the `aigenerate` function. Defaults to `:RAGAnswerRefiner`.
- `cost_tracker`: An atomic counter to track the cost of the operation.
"""
function refine!(
        refiner::SimpleRefiner, index::Union{AbstractDocumentIndex, AbstractManagedIndex}, result::AbstractRAGResult;
        verbose::Bool = true,
        model::AbstractString = PT.MODEL_CHAT,
        template::Symbol = :RAGAnswerRefiner,
        cost_tracker = Threads.Atomic{Float64}(0.0),
        kwargs...)
    ## Checks
    placeholders = only(aitemplates(template)).variables # only one template should be found
    @assert (:query in placeholders)&&(:answer in placeholders) &&
            (:context in placeholders) "Provided RAG Template $(template) is not suitable. It must have placeholders: `query`, `answer` and `context`."
    ##
    (; answer, question, context) = result
    conv = aigenerate(template; query = question,
        context = join(context, "\n\n"), answer, model, verbose = false,
        return_all = true,
        kwargs...)
    msg = conv[end]
    result.final_answer = strip(msg.content)
    result.conversations[:final_answer] = conv

    ## Increment the cost
    Threads.atomic_add!(cost_tracker, msg.cost)
    verbose &&
        @info "Done refining the answer. Cost: \$$(round(msg.cost,digits=3))"

    return result
end


# TODO: update docs signature
"""
    refine!(
        refiner::TavilySearchRefiner, index::AbstractDocumentIndex, result::AbstractRAGResult;
        verbose::Bool = true,
        model::AbstractString = PT.MODEL_CHAT,
        include_answer::Bool = true,
        max_results::Integer = 5,
        include_domains::AbstractVector{<:AbstractString} = String[],
        exclude_domains::AbstractVector{<:AbstractString} = String[],
        template::Symbol = :RAGWebSearchRefiner,
        cost_tracker = Threads.Atomic{Float64}(0.0),
        kwargs...)

Refines the answer by executing a web search using the Tavily API. This method aims to enhance the answer's accuracy and relevance by incorporating information retrieved from the web.

Note: The web results and web answer (if requested) will be added to the context and sources!

# Returns
- Mutated `result` with `result.final_answer` and the full conversation saved in `result.conversations[:final_answer]`.
- In addition, the web results and web answer (if requested) are appended to the `result.context` and `result.sources` for correct highlighting and verification.

# Arguments
- `refiner::TavilySearchRefiner`: The method to use for refining the answer. Uses `aigenerate` with a web search template.
- `index::AbstractDocumentIndex`: The index containing chunks and sources.
- `result::AbstractRAGResult`: The result containing the context and question to generate the answer for.
- `model::AbstractString`: The model to use for generating the answer. Defaults to `PT.MODEL_CHAT`.
- `include_answer::Bool`: If `true`, includes the answer from Tavily in the web search.
- `max_results::Integer`: The maximum number of results to return.
- `include_domains::AbstractVector{<:AbstractString}`: A list of domains to include in the search results. Default is an empty list.
- `exclude_domains::AbstractVector{<:AbstractString}`: A list of domains to exclude from the search results. Default is an empty list.
- `verbose::Bool`: If `true`, enables verbose logging.
- `template::Symbol`: The template to use for the `aigenerate` function. Defaults to `:RAGWebSearchRefiner`.
- `cost_tracker`: An atomic counter to track the cost of the operation.

# Example
```julia
refiner!(TavilySearchRefiner(), index, result)
# See result.final_answer or pprint(result)
```

To enable this refiner in a full RAG pipeline, simply swap the component in the config:
```julia
cfg = RT.RAGConfig()
cfg.generator.refiner = RT.TavilySearchRefiner()

result = airag(cfg, index; question, return_all = true)
pprint(result)
```
"""
function refine!(
        refiner::TavilySearchRefiner, index::Union{AbstractDocumentIndex, AbstractManagedIndex}, result::AbstractRAGResult;
        verbose::Bool = true,
        model::AbstractString = PT.MODEL_CHAT,
        include_answer::Bool = true,
        max_results::Integer = 5,
        include_domains::AbstractVector{<:AbstractString} = String[],
        exclude_domains::AbstractVector{<:AbstractString} = String[],
        template::Symbol = :RAGWebSearchRefiner,
        cost_tracker = Threads.Atomic{Float64}(0.0),
        kwargs...)

    ## Checks
    placeholders = only(aitemplates(template)).variables # only one template should be found
    @assert (:query in placeholders)&&(:answer in placeholders) &&
            (:search_results in placeholders) "Provided RAG Template $(template) is not suitable. It must have placeholders: `query`, `answer` and `search_results`."
    ##
    (; answer, question) = result
    ## execute Tavily web search and format it
    r = create_websearch(
        question; include_answer, max_results, include_domains,
        exclude_domains)
    web_summary = get(r.response, "answer", "")
    web_raw = get(r.response, "results", [])
    web_sources = ["TOOL(TavilySearch): " * get(res, "url", "") for res in web_raw]
    web_content = join(
        ["$(i). TavilySearch: " * get(res, "content", "")
         for (i, res) in enumerate(web_raw)],
        "\n\n")
    search_results = """
    Web Results Summary: $(web_summary)

    **Raw Results:** 
    $(web_content)

    """
    ##
    conv = aigenerate(template; query = question, search_results,
        answer, model, verbose = false,
        return_all = true,
        kwargs...)
    msg = conv[end]
    result.final_answer = strip(msg.content)
    result.conversations[:final_answer] = conv

    ## Attache the web sources to the context + sources (for reference)
    result.sources = vcat(result.sources, web_sources)
    result.context = vcat(result.context, web_content)

    ## Increment the cost
    Threads.atomic_add!(cost_tracker, msg.cost)
    verbose &&
        @info "Done refining the answer. Cost: \$$(round(msg.cost,digits=3))"

    return result
end

"""
    NoPostprocessor <: AbstractPostprocessor

Default method for `postprocess!` method. A passthrough option that returns the `result` without any changes.

Overload this method to add custom postprocessing steps, eg, logging, saving conversations to disk, etc.
"""
struct NoPostprocessor <: AbstractPostprocessor end

function postprocess!(postprocessor::AbstractPostprocessor, index::Union{AbstractDocumentIndex, AbstractManagedIndex},
        result::AbstractRAGResult; kwargs...)
    throw(ArgumentError("Postprocessor $(typeof(postprocessor)) not implemented"))
end

function postprocess!(
        ::NoPostprocessor, index::Union{AbstractDocumentIndex, AbstractManagedIndex}, result::AbstractRAGResult; kwargs...)
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

# TODO: update docs signature
"""
    generate!(
        generator::AbstractGenerator, index::AbstractDocumentIndex, result::AbstractRAGResult;
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
It is the second step in the RAG pipeline (after `retrieve`)

Returns the mutated `result` with the `result.final_answer` and the full conversation saved in `result.conversations[:final_answer]`.

# Notes
- The default flow is `build_context!` -> `answer!` -> `refine!` -> `postprocess!`.
- `contexter` is the method to use for building the context, eg, simply enumerate the context chunks with `ContextEnumerator`.
- `answerer` is the standard answer generation step with LLMs.
- `refiner` step allows the LLM to critique itself and refine its own answer.
- `postprocessor` step allows for additional processing of the answer, eg, logging, saving conversations, etc.
- All of its sub-routines operate by mutating the `result` object (and adding their part).
- Discover available sub-types for each step with `subtypes(AbstractRefiner)` and similar for other abstract types.

# Arguments
- `generator::AbstractGenerator`: The `generator` to use for generating the answer. Can be `SimpleGenerator` or `AdvancedGenerator`.
- `index::AbstractDocumentIndex`: The index containing chunks and sources.
- `result::AbstractRAGResult`: The result containing the context and question to generate the answer for.
- `verbose::Integer`: If >0, enables verbose logging.
- `api_kwargs::NamedTuple`: API parameters that will be forwarded to ALL of the API calls (`aiembed`, `aigenerate`, and `aiextract`).
- `contexter::AbstractContextBuilder`: The method to use for building the context. Defaults to `generator.contexter`, eg, `ContextEnumerator`.
- `contexter_kwargs::NamedTuple`: API parameters that will be forwarded to the `contexter` call.
- `answerer::AbstractAnswerer`: The method to use for generating the answer. Defaults to `generator.answerer`, eg, `SimpleAnswerer`.
- `answerer_kwargs::NamedTuple`: API parameters that will be forwarded to the `answerer` call. Examples:
    - `model`: The model to use for generating the answer. Defaults to `PT.MODEL_CHAT`.
    - `template`: The template to use for the `aigenerate` function. Defaults to `:RAGAnswerFromContext`.
- `refiner::AbstractRefiner`: The method to use for refining the answer. Defaults to `generator.refiner`, eg, `NoRefiner`.
- `refiner_kwargs::NamedTuple`: API parameters that will be forwarded to the `refiner` call.
    - `model`: The model to use for generating the answer. Defaults to `PT.MODEL_CHAT`.
    - `template`: The template to use for the `aigenerate` function. Defaults to `:RAGAnswerRefiner`.
- `postprocessor::AbstractPostprocessor`: The method to use for postprocessing the answer. Defaults to `generator.postprocessor`, eg, `NoPostprocessor`.
- `postprocessor_kwargs::NamedTuple`: API parameters that will be forwarded to the `postprocessor` call.
- `cost_tracker`: An atomic counter to track the total cost of the operations.

See also: `retrieve`, `build_context!`, `ContextEnumerator`, `answer!`, `SimpleAnswerer`, `refine!`, `NoRefiner`, `SimpleRefiner`, `postprocess!`, `NoPostprocessor`

# Examples
```julia
Assume we already have `index`

question = "What are the best practices for parallel computing in Julia?"

# Retrieve the relevant chunks - returns RAGResult
result = retrieve(index, question)

# Generate the answer using the default generator, mutates the same result
result = generate!(index, result)

```
"""
function generate!(
        generator::AbstractGenerator, index::Union{AbstractDocumentIndex, AbstractManagedIndex}, result::AbstractRAGResult;
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
function generate!(index::AbstractDocumentIndex, result::AbstractRAGResult; kwargs...)
    return generate!(DEFAULT_GENERATOR, index, result; kwargs...)
end

### Overarching

"""
    RAGConfig <: AbstractRAGConfig

Default configuration for RAG. It uses `SimpleIndexer`, `SimpleRetriever`, and `SimpleGenerator` as default components. Provided as the first argument in `airag`.

To customize the components, replace corresponding fields for each step of the RAG pipeline (eg, use `subtypes(AbstractIndexBuilder)` to find the available options).
"""
@kwdef mutable struct RAGConfig <: AbstractRAGConfig
    indexer::AbstractIndexBuilder = SimpleIndexer()
    retriever::AbstractRetriever = SimpleRetriever()
    generator::AbstractGenerator = SimpleGenerator()
end
function Base.show(io::IO, cfg::AbstractRAGConfig)
    dump(io, cfg; maxdepth = 2)
end

"""
    airag(cfg::AbstractRAGConfig, index::AbstractDocumentIndex;
        question::AbstractString,
        verbose::Integer = 1, return_all::Bool = false,
        api_kwargs::NamedTuple = NamedTuple(),
        retriever::AbstractRetriever = cfg.retriever,
        retriever_kwargs::NamedTuple = NamedTuple(),
        generator::AbstractGenerator = cfg.generator,
        generator_kwargs::NamedTuple = NamedTuple(),
        cost_tracker = Threads.Atomic{Float64}(0.0))

High-level wrapper for Retrieval-Augmented Generation (RAG), it combines together the `retrieve` and `generate!` steps which you can customize if needed.

The simplest version first finds the relevant chunks in `index` for the `question` and then sends these chunks to the AI model to help with generating a response to the `question`.

To customize the components, replace the types (`retriever`, `generator`) of the corresponding step of the RAG pipeline - or go into sub-routines within the steps.
Eg, use `subtypes(AbstractRetriever)` to find the available options.

# Arguments
- `cfg::AbstractRAGConfig`: The configuration for the RAG pipeline. Defaults to `RAGConfig()`, where you can swap sub-types to customize the pipeline.
- `index::AbstractDocumentIndex`: The chunk index to search for relevant text.
- `question::AbstractString`: The question to be answered.
- `return_all::Bool`: If `true`, returns the details used for RAG along with the response.
- `verbose::Integer`: If `>0`, enables verbose logging. The higher the number, the more nested functions will log.
- `api_kwargs`: API parameters that will be forwarded to ALL of the API calls (`aiembed`, `aigenerate`, and `aiextract`).
- `retriever::AbstractRetriever`: The retriever to use for finding relevant chunks. Defaults to `cfg.retriever`, eg, `SimpleRetriever` (with no question rephrasing).
- `retriever_kwargs::NamedTuple`: API parameters that will be forwarded to the `retriever` call. Examples of important ones:
    - `top_k::Int`: Number of top candidates to retrieve based on embedding similarity.
    - `top_n::Int`: Number of candidates to return after reranking.
    - `tagger::AbstractTagger`: Tagger to use for tagging the chunks. Defaults to `NoTagger()`.
    - `tagger_kwargs::NamedTuple`: API parameters that will be forwarded to the `tagger` call. You could provide the explicit tags directly with `PassthroughTagger` and `tagger_kwargs = (; tags = ["tag1", "tag2"])`.
- `generator::AbstractGenerator`: The generator to use for generating the answer. Defaults to `cfg.generator`, eg, `SimpleGenerator`.
- `generator_kwargs::NamedTuple`: API parameters that will be forwarded to the `generator` call. Examples of important ones:
    - `answerer_kwargs::NamedTuple`: API parameters that will be forwarded to the `answerer` call. Examples:
        - `model`: The model to use for generating the answer. Defaults to `PT.MODEL_CHAT`.
        - `template`: The template to use for the `aigenerate` function. Defaults to `:RAGAnswerFromContext`.
    - `refiner::AbstractRefiner`: The method to use for refining the answer. Defaults to `generator.refiner`, eg, `NoRefiner`.
    - `refiner_kwargs::NamedTuple`: API parameters that will be forwarded to the `refiner` call.
        - `model`: The model to use for generating the answer. Defaults to `PT.MODEL_CHAT`.
        - `template`: The template to use for the `aigenerate` function. Defaults to `:RAGAnswerRefiner`.
- `cost_tracker`: An atomic counter to track the total cost of the operations (if you want to track the cost of multiple pipeline runs - it passed around in the pipeline).

# Returns
- If `return_all` is `false`, returns the generated message (`msg`).
- If `return_all` is `true`, returns the detail of the full pipeline in `RAGResult` (see the docs).

See also `build_index`, `retrieve`, `generate!`, `RAGResult`, `getpropertynested`, `setpropertynested`, `merge_kwargs_nested`, `ChunkKeywordsIndex`.

# Examples

Using `airag` to get a response for a question:
```julia
index = build_index(...)  # create an index
question = "How to make a barplot in Makie.jl?"
msg = airag(index; question)
```

To understand the details of the RAG process, use `return_all=true`
```julia
msg, details = airag(index; question, return_all = true)
# details is a RAGDetails object with all the internal steps of the `airag` function
```

You can also pretty-print `details` to highlight generated text vs text that is supported by context.
It also includes annotations of which context was used for each part of the response (where available).
```julia
PT.pprint(details)
```

Example with advanced retrieval (with question rephrasing and reranking (requires `COHERE_API_KEY`).
We will obtain top 100 chunks from embeddings (`top_k`) and top 5 chunks from reranking (`top_n`).
In addition, it will be done with a "custom" locally-hosted model.

```julia
cfg = RAGConfig(; retriever = AdvancedRetriever())

# kwargs will be big and nested, let's prepare them upfront
# we specify "custom" model for each component that calls LLM
kwargs = (
    retriever_kwargs = (;
        top_k = 100,
        top_n = 5,
        rephraser_kwargs = (;
            model = "custom"),
        embedder_kwargs = (;
            model = "custom"),
        tagger_kwargs = (;
            model = "custom")),
    generator_kwargs = (;
        answerer_kwargs = (;
            model = "custom"),
        refiner_kwargs = (;
            model = "custom")),
    api_kwargs = (;
        url = "http://localhost:8080"))

result = airag(cfg, index, question; kwargs...)
```

If you want to use hybrid retrieval (embeddings + BM25), you can easily create an additional index based on keywords
 and pass them both into a `MultiIndex`. 
 
You need to provide an explicit config, so the pipeline knows how to handle each index in the search similarity phase (`finder`).

```julia
index = # your existing index

# create the multi-index with the keywords index
index_keywords = ChunkKeywordsIndex(index)
multi_index = MultiIndex([index, index_keywords])

# define the similarity measures for the indices that you have (same order)
finder = RT.MultiFinder([RT.CosineSimilarity(), RT.BM25Similarity()])
cfg = RAGConfig(; retriever=AdvancedRetriever(; processor=RT.KeywordsProcessor(), finder))

# Run the pipeline with the new hybrid retrieval (return the `RAGResult` to see the details)
result = airag(cfg, multi_index; question, return_all=true)

# Pretty-print the result
PT.pprint(result)
```

For easier manipulation of nested kwargs, see utilities `getpropertynested`, `setpropertynested`, `merge_kwargs_nested`.
"""
function airag(cfg::AbstractRAGConfig, index::Union{AbstractDocumentIndex, AbstractManagedIndex};
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
        retriever, index, question; verbose = verbose - 1, cost_tracker, retriever_kwargs_...)

    ## Generate the response
    generator_kwargs_ = isempty(api_kwargs) ? generator_kwargs :
                        merge(generator_kwargs, (; api_kwargs))
    result = generate!(generator, index, result; verbose = verbose - 1, cost_tracker,
        generator_kwargs_...)

    verbose > 0 &&
        @info "Done with RAG. Total cost: \$$(round(cost_tracker[], digits=3))"

    ## Return `RAGResult` or more user-friendly `AIMessage`
    output = if return_all
        result
    elseif haskey(result.conversations, :final_answer) &&
           !isempty(result.conversations[:final_answer])
        result.conversations[:final_answer][end]
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
function airag(index::AbstractDocumentIndex; question::AbstractString, kwargs...)
    return airag(DEFAULT_RAG_CONFIG, index; question, kwargs...)
end

# Special method to pretty-print the airag results
function PT.pprint(io::IO, airag_result::Tuple{PT.AIMessage, AbstractRAGResult},
        text_width::Int = displaysize(io)[2])
    rag_details = airag_result[2]
    pprint(io, rag_details; text_width)
end
