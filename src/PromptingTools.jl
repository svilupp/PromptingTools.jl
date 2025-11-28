module PromptingTools

import AbstractTrees
using Base64: base64encode
import Dates
using Dates: now, DateTime, @dateformat_str
using Logging
using OpenAI
using JSON3
using JSON3: StructTypes
using HTTP
import Preferences
using Preferences: @load_preference, @set_preferences!
using PrecompileTools
using StreamCallbacks
using StreamCallbacks: OpenAIStream, OpenAIResponsesStream, AnthropicStream, OllamaStream,
                       StreamCallback, StreamChunk, AbstractStreamCallback,
                       streamed_request!, build_response_body
using Test, Pkg
## Added REPL because it extends methods in Base.docs for extraction of docstrings
using REPL

## Fix for Julia v1.9 with missing methods
@static if VERSION >= v"1.9" && VERSION <= v"1.10"
    ## This definition is missing in Julia v1.9
    method_missing = try
        which(parentmodule, (Method,))
        false
    catch e
        true
    end
    if method_missing
        Base.parentmodule(m::Method) = m.module
    end
end
# GLOBALS and Preferences are managed by Preferences.jl - see src/preferences.jl for details
"The following keywords are reserved for internal use in the `ai*` functions and cannot be used as placeholders in the Messages"
const RESERVED_KWARGS = [
    :http_kwargs,
    :api_kwargs,
    :conversation,
    :return_all,
    :dry_run,
    :image_url,
    :image_path,
    :image_detail,
    :model,
    :strict,
    :json_mode,
    :no_system_message,
    :aiprefill,
    :name_user,
    :name_assistant,
    :betas
]

# export replace_words, recursive_splitter, split_by_length, call_cost, auth_header # for debugging only
# export length_longest_common_subsequence, distance_longest_common_subsequence
# export pprint
include("utils.jl")

export aigenerate, aiembed, aiclassify, aiextract, aitools, aiscan, aiimage
# export render # for debugging only
include("llm_interface.jl")

# sets up the global registry of models and default model choices
include("user_preferences.jl")

## Conversation history / Prompt elements
export AIMessage
include("messages.jl")

export ConversationMemory
include("memory.jl")
# export annotate!
include("annotation.jl")

export aitemplates, AITemplate
include("templates.jl")

const TEMPLATE_PATH = String[joinpath(@__DIR__, "..", "templates")]
const TEMPLATE_STORE = Dict{Symbol, Any}()
const TEMPLATE_METADATA = Vector{AITemplateMetadata}()

# export save_conversation, load_conversation, save_template, load_template
include("serialization.jl")

## Utilities to support structured extraction
include("extraction.jl")

## Utilities to support code generation
# Not export extract_code_blocks, extract_function_name
include("code_parsing.jl")
include("code_expressions.jl")
export AICode
include("code_eval.jl")

## Streaming support
include("streaming.jl")

## Individual interfaces
include("llm_shared.jl")
include("llm_openai_schema_defs.jl")
# OpenAI API has two endpoints: /chat/completions and /responses
# - llm_openai_chat.jl: Standard Chat Completions API (most models)
# - llm_openai_responses.jl: Responses API for models like gpt-5.1-codex
include("llm_openai_chat.jl")
include("llm_openai_responses.jl")

include("llm_ollama_managed.jl")
include("llm_ollama.jl")
include("llm_google.jl")
include("llm_anthropic.jl")
include("llm_sharegpt.jl")
include("llm_tracer.jl")

## Custom retry layer
include("retry_layer.jl")
using .CustomRetryLayer: enable_retry!

## Convenience utils
export @ai_str, @aai_str, @ai!_str, @aai!_str
include("macros.jl")

## Experimental modules
include("Experimental/Experimental.jl")

function __init__()
    # Load templates
    load_templates!()

    # Load ENV variables
    load_api_keys!()
end

# Enable precompilation to reduce start time, disabled logging
with_logger(NullLogger()) do
    @compile_workload include("precompilation.jl")
end

end # module PromptingTools
