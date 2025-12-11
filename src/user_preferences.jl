# Defines the important Globals, model registry and user preferences
# See below (eg, MODEL_REGISTRY, ModelSpec)

"""
    PREFERENCES

You can set preferences for PromptingTools by setting environment variables or by using the `set_preferences!`.
    It will create a `LocalPreferences.toml` file in your current directory and will reload your prefences from there.

Check your preferences by calling `get_preferences(key::String)`.
    
# Available Preferences (for `set_preferences!`)
- `OPENAI_API_KEY`: The API key for the OpenAI API. See [OpenAI's documentation](https://platform.openai.com/docs/quickstart?context=python) for more information.
- `AZURE_OPENAI_API_KEY`: The API key for the Azure OpenAI API. See [Azure OpenAI's documentation](https://learn.microsoft.com/en-us/azure/ai-services/openai/reference) for more information.
- `AZURE_OPENAI_HOST`: The host for the Azure OpenAI API. See [Azure OpenAI's documentation](https://learn.microsoft.com/en-us/azure/ai-services/openai/reference) for more information.
- `MISTRAL_API_KEY`: The API key for the Mistral AI API. See [Mistral AI's documentation](https://docs.mistral.ai/) for more information.
- `COHERE_API_KEY`: The API key for the Cohere API. See [Cohere's documentation](https://docs.cohere.com/docs/the-cohere-platform) for more information.
- `DATABRICKS_API_KEY`: The API key for the Databricks Foundation Model API. See [Databricks' documentation](https://docs.databricks.com/en/machine-learning/foundation-models/api-reference.html) for more information.
- `DATABRICKS_HOST`: The host for the Databricks API. See [Databricks' documentation](https://docs.databricks.com/en/machine-learning/foundation-models/api-reference.html) for more information.
- `TAVILY_API_KEY`: The API key for the Tavily Search API. Register [here](https://tavily.com/). See more information [here](https://docs.tavily.com/docs/tavily-api/rest_api).
- `GOOGLE_API_KEY`: The API key for Google Gemini models. Get yours from [here](https://ai.google.dev/). If you see a documentation page ("Available languages and regions for Google AI Studio and Gemini API"), it means that it's not yet available in your region.
- `ANTHROPIC_API_KEY`: The API key for the Anthropic API. Get yours from [here](https://www.anthropic.com/).
- `VOYAGE_API_KEY`: The API key for the Voyage API. Free tier is upto 50M tokens! Get yours from [here](https://dash.voyageai.com/api-keys).
- `GROQ_API_KEY`: The API key for the Groq API. Free in beta! Get yours from [here](https://console.groq.com/keys).
- `DEEPSEEK_API_KEY`: The API key for the DeepSeek API. Get \$5 credit when you join. Get yours from [here](https://platform.deepseek.com/api_keys).
- `OPENROUTER_API_KEY`: The API key for the OpenRouter API. Get yours from [here](https://openrouter.ai/keys).
- `CEREBRAS_API_KEY`: The API key for the Cerebras API. Get yours from [here](https://cloud.cerebras.ai/).
- `SAMBANOVA_API_KEY`: The API key for the Sambanova API. Get yours from [here](https://cloud.sambanova.ai/apis).
- `XAI_API_KEY`: The API key for the XAI API. Get your key from [here](https://console.x.ai/).
- `MOONSHOT_API_KEY`: The API key for the Moonshot API. Get your key from [here](https://platform.moonshot.ai/).
- `MINIMAX_API_KEY`: The API key for the MiniMax API. Get your key from [here](https://intl.minimaxi.com/document/platform%20introduction).
- `MODEL_CHAT`: The default model to use for aigenerate and most ai* calls. See `MODEL_REGISTRY` for a list of available models or define your own.
- `MODEL_EMBEDDING`: The default model to use for aiembed (embedding documents). See `MODEL_REGISTRY` for a list of available models or define your own.
- `PROMPT_SCHEMA`: The default prompt schema to use for aigenerate and most ai* calls (if not specified in `MODEL_REGISTRY`). Set as a string, eg, `"OpenAISchema"`.
    See `PROMPT_SCHEMA` for more information.
- `MODEL_ALIASES`: A dictionary of model aliases (`alias => full_model_name`). Aliases are used to refer to models by their aliases instead of their full names to make it more convenient to use them.
    See `MODEL_ALIASES` for more information.
- `MAX_HISTORY_LENGTH`: The maximum length of the conversation history. Defaults to 5. Set to `nothing` to disable history.
    See `CONV_HISTORY` for more information.
- `LOCAL_SERVER`: The URL of the local server to use for `ai*` calls. Defaults to `http://localhost:10897/v1`. This server is called when you call `model="local"`
    See `?LocalServerOpenAISchema` for more information and examples.
- `LOG_DIR`: The directory to save the logs to, eg, when using `SaverSchema <: AbstractTracerSchema`. Defaults to `joinpath(pwd(), "log")`. Refer to `?SaverSchema` for more information on how it works and examples.

At the moment it is not possible to persist changes to `MODEL_REGISTRY` across sessions. 
Define your `register_model!()` calls in your `startup.jl` file to make them available across sessions or put them at the top of your script.

# Available ENV Variables
- `OPENAI_API_KEY`: The API key for the OpenAI API. 
- `AZURE_OPENAI_API_KEY`: The API key for the Azure OpenAI API. 
- `AZURE_OPENAI_HOST`: The host for the Azure OpenAI API. This is the URL built as `https://<resource-name>.openai.azure.com`.
- `MISTRAL_API_KEY`: The API key for the Mistral AI API.
- `COHERE_API_KEY`: The API key for the Cohere API.
- `LOCAL_SERVER`: The URL of the local server to use for `ai*` calls. Defaults to `http://localhost:10897/v1`. This server is called when you call `model="local"`
- `DATABRICKS_API_KEY`: The API key for the Databricks Foundation Model API.
- `DATABRICKS_HOST`: The host for the Databricks API.
- `TAVILY_API_KEY`: The API key for the Tavily Search API. Register [here](https://tavily.com/). See more information [here](https://docs.tavily.com/docs/tavily-api/rest_api).
- `GOOGLE_API_KEY`: The API key for Google Gemini models. Get yours from [here](https://ai.google.dev/). If you see a documentation page ("Available languages and regions for Google AI Studio and Gemini API"), it means that it's not yet available in your region.
- `ANTHROPIC_API_KEY`: The API key for the Anthropic API. Get yours from [here](https://www.anthropic.com/).
- `VOYAGE_API_KEY`: The API key for the Voyage API. Free tier is upto 50M tokens! Get yours from [here](https://dash.voyageai.com/api-keys).
- `GROQ_API_KEY`: The API key for the Groq API. Free in beta! Get yours from [here](https://console.groq.com/keys).
- `DEEPSEEK_API_KEY`: The API key for the DeepSeek API. Get \$5 credit when you join. Get yours from [here](https://platform.deepseek.com/api_keys).
- `OPENROUTER_API_KEY`: The API key for the OpenRouter API. Get yours from [here](https://openrouter.ai/keys).
- `CEREBRAS_API_KEY`: The API key for the Cerebras API.
- `SAMBANOVA_API_KEY`: The API key for the Sambanova API.
- `LOG_DIR`: The directory to save the logs to, eg, when using `SaverSchema <: AbstractTracerSchema`. Defaults to `joinpath(pwd(), "log")`. Refer to `?SaverSchema` for more information on how it works and examples.
- `XAI_API_KEY`: The API key for the XAI API. Get your key from [here](https://console.x.ai/).
- `MOONSHOT_API_KEY`: The API key for the Moonshot API. Get your key from [here](https://platform.moonshot.cn/).
- `MINIMAX_API_KEY`: The API key for the MiniMax API. Get your key from [here](https://intl.minimaxi.com/document/platform%20introduction).

Preferences.jl takes priority over ENV variables, so if you set a preference, it will take precedence over the ENV variable.

WARNING: NEVER EVER sync your `LocalPreferences.toml` file! It contains your API key and other sensitive information!!!
"""
const PREFERENCES = nothing

"Keys that are allowed to be set via `set_preferences!`"
const ALLOWED_PREFERENCES = ["MISTRAL_API_KEY",
    "OPENAI_API_KEY",
    "AZURE_OPENAI_API_KEY",
    "AZURE_OPENAI_HOST",
    "COHERE_API_KEY",
    "DATABRICKS_API_KEY",
    "DATABRICKS_HOST",
    "TAVILY_API_KEY",
    "GOOGLE_API_KEY",
    "ANTHROPIC_API_KEY",
    "VOYAGE_API_KEY",
    "GROQ_API_KEY",
    "DEEPSEEK_API_KEY",
    "OPENROUTER_API_KEY",  # Added OPENROUTER_API_KEY
    "CEREBRAS_API_KEY",
    "SAMBANOVA_API_KEY",
    "XAI_API_KEY",
    "MOONSHOT_API_KEY",  # Added XAI_API_KEY
    "MINIMAX_API_KEY",
    "MODEL_CHAT",
    "MODEL_EMBEDDING",
    "MODEL_ALIASES",
    "PROMPT_SCHEMA",
    "MAX_HISTORY_LENGTH",
    "LOCAL_SERVER",
    "LOG_DIR"]

"""
    set_preferences!(pairs::Pair{String, <:Any}...)

Set preferences for PromptingTools. See `?PREFERENCES` for more information. 

See also: `get_preferences`

# Example

Change your API key and default model:
```julia
PromptingTools.set_preferences!("OPENAI_API_KEY" => "key1", "MODEL_CHAT" => "chat1")
```
"""
function set_preferences!(pairs::Pair{String, <:Any}...)
    global ALLOWED_PREFERENCES
    for (key, value) in pairs
        @assert key in ALLOWED_PREFERENCES "Unknown preference '$key'! (Allowed preferences: $(join(ALLOWED_PREFERENCES,", "))"
        @set_preferences!(key=>value)
        if key == "MODEL_ALIASES" || key == "PROMPT_SCHEMA"
            # cannot change in the same session
            continue
        else
            setproperty!(@__MODULE__, Symbol(key), value)
        end
    end
    @info("Preferences set; restart your Julia session for this change to take effect!")
end
"""
    get_preferences(key::String)

Get preferences for PromptingTools. See `?PREFERENCES` for more information.

See also: `set_preferences!`

# Example
```julia
PromptingTools.get_preferences("MODEL_CHAT")
```
"""
function get_preferences(key::String)
    global ALLOWED_PREFERENCES
    @assert key in ALLOWED_PREFERENCES "Unknown preference '$key'! (Allowed preferences: $(join(ALLOWED_PREFERENCES,", "))"
    getproperty(@__MODULE__, Symbol(key))
end

## Load up GLOBALS
global MODEL_CHAT::String = @load_preference("MODEL_CHAT", default="gpt-5-mini")
global MODEL_EMBEDDING::String = @load_preference("MODEL_EMBEDDING",
    default="text-embedding-3-small")
global MODEL_IMAGE_GENERATION::String = @load_preference("MODEL_IMAGE_GENERATION",
    default="dall-e-3")
# the prompt schema default is defined in llm_interace.jl !
# const PROMPT_SCHEMA = OpenAISchema()

# First, load from preferences, then from environment variables
# Instantiate empty global variables
global OPENAI_API_KEY::String = ""
global AZURE_OPENAI_API_KEY::String = ""
global AZURE_OPENAI_HOST::String = ""
global MISTRAL_API_KEY::String = ""
global COHERE_API_KEY::String = ""
global DATABRICKS_API_KEY::String = ""
global DATABRICKS_HOST::String = ""
global TAVILY_API_KEY::String = ""
global GOOGLE_API_KEY::String = ""
global TOGETHER_API_KEY::String = ""
global FIREWORKS_API_KEY::String = ""
global ANTHROPIC_API_KEY::String = ""
global VOYAGE_API_KEY::String = ""
global GROQ_API_KEY::String = ""
global DEEPSEEK_API_KEY::String = ""
global OPENROUTER_API_KEY::String = ""
global CEREBRAS_API_KEY::String = ""
global SAMBANOVA_API_KEY::String = ""
global LOCAL_SERVER::String = ""
global LOG_DIR::String = ""
global XAI_API_KEY::String = ""
global MOONSHOT_API_KEY::String = ""
global MINIMAX_API_KEY::String = ""

