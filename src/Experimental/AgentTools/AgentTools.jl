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
using Random
using Test

# re-export
export AICode, last_output, last_message # extended in lazy_types.jl
using PromptingTools: last_output, last_message, AICode

export print_tree, PreOrderDFS, PostOrderDFS
include("utils.jl")

export print_samples, find_node
include("mcts.jl")

export aicodefixer_feedback, error_feedback, score_feedback
include("code_feedback.jl")

export AICall, AIGenerate, AIExtract, AIEmbed, AIClassify, AIScan
export RetryConfig
export AICodeFixer, run!
include("lazy_types.jl")

export airetry!
# export add_feedback!, evaluate_condition!
include("retry.jl")

end
