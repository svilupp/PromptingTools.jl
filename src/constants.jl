# Constants used throughout the package

# Model Registry
const MODEL_REGISTRY = Dict{String,Any}()

# Default Models
const MODEL_CHAT = "gpt-3.5-turbo"
const MODEL_COMPLETION = "gpt-3.5-turbo-instruct"

# Reserved keywords that cannot be used as placeholders in templates
const RESERVED_KWARGS = Symbol[
    :model, :api_key, :verbose, :return_all, :dry_run, :conversation,
    :streamcallback, :no_system_message, :name_user, :name_assistant,
    :http_kwargs, :api_kwargs
]

# Default system message
const DEFAULT_SYSTEM_MESSAGE = "You are a helpful AI assistant."

# Default API Keys
const OPENAI_API_KEY = get(ENV, "OPENAI_API_KEY", "")
const ANTHROPIC_API_KEY = get(ENV, "ANTHROPIC_API_KEY", "")
const GOOGLE_API_KEY = get(ENV, "GOOGLE_API_KEY", "")
