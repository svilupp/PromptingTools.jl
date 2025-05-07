using PromptingTools: OpenAISchema, render, AIMessage
using PromptingTools: ToolRef
using PromptingTools: UserMessage, SystemMessage

@testset "openai_response_api_simplified" begin
    @testset "render_for_responses" begin
        schema = OpenAISchema()
        
        # Test with string prompt
        prompt = "Hello world"
        result = PromptingTools.render_for_responses(schema, prompt)
        @test result == "Hello world"
        
        # Test with user message
        prompt = UserMessage("Hello world")
        result = PromptingTools.render_for_responses(schema, prompt)
        @test result == "Hello world"
        
        # Test with conversation
        conversation = [
            SystemMessage("You are a helpful assistant"),
            UserMessage("Hello"),
            AIMessage("Hi there")
        ]
        result = PromptingTools.render_for_responses(schema, UserMessage("How are you?"), conversation = conversation)
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
        tool = ToolRef(ref=:websearch, extras=Dict("name" => "web_search"))
        result = PromptingTools.render(schema, tool)
        @test result["type"] == "web_search"
        @test result["name"] == "web_search"
        
        # Test file_search tool
        tool = ToolRef(ref=:file_search, extras=Dict(
            "name" => "file_search",
            "vector_store_ids" => ["store1", "store2"],
            "max_num_results" => 5
        ))
        result = PromptingTools.render(schema, tool)
        @test result["type"] == "file_search"
        @test result["name"] == "file_search"
        @test result["vector_store_ids"] == ["store1", "store2"]
        @test result["max_num_results"] == 5
        
        # Test function tool
        tool = ToolRef(ref=:function, extras=Dict(
            "name" => "get_weather",
            "description" => "Get weather information",
            "parameters" => Dict("type" => "object", "properties" => Dict())
        ))
        result = PromptingTools.render(schema, tool)
        @test result["type"] == "function"
        @test result["name"] == "get_weather"
        @test result["description"] == "Get weather information"
        @test haskey(result, "parameters")
        
        # Test unknown tool
        @test_throws ArgumentError PromptingTools.render(schema, ToolRef(ref=:unknown, extras=Dict()))
    end
end
