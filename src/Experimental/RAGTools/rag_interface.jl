############################
### RAG Interface Write-up
############################

# This is the outline of the current RAG interface.
#
## # System Overview
##
## This system is designed for information retrieval and response generation, structured in three main phases:
## - Preparation, when you create an instance of `AbstractIndex`
## - Retrieval, when you surface the top most relevant chunks/items in the `index` and return `AbstractRAGResult`, which contains the references to the chunks (`AbstractCandidateChunks`)
## - Generation, when you generate an answer based on the context built from the retrieved chunks, return either `AIMessage` or `AbstractRAGResult`
##
## The system is designed to be hackable and extensible at almost every entry point.
## If you want to customize the behavior of any step, you can do so by defining a new type and defining a new method for the step you're changing, eg, 
## ```julia
## struct MyReranker <: AbstractReranker end
## RT.rerank(::MyReranker, index, candidates) = ...
## ```
## And then you'd ask for the `retrive` step to use your custom `MyReranker`, eg, `retrieve(....; reranker = MyReranker())` (or customize the main dispatching `AbstractRetriever` struct).
##
## # RAG Diagram
##
## The main functions are:
##
## `build_index`:
## - signature: `(indexer::AbstractIndexBuilder, files_or_docs::Vector{<:AbstractString}) -> AbstractChunkIndex`
## - flow: `get_chunks` -> `get_embeddings` -> `get_tags` -> `build_tags`
## - dispatch types: `AbstractIndexBuilder`, `AbstractChunker`, `AbstractEmbedder`, `AbstractTagger`
##
## `airag`: 
## - signature: `(cfg::AbstractRAGConfig, index::AbstractChunkIndex; question::AbstractString)` -> `AIMessage` or `AbstractRAGResult`
## - flow: `retrieve` -> `generate!`
## - dispatch types: `AbstractRAGConfig`, `AbstractRetriever`, `AbstractGenerator`
##
## `retrieve`:
## - signature: `(retriever::AbstractRetriever, index::AbstractChunkIndex, question::AbstractString) -> AbstractRAGResult`
## - flow: `rephrase` -> `get_embeddings` -> `find_closest` -> `get_tags` -> `find_tags` -> `rerank`
## - dispatch types: `AbstractRAGConfig`, `AbstractRephraser`, `AbstractEmbedder`, `AbstractSimilarityFinder`, `AbstractTagger`, `AbstractTagFilter`, `AbstractReranker`
##
## `generate!`:
## - signature: `(generator::AbstractGenerator, index::AbstractChunkIndex, result::AbstractRAGResult)` -> `AIMessage` or `AbstractRAGResult`
## - flow: `build_context!` -> `answer!` -> `refine!` -> `postprocess!`
## - dispatch types: `AbstractGenerator`, `AbstractContextBuilder`, `AbstractAnswerer`, `AbstractRefiner`, `AbstractPostprocessor`
##
## To discover the currently available implementations, use `subtypes` function, eg, `subtypes(AbstractReranker)`.
##
## # Deepdive
##
## **Preparation Phase:**
## - Begins with `build_index`, which creates a user-defined index type from an abstract chunk index using specified dels and function strategies.
## - `get_chunks` then divides the indexed data into manageable pieces based on a chunking strategy.
## - `get_embeddings` generates embeddings for each chunk using an embedding strategy to facilitate similarity arches.
## - Finally, `get_tags` extracts relevant metadata from each chunk, enabling tag-based filtering (hybrid search index). If there are `tags` available, `build_tags` is called to build the corresponding sparse matrix for filtering with tags.

## **Retrieval Phase:**
## - The `retrieve` step is intended to find the most relevant chunks in the `index`.
## - `rephrase` is called first, if we want to rephrase the query (methods like `HyDE` can improve retrieval quite a bit)!
## - `get_embeddings` generates embeddings for the original + rephrased query
## - `find_closest` looks up the most relevant candidates (`CandidateChunks`) using a similarity search strategy.
## - `get_tags` extracts the potential tags (can be provided as part of the `airag` call, eg, when we want to use only some small part of the indexed chunks)
## - `find_tags` filters the candidates to strictly match _at least one_ of the tags (if provided)
## - `rerank` is called to rerank the candidates based on the reranking strategy (ie, to improve the ordering of the chunks in context).

