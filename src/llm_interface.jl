# This file defines all key types that the various function dispatch on.
# New LLM interfaces should define:
# - corresponding schema to dispatch on (`schema <: AbstractPromptSchema`)
# - how to render conversation history/prompts (`render(schema)`)
# - user-facing functionality (eg, `aigenerate`, `aiembed`)
#
# Ideally, each new interface would be defined in a separate `llm_<interface>.jl` file (eg, `llm_chatml.jl`).

## Main Functions
function render end
function aigenerate end
function aiembed end
function aiclassify end
function aiextract end
function aiscan end
function aiimage end
# Re-usable blocks are defined in src/llm_shared.jl

## Prompt Schema
"Defines different prompting styles based on the model training and fine-tuning."
abstract type AbstractPromptSchema end

"Schema that keeps messages (<:AbstractMessage) and does not transform for any specific model. It used by the first pass of the prompt rendering system (see `?render`)."
struct NoSchema <: AbstractPromptSchema end

abstract type AbstractOpenAISchema <: AbstractPromptSchema end

"""
OpenAISchema is the default schema for OpenAI models.

It uses the following conversation template:
```
[Dict(role="system",content="..."),Dict(role="user",content="..."),Dict(role="assistant",content="...")]
```

It's recommended to separate sections in your prompt with markdown headers (e.g. `##Answer\n\n`).
"""
struct OpenAISchema <: AbstractOpenAISchema end

"Echoes the user's input back to them. Used for testing the implementation"
@kwdef mutable struct TestEchoOpenAISchema <: AbstractOpenAISchema
    response::AbstractDict
    status::Integer
    model_id::String = ""
    inputs::Any = nothing
end

"""
    CustomOpenAISchema 
    
CustomOpenAISchema() allows user to call any OpenAI-compatible API.

All user needs to do is to pass this schema as the first argument and provide the BASE URL of the API to call (`api_kwargs.url`).

# Example

Assumes that we have a local server running at `http://127.0.0.1:8081`:

```julia
api_key = "..."
prompt = "Say hi!"
msg = aigenerate(CustomOpenAISchema(), prompt; model="my_model", api_key, api_kwargs=(; url="http://127.0.0.1:8081"))
```

"""
struct CustomOpenAISchema <: AbstractOpenAISchema end

"""
    LocalServerOpenAISchema

Designed to be used with local servers. It's automatically called with model alias "local" (see `MODEL_REGISTRY`).

This schema is a flavor of CustomOpenAISchema with a `url` key` preset by global Preference key `LOCAL_SERVER`. See `?PREFERENCES` for more details on how to change it.
It assumes that the server follows OpenAI API conventions (eg, `POST /v1/chat/completions`).

Note: Llama.cpp (and hence Llama.jl built on top of it) do NOT support embeddings endpoint! You'll get an address error.

# Example

Assumes that we have a local server running at `http://127.0.0.1:10897/v1` (port and address used by Llama.jl, "v1" at the end is needed for OpenAI endpoint compatibility):

Three ways to call it:
```julia

# Use @ai_str with "local" alias
ai"Say hi!"local

# model="local"
aigenerate("Say hi!"; model="local")

# Or set schema explicitly
const PT = PromptingTools
msg = aigenerate(PT.LocalServerOpenAISchema(), "Say hi!")
```

How to start a LLM local server? You can use `run_server` function from [Llama.jl](https://github.com/marcom/Llama.jl). Use a separate Julia session.
```julia
using Llama
model = "...path..." # see Llama.jl README how to download one
run_server(; model)
```

To change the default port and address:
```julia
# For a permanent change, set the preference:
using Preferences
set_preferences!("LOCAL_SERVER"=>"http://127.0.0.1:10897/v1")

# Or if it's a temporary fix, just change the variable `LOCAL_SERVER`:
const PT = PromptingTools
PT.LOCAL_SERVER = "http://127.0.0.1:10897/v1"
```

"""
struct LocalServerOpenAISchema <: AbstractOpenAISchema end

"""
    MistralOpenAISchema

MistralOpenAISchema() allows user to call MistralAI API known for mistral and mixtral models.

It's a flavor of CustomOpenAISchema() with a url preset to `https://api.mistral.ai`.

Most models have been registered, so you don't even have to specify the schema

# Example

Let's call `mistral-tiny` model:
```julia
api_key = "..." # can be set via ENV["MISTRAL_API_KEY"] or via our preference system
msg = aigenerate("Say hi!"; model="mistral_tiny", api_key)
```

See `?PREFERENCES` for more details on how to set your API key permanently.

"""
struct MistralOpenAISchema <: AbstractOpenAISchema end

