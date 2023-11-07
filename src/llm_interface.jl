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
function aiextract end # not implemented yet

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
ChatMLSchema is used by many open-source chatbots, by OpenAI models under the hood and by several models and inferfaces (eg, Ollama, vLLM)

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

## Dispatch into defaults
const PROMPT_SCHEMA = OpenAISchema()

aigenerate(prompt; kwargs...) = aigenerate(PROMPT_SCHEMA, prompt; kwargs...)
function aiembed(doc_or_docs, args...; kwargs...)
    aiembed(PROMPT_SCHEMA, doc_or_docs, args...; kwargs...)
end
aiclassify(prompt; kwargs...) = aiclassify(PROMPT_SCHEMA, prompt; kwargs...)
