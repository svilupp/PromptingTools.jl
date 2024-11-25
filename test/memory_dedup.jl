using Test
using PromptingTools
using PromptingTools: SystemMessage, UserMessage, AIMessage, AbstractMessage, ConversationMemory
using PromptingTools: issystemmessage, isusermessage, isaimessage, TestEchoOpenAISchema
using PromptingTools: last_message, last_output

@testset "ConversationMemory Deduplication" begin
    # Test run_id based deduplication
    mem = ConversationMemory()

    # Create messages with run_ids
    msgs1 = [
        SystemMessage("System", run_id=1),
        UserMessage("User1", run_id=1),
        AIMessage("AI1", run_id=1)
    ]

    msgs2 = [
        UserMessage("User2", run_id=2),
        AIMessage("AI2", run_id=2)
    ]

    # Test initial append
    append!(mem, msgs1)
    @test length(mem.conversation) == 3

    # Test appending newer messages
    append!(mem, msgs2)
    @test length(mem.conversation) == 5

    # Test appending older messages (should not append)
    append!(mem, msgs1)
    @test length(mem.conversation) == 5

    # Test mixed run_ids (should only append newer ones)
    mixed_msgs = [
        UserMessage("Old", run_id=1),
        UserMessage("New", run_id=3),
        AIMessage("Response", run_id=3)
    ]
    append!(mem, mixed_msgs)
    @test length(mem.conversation) == 7
end

@testset "ConversationMemory AIGenerate Integration" begin
    OLD_PROMPT_SCHEMA = PromptingTools.PROMPT_SCHEMA

    # Setup mock response
    response = Dict(
        :choices => [Dict(:message => Dict(:content => "Test response"), :finish_reason => "stop")],
        :usage => Dict(:total_tokens => 3, :prompt_tokens => 2, :completion_tokens => 1)
    )
    schema = TestEchoOpenAISchema(; response, status=200)
    PromptingTools.PROMPT_SCHEMA = schema

    mem = ConversationMemory()

    # Test direct aigenerate integration
    result = aigenerate(mem, "Test prompt"; model="test-model")
    @test result.content == "Test response"

    # Test functor interface with history truncation
    push!(mem, SystemMessage("System"))
    for i in 1:5
        push!(mem, UserMessage("User$i"))
        push!(mem, AIMessage("AI$i"))
    end

    result = mem("Final prompt"; last=3, model="test-model")
    @test result.content == "Test response"
    @test length(get_last(mem, 3)) == 4  # system + last 3

    # Restore schema
    PromptingTools.PROMPT_SCHEMA = OLD_PROMPT_SCHEMA
end
