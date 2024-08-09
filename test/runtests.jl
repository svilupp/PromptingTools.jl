using PromptingTools
using OpenAI, HTTP, JSON3
using SparseArrays, LinearAlgebra, Markdown
using Statistics
using Dates: now
using Test, Pkg, Random
const PT = PromptingTools
using Snowball, FlashRank
using Aqua

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
    include("llm_ollama.jl")
    include("llm_google.jl")
    include("llm_anthropic.jl")
    include("llm_sharegpt.jl")
    include("llm_tracer.jl")
    include("macros.jl")
    include("templates.jl")
    include("serialization.jl")
    include("code_parsing.jl")
    include("code_expressions.jl")
    include("code_eval.jl")
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

@testset "aiextract with strict parameter" begin
    # Test with strict=true
    result_strict_true = aiextract("Extract the name and age: John is 30 years old",
                                   Dict("name" => String, "age" => Int);
                                   strict=true)
    @test result_strict_true == Dict("name" => "John", "age" => 30)

    # Test with strict=false
    result_strict_false = aiextract("Extract the name and age: John is 30 years old",
                                    Dict("name" => String, "age" => Int);
                                    strict=false)
    @test haskey(result_strict_false, "strict")
    @test result_strict_false["strict"] == false
    @test result_strict_false["name"] == "John"
    @test result_strict_false["age"] == 30

    # Test with strict=nothing (default behavior)
    result_strict_nothing = aiextract("Extract the name and age: John is 30 years old",
                                      Dict("name" => String, "age" => Int))
    @test !haskey(result_strict_nothing, "strict")
    @test result_strict_nothing["name"] == "John"
    @test result_strict_nothing["age"] == 30
end

## Run experimental
@testset "Experimental" begin
    include("Experimental/RAGTools/runtests.jl")
    include("Experimental/AgentTools/runtests.jl")
    include("Experimental/APITools/runtests.jl")
end
