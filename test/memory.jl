using Test
using PromptingTools
using PromptingTools: SystemMessage, UserMessage, AIMessage, AbstractMessage
using PromptingTools: TestEchoOpenAISchema, ConversationMemory
using PromptingTools: issystemmessage, isusermessage, isaimessage, last_message, last_output, register_model!
using HTTP, JSON3

const TEST_RESPONSE = Dict(
    "model" => "gpt-3.5-turbo",
    "choices" => [Dict("message" => Dict("role" => "assistant", "content" => "Echo response"))],
    "usage" => Dict("total_tokens" => 3, "prompt_tokens" => 2, "completion_tokens" => 1),
    "id" => "chatcmpl-123",
    "object" => "chat.completion",
    "created" => Int(floor(time()))
)

@testset "ConversationMemory" begin
    # Setup mock server for all tests
    PORT = rand(10000:20000)
    server = Ref{Union{Nothing, HTTP.Server}}(nothing)

    try
        server[] = HTTP.serve!(PORT; verbose=-1) do req
            return HTTP.Response(200, ["Content-Type" => "application/json"], JSON3.write(TEST_RESPONSE))
        end

        # Register test model
        register_model!(;
            name = "memory-echo",
            schema = TestEchoOpenAISchema(; response=TEST_RESPONSE),
            api_kwargs = (; url = "http://localhost:$(PORT)")
        )

        # Test constructor and empty initialization
        mem = ConversationMemory()
        @test length(mem) == 0
        @test isempty(mem.conversation)

        # Test show method
        io = IOBuffer()
        show(io, mem)
        @test String(take!(io)) == "ConversationMemory(0 messages)"

        # Test push! and length
        push!(mem, SystemMessage("System prompt"))
        @test length(mem) == 0  # System messages don't count in length
        push!(mem, UserMessage("Hello"))
        @test length(mem) == 1
        push!(mem, AIMessage("Hi there"))
        @test length(mem) == 2

        # Test last_message and last_output
        @test last_message(mem).content == "Hi there"
        @test last_output(mem).content == "Hi there"

        # Test with non-AI last message
        push!(mem, UserMessage("How are you?"))
        @test last_message(mem).content == "How are you?"
        @test last_output(mem).content == "Hi there"  # Still returns last AI message

        @testset "Message Retrieval" begin
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
            @test length(recent) == 7  # 5 + system + first user
            @test recent[1].content == "System prompt"
            @test recent[2].content == "First user"

            # Test get_last with batch_size=10
            recent = get_last(mem, 20; batch_size=10)
            @test 11 <= length(recent) <= 20  # Should be between 11-20 messages
            @test recent[1].content == "System prompt"
            @test recent[2].content == "First user"

            # Test get_last with explanation
            recent = get_last(mem, 5; explain=true)
            @test contains(recent[3].content, "For efficiency reasons")

            # Test get_last with verbose
            io = IOBuffer()
            redirect_stdout(io) do
                get_last(mem, 5; verbose=true)
            end
            output = String(take!(io))
            @test contains(output, "Total messages:")
            @test contains(output, "Keeping:")
        end

        @testset "Message Deduplication" begin
            mem = ConversationMemory()

            # Test append! with empty memory
            msgs = [
                SystemMessage("System prompt"),
                UserMessage("User 1"),
                AIMessage("AI 1")
            ]
            append!(mem, msgs)
            @test length(mem) == 2  # excluding system message

            # Test append! with run_id based deduplication
            msgs_with_ids = [
                SystemMessage("System prompt"; run_id=1),
                UserMessage("User 2"; run_id=2),
                AIMessage("AI 2"; run_id=2)
            ]
            append!(mem, msgs_with_ids)
            @test length(mem) == 4  # Should add new messages with higher run_id

            # Test append! with overlapping messages
            msgs_overlap = [
                UserMessage("User 2"; run_id=1),  # Old run_id, should be ignored
                AIMessage("AI 2"; run_id=1),      # Old run_id, should be ignored
                UserMessage("User 3"; run_id=3),  # New run_id, should be added
                AIMessage("AI 3"; run_id=3)       # New run_id, should be added
            ]
            append!(mem, msgs_overlap)
            @test length(mem) == 6  # Should only add the new messages
        end

        @testset "Generation Interface" begin
            mem = ConversationMemory()

            # Test functor interface basic usage
            push!(mem, SystemMessage("You are a helpful assistant"))
            result = mem("Hello!"; model="memory-echo")
            @test result.content == "Echo response"
            @test length(mem) == 2  # User message + AI response

            # Test functor interface with history truncation
            for i in 1:5
                result = mem("Message $i"; model="memory-echo")
            end
            result = mem("Final message"; last=3, model="memory-echo")
            @test length(get_last(mem, 3)) == 5  # 3 messages + system + first user

            # Test aigenerate method integration
            result = aigenerate(mem, "Direct generation"; model="memory-echo")
            @test result.content == "Echo response"
            @test length(mem) == 14  # Previous messages + new exchange
        end
    finally
        # Ensure server is properly closed
        !isnothing(server[]) && close(server[])
    end
end
