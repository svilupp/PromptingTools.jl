using PromptingTools
using Test
using Aqua
const PT = PromptingTools

@testset "Code quality (Aqua.jl)" begin
    Aqua.test_all(PromptingTools)
end
@testset "PromptingTools.jl" begin
    include("utils.jl")
    include("messages.jl")
    include("llm_openai.jl")
end