## **Generation Phase:**
## - The `generate` step is intended to generate a response based on the retrieved chunks, provided via `AbstractRAGResult` (eg, `RAGResult`).
## - `build_context!` constructs the context for response generation based on a context strategy and applies the necessary formatting
## - `answer!` generates the response based on the context and the query
## - `refine!` is called to refine the response (optional, defaults to passthrough)
## - `postprocessing!` is available for any final touches to the response or to potentially save or format the results (eg, automatically save to the disk)

## Note that all generation steps are mutating the `RAGResult` object.

############################
### TYPES
############################

# Defines the main abstract types used in our RAG system.

# ## Overarching

# Dispatch type for airag
abstract type AbstractRAGConfig end

# supertype for RAGDetails, return_type for retrieve and generate (and optionally airag)
"""
    AbstractRAGResult

Abstract type for the result of the RAG (Retrieval-Augmented Generation) process. 
    
Implementations of this type should contain the necessary fields to represent the outcome of the RAG pipeline, including the original question, any rephrased versions of the question, the generated answer, and any additional context or metadata used or generated during the process.

# Fields
- [OPTIONAL] `question::AbstractString`: The original question posed to the RAG system.
- `rephrased_questions::AbstractVector{<:AbstractString}`: A vector of rephrased versions of the original question, generated during the retrieval phase to improve the quality of the results.
- [OPTIONAL] `answer::Union{Nothing, AbstractString}`: The initial answer generated based on the retrieved information and the question. This field may be `nothing` if the generation phase has not yet produced an answer.
- `final_answer::Union{Nothing, AbstractString}`: The final refined answer after any post-processing steps have been applied. This is considered the definitive answer produced by the RAG system.
- `context::Vector{<:AbstractString}`: A vector of strings representing the context used for generating the answer. This may include relevant information retrieved during the retrieval phase.
- `sources::Vector{<:AbstractString}`: The sources of the context information, providing traceability for the data used in generating the answer.
... some fields for search candidates (`::CandidateChunks`)
- [OPTIONAL] `conversations::Dict{Symbol,Vector{<:AbstractMessage}}`: A dictionary containing the history of AI-generated messages and interactions during the RAG process. Keys correspond to the names of functions in the RAG pipeline, providing insight into the decision-making process at each step.

If `rephrased_questions` is the primarily field, it should be used instead of `question`.
If `final_answer` is the primarily field, it should be used instead of `answer`.
`conversations` recording is optional but highly recommended for observability.

This abstract type serves as a blueprint for concrete implementations that store the results of the RAG process, facilitating debugging, analysis, and further processing of the generated answers.
"""

abstract type AbstractRAGResult end

# ## Preparation Stage

# Main supertype for all customizations of the indexing process
abstract type AbstractIndexingMethod end

"""
    AbstractIndexBuilder

Abstract type for building an index with `build_index` (use to change the process / return type of `build_index`).

# Required Fields
- `chunker::AbstractChunker`: the chunking method, dispatching `get_chunks`
- `embedder::AbstractEmbedder`: the embedding method, dispatching `get_embeddings`
- `tagger::AbstractTagger`: the tagging method, dispatching `get_tags`
"""
abstract type AbstractIndexBuilder <: AbstractIndexingMethod end

# For get_chunks function
abstract type AbstractChunker <: AbstractIndexingMethod end
# For get_embeddings function
abstract type AbstractEmbedder <: AbstractIndexingMethod end
# For get_tags function
abstract type AbstractTagger <: AbstractIndexingMethod end

### Index itself - return type of `build_index`
abstract type AbstractDocumentIndex end

"""
    AbstractMultiIndex <: AbstractDocumentIndex

Experimental abstract type for storing multiple document indexes. Not yet implemented.
"""
abstract type AbstractMultiIndex <: AbstractDocumentIndex end

"""
    AbstractChunkIndex <: AbstractDocumentIndex

Main abstract type for storing document chunks and their embeddings. It also stores tags and sources for each chunk.

# Required Fields
- `id::Symbol`: unique identifier of each index (to ensure we're using the right index with `CandidateChunks`)
- `chunks::Vector{<:AbstractString}`: underlying document chunks / snippets
- `embeddings::Union{Nothing, Matrix{<:Real}}`: for semantic search
- `tags::Union{Nothing, AbstractMatrix{<:Bool}}`: for exact search, filtering, etc. This is often a sparse matrix indicating which chunks have the given `tag` (see `tag_vocab` for the position lookup)
- `tags_vocab::Union{Nothing, Vector{<:AbstractString}}`: vocabulary for the `tags` matrix (each column in `tags` is one item in `tags_vocab` and rows are the chunks)
- `sources::Vector{<:AbstractString}`: sources of the chunks
- `extras::Union{Nothing, AbstractVector}`: additional data, eg, metadata, source code, etc.
"""
abstract type AbstractChunkIndex <: AbstractDocumentIndex end

