using Test
using PromptingTools
using PromptingTools: SystemMessage, UserMessage, AIMessage, AbstractMessage
using PromptingTools: last_message, last_output

@testset "Message Utilities" begin
    @testset "last_message" begin
        # Test empty vector
        @test last_message(AbstractMessage[]) === nothing

        # Test single message
        msgs = [UserMessage("Hello")]
        @test last_message(msgs).content == "Hello"

        # Test multiple messages
        msgs = [
            SystemMessage("System"),
            UserMessage("User"),
            AIMessage("AI")
        ]
        @test last_message(msgs).content == "AI"
    end

    @testset "last_output" begin
        # Test empty vector
        @test last_output(AbstractMessage[]) === nothing

        # Test no AI messages
        msgs = [
            SystemMessage("System"),
            UserMessage("User")
        ]
        @test last_output(msgs) === nothing

        # Test with AI messages
        msgs = [
            SystemMessage("System"),
            UserMessage("User"),
            AIMessage("AI 1"),
            UserMessage("User 2"),
            AIMessage("AI 2")
        ]
        @test last_output(msgs).content == "AI 2"

        # Test with non-AI last message
        push!(msgs, UserMessage("Last user"))
        @test last_output(msgs).content == "AI 2"
    end
end
