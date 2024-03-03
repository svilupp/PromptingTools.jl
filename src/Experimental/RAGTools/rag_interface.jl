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
#   signature: () -> AIMessage or (AIMessage, RAGContext)
#   flow: retrieve -> generate
#
# retrieve:
#   signature: () -> RAGContext
#   flow: rephrase -> aiembed -> find_closest -> find_exact -> rerank
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

# ## Preparation Stage

abstract type AbstractDocumentIndex end
abstract type AbstractMultiIndex <: AbstractDocumentIndex end
abstract type AbstractChunkIndex <: AbstractDocumentIndex end

abstract type AbstractCandidateChunks end

abstract type AbstractRAGResult end

# ## Retrieval stage
abstract type AbstractRetrievalStrategies end

# Main dispatch type for `rephrase`
abstract type AbstractRephraserStrategy <: AbstractRetrievalStrategies end

# Main dispatch type for `find_similar`
abstract type AbstractSimilarityStrategy <: AbstractRetrievalStrategies end

# Main dispatch type for `find_exact`
abstract type AbstractExactnessStrategy <: AbstractRetrievalStrategies end

# Main dispatch type for `rerank`
abstract type AbstractRerankerStrategy <: AbstractRetrievalStrategies end

# ## Generation stage
abstract type AbstractGenerationStrategies end

# Main dispatch type for: `format_context`
abstract type AbstractContextFormater <: AbstractGenerationStrategies end

# Main dispatch type for: `refine`
abstract type AbstractRefiner <: AbstractGenerationStrategies end

# ## Exploration/Display stage

abstract type AbstractAnnotater end

abstract type AbstractAnnotatedNode end
abstract type AbstractAnnotationStyler end