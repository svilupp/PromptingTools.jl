using Test
using PromptingTools
using PromptingTools.Experimental.AgentTools
const PT = PromptingTools

@testset "AgentTools" begin
    include("utils.jl")
    include("code_feedback.jl")
    include("lazy_types.jl")
end
