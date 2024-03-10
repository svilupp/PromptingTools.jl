"""
    RAGTools

Provides Retrieval-Augmented Generation (RAG) functionality.

Requires: LinearAlgebra, SparseArrays, PromptingTools for proper functionality.

This module is experimental and may change at any time. It is intended to be moved to a separate package in the future.
"""
module RAGTools

using PromptingTools
using PromptingTools: pprint
using HTTP, JSON3
using AbstractTrees
using AbstractTrees: PreOrderDFS
const PT = PromptingTools

## export trigrams, trigrams_hashed, text_to_trigrams, text_to_trigrams_hashed
## export STOPWORDS, tokenize, split_into_code_and_sentences
include("utils.jl")

# eg, cohere_api
include("api_services.jl")

include("rag_interface.jl")

export ChunkIndex, CandidateChunks
# export MultiIndex # not ready yet
include("types.jl")

export build_index, get_chunks, get_embeddings, get_tags
include("preparation.jl")

export retrieve
export find_closest, find_tags, rerank
include("retrieval.jl")

export airag, format_context
include("generation.jl")

export annotate_support
include("annotation.jl")

export build_qa_evals, run_qa_evals
include("evaluation.jl")

end
