using PromptingTools

# Set your API key if not already set
# ENV["OPENAI_API_KEY"] = "your-api-key"

# Simple text response
response = airespond("What is the capital of France?")
println("Response: ", response.content)
println("Number of parts: ", length(response.parts))
println("Tokens used: ", response.tokens)

# Continue a conversation
second_response = airespond("Tell me more about its history."; 
                           previous_response_id=response.response_id)
println("\nFollow-up response: ", second_response.content)

# Using tools (web search)
web_response = airespond("What are the latest developments in quantum computing?";
                       tools=[PromptingTools.ToolRef(:websearch, Dict("name" => "web_search"))])
println("\nWeb search response: ", web_response.content)

# Using high reasoning effort
reasoned_response = airespond("Explain the concept of quantum entanglement.";
                            reasoning=Dict("effort" => "high"))
println("\nReasoned response: ", reasoned_response.content)
println("Reasoning effort: ", reasoned_response.reasoning.effort)

# Using a custom model
custom_response = airespond("Generate a haiku about programming.";
                          model="gpt-4o")
println("\nCustom model response: ", custom_response.content)
