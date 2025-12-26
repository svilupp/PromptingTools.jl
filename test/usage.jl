using Test
using PromptingTools
using PromptingTools: TokenUsage, total_tokens, extract_usage, call_cost_with_cache,
                      get_cache_discounts, build_message, extract_log_prob,
                      CACHE_DISCOUNTS, call_cost, AIMessage, DataMessage, AIToolRequest,
                      ToolMessage, OpenAISchema, AnthropicSchema, OllamaSchema,
                      GoogleOpenAISchema, OpenAIResponseSchema

@testset "TokenUsage" begin
    @testset "Construction and defaults" begin
        usage = TokenUsage()
        @test usage.input_tokens == 0
        @test usage.output_tokens == 0
        @test usage.cache_read_tokens == 0
        @test usage.cache_write_tokens == 0
        @test usage.reasoning_tokens == 0
        @test usage.cost == 0.0
        @test usage.elapsed == 0.0
        @test usage.model_id == ""
        @test isempty(usage.extras)
    end

    @testset "Construction with values" begin
        usage = TokenUsage(
            input_tokens = 100,
            output_tokens = 50,
            cache_read_tokens = 30,
            cache_write_tokens = 20,
            reasoning_tokens = 10,
            model_id = "gpt-4o",
            cost = 0.001,
            elapsed = 1.5
        )
        @test usage.input_tokens == 100
        @test usage.output_tokens == 50
        @test usage.cache_read_tokens == 30
        @test usage.cache_write_tokens == 20
        @test usage.reasoning_tokens == 10
        @test total_tokens(usage) == 100 + 50 + 30 + 20 + 10
        @test usage.model_id == "gpt-4o"
        @test usage.cost == 0.001
        @test usage.elapsed == 1.5
    end

    @testset "Addition" begin
        u1 = TokenUsage(input_tokens = 100, output_tokens = 50, cost = 0.01, elapsed = 1.0)
        u2 = TokenUsage(input_tokens = 200, output_tokens = 100, cost = 0.02, elapsed = 2.0)
        u3 = u1 + u2
        @test u3.input_tokens == 300
        @test u3.output_tokens == 150
        @test u3.cost ≈ 0.03
        @test u3.elapsed ≈ 3.0
    end

    @testset "Display" begin
        usage = TokenUsage(input_tokens = 100, output_tokens = 50, cache_read_tokens = 30, cost = 0.001)
        io = IOBuffer()
        show(io, usage)
        str = String(take!(io))
        @test occursin("in=100", str)
        @test occursin("out=50", str)
        @test occursin("cache_read=30", str)
        @test occursin("cost=", str)
    end
end

@testset "get_cache_discounts" begin
    @testset "Schema-based lookup (Priority 1 & 2)" begin
        # Priority 1: Explicit schema parameter
        @test get_cache_discounts("any-model"; schema = OpenAISchema()).read_discount == 0.5
        @test get_cache_discounts("any-model"; schema = GoogleOpenAISchema()).read_discount ==
              0.9
        @test get_cache_discounts("any-model"; schema = AnthropicSchema()).read_discount ==
              0.9
        @test get_cache_discounts("any-model"; schema = AnthropicSchema()).write_premium ==
              0.25

        # Unknown schema defaults to 0%
        @test get_cache_discounts("any-model"; schema = OllamaSchema()).read_discount == 0.0

        # Priority 2: Model registry lookup (registered models use their schema)
        # Gemini models in registry have GoogleOpenAISchema → 90%
        @test get_cache_discounts("gemini-2.5-flash").read_discount == 0.9
        @test get_cache_discounts("gemini-1.5-pro-latest").read_discount == 0.9
        @test get_cache_discounts("gemini-3-pro-preview").read_discount == 0.9
    end

    @testset "Model name prefix matching (Priority 3)" begin
        # Exact prefix matches
        discounts = get_cache_discounts("gpt-4o")
        @test discounts.read_discount == 0.5
        @test discounts.write_premium == 0.0

        discounts = get_cache_discounts("claude")
        @test discounts.read_discount == 0.9
        @test discounts.write_premium == 0.25

        # Prefix matching for unregistered models
        @test get_cache_discounts("gpt-4o-custom-variant").read_discount == 0.5
        @test get_cache_discounts("claude-custom-model").read_discount == 0.9
    end

    @testset "Default fallback (Priority 4)" begin
        # Unknown model with no schema
        discounts = get_cache_discounts("totally-unknown-model")
        @test discounts.read_discount == 0.0
        @test discounts.write_premium == 0.0

        # CustomOpenAISchema (unknown provider) defaults to 0%
        @test get_cache_discounts("custom"; schema = PromptingTools.CustomOpenAISchema()).read_discount ==
              0.0
    end

    @testset "Custom model name with GoogleOpenAISchema" begin
        # Register a custom model with GoogleOpenAISchema
        PromptingTools.register_model!(
            name = "my-awesome-custom-gemini",
            schema = PromptingTools.GoogleOpenAISchema(),
            cost_of_token_prompt = 1e-6,
            cost_of_token_generation = 1e-6
        )

        # Should get Google 90% discount from schema, not model name!
        @test get_cache_discounts("my-awesome-custom-gemini").read_discount == 0.9
        @test get_cache_discounts("my-awesome-custom-gemini").write_premium == 0.0
    end
