using PromptingTools
using JSON3
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
    include("llm_openai.jl")
    include("templates.jl")
end
