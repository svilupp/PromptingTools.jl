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

## Prompt Schema
"Defines different prompting styles based on the model training and fine-tuning."
abstract type AbstractPromptSchema end
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

"""
Ollama by default manages different models and their associated prompt schemas when you pass `system_prompt` and `prompt` fields to the API.

Warning: It works only for 1 system message and 1 user message, so anything more than that has to be rejected.

If you need to pass more messagese / longer conversational history, you can use define the model-specific schema directly and pass your Ollama requests with `raw=true`, 
 which disables and templating and schema management by Ollama.
"""
struct OllamaManagedSchema <: AbstractManagedSchema end

## Dispatch into default schema
const PROMPT_SCHEMA = OpenAISchema()

aigenerate(prompt; kwargs...) = aigenerate(PROMPT_SCHEMA, prompt; kwargs...)
function aiembed(doc_or_docs, args...; kwargs...)
    aiembed(PROMPT_SCHEMA, doc_or_docs, args...; kwargs...)
end
aiclassify(prompt; kwargs...) = aiclassify(PROMPT_SCHEMA, prompt; kwargs...)
aiextract(prompt; kwargs...) = aiextract(PROMPT_SCHEMA, prompt; kwargs...)