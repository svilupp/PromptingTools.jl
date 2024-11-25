using Test
using PromptingTools
using PromptingTools: SystemMessage, UserMessage, AIMessage, AbstractMessage
using PromptingTools: issystemmessage, isusermessage, isaimessage

@testset "ConversationMemory Core" begin
    # Test constructor
    mem = ConversationMemory()
    @test length(mem.conversation) == 0

    # Test push!
    push!(mem, SystemMessage("System"))
    @test length(mem.conversation) == 1
    @test issystemmessage(mem.conversation[1])

    # Test append!
    msgs = [UserMessage("User1"), AIMessage("AI1")]
    append!(mem, msgs)
    @test length(mem.conversation) == 3

    # Test get_last basic functionality
    result = get_last(mem, 2)
    @test length(result) == 3  # system + requested 2
    @test issystemmessage(result[1])
    @test result[end].content == "AI1"

    # Test show method
    mem_show = ConversationMemory()
    push!(mem_show, SystemMessage("System"))
    push!(mem_show, UserMessage("User1"))
    @test sprint(show, mem_show) == "ConversationMemory(1 messages)"  # system messages not counted

    # Test length (excluding system messages)
    mem_len = ConversationMemory()
    push!(mem_len, SystemMessage("System"))
    @test length(mem_len) == 0  # system message not counted
    push!(mem_len, UserMessage("User1"))
    @test length(mem_len) == 1
    push!(mem_len, AIMessage("AI1"))
    @test length(mem_len) == 2

    # Test empty memory
    empty_mem = ConversationMemory()
    @test isempty(get_last(empty_mem))
end
