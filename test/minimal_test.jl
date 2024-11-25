module TestPromptingTools

using Test
using Dates
using JSON3
using HTTP
using OpenAI
using StreamCallbacks, StructTypes

# First define the abstract types and schemas needed
abstract type AbstractPromptSchema end
abstract type AbstractMessage end

# Import the essential files in correct order
include("../src/constants.jl")
include("../src/utils.jl")
include("../src/messages.jl")

@testset "Basic Message Types" begin
    # Test basic message creation
    sys_msg = SystemMessage("test system")
    @test issystemmessage(sys_msg)

    user_msg = UserMessage("test user")
    @test isusermessage(user_msg)

    ai_msg = AIMessage("test ai")
    @test isaimessage(ai_msg)
end

end # module
