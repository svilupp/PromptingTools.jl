# # Working with OpenAI Responses API
#
# This example demonstrates how to use the OpenAI Responses API (`/responses` endpoint)
# which provides features like reasoning traces, multi-turn conversations without
# re-sending history, and structured extraction.
#
# The Responses API is used by reasoning models like `gpt-5`, `o3`, and code models like `gpt-5.1-codex`.

using PromptingTools
const PT = PromptingTools

# Get the schema for Responses API
schema = PT.OpenAIResponseSchema()

# ## 1. Basic Usage
#
# Simple text generation - equivalent to:
# ```bash
# curl "https://api.openai.com/v1/responses" \
#     -H "Authorization: Bearer $OPENAI_API_KEY" \
#     -d '{"model": "gpt-5-mini", "input": "Write a one-sentence bedtime story about a unicorn."}'
# ```

response = aigenerate(schema, "Write a one-sentence bedtime story about a unicorn.";
    model = "gpt-5-mini",
    verbose = true)

println("Response: ", response.content)
println("Response ID: ", response.extras[:response_id])

# ## 2. With System Instructions
#
# Use SystemMessage for instructions - equivalent to:
# ```bash
# curl "https://api.openai.com/v1/responses" \
#     -d '{"model": "gpt-5-mini", "instructions": "Talk like a pirate.", "input": "Hello!"}'
# ```

response = aigenerate(schema,
    [
        PT.SystemMessage("Talk like a pirate."),
        PT.UserMessage("Are semicolons optional in JavaScript?")
    ];
    model = "gpt-5-mini",
    verbose = true)

println("Pirate response: ", response.content)

# ## 3. Controlling Reasoning Effort
#
# Use `api_kwargs` to control reasoning effort ("low", "medium", "high"):
# This is for reasoning models that support the `reasoning` parameter.
#
# NOTE: Reasoning is only available on certain models like o1, o3, o4-mini, gpt-5.
# Regular models like gpt-4o-mini don't support reasoning and will return empty reasoning_content.
#
# ```bash
# curl "https://api.openai.com/v1/responses" \
#     -d '{"model": "o3-mini", "reasoning": {"effort": "low"}, "input": "What is 2+2*3?"}'
# ```

# Low reasoning effort - faster, less detailed thinking
# Use a reasoning model like o3-mini, o4-mini, or o1
response_low = aigenerate(schema, "What is 2+2*3?";
    model = "o4-mini",  # Use a reasoning model for reasoning content
    api_kwargs = (reasoning = Dict("effort" => "low", "summary" => "auto"),),
    verbose = true)

println("Low effort result: ", response_low.content)
println("Reasoning content: ", response_low.extras[:reasoning_content])

# High reasoning effort - slower, more detailed thinking
response_high = aigenerate(schema,
    "What is the integral of x^2? Think about it step by step. Then return the answer";
    model = "gpt-5.1-codex",
    api_kwargs = (reasoning = Dict("effort" => "high", "summary" => "detailed"),),
    verbose = true)

println("High effort result: ", response_high.content)
println("Reasoning content: ", response_high.extras[:reasoning_content])

# ## 4. Controlling Reasoning Summary Verbosity
#
# Control how much reasoning is shown in the summary ("concise", "detailed", "auto"):
# - "auto": Let the model decide (default)
# - "concise": Brief summary of reasoning steps
# - "detailed": More verbose reasoning trace

response = aigenerate(schema, "Explain quantum entanglement simply.";
    model = "o4-mini",
    api_kwargs = (reasoning = Dict("effort" => "medium", "summary" => "detailed"),),
    verbose = true)

println("Reasoning summary: ", response.extras[:reasoning_content])

# ## 5. Multi-Turn Conversations with previous_response_id
#
# The Responses API supports continuing conversations WITHOUT re-sending the entire
# conversation history. Just pass the `previous_response_id` from the last response.
# This is more efficient and maintains context on the server side.

# First turn - introduce yourself
turn1 = aigenerate(schema, "My name is Alice and I love programming in Julia.";
    model = "gpt-5-mini",
    verbose = true)

println("\n=== Multi-turn Conversation ===")
println("Turn 1: ", turn1.content)
println("Response ID: ", turn1.extras[:response_id])

# Second turn - the model remembers context via previous_response_id
# No need to re-send the conversation history!
turn2 = aigenerate(schema, "What's my name and what language do I like?";
    model = "gpt-5-mini",
    previous_response_id = turn1.extras[:response_id],
    verbose = true)

println("Turn 2: ", turn2.content)
# The model remembers Alice and Julia from turn 1!

# Third turn - continue building on the conversation
turn3 = aigenerate(schema, "Can you suggest a project I might enjoy?";
    model = "gpt-5-mini",
    previous_response_id = turn2.extras[:response_id],
    verbose = true)

println("Turn 3: ", turn3.content)

# ## 6. Structured Extraction with aiextract
#
# Extract structured data into Julia types using JSON schema output.
# Equivalent to Python's `client.responses.parse()` with Pydantic models.
#
# Uses existing PromptingTools utilities: `tool_call_signature` for schema generation
# and `parse_tool` for parsing.

