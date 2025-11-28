using PromptingTools: TestEchoOpenAIResponseSchema, OpenAIResponseSchema,
                      AbstractResponseSchema, render
using PromptingTools: AIMessage, DataMessage, SystemMessage, UserMessage, AbstractMessage
using PromptingTools: aigenerate, aiextract, create_response, call_cost
using PromptingTools: tool_call_signature, parse_tool

@testset "render-OpenAIResponses" begin
    schema = OpenAIResponseSchema()

    # Test rendering a simple string prompt (no default system message for strings)
    @testset "String prompt" begin
        result = render(schema, "Hello, world!")
        @test result.input == "Hello, world!"
        # String prompts default to no_system_message=true
        @test isnothing(result.instructions)
    end

    # Test rendering a UserMessage (default system message is added)
    @testset "UserMessage" begin
        result = render(schema, UserMessage("User question"))
        @test result.input == "User question"
        # Default system message should be added for UserMessage
        @test result.instructions == "Act as a helpful AI assistant"
    end

    # Test rendering with SystemMessage and UserMessage
    @testset "SystemMessage and UserMessage" begin
        messages = [
            SystemMessage("You are a helpful assistant"),
            UserMessage("What is Julia?")
        ]
        result = render(schema, messages)
        @test result.input == "What is Julia?"
        @test result.instructions == "You are a helpful assistant"
    end

    # Test placeholder replacement
    @testset "Placeholder replacement" begin
        messages = [
            SystemMessage("You are {{role}}"),
            UserMessage("Hello, my name is {{name}}")
        ]
        result = render(schema, messages; role = "a coding assistant", name = "Alice")
        @test result.input == "Hello, my name is Alice"
        @test result.instructions == "You are a coding assistant"
    end

    # Test that UserMessage is required
    @testset "UserMessage required" begin
        messages = [SystemMessage("System only")]
        @test_throws ArgumentError render(schema, messages)
    end

    # Test rendering with only SystemMessage throws error
    @testset "Only SystemMessage throws error" begin
        @test_throws ArgumentError render(schema, [SystemMessage("Only system")])
    end
end

@testset "aigenerate-OpenAIResponses" begin
    # Create a test schema with mock response
    # Note: Use Symbol keys to match JSON3.read behavior
    mock_response = Dict{Symbol, Any}(
        :id => "resp_abc123",
        :object => "response",
        :status => "completed",
        :output => [
            Dict{Symbol, Any}(
            :type => "message",
            :content => [
                Dict{Symbol, Any}(:type => "output_text", :text => "Julia is a programming language.")
            ]
        )
        ],
        :usage => Dict{Symbol, Any}(
            :input_tokens => 15,
            :output_tokens => 25
        ),
        :reasoning => Dict{Symbol, Any}(:summary => "This is a test reasoning trace")
    )

    schema = TestEchoOpenAIResponseSchema(; response = mock_response, status = 200)

    @testset "Basic generation" begin
        result = aigenerate(schema, "What is Julia?"; model = "gpt-5.1-codex", verbose = false)

        @test result isa AIMessage
        @test result.content == "Julia is a programming language."
        @test result.tokens == (15, 25)
        @test result.status == 200
        @test haskey(result.extras, :response_id)
        @test result.extras[:response_id] == "resp_abc123"
        @test haskey(result.extras, :reasoning)

        # Check that inputs were recorded correctly
        @test schema.inputs.input == "What is Julia?"
        @test schema.model_id == "gpt-5.1-codex"
    end

    @testset "With system message" begin
        schema2 = TestEchoOpenAIResponseSchema(; response = mock_response, status = 200)
        messages = [
            SystemMessage("You are a Julia expert"),
            UserMessage("Explain multiple dispatch")
        ]
        result = aigenerate(schema2, messages; model = "gpt-5.1-codex", verbose = false)

        @test result isa AIMessage
        @test schema2.inputs.input == "Explain multiple dispatch"
        @test schema2.inputs.instructions == "You are a Julia expert"
    end

    @testset "With placeholder replacement" begin
        schema3 = TestEchoOpenAIResponseSchema(; response = mock_response, status = 200)
        messages = [
            SystemMessage("You are an expert in {{topic}}"),
            UserMessage("Tell me about {{subject}}")
        ]
        result = aigenerate(schema3, messages;
            model = "gpt-5.1-codex",
            topic = "programming languages",
            subject = "Julia performance",
            verbose = false)

        @test schema3.inputs.input == "Tell me about Julia performance"
        @test schema3.inputs.instructions == "You are an expert in programming languages"
    end

    @testset "API key handling" begin
        # Test that empty api_key falls back to ENV
        schema4 = TestEchoOpenAIResponseSchema(; response = mock_response, status = 200)

        # Should not throw even with empty api_key (falls back to ENV)
        result = aigenerate(schema4, "Test"; model = "test", api_key = "", verbose = false)
        @test result isa AIMessage

        # Test that explicit api_key is used
        result = aigenerate(
            schema4, "Test"; model = "test", api_key = "my-key", verbose = false)
        @test result isa AIMessage
    end
end

