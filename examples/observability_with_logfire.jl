# Observability with Logfire.jl - PromptingTools Integration
#
# This example shows how to trace LLM calls made with PromptingTools using Logfire.jl.
# All AI operations are automatically traced with full observability including
# tokens, costs, messages, and latency.
#
# IMPORTANT: You must install Logfire.jl first to enable this integration!
# The PromptingTools extension is loaded automatically when Logfire.jl is present.
#
# ENVIRONMENT VARIABLES
# =====================
# Create a `.env` file in your project root with:
#
#   LOGFIRE_TOKEN=your-write-token     # From https://logfire.pydantic.dev
#   OPENAI_API_KEY=your-openai-key     # Required for OpenAI models
#
# INSTALLATION
# ============
# using Pkg
# Pkg.add(["Logfire", "DotEnv"])  # This enables the PromptingTools extension
#
# Run: julia --project=. examples/observability_with_logfire.jl

using DotEnv
DotEnv.load!()

using Logfire
using PromptingTools

# =============================================================================
# Setup (3 steps)
# =============================================================================

# 1. Configure Logfire
#    - Uses LOGFIRE_TOKEN from environment (loaded via DotEnv above)
#    - Or pass token directly: Logfire.configure(token = "your-token", ...)
Logfire.configure(service_name = "promptingtools-example")

# 2. Instrument PromptingTools - this wraps ALL registered models with tracing
#    The integration works by wrapping models in a Logfire tracing schema.
Logfire.instrument_promptingtools!()

# 3. Use PromptingTools as normal - traces are automatic!

# =============================================================================
# Example 1: Simple text generation
# =============================================================================
println("Example 1: Simple text generation")
println("-"^50)

response = aigenerate("What is 2 + 2? Reply in one word."; model = "gpt4om")
println("Response: ", response.content)
println()

# What gets traced:
#   - Span: "chat gpt-4o-mini" with timing
#   - Input messages (your prompt)
#   - Output messages (model response)
#   - Token usage (input/output tokens)
#   - Model parameters (temperature, etc.)
#   - Cost estimate

# =============================================================================
# Example 2: With system prompt and parameters
# =============================================================================
println("Example 2: With system prompt and parameters")
println("-"^50)

response = aigenerate(
    "Translate 'Hello, world!' to French.";
    system = "You are a helpful translator. Be concise.",
    model = "gpt4om",
    api_kwargs = (; temperature = 0.3)
)
println("Response: ", response.content)
println()

# Additional attributes traced:
#   - System instructions (shown separately in Logfire UI)
#   - gen_ai.request.temperature = 0.3

# =============================================================================
# Example 3: Structured extraction with aiextract
# =============================================================================
println("Example 3: Structured extraction")
println("-"^50)

# Define a struct for extraction
@kwdef struct City
    name::String
    country::String
    population::Int
end

result = aiextract(
    "Paris is the capital of France with about 2.1 million people.";
    return_type = City,
    model = "gpt4om"
)
println("Extracted: ", result.content)
println()

# Traces include:
#   - The extraction schema/return type
#   - Successful parsing confirmation

# =============================================================================
# Example 4: Multi-turn conversation
# =============================================================================
println("Example 4: Multi-turn conversation")
println("-"^50)

# First turn
conv = aigenerate("My name is Alice."; model = "gpt4om", return_all = true)
println("Turn 1: ", conv[end].content)

# Continue the conversation
conv = aigenerate(
    "What's my name?"; model = "gpt4om", conversation = conv, return_all = true)
println("Turn 2: ", conv[end].content)
println()

# Each turn creates a separate span with:
#   - Full conversation history in gen_ai.input.messages
#   - Parent-child relationship visible in trace view

# =============================================================================
# Optional: Instrument only specific models
# =============================================================================
# If you don't want to instrument ALL models, you can wrap individual models:
#
#   Logfire.instrument_promptingtools_model!("my-local-llm")
#
# This is useful when you want selective tracing for specific models.

# =============================================================================
# Optional: Alternative backends (Jaeger, Langfuse, etc.)
# =============================================================================
# You don't have to use Logfire cloud! Send traces to any OTLP-compatible backend:
#
# For Jaeger (local development):
#   docker run --rm -p 16686:16686 -p 4318:4318 jaegertracing/all-in-one:latest
#   ENV["OTEL_EXPORTER_OTLP_ENDPOINT"] = "http://localhost:4318"
#   Logfire.configure(service_name = "my-app", send_to_logfire = :always)
#
# For Langfuse:
#   ENV["OTEL_EXPORTER_OTLP_ENDPOINT"] = "https://cloud.langfuse.com/api/public/otel"
#   ENV["OTEL_EXPORTER_OTLP_HEADERS"] = "Authorization=Basic <base64-credentials>"
#   Logfire.configure(service_name = "my-app", send_to_logfire = :always)

# =============================================================================
# Cleanup
# =============================================================================
println("Shutting down...")
Logfire.shutdown!()

println("\nDone! Check your Logfire dashboard to see:")
println("  - 'chat gpt-4o-mini' spans for each AI call")
println("  - Input/output messages with full content")
println("  - Token usage and cost estimates")
println("  - Latency measurements for each call")
println("  - Conversation history for multi-turn chats")
