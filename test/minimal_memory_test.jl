using Test
using PromptingTools
using PromptingTools: SystemMessage, UserMessage, AIMessage, AbstractMessage
using PromptingTools: issystemmessage, isusermessage, isaimessage
using PromptingTools: ConversationMemory

@testset "ConversationMemory Basic Tests" begin
    mem = ConversationMemory()

    # Test basic message addition
    push!(mem, SystemMessage("System"))
    push!(mem, UserMessage("First User"))
    @test length(mem) == 1  # system message not counted

    # Test get_last with just these messages
    result = get_last(mem, 2)
    @test length(result) == 2
    @test issystemmessage(result[1])
    @test isusermessage(result[2])
end