@testset "create_response-TestEcho" begin
    mock_response = Dict{Symbol, Any}(
        :id => "resp_test",
        :output => [Dict{Symbol, Any}(
            :type => "message", :content => [Dict{Symbol, Any}(:type => "output_text", :text => "Hello")])],
        :usage => Dict{Symbol, Any}(:input_tokens => 5, :output_tokens => 10)
    )

    schema = TestEchoOpenAIResponseSchema(; response = mock_response, status = 200)

    response = create_response(schema, "test-key", "test-model", "Test input";
        instructions = "Test instructions")

    @test response.status == 200
    @test response.response[:id] == "resp_test"
    @test schema.model_id == "test-model"
    @test schema.inputs.input == "Test input"
    @test schema.inputs.instructions == "Test instructions"
end

@testset "Response content extraction" begin
    # Test extraction of content from various response formats

    @testset "Standard output format" begin
        mock_response = Dict{Symbol, Any}(
            :id => "resp_1",
            :status => "completed",
            :output => [
                Dict{Symbol, Any}(
                :type => "message",
                :content => [
                    Dict{Symbol, Any}(:type => "output_text", :text => "Line 1"),
                    Dict{Symbol, Any}(:type => "output_text", :text => "Line 2")
                ]
            )
            ],
            :usage => Dict{Symbol, Any}(:input_tokens => 10, :output_tokens => 20)
        )
        schema = TestEchoOpenAIResponseSchema(; response = mock_response, status = 200)
        result = aigenerate(schema, "Test"; model = "test", verbose = false)

        # Multiple output_text items should be concatenated
        @test occursin("Line 1", result.content)
        @test occursin("Line 2", result.content)
    end

    @testset "No output content" begin
        mock_response = Dict{Symbol, Any}(
            :id => "resp_2",
            :status => "completed",
            :usage => Dict{Symbol, Any}(:input_tokens => 10, :output_tokens => 0)
        )
        schema = TestEchoOpenAIResponseSchema(; response = mock_response, status = 200)
        result = aigenerate(schema, "Test"; model = "test", verbose = false)

        @test result.content == "No output content found in response"
    end
end

@testset "Reasoning content extraction" begin
    # Test extraction of reasoning content from response
    # Uses actual OpenAI format: reasoning items have "summary" array, not "content" with "reasoning_text"
    mock_response = Dict{Symbol, Any}(
        :id => "resp_reasoning",
        :status => "completed",
        :output => [
            Dict{Symbol, Any}(
                :type => "reasoning",
                :id => "rs_123",
                :summary => [
                    Dict{Symbol, Any}(:type => "summary_text", :text => "Step 1: Think"),
                    Dict{Symbol, Any}(:type => "summary_text", :text => "Step 2: Reason")
                ]
            ),
            Dict{Symbol, Any}(
                :type => "message",
                :content => [
                    Dict{Symbol, Any}(:type => "output_text", :text => "Final answer")
                ]
            )
        ],
        :usage => Dict{Symbol, Any}(:input_tokens => 10, :output_tokens => 20)
    )
    schema = TestEchoOpenAIResponseSchema(; response = mock_response, status = 200)
    result = aigenerate(schema, "Test"; model = "test", verbose = false)

    @test result.content == "Final answer"
    @test haskey(result.extras, :reasoning_content)
    @test length(result.extras[:reasoning_content]) == 2
    @test result.extras[:reasoning_content][1] == "Step 1: Think"
    @test result.extras[:reasoning_content][2] == "Step 2: Reason"
end

@testset "aiextract-OpenAIResponses" begin
    # Test structured extraction

    # Define a test struct
    struct TestExtractStruct
        name::String
        value::Int
    end

    # Mock response with JSON content
    mock_response = Dict{Symbol, Any}(
        :id => "resp_extract",
        :status => "completed",
        :output => [
            Dict{Symbol, Any}(
            :type => "message",
            :content => [
                Dict{Symbol, Any}(
                :type => "output_text",
                :text => "{\"name\": \"test\", \"value\": 42}"
            )
            ]
        )
        ],
        :usage => Dict{Symbol, Any}(:input_tokens => 15, :output_tokens => 10)
    )

    schema = TestEchoOpenAIResponseSchema(; response = mock_response, status = 200)
    result = aiextract(schema, "Extract name and value";
        return_type = TestExtractStruct,
        model = "test",
        verbose = false)

    @test result isa DataMessage
    @test result.content isa TestExtractStruct
    @test result.content.name == "test"
    @test result.content.value == 42
    @test haskey(result.extras, :reasoning_content)
    @test haskey(result.extras, :raw_content)
end

@testset "Model registry integration" begin
    # Test that OpenAIResponseSchema models are properly registered

    @test haskey(PromptingTools.MODEL_REGISTRY, "gpt-5.1-codex")
    @test PromptingTools.MODEL_REGISTRY["gpt-5.1-codex"].schema isa OpenAIResponseSchema

    @test haskey(PromptingTools.MODEL_REGISTRY, "gpt-5.1-codex-mini")
    @test PromptingTools.MODEL_REGISTRY["gpt-5.1-codex-mini"].schema isa
          OpenAIResponseSchema
end
