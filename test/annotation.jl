using PromptingTools: isabstractannotationmessage, annotate!, pprint
using PromptingTools: OpenAISchema, AnthropicSchema, OllamaSchema, GoogleSchema,
                      TestEchoOpenAISchema, render, NoSchema
using PromptingTools: AnnotationMessage, SystemMessage, TracerMessage, UserMessage,
                      AIMessage

@testset "Annotation Message Rendering" begin
    # Create a mix of messages including annotation messages
    messages = [
        SystemMessage("Be helpful"),
        AnnotationMessage("This is metadata", extras = Dict{Symbol, Any}(:key => "value")),
        UserMessage("Hello"),
        AnnotationMessage("More metadata"),
        AIMessage("Hi there!")  # No status needed for basic message
    ]

    @testset "Basic Message Filtering" begin
        # Test OpenAI Schema with TestEcho
        schema = TestEchoOpenAISchema(;
            response = Dict(
                "choices" => [Dict(
                    "message" => Dict("content" => "Test response", "role" => "assistant"),
                    "index" => 0, "finish_reason" => "stop")],
                "usage" => Dict(
                    "prompt_tokens" => 10, "completion_tokens" => 20, "total_tokens" => 30),
                "model" => "gpt-3.5-turbo",
                "id" => "test-id",
                "object" => "chat.completion",
                "created" => 1234567890
            ),
            status = 200
        )
        rendered = render(schema, messages)
        @test length(rendered) == 3  # Should only have system, user, and AI messages
        @test all(msg["role"] in ["system", "user", "assistant"] for msg in rendered)
        @test !any(msg -> contains(msg["content"], "metadata"), rendered)

        # Test Anthropic Schema
        rendered = render(AnthropicSchema(), messages)
        @test length(rendered.conversation) == 2  # Should have user and AI messages
        @test !isnothing(rendered.system)  # System message should be preserved separately
        @test all(msg["role"] in ["user", "assistant"] for msg in rendered.conversation)
        @test !contains(rendered.system, "metadata")  # Check system message
        @test !any(
            msg -> any(content -> contains(content["text"], "metadata"), msg["content"]),
            rendered.conversation)

        # Test Ollama Schema
        rendered = render(OllamaSchema(), messages)
        @test length(rendered) == 3  # Should only have system, user, and AI messages
        @test all(msg["role"] in ["system", "user", "assistant"] for msg in rendered)
        @test !any(msg -> contains(msg["content"], "metadata"), rendered)

        # Test Google Schema
        rendered = render(GoogleSchema(), messages)
        @test length(rendered) == 2  # Google schema combines system message with first user message
        @test all(msg[:role] in ["user", "model"] for msg in rendered)  # Google uses "model" instead of "assistant"
        @test !any(
            msg -> any(part -> contains(part["text"], "metadata"), msg[:parts]), rendered)

        # Create a basic NoSchema
        schema = NoSchema()
        rendered = render(schema, messages)
        @test length(rendered) == 3
        @test all(!isabstractannotationmessage, rendered)
    end
end
