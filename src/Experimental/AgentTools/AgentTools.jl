"""
    AgentTools

Provides Agentic functionality providing lazy calls for building pipelines (eg, `AIGenerate`) and `AICodeFixer`.

This module is experimental and may change at any time. It is intended to be moved to a separate package in the future.
"""
module AgentTools

using PromptingTools
const PT = PromptingTools
using AbstractTrees
using AbstractTrees: print_tree, PreOrderDFS, PostOrderDFS
using Test

export print_tree, PreOrderDFS, PostOrderDFS
include("utils.jl")

export print_samples, find_node
include("mcts.jl")

export aicodefixer_feedback, error_feedback, score_feedback
include("code_feedback.jl")

export AICall, AIGenerate, AIExtract, AIEmbed, AIClassify, AIScan
export RetryConfig, last_output, last_message
export AICodeFixer, run!
include("lazy_types.jl")

export airetry
include("retry.jl")

end
