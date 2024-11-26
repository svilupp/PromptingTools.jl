using Test
using PromptingTools
using PromptingTools: TestEchoOpenAISchema, render, SystemMessage, UserMessage, AIMessage, AnnotationMessage
using PromptingTools: OpenAISchema, AnthropicSchema, OllamaSchema, GoogleSchema

@testset "AnnotationMessage" begin
    # Test creation and basic properties
    @testset "Basic Construction" begin
        msg = AnnotationMessage(content="Test content")
        @test msg.content == "Test content"
        @test isempty(msg.extras)
        @test !isnothing(msg.run_id)
    end

    # Test with all fields
    @testset "Full Construction" begin
        msg = AnnotationMessage(
            content="Full test",
            extras=Dict{Symbol,Any}(:key => "value"),
            tags=[:test, :example],
            comment="Test comment"
        )
        @test msg.content == "Full test"
        @test msg.extras[:key] == "value"
        @test msg.tags == [:test, :example]
        @test msg.comment == "Test comment"
    end

    # Test annotate! utility
    @testset "annotate! utility" begin
        # Test with vector of messages
        messages = [SystemMessage("System"), UserMessage("User")]
        annotated = annotate!(messages, "Annotation")
        @test length(annotated) == 3
        @test annotated[1] isa AnnotationMessage
        @test annotated[1].content == "Annotation"

        # Test with single message
        message = UserMessage("Single")
        annotated = annotate!(message, "Single annotation")
        @test length(annotated) == 2
        @test annotated[1] isa AnnotationMessage
        @test annotated[1].content == "Single annotation"

        # Test annotation placement with existing annotations
        messages = [
            AnnotationMessage("First"),
            SystemMessage("System"),
            UserMessage("User")
        ]
        annotated = annotate!(messages, "Second")
        @test length(annotated) == 4
        @test annotated[2] isa AnnotationMessage
        @test annotated[2].content == "Second"
    end

    # Test serialization
    @testset "Serialization" begin
        original = AnnotationMessage(
            content="Test",
            extras=Dict{Symbol,Any}(:key => "value"),
            tags=[:test],
            comment="Comment"
        )

        # Convert to Dict and back
        dict = Dict(original)
        reconstructed = convert(AnnotationMessage, dict)

        @test reconstructed.content == original.content
        @test reconstructed.extras == original.extras
        @test reconstructed.tags == original.tags
        @test reconstructed.comment == original.comment
    end

    # Test rendering skipping across all providers
    @testset "Render Skipping" begin
        # Create a mix of messages including annotation messages
        messages = [
            SystemMessage("Be helpful"),
            AnnotationMessage("This is metadata", extras=Dict{Symbol,Any}(:key => "value")),
            UserMessage("Hello"),
            AnnotationMessage("More metadata"),
            AIMessage("Hi there!")
        ]

        # Additional edge cases
        messages_complex = [
            AnnotationMessage("Metadata 1", extras=Dict{Symbol,Any}(:key => "value")),
            AnnotationMessage("Metadata 2", extras=Dict{Symbol,Any}(:key2 => "value2")),
            SystemMessage("Be helpful"),
            AnnotationMessage("Metadata 3", tags=[:important]),
            UserMessage("Hello"),
            AnnotationMessage("Metadata 4", comment="For debugging"),
            AIMessage("Hi there!"),
            AnnotationMessage("Metadata 5", extras=Dict{Symbol,Any}(:key3 => "value3"))
        ]

        # Test OpenAI Schema with TestEcho
        schema = TestEchoOpenAISchema(
            response=Dict(
                "choices" => [Dict("message" => Dict("content" => "Test response", "role" => "assistant"), "index" => 0, "finish_reason" => "stop")],
                "usage" => Dict("prompt_tokens" => 10, "completion_tokens" => 20, "total_tokens" => 30),
                "model" => "gpt-3.5-turbo",
                "id" => "test-id",
                "object" => "chat.completion",
                "created" => 1234567890
            ),
            status=200
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
        @test !any(msg -> any(content -> contains(content["text"], "metadata"), msg["content"]), rendered.conversation)

        # Test Ollama Schema
        rendered = render(OllamaSchema(), messages)
        @test length(rendered) == 3  # Should only have system, user, and AI messages
        @test all(msg["role"] in ["system", "user", "assistant"] for msg in rendered)
        @test !any(msg -> contains(msg["content"], "metadata"), rendered)

        # Test Google Schema
        rendered = render(GoogleSchema(), messages)
        @test length(rendered) == 2  # Google schema combines system message with first user message
        @test all(msg[:role] in ["user", "model"] for msg in rendered)  # Google uses "model" instead of "assistant"
        @test !any(msg -> any(part -> contains(part["text"], "metadata"), msg[:parts]), rendered)

        # Test complex edge cases
        @testset "Complex Edge Cases" begin
            for schema in [TestEchoOpenAISchema(), AnthropicSchema(), OllamaSchema(), GoogleSchema()]
                rendered = render(schema, messages_complex)

                if schema isa AnthropicSchema
                    @test length(rendered.conversation) == 2  # user and AI only
                    @test !isnothing(rendered.system)  # system preserved
                else
                    @test length(rendered) == (schema isa GoogleSchema ? 2 : 3)  # Google schema combines system with user message
                end

                # Test no metadata leaks through
                for i in 1:5
                    if schema isa GoogleSchema
                        @test !any(msg -> any(part -> contains(part["text"], "Metadata $i"), msg[:parts]), rendered)
                    elseif schema isa AnthropicSchema
                        @test !any(msg -> any(content -> contains(content["text"], "Metadata $i"), msg["content"]), rendered.conversation)
                        @test !contains(rendered.system, "Metadata $i")
                    else
                        @test !any(msg -> contains(msg["content"], "Metadata $i"), rendered)
                    end
                end
            end
        end
    end
end
