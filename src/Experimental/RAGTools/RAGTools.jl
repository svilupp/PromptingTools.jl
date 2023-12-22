"""
    RAGTools

Provides Retrieval-Augmented Generation (RAG) functionality.

Requires: LinearAlgebra, SparseArrays, PromptingTools for proper functionality.

This module is experimental and may change at any time. It is intended to be moved to a separate package in the future.
"""
module RAGTools

using PromptingTools
using JSON3
const PT = PromptingTools

include("utils.jl")

export ChunkIndex, CandidateChunks # MultiIndex
include("types.jl")

export build_index, build_tags
include("preparation.jl")

export find_closest, find_tags, rerank
include("retrieval.jl")

export airag
include("generation.jl")

export build_qa_evals, run_qa_evals
include("evaluation.jl")

end