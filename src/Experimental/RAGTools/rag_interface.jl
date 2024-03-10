############################
### THIS IS WORK IN PROGRESS
############################

# This is the outline of the current RAG interface.
#
### System Overview
#
# This system is designed for information retrieval and response generation, structured in three main phases:
# - Preparation, when you create an instance of `AbstractIndex`
# - Retrieval, when you surface the top most relevant chunks/items in the `index` 
# - Generation, when you generate an answer based on the retrieved chunks
#
# The system is designed to be hackable and extensible at almost every entry point.
# You just need to define the corresponding concrete type (struct XYZ <: AbstractXYZ end) and the corresponding method.
# Then you pass the instance of this new type via kwargs, eg, `annotater=TrigramAnnotater()`
#
### RAG Diagram
#
# build_index
#   signature: () -> AbstractChunkIndex
#   flow: get_chunks -> get_embeddings -> get_tags
# 
# airag: 
#   signature: () -> AIMessage or (AIMessage, RAGDetails)
#   flow: retrieve -> generate
#
# retrieve:
#   signature: () -> RAGContext
#   flow: rephrase -> aiembed -> find_closest -> find_tags -> rerank
#
# generate:
#  signature: () -> AIMessage or (AIMessage, RAGContext)
#  flow: format_context -> aigenerate -> refine   
#
### Deepdive
#
# Preparation Phase:
# - Begins with `build_index`, which creates a user-defined index type from an abstract chunk index using specified models and function strategies.
# - `get_chunks` then divides the indexed data into manageable pieces based on a chunking strategy.
# - `get_embeddings` generates embeddings for each chunk using an embedding strategy to facilitate similarity searches.
# - Finally, `get_metadata` extracts relevant metadata from each chunk using a metadata strategy, enabling metadata-based filtering.
#
# Generation/E2E Phase:
# - Starts with `airag`, initiating the response generation process using a custom index to potentially alter the high-level structure.
# - The `retrieve` step employs a retrieval strategy to fetch relevant data, which can be modified by a rephrase strategy for better query matching.
# - `aiembed` generates embeddings for the rephrased query, which are used in `find_closest` to identify the most relevant chunks using a similarity strategy.
# - Optional tag filtering (`aiextract + find_exact`) can be applied before candidates are re-ranked using a reranking strategy.
# - `format_context` constructs the context for response generation based on a context strategy, leading to the `aigenerate` step that produces the final answer.
# - The process concludes with `Refine`, applying a refine strategy for any final adjustments or re-evaluation.
#

### Types
############################
### NOT READY!!!
############################

#
# Defines three key types for RAG: ChunkIndex, MultiIndex, and CandidateChunks
# In addition, RAGContext is defined for debugging purposes

# ## Overarching

# Dispatch type for airag
abstract type AbstractRAGConfig end

# supertype for RAGDetails, return_type for retrieve and generate (and optionally airag)
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
- `distances::Vector{Float32}`: the distances of the candidates from the query
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
- `similarity_search::AbstractSimilaritySearch`: the similarity search method, dispatching `find_closest`
- `tag_match::AbstractTagMatch`: the tag matching method, dispatching `find_tags`
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

# Main dispatch type for: `generate`
abstract type AbstractGenerator <: AbstractGenerationMethod end

# Main dispatch type for: `build_context`
abstract type AbstractContextBuilder <: AbstractGenerationMethod end

# Main dispatch type for: `refine`
abstract type AbstractRefiner <: AbstractGenerationMethod end

# ## Exploration/Display stage

# Supertype for annotaters, dispatch for `annotate_support`
abstract type AbstractAnnotater end

abstract type AbstractAnnotatedNode end
abstract type AbstractAnnotationStyler end

# ## Main Functions

# Builds the index from provided data, dispatch via `indexer::AbstractIndexer`.
function build_index end
function get_chunks end
function get_embeddings end
function get_tags end
# Sub-routing of get_tags, extended in ext/RAGToolsExperimentalExt.jl
"Builds a matrix of tags and a vocabulary list. REQUIRES SparseArrays and LinearAlgebra packages to be loaded!!"
function build_tags end

function retrieve end
function rephrase end
function find_closest end
function find_tags end
function rerank end

function generate end
function format_context end
function refine end