# ## Retrieval stage

"""
    AbstractCandidateChunks

Abstract type for storing candidate chunks, ie, references to items in a `AbstractChunkIndex`.

Return type from `find_closest` and `find_tags` functions.

# Required Fields
- `index_id::Symbol`: the id of the index from which the candidates are drawn
- `positions::Vector{Int}`: the positions of the candidates in the index
- `scores::Vector{Float32}`: the similarity scores of the candidates from the query (higher is better)
"""
abstract type AbstractCandidateChunks end

# Main supertype for retrieval customizations
abstract type AbstractRetrievalMethod end

# Main dispatch type for `retrieve`
"""
    AbstractRetriever <: AbstractRetrievalMethod

Abstract type for retrieving chunks from an index with `retrieve` (use to change the process / return type of `retrieve`).

# Required Fields
- `rephraser::AbstractRephraser`: the rephrasing method, dispatching `rephrase`
- `finder::AbstractSimilarityFinder`: the similarity search method, dispatching `find_closest`
- `filter::AbstractTagFilter`: the tag matching method, dispatching `find_tags`
- `reranker::AbstractReranker`: the reranking method, dispatching `rerank`
"""
abstract type AbstractRetriever <: AbstractRetrievalMethod end

# Main dispatch type for `rephrase`
abstract type AbstractRephraser <: AbstractRetrievalMethod end

# Main dispatch type for `find_closest`
abstract type AbstractSimilarityFinder <: AbstractRetrievalMethod end

# Main dispatch type for `find_tags`
abstract type AbstractTagFilter <: AbstractRetrievalMethod end

# Main dispatch type for `rerank`
abstract type AbstractReranker <: AbstractRetrievalMethod end

# ## Generation stage
abstract type AbstractGenerationMethod end

# Main dispatch type for: `generate!`
"""
    AbstractGenerator <: AbstractGenerationMethod

Abstract type for generating an answer with `generate!` (use to change the process / return type of `generate`).

# Required Fields
- `contexter::AbstractContextBuilder`: the context building method, dispatching `build_context!
- `answerer::AbstractAnswerer`: the answer generation method, dispatching `answer!`
- `refiner::AbstractRefiner`: the answer refining method, dispatching `refine!`
- `postprocessor::AbstractPostprocessor`: the postprocessing method, dispatching `postprocess!`
"""
abstract type AbstractGenerator <: AbstractGenerationMethod end

# Main dispatch type for: `build_context!`
abstract type AbstractContextBuilder <: AbstractGenerationMethod end

# Main dispatch type for: `answer!`
abstract type AbstractAnswerer <: AbstractGenerationMethod end

# Main dispatch type for: `refine!`
abstract type AbstractRefiner <: AbstractGenerationMethod end

# Main dispatch type for: `postprocess!`
abstract type AbstractPostprocessor <: AbstractGenerationMethod end

# ## Exploration/Display stage

# Supertype for annotaters, dispatch for `annotate_support`
abstract type AbstractAnnotater end

abstract type AbstractAnnotatedNode end
abstract type AbstractAnnotationStyler end

############################
### FUNCTIONS
############################

# ## Main Functions

# Builds the index from provided data, dispatch via `indexer::AbstractIndexer`.
function build_index end
function get_chunks end
function get_embeddings end
function get_tags end
# Sub-routing of get_tags, extended in ext/RAGToolsExperimentalExt.jl
"Builds a matrix of tags and a vocabulary list. REQUIRES SparseArrays and LinearAlgebra packages to be loaded!!"
function build_tags end

# Retrieval stage -> ultimately returns `RAGResult`
function retrieve end
function rephrase end
function find_closest end
function find_tags end
function rerank end

# Generation stage -> returns mutated `RAGResult`
function generate! end
function build_context! end
function build_context end
function answer! end
function refine! end
function postprocess! end