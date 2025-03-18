using Test
using PromptingTools

@testset "Anthropic thinking budget validation" begin
    # Test that an assertion error is thrown when thinking budget exceeds max_tokens
    @test_throws AssertionError PromptingTools.anthropic_api(
        PromptingTools.AnthropicSchema(),
        [Dict("role" => "user", "content" => [Dict("type" => "text", "text" => "Hello")])];
        model = "claude-3-haiku-20240307",
        max_tokens = 100,
        thinking = Dict(:type => "enabled", :budget_tokens => 200)
    )
    
    # Set up a dummy response for the test echo schema
    dummy_response = Dict(
        "content" => [Dict("text" => "Test response", "type" => "text")],
        "model" => "claude-3-haiku-20240307",
        "id" => "test-id",
        "type" => "message",
        "role" => "assistant",
        "stop_reason" => "end_turn",
        "usage" => Dict("input_tokens" => 10, "output_tokens" => 20)
    )
    
    # Test that no error is thrown when thinking budget is equal to max_tokens
    try
        PromptingTools.anthropic_api(
            PromptingTools.TestEchoAnthropicSchema(
                response = dummy_response,
                status = 200
            ),
            [Dict("role" => "user", "content" => [Dict("type" => "text", "text" => "Hello")])];
            model = "claude-3-haiku-20240307",
            max_tokens = 100,
            thinking = Dict(:type => "enabled", :budget_tokens => 100)
        )
        @test true  # No exception thrown
    catch e
        @test false  # Should not reach here
    end
    
    # Test that no error is thrown when thinking budget is less than max_tokens
    try
        PromptingTools.anthropic_api(
            PromptingTools.TestEchoAnthropicSchema(
                response = dummy_response,
                status = 200
            ),
            [Dict("role" => "user", "content" => [Dict("type" => "text", "text" => "Hello")])];
            model = "claude-3-haiku-20240307",
            max_tokens = 100,
            thinking = Dict(:type => "enabled", :budget_tokens => 50)
        )
        @test true  # No exception thrown
    catch e
        @test false  # Should not reach here
    end
end
