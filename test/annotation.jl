using PromptingTools: isabstractannotationmessage, annotate!, pprint
using PromptingTools: OpenAISchema, AnthropicSchema, OllamaSchema, GoogleSchema, TestEchoOpenAISchema, render, NoSchema
using PromptingTools: AnnotationMessage, SystemMessage, TracerMessage,UserMessage, AIMessage

@testset "Annotation Message Rendering" begin
    # Create a mix of messages including annotation messages
    messages = [
        SystemMessage("Be helpful"),
        AnnotationMessage("This is metadata", extras=Dict{Symbol,Any}(:key => "value")),
        UserMessage("Hello"),
        AnnotationMessage("More metadata"),
        AIMessage("Hi there!")  # No status needed for basic message
    ]

    @testset "Basic Message Filtering" begin
        # Test OpenAI Schema with TestEcho
        schema = TestEchoOpenAISchema(; 
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
    end
end


@testset "AnnotationMessage" begin
    # Test creation and basic properties
    annotation = AnnotationMessage(
        content="Test annotation",
        extras=Dict{Symbol,Any}(:key => "value"),
        tags=[:debug, :test],
        comment="Test comment"
    )
    @test annotation.content == "Test annotation"
    @test annotation.extras[:key] == "value"
    @test :debug in annotation.tags
    @test annotation.comment == "Test comment"
    @test isabstractannotationmessage(annotation)
    @test !isabstractannotationmessage(UserMessage("test"))

    # Test that annotations are filtered out during rendering
    messages = [
        SystemMessage("System prompt"),
        UserMessage("User message"),
        AnnotationMessage(content="Debug info", comment="Debug note"),
        AIMessage("AI response")
    ]

    # Create a basic schema for testing
    schema = NoSchema()
    rendered = render(schema, messages)

    # Verify annotation message is not in rendered output
    @test length(rendered) == 3  # Only system, user, and AI messages
    @test all(!isabstractannotationmessage, rendered)

    # Test annotate! utility
    msgs = [UserMessage("Hello"), AIMessage("Hi")]
    msgs=annotate!(msgs, "Debug info", tags=[:debug])
    @test length(msgs) == 3
    @test isabstractannotationmessage(msgs[1])
    @test msgs[1].tags == [:debug]

    # Test single message annotation
    msg = UserMessage("Test")
    result = annotate!(msg, "Annotation", comment="Note")
    @test length(result) == 2
    @test isabstractannotationmessage(result[1])
    @test result[1].comment == "Note"

    # Test pretty printing
    io = IOBuffer()
    pprint(io, annotation)
    output = String(take!(io))
    @test contains(output, "Test annotation")
    @test contains(output, "debug")
    @test contains(output, "Test comment")
end