"""
    DatabricksOpenAISchema

DatabricksOpenAISchema() allows user to call Databricks Foundation Model API. [API Reference](https://docs.databricks.com/en/machine-learning/foundation-models/api-reference.html)

Requires two environment variables to be set:
- `DATABRICKS_API_KEY`: Databricks token
- `DATABRICKS_HOST`: Address of the Databricks workspace (`https://<workspace_host>.databricks.com`)
"""
struct DatabricksOpenAISchema <: AbstractOpenAISchema end

"""
    FireworksOpenAISchema

Schema to call the [Fireworks.ai](https://fireworks.ai/) API.

Links:
- [Get your API key](https://fireworks.ai/api-keys)
- [API Reference](https://readme.fireworks.ai/reference/createchatcompletion)
- [Available models](https://fireworks.ai/models)

Requires one environment variables to be set:
- `FIREWORKS_API_KEY`: Your API key
"""
struct FireworksOpenAISchema <: AbstractOpenAISchema end

"""
    TogetherOpenAISchema

Schema to call the [Together.ai](https://www.together.ai/) API.

Links:
- [Get your API key](https://api.together.xyz/settings/api-keys)
- [API Reference](https://docs.together.ai/docs/openai-api-compatibility)
- [Available models](https://docs.together.ai/docs/inference-models)

Requires one environment variables to be set:
- `TOGETHER_API_KEY`: Your API key
"""
struct TogetherOpenAISchema <: AbstractOpenAISchema end

"""
    GroqOpenAISchema

Schema to call the [groq.com](https://console.groq.com/keys) API.

Links:
- [Get your API key](https://console.groq.com/keys)
- [API Reference](https://console.groq.com/docs/quickstart)
- [Available models](https://console.groq.com/docs/models)

Requires one environment variables to be set:
- `GROQ_API_KEY`: Your API key (often starts with "gsk_...")
"""
struct GroqOpenAISchema <: AbstractOpenAISchema end

"""
    DeepSeekOpenAISchema

Schema to call the [DeepSeek](https://platform.deepseek.com/docs) API.

Links:
- [Get your API key](https://platform.deepseek.com/api_keys)
- [API Reference](https://platform.deepseek.com/docs)

Requires one environment variables to be set:
- `DEEPSEEK_API_KEY`: Your API key (often starts with "sk-...")
"""
struct DeepSeekOpenAISchema <: AbstractOpenAISchema end

abstract type AbstractOllamaSchema <: AbstractPromptSchema end

"""
OllamaSchema is the default schema for Olama models.

It uses the following conversation template:
```
[Dict(role="system",content="..."),Dict(role="user",content="..."),Dict(role="assistant",content="...")]
```

It's very similar to OpenAISchema, but it appends images differently.
"""
struct OllamaSchema <: AbstractOllamaSchema end

"Echoes the user's input back to them. Used for testing the implementation"
@kwdef mutable struct TestEchoOllamaSchema <: AbstractOllamaSchema
    response::AbstractDict
    status::Integer
    model_id::String = ""
    inputs::Any = nothing
end

abstract type AbstractChatMLSchema <: AbstractPromptSchema end
"""
ChatMLSchema is used by many open-source chatbots, by OpenAI models (under the hood) and by several models and inferfaces (eg, Ollama, vLLM)

You can explore it on [tiktokenizer](https://tiktokenizer.vercel.app/)

It uses the following conversation structure:
```
<im_start>system
...<im_end>
<|im_start|>user
...<|im_end|>
<|im_start|>assistant
...<|im_end|>
```
"""
struct ChatMLSchema <: AbstractChatMLSchema end

abstract type AbstractManagedSchema <: AbstractPromptSchema end
abstract type AbstractOllamaManagedSchema <: AbstractManagedSchema end

"""
Ollama by default manages different models and their associated prompt schemas when you pass `system_prompt` and `prompt` fields to the API.

Warning: It works only for 1 system message and 1 user message, so anything more than that has to be rejected.

If you need to pass more messagese / longer conversational history, you can use define the model-specific schema directly and pass your Ollama requests with `raw=true`, 
 which disables and templating and schema management by Ollama.
"""
struct OllamaManagedSchema <: AbstractOllamaManagedSchema end

"Echoes the user's input back to them. Used for testing the implementation"
@kwdef mutable struct TestEchoOllamaManagedSchema <: AbstractOllamaManagedSchema
    response::AbstractDict
    status::Integer
    model_id::String = ""
    inputs::Any = nothing
end

abstract type AbstractGoogleSchema <: AbstractPromptSchema end

"Calls Google's Gemini API. See more information [here](https://aistudio.google.com/). It's available only for _some_ regions."
struct GoogleSchema <: AbstractGoogleSchema end

"Echoes the user's input back to them. Used for testing the implementation"
@kwdef mutable struct TestEchoGoogleSchema <: AbstractGoogleSchema
    text::Any
    response_status::Integer
    model_id::String = ""
    inputs::Any = nothing
end

abstract type AbstractAnthropicSchema <: AbstractPromptSchema end