# Load them on init
"Loads API keys from environment variables and preferences"
function load_api_keys!()
    global OPENAI_API_KEY
    OPENAI_API_KEY = @load_preference("OPENAI_API_KEY",
        default=get(ENV, "OPENAI_API_KEY", ""))
    global AZURE_OPENAI_API_KEY
    AZURE_OPENAI_API_KEY = @load_preference("AZURE_OPENAI_API_KEY",
        default=get(ENV, "AZURE_OPENAI_API_KEY", ""))
    global AZURE_OPENAI_HOST
    AZURE_OPENAI_HOST = @load_preference("AZURE_OPENAI_HOST",
        default=get(ENV, "AZURE_OPENAI_HOST", ""))
    global MISTRAL_API_KEY
    MISTRAL_API_KEY = @load_preference("MISTRAL_API_KEY",
        default=get(ENV, "MISTRAL_API_KEY",
        get(ENV, "MISTRALAI_API_KEY", "")))
    if !isempty(get(ENV, "MISTRALAI_API_KEY", ""))
        @debug "The MISTRALAI_API_KEY environment variable is deprecated. Use MISTRAL_API_KEY instead."
    end
    global COHERE_API_KEY
    COHERE_API_KEY = @load_preference("COHERE_API_KEY",
        default=get(ENV, "COHERE_API_KEY", ""))
    global DATABRICKS_API_KEY
    DATABRICKS_API_KEY = @load_preference("DATABRICKS_API_KEY",
        default=get(ENV, "DATABRICKS_API_KEY", ""))
    global DATABRICKS_HOST
    DATABRICKS_HOST = @load_preference("DATABRICKS_HOST",
        default=get(ENV, "DATABRICKS_HOST", ""))
    global TAVILY_API_KEY
    TAVILY_API_KEY = @load_preference("TAVILY_API_KEY",
        default=get(ENV, "TAVILY_API_KEY", ""))
    global GOOGLE_API_KEY
    GOOGLE_API_KEY = @load_preference("GOOGLE_API_KEY",
        default=get(ENV, "GOOGLE_API_KEY", ""))
    global TOGETHER_API_KEY
    TOGETHER_API_KEY = @load_preference("TOGETHER_API_KEY",
        default=get(ENV, "TOGETHER_API_KEY", ""))
    global FIREWORKS_API_KEY
    FIREWORKS_API_KEY = @load_preference("FIREWORKS_API_KEY",
        default=get(ENV, "FIREWORKS_API_KEY", ""))
    global ANTHROPIC_API_KEY
    ANTHROPIC_API_KEY = @load_preference("ANTHROPIC_API_KEY",
        default=get(ENV, "ANTHROPIC_API_KEY", ""))
    global VOYAGE_API_KEY
    VOYAGE_API_KEY = @load_preference("VOYAGE_API_KEY",
        default=get(ENV, "VOYAGE_API_KEY", ""))
    global GROQ_API_KEY
    GROQ_API_KEY = @load_preference("GROQ_API_KEY",
        default=get(ENV, "GROQ_API_KEY", ""))
    global DEEPSEEK_API_KEY
    DEEPSEEK_API_KEY = @load_preference("DEEPSEEK_API_KEY",
        default=get(ENV, "DEEPSEEK_API_KEY", ""))
    global OPENROUTER_API_KEY  # Added OPENROUTER_API_KEY
    OPENROUTER_API_KEY = @load_preference("OPENROUTER_API_KEY",
        default=get(ENV, "OPENROUTER_API_KEY", ""))
    global CEREBRAS_API_KEY
    CEREBRAS_API_KEY = @load_preference("CEREBRAS_API_KEY",
        default=get(ENV, "CEREBRAS_API_KEY", ""))
    global SAMBANOVA_API_KEY
    SAMBANOVA_API_KEY = @load_preference("SAMBANOVA_API_KEY",
        default=get(ENV, "SAMBANOVA_API_KEY", ""))
    global LOCAL_SERVER
    LOCAL_SERVER = @load_preference("LOCAL_SERVER",
        default=get(ENV, "LOCAL_SERVER", ""))
    global LOG_DIR
    LOG_DIR = @load_preference("LOG_DIR",
        default=get(ENV, "LOG_DIR", joinpath(pwd(), "log")))
    global XAI_API_KEY
    XAI_API_KEY = @load_preference("XAI_API_KEY",
        default=get(ENV, "XAI_API_KEY", ""))
    global MOONSHOT_API_KEY
    MOONSHOT_API_KEY = @load_preference("MOONSHOT_API_KEY",
        default=get(ENV, "MOONSHOT_API_KEY", ""))
    global MINIMAX_API_KEY
    MINIMAX_API_KEY = @load_preference("MINIMAX_API_KEY",
        default=get(ENV, "MINIMAX_API_KEY", ""))

    return nothing
end
# Try to load already for safety
load_api_keys!()

## CONVERSATION HISTORY
"""
    CONV_HISTORY

Tracks the most recent conversations through the `ai_str macros`.

Preference available: MAX_HISTORY_LENGTH, which sets how many last messages should be remembered.

See also: `push_conversation!`, `resize_conversation!`

"""
const CONV_HISTORY = Vector{Vector{<:Any}}()
const CONV_HISTORY_LOCK = ReentrantLock()
global MAX_HISTORY_LENGTH::Union{
    Int, Nothing} = @load_preference("MAX_HISTORY_LENGTH",
    default=5)

## Model registry
# A dictionary of model names and their specs (ie, name, costs per token, etc.)
# Model specs are saved in ModelSpec struct (see below)

### ModelSpec Functionality
"""
    ModelSpec

A struct that contains information about a model, such as its name, schema, cost per token, etc.

# Fields
- `name::String`: The name of the model. This is the name that will be used to refer to the model in the `ai*` functions.
- `schema::AbstractPromptSchema`: The schema of the model. This is the schema that will be used to generate prompts for the model, eg, `:OpenAISchema`.
- `cost_of_token_prompt::Float64`: The cost of 1 token in the prompt for this model. This is used to calculate the cost of a prompt. 
    Note: It is often provided online as cost per 1000 tokens, so make sure to convert it correctly!
- `cost_of_token_generation::Float64`: The cost of 1 token generated by this model. This is used to calculate the cost of a generation.
    Note: It is often provided online as cost per 1000 tokens, so make sure to convert it correctly!
- `description::String`: A description of the model. This is used to provide more information about the model when it is queried.

# Example
```julia
spec = ModelSpec("gpt-3.5-turbo",
    OpenAISchema(),
    0.0015,
    0.002,
    "GPT-3.5 Turbo is a 175B parameter model and a common default on the OpenAI API.")

# register it
PromptingTools.register_model!(spec)
```

But you can also register any model directly via keyword arguments:
```julia
PromptingTools.register_model!(
    name = "gpt-3.5-turbo",
    schema = OpenAISchema(),
    cost_of_token_prompt = 0.0015,
    cost_of_token_generation = 0.002,
    description = "GPT-3.5 Turbo is a 175B parameter model and a common default on the OpenAI API.")
```
"""
@kwdef mutable struct ModelSpec
    name::String
    schema::Union{AbstractPromptSchema, Nothing} = nothing
    cost_of_token_prompt::Float64 = 0.0
    cost_of_token_generation::Float64 = 0.0
    description::String = ""
end
function Base.show(io::IO, m::ModelSpec)
    dump(IOContext(io, :limit => true), m, maxdepth = 1)
end

"""
    register_model!(registry = MODEL_REGISTRY;
        name::String,
        schema::Union{AbstractPromptSchema, Nothing} = nothing,
        cost_of_token_prompt::Float64 = 0.0,
        cost_of_token_generation::Float64 = 0.0,
        description::String = "")

Register a new AI model with `name` and its associated `schema`. 

Registering a model helps with calculating the costs and automatically selecting the right prompt schema.

# Arguments
- `name`: The name of the model. This is the name that will be used to refer to the model in the `ai*` functions.
- `schema`: The schema of the model. This is the schema that will be used to generate prompts for the model, eg, `OpenAISchema()`.
- `cost_of_token_prompt`: The cost of a token in the prompt for this model. This is used to calculate the cost of a prompt. 
   Note: It is often provided online as cost per 1000 tokens, so make sure to convert it correctly!
- `cost_of_token_generation`: The cost of a token generated by this model. This is used to calculate the cost of a generation.
    Note: It is often provided online as cost per 1000 tokens, so make sure to convert it correctly!
- `description`: A description of the model. This is used to provide more information about the model when it is queried.
"""
function register_model!(registry = MODEL_REGISTRY;
        name::String,
        schema::Union{AbstractPromptSchema, Nothing} = nothing,
        cost_of_token_prompt::Float64 = 0.0,
        cost_of_token_generation::Float64 = 0.0,
        description::String = "")
    spec = ModelSpec(name,
        schema,
        cost_of_token_prompt,
        cost_of_token_generation,
        description)
    register_model!(spec; registry)
end
function register_model!(spec::ModelSpec; registry = MODEL_REGISTRY)
    haskey(registry, spec.name) &&
        @warn "Model `$(spec.name)` already registered! It will be overwritten."
    registry[spec.name] = spec
end

## Model Registry Data

### Model Aliases

