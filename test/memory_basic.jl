using Test
using PromptingTools
using PromptingTools: SystemMessage, UserMessage, AIMessage, AbstractMessage, ConversationMemory
using PromptingTools: issystemmessage, isusermessage, isaimessage, TestEchoOpenAISchema
using PromptingTools: last_message, last_output, register_model!

# Setup test schema for all tests
const TEST_RESPONSE = Dict(
    "model" => "gpt-3.5-turbo",
    "choices" => [Dict("message" => Dict("role" => "assistant", "content" => "Echo response"))],
    "usage" => Dict("total_tokens" => 3, "prompt_tokens" => 2, "completion_tokens" => 1),
    "id" => "chatcmpl-123",
    "object" => "chat.completion",
    "created" => Int(floor(time()))
)

# Register test model
register_model!(;
    name = "memory-basic-echo",
    schema = TestEchoOpenAISchema(; response=TEST_RESPONSE),
    cost_of_token_prompt = 0.0,
    cost_of_token_generation = 0.0,
    description = "Test echo model for memory basic tests"
)

let old_registry = copy(PromptingTools.MODEL_REGISTRY.registry)
    @testset "ConversationMemory Basic Operations" begin
        # Single basic test
        mem = ConversationMemory()
        @test length(mem.conversation) == 0

        # Test single push
        push!(mem, SystemMessage("Test"))
        @test length(mem.conversation) == 1
    end

    @testset "ConversationMemory with AI Generation" begin
        # Test memory with AI generation
        mem = ConversationMemory()
        push!(mem, SystemMessage("You are a helpful assistant"))
        result = mem("Hello!"; model="memory-basic-echo")

        @test length(mem.conversation) == 3  # system + user + ai
        @test last_message(mem).content == "Hello!"
        @test isaimessage(last_message(mem))
    end

    @testset "ConversationMemory Advanced Features" begin
        # Test batch size handling
        mem = ConversationMemory()

        # Add multiple messages
        push!(mem, SystemMessage("System prompt"))
        for i in 1:15
            push!(mem, UserMessage("User message $i"))
            push!(mem, AIMessage("AI response $i"))
        end

        # Test batch size truncation
        recent = get_last(mem, 10; batch_size=5)
        @test length(recent) == 11  # system + first user + last 9 messages
        @test issystemmessage(recent[1])
        @test isusermessage(recent[2])

        # Test explanation message
        recent_explained = get_last(mem, 10; batch_size=5, explain=true)
        @test length(recent_explained) == 11
        @test occursin("truncated", first(filter(isaimessage, recent_explained)).content)

        # Test verbose output
        @test_nowarn get_last(mem, 10; batch_size=5, verbose=true)
    end

    # Restore original registry
    empty!(PromptingTools.MODEL_REGISTRY.registry)
    merge!(PromptingTools.MODEL_REGISTRY.registry, old_registry)
end
