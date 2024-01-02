"""
    AgentTools

Provides Agentic functionality providing lazy calls for building pipelines (eg, `AIGenerate`) and `AICodeFixer`.

This module is experimental and may change at any time. It is intended to be moved to a separate package in the future.
"""
module AgentTools

using PromptingTools
const PT = PromptingTools

include("utils.jl")

export aicodefixer_feedback
include("code_feedback.jl")

export AICall, AIGenerate, AIExtract, AIEmbed
export AICodeFixer, run!
include("lazy_types.jl")

end