end

@testset "call_cost_with_cache" begin
    # Register test models for cost calculation
    PromptingTools.register_model!(
        name = "test-gpt-4",
        schema = OpenAISchema(),
        cost_of_token_prompt = 1e-5,
        cost_of_token_generation = 3e-5
    )
    PromptingTools.register_model!(
        name = "test-claude",
        schema = AnthropicSchema(),
        cost_of_token_prompt = 3e-6,
        cost_of_token_generation = 15e-6
    )

    @testset "No cache" begin
        cost = call_cost_with_cache(100, 50, 0, 0, "test-gpt-4")
        @test cost ≈ 100 * 1e-5 + 50 * 3e-5
    end

    @testset "OpenAI GPT-4 cache (50% discount)" begin
        # With 80 cached tokens out of 100 input
        cost_cached = call_cost_with_cache(100, 50, 80, 0, "test-gpt-4")
        cost_no_cache = call_cost_with_cache(100, 50, 0, 0, "test-gpt-4")
        @test cost_cached < cost_no_cache
        # 20 regular + 80 at 50% = 20 + 40 = 60 effective input tokens
        expected = 20 * 1e-5 + 80 * 1e-5 * 0.5 + 50 * 3e-5
        @test cost_cached ≈ expected
    end

    @testset "Anthropic cache (90% read discount, 25% write premium)" begin
        # Cache read: 90% discount (pay 10%)
        cost_read = call_cost_with_cache(100, 50, 80, 0, "test-claude")
        # 20 regular + 80 at 10% = 20 + 8 = 28 effective input
        expected_read = 20 * 3e-6 + 80 * 3e-6 * 0.1 + 50 * 15e-6
        @test cost_read ≈ expected_read

        # Cache write: 25% premium (pay 125%)
        cost_write = call_cost_with_cache(100, 50, 0, 50, "test-claude")
        expected_write = 100 * 3e-6 + 50 * 3e-6 * 1.25 + 50 * 15e-6
        @test cost_write ≈ expected_write
    end
end

@testset "call_cost with TokenUsage" begin
    usage = TokenUsage(
        input_tokens = 100,
        output_tokens = 50,
        model_id = "test-gpt-4",
        cost = 0.0  # Not pre-calculated
    )
    cost = call_cost(usage)
    @test cost ≈ 100 * 1e-5 + 50 * 3e-5

    # Pre-calculated cost should be returned
    usage2 = TokenUsage(
        input_tokens = 100,
        output_tokens = 50,
        model_id = "test-gpt-4",
        cost = 0.123
    )
    @test call_cost(usage2) == 0.123
end

@testset "extract_usage - OpenAI" begin
    schema = OpenAISchema()

    @testset "Basic usage extraction" begin
        resp = (
            response = Dict(
                :usage => Dict(
                :prompt_tokens => 100,
                :completion_tokens => 50,
                :total_tokens => 150
            )
            ),
            status = 200
        )
        usage = extract_usage(schema, resp; model_id = "gpt-4o")
        @test usage.input_tokens == 100
        @test usage.output_tokens == 50
        @test usage.model_id == "gpt-4o"
    end

    @testset "CamelCase keys" begin
        resp = (
            response = Dict(
                :usage => Dict(
                :promptTokens => 100,
                :completionTokens => 50
            )
            ),
            status = 200
        )
        usage = extract_usage(schema, resp)
        @test usage.input_tokens == 100
        @test usage.output_tokens == 50
    end

    @testset "With cache tokens" begin
        resp = (
            response = Dict(
                :usage => Dict(
                :prompt_tokens => 100,
                :completion_tokens => 50,
                :prompt_tokens_details => Dict(
                    :cached_tokens => 80
                )
            )
            ),
            status = 200
        )
        usage = extract_usage(schema, resp; model_id = "gpt-4o")
        @test usage.cache_read_tokens == 80
    end

    @testset "With reasoning tokens" begin
        resp = (
            response = Dict(
                :usage => Dict(
                :prompt_tokens => 100,
                :completion_tokens => 200,
                :completion_tokens_details => Dict(
                    :reasoning_tokens => 150
                )
            )
            ),
            status = 200
        )
        usage = extract_usage(schema, resp)
        @test usage.reasoning_tokens == 150
    end

    @testset "Empty/missing usage" begin
        resp = (response = Dict(), status = 200)
        usage = extract_usage(schema, resp)
        @test usage.input_tokens == 0
        @test usage.output_tokens == 0
    end