# global reference MODEL_ALIASES is defined below
aliases = merge(
    Dict("gpt3" => "gpt-3.5-turbo",
        "gpt4" => "gpt-4",
        "gpt4o" => "gpt-4o",
        "gpt4ol" => "gpt-4o-2024-08-06", #GPT4o latest
        "gpt4om" => "gpt-4o-mini",
        "gpt4v" => "gpt-4-vision-preview", # 4v is for "4 vision"
        "gpt4t" => "gpt-4-turbo", # 4t is for "4 turbo"
        "gpt3t" => "gpt-3.5-turbo-0125", # 3t is for "3 turbo"
        "gpt41" => "gpt-4.1-2025-04-14",
        "gpt41m" => "gpt-4.1-mini-2025-04-14",
        "gpt41n" => "gpt-4.1-nano-2025-04-14",
        "gpt5" => "gpt-5",
        "gpt5m" => "gpt-5-mini",
        "gpt5n" => "gpt-5-nano",
        "gpt51" => "gpt-5.1",
        "gpt51c" => "gpt-5.1-codex",
        "gpt51cm" => "gpt-5.1-codex-mini",
        "gpt52" => "gpt-5.2",
        "gpt52i" => "gpt-5.2-chat-latest",
        "gpt52p" => "gpt-5.2-pro",
        "gpt45" => "gpt-4.5-preview", # 4.5 is for "4.5"
        "chatgpt" => "chatgpt-4o-latest",
        "o1" => "o1",
        "o1p" => "o1-preview",
        "o1m" => "o1-mini",
        "o3m" => "o3-mini",
        "o3" => "o3-2025-04-16",
        "o4m" => "o4-mini-2025-04-16",
        "ada" => "text-embedding-ada-002",
        "emb3small" => "text-embedding-3-small",
        "emb3large" => "text-embedding-3-large",
        "yi34c" => "yi:34b-chat",
        "oh25" => "openhermes2.5-mistral",
        "starling" => "starling-lm",
        "llama3" => "llama3:8b-instruct-q5_K_S",
        # o-llama3, because it's hosted on Ollama (same as t-mixtral on Together)
        "ollama3" => "llama3:8b-instruct-q5_K_S",
        "local" => "local-server",
        "gemini" => "gemini-pro",
        ## f-mixtral -> Fireworks.ai Mixtral
        "fmixtral" => "accounts/fireworks/models/mixtral-8x7b-instruct",
        "firefunction" => "accounts/fireworks/models/firefunction-v1",
        "fllama3" => "accounts/fireworks/models/llama-v3p1-8b-instruct",
        "fllama370" => "accounts/fireworks/models/llama-v3p1-70b-instruct",
        "fllama3405" => "accounts/fireworks/models/llama-v3p1-405b-instruct",
        "fls" => "accounts/fireworks/models/llama-v3p1-8b-instruct", #s for small
        "flm" => "accounts/fireworks/models/llama-v3p1-70b-instruct", #m for medium
        "fll" => "accounts/fireworks/models/llama-v3p1-405b-instruct", #l for large
        "fds" => "accounts/fireworks/models/deepseek-v3",
        "fqwen25c" => "accounts/fireworks/models/qwen2p5-coder-32b-instruct",
        ## t-mixtral -> Together.ai Mixtral
        "tmixtral" => "mistralai/Mixtral-8x7B-Instruct-v0.1",
        "tmixtral22" => "mistralai/Mixtral-8x22B-Instruct-v0.1",
        "tllama3" => "meta-llama/Meta-Llama-3.1-8B-Instruct-Turbo",
        "tllama370" => "meta-llama/Meta-Llama-3.1-70B-Instruct-Turbo",
        "tllama3405" => "meta-llama/Meta-Llama-3.1-405B-Instruct-Turbo",
        "tqwen25b72" => "Qwen/Qwen2.5-72B-Instruct-Turbo",
        "tqwen25b7" => "Qwen/Qwen2.5-7B-Instruct-Turbo",
        "tls" => "meta-llama/Meta-Llama-3.1-8B-Instruct-Turbo", #s for small
        "tlm" => "meta-llama/Meta-Llama-3.1-70B-Instruct-Turbo", #m for medium
        "tll" => "meta-llama/Meta-Llama-3.1-405B-Instruct-Turbo", #l for large
        "tqwen25c" => "Qwen/Qwen2.5-Coder-32B-Instruct", # c for coder
        "tds" => "deepseek-ai/DeepSeek-V3",
        ## Mistral AI
        "mistral-nemo" => "open-mistral-nemo",
        "mistral-tiny" => "mistral-tiny",
        "mistral-small" => "mistral-small-latest",
        "mistral-medium" => "mistral-medium-latest",
        "mistral-large" => "mistral-large-latest",
        "mistralt" => "mistral-tiny",
        "mistrals" => "mistral-small-latest",
        "mistralm" => "mistral-medium-latest",
        "mistrall" => "mistral-large-latest",
        "mistraln" => "open-mistral-nemo",
        "mistralc" => "codestral-latest",
        "codestral" => "codestral-latest",
        "ministral3" => "ministral-3b-latest",
        "ministral8" => "ministral-8b-latest",
        ## Default to Sonnet as a the medium offering
        "claude" => "claude-sonnet-4-20250514",
        "claude37" => "claude-3-7-sonnet-latest",
        "claude35" => "claude-3-5-sonnet-latest",
        "claude4" => "claude-sonnet-4-20250514",
        "claudeh" => "claude-haiku-4-5",
        "claudes" => "claude-sonnet-4-20250514",
        "claudeo" => "claude-opus-4-5-20251101",
        ## Groq
        "gllama3" => "llama-3.1-8b-instant",
        "gl3" => "llama-3.1-8b-instant",
        "gllama370" => "llama-3.3-70b-versatile",
        "gl70" => "llama-3.3-70b-versatile",
        "gl70s" => "llama-3.3-70b-specdec", #s for small speculative decoding
        "gllama3405" => "llama-3.1-405b-reasoning",
        "gl405" => "llama-3.1-405b-reasoning",
        "glxxs" => "llama-3.2-1b-preview", #xxs for extra extra small
        "glxs" => "llama-3.2-3b-preview", #xs for extra small
        "gls" => "llama-3.1-8b-instant", #s for small
        "glm" => "llama-3.3-70b-versatile", #m for medium
        "glmr" => "DeepSeek-R1-Distill-Llama-70b", #r R1 Distill
        "glms" => "llama-3.3-70b-specdec", #ms for medium speculative decoding
        "gll" => "llama-3.1-405b-reasoning", #l for large
        "gmixtral" => "mixtral-8x7b-32768",
        "ggemma9" => "gemma2-9b-it",
        "glst" => "llama3-groq-8b-8192-tool-use-preview",
        "glmt" => "llama3-groq-70b-8192-tool-use-preview",
        "glguard" => "llama-guard-3-8b",
        "glsv" => "llama-3.2-11b-vision-preview",
        "glmv" => "llama-3.2-90b-vision-preview",
        "gk2" => "moonshotai/kimi-k2-instruct",
        "ggptoss120" => "openai/gpt-oss-120b",
        "ggptoss20" => "openai/gpt-oss-20b",
        ## Cerebras
        "cl3" => "llama3.1-8b",
        "cllama3" => "llama3.1-8b",
        "cl70" => "llama3.1-70b",
        "cllama70" => "llama3.1-70b",
        "cgptoss120" => "gpt-oss-120b",
        ## SambaNova
        "sl3" => "Meta-Llama-3.1-8B-Instruct",
        "sllama3" => "Meta-Llama-3.1-8B-Instruct",
        "sl70" => "Meta-Llama-3.1-70B-Instruct",
        "sllama70" => "Meta-Llama-3.1-70B-Instruct",
        "sl405" => "Meta-Llama-3.1-405B-Instruct",
        "sllama405" => "Meta-Llama-3.1-405B-Instruct",
        "sl1" => "Meta-Llama-3.2-1B-Instruct",
        "sl3b" => "Meta-Llama-3.2-3B-Instruct", ## deviation not to clash with Llama 3 notation
        "slxs" => "Meta-Llama-3.2-1B-Instruct",
        "slxxs" => "Meta-Llama-3.2-3B-Instruct",
        "sls" => "Meta-Llama-3.1-8B-Instruct", # s for small
        "slm" => "Meta-Llama-3.1-70B-Instruct", # m for medium
        "sll" => "Meta-Llama-3.1-405B-Instruct", # l for large
        ## XAI's Grok
        "grok" => "grok-beta",
        "grok4" => "grok-4-0709",
        "grok4fr" => "grok-4-fast-reasoning",
        "grok4f" => "grok-4-fast-non-reasoning",
        ## MiniMax
        "minimax" => "MiniMax-Text-01",
        ## DeepSeek
        "dschat" => "deepseek-chat",
        "ds" => "deepseek-chat",
        "dscode" => "deepseek-coder",
        "dsreason" => "deepseek-reasoner",
        "dsr" => "deepseek-reasoner",
        ## OpenRouter
        "orgf8b" => "google/gemini-flash-1.5-8b",
        "orgf" => "google/gemini-flash-1.5",
        "oro1" => "openai/o1-preview",
        "oro1m" => "openai/o1-mini",
        "orcop" => "cohere/command-r-plus-08-2024",
        "orco" => "cohere/command-r-08-2024",
        "orqwenturbo" => "qwen/qwen-turbo",
        "orqwenplus" => "qwen/qwen-plus",
        "orqwenmax" => "qwen/qwen-max",
        ## Gemini 1.5 Models
        "gem15p" => "gemini-1.5-pro-latest",
        "gem15f8" => "gemini-1.5-flash-8b-latest",
        "gem15f" => "gemini-1.5-flash-latest",
        "gem20p" => "gemini-2.0-pro-exp-02-05",
        "gem20f" => "gemini-2.0-flash",
        "gem20fl" => "gemini-2.0-flash-lite-preview-02-05",
        "gem20ft" => "gemini-2.0-flash-thinking-exp-01-21",
        "gemexp" => "gemini-exp-1206", # latest experimental model from December 2024,
        "gem25p" => "gemini-2.5-pro-preview-05-06",
        "gem25f" => "gemini-2.5-flash",
        "gem25fl" => "gemini-2.5-flash-lite",
        "gem25fi" => "gemini-2.5-flash-image-preview",
        "gem3p" => "gemini-3-pro-preview",
        "gemf" => "gemini-flash-latest",
        "gemfl" => "gemini-flash-lite-latest",
        "gem25f09" => "gemini-2.5-flash-preview-09-2025",
        "gem25fl09" => "gemini-2.5-flash-lite-preview-09-2025",
        "k2" => "kimi-k2-0711-preview",
        ## Grok Code Fast
        "grokcode" => "grok-code-fast-1",
        "grokfast" => "grok-code-fast-1",
        "gcf1" => "grok-code-fast-1"
    ),
    ## Load aliases from preferences as well
    @load_preference("MODEL_ALIASES", default=Dict{String, String}()))