"""
    AnthropicSchema <: AbstractAnthropicSchema

AnthropicSchema is the default schema for Anthropic API models (eg, Claude). See more information [here](https://docs.anthropic.com/claude/reference/getting-started-with-the-api).

It uses the following conversation template:
```
Dict(role="user",content="..."),Dict(role="assistant",content="...")]
```
`system` messages are provided as a keyword argument to the API call.

It's recommended to separate sections in your prompt with XML markup (e.g. `<document>\n{{document}}\n</document>`). See [here](https://docs.anthropic.com/claude/docs/use-xml-tags).
"""
struct AnthropicSchema <: AbstractAnthropicSchema end

"Echoes the user's input back to them. Used for testing the implementation"
@kwdef mutable struct TestEchoAnthropicSchema <: AbstractAnthropicSchema
    response::AbstractDict
    status::Integer
    model_id::String = ""
    inputs::Any = nothing
end

abstract type AbstractShareGPTSchema <: AbstractPromptSchema end

"""
    ShareGPTSchema <: AbstractShareGPTSchema

Frequently used schema for finetuning LLMs. Conversations are recorded as a vector of dicts with keys `from` and `value` (similar to OpenAI).
"""
struct ShareGPTSchema <: AbstractShareGPTSchema end

abstract type AbstractTracerSchema <: AbstractPromptSchema end

"""
    TracerSchema <: AbstractTracerSchema

A schema designed to wrap another schema, enabling pre- and post-execution callbacks for tracing and additional functionalities. This type is specifically utilized within the `TracerMessage` type to trace the execution flow, facilitating observability and debugging in complex conversational AI systems.

The `TracerSchema` acts as a middleware, allowing developers to insert custom logic before and after the execution of the primary schema's functionality. This can include logging, performance measurement, or any other form of tracing required to understand or improve the execution flow.

# Usage
```julia
wrap_schema = TracerSchema(OpenAISchema())
msg = aigenerate(wrap_schema, "Say hi!"; model="gpt-4")
# output type should be TracerMessage
msg isa TracerMessage
```
You can define your own tracer schema and the corresponding methods: `initialize_tracer`, `finalize_tracer`. See `src/llm_tracer.jl`
"""
struct TracerSchema <: AbstractTracerSchema
    schema::AbstractPromptSchema
end

## Dispatch into a default schema (can be set by Preferences.jl)
# Since we load it as strings, we need to convert it to a symbol and instantiate it
global PROMPT_SCHEMA::AbstractPromptSchema = @load_preference("PROMPT_SCHEMA",
    default="OpenAISchema") |> x -> getproperty(@__MODULE__, Symbol(x))()

function aigenerate(prompt; model = MODEL_CHAT, kwargs...)
    global MODEL_REGISTRY
    # first look up the model schema in the model registry; otherwise, use the default schema PROMPT_SCHEMA
    schema = get(MODEL_REGISTRY, model, (; schema = PROMPT_SCHEMA)).schema
    aigenerate(schema, prompt; model, kwargs...)
end
function aiembed(doc_or_docs, args...; model = MODEL_EMBEDDING, kwargs...)
    global MODEL_REGISTRY
    schema = get(MODEL_REGISTRY, model, (; schema = PROMPT_SCHEMA)).schema
    aiembed(schema, doc_or_docs, args...; model, kwargs...)
end
function aiclassify(prompt; model = MODEL_CHAT, kwargs...)
    global MODEL_REGISTRY
    schema = get(MODEL_REGISTRY, model, (; schema = PROMPT_SCHEMA)).schema
    aiclassify(schema, prompt; model, kwargs...)
end
function aiextract(prompt; model = MODEL_CHAT, kwargs...)
    global MODEL_REGISTRY
    schema = get(MODEL_REGISTRY, model, (; schema = PROMPT_SCHEMA)).schema
    aiextract(schema, prompt; model, kwargs...)
end
function aiscan(prompt; model = MODEL_CHAT, kwargs...)
    schema = get(MODEL_REGISTRY, model, (; schema = PROMPT_SCHEMA)).schema
    aiscan(schema, prompt; model, kwargs...)
end
function aiimage(prompt; model = MODEL_IMAGE_GENERATION, kwargs...)
    schema = get(MODEL_REGISTRY, model, (; schema = PROMPT_SCHEMA)).schema
    aiimage(schema, prompt; model, kwargs...)
end
"Utility to facilitate unwrapping of HTTP response to a message type `MSG` provided. Designed to handle multi-sample completions."
function response_to_message(schema::AbstractPromptSchema,
        MSG::Type{T},
        choice,
        resp;
        return_type = nothing,
        model_id::AbstractString = "",
        time::Float64 = 0.0,
        run_id::Integer = rand(Int16),
        sample_id::Union{Nothing, Integer} = nothing) where {T}
    throw(ArgumentError("Response unwrapping not implemented for $(typeof(schema)) and $MSG"))
end
