"""
    Experimental

This module is for experimental code that is not yet ready for production.
It is not included in the main module, so it must be explicitly imported.

Contains:
- `RAGTools`: [DEPRECATED] RAG functionality has moved to RAGTools.jl package.
- `AgentTools`: Agentic functionality - lazy calls for building pipelines (eg, `AIGenerate`) and `AICodeFixer`.
- `APITools`: APIs to complement GenAI workflows (eg, Tavily Search API).
"""
module Experimental

export APITools
include("APITools/APITools.jl")

export RAGTools
include("RAGTools.jl")

export AgentTools
include("AgentTools/AgentTools.jl")

end # module Experimental