registry = Dict{String, ModelSpec}(
    "gpt-3.5-turbo" => ModelSpec("gpt-3.5-turbo",
        OpenAISchema(),
        0.5e-6,
        1.5e-6,
        "GPT-3.5 Turbo is a 175B parameter model and a common default on the OpenAI API. From mid-Feb 2024, it will be using the new GPT-3.5 Turbo 0125 version (pricing is set assuming the 0125 version)."),
    "gpt-3.5-turbo-1106" => ModelSpec("gpt-3.5-turbo-1106",
        OpenAISchema(),
        1e-6,
        2e-6,
        "GPT-3.5 Turbo is an updated version of GPT3.5 that is much faster and cheaper to use. 1106 refers to the release date of November 6, 2023."),
    "gpt-3.5-turbo-0125" => ModelSpec("gpt-3.5-turbo-0125",
        OpenAISchema(),
        0.5e-6,
        1.5e-6,
        "GPT-3.5 Turbo is an updated version of GPT3.5 that is much faster and cheaper to use. This is the cheapest GPT-3.5 Turbo model. 0125 refers to the release date of January 25, 2024."),
    "gpt-4" => ModelSpec("gpt-4",
        OpenAISchema(),
        3e-5,
        6e-5,
        "GPT-4 is a 1.75T parameter model and the largest model available on the OpenAI API."),
    "gpt-4-1106-preview" => ModelSpec("gpt-4-1106-preview",
        OpenAISchema(),
        1e-5,
        3e-5,
        "GPT-4 Turbo 1106 is an updated version of GPT4 that is much faster and the cheaper to use. 1106 refers to the release date of November 6, 2023."),
    "gpt-4-0125-preview" => ModelSpec("gpt-4-0125-preview",
        OpenAISchema(),
        1e-5,
        3e-5,
        "GPT-4 Turbo is an updated version of GPT4 that is much faster and the cheaper to use. This is the general name for whatever is the latest GPT4 Turbo preview release. In April-24, it points to version 2024-04-09."),
    "gpt-4-turbo" => ModelSpec("gpt-4-turbo",
        OpenAISchema(),
        1e-5,
        3e-5,
        "GPT-4 Turbo is an updated version of GPT4 that is much faster and cheaper to use. This is the general name for whatever is the latest GPT4 Turbo preview release."),
    "gpt-4-turbo-2024-04-09" => ModelSpec("gpt-4-turbo-2024-04-09",
        OpenAISchema(),
        1e-5,
        3e-5,
        "GPT-4 Turbo is an updated version of GPT4 that is much faster and the cheaper to use. 2024-04-09 refers to the release date of 9th April 2024 with knowledge upto December 2023."),
    "gpt-4-turbo-preview" => ModelSpec("gpt-4-turbo-preview",
        OpenAISchema(),
        1e-5,
        3e-5,
        "GPT-4 Turbo is an updated version of GPT4 that is much faster and the cheaper to use. This is the general name for whatever is the latest GPT4 Turbo preview release. Right now it is 0125."),
    "gpt-4.5-preview" => ModelSpec("gpt-4.5-preview",
        OpenAISchema(),
        7.5e-5,
        1.5e-4,
        "GPT-4.5 is the latest preview version of GPT4.5. It has 128K context, 16K output and is the largest model available on the OpenAI API."),
    "gpt-4.5-preview-2025-02-27" => ModelSpec("gpt-4.5-preview-2025-02-27",
        OpenAISchema(),
        7.5e-5,
        1.5e-4,
        "GPT-4.5 is the latest preview version of GPT4.5. It has 128K context, 16K output and is the largest model available on the OpenAI API."),
    "gpt-4o-2024-05-13" => ModelSpec("gpt-4o-2024-05-13",
        OpenAISchema(),
        5e-6,
        1.5e-5,
        "GPT-4 Omni, the latest GPT4 model that is faster and cheaper than GPT-4 Turbo is an updated version of GPT4 that is much faster and the cheaper to use."),
    "gpt-4o-2024-08-06" => ModelSpec("gpt-4o-2024-08-06",
        OpenAISchema(),
        2.5e-6,
        1.0e-5,
        "GPT-4 Omni, the latest GPT4 model series that is faster and faster. This is the latest version from Aug-24, which is cheaper than May-24 version."),
    "gpt-4o" => ModelSpec("gpt-4o",
        OpenAISchema(),
        5e-6,
        1.5e-5,
        "GPT-4 Omni, the latest GPT4 model that is faster and cheaper than GPT-4 Turbo is an updated version of GPT4 that is much faster and the cheaper to use. Context of 128K, knowledge until October 2023. Currently points to version gpt-4o-2024-05-13."),
    "gpt-4o-mini" => ModelSpec("gpt-4o-mini",
        OpenAISchema(),
        1.5e-7,
        6e-7,
        "GPT-4 Omni Mini, the smallest and fastest model based on GPT4 (and cheaper than GPT3.5Turbo)."),
    "gpt-4o-mini-2024-07-18" => ModelSpec("gpt-4o-mini-2024-07-18",
        OpenAISchema(),
        1.5e-7,
        6e-7,
        "GPT-4 Omni Mini, the smallest and fastest model based on GPT4 (and cheaper than GPT3.5Turbo). Context of 128K, knowledge until October 2023. Currently points to version gpt-4o-2024-07-18."),
    "gpt-4.1-mini-2025-04-14" => ModelSpec("gpt-4.1-mini-2025-04-14",
        OpenAISchema(),
        4e-7,
        1.6e-6,
        "GPT-4.1 mini is the latest OpenAI model. It has 1M context, 32K output."),
    "gpt-4.1-nano-2025-04-14" => ModelSpec("gpt-4.1-nano-2025-04-14",
        OpenAISchema(),
        1e-7,
        4e-7,
        "GPT-4.1 nano is the cheapest and smallest OpenAI model. It has 1M context, 32K output."),
    "gpt-4.1-2025-04-14" => ModelSpec("gpt-4.1-2025-04-14",
        OpenAISchema(),
        2e-6,
        8e-6,
        "GPT-4.1 is the latest OpenAI model. It has 1M context, 32K output."),
    "gpt-5-2025-08-07" => ModelSpec("gpt-5-2025-08-07",
        OpenAISchema(),
        1.25e-6,
        10e-6,
        "GPT-5 is the newest OpenAI flagship model with 256K context and 128K output."),
    "gpt-5" => ModelSpec("gpt-5",
        OpenAISchema(),
        1.25e-6,
        10e-6,
        "GPT-5 is the newest OpenAI flagship model with 256K context and 128K output."),
    "gpt-5.1" => ModelSpec("gpt-5.1",
        OpenAISchema(),
        1.25e-6,
        10e-6,
        "GPT-5.1 is an update to GPT-5 with 256K context and 128K output."),
    "gpt-5.1-2025-11-13" => ModelSpec("gpt-5.1-2025-11-13",
        OpenAISchema(),
        1.25e-6,
        10e-6,
        "GPT-5.1 is with its internal name."),
    "gpt-5.1-codex" => ModelSpec("gpt-5.1-codex",
        OpenAIResponseSchema(),
        1.25e-6,
        10e-6,
        "GPT-5.1 Codex is the code-specialized variant of GPT-5.1 with 256K context and 128K output."),
    "openai/gpt-5.1-codex" => ModelSpec("openai/gpt-5.1-codex",
        OpenAIResponseSchema(),
        1.25e-6,
        10e-6,
        "GPT-5.1 Codex with its internal name."),
    "gpt-5.1-codex-mini" => ModelSpec("gpt-5.1-codex-mini",
        OpenAIResponseSchema(),
        2.5e-7,
        2e-6,
        "GPT-5.1 Codex Mini balances code performance and cost with 256K context and 128K output."),
    "openai/gpt-5.1-codex-mini" => ModelSpec("openai/gpt-5.1-codex-mini",
        OpenAIResponseSchema(),
        2.5e-7,
        2e-6,
        "GPT-5.1 Codex Mini with its internal name."),
    "gpt-5.2" => ModelSpec("gpt-5.2",
        OpenAISchema(),
        1.75e-6,
        14e-6,
        "GPT-5.2 Thinking is OpenAI's flagship model for complex tasks like coding, analysis, and planning. 400K context, 128K output."),
    "gpt-5.2-chat-latest" => ModelSpec("gpt-5.2-chat-latest",
        OpenAISchema(),
        0.5e-6,
        4e-6,
        "GPT-5.2 Instant is optimized for speed on routine queries like writing and translation. 400K context, 128K output."),
    "gpt-5.2-pro" => ModelSpec("gpt-5.2-pro",
        OpenAIResponseSchema(),
        21e-6,
        168e-6,
        "GPT-5.2 Pro is the top-end model for maximum accuracy on difficult problems. 400K context, 128K output."),
    "gpt-5-mini-2025-08-07" => ModelSpec("gpt-5-mini-2025-08-07",
        OpenAISchema(),
        2.5e-7,
        2e-6,
        "GPT-5 Mini balances capability and cost with 256K context and 128K output."),
    "gpt-5-mini" => ModelSpec("gpt-5-mini",
        OpenAISchema(),
        2.5e-7,
        2e-6,
        "GPT-5 Mini balances capability and cost with 256K context and 128K output."),
    "gpt-5-nano-2025-08-07" => ModelSpec("gpt-5-nano-2025-08-07",
        OpenAISchema(),
        5e-8,
        4e-7,
        "GPT-5 Nano is the most affordable GPT-5 variant with 256K context and 128K output."),
    "gpt-5-nano" => ModelSpec("gpt-5-nano",
        OpenAISchema(),
        5e-8,
        4e-7,
        "GPT-5 Nano is the most affordable GPT-5 variant with 256K context and 128K output."),
    "o1-preview" => ModelSpec("o1-preview",
        OpenAISchema(),
        1.5e-5,
        6e-5,
        "O1 Preview is the latest version of OpenAI's O1 model. 128K context. Knowledge until October 2023."),
    "o1-preview-2024-09-12" => ModelSpec("o1-preview-2024-09-12",
        OpenAISchema(),
        1.5e-5,
        6e-5,
        "O1 Preview is the latest version of OpenAI's O1 model. 128K context. Knowledge until October 2023."),
    "o1-mini" => ModelSpec("o1-mini",
        OpenAISchema(),
        3e-6,
        1.2e-5,
        "O1 Mini is the latest version of OpenAI's O1 model. 128K context. Knowledge until October 2023."),
    "o1-mini-2024-09-12" => ModelSpec("o1-mini-2024-09-12",
        OpenAISchema(),
        3e-6,
        1.2e-5,
        "O1 Mini is the latest version of OpenAI's O1 model. 128K context. Knowledge until October 2023."),
    "o1" => ModelSpec("o1",
        OpenAISchema(),
        1.5e-5,
        6e-5,
        "O1 is the latest version of OpenAI's O1 model. 200K context, 100K output."),
    "o1-2024-12-17" => ModelSpec("o1-2024-12-17",
        OpenAISchema(),
        1.5e-5,
        6e-5,
        "O1 is the latest version of OpenAI's O1 model. 200K context, 100K output."),
    "o3-mini" => ModelSpec("o3-mini",
        OpenAISchema(),
        1.5e-5,
        6e-5,
        "O3 Mini is the latest version of OpenAI's O3 model. 200K context, 100K output."),
    "o3-mini-2025-01-31" => ModelSpec("o3-mini-2025-01-31",
        OpenAISchema(),
        1.1e-6,
        4.4e-6,
        "O3 Mini is the latest version of OpenAI's O3 reasoning model. 200K context, 100K output."),
    "o3-2025-04-16" => ModelSpec("o3-2025-04-16",
        OpenAISchema(),
        1e-5,
        4e-5,
        "O3 is the latest version of OpenAI's O3 reasoning model, June 2024 data cut-off, 200K context, 100K output."),
    "o4-mini-2025-04-16" => ModelSpec("o4-mini-2025-04-16",
        OpenAISchema(),
        1.1e-6,
        4.4e-6,
        "O4 Mini is the latest version of OpenAI's O4 reasoning model, June 2024 data cut-off, 200K context, 100K output."),
    "chatgpt-4o-latest" => ModelSpec("chatgpt-4o-latest",
        OpenAISchema(),
        5e-6,
        1.5e-5,
        "ChatGPT-4o-latest is the latest version of ChatGPT-4o tuned for ChatGPT. It is the NOT same as gpt-4o-latest."),
    "gpt-4-vision-preview" => ModelSpec(
        "gpt-4-vision-preview",
        OpenAISchema(),
        1e-5,
        3e-5,
        "GPT-4 Vision is similar to GPT-4 but it adds visual capabilities."),
    "dall-e-3" => ModelSpec("dall-e-3",
        OpenAISchema(),
        0, ## tracked differently via ALTERNATIVE_GENERATION_COSTS
        0,  ## tracked differently via ALTERNATIVE_GENERATION_COSTS
        "The best image generation model from OpenAI DALL-E 3. Note: Costs are tracked on per-image basis!"),
    "dall-e-2" => ModelSpec("dall-e-2",
        OpenAISchema(),
        0, ## tracked differently via ALTERNATIVE_GENERATION_COSTS
        0,  ## tracked differently via ALTERNATIVE_GENERATION_COSTS
        "Image generation model from OpenAI DALL-E 2. Note: Costs are tracked on per-image basis!"),
    "text-embedding-ada-002" => ModelSpec("text-embedding-ada-002",
        OpenAISchema(),
        1e-7,
        0.0,
        "Classic text embedding endpoint Ada from 2022 with 1536 dimensions."),
    "text-embedding-3-small" => ModelSpec("text-embedding-3-small",
        OpenAISchema(),
        0.2e-7,
        0.0,
        "New text embedding endpoint with 1536 dimensions, but 5x cheaper than Ada and more performant."),
    "text-embedding-3-large" => ModelSpec("text-embedding-3-large",
        OpenAISchema(),
        1.3e-7,
        0.0,
        "New text embedding endpoint with 3072 dimensions, c. 30% more expensive than Ada but more performant."),
    "llama2" => ModelSpec("llama2",
        OllamaSchema(),
        0.0,
        0.0,
        "LLAMA2 is a 7B parameter model from Meta."),
    "openhermes2.5-mistral" => ModelSpec("openhermes2.5-mistral",
        OllamaSchema(),
        0.0,
        0.0,
        "OpenHermes 2.5 Mistral is a 7B parameter model finetuned by X on top of base model from Mistral AI."),
    "starling-lm" => ModelSpec("starling-lm",
        OllamaSchema(),
        0.0,
        0.0,
        "Starling LM is a 7B parameter model finetuned by X on top of base model from Starling AI."),
    "yi:34b-chat" => ModelSpec("yi:34b-chat",
        OllamaSchema(),
        0.0,
        0.0,
        "Yi is a 34B parameter model finetuned by X on top of base model from Starling AI."),
    "llama3:8b-instruct-q5_K_S" => ModelSpec("llama3:8b-instruct-q5_K_S",
        OllamaSchema(),
        0.0,
        0.0,
        "Llama 3 8b is the latest model from Meta"
    ),
    "wizardlm2:7b-q5_K_S" => ModelSpec("wizardlm2:7b-q5_K_S",
        OllamaSchema(),
        0.0,
        0.0,
        "WizardLM2 7b from Microsoft."),
    "nomic-embed-text" => ModelSpec("nomic-embed-text",
        OllamaSchema(),
        0.0,
        0.0,
        "Ollama-hosted embedding model from Nomic with 127M parameters and 8K tokens context. Alleged to be competitive with OpenAI small embedding model."),
    "mxbai-embed-large" => ModelSpec("mxbai-embed-large",
        OllamaSchema(),
        0.0,
        0.0,
        "Ollama-hosted embedding model from MixedBread.ai with 334M parameters and 512 tokens context. Alleged to be competitive with OpenAI large embedding model."),
    "llava" => ModelSpec("llava",
        OllamaSchema(),
        0.0,
        0.0,
        "A novel end-to-end trained large multimodal model that combines a vision encoder and Vicuna for general-purpose visual and language understanding."),
    "bakllava" => ModelSpec("bakllava",
        OllamaSchema(),
        0.0, 0.0,
        "BakLLaVA is a multimodal model consisting of the Mistral 7B base model augmented with the LLaVA architecture."),
    "open-mistral-7b" => ModelSpec("open-mistral-7b",
        MistralOpenAISchema(),
        2.5e-7,
        2.5e-7,
        "Mistral AI's hosted version of openly available Mistral-7B-v0.2. Great for simple tasks."),
    "open-mixtral-8x7b" => ModelSpec("open-mixtral-8x7b",
        MistralOpenAISchema(),
        7e-7,
        7e-7,
        "Mistral AI's hosted version of openly available Mixtral-8x7B-v0.1. Good for more complicated tasks."),
    "mistral-tiny" => ModelSpec("mistral-tiny",
        MistralOpenAISchema(),
        2e-6,
        6e-6,
        "Mistral AI's own finetune of their 7b model."),
    "mistral-tiny-2312" => ModelSpec("mistral-tiny-2312",
        MistralOpenAISchema(),
        2e-6,
        6e-6,
        "Mistral AI's own finetune of their 7b model. Version 2312."),
    "mistral-small-latest" => ModelSpec("mistral-small-latest",
        MistralOpenAISchema(),
        2e-6,
        6e-6,
        "Mistral AI's own finetune (historically similar to Mixtral-8x7B)."),
    "mistral-small-2402" => ModelSpec("mistral-small-2402",
        MistralOpenAISchema(),
        2e-6,
        6e-6,
        "Mistral AI's own finetune (historically similar to Mixtral-8x7B). Version 2402."),
    "mistral-medium-latest" => ModelSpec("mistral-medium-latest",
        MistralOpenAISchema(),
        2.7e-6,
        8.1e-6,
        "Mistral AI's own model. Details unknown."),
    "mistral-medium-2312" => ModelSpec("mistral-medium-2312",
        MistralOpenAISchema(),
        2.7e-6,
        8.1e-6,
        "Mistral AI's own model. Version 2312. Details unknown."),
    "mistral-large-latest" => ModelSpec("mistral-large-latest",
        MistralOpenAISchema(),
        8e-6,
        2.4e-5,
        "Mistral AI's hosted version of their best model available. Details unknown."),
    "mistral-large-2402" => ModelSpec("mistral-large-2402",
        MistralOpenAISchema(),
        3e-6,
        9e-6,
        "Mistral AI's hosted version of their best model available. Version 2402. Details unknown."),
    "mistral-large-2407" => ModelSpec("mistral-large-2407",
        MistralOpenAISchema(),
        3e-6,
        9e-6,
        "Mistral AI's hosted version of their largest and best model available Mistral Large with 123bn parameters and 128K context. Version 2407 (released in July 2024). Details unknown."),
    "codestral-latest" => ModelSpec("codestral-latest",
        MistralOpenAISchema(),
        1e-6,
        3e-6,
        "Mistral AI's Code completion model, 22B parameters. Very quick and performant."),
    "codestral-2405" => ModelSpec("codestral-2405",
        MistralOpenAISchema(),
        1e-6,
        3e-6,
        "Mistral AI's Code completion model, 22B parameters. Very quick and performant."),
    "open-mistral-nemo" => ModelSpec("open-mistral-nemo",
        MistralOpenAISchema(),
        3e-7,
        3e-7,
        "Mistral Nemo is a state-of-the-art 12B model developed with NVIDIA."),
    "open-mistral-nemo-2407" => ModelSpec("open-mistral-nemo-2407",
        MistralOpenAISchema(),
        3e-7,
        3e-7,
        "Mistral Nemo is a state-of-the-art 12B model developed with NVIDIA. Version 2407."),
    "ministral-8b-latest" => ModelSpec("ministral-8b-latest",
        MistralOpenAISchema(),
        1e-7,
        1e-7,
        "Mistral AI's latest 8B model. 128K context."),
    "ministral-8b-2410" => ModelSpec("ministral-8b-2410",
        MistralOpenAISchema(),
        1e-7,
        1e-7,
        "Mistral AI's latest 8B model. Version 2410, 128K context."),
    "ministral-3b-latest" => ModelSpec("ministral-3b-latest",
        MistralOpenAISchema(),
        4e-8,
        4e-8,
        "Mistral AI's latest 3B model. 128K context."),
    "ministral-3b-2410" => ModelSpec("ministral-3b-2410",
        MistralOpenAISchema(),
        4e-8,
        4e-8,
        "Mistral AI's latest 3B model. Version 2410, 128K context."),
    "mistral-embed" => ModelSpec("mistral-embed",
        MistralOpenAISchema(),
        1e-7,
        0.0,
        "Mistral AI's hosted model for embeddings."),
    "echo" => ModelSpec("echo",
        TestEchoOpenAISchema(;
            response = Dict(
                :choices => [
                    Dict(:message => Dict(:content => "Hello!"),
                    :finish_reason => "stop")
                ],
                :usage => Dict(:total_tokens => 3,
                    :prompt_tokens => 2,
                    :completion_tokens => 1)), status = 200),
        0.0,
        0.0,
        "Echo is only for testing. It always responds with 'Hello!'"),
    "local-server" => ModelSpec("local-server",
        LocalServerOpenAISchema(),
        0.0,
        0.0,
        "Local server, eg, powered by [Llama.jl](https://github.com/marcom/Llama.jl). Model is specified when instantiating the server itself. It will be automatically pointed to the address in `LOCAL_SERVER`."),
    "custom" => ModelSpec("custom",
        LocalServerOpenAISchema(),
        0.0,
        0.0,
        "Send a generic request to a custom server. Make sure to explicitly define the `api_kwargs = (; url = ...)` when calling the model."),
    "gemini-pro" => ModelSpec("gemini-pro",
        GoogleSchema(),
        0.0, #unknown, expected 1.25e-7
        0.0, #unknown, expected 3.75e-7
        "Gemini Pro is a LLM from Google. For more information, see [models](https://ai.google.dev/models/gemini)."),
    "accounts/fireworks/models/mixtral-8x7b-instruct" => ModelSpec(
        "accounts/fireworks/models/mixtral-8x7b-instruct",
        FireworksOpenAISchema(),
        5e-7,
        5e-7,
        "Mixtral (8x7b) from Mistral, hosted by Fireworks.ai. For more information, see [models](https://fireworks.ai/models/fireworks/mixtral-8x7b-instruct)."),
    "accounts/fireworks/models/mixtral-8x22b-instruct-preview" => ModelSpec(
        "accounts/fireworks/models/mixtral-8x22b-instruct-preview",
        FireworksOpenAISchema(),
        9e-7,
        9e-7,
        "Mixtral (8x22b) from Mistral, instruction finetuned and hosted by Fireworks.ai. For more information, see [models](https://fireworks.ai/models/fireworks/mixtral-8x22b-instruct-preview)."),
    "accounts/fireworks/models/dbrx-instruct" => ModelSpec(
        "accounts/fireworks/models/dbrx-instruct",
        FireworksOpenAISchema(),
        1.6e-6,
        1.6e-6,
        "Databricks DBRX Instruct, hosted by Fireworks.ai. For more information, see [models](https://fireworks.ai/models/fireworks/dbrx-instruct)."),
    "accounts/fireworks/models/qwen-72b-chat" => ModelSpec(
        "accounts/fireworks/models/qwen-72b-chat",
        FireworksOpenAISchema(),
        9e-7,
        9e-7,
        "Qwen is a 72B parameter model from Alibaba Cloud, hosted by from Fireworks.ai. For more information, see [models](https://fireworks.ai/models/fireworks/dbrx-instruct)."),
    "accounts/fireworks/models/firefunction-v1" => ModelSpec(
        "accounts/fireworks/models/firefunction-v1",
        FireworksOpenAISchema(),
        0.0, #unknown, expected to be the same as Mixtral
        0.0, #unknown, expected to be the same as Mixtral
        "Fireworks' open-source function calling model (fine-tuned Mixtral). Useful for `aiextract` calls. For more information, see [models](https://fireworks.ai/models/fireworks/firefunction-v1)."),
    "accounts/fireworks/models/llama-v3p1-405b-instruct" => ModelSpec(
        "accounts/fireworks/models/llama-v3p1-405b-instruct",
        FireworksOpenAISchema(),
        3e-6,
        3e-6,
        "Meta Llama 3.1 405b, hosted by Fireworks.ai. Context 131K tokens. For more information, see [models](https://fireworks.ai/models/fireworks/llama-v3p1-405b-instruct)."),
    "accounts/fireworks/models/llama-v3p1-70b-instruct" => ModelSpec(
        "accounts/fireworks/models/llama-v3p1-70b-instruct",
        FireworksOpenAISchema(),
        9e-7,
        9e-7,
        "Meta Llama 3.1 70b, hosted by Fireworks.ai. Context 131K tokens. For more information, see [models](https://fireworks.ai/models/fireworks/llama-v3p1-70b-instruct)."),
    "accounts/fireworks/models/llama-v3p1-8b-instruct" => ModelSpec(
        "accounts/fireworks/models/llama-v3p1-8b-instruct",
        FireworksOpenAISchema(),
        2e-7,
        2e-7,
        "Meta Llama 3.1 8b, hosted by Fireworks.ai. Context 131K tokens. For more information, see [models](https://fireworks.ai/models/fireworks/llama-v3p1-8b-instruct)."),
    "accounts/fireworks/models/deepseek-v3" => ModelSpec(
        "accounts/fireworks/models/deepseek-v3",
        FireworksOpenAISchema(),
        9e-7,
        9e-7,
        "Deepseek's latest model, DeepSeek V3, hosted by Fireworks.ai. 130K context."),
    "accounts/fireworks/models/qwen2p5-coder-32b-instruct" => ModelSpec(
        "accounts/fireworks/models/qwen2p5-coder-32b-instruct",
        FireworksOpenAISchema(),
        9e-7,
        9e-7,
        "Qwen 2.5 Coder 32B, hosted by Fireworks.ai. 32K context."),
    ## Together AI
    "mistralai/Mixtral-8x7B-Instruct-v0.1" => ModelSpec(
        "mistralai/Mixtral-8x7B-Instruct-v0.1",
        TogetherOpenAISchema(),
        6e-7,
        6e-7,
        "Mixtral (8x7b) from Mistral, hosted by Together.ai. For more information, see [models](https://docs.together.ai/docs/inference-models)."),
    "mistralai/Mixtral-8x22B-Instruct-v0.1" => ModelSpec(
        "mistralai/Mixtral-8x22B-Instruct-v0.1",
        TogetherOpenAISchema(),
        1.2e-6,
        1.2e-6,
        "Mixtral (22x7b) from Mistral, hosted by Together.ai. For more information, see [models](https://docs.together.ai/docs/inference-models)."),
    "meta-llama/Llama-3-8b-chat-hf" => ModelSpec(
        "meta-llama/Llama-3-8b-chat-hf",
        TogetherOpenAISchema(),
        2e-7,
        2e-7,
        "Meta Llama3 8b, hosted by Together.ai. For more information, see [models](https://docs.together.ai/docs/inference-models)."),
    "meta-llama/Llama-3-70b-chat-hf" => ModelSpec(
        "meta-llama/Llama-3-70b-chat-hf",
        TogetherOpenAISchema(),
        9e-7,
        9e-7,
        "Meta Llama3 70b, hosted by Together.ai. For more information, see [models](https://docs.together.ai/docs/inference-models)."),
    "meta-llama/Meta-Llama-3.1-8B-Instruct-Turbo" => ModelSpec(
        "meta-llama/Meta-Llama-3.1-8B-Instruct-Turbo",
        TogetherOpenAISchema(),
        1e-7,
        1.8e-7,
        "Meta Llama3.1 8b, hosted by Together.ai. For more information, see [models](https://docs.together.ai/docs/inference-models)."),
    "meta-llama/Meta-Llama-3.1-70B-Instruct-Turbo" => ModelSpec(
        "meta-llama/Meta-Llama-3.1-70B-Instruct-Turbo",
        TogetherOpenAISchema(),
        5.4e-7,
        8.8e-7,
        "Meta Llama3.1 70b, hosted by Together.ai. For more information, see [models](https://docs.together.ai/docs/inference-models)."),
    "meta-llama/Meta-Llama-3.1-405B-Instruct-Turbo" => ModelSpec(
        "meta-llama/Meta-Llama-3.1-405B-Instruct-Turbo",
        TogetherOpenAISchema(),
        5e-6,
        1.5e-5,
        "Meta Llama3.1 405b, hosted by Together.ai. For more information, see [models](https://docs.together.ai/docs/inference-models)."),
    "Qwen/Qwen2.5-72B-Instruct-Turbo" => ModelSpec(
        "Qwen/Qwen2.5-72B-Instruct-Turbo",
        TogetherOpenAISchema(),
        0.88e-6,
        1.2e-6,
        ""),
    "Qwen/Qwen2.5-7B-Instruct-Turbo" => ModelSpec(
        "Qwen/Qwen2.5-7B-Instruct-Turbo",
        TogetherOpenAISchema(),
        0.18e-6,
        0.3e-6,
        ""),
    "MiniMax-Text-01" => ModelSpec("MiniMax-Text-01",
        MiniMaxOpenAISchema(),
        0.2e-6,  # Update these costs if you know them
        1.1e-6,
        "MiniMax Text model for chat completions."),
    "deepseek-ai/DeepSeek-V3" => ModelSpec(
        "deepseek-ai/DeepSeek-V3",
        TogetherOpenAISchema(),
        1.25e-6,
        1.25e-6,
        "Deepseek's latest model, DeepSeek V3, hosted by Together.ai. 130K context, FP8 version."),
    "Qwen/Qwen2.5-Coder-32B-Instruct" => ModelSpec(
        "Qwen/Qwen2.5-Coder-32B-Instruct",
        TogetherOpenAISchema(),
        8e-7,
        8e-7,
        "Qwen 2.5 Coder 32B, hosted by Together.ai. 32K context."),
    "Qwen/QwQ-32B-Preview" => ModelSpec(
        "Qwen/QwQ-32B-Preview",
        TogetherOpenAISchema(),
        1.2e-6,
        1.2e-6,
        "Qwen 32B reasoning model, hosted by Together.ai. 32K context."),
    ### Anthropic models
    "claude-3-7-sonnet-latest" => ModelSpec("claude-3-7-sonnet-latest",
        AnthropicSchema(),
        3e-6,
        1.5e-5,
        "Anthropic's latest Claude 3.7 Sonnet model. 200K context. See details [here](https://docs.anthropic.com/claude/docs/models-overview)"),
    "claude-3-7-sonnet-20250219" => ModelSpec("claude-3-7-sonnet-20250219",
        AnthropicSchema(),
        3e-6,
        1.5e-5,
        "Anthropic's latest Claude 3.7 Sonnet model. 200K context. See details [here](https://docs.anthropic.com/claude/docs/models-overview)"),
    "claude-3-5-sonnet-latest" => ModelSpec("claude-3-5-sonnet-latest",
        AnthropicSchema(),
        3e-6,
        1.5e-5,
        "Anthropic's latest Claude 3 Sonnet 3.5. 200K context. See details [here](https://docs.anthropic.com/claude/docs/models-overview)"),
    "claude-3-5-sonnet-20241022" => ModelSpec("claude-3-5-sonnet-20241022",
        AnthropicSchema(),
        3e-6,
        1.5e-5,
        "Anthropic's Claude 3 Sonnet 3.5 released on 2024-10-22. 200K context. See details [here](https://docs.anthropic.com/claude/docs/models-overview)"),
    "claude-3-5-sonnet-20240620" => ModelSpec("claude-3-5-sonnet-20240620",
        AnthropicSchema(),
        3e-6,
        1.5e-5,
        "Anthropic's model Claude 3 Sonent 3.5. Max output 4096 tokens, 200K context. See details [here](https://docs.anthropic.com/claude/docs/models-overview)"),
    "claude-3-opus-20240229" => ModelSpec("claude-3-opus-20240229",
        AnthropicSchema(),
        1.5e-5,
        7.5e-5,
        "Anthropic's latest and strongest model Claude 3 Opus. Max output 4096 tokens, 200K context. See details [here](https://docs.anthropic.com/claude/docs/models-overview)"),
    "claude-sonnet-4-20250514" => ModelSpec("claude-sonnet-4-20250514",
        AnthropicSchema(),
        3e-6,
        1.5e-5,
        "Anthropic's Claude 4 Sonnet model. 200K context, 64K output. See details [here](https://docs.anthropic.com/claude/docs/models-overview)"),
    "claude-opus-4-20250514" => ModelSpec("claude-opus-4-20250514",
        AnthropicSchema(),
        1.5e-5,
        7.5e-5,
        "Anthropic's Claude 4 Opus model. 200K context, 32K output. See details [here](https://docs.anthropic.com/claude/docs/models-overview)"),
    "claude-opus-4-5-20251101" => ModelSpec("claude-opus-4-5-20251101",
        AnthropicSchema(),
        5e-6,
        2.5e-5,
        "Anthropic's Claude Opus 4.5 model. 200K context, 64K output. See details [here](https://docs.anthropic.com/claude/docs/models-overview)"),
    "claude-3-sonnet-20240229" => ModelSpec("claude-3-sonnet-20240229",
        AnthropicSchema(),
        3e-6,
        1.5e-5,
        "Anthropic's middle model Claude 3 Sonnet. Max output 4096 tokens, 200K context. See details [here](https://docs.anthropic.com/claude/docs/models-overview)"),
    "claude-haiku-4-5" => ModelSpec("claude-haiku-4-5",
        AnthropicSchema(),
        1e-6,
        5e-6,
        "Anthropic's Claude Haiku 4.5 model. 200K context window, 64K output window. See details [here](https://docs.anthropic.com/claude/docs/models-overview)"),
    "claude-3-5-haiku-latest" => ModelSpec("claude-3-5-haiku-latest",
        AnthropicSchema(),
        1e-6,
        5e-6,
        "Anthropic's smallest and faster model Claude 3 Haiku. Latest version, 200K context. See details [here](https://docs.anthropic.com/claude/docs/models-overview)"),
    "claude-3-5-haiku-20241022" => ModelSpec("claude-3-5-haiku-20241022",
        AnthropicSchema(),
        1e-6,
        5e-6,
        "Anthropic's smallest and faster model Claude 3 Haiku. Version 2024-10-22, 200K context. See details [here](https://docs.anthropic.com/claude/docs/models-overview)"),
    "claude-3-haiku-20240307" => ModelSpec("claude-3-haiku-20240307",
        AnthropicSchema(),
        2.5e-7,
        1.25e-6,
        "Anthropic's smallest and faster model Claude 3 Haiku. Max output 4096 tokens, 200K context. See details [here](https://docs.anthropic.com/claude/docs/models-overview)"),
    "claude-2.1" => ModelSpec("claude-2.1",
        AnthropicSchema(),
        8e-6,
        2.4e-5,
        "Anthropic's Claude 2.1 model."),
    ## Groq -- using preliminary pricing on https://wow.groq.com/
    "DeepSeek-R1-Distill-Llama-70b" => ModelSpec("DeepSeek-R1-Distill-Llama-70b",
        GroqOpenAISchema(),
        5.9e-7,
        7.9e-7,
        "DeepSeek's R1 Distill Llama 70b, hosted by Groq. Context 128K tokens. See details [here](https://console.groq.com/docs/models)"),
    "llama-3.3-70b-specdec" => ModelSpec("llama-3.3-70b-specdec",
        GroqOpenAISchema(),
        5.9e-7,
        9.9e-7,
        "Meta's Llama3.3 70b with speculative decoding (slightly more expensive), hosted by Groq. Max output 8192 tokens, 128K context. See details [here](https://console.groq.com/docs/models)"),
    "llama-3.3-70b-versatile" => ModelSpec("llama-3.3-70b-versatile",
        GroqOpenAISchema(),
        5.9e-7,
        7.9e-7,
        "Meta's Llama3.3 70b, hosted by Groq. Max output 8192 tokens, 128K context. See details [here](https://console.groq.com/docs/models)"),
    "llama-3.1-405b-reasoning" => ModelSpec("llama-3.1-405b-reasoning",
        GroqOpenAISchema(),
        5e-6, # based on prices at together.ai... likely it will be much cheaper
        1.5e-5, # based on prices at together.ai... likely it will be much cheaper
        "Meta's Llama3.1 405b, hosted by Groq. Max output 16384 tokens, 131K context - during preview window limited to max tokens=16K. See details [here](https://console.groq.com/docs/models)"),
    "llama-3.1-70b-versatile" => ModelSpec("llama-3.1-70b-versatile",
        GroqOpenAISchema(),
        5.9e-7,
        7.9e-7,
        "Meta's Llama3.1 70b, hosted by Groq. Max output 8192 tokens, 131K context - during preview window limited to max tokens=8K. See details [here](https://console.groq.com/docs/models)"),
    "llama-3.1-8b-instant" => ModelSpec("llama-3.1-8b-instant",
        GroqOpenAISchema(),
        5e-8,
        8e-8,
        "Meta's Llama3.1 8b, hosted by Groq. Max output 8192 tokens, 131K context - during preview window limited to max tokens=8K. See details [here](https://console.groq.com/docs/models)"),
    "llama3-8b-8192" => ModelSpec("llama3-8b-8192",
        GroqOpenAISchema(),
        5e-8,
        8e-8,
        "Meta's Llama3 8b, hosted by Groq. Max output 8192 tokens, 8K context. See details [here](https://console.groq.com/docs/models)"),
    "llama3-70b-8192" => ModelSpec("llama3-70b-8192",
        GroqOpenAISchema(),
        5.9e-7,
        7.9e-7,
        "Meta's Llama3 70b, hosted by Groq. Max output 8192 tokens, 8K context. See details [here](https://console.groq.com/docs/models)"),
    "llama3-groq-70b-8192-tool-use-preview" => ModelSpec(
        "llama3-groq-70b-8192-tool-use-preview",
        GroqOpenAISchema(),
        8.9e-7,
        8.9e-7,
        "Meta's Llama3 70b, hosted by Groq and finetuned for tool use. Max output 8192 tokens, 8K context. See details [here](https://console.groq.com/docs/models)"),
    "llama3-groq-8b-8192-tool-use-preview" => ModelSpec(
        "llama3-groq-8b-8192-tool-use-preview",
        GroqOpenAISchema(),
        1.9e-7,
        1.9e-7,
        "Meta's Llama3 8b, hosted by Groq and finetuned for tool use. Max output 8192 tokens, 8K context. See details [here](https://console.groq.com/docs/models)"),
    "llama-3.2-1b-preview" => ModelSpec("llama-3.2-1b-preview",
        GroqOpenAISchema(),
        4e-8,
        4e-8,
        "Meta's Llama3.2 1b, hosted by Groq. See details [here](https://console.groq.com/docs/models)"),
    "llama-3.2-3b-preview" => ModelSpec("llama-3.2-3b-preview",
        GroqOpenAISchema(),
        6e-8,
        6e-8,
        "Meta's Llama3.2 3b, hosted by Groq. See details [here](https://console.groq.com/docs/models)"),
    ## Price guess as 11b
    "llama-3.2-11b-vision-preview" => ModelSpec("llama-3.2-11b-vision-preview",
        GroqOpenAISchema(),
        5e-8,
        8e-8,
        "Meta's Llama3.2 11b with vision, hosted by Groq. Price unknown, using 8b price as proxy. See details [here](https://console.groq.com/docs/models)"),
    ## Price guess as 70b
    "llama-3.2-90b-vision-preview" => ModelSpec("llama-3.2-90b-vision-preview",
        GroqOpenAISchema(),
        5.9e-7,
        7.9e-7,
        "Meta's Llama3.2 90b with vision, hosted by Groq. Price unknown, using 70b price as proxy. See details [here](https://console.groq.com/docs/models)"),
    "llama-guard-3-8b" => ModelSpec("llama-guard-3-8b",
        GroqOpenAISchema(),
        2e-7,
        2e-7,
        "Meta's LlamaGuard 8b, hosted by Groq. See details [here](https://console.groq.com/docs/models)"),
    "mixtral-8x7b-32768" => ModelSpec("mixtral-8x7b-32768",
        GroqOpenAISchema(),
        2.7e-7,
        2.7e-7,
        "Mistral.ai Mixtral 8x7b, hosted by Groq. Max 32K context. See details [here](https://console.groq.com/docs/models)"),
    "gemma2-9b-it" => ModelSpec("gemma2-9b-it",
        GroqOpenAISchema(),
        2e-7,
        2e-7,
        "Google's Gemma 2 9b, hosted by Groq. Max 8K context. See details [here](https://console.groq.com/docs/models)"),
    "moonshotai/kimi-k2-instruct" => ModelSpec("moonshotai/kimi-k2-instruct",
        GroqOpenAISchema(),
        1e-6,
        3e-6,
        "Moonshot's Kimi K2 model hosted by Groq. Advanced reasoning capabilities with long context support."),
    "openai/gpt-oss-120b" => ModelSpec("openai/gpt-oss-120b",
        GroqOpenAISchema(),
        1.5e-7,
        7.5e-7,
        "Open-source GPT-OSS 120B model hosted by Groq. 128K context."),
    "openai/gpt-oss-20b" => ModelSpec("openai/gpt-oss-20b",
        GroqOpenAISchema(),
        1e-7,
        5e-7,
        "Open-source GPT-OSS 20B model hosted by Groq. 128K context."),
    "deepseek-chat" => ModelSpec("deepseek-chat",
        DeepSeekOpenAISchema(),
        1.4e-7,
        2.8e-7,
        "Deepseek.com-hosted DeepSeekV2 model. Max 32K context. See details [here](https://platform.deepseek.com/docs)"),
    "deepseek-coder" => ModelSpec("deepseek-coder",
        DeepSeekOpenAISchema(),
        1.4e-7,
        2.8e-7,
        "Deepseek.com-hosted coding model. Max 16K context. See details [here](https://platform.deepseek.com/docs)"),
    "deepseek-reasoner" => ModelSpec("deepseek-reasoner",
        DeepSeekOpenAISchema(),
        5.5e-7,
        2.19e-6,
        "Deepseek.com-hosted coding model. Max 16K context. See details [here](https://platform.deepseek.com/docs)"),
    ## OpenRouter models
    "google/gemini-flash-1.5-8b" => ModelSpec("google/gemini-flash-1.5-8b",
        OpenRouterOpenAISchema(),
        0.375e-7,
        1.5e-7,
        "OpenRouter's hosted version of emini 1.5 Flash-8B is optimized for speed and efficiency, offering enhanced performance in small prompt tasks like chat, transcription, and translation."),
    "google/gemini-flash-1.5" => ModelSpec("google/gemini-flash-1.5",
        OpenRouterOpenAISchema(),
        0.75e-7,
        3e-7,
        "OpenRouter's hosted version of emini 1.5 Flash-8B is optimized for speed and efficiency, offering enhanced performance in small prompt tasks like chat, transcription, and translation."),
    "openai/o1-preview" => ModelSpec("openai/o1-preview",
        OpenRouterOpenAISchema(),
        15e-6,
        60e-6,
        "OpenRouter's hosted version of OpenAI's latest reasoning model o1-preview. 128K context, max output 32K tokens. Details unknown."),
    "openai/o1-preview-2024-09-12" => ModelSpec("openai/o1-preview-2024-09-12",
        OpenRouterOpenAISchema(),
        15e-6,
        60e-6,
        "OpenRouter's hosted version of OpenAI's latest reasoning model o1-preview, version 2024-09-12. 128K context, max output 32K tokens. Details unknown."),
    "openai/o1-mini" => ModelSpec("openai/o1-mini",
        OpenRouterOpenAISchema(),
        3e-6,
        12e-6,
        "OpenRouter's hosted version of OpenAI's latest and smallest reasoning model o1-mini. 128K context, max output 65K tokens. Details unknown."),
    "openai/o1-mini-2024-09-12" => ModelSpec("openai/o1-mini-2024-09-12",
        OpenRouterOpenAISchema(),
        3e-6,
        12e-6,
        "OpenRouter's hosted version of OpenAI's latest and smallest reasoning model o1-mini, version 2024-09-12. 128K context, max output 65K tokens. Details unknown."),
    "cohere/command-r-plus-08-2024" => ModelSpec("cohere/command-r-plus-08-2024",
        OpenRouterOpenAISchema(),
        2.5e-6,
        10e-6,
        "OpenRouter's hosted version of Cohere's latest and strongest model Command R Plus. 128K context, max output 4K tokens."),
    "qwen/qwen-turbo" => ModelSpec("qwen/qwen-turbo",
        OpenRouterOpenAISchema(),
        0.05e-6,
        0.2e-6,
        "OpenRouter's hosted version of Qwen's latest and strongest model Qwen-Plus. 128K context, max output 8K tokens."),
    "qwen/qwen-plus" => ModelSpec("qwen/qwen-plus",
        OpenRouterOpenAISchema(),
        0.4e-6,
        1.2e-6,
        "OpenRouter's hosted version of Qwen's latest and strongest model Qwen-Plus. 128K context, max output 8K tokens."),
    "qwen/qwen-max" => ModelSpec("qwen/qwen-max",
        OpenRouterOpenAISchema(),
        1.6e-6,
        6.4e-6,
        "OpenRouter's hosted version of Qwen's latest and strongest model Qwen-Plus. 128K context, max output 8K tokens."), "cohere/command-r-08-2024" => ModelSpec(
        "cohere/command-r-08-2024",
        OpenRouterOpenAISchema(),
        1.5e-7,
        6e-7,
        "OpenRouter's hosted version of Cohere's latest smaller model Command R. 128K context, max output 4K tokens."),
    "meta-llama/llama-3.1-405b" => ModelSpec("meta-llama/llama-3.1-405b",
        OpenRouterOpenAISchema(),
        2e-6,
        2e-6,
        "Meta's Llama3.1 405b, hosted by OpenRouter. This is a BASE model!! Max output 32K tokens, 131K context. See details [here](https://openrouter.ai/models/meta-llama/llama-3.1-405b)"),
    "llama3.1-8b" => ModelSpec("llama3.1-8b",
        CerebrasOpenAISchema(),
        1e-7,
        1e-7,
        "Meta's Llama3.1 8b, hosted by Cerebras.ai. Max 8K context."),
    "llama3.1-70b" => ModelSpec("llama3.1-70b",
        CerebrasOpenAISchema(),
        6e-7,
        6e-7,
        "Meta's Llama3.1 70b, hosted by Cerebras.ai. Max 8K context."),
    "gpt-oss-120b" => ModelSpec("gpt-oss-120b",
        CerebrasOpenAISchema(),
        2.5e-7,
        6.9e-7,
        "Open-source GPT-OSS 120B model hosted by Cerebras. 8K context."),
    "Meta-Llama-3.2-1B-Instruct" => ModelSpec(
        "Meta-Llama-3.2-1B-Instruct",
        SambaNovaOpenAISchema(),
        4e-8,
        8e-8,
        "Meta's Llama3.2 1b, hosted by SambaNova.ai. Max 4K context."),
    "Meta-Llama-3.2-3B-Instruct" => ModelSpec("Meta-Llama-3.2-3B-Instruct",
        SambaNovaOpenAISchema(),
        8e-8,
        1.6e-7,
        "Meta's Llama3.2 3b, hosted by SambaNova.ai. Max 4K context."),
    "Meta-Llama-3.1-8B-Instruct" => ModelSpec("Meta-Llama-3.1-8B-Instruct",
        SambaNovaOpenAISchema(),
        1e-7,
        2e-7,
        "Meta's Llama3.1 8b, hosted by SambaNova.ai. Max 64K context."),
    "Meta-Llama-3.1-70B-Instruct" => ModelSpec("Meta-Llama-3.1-70B-Instruct",
        SambaNovaOpenAISchema(),
        6e-7,
        1.2e-6,
        "Meta's Llama3.1 70b, hosted by SambaNova.ai. Max 64K context."),
    "Meta-Llama-3.1-405B-Instruct" => ModelSpec("Meta-Llama-3.1-405B-Instruct",
        SambaNovaOpenAISchema(),
        5e-6,
        1e-7,
        "Meta's Llama3.1 405b, hosted by SambaNova.ai. Max 64K context."),
    "grok-beta" => ModelSpec("grok-beta",
        XAIOpenAISchema(),
        5e-6,
        15e-6,
        "XAI's Grok 2 beta model. Max 128K context."),
    "grok-4-0709" => ModelSpec("grok-4-0709",
        XAIOpenAISchema(),
        3e-6,
        15e-6,
        "XAI's Grok 4 model with 256K context window, vision, function calling, and reasoning capabilities."),
    "grok-4-fast-reasoning" => ModelSpec("grok-4-fast-reasoning",
        XAIOpenAISchema(),
        2e-7,
        5e-7,
        "XAI's Grok 4 Fast Reasoning model featuring a 2M token context window with optimized reasoning performance."),
    "grok-4-fast-non-reasoning" => ModelSpec("grok-4-fast-non-reasoning",
        XAIOpenAISchema(),
        2e-7,
        5e-7,
        "XAI's Grok 4 Fast Non-Reasoning model with a 2M token context window optimized for general-purpose generation."),
    "grok-code-fast-1" => ModelSpec("grok-code-fast-1",
        XAIOpenAISchema(),
        2e-7,
        1.5e-6,
        "XAI's Grok Code Fast 1 is a speedy and economical reasoning model that excels at agentic coding. 256K context window with visible reasoning traces. Supports function calling and structured outputs."),
    ## Gemini 1.5 Models
    "gemini-1.5-pro-latest" => ModelSpec("gemini-1.5-pro-latest",
        GoogleOpenAISchema(),
        1.25e-6,
        5e-6,
        "Gemini 1.5 Pro is Google's latest large language model with enhanced capabilities across reasoning, math, coding, and multilingual tasks. 128K context window."),
    "gemini-1.5-flash-8b-latest" => ModelSpec("gemini-1.5-flash-8b-latest",
        GoogleOpenAISchema(),
        3.75e-8,
        1.5e-7,
        "Gemini 1.5 Flash 8B is a smaller, faster version of Gemini 1.5 optimized for quick responses while maintaining good performance. 128K context window."),
    "gemini-1.5-flash-latest" => ModelSpec("gemini-1.5-flash-latest",
        GoogleOpenAISchema(),
        7.5e-8,
        3.0e-7,
        "Gemini 1.5 Flash is a high-performance model optimized for speed while maintaining strong capabilities across various tasks. 128K context window."),
    "gemini-2.0-flash-exp" => ModelSpec("gemini-2.0-flash-exp",
        GoogleOpenAISchema(),
        7.5e-8,
        3.0e-7,
        "Gemini 2.0 Flash Experimental Model from December 2024. Context 1M tokens, 8K output. See details [here](https://ai.google.dev/gemini-api/docs/models/experimental-models#use-an-experimental-model)."),
    "gemini-2.0-flash" => ModelSpec("gemini-2.0-flash",
        GoogleOpenAISchema(),
        1.0e-7,
        4.0e-7,
        "Gemini 2.0 Flash Latest Model. Context 1M tokens, 8K output. See details [here](https://ai.google.dev/gemini-api/docs/models/experimental-models#use-an-experimental-model)."),
    "gemini-2.0-flash-lite-preview-02-05" => ModelSpec(
        "gemini-2.0-flash-lite-preview-02-05",
        GoogleOpenAISchema(),
        7.5e-8,
        3.0e-7,
        "Gemini 2.0 Flash Lite Preview from February 2025. Context 1M tokens, 8K output. See details [here](https://ai.google.dev/gemini-api/docs/models/experimental-models#use-an-experimental-model)."),
    "gemini-2.0-flash-thinking-exp-01-21" => ModelSpec(
        "gemini-2.0-flash-thinking-exp-01-21",
        GoogleOpenAISchema(),
        1.0e-7,
        4.0e-7,
        "Gemini 2.0 Flash Thinking Experimental Model from January 2025. Context 1M tokens, 8K output. See details [here](https://ai.google.dev/gemini-api/docs/models/experimental-models#use-an-experimental-model)."),
    "gemini-2.5-flash-preview-04-17" => ModelSpec("gemini-2.5-flash-preview-04-17",
        GoogleOpenAISchema(),
        1.5e-7,
        3.5e-6,
        "Gemini 2.5 Flash Preview from April 2025. 1M context, 65K output. Price differs if you request thinking or not. See details [here](https://ai.google.dev/gemini-api/docs/models/experimental-models#use-an-experimental-model)."),
    "gemini-2.5-flash-preview-05-20" => ModelSpec("gemini-2.5-flash-preview-05-20",
        GoogleOpenAISchema(),
        1.5e-7,
        3.5e-6,
        "Gemini 2.5 Flash Preview from May 2025. 1M context, 65K output. Price differs if you request thinking or not. See details [here](https://ai.google.dev/gemini-api/docs/models/experimental-models#use-an-experimental-model)."),
    "gemini-2.5-flash-lite" => ModelSpec("gemini-2.5-flash-lite",
        GoogleOpenAISchema(),
        1e-7,
        4e-7,
        "Gemini 2.5 Flash Lite. 1M context, 65K output. Price differs if you request thinking or not. See details [here](https://ai.google.dev/gemini-api/docs/models/experimental-models#use-an-experimental-model)."),
    "gemini-2.5-flash" => ModelSpec("gemini-2.5-flash",
        GoogleOpenAISchema(),
        3e-7,
        2.5e-6,
        "Gemini 2.5 Flash Latest Model. Context 1M tokens, 8K output. See details [here](https://ai.google.dev/gemini-api/docs/models/experimental-models#use-an-experimental-model)."),
    "gemini-flash-latest" => ModelSpec("gemini-flash-latest",
        GoogleOpenAISchema(),
        3e-7,
        2.5e-6,
        "Gemini 2.5 Flash Latest Model. Context 1M tokens, 64K output. See details [here](https://ai.google.dev/gemini-api/docs/models/experimental-models#use-an-experimental-model)."),
    "gemini-2.5-flash-preview-09-2025" => ModelSpec("gemini-2.5-flash-preview-09-2025",
        GoogleOpenAISchema(),
        3e-7,
        2.5e-6,
        "Gemini 2.5 Flash Preview from September 2025. 1M context, 65K output. See details [here](https://ai.google.dev/gemini-api/docs/models/experimental-models#use-an-experimental-model)."),
    "gemini-2.5-flash-lite-preview-09-2025" => ModelSpec(
        "gemini-2.5-flash-lite-preview-09-2025",
        GoogleOpenAISchema(),
        1e-7,
        4e-7,
        "Gemini 2.5 Flash Lite Preview from September 2025. 1M context, 65K output. See details [here](https://ai.google.dev/gemini-api/docs/models/experimental-models#use-an-experimental-model)."),
    "gemini-flash-lite-latest" => ModelSpec("gemini-flash-lite-latest",
        GoogleOpenAISchema(),
        1e-7,
        4e-7,
        "Gemini Flash Lite Latest Model. Context 1M tokens, 65K output. Always points to the latest available version. See details [here](https://ai.google.dev/gemini-api/docs/models/experimental-models#use-an-experimental-model)."),
    "gemini-2.5-flash-image-preview" => ModelSpec("gemini-2.5-flash-image-preview",
        GoogleSchema(),
        3e-7,
        2.5e-6,
        "Gemini 2.5 Flash Image Preview - conversational image generation and editing model. Context 32K tokens, 32K output. Supports both image input and image generation. See details [here](https://ai.google.dev/gemini-api/docs/models/gemini#gemini-2.5-flash-image-preview)."),
    "gemini-exp-1114" => ModelSpec("gemini-exp-1114",
        GoogleOpenAISchema(),
        1.25e-6,
        5e-6,
        "Gemini Experimental Model from November 2024. Pricing assumed as per Gemini 1.5 Pro. See details [here](https://ai.google.dev/gemini-api/docs/models/experimental-models#use-an-experimental-model)."),
    "gemini-exp-1121" => ModelSpec("gemini-exp-1121",
        GoogleOpenAISchema(),
        1.25e-6,
        5e-6,
        "Gemini Experimental Model from November 2024. Pricing assumed as per Gemini 1.5 Pro. See details [here](https://ai.google.dev/gemini-api/docs/models/experimental-models#use-an-experimental-model)."),
    "gemini-exp-1206" => ModelSpec("gemini-exp-1206",
        GoogleOpenAISchema(),
        1.25e-6,
        5e-6,
        "Gemini Experimental Model from December 2024. Pricing assumed as per Gemini 1.5 Pro. See details [here](https://ai.google.dev/gemini-api/docs/models/experimental-models#use-an-experimental-model)."),
    "gemini-2.0-pro-exp-02-05" => ModelSpec("gemini-2.0-pro-exp-02-05",
        GoogleOpenAISchema(),
        1.25e-6,
        5e-6,
        "Gemini 2.0 Pro Experimental Model from February 2025. Pricing assumed as per Gemini 1.5 Pro. See details [here](https://ai.google.dev/gemini-api/docs/models/experimental-models#use-an-experimental-model)."),
    "gemini-2.5-pro-preview-05-06" => ModelSpec("gemini-2.5-pro-preview-05-06",
        GoogleOpenAISchema(),
        1.25e-6,
        10e-6,
        "Gemini 2.5 Pro Preview from May 2025. 1M context, 65K output. See details [here](https://ai.google.dev/gemini-api/docs/models/experimental-models#use-an-experimental-model)."),
    "gemini-3-pro-preview" => ModelSpec("gemini-3-pro-preview",
        GoogleOpenAISchema(),
        2e-6,
        12e-6,
        "Gemini 3 Pro Preview is Google's most advanced AI model launched November 2025. 1M context, 64K output. Price is for contexts ≤200K tokens."),
    "kimi-k2-0711-preview" => ModelSpec("kimi-k2-0711-preview",
        MoonshotOpenAISchema(),
        0.6e-6,
        2.5e-6,
        "Moonshot's Kimi K2 model with advanced reasoning capabilities and long context support (131K tokens).")
)

