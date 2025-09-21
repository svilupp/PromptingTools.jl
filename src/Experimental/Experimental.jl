"""
    Experimental

This module is for experimental code that is not yet ready for production.
It is not included in the main module, so it must be explicitly imported.

Contains:
- `AgentTools`: Agentic functionality - lazy calls for building pipelines (eg, `AIGenerate`) and `AICodeFixer`.
- `APITools`: APIs to complement GenAI workflows (eg, Tavily Search API).

Removed:
- `RAGTools`: RAG functionality has moved to [RAGTools.jl](https://github.com/JuliaGenAI/RAGTools.jl) package.
"""
module Experimental

export APITools
include("APITools/APITools.jl")

export AgentTools
include("AgentTools/AgentTools.jl")

end # module Experimental
