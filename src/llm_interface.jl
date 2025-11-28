# This file defines all key types that the various function dispatch on.
# New LLM interfaces should define:
# - corresponding schema to dispatch on (`schema <: AbstractPromptSchema`)
# - how to render conversation history/prompts (`render(schema)`)
# - user-facing functionality (eg, `aigenerate`, `aiembed`)
#
# Ideally, each new interface would be defined in a separate `llm_<interface>.jl` file (eg, `llm_chatml.jl`).
#
# OpenAI API Organization:
# - llm_openai_schema_defs.jl: Schema type definitions for OpenAI-compatible APIs
# - llm_openai_chat.jl: Chat Completions API (`/chat/completions` endpoint)
# - llm_openai_responses.jl: Responses API (`/responses` endpoint) for models like gpt-5.1-codex

## Main Functions
function role4render end
function render end
function aigenerate end
function aiembed end
function aiclassify end
function aiextract end
function aiscan end
function aiimage end
function aitools end
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
    response::AbstractDict = Dict(
        "choices" => [Dict(
            "message" => Dict("content" => "Test response", "role" => "assistant"),
            "index" => 0, "finish_reason" => "stop")],
        "usage" => Dict(
            "prompt_tokens" => 10, "completion_tokens" => 20, "total_tokens" => 30),
        "model" => "gpt-3.5-turbo",
        "id" => "test-id",
        "object" => "chat.completion",
        "created" => 1234567890
    )
    status::Integer = 200
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
   AzureOpenAISchema