"""
    ALTERNATIVE_GENERATION_COSTS

Tracker of alternative costing models, eg, for image generation (`dall-e-3`), the cost is driven by quality/size.
"""
ALTERNATIVE_GENERATION_COSTS = Dict{String, Any}(
    "dall-e-3" => Dict(
        "standard" => Dict(
            "1024x1024" => 0.04, "1024x1792" => 0.08, "1792x1024" => 0.08),
        "hd" => Dict(
            "1024x1024" => 0.08, "1024x1792" => 0.12, "1792x1024" => 0.12)),
    "dall-e-2" => Dict(
        "standard" => Dict(
            "1024x1024" => 0.02, "512x512" => 0.018, "256x256" => 0.016),
        "hd" => Dict("1024x1024" => 0.02, "512x512" => 0.018, "256x256" => 0.016))
)

### Model Registry Structure
@kwdef mutable struct ModelRegistry
    registry::Dict{String, ModelSpec}
    aliases::Dict{String, String}
end
function Base.show(io::IO, registry::ModelRegistry)
    num_models = length(registry.registry)
    num_aliases = length(registry.aliases)
    print(io,
        "ModelRegistry with $num_models models and $num_aliases aliases. See `?MODEL_REGISTRY` for more information.")
end

"""
    model_docs(m::ModelRegistry)
Generate a documentation string list of models and their aliases
"""
function model_docs(m::ModelRegistry)
    by_schema = Dict{Symbol, Vector{String}}()
    foreach(m.registry) do (name, spec)
        schema = nameof(typeof(spec.schema))
        push!(get!(() -> Vector{String}(), by_schema, schema), name)
    end

    by_model = Dict{String, Vector{String}}()
    foreach(m.aliases) do (name, model)
        push!(get!(() -> Vector{String}(), by_model, model), name)
    end

    join(
        (
            """
            ## $(string(schema))
            - $(join(( "`$s`$(haskey(by_model, s) ? " - aliases: " : "")$(join(( "`$a`" for a in get(by_model,s, [])), ", ", " and "))" for s in by_schema[schema]), "\n- "))
            """
        for schema in sort(collect(keys(by_schema)), by = string)), "\n"
    )
