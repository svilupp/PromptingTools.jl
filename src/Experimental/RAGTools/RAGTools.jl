"""
    RAGTools

Provides Retrieval-Augmented Generation (RAG) functionality.

Requires: LinearAlgebra, SparseArrays, PromptingTools for proper functionality.

This module is experimental and may change at any time. It is intended to be moved to a separate package in the future.
"""
module RAGTools

using PromptingTools
using PromptingTools: pprint, AbstractMessage
using HTTP, JSON3
using AbstractTrees
using AbstractTrees: PreOrderDFS
const PT = PromptingTools

# reexport
export pprint

## export trigrams, trigrams_hashed, text_to_trigrams, text_to_trigrams_hashed
## export STOPWORDS, tokenize, split_into_code_and_sentences
include("utils.jl")

# eg, cohere_api
include("api_services.jl")

include("rag_interface.jl")

export ChunkIndex, CandidateChunks, RAGResult
# export MultiIndex # not ready yet
include("types.jl")

export build_index, get_chunks, get_embeddings, get_tags
include("preparation.jl")

export retrieve, SimpleRetriever, AdvancedRetriever
export find_closest, find_tags, rerank, rephrase
include("retrieval.jl")

export airag, build_context!, generate!, refine!, answer!, postprocess!
export SimpleGenerator, AdvancedGenerator, RAGConfig
include("generation.jl")

export annotate_support, TrigramAnnotater, print_html
include("annotation.jl")

export build_qa_evals, run_qa_evals
include("evaluation.jl")

end