AzureOpenAISchema() allows user to call Azure OpenAI API. [API Reference](https://learn.microsoft.com/en-us/azure/ai-services/openai/reference)

Requires two environment variables to be set:
- `AZURE_OPENAI_API_KEY`: Azure token
- `AZURE_OPENAI_HOST`: Address of the Azure resource (`"https://<resource>.openai.azure.com"`)
"""
struct AzureOpenAISchema <: AbstractOpenAISchema end

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

"""
    OpenRouterOpenAISchema

Schema to call the [OpenRouter](https://openrouter.ai/) API.

Links:
- [Get your API key](https://openrouter.ai/keys)
- [API Reference](https://openrouter.ai/docs)
- [Available models](https://openrouter.ai/models)

Requires one environment variable to be set:
- `OPENROUTER_API_KEY`: Your API key
"""
struct OpenRouterOpenAISchema <: AbstractOpenAISchema end

"""
    CerebrasOpenAISchema

Schema to call the [Cerebras](https://cerebras.ai/) API.

Links:
- [Get your API key](https://cloud.cerebras.ai)
- [API Reference](https://inference-docs.cerebras.ai/api-reference/chat-completions)

Requires one environment variable to be set:
- `CEREBRAS_API_KEY`: Your API key
"""
struct CerebrasOpenAISchema <: AbstractOpenAISchema end

"""
    SambaNovaOpenAISchema

Schema to call the [SambaNova](https://sambanova.ai/) API.

Links:
- [Get your API key](https://cloud.sambanova.ai/apis)
- [API Reference](https://community.sambanova.ai/c/docs)

Requires one environment variable to be set:
- `SAMBANOVA_API_KEY`: Your API key
"""
struct SambaNovaOpenAISchema <: AbstractOpenAISchema end

"""
    XAIOpenAISchema

Schema to call the XAI API. It follows OpenAI API conventions.

Get your API key from [here](https://console.x.ai/).

Requires one environment variable to be set:
- `XAI_API_KEY`: Your API key
"""
struct XAIOpenAISchema <: AbstractOpenAISchema end

"""
    GoogleOpenAISchema

Schema to call the Google's Gemini API using OpenAI compatibility mode. [API Reference](https://ai.google.dev/gemini-api/docs/openai#rest)

Links:
- [Get your API key](https://aistudio.google.com/apikey)
- [API Reference](https://ai.google.dev/gemini-api/docs/openai#rest)
- [Available models](https://ai.google.dev/models/gemini)

Requires one environment variable to be set:
- `GOOGLE_API_KEY`: Your API key

The base URL for the API is "https://generativelanguage.googleapis.com/v1beta"

Warning: Token counting and cost counting have not yet been implemented by Google, so you'll not have any such metrics. If you need it, use the native GoogleSchema with the GoogleGenAI.jl library.
"""
struct GoogleOpenAISchema <: AbstractOpenAISchema end

"""
    MiniMaxOpenAISchema

Schema to call the MiniMax API.

Links:
- [API Reference](https://api.minimaxi.chat/v1/text/chatcompletion_v2)

Requires one environment variable to be set:
- `MINIMAX_API_KEY`: Your API key
"""
struct MiniMaxOpenAISchema <: AbstractOpenAISchema end

"""
    MoonshotOpenAISchema

Schema to call the Moonshot API (Kimi models).

Links:
- [Get your API key](https://platform.moonshot.ai/)
- [API Reference](https://platform.moonshot.ai/docs/api/chat)

Requires one environment variable to be set:
- `MOONSHOT_API_KEY`: Your API key
"""
struct MoonshotOpenAISchema <: AbstractOpenAISchema end

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
    config_kwargs::Dict{Symbol, Any} = Dict{Symbol, Any}()
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

`TracerSchema` automatically wraps messages in `TracerMessage` type, which has several important fields, eg,
- `object`: the original message - unwrap with utility `unwrap`
- `meta`: a dictionary with metadata about the tracing process (eg, prompt templates, LLM API kwargs) - extract with utility `meta`
- `parent_id`: an identifier for the overall job / high-level conversation with the user where the current conversation `thread` originated. It should be the same for objects in the same thread.
- `thread_id`: an identifier for the current thread or execution context (sub-task, sub-process, CURRENT CONVERSATION or vector of messages) within the broader parent task. It should be the same for objects in the same thread.

See also: `meta`, `unwrap`, `SaverSchema`, `initialize_tracer`, `finalize_tracer`

# Example
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

"""
    SaverSchema <: AbstractTracerSchema

SaverSchema is a schema that automatically saves the conversation to the disk. 
It's useful for debugging and for persistent logging.

It can be composed with any other schema, eg, `TracerSchema` to save additional metadata.

Set environment variable `LOG_DIR` to the directory where you want to save the conversation (see `?PREFERENCES`).
Conversations are named by the hash of the first message in the conversation to naturally group subsequent conversations together.

If you need to provide logging directory of the file name dynamically, you can provide the following arguments to `tracer_kwargs`:
- `log_dir` - used as the directory to save the log into when provided. Defaults to `LOG_DIR` if not provided.
- `log_file_path` - used as the file name to save the log into when provided. This value overrules the `log_dir` and `LOG_DIR` if provided.

To use it automatically, re-register the models you use with the schema wrapped in `SaverSchema`

See also: `meta`, `unwrap`, `TracerSchema`, `initialize_tracer`, `finalize_tracer`

# Example
```julia
using PromptingTools: TracerSchema, OpenAISchema, SaverSchema
# This schema will first trace the metadata (change to TraceMessage) and then save the conversation to the disk

wrap_schema = OpenAISchema() |> TracerSchema |> SaverSchema
conv = aigenerate(wrap_schema,:BlankSystemUser; system="You're a French-speaking assistant!",
    user="Say hi!", model="gpt-4", api_kwargs=(;temperature=0.1), return_all=true)

# conv is a vector of messages that will be saved to a JSON together with metadata about the template and api_kwargs
```

If you wanted to enable this automatically for models you use, you can do it like this:
```julia
PT.register_model!(; name= "gpt-3.5-turbo", schema=OpenAISchema() |> TracerSchema |> SaverSchema)
```
Any subsequent calls `model="gpt-3.5-turbo"` will automatically capture metadata and save the conversation to the disk.

To provide logging file path explicitly, use the `tracer_kwargs`:
```julia
conv = aigenerate(wrap_schema,:BlankSystemUser; system="You're a French-speaking assistant!",
    user="Say hi!", model="gpt-4", api_kwargs=(;temperature=0.1), return_all=true,
    tracer_kwargs=(; log_file_path="my_logs/my_log.json"))
```
"""
struct SaverSchema <: AbstractTracerSchema
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
function aitools(prompt; model = MODEL_CHAT, kwargs...)
    schema = get(MODEL_REGISTRY, model, (; schema = PROMPT_SCHEMA)).schema
    aitools(schema, prompt; model, kwargs...)
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
        sample_id::Union{Nothing, Integer} = nothing, kwargs...) where {T}
    throw(ArgumentError("Response unwrapping not implemented for $(typeof(schema)) and $MSG"))
end

### For structured extraction
# We can generate fields, they will all share this parent type
abstract type AbstractExtractedData end
Base.show(io::IO, x::AbstractExtractedData) = dump(io, x; maxdepth = 1)
"Check if the object is an instance of `AbstractExtractedData`"
isextracted(x) = x isa AbstractExtractedData

# OpenAI Responses API implementation
#
# This file contains the implementation for OpenAI's Responses API endpoint (/responses)
# which is used by models like gpt-5.1-codex that don't support the standard chat completions API.

"""
    AbstractOpenAIResponseSchema

Abstract type for all OpenAI response-based schemas that use the `/responses` endpoint instead of `/chat/completions`.
"""
abstract type AbstractOpenAIResponseSchema <: AbstractPromptSchema end

"""
    OpenAIResponseSchema <: AbstractOpenAIResponseSchema

A schema for OpenAI's Responses API (`/responses` endpoint).

This schema is used for models that only support the Responses API, such as `gpt-5.1-codex`.
Unlike the standard chat completions API, the Responses API uses `input` and `instructions`
fields instead of a messages array.

# Example
```julia
schema = OpenAIResponseSchema()
response = aigenerate(schema, "What is Julia?"; model="gpt-5.1-codex")
```
"""
struct OpenAIResponseSchema <: AbstractOpenAIResponseSchema end

"Echoes the user's input back to them. Used for testing the Responses API implementation"
@kwdef mutable struct TestEchoOpenAIResponseSchema <: AbstractOpenAIResponseSchema
    response::AbstractDict = Dict(
        "id" => "resp_test123",
        "object" => "response",
        "status" => "completed",
        "output" => [
            Dict(
            "type" => "message",
            "content" => [
                Dict("type" => "output_text", "text" => "Test response")
            ]
        )
        ],
        "usage" => Dict(
            "input_tokens" => 10,
            "output_tokens" => 20
        ),
        "reasoning" => Dict()
    )
    status::Integer = 200
    model_id::String = ""
    inputs::Any = nothing
end
