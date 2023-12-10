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
    aiembed(schema, doc_or_docs, args...; kwargs...)
end
function aiclassify(prompt; model = MODEL_CHAT, kwargs...)
    global MODEL_REGISTRY
    schema = get(MODEL_REGISTRY, model, (; schema = PROMPT_SCHEMA)).schema
    aiclassify(schema, prompt; kwargs...)
end
function aiextract(prompt; model = MODEL_CHAT, kwargs...)
    global MODEL_REGISTRY
    schema = get(MODEL_REGISTRY, model, (; schema = PROMPT_SCHEMA)).schema
    aiextract(schema, prompt; kwargs...)
end
function aiscan(prompt; model = MODEL_CHAT, kwargs...)
    schema = get(MODEL_REGISTRY, model, (; schema = PROMPT_SCHEMA)).schema
    aiscan(schema, prompt; kwargs...)
end