# Defines the important Globals, model registry and user preferences
# See below (eg, MODEL_REGISTRY, ModelSpec)

"""
    PREFERENCES

You can set preferences for PromptingTools by setting environment variables (for `OPENAI_API_KEY` only) 
    or by using the `set_preferences!`.
    It will create a `LocalPreferences.toml` file in your current directory and will reload your prefences from there.

Check your preferences by calling `get_preferences(key::String)`.
    
# Available Preferences (for `set_preferences!`)
- `OPENAI_API_KEY`: The API key for the OpenAI API. See [OpenAI's documentation](https://platform.openai.com/docs/quickstart?context=python) for more information.
- `MISTRALAI_API_KEY`: The API key for the Mistral AI API. See [Mistral AI's documentation](https://docs.mistral.ai/) for more information.
- `COHERE_API_KEY`: The API key for the Cohere API. See [Cohere's documentation](https://docs.cohere.com/docs/the-cohere-platform) for more information.
- `DATABRICKS_API_KEY`: The API key for the Databricks Foundation Model API. See [Databricks' documentation](https://docs.databricks.com/en/machine-learning/foundation-models/api-reference.html) for more information.
- `DATABRICKS_HOST`: The host for the Databricks API. See [Databricks' documentation](https://docs.databricks.com/en/machine-learning/foundation-models/api-reference.html) for more information.
- `TAVILY_API_KEY`: The API key for the Tavily Search API. Register [here](https://tavily.com/). See more information [here](https://docs.tavily.com/docs/tavily-api/rest_api).
- `GOOGLE_API_KEY`: The API key for Google Gemini models. Get yours from [here](https://ai.google.dev/). If you see a documentation page ("Available languages and regions for Google AI Studio and Gemini API"), it means that it's not yet available in your region.
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

At the moment it is not possible to persist changes to `MODEL_REGISTRY` across sessions. 
Define your `register_model!()` calls in your `startup.jl` file to make them available across sessions or put them at the top of your script.

# Available ENV Variables
- `OPENAI_API_KEY`: The API key for the OpenAI API. 
- `MISTRALAI_API_KEY`: The API key for the Mistral AI API.
- `COHERE_API_KEY`: The API key for the Cohere API.
- `LOCAL_SERVER`: The URL of the local server to use for `ai*` calls. Defaults to `http://localhost:10897/v1`. This server is called when you call `model="local"`
- `DATABRICKS_API_KEY`: The API key for the Databricks Foundation Model API.
- `DATABRICKS_HOST`: The host for the Databricks API.
- `TAVILY_API_KEY`: The API key for the Tavily Search API. Register [here](https://tavily.com/). See more information [here](https://docs.tavily.com/docs/tavily-api/rest_api).
- `GOOGLE_API_KEY`: The API key for Google Gemini models. Get yours from [here](https://ai.google.dev/). If you see a documentation page ("Available languages and regions for Google AI Studio and Gemini API"), it means that it's not yet available in your region.

Preferences.jl takes priority over ENV variables, so if you set a preference, it will take precedence over the ENV variable.

WARNING: NEVER EVER sync your `LocalPreferences.toml` file! It contains your API key and other sensitive information!!!
"""
const PREFERENCES = nothing

"Keys that are allowed to be set via `set_preferences!`"
const ALLOWED_PREFERENCES = ["MISTRALAI_API_KEY",
    "OPENAI_API_KEY",
    "COHERE_API_KEY",
    "DATABRICKS_API_KEY",
    "DATABRICKS_HOST",
    "TAVILY_API_KEY",
    "GOOGLE_API_KEY",
    "MODEL_CHAT",
    "MODEL_EMBEDDING",
    "MODEL_ALIASES",
    "PROMPT_SCHEMA",
    "MAX_HISTORY_LENGTH",
    "LOCAL_SERVER"]

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
const MODEL_CHAT::String = @load_preference("MODEL_CHAT", default="gpt-3.5-turbo")
const MODEL_EMBEDDING::String = @load_preference("MODEL_EMBEDDING",
    default="text-embedding-3-small")
# the prompt schema default is defined in llm_interace.jl !
# const PROMPT_SCHEMA = OpenAISchema()

# First, load from preferences, then from environment variables
# Note: We load first into a variable `temp_` to avoid inlining of the get(ENV...) call
_temp = get(ENV, "OPENAI_API_KEY", "")
const OPENAI_API_KEY::String = @load_preference("OPENAI_API_KEY",
    default=_temp);
# Note: Disable this warning by setting OPENAI_API_KEY to anything
isempty(OPENAI_API_KEY) &&
    @warn "OPENAI_API_KEY variable not set! OpenAI models will not be available - set API key directly via `PromptingTools.OPENAI_API_KEY=<api-key>`!"

_temp = get(ENV, "MISTRALAI_API_KEY", "")
const MISTRALAI_API_KEY::String = @load_preference("MISTRALAI_API_KEY",
    default=_temp);

_temp = get(ENV, "COHERE_API_KEY", "")
const COHERE_API_KEY::String = @load_preference("COHERE_API_KEY",
    default=_temp);

_temp = get(ENV, "DATABRICKS_API_KEY", "")
const DATABRICKS_API_KEY::String = @load_preference("DATABRICKS_API_KEY",
    default=_temp);

_temp = get(ENV, "DATABRICKS_HOST", "")
const DATABRICKS_HOST::String = @load_preference("DATABRICKS_HOST",
    default=_temp);

_temp = get(ENV, "TAVILY_API_KEY", "")
const TAVILY_API_KEY::String = @load_preference("TAVILY_API_KEY",
    default=_temp);

_temp = get(ENV, "GOOGLE_API_KEY", "")
const GOOGLE_API_KEY::String = @load_preference("GOOGLE_API_KEY",
    default=_temp);

_temp = get(ENV, "TOGETHER_API_KEY", "")
const TOGETHER_API_KEY::String = @load_preference("TOGETHER_API_KEY",
    default=_temp);

_temp = get(ENV, "FIREWORKS_API_KEY", "")
const FIREWORKS_API_KEY::String = @load_preference("FIREWORKS_API_KEY",
    default=_temp);

_temp = get(ENV, "LOCAL_SERVER", "")
## Address of the local server
const LOCAL_SERVER::String = @load_preference("LOCAL_SERVER",
    default=_temp);

## CONVERSATION HISTORY
"""
    CONV_HISTORY

Tracks the most recent conversations through the `ai_str macros`.

Preference available: MAX_HISTORY_LENGTH, which sets how many last messages should be remembered.

See also: `push_conversation!`, `resize_conversation!`

"""
const CONV_HISTORY = Vector{Vector{<:Any}}()
const CONV_HISTORY_LOCK = ReentrantLock()
const MAX_HISTORY_LENGTH = @load_preference("MAX_HISTORY_LENGTH",
    default=5)::Union{Int, Nothing}

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
aliases = merge(Dict("gpt3" => "gpt-3.5-turbo",
        "gpt4" => "gpt-4",
        "gpt4v" => "gpt-4-vision-preview", # 4v is for "4 vision"
        "gpt4t" => "gpt-4-turbo-preview", # 4t is for "4 turbo"
        "gpt3t" => "gpt-3.5-turbo-0125", # 3t is for "3 turbo"
        "ada" => "text-embedding-ada-002",
        "emb3small" => "text-embedding-3-small",
        "emb3large" => "text-embedding-3-large",
        "yi34c" => "yi:34b-chat",
        "oh25" => "openhermes2.5-mistral",
        "starling" => "starling-lm",
        "local" => "local-server",
        "gemini" => "gemini-pro",
        ## f-mixtral -> Fireworks.ai Mixtral
        "fmixtral" => "accounts/fireworks/models/mixtral-8x7b-instruct",
        "firefunction" => "accounts/fireworks/models/firefunction-v1",
        ## t-mixtral -> Together.ai Mixtral
        "tmixtral" => "mistralai/Mixtral-8x7B-Instruct-v0.1",
        ## Mistral AI
        "mistral-small" => "mistral-small-latest",
        "mistral-medium" => "mistral-medium-latest",
        "mistral-large" => "mistral-large-latest",
        "mistrals" => "mistral-small-latest",
        "mistralm" => "mistral-medium-latest",
        "mistrall" => "mistral-large-latest"),
    ## Load aliases from preferences as well
    @load_preference("MODEL_ALIASES", default=Dict{String, String}()))

registry = Dict{String, ModelSpec}("gpt-3.5-turbo" => ModelSpec("gpt-3.5-turbo",
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
        "GPT-4 Turbo is an updated version of GPT4 that is much faster and the cheaper to use. 0125 refers to the release date of January 25, 2024."),
    "gpt-4-turbo-preview" => ModelSpec("gpt-4-turbo-preview",
        OpenAISchema(),
        1e-5,
        3e-5,
        "GPT-4 Turbo is an updated version of GPT4 that is much faster and the cheaper to use. This is the general name for whatever is the latest GPT4 Turbo preview release. Right now it is 0125."),
    "gpt-4-vision-preview" => ModelSpec("gpt-4-vision-preview",
        OpenAISchema(),
        1e-5,
        3e-5,
        "GPT-4 Vision is similar to GPT-4 but it adds visual capabilities."),
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
    "mistral-small-latest" => ModelSpec("mistral-small-latest",
        MistralOpenAISchema(),
        2e-6,
        6e-6,
        "Mistral AI's own finetune (historically similar to Mixtral-8x7B)."),
    "mistral-medium-latest" => ModelSpec("mistral-medium-latest",
        MistralOpenAISchema(),
        2.7e-6,
        8.1e-6,
        "Mistral AI's own model. Details unknown."),
    "mistral-large-latest" => ModelSpec("mistral-large-latest",
        MistralOpenAISchema(),
        8e-6,
        2.4e-5,
        "Mistral AI's hosted version of their best model available. Details unknown."),
    "mistral-embed" => ModelSpec("mistral-embed",
        MistralOpenAISchema(),
        1e-7,
        0.0,
        "Mistral AI's hosted model for embeddings."),
    "echo" => ModelSpec("echo",
        TestEchoOpenAISchema(;
            response = Dict(:choices => [
                    Dict(:message => Dict(:content => "Hello!"),
                        :finish_reason => "stop"),
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
        "Local server, eg, powered by [Llama.jl](https://github.com/marcom/Llama.jl). Model is specified when instantiating the server itself."),
    "gemini-pro" => ModelSpec("gemini-pro",
        GoogleSchema(),
        0.0, #unknown, expected 1.25e-7
        0.0, #unknown, expected 3.75e-7
        "Gemini Pro is a LLM from Google. For more information, see [models](https://ai.google.dev/models/gemini)."),
    "accounts/fireworks/models/mixtral-8x7b-instruct" => ModelSpec("accounts/fireworks/models/mixtral-8x7b-instruct",
        FireworksOpenAISchema(),
        4e-7, #unknown, expected 1.25e-7
        1.6e-6, #unknown, expected 3.75e-7
        "Mixtral (8x7b) from Mistral, hosted by Fireworks.ai. For more information, see [models](https://fireworks.ai/models/fireworks/mixtral-8x7b-instruct)."),
    "accounts/fireworks/models/firefunction-v1" => ModelSpec("accounts/fireworks/models/firefunction-v1",
        FireworksOpenAISchema(),
        0.0, #unknown, expected to be the same as Mixtral
        0.0, #unknown, expected to be the same as Mixtral
        "Fireworks' open-source function calling model (fine-tuned Mixtral). Useful for `aiextract` calls. For more information, see [models](https://fireworks.ai/models/fireworks/firefunction-v1)."),
    "mistralai/Mixtral-8x7B-Instruct-v0.1" => ModelSpec("mistralai/Mixtral-8x7B-Instruct-v0.1",
        TogetherOpenAISchema(),
        6e-7,
        6e-7,
        "Mixtral (8x7b) from Mistral, hosted by Together.ai. For more information, see [models](https://docs.together.ai/docs/inference-models)."))

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

"""
const MODEL_REGISTRY = ModelRegistry(registry, aliases)

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
