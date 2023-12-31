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
- `MODEL_CHAT`: The default model to use for aigenerate and most ai* calls. See `MODEL_REGISTRY` for a list of available models or define your own.
- `MODEL_EMBEDDING`: The default model to use for aiembed (embedding documents). See `MODEL_REGISTRY` for a list of available models or define your own.
- `PROMPT_SCHEMA`: The default prompt schema to use for aigenerate and most ai* calls (if not specified in `MODEL_REGISTRY`). Set as a string, eg, `"OpenAISchema"`.
    See `PROMPT_SCHEMA` for more information.
- `MODEL_ALIASES`: A dictionary of model aliases (`alias => full_model_name`). Aliases are used to refer to models by their aliases instead of their full names to make it more convenient to use them.
    See `MODEL_ALIASES` for more information.
- `MAX_HISTORY_LENGTH`: The maximum length of the conversation history. Defaults to 5. Set to `nothing` to disable history.
    See `CONV_HISTORY` for more information.

At the moment it is not possible to persist changes to `MODEL_REGISTRY` across sessions. 
Define your `register_model!()` calls in your `startup.jl` file to make them available across sessions or put them at the top of your script.

# Available ENV Variables
- `OPENAI_API_KEY`: The API key for the OpenAI API. 
- `MISTRALAI_API_KEY`: The API key for the Mistral AI API.

Preferences.jl takes priority over ENV variables, so if you set a preference, it will override the ENV variable.

WARNING: NEVER EVER sync your `LocalPreferences.toml` file! It contains your API key and other sensitive information!!!
"""
const PREFERENCES = nothing

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
    allowed_preferences = [
        "MISTRALAI_API_KEY",
        "OPENAI_API_KEY",
        "MODEL_CHAT",
        "MODEL_EMBEDDING",
        "MODEL_ALIASES",
        "PROMPT_SCHEMA",
        "MAX_HISTORY_LENGTH",
    ]
    for (key, value) in pairs
        @assert key in allowed_preferences "Unknown preference '$key'! (Allowed preferences: $(join(allowed_preferences,", "))"
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
    allowed_preferences = [
        "MISTRALAI_API_KEY",
        "OPENAI_API_KEY",
        "MODEL_CHAT",
        "MODEL_EMBEDDING",
        "MODEL_ALIASES",
        "PROMPT_SCHEMA",
    ]
    @assert key in allowed_preferences "Unknown preference '$key'! (Allowed preferences: $(join(allowed_preferences,", "))"
    getproperty(@__MODULE__, Symbol(key))
end

## Load up GLOBALS
const MODEL_CHAT::String = @load_preference("MODEL_CHAT", default="gpt-3.5-turbo")
const MODEL_EMBEDDING::String = @load_preference("MODEL_EMBEDDING",
    default="text-embedding-ada-002")
# the prompt schema default is defined in llm_interace.jl !
# const PROMPT_SCHEMA = OpenAISchema()

# First, load from preferences, then from environment variables
const OPENAI_API_KEY::String = @load_preference("OPENAI_API_KEY",
    default=get(ENV, "OPENAI_API_KEY", ""));
# Note: Disable this warning by setting OPENAI_API_KEY to anything
isempty(OPENAI_API_KEY) &&
    @warn "OPENAI_API_KEY variable not set! OpenAI models will not be available - set API key directly via `PromptingTools.OPENAI_API_KEY=<api-key>`!"

const MISTRALAI_API_KEY::String = @load_preference("MISTRALAI_API_KEY",
    default=get(ENV, "MISTRALAI_API_KEY", ""));

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
        "gpt4t" => "gpt-4-1106-preview", # 4t is for "4 turbo"
        "gpt3t" => "gpt-3.5-turbo-1106", # 3t is for "3 turbo"
        "ada" => "text-embedding-ada-002",
        "yi34c" => "yi:34b-chat",
        "oh25" => "openhermes2.5-mistral",
        "starling" => "starling-lm"),
    ## Load aliases from preferences as well
    @load_preference("MODEL_ALIASES", default=Dict{String, String}()))

registry = Dict{String, ModelSpec}("gpt-3.5-turbo" => ModelSpec("gpt-3.5-turbo",
        OpenAISchema(),
        1.5e-6,
        2e-6,
        "GPT-3.5 Turbo is a 175B parameter model and a common default on the OpenAI API."),
    "gpt-3.5-turbo-1106" => ModelSpec("gpt-3.5-turbo-1106",
        OpenAISchema(),
        1e-6,
        2e-6,
        "GPT-3.5 Turbo is the latest version of GPT3.5 and the cheapest to use."),
    "gpt-4" => ModelSpec("gpt-4",
        OpenAISchema(),
        3e-5,
        6e-5,
        "GPT-4 is a 1.75T parameter model and the largest model available on the OpenAI API."),
    "gpt-4-1106-preview" => ModelSpec("gpt-4-1106-preview",
        OpenAISchema(),
        1e-5,
        3e-5,
        "GPT-4 Turbo is the latest version of GPT4 that is much faster and the cheapest to use."),
    "gpt-4-vision-preview" => ModelSpec("gpt-4-vision-preview",
        OpenAISchema(),
        1e-5,
        3e-5,
        "GPT-4 Vision is similar to GPT-4 but it adds visual capabilities."),
    "text-embedding-ada-002" => ModelSpec("text-embedding-ada-002",
        OpenAISchema(),
        1e-7,
        0.0,
        "Text Embedding Ada is a 1.75T parameter model and the largest model available on the OpenAI API."),
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
    "mistral-tiny" => ModelSpec("mistral-tiny",
        MistralOpenAISchema(),
        1.4e-7,
        4.53e-7,
        "Mistral AI's hosted version of Mistral-7B-v0.2. Great for simple tasks."),
    "mistral-small" => ModelSpec("mistral-small",
        MistralOpenAISchema(),
        6.47e-7,
        1.94e-6,
        "Mistral AI's hosted version of Mixtral-8x7B-v0.1. Good for more complicated tasks."),
    "mistral-medium" => ModelSpec("mistral-medium",
        MistralOpenAISchema(),
        2.7e-6,
        8.09e-6,
        "Mistral AI's hosted version of their best model available. Details unknown."),
    "mistral-embed" => ModelSpec("mistral-embed",
        MistralOpenAISchema(),
        1.08e-7,
        0.0,
        "Mistral AI's hosted model for embeddings."),
    "echo" => ModelSpec("echo",
        TestEchoOpenAISchema(;
            response = Dict(:choices => [Dict(:message => Dict(:content => "Hello!"))],
                :usage => Dict(:total_tokens => 3,
                    :prompt_tokens => 2,
                    :completion_tokens => 1)), status = 200),
        0.0,
        0.0,
        "Echo is only for testing. It always responds with 'Hello!'"))

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
