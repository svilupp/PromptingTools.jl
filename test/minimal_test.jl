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

    # Test annotation message
    annotation = AnnotationMessage("Test annotation";
        extras=Dict{Symbol,Any}(:key => "value"),
        tags=Symbol[:test],
        comment="Test comment")
    @test isabstractannotationmessage(annotation)

    # Test conversation memory
    memory = ConversationMemory()
    push!(memory, sys_msg)
    push!(memory, user_msg)
    @test length(memory) == 1  # system messages not counted
    @test last_message(memory) == user_msg

    # Test rendering with annotation message
    messages = [sys_msg, annotation, user_msg, ai_msg]
    rendered = render(OpenAISchema(), messages)
    @test length(rendered) == 3  # annotation message should be filtered out
end

end # module
