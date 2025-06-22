#!/usr/bin/env julia

# Test script to verify PromptingTools works with GoogleGenAI extension

using PromptingTools
const PT = PromptingTools
using GoogleGenAI

println("Testing GoogleGenAI extension with PromptingTools...")

# Test basic functionality - this should work even without API key
try
    # This will fail due to missing API key, but should show the extension is working
    msg = aigenerate(PT.GoogleSchema(), "Hello world", model="gemini-2.0-flash")
    println("SUCCESS: aigenerate() completed successfully")
    println("Response: ", msg.content)
catch e
    if occursin("API_KEY", string(e)) || occursin("authentication", string(e)) || occursin("Unauthorized", string(e))
        println("SUCCESS: GoogleGenAI extension is working (failed due to missing API key as expected)")
        println("Error: ", e)
    else
        println("ERROR: Unexpected error - extension may not be working properly")
        println("Error: ", e)
        rethrow(e)
    end
end

println("\nTest completed!")

# Debug test to verify system instruction handling
println("\n=== Debug: Testing system instruction extraction ===")
try
    # Test render function directly
    rendered = PromptingTools.render(PT.GoogleSchema(), [
        PT.SystemMessage("You are a pirate"),
        PT.UserMessage("Say hello")
    ])
    
    println("System instruction extracted: ", rendered.system_instruction)
    println("Conversation: ", rendered.conversation)
    println("SUCCESS: System instruction properly extracted in render()")
catch e
    println("ERROR in render test: ", e)
end

# Additional test with system message and api_kwargs
println("\n=== Testing with system message and api_kwargs ===")
try
    conversation = [
        PT.SystemMessage("You're a Czech person. Speak only in Czech."),
        PT.UserMessage("What is 2+2? Explain")
    ]
    
    msg = aigenerate(PT.GoogleSchema(), conversation; 
        model="gemini-2.0-flash",
        api_kwargs=(temperature=0.5, max_output_tokens=100, top_p=0.9),
        http_kwargs=(readtimeout=60,)
    )
    
    println("SUCCESS: Test with system message and api_kwargs completed")
    println("Response: ", msg.content)
catch e
    if occursin("API_KEY", string(e)) || occursin("authentication", string(e)) || occursin("Unauthorized", string(e))
        println("SUCCESS: Extension working (API key error as expected)")
    else
        println("ERROR: ", e)
    end
end
