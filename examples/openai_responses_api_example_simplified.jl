using PromptingTools
const PT = PromptingTools

# This example demonstrates the use of the OpenAI Responses API
# with a simplified implementation that returns standard AIMessage objects

"""
    mock_openai_response_api(prompt; previous_response_id=nothing, enable_websearch=false)

A simple function that mocks the OpenAI Responses API call.
Returns a dictionary simulating the API response.
"""
function mock_openai_response_api(prompt; previous_response_id=nothing, enable_websearch=false)
    # Create a mock response that mimics the OpenAI Responses API format
    response_id = isnothing(previous_response_id) ? "resp_" * string(rand(UInt32)) : previous_response_id
    
    # Simulate different response based on whether websearch is enabled
    if enable_websearch
        output = [
            Dict(
                "type" => "message",
                "content" => [
                    Dict(
                        "type" => "output_text",
                        "text" => "Based on my web search, " * prompt,
                        "annotations" => [
                            Dict("type" => "citation", "text" => "Source: example.com")
                        ]
                    )
                ]
            )
        ]
    else
        output = [
            Dict(
                "type" => "message",
                "content" => [
                    Dict(
                        "type" => "output_text",
                        "text" => "Response to: " * prompt
                    )
                ]
            )
        ]
    end
    
    # Create a mock response structure
    return Dict(
        "id" => response_id,
        "output" => output,
        "usage" => Dict(
            "input_tokens" => length(split(prompt)),
            "output_tokens" => 20,
            "total_tokens" => length(split(prompt)) + 20
        ),
        "reasoning" => Dict(
            "effort" => enable_websearch ? "high" : "standard",
            "summary" => "Processed the query" * (enable_websearch ? " with web search" : "")
        )
    )
end

"""
    airespond(prompt; kwargs...)

Generate a response using the OpenAI Responses API.
Returns an AIMessage with the response content and additional information in the extras field.

# Arguments
- `prompt`: The prompt to send to the API
- `previous_response_id=nothing`: ID of a previous response to continue the conversation
- `enable_websearch=false`: Whether to enable web search capabilities
- `model="gpt-4o"`: The model to use
- `verbose=true`: Whether to print verbose information

# Returns
- `AIMessage`: The response from the API with extras containing response_id and other metadata
"""
function airespond(prompt; 
                  previous_response_id=nothing, 
                  enable_websearch=false,
                  model="gpt-4o",
                  verbose=true,
                  kwargs...)
    
    # Start timing
    start_time = time()
    
    # Call the mock API (in a real implementation, this would call the actual API)
    response = mock_openai_response_api(prompt; 
                                       previous_response_id=previous_response_id, 
                                       enable_websearch=enable_websearch)
    
    # Calculate elapsed time
    elapsed = time() - start_time
    
    # Extract the text content from the response
    content = ""
    for item in response["output"]
        if item["type"] == "message"
            for msg_content in item["content"]
                if msg_content["type"] == "output_text"
                    content *= msg_content["text"] * "\n"
                end
            end
        end
    end
    content = rstrip(content)
    
    # Extract usage information
    input_tokens = response["usage"]["input_tokens"]
    output_tokens = response["usage"]["output_tokens"]
    
    # Create extras dictionary with all the additional information
    extras = Dict{Symbol, Any}(
        :response_id => response["id"],
        :reasoning => response["reasoning"],
        :usage => response["usage"],
        :full_response => response
    )
    
    # Create and return an AIMessage
    result = PT.AIMessage(
        content = content,
        tokens = (input_tokens, output_tokens),
        elapsed = elapsed,
        extras = extras
    )
    
    # Print stats if verbose
    if verbose
        @info "Response generated in $(round(elapsed, digits=2))s using $(input_tokens + output_tokens) tokens"
    end
    
    return result
end

# Example 1: Basic usage
println("Example 1: Basic usage")
response = airespond("What is the capital of France?")
println("Response: ", response.content)
println("Response ID: ", response.extras[:response_id])
println()

# Example 2: Continue a conversation
println("Example 2: Continue a conversation")
follow_up = airespond("Tell me more about its history"; 
                     previous_response_id=response.extras[:response_id])
println("Follow-up: ", follow_up.content)
println()

# Example 3: Using web search
println("Example 3: Using web search")
web_response = airespond("What are the latest developments in quantum computing?"; 
                        enable_websearch=true)
println("Web search response: ", web_response.content)
println("Reasoning effort: ", web_response.extras[:reasoning]["effort"])
println()

# Example 4: Using a different model
println("Example 4: Using a different model")
custom_model = airespond("Generate a haiku about programming"; 
                        model="gpt-4-turbo")
println("Custom model response: ", custom_model.content)
