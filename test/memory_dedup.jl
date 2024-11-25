using Test
using PromptingTools
using PromptingTools: SystemMessage, UserMessage, AIMessage, AbstractMessage, ConversationMemory
using PromptingTools: issystemmessage, isusermessage, isaimessage, TestEchoOpenAISchema
using PromptingTools: last_message, last_output, register_model!

# Setup test schema for dedup tests
const DEDUP_TEST_RESPONSE = Dict(
    "model" => "gpt-3.5-turbo",
    "choices" => [Dict("message" => Dict("role" => "assistant", "content" => "Dedup test response"))],
    "usage" => Dict("total_tokens" => 3, "prompt_tokens" => 2, "completion_tokens" => 1),
    "id" => "chatcmpl-dedup-123",
    "object" => "chat.completion",
    "created" => Int(floor(time()))
)

# Register test model for dedup tests
register_model!(;
    name = "memory-dedup-echo",
    schema = TestEchoOpenAISchema(; response=DEDUP_TEST_RESPONSE),
    cost_of_token_prompt = 0.0,
    cost_of_token_generation = 0.0,
    description = "Test echo model for memory deduplication tests"
)

let old_registry = deepcopy(PromptingTools.MODEL_REGISTRY.registry)
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
        mem = ConversationMemory()

        # Test direct aigenerate integration
        result = aigenerate(mem, "Test prompt"; model="memory-dedup-echo")
        @test result.content == "Dedup test response"

        # Test functor interface with history truncation
        push!(mem, SystemMessage("System"))
        for i in 1:5
            push!(mem, UserMessage("User$i"))
            push!(mem, AIMessage("AI$i"))
        end

        result = mem("Final prompt"; last=3, model="memory-dedup-echo")
        @test result.content == "Dedup test response"
        @test length(get_last(mem, 3)) == 4  # system + last 3
    end

    # Restore original registry
    empty!(PromptingTools.MODEL_REGISTRY.registry)
    merge!(PromptingTools.MODEL_REGISTRY.registry, old_registry)
end

    # Restore original registry
    empty!(PromptingTools.MODEL_REGISTRY.registry)
    merge!(PromptingTools.MODEL_REGISTRY.registry, old_registry)
end
