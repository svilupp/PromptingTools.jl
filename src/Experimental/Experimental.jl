"""
    Experimental

This module is for experimental code that is not yet ready for production.
It is not included in the main module, so it must be explicitly imported.

Contains:
- `RAGTools`: Retrieval-Augmented Generation (RAG) functionality.
- `AgentTools`: Agentic functionality - lazy calls for building pipelines (eg, `AIGenerate`) and `AICodeFixer`.
"""
module Experimental

export RAGTools
include("RAGTools/RAGTools.jl")

export AgentTools
include("AgentTools/AgentTools.jl")

end # module Experimental