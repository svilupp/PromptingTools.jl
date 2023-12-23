using PromptingTools
using OpenAI, HTTP, JSON3
using SparseArrays, LinearAlgebra
using Test
using Aqua
const PT = PromptingTools

@testset "Code quality (Aqua.jl)" begin
    # Skipping unbound_args check because we need our `MaybeExtract` type to be unboard
    Aqua.test_all(PromptingTools; unbound_args = false)
end
@testset "PromptingTools.jl" begin
    include("utils.jl")
    include("messages.jl")
    include("extraction.jl")
    include("user_preferences.jl")
    include("llm_interface.jl")
    include("llm_shared.jl")
    include("llm_openai.jl")
    include("llm_ollama_managed.jl")
    include("templates.jl")
    include("serialization.jl")
    include("code_generation.jl")
end

# Part of code_generation.jl / @testset "eval!" begin
# Test that it captures test failures, we need to move it to the main file as it as it doesn't work inside a testset
let cb = AICode(; code = """
    @test 1==2
    """)
    eval!(cb)
    @test cb.success == false
    @test cb.error isa Test.FallbackTestSetException
    @test !isnothing(cb.expression) # parsed
    @test occursin("Test Failed", cb.stdout) # capture details of the test failure
    @test isnothing(cb.output) # because it failed
end

## Run experimental
@testset "Experimental" begin
    include("Experimental/RAGTools/runtests.jl")
end
