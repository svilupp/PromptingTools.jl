using PromptingTools: SystemMessage, UserMessage, AIMessage, AbstractMessage
using PromptingTools: TestEchoOpenAISchema, ConversationMemory
using PromptingTools: issystemmessage, isusermessage, isaimessage, last_message,
                      last_output, register_model!, batch_start_index,
                      get_last, pprint

@testset "batch_start_index" begin
    # Test basic batch calculation
    @test batch_start_index(30, 10, 10) == 30  # Last batch of size 10
    @test batch_start_index(31, 10, 10) == 30  # Last batch of size 10
    @test batch_start_index(32, 10, 10) == 30  # Last batch of size 10
    @test batch_start_index(30, 20, 10) == 20  # Middle batch
    @test batch_start_index(31, 20, 10) == 20  # Middle batch
    @test batch_start_index(32, 20, 10) == 20  # Middle batch
    @test batch_start_index(30, 30, 10) == 10
    @test batch_start_index(31, 30, 10) == 10
    @test batch_start_index(32, 30, 10) == 10

    # Test edge cases
    @test batch_start_index(10, 10, 5) == 5   # Last batch with exact fit
    @test batch_start_index(11, 10, 5) == 5   # Last batch with exact fit
    @test batch_start_index(12, 10, 5) == 5   # Last batch with exact fit
    @test batch_start_index(13, 10, 5) == 5   # Last batch with exact fit
    @test batch_start_index(14, 10, 5) == 5   # Last batch with exact fit
    @test batch_start_index(15, 10, 5) == 10

    # Test minimum bound
    @test batch_start_index(5, 10, 10) == 1     # Should not go below 1

    @test_throws AssertionError batch_start_index(3, 5, 10)
end

@testset "ConversationMemory-type" begin
    # Test constructor and empty initialization
    mem = ConversationMemory()
    @test length(mem) == 0
    @test isempty(mem.conversation)

    # Test show method
    io = IOBuffer()
    show(io, mem)
    @test String(take!(io)) == "ConversationMemory(0 messages)"
    pprint(io, mem)
    @test String(take!(io)) == ""

    # Test push! and length
    push!(mem, SystemMessage("System prompt"))
    show(io, mem)
    @test String(take!(io)) == "ConversationMemory(0 messages)" # don't count system messages
    @test length(mem) == 1
    push!(mem, UserMessage("Hello"))
    @test length(mem) == 2
    push!(mem, AIMessage("Hi there"))
    @test length(mem) == 3

    # Test last_message and last_output
    @test last_message(mem).content == "Hi there"
    @test last_output(mem) == "Hi there"

    # Test with non-AI last message
    push!(mem, UserMessage("How are you?"))
    @test last_message(mem).content == "How are you?"
    @test last_output(mem) == "How are you?"

    pprint(io, mem)
    output = String(take!(io))
    @test occursin("How are you?", output)
end

@testset "get_last" begin
    mem = ConversationMemory()

    # Add test messages
    push!(mem, SystemMessage("System prompt"))
    push!(mem, UserMessage("First user"))
    for i in 1:15
        push!(mem, AIMessage("AI message $i"))
        push!(mem, UserMessage("User message $i"))
    end

    # Test get_last without batch_size
    recent = get_last(mem, 5)
    @test length(recent) == 4  # 5 + system + first user
    @test recent[1].content == "System prompt"
    @test recent[2].content == "First user"

    # Test get_last with batch_size=10
    recent = get_last(mem, 20; batch_size = 10)
    # @test 11 <= length(recent) <= 20  # Should be between 11-20 messages
    @test length(recent) == 14
    @test recent[1].content == "System prompt"
    @test recent[2].content == "First user"
    recent = get_last(mem, 14; batch_size = 10)
    @test length(recent) == 14
    # @test 11 <= length(recent) <= 14  # Should be between 11-20 messages
    @test recent[1].content == "System prompt"
    @test recent[2].content == "First user"

    # Test get_last with explanation
    recent = get_last(mem, 5; explain = true)
    @test startswith(recent[3].content, "[This is an automatically added explanation")

    # Test get_last with verbose
    @test_logs (:info, r"truncated to 4/32") get_last(mem, 5; verbose = true)
end

@testset "ConversationMemory-append!" begin
    mem = ConversationMemory()

    # Test append! with empty memory
    msgs = [
        SystemMessage("System prompt"),
        UserMessage("User 1"),
        AIMessage("AI 1"; run_id = 1)
    ]
    append!(mem, msgs)
    @test length(mem) == 3

    # Run again, changes nothing
    append!(mem, msgs)
    @test length(mem) == 3

    # Test append! with run_id based deduplication
    msgs = [
        SystemMessage("System prompt"),
        UserMessage("User 1"),
        AIMessage("AI 1"; run_id = 1),
        UserMessage("User 2"),
        AIMessage("AI 2"; run_id = 2)
    ]
    append!(mem, msgs)
    @test length(mem) == 5

    # Test append! with overlapping messages
    msgs_overlap = [
        SystemMessage("System prompt 2"),
        UserMessage("User 3"),
        AIMessage("AI 3"; run_id = 3),
        UserMessage("User 4"),
        AIMessage("AI 4"; run_id = 4)
    ]
    append!(mem, msgs_overlap)
    @test length(mem) == 10
end

@testset "ConversationMemory-aigenerate" begin
    # Setup mock response
    response = Dict(
        :choices => [
            Dict(:message => Dict(:content => "Hello World!"),
            :finish_reason => "stop")
        ],
        :usage => Dict(:total_tokens => 3, :prompt_tokens => 2, :completion_tokens => 1))

    schema = TestEchoOpenAISchema(; response = response, status = 200)
    register_model!(; name = "memory-echo", schema)

    mem = ConversationMemory()
    push!(mem, SystemMessage("You are a helpful assistant"))
    result = mem("Hello!"; model = "memory-echo")
    @test result.content == "Hello World!"
    @test length(mem) == 3

    # Test functor interface with history truncation
    for i in 1:5
        result = mem("Message $i"; model = "memory-echo")
    end
    result = mem("Final message"; last = 3, model = "memory-echo")
    @test length(mem) == 15 # 5x2 + final x2 + 3

    # Test aigenerate method integration
    result = aigenerate(mem; model = "memory-echo")
    @test result.content == "Hello World!"
end
