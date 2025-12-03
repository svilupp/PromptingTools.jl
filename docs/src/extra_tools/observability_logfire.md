# Observability with Logfire.jl

[Logfire.jl](https://github.com/svilupp/Logfire.jl) provides OpenTelemetry-based observability for your LLM applications built with PromptingTools.jl. It automatically traces all your AI calls with detailed information about tokens, costs, messages, and latency.

## Why Logfire.jl?

| Benefit | Description |
|---------|-------------|
| **Automatic Tracing** | All `ai*` function calls are traced with zero code changes |
| **Full Visibility** | Token usage, costs, latency, messages, and errors captured |
| **Flexible Backends** | Use Logfire cloud, Jaeger, Langfuse, or any OTLP-compatible backend |
| **Cross-Language** | Same observability infrastructure works with Python and TypeScript |
| **Generous Free Tier** | Hundreds of thousands of traced conversations/month on Logfire cloud |

## Cross-Language Ecosystem

Logfire is available across multiple languages, enabling teams to share observability infrastructure:

| Language | Package | Installation |
|----------|---------|--------------|
| **Julia** | [Logfire.jl](https://github.com/svilupp/Logfire.jl) | `Pkg.add("Logfire")` |
| **Python** | [logfire](https://docs.pydantic.dev/logfire/) | `pip install logfire` |

All traces flow to the same [Pydantic Logfire](https://pydantic.dev/logfire) dashboard, giving you unified visibility across your entire stack!

## Installation

Logfire.jl is a separate package that provides a PromptingTools extension. Install it along with DotEnv for loading secrets:

```julia
using Pkg
Pkg.add(["Logfire", "DotEnv"])
```

The extension is loaded automatically when both packages are present - no additional configuration needed.

## Quick Start

```julia
using DotEnv
DotEnv.load!()  # Load LOGFIRE_TOKEN and API keys from .env file

using Logfire, PromptingTools

# 1. Configure Logfire (uses LOGFIRE_TOKEN env var, or pass token directly)
Logfire.configure(service_name = "my-app")

# 2. Instrument all registered models - wraps them with tracing schema
Logfire.instrument_promptingtools!()

# 3. Use PromptingTools as normal - traces are automatic!
aigenerate("What is 2 + 2?"; model = "gpt4om")
```

## How It Works

The integration works by wrapping registered models in a Logfire tracing schema. When you call `instrument_promptingtools!()`, Logfire modifies the model registry to route all calls through its tracing layer. This means:

- All `ai*` functions work exactly as before
- No code changes needed in your existing workflows
- Traces are captured automatically with rich metadata

## What Gets Captured

Each AI call creates a span with:

- **Request parameters**: model, temperature, top_p, max_tokens, stop, penalties
- **Usage metrics**: input/output/total tokens, latency, cost estimates
- **Provider metadata**: model returned, status, finish_reason, response_id
- **Conversation**: full message history (roles + content)
- **Cache & streaming**: flags and chunk counts
- **Tool/function calls**: count and payload
- **Errors**: exceptions with span status set to error

## Extras Field Reference

PromptingTools populates `AIMessage.extras` with detailed metadata that Logfire.jl maps to OpenTelemetry GenAI semantic convention attributes. The fields use unified naming across providers for consistency.

### Provider Metadata

| Extras Key | Type | Description | OpenAI | Anthropic |
|------------|------|-------------|--------|-----------|
| `:model` | String | Actual model used (may differ from requested) | ✓ | ✓ |
| `:response_id` | String | Provider's unique response identifier | ✓ | ✓ |
| `:system_fingerprint` | String | OpenAI system fingerprint for determinism | ✓ | - |
| `:service_tier` | String | Service tier used (e.g., "default", "standard") | ✓ | ✓ |

### Unified Usage Keys

These keys provide cross-provider compatibility. Use these for provider-agnostic code:

| Extras Key | Type | Description | OpenAI Source | Anthropic Source |
|------------|------|-------------|---------------|------------------|
| `:cache_read_tokens` | Int | Tokens read from cache (cache hits) | `prompt_tokens_details.cached_tokens` | `cache_read_input_tokens` |
| `:cache_write_tokens` | Int | Tokens written to cache | - | `cache_creation_input_tokens` |
| `:reasoning_tokens` | Int | Chain-of-thought/reasoning tokens | `completion_tokens_details.reasoning_tokens` | - |
| `:audio_input_tokens` | Int | Audio tokens in input | `prompt_tokens_details.audio_tokens` | - |
| `:audio_output_tokens` | Int | Audio tokens in output | `completion_tokens_details.audio_tokens` | - |
| `:accepted_prediction_tokens` | Int | Predicted tokens that were accepted | `completion_tokens_details.accepted_prediction_tokens` | - |
| `:rejected_prediction_tokens` | Int | Predicted tokens that were rejected | `completion_tokens_details.rejected_prediction_tokens` | - |

### Anthropic-Specific Keys

| Extras Key | Type | Description |
|------------|------|-------------|
| `:cache_write_1h_tokens` | Int | Ephemeral 1-hour cache tokens |
| `:cache_write_5m_tokens` | Int | Ephemeral 5-minute cache tokens |
| `:web_search_requests` | Int | Server-side web search requests |
| `:cache_creation_input_tokens` | Int | Original Anthropic key (backwards compat) |
| `:cache_read_input_tokens` | Int | Original Anthropic key (backwards compat) |

### Raw Provider Dicts

For debugging or advanced use cases, the original nested structures are preserved:

| Extras Key | Provider | Contents |
|------------|----------|----------|
| `:prompt_tokens_details` | OpenAI | `{:cached_tokens, :audio_tokens}` |
| `:completion_tokens_details` | OpenAI | `{:reasoning_tokens, :audio_tokens, :accepted_prediction_tokens, :rejected_prediction_tokens}` |
| `:cache_creation` | Anthropic | `{:ephemeral_1h_input_tokens, :ephemeral_5m_input_tokens}` |
| `:server_tool_use` | Anthropic | `{:web_search_requests}` |

### Example: Accessing Extras

```julia
using PromptingTools

msg = aigenerate("What is 2+2?"; model="gpt4om")

# Provider metadata
println("Model used: ", msg.extras[:model])
println("Response ID: ", msg.extras[:response_id])

# Unified usage (works across providers)
cache_hits = get(msg.extras, :cache_read_tokens, 0)
reasoning = get(msg.extras, :reasoning_tokens, 0)

# Raw OpenAI details (if needed)
if haskey(msg.extras, :prompt_tokens_details)
    details = msg.extras[:prompt_tokens_details]
    println("Cached: ", get(details, :cached_tokens, 0))
end
```

## Instrument Individual Models

You don't have to instrument all models. For selective tracing, wrap only specific models:

```julia
Logfire.instrument_promptingtools_model!("my-local-llm")
```

This reuses the model's registered PromptingTools schema, so provider-specific behavior is preserved.

## Alternative Backends

You don't have to use Logfire cloud. Send traces to any OpenTelemetry-compatible backend using standard environment variables:

| Variable | Purpose |
|----------|---------|
| `OTEL_EXPORTER_OTLP_ENDPOINT` | Backend URL (e.g., `http://localhost:4318`) |
| `OTEL_EXPORTER_OTLP_HEADERS` | Custom headers (e.g., `Authorization=Bearer token`) |

### Local Development with Jaeger

```bash
# Start Jaeger
docker run --rm -p 16686:16686 -p 4318:4318 jaegertracing/all-in-one:latest
```

```julia
using Logfire

ENV["OTEL_EXPORTER_OTLP_ENDPOINT"] = "http://localhost:4318"

Logfire.configure(
    service_name = "my-app",
    send_to_logfire = :always  # Export even without Logfire token
)

Logfire.instrument_promptingtools!()
# Now use PromptingTools normally - traces go to Jaeger
```

View traces at: http://localhost:16686

### Using with Langfuse

```julia
ENV["OTEL_EXPORTER_OTLP_ENDPOINT"] = "https://cloud.langfuse.com/api/public/otel"
ENV["OTEL_EXPORTER_OTLP_HEADERS"] = "Authorization=Basic <base64-credentials>"

Logfire.configure(service_name = "my-llm-app", send_to_logfire = :always)
```

## Recommended: Pydantic Logfire

While you can use any OTLP-compatible backend, we strongly recommend [Pydantic Logfire](https://pydantic.dev/logfire). Their free tier provides hundreds of thousands of traced conversations per month, which is more than enough for most use cases. The UI is purpose-built for LLM observability with excellent visualization of conversations, token usage, and costs.

## Authentication

- Provide your Logfire token via `Logfire.configure(token = "...")` or set `ENV["LOGFIRE_TOKEN"]`
- Use `DotEnv.load!()` to load tokens from a project-local `.env` file (recommended for per-project configuration)

## Example

See the full example at [`examples/observability_with_logfire.jl`](https://github.com/svilupp/PromptingTools.jl/blob/main/examples/observability_with_logfire.jl).

## Combining with TextPrompts.jl

For a complete LLM workflow, combine Logfire.jl with [TextPrompts.jl](prompt_management_textprompts.md) for prompt management:

```julia
using TextPrompts, PromptingTools, Logfire

Logfire.configure(service_name = "my-app")
Logfire.instrument_promptingtools!()

# Load prompts from version-controlled files
system = load_prompt("prompts/system.txt")(; role = "Expert") |> SystemMessage
user = load_prompt("prompts/task.txt")(; task = "analyze data") |> UserMessage

# Traces include full conversation with formatted prompts
response = aigenerate([system, user]; model = "gpt4om")
```

This enables a powerful workflow: version prompts in git, trace calls in Logfire, and continuously improve based on real-world performance.

## Further Reading

- [Logfire.jl Documentation](https://svilupp.github.io/Logfire.jl/dev)
- [Logfire.jl GitHub](https://github.com/svilupp/Logfire.jl)
- [Pydantic Logfire](https://pydantic.dev/logfire)
- [TextPrompts.jl - Prompt Management](prompt_management_textprompts.md)
- [Discourse Announcement](https://discourse.julialang.org/t/announcing-logfire-jl-textprompts-jl-observability-and-prompt-management-for-julia-genai/134268)
