module PromptingTools

using OpenAI
using JSON3
using JSON3: StructTypes
using HTTP
using PrecompileTools

# GLOBALS
const MODEL_CHAT = "gpt-3.5-turbo"
const MODEL_EMBEDDING = "text-embedding-ada-002"
const API_KEY = get(ENV, "OPENAI_API_KEY", "")
@assert isempty(API_KEY)==false "Please set OPENAI_API_KEY environment variable!"
# Cost per 1K tokens as of 7th November 2023
const MODEL_COSTS = Dict("gpt-3.5-turbo" => (0.0015, 0.002),
    "gpt-3.5-turbo-1106" => (0.001, 0.002),
    "gpt-4" => (0.03, 0.06),
    "gpt-4-1106-preview" => (0.01, 0.03),
    "text-embedding-ada-002" => (0.001, 0.0))
const MODEL_ALIASES = Dict("gpt3" => "gpt-3.5-turbo",
    "gpt4" => "gpt-4",
    "gpt4t" => "gpt-4-1106-preview", # 4t is for "4 turbo"
    "gpt3t" => "gpt-3.5-turbo-1106", # 3t is for "3 turbo"
    "ada" => "text-embedding-ada-002")
# the below default is defined in llm_interace.jl !
# const PROMPT_SCHEMA = OpenAISchema()

include("utils.jl")

export aigenerate, aiembed, aiclassify
# export render # for debugging only
include("llm_interface.jl")

## Conversation history / Prompt elements
export AIMessage
# export UserMessage, SystemMessage, DataMessage # for debugging only
include("messages.jl")

export aitemplates, AITemplate
include("templates.jl")
const TEMPLATE_STORE = Dict{Symbol, Any}()
const TEMPLATE_METADATA = Vector{AITemplateMetadata}()

## Individual interfaces
include("llm_openai.jl")

## Convenience utils
export @ai_str, @aai_str
include("macros.jl")

function __init__()
    # Load templates
    load_templates!()
end

# Enable precompilation to reduce start time
# @setup_workload include("precompilation.jl");

end # module PromptingTools
