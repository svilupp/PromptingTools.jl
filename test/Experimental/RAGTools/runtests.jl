using Test
using SparseArrays, LinearAlgebra
using PromptingTools.Experimental.RAGTools
using JSON3, HTTP

@testset "RAGTools" begin
    include("utils.jl")
    include("types.jl")
    include("preparation.jl")
    include("retrieval.jl")
    include("generation.jl")
    include("annotation.jl")
    include("evaluation.jl")
end
