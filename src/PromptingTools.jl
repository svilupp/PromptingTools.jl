module PromptingTools

using Base64: base64encode
using Logging
using OpenAI
using JSON3
using JSON3: StructTypes
using HTTP
import Preferences
using Preferences: @load_preference, @set_preferences!
using PrecompileTools
using Test, Pkg

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
]

# export replace_words, split_by_length, call_cost, auth_header # for debugging only
include("utils.jl")

export aigenerate, aiembed, aiclassify, aiextract, aiscan
# export render # for debugging only
include("llm_interface.jl")

# sets up the global registry of models and default model choices
include("user_preferences.jl")

## Conversation history / Prompt elements
export AIMessage
# export UserMessage, UserMessageWithImages, SystemMessage, DataMessage # for debugging only
include("messages.jl")

export aitemplates, AITemplate
include("templates.jl")

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

## Individual interfaces
include("llm_shared.jl")
include("llm_openai.jl")
include("llm_ollama_managed.jl")
include("llm_ollama.jl")

## Convenience utils
export @ai_str, @aai_str, @ai!_str, @aai!_str
include("macros.jl")

## Experimental modules
include("Experimental/Experimental.jl")

function __init__()
    # Load templates
    load_templates!()
end

# Enable precompilation to reduce start time, disabled logging
with_logger(NullLogger()) do
    @compile_workload include("precompilation.jl")
end

end # module PromptingTools