end

@doc (
    """
    MODEL_REGISTRY

    A store of available model names and their specs (ie, name, costs per token, etc.)

    # Accessing the registry

    You can use both the alias name or the full name to access the model spec:
    ```
    PromptingTools.MODEL_REGISTRY["gpt-3.5-turbo"]
    ```

    # Registering a new model
    ```julia
    register_model!(
        name = "gpt-3.5-turbo",
        schema = :OpenAISchema,
        cost_of_token_prompt = 0.0015,
        cost_of_token_generation = 0.002,
        description = "GPT-3.5 Turbo is a 175B parameter model and a common default on the OpenAI API.")
    ```

    # Registering a model alias
    ```julia
    PromptingTools.MODEL_ALIASES["gpt3"] = "gpt-3.5-turbo"
    ```
    # Extended help
    """*model_docs(MODEL_REGISTRY)
)
const MODEL_REGISTRY = ModelRegistry(registry, aliases)

"""
    keys(m::ModelRegistry)
Returns all the model names and aliases that are available from the registry.
"""
Base.keys(m::ModelRegistry) = Set((keys(m.registry)..., keys(m.aliases)...))

# We overload the getindex function to allow for lookup via model aliases
function Base.getindex(registry::ModelRegistry, key::String)
    # Check if the key exists in the registry
    if haskey(registry.registry, key)
        return registry.registry[key]
    end

    # If the key is not in the registry, check if it's an alias
    aliased_key = get(registry.aliases, key, nothing)
    if !isnothing(aliased_key) && haskey(registry.registry, aliased_key)
        return registry.registry[aliased_key]
    end

    # Handle the case where the key is neither in the registry nor an alias
    throw(KeyError("Model with key '$key' not found in PromptingTools.MODEL_REGISTRY."))
