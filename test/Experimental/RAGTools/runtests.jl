using Test
using SparseArrays, LinearAlgebra, Unicode, Random
using PromptingTools.Experimental.RAGTools
using PromptingTools
using PromptingTools.AbstractTrees
const PT = PromptingTools
const RT = PromptingTools.Experimental.RAGTools

# Try to load Snowball, provide fallback if not available
const SNOWBALL_AVAILABLE = try
    using Snowball
    true
catch
    @warn "Snowball package not available. Some RAGTools tests will be skipped."
    false
end
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
