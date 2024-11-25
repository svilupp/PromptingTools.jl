using Test
using PromptingTools
using PromptingTools: SystemMessage, UserMessage, AIMessage, AbstractMessage, ConversationMemory
using PromptingTools: issystemmessage, isusermessage, isaimessage

@testset "ConversationMemory Basic" begin
    # Test constructor only
    mem = ConversationMemory()
    @test isa(mem, ConversationMemory)
    @test isempty(mem.conversation)

    # Test push! with system message
    push!(mem, SystemMessage("Test system"))
    @test length(mem.conversation) == 1
    @test issystemmessage(mem.conversation[1])

    # Test push! with user message
    push!(mem, UserMessage("Test user"))
    @test length(mem.conversation) == 2
    @test isusermessage(mem.conversation[2])

    # Test get_last basic functionality
    recent = get_last(mem, 2)
    @test length(recent) == 2
    @test recent[1].content == "Test system"
    @test recent[2].content == "Test user"
end
