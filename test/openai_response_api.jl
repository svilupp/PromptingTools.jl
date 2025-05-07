using PromptingTools: OpenAISchema, render, response_to_message, create_response
using PromptingTools: AIMessageParts, TextMessagePart, ImageMessagePart, ReasoningParams, UsageMetrics
using PromptingTools: AbstractMessagePart, render_for_responses
using PromptingTools: ToolRef

@testset "openai_response_api" begin
    @testset "AIMessageParts" begin
        # Test basic construction
        msg = AIMessageParts()
        @test msg.parts isa Vector{AbstractMessagePart}
        @test isempty(msg.parts)
        @test msg.reasoning isa ReasoningParams
        @test msg.usage isa UsageMetrics
        @test msg.response_id == ""
        
        # Test with parts
        text_part = TextMessagePart(text = "Hello world")
        image_part = ImageMessagePart(url = "https://example.com/image.jpg")
        msg = AIMessageParts(
            parts = [text_part, image_part],
            response_id = "resp_123",
            tokens = (10, 20),
            elapsed = 1.5,
            cost = 0.01
        )
        @test length(msg.parts) == 2
        @test msg.parts[1] isa TextMessagePart
        @test msg.parts[2] isa ImageMessagePart
        @test msg.response_id == "resp_123"
        @test msg.tokens == (10, 20)
        @test msg.elapsed == 1.5
        @test msg.cost == 0.01
        
        # Test content property
        @test msg.content == "Hello world"
        
        # Test with multiple text parts
        text_part1 = TextMessagePart(text = "Hello")
        text_part2 = TextMessagePart(text = "world")
        msg = AIMessageParts(parts = [text_part1, text_part2])
        @test msg.content == "Hello\nworld"
    end
    
    @testset "TextMessagePart" begin
        # Test basic construction
        part = TextMessagePart(text = "Hello world")
        @test part.text == "Hello world"
        @test isempty(part.annotations)
        
        # Test with annotations
        annotations = [Dict("type" => "citation", "text" => "Source")]
        part = TextMessagePart(text = "Hello world", annotations = annotations)
        @test part.text == "Hello world"
        @test part.annotations == annotations
    end
    
    @testset "ImageMessagePart" begin
        # Test basic construction
        part = ImageMessagePart(url = "https://example.com/image.jpg")
        @test part.url == "https://example.com/image.jpg"
        @test part.detail == "auto"
        
        # Test with custom detail
        part = ImageMessagePart(url = "https://example.com/image.jpg", detail = "high")
        @test part.url == "https://example.com/image.jpg"
        @test part.detail == "high"
    end
    
    @testset "ReasoningParams" begin
        # Test basic construction
        params = ReasoningParams()
        @test params.effort === nothing
        @test params.summary === nothing
        
        # Test with values
        params = ReasoningParams(effort = "high", summary = "Detailed reasoning")
        @test params.effort == "high"
        @test params.summary == "Detailed reasoning"
    end
    
    @testset "UsageMetrics" begin
        # Test basic construction
        metrics = UsageMetrics()
        @test metrics.input_tokens == -1
        @test metrics.output_tokens == -1
        @test metrics.total_tokens == -1
        @test isempty(metrics.input_tokens_details)
        @test isempty(metrics.output_tokens_details)
        
        # Test with values
        metrics = UsageMetrics(
            input_tokens = 10,
            output_tokens = 20,
            total_tokens = 30,
            input_tokens_details = Dict("prompt_tokens" => 10),
            output_tokens_details = Dict("completion_tokens" => 20)
        )
        @test metrics.input_tokens == 10
        @test metrics.output_tokens == 20
        @test metrics.total_tokens == 30
        @test metrics.input_tokens_details["prompt_tokens"] == 10
        @test metrics.output_tokens_details["completion_tokens"] == 20
    end
    
    @testset "render_for_responses" begin
        schema = OpenAISchema()
        
        # Test with string prompt
        prompt = "Hello world"
        result = render_for_responses(schema, prompt)
        @test result == "Hello world"
        
        # Test with user message
        prompt = UserMessage("Hello world")
        result = render_for_responses(schema, prompt)
        @test result == "Hello world"
        
        # Test with conversation
        conversation = [
            SystemMessage("You are a helpful assistant"),
            UserMessage("Hello"),
            AIMessage("Hi there")
        ]
        result = render_for_responses(schema, UserMessage("How are you?"), conversation = conversation)
        @test result isa Vector
        @test length(result) == 4
        @test result[1]["role"] == "system"
        @test result[2]["role"] == "user"
        @test result[3]["role"] == "assistant"
        @test result[4]["role"] == "user"
    end
    
    @testset "render ToolRef" begin
        schema = OpenAISchema()
        
        # Test websearch tool
        tool = ToolRef(:websearch, Dict("name" => "web_search"))
        result = render(schema, tool)
        @test result["type"] == "web_search"
        @test result["name"] == "web_search"
        
        # Test file_search tool
        tool = ToolRef(:file_search, Dict(
            "name" => "file_search",
            "vector_store_ids" => ["store1", "store2"],
            "max_num_results" => 5
        ))
        result = render(schema, tool)
        @test result["type"] == "file_search"
        @test result["name"] == "file_search"
        @test result["vector_store_ids"] == ["store1", "store2"]
        @test result["max_num_results"] == 5
        
        # Test function tool
        tool = ToolRef(:function, Dict(
            "name" => "get_weather",
            "description" => "Get weather information",
            "parameters" => Dict("type" => "object", "properties" => Dict())
        ))
        result = render(schema, tool)
        @test result["type"] == "function"
        @test result["name"] == "get_weather"
        @test result["description"] == "Get weather information"
        @test haskey(result, "parameters")
        
        # Test unknown tool
        @test_throws ArgumentError render(schema, ToolRef(:unknown, Dict()))
    end
end
