using PromptingTools
using OpenAI, HTTP, JSON3
using SparseArrays, LinearAlgebra, Markdown
using Statistics
using Dates: now
using Test, Pkg, Random
const PT = PromptingTools
using GoogleGenAI
using Aqua

@testset "Code quality (Aqua.jl)" begin
    # Skipping unbound_args check because we need our `MaybeExtract` type to be unboard
    @static if VERSION >= v"1.9" && VERSION <= v"1.10"
        Aqua.test_all(PromptingTools; unbound_args = false, piracy = false)
    else
        Aqua.test_all(PromptingTools; unbound_args = false)
    end
end
@testset "PromptingTools.jl" begin
    include("utils.jl")
    include("messages.jl")
    include("annotation.jl")
    include("memory.jl")
    include("extraction.jl")
    include("user_preferences.jl")
    include("llm_interface.jl")
    include("streaming.jl")
    include("retry_layer.jl")
    include("llm_shared.jl")
    include("llm_openai_chat.jl")
    include("llm_openai_responses.jl")
    include("llm_ollama_managed.jl")
    include("llm_ollama.jl")
    include("llm_google.jl")
    include("llm_openai_schema_def.jl")
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

## Run experimental
@testset "Experimental" begin
    include("Experimental/AgentTools/runtests.jl")
    include("Experimental/APITools/runtests.jl")
end
