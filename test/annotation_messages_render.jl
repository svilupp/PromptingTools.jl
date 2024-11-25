using Test
using PromptingTools
using PromptingTools: OpenAISchema, AnthropicSchema, OllamaSchema, GoogleSchema, TestEchoOpenAISchema

@testset "Annotation Message Rendering" begin
    # Create a mix of messages including annotation messages
    messages = [
        SystemMessage("Be helpful"),
        AnnotationMessage("This is metadata", extras=Dict{Symbol,Any}(:key => "value")),
        UserMessage("Hello"),
        AnnotationMessage("More metadata"),
        AIMessage("Hi there!")  # No status needed for basic message
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

    @testset "Basic Message Filtering" begin
        # Test OpenAI Schema with TestEcho
        schema = TestEchoOpenAISchema(
            response=Dict("choices" => [Dict("message" => Dict("content" => "Test response", "role" => "assistant"))]),
            status=200
        )
        rendered = render(schema, messages)
        @test length(rendered) == 3  # Should only have system, user, and AI messages
        @test all(msg["role"] in ["system", "user", "assistant"] for msg in rendered)
        @test !any(contains.(getindex.(rendered, "content"), "metadata"))

        # Test Anthropic Schema
        rendered = render(AnthropicSchema(), messages)
        @test length(rendered.conversation) == 2  # Should have user and AI messages
        @test !isnothing(rendered.system)  # System message should be preserved separately
        @test all(msg["role"] in ["user", "assistant"] for msg in rendered.conversation)
        @test !any(contains(rendered.system, "metadata"))  # Check system message
        @test !any(contains.(getindex.(getindex.(rendered.conversation, "content"), 1, "text"), "metadata"))

        # Test Ollama Schema
        rendered = render(OllamaSchema(), messages)
        @test length(rendered) == 3  # Should only have system, user, and AI messages
        @test all(msg["role"] in ["system", "user", "assistant"] for msg in rendered)
        @test !any(contains.(getindex.(rendered, "content"), "metadata"))

        # Test Google Schema
        rendered = render(GoogleSchema(), messages)
        @test length(rendered) == 3  # Should only have system, user, and AI messages
        @test all(msg[:role] in ["user", "model"] for msg in rendered)  # Google uses "model" instead of "assistant"
        @test !any(contains.(first.(getindex.(getindex.(rendered, :parts))), "metadata"))
    end

    @testset "Complex Edge Cases" begin
        # Test with multiple consecutive annotation messages
        for schema in [TestEchoOpenAISchema(), AnthropicSchema(), OllamaSchema(), GoogleSchema()]
            rendered = render(schema, messages_complex)

            if schema isa AnthropicSchema
                @test length(rendered.conversation) == 2  # user and AI only
                @test !isnothing(rendered.system)  # system preserved
            else
                @test length(rendered) == 3  # system, user, and AI only
            end

            # Test no metadata leaks through
            for i in 1:5
                if schema isa GoogleSchema
                    @test !any(contains.(first.(getindex.(getindex.(rendered, :parts))), "Metadata $i"))
                elseif schema isa AnthropicSchema
                    @test !any(contains.(getindex.(getindex.(rendered.conversation, "content"), 1, "text"), "Metadata $i"))
                    @test !contains(rendered.system, "Metadata $i")
                else
                    @test !any(contains.(getindex.(rendered, "content"), "Metadata $i"))
                end
            end
        end
    end
end