end
function Base.setindex!(registry::ModelRegistry, value::ModelSpec, key::String)
    registry.registry[key] = value
end
function Base.haskey(registry::ModelRegistry, key::String)
    haskey(registry.registry, key) || haskey(registry.aliases, key)
end
function Base.get(registry::ModelRegistry, key::String, default)
    if haskey(registry, key)
        return registry[key]
    else
        return default
    end
end
function Base.delete!(registry::ModelRegistry, key::String)
    haskey(registry.registry, key) && delete!(registry.registry, key)
    haskey(registry.aliases, key) && delete!(registry.aliases, key)
    return registry
end

"Shows the list of models in the registry. Add more with `register_model!`."
list_registry() = sort(collect(keys(MODEL_REGISTRY.registry)))
"Shows the Dictionary of model aliases in the registry. Add more with `MODEL_ALIASES[alias] = model_name`."
list_aliases() = MODEL_REGISTRY.aliases

"""
    MODEL_ALIASES

A dictionary of model aliases. Aliases are used to refer to models by their aliases instead of their full names to make it more convenient to use them.

# Accessing the aliases
```
PromptingTools.MODEL_ALIASES["gpt3"]
```

# Register a new model alias
```julia
PromptingTools.MODEL_ALIASES["gpt3"] = "gpt-3.5-turbo"
```
"""
const MODEL_ALIASES = MODEL_REGISTRY.aliases