end

@testset "extract_usage - Anthropic" begin
    schema = AnthropicSchema()

    @testset "Basic usage" begin
        resp = (
            response = Dict(
                :usage => Dict(
                :input_tokens => 100,
                :output_tokens => 50
            )
            ),
            status = 200
        )
        usage = extract_usage(schema, resp; model_id = "claude-sonnet-4-20250514")
        @test usage.input_tokens == 100
        @test usage.output_tokens == 50
    end

    @testset "With cache tokens" begin
        resp = (
            response = Dict(
                :usage => Dict(
                :input_tokens => 100,
                :output_tokens => 50,
                :cache_read_input_tokens => 80,
                :cache_creation_input_tokens => 20
            )
            ),
            status = 200
        )
        usage = extract_usage(schema, resp; model_id = "claude-sonnet-4-20250514")
        @test usage.cache_read_tokens == 80
        @test usage.cache_write_tokens == 20
    end
end

@testset "extract_usage - Ollama" begin
    schema = OllamaSchema()

    resp = (
        response = Dict(
            :prompt_eval_count => 100,
            :eval_count => 50
        ),
        status = 200
    )
    usage = extract_usage(schema, resp)
    @test usage.input_tokens == 100
    @test usage.output_tokens == 50
    @test usage.cost == 0.0  # Ollama is free
end

@testset "extract_log_prob" begin
    @testset "With log probs" begin
        choice = Dict(
            :logprobs => Dict(
            :content => [
            Dict(:logprob => -0.5),
            Dict(:logprob => -0.3),
            Dict(:logprob => -0.2)
        ]
        )
        )
        log_prob = extract_log_prob(choice)
        @test log_prob ≈ -1.0
    end

    @testset "Without log probs" begin
        choice = Dict()
        @test isnothing(extract_log_prob(choice))

        choice2 = Dict(:logprobs => nothing)
        @test isnothing(extract_log_prob(choice2))
    end
end

@testset "build_message" begin
    usage = TokenUsage(
        input_tokens = 100,
        output_tokens = 50,
        model_id = "gpt-4o",
        cost = 0.001,
        elapsed = 1.5
    )

    @testset "AIMessage" begin
        msg = build_message(AIMessage, "Hello!", usage;
            status = 200,
            finish_reason = "stop",
            run_id = 12345)

        @test msg isa AIMessage
        @test msg.content == "Hello!"
        @test msg.tokens == (100, 50)
        @test msg.cost ≈ 0.001
        @test msg.elapsed ≈ 1.5
        @test !isnothing(msg.usage)
        @test msg.usage === usage
        @test msg.finish_reason == "stop"
        @test msg.status == 200
        @test msg.run_id == 12345
    end

    @testset "DataMessage" begin
        data = Dict(:key => "value")
        msg = build_message(DataMessage, data, usage;
            status = 200,
            finish_reason = "stop")

        @test msg isa DataMessage
        @test msg.content == data
        @test msg.tokens == (100, 50)
        @test msg.usage === usage
    end

    @testset "AIToolRequest" begin
        tool = ToolMessage(; tool_call_id = "call_123", raw = "{}", name = "test")
        msg = build_message(AIToolRequest, "Calling tool", usage;
            tool_calls = [tool],
            status = 200)

        @test msg isa AIToolRequest
        @test msg.content == "Calling tool"
        @test length(msg.tool_calls) == 1
        @test msg.tool_calls[1].tool_call_id == "call_123"
        @test msg.usage === usage
    end
end

@testset "AIMessage with usage field" begin
    usage = TokenUsage(input_tokens = 100, output_tokens = 50, cost = 0.01)
    msg = AIMessage(; content = "Hello", usage = usage)

    @test !isnothing(msg.usage)
    @test msg.usage === usage
    @test msg.usage.input_tokens == 100

    # Both legacy and usage fields can be set
    msg2 = AIMessage(; content = "Hello", tokens = (100, 50), usage = usage)
    @test msg2.tokens == (100, 50)
    @test !isnothing(msg2.usage)
end
