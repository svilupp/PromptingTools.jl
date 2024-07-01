using Test
using SparseArrays, LinearAlgebra, Unicode
using PromptingTools.Experimental.RAGTools
using PromptingTools
using PromptingTools.AbstractTrees
const PT = PromptingTools
const RT = PromptingTools.Experimental.RAGTools
using Snowball
using JSON3, HTTP

@testset "RAGTools" begin
    include("utils.jl")
    include("types.jl")
    include("preparation.jl")
    include("rank_gpt.jl")
    include("retrieval.jl")
    include("generation.jl")
    include("annotation.jl")
    include("evaluation.jl")
end