# Define the structure to extract
struct CalendarEvent
    name::String
    date::String
    participants::Vector{String}
end

# Extract structured data
result = aiextract(schema,
    [
        PT.SystemMessage("Extract the event information."),
        PT.UserMessage("Alice and Bob are going to a science fair on Friday.")
    ];
    return_type = CalendarEvent,
    model = "gpt-5-mini",
    verbose = true)

# Access the parsed data
event = result.content
println("\n=== Structured Extraction ===")
println("Event name: ", event.name)
println("Event date: ", event.date)
println("Participants: ", event.participants)

# ## 7. Structured Extraction with Reasoning
#
# Combine structured extraction with reasoning for explainable results:

struct MathSolution
    problem::String
    steps::Vector{String}
    answer::Float64
end

result = aiextract(schema,
    "Solve: If a train travels 120 miles in 2 hours, what is its average speed in mph?";
    return_type = MathSolution,
    model = "o1",  # Use reasoning model
    api_kwargs = (reasoning = Dict("effort" => "high", "summary" => "detailed"),),
    verbose = true)

solution = result.content
println("\n=== Math with Reasoning ===")
println("Problem: ", solution.problem)
println("Steps: ")
for (i, step) in enumerate(solution.steps)
    println("  $i. $step")
end
println("Answer: ", solution.answer, " mph")
println("\nReasoning trace: ", result.extras[:reasoning_content])

# ## 8. Web Search Integration
#
# Enable web search for up-to-date information:

response = aigenerate(schema, "What are the latest developments in Julia 1.11?";
    model = "gpt-5-mini",
    enable_websearch = true,
    verbose = true)

println("\n=== Web Search ===")
println("Web search result: ", response.content)

# ## 9. Accessing Full Response Details
#
# All API response details are available in `extras`:

response = aigenerate(schema, "Hello!";
    model = "gpt-5-mini",
    verbose = true)

println("\n=== Response Details ===")
println("Response ID: ", response.extras[:response_id])
println("Reasoning object: ", response.extras[:reasoning])
println("Reasoning content: ", response.extras[:reasoning_content])
println("Usage: ", response.extras[:usage])
# println("Full response: ", response.extras[:full_response])  # Complete API response

# ## 10. Using with Templates
#
# Works with PromptingTools templates:
tpl = PT.render(AITemplate(:BlankSystemUser))
response = aigenerate(schema, tpl;
    system = "You are a helpful coding assistant specialized in Julia.",
    user = "How do I read a CSV file?",
    model = "gpt-5-mini",
    verbose = true)

println("\n=== Template Usage ===")
println("Template response: ", response.content)

# ## 11. Streaming Responses
#
# Stream responses in real-time for better interactivity.
# Uses `OpenAIResponsesStream` flavor from StreamCallbacks.jl.

using PromptingTools: StreamCallback

# Basic streaming to stdout - see tokens appear as they're generated
println("\n=== Streaming to stdout ===")
response = aigenerate(schema, "Count from 1 to 10, one number per line.";
    model = "gpt-5-mini",
    streamcallback = stdout,
    verbose = false)

# Streaming with custom StreamCallback to capture chunks
println("\n\n=== Streaming with StreamCallback ===")
cb = StreamCallback()  # captures all chunks for inspection
response = aigenerate(schema, "What is Julia in one sentence?";
    model = "gpt-5-mini",
    streamcallback = cb,
    verbose = false)

println("Final content: ", response.content)
println("Number of chunks received: ", length(cb.chunks))

# Streaming to an IOBuffer for programmatic capture
output = IOBuffer()
cb = StreamCallback(; out = output)
response = aigenerate(schema, "Say hello in 3 languages.";
    model = "gpt-5-mini",
    streamcallback = cb,
    verbose = false)

streamed_text = String(take!(output))
println("Captured streamed text: ", streamed_text)

# Streaming with reasoning models - see reasoning and output streamed
println("\n=== Streaming with Reasoning ===")
cb = StreamCallback(; out = stdout)
response = aigenerate(schema, "What is 15 * 7? Think step by step.";
    model = "o4-mini",
    api_kwargs = (reasoning = Dict("effort" => "medium", "summary" => "auto"),),
    streamcallback = cb,
    verbose = false)

println("\nReasoning content: ", response.extras[:reasoning_content])

# ## Summary of Key Features
#
# | Feature | How to Use |
# |---------|------------|
# | Basic generation | `aigenerate(schema, "prompt"; model="gpt-5-mini")` |
# | System instructions | `aigenerate(schema, [SystemMessage(...), UserMessage(...)])` |
# | Reasoning effort | `api_kwargs = (reasoning = Dict("effort" => "low"),)` |
# | Reasoning verbosity | `api_kwargs = (reasoning = Dict("summary" => "concise"),)` |
# | Multi-turn (efficient) | `previous_response_id = response.extras[:response_id]` |
# | Structured extraction | `aiextract(schema, prompt; return_type=MyStruct)` |
# | Web search | `enable_websearch = true` |
# | Streaming | `streamcallback = stdout` or `StreamCallback()` |
# | Access reasoning | `response.extras[:reasoning_content]` |
