module PromptingTools

using Base64: base64encode
using Logging
using OpenAI
using JSON3
using JSON3: StructTypes
using HTTP
using PrecompileTools

# GLOBALS
const MODEL_CHAT = "gpt-3.5-turbo"
const MODEL_EMBEDDING = "text-embedding-ada-002"
const API_KEY = get(ENV, "OPENAI_API_KEY", "")
# Note: Disable this warning by setting OPENAI_API_KEY to anything
isempty(API_KEY) &&
    @warn "OPENAI_API_KEY environment variable not set! OpenAI models will not be available - set API key directly via `PromptingTools.API_KEY=<api-key>`!"

# Cost per 1K tokens as of 7th November 2023
const MODEL_COSTS = Dict("gpt-3.5-turbo" => (0.0015, 0.002),
    "gpt-3.5-turbo-1106" => (0.001, 0.002),
    "gpt-4" => (0.03, 0.06),
    "gpt-4-1106-preview" => (0.01, 0.03),
    "gpt-4-vision-preview" => (0.01, 0.03),
    "text-embedding-ada-002" => (0.001, 0.0))
const MODEL_ALIASES = Dict("gpt3" => "gpt-3.5-turbo",
    "gpt4" => "gpt-4",
    "gpt4v" => "gpt-4-vision-preview", # 4v is for "4 vision"
    "gpt4t" => "gpt-4-1106-preview", # 4t is for "4 turbo"
    "gpt3t" => "gpt-3.5-turbo-1106", # 3t is for "3 turbo"
    "ada" => "text-embedding-ada-002")
# the below default is defined in llm_interace.jl !
# const PROMPT_SCHEMA = OpenAISchema()

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

include("utils.jl")

export aigenerate, aiembed, aiclassify, aiextract, aiscan
# export render # for debugging only
include("llm_interface.jl")

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
export AICode
# Not export extract_code_blocks, extract_function_name
include("code_generation.jl")

## Individual interfaces
include("llm_shared.jl")
include("llm_openai.jl")
include("llm_ollama_managed.jl")

## Convenience utils
export @ai_str, @aai_str
include("macros.jl")

function __init__()
    # Load templates
    load_templates!()
end

# Enable precompilation to reduce start time, disabled logging
with_logger(NullLogger()) do
    @compile_workload include("precompilation.jl")
end

end # module PromptingTools
