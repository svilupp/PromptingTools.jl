## OpenAI.jl back-end
#
# This file defines overloads for the OpenAI.jl package to allow for
# custom PromptSchemas routing to various OpenAI-compatible APIs
#
## Types
# "Providers" are a way to use other APIs that are compatible with OpenAI API specs, eg, Azure and mamy more
# Define our sub-type to distinguish it from other OpenAI.jl providers
abstract type AbstractCustomProvider <: OpenAI.AbstractOpenAIProvider end
Base.@kwdef struct CustomProvider <: AbstractCustomProvider
    api_key::String = ""
    base_url::String = "http://localhost:8080"
    api_version::String = ""
end
function OpenAI.build_url(provider::AbstractCustomProvider, api::AbstractString)
    string(provider.base_url, "/", api)
end
function OpenAI.auth_header(provider::AbstractCustomProvider, api_key::AbstractString)
    OpenAI.auth_header(
        OpenAI.OpenAIProvider(provider.api_key,
            provider.base_url,
            provider.api_version),
        api_key)
end
## Extend OpenAI create_chat to allow for testing/debugging
# Default passthrough
function OpenAI.create_chat(schema::AbstractOpenAISchema,
        api_key::AbstractString,
        model::AbstractString,
        conversation;
        http_kwargs::NamedTuple = NamedTuple(),
        streamcallback::Any = nothing,
        kwargs...)
    api_key = !isempty(api_key) ? api_key : OPENAI_API_KEY
    if !isnothing(streamcallback)
        ## Take over from OpenAI.jl
        url = OpenAI.build_url(OpenAI.DEFAULT_PROVIDER, "chat/completions")
        headers = OpenAI.auth_header(OpenAI.DEFAULT_PROVIDER, api_key)
        streamcallback, new_kwargs = configure_callback!(
            streamcallback, schema; kwargs...)
        input = OpenAI.build_params((; messages = conversation, model, new_kwargs...))
        ## Use the streaming callback
        resp = streamed_request!(streamcallback, url, headers, input; http_kwargs...)
        OpenAI.OpenAIResponse(resp.status, JSON3.read(resp.body))
    else
        ## Use OpenAI.jl default
        OpenAI.create_chat(api_key, model, conversation; http_kwargs, kwargs...)
    end
end

# Overload for testing/debugging
function OpenAI.create_chat(schema::TestEchoOpenAISchema, api_key::AbstractString,
        model::AbstractString,
        conversation; kwargs...)
    schema.model_id = model
    schema.inputs = conversation
    return schema
end

"""
    OpenAI.create_chat(schema::CustomOpenAISchema,
        api_key::AbstractString,
        model::AbstractString,
        conversation;
        http_kwargs::NamedTuple = NamedTuple(),
        streamcallback::Any = nothing,
        url::String = "http://localhost:8080",
        kwargs...)

Dispatch to the OpenAI.create_chat function, for any OpenAI-compatible API. 

It expects `url` keyword argument. Provide it to the `aigenerate` function via `api_kwargs=(; url="my-url")`

It will forward your query to the "chat/completions" endpoint of the base URL that you provided (=`url`).
"""
function OpenAI.create_chat(schema::CustomOpenAISchema,
        api_key::AbstractString,
        model::AbstractString,
        conversation;
        http_kwargs::NamedTuple = NamedTuple(),
        streamcallback::Any = nothing,
        url::String = "http://localhost:8080",
        kwargs...)
    # Build the corresponding provider object
    # Create chat will automatically pass our data to endpoint `/chat/completions`
    provider = CustomProvider(; api_key, base_url = url)
    if !isnothing(streamcallback)
        ## Take over from OpenAI.jl
        url = OpenAI.build_url(provider, "chat/completions")
        headers = OpenAI.auth_header(provider, api_key)
        streamcallback, new_kwargs = configure_callback!(
            streamcallback, schema; kwargs...)
        input = OpenAI.build_params((; messages = conversation, model, new_kwargs...))
        ## Use the streaming callback
        resp = streamed_request!(streamcallback, url, headers, input; http_kwargs...)
        OpenAI.OpenAIResponse(resp.status, JSON3.read(resp.body))
    else
        ## Use OpenAI.jl default
        OpenAI.create_chat(provider, model, conversation; http_kwargs, kwargs...)
    end
end

"""
    OpenAI.create_chat(schema::LocalServerOpenAISchema,
        api_key::AbstractString,
        model::AbstractString,
        conversation;
        url::String = "http://localhost:8080",
        kwargs...)

Dispatch to the OpenAI.create_chat function, but with the LocalServer API parameters, ie, defaults to `url` specified by the `LOCAL_SERVER` preference. See `?PREFERENCES`

"""
function OpenAI.create_chat(schema::LocalServerOpenAISchema,
        api_key::AbstractString,
        model::AbstractString,
        conversation;
        url::String = LOCAL_SERVER,
        kwargs...)
    OpenAI.create_chat(CustomOpenAISchema(), api_key, model, conversation; url, kwargs...)
end

"""
    OpenAI.create_chat(schema::MistralOpenAISchema,
  api_key::AbstractString,
  model::AbstractString,
  conversation;
  url::String="https://api.mistral.ai/v1",
  kwargs...)

Dispatch to the OpenAI.create_chat function, but with the MistralAI API parameters. 

It tries to access the `MISTRAL_API_KEY` ENV variable, but you can also provide it via the `api_key` keyword argument.
"""
function OpenAI.create_chat(schema::MistralOpenAISchema,
        api_key::AbstractString,
        model::AbstractString,
        conversation;
        url::String = "https://api.mistral.ai/v1",
        kwargs...)
    # try to override provided api_key because the default is OpenAI key
    api_key = !isempty(api_key) ? api_key : MISTRAL_API_KEY
    OpenAI.create_chat(CustomOpenAISchema(), api_key, model, conversation; url, kwargs...)
end
function OpenAI.create_chat(schema::FireworksOpenAISchema,
        api_key::AbstractString,
        model::AbstractString,
        conversation;
        url::String = "https://api.fireworks.ai/inference/v1",
        kwargs...)
    # try to override provided api_key because the default is OpenAI key
    api_key = !isempty(api_key) ? api_key : FIREWORKS_API_KEY
    OpenAI.create_chat(CustomOpenAISchema(), api_key, model, conversation; url, kwargs...)
end
function OpenAI.create_chat(schema::TogetherOpenAISchema,
        api_key::AbstractString,
        model::AbstractString,
        conversation;
        url::String = "https://api.together.xyz/v1",
        kwargs...)
    api_key = !isempty(api_key) ? api_key : TOGETHER_API_KEY
    OpenAI.create_chat(CustomOpenAISchema(), api_key, model, conversation; url, kwargs...)
end
function OpenAI.create_chat(schema::GroqOpenAISchema,
        api_key::AbstractString,
        model::AbstractString,
        conversation;
        url::String = "https://api.groq.com/openai/v1",
        kwargs...)
    api_key = !isempty(api_key) ? api_key : GROQ_API_KEY
    OpenAI.create_chat(CustomOpenAISchema(), api_key, model, conversation; url, kwargs...)
end
function OpenAI.create_chat(schema::DeepSeekOpenAISchema,
        api_key::AbstractString,
        model::AbstractString,
        conversation;
        url::String = "https://api.deepseek.com/v1",
        kwargs...)
    api_key = !isempty(api_key) ? api_key : DEEPSEEK_API_KEY
    OpenAI.create_chat(CustomOpenAISchema(), api_key, model, conversation; url, kwargs...)
end
function OpenAI.create_chat(schema::OpenRouterOpenAISchema,
        api_key::AbstractString,
        model::AbstractString,
        conversation;
        url::String = "https://openrouter.ai/api/v1",
        kwargs...)
    api_key = !isempty(api_key) ? api_key : OPENROUTER_API_KEY
    OpenAI.create_chat(CustomOpenAISchema(), api_key, model, conversation; url, kwargs...)
end
function OpenAI.create_chat(schema::CerebrasOpenAISchema,
        api_key::AbstractString,
        model::AbstractString,
        conversation;
        url::String = "https://api.cerebras.ai/v1",
        kwargs...)
    api_key = !isempty(api_key) ? api_key : CEREBRAS_API_KEY
    OpenAI.create_chat(CustomOpenAISchema(), api_key, model, conversation; url, kwargs...)
end
function OpenAI.create_chat(schema::SambaNovaOpenAISchema,
        api_key::AbstractString,
        model::AbstractString,
        conversation;
        url::String = "https://api.sambanova.ai/v1",
        kwargs...)
    api_key = !isempty(api_key) ? api_key : SAMBANOVA_API_KEY
    OpenAI.create_chat(CustomOpenAISchema(), api_key, model, conversation; url, kwargs...)
end
function OpenAI.create_chat(schema::XAIOpenAISchema,
        api_key::AbstractString,
        model::AbstractString,
        conversation;
        url::String = "https://api.x.ai/v1",
        kwargs...)
    api_key = !isempty(api_key) ? api_key : XAI_API_KEY
    OpenAI.create_chat(CustomOpenAISchema(), api_key, model, conversation; url, kwargs...)
end

function OpenAI.create_chat(schema::MoonshotOpenAISchema,
        api_key::AbstractString,
        model::AbstractString,
        conversation;
        url::String = "https://api.moonshot.ai/v1",
        kwargs...)
    api_key = !isempty(api_key) ? api_key : MOONSHOT_API_KEY
    OpenAI.create_chat(CustomOpenAISchema(), api_key, model, conversation; url, kwargs...)
end
function OpenAI.create_chat(schema::MiniMaxOpenAISchema,
        api_key::AbstractString,
        model::AbstractString,
        conversation;
        url::String = "https://api.minimaxi.chat/v1",
        kwargs...)
    api_key = !isempty(api_key) ? api_key : MINIMAX_API_KEY
    OpenAI.create_chat(CustomOpenAISchema(), api_key, model, conversation; url, kwargs...)
end

# Add GoogleProvider implementation
Base.@kwdef struct GoogleProvider <: AbstractCustomProvider
    api_key::String = ""
    base_url::String = "https://generativelanguage.googleapis.com/v1beta"
    api_version::String = ""
end

function OpenAI.auth_header(provider::GoogleProvider, api_key::AbstractString)
    OpenAI.auth_header(
        OpenAI.OpenAIProvider(provider.api_key, provider.base_url, provider.api_version),
        api_key)
end

function OpenAI.create_chat(schema::GoogleOpenAISchema,
        api_key::AbstractString,
        model::AbstractString,
        conversation;
        url::String = "https://generativelanguage.googleapis.com/v1beta",
        kwargs...)
    api_key = !isempty(api_key) ? api_key : GOOGLE_API_KEY
    # Use GoogleProvider instead of CustomProvider
    provider = GoogleProvider(; api_key, base_url = url)
    OpenAI.openai_request("chat/completions",
        provider;
        method = "POST",
        messages = conversation,
        model = model,
        kwargs...)
end
function OpenAI.create_chat(schema::DatabricksOpenAISchema,
        api_key::AbstractString,
        model::AbstractString,
        conversation;
        http_kwargs::NamedTuple = NamedTuple(),
        streamcallback::Any = nothing,
        url::String = "https://<workspace_host>.databricks.com",
        kwargs...)
    # Build the corresponding provider object
    provider = CustomProvider(;
        api_key = !isempty(api_key) ? api_key : DATABRICKS_API_KEY,
        base_url = isempty(DATABRICKS_HOST) ? url : DATABRICKS_HOST)
    if !isnothing(streamcallback)
        throw(ArgumentError("Streaming is not supported for Databricks models yet!"))
        ## Take over from OpenAI.jl
        # url = OpenAI.build_url(provider, "serving-endpoints/$model/invocations")
        # headers = OpenAI.auth_header(provider, api_key)
        # streamcallback, new_kwargs = configure_callback!(
        #     streamcallback, schema; kwargs...)
        # input = OpenAI.build_params((; messages = conversation, model, new_kwargs...))
        # ## Use the streaming callback
        # resp = streamed_request!(streamcallback, url, headers, input; http_kwargs...)
        # OpenAI.OpenAIResponse(resp.status, JSON3.read(resp.body))
    else
        # Override standard OpenAI request endpoint
        OpenAI.openai_request("serving-endpoints/$model/invocations",
            provider;
            method = "POST",
            model,
            messages = conversation,
            http_kwargs,
            kwargs...)
    end
end
function OpenAI.create_chat(schema::AzureOpenAISchema,
        api_key::AbstractString,
        model::AbstractString,
        conversation;
        api_version::String = "2023-03-15-preview",
        http_kwargs::NamedTuple = NamedTuple(),
        streamcallback::Any = nothing,
        url::String = "https://<resource-name>.openai.azure.com",
        kwargs...)

    # Build the corresponding provider object
    provider = OpenAI.AzureProvider(;
        api_key = !isempty(api_key) ? api_key : AZURE_OPENAI_API_KEY,
        base_url = (isempty(AZURE_OPENAI_HOST) ? url : AZURE_OPENAI_HOST) *
                   "/openai/deployments/$model",
        api_version = api_version
    )
    # Override standard OpenAI request endpoint
    OpenAI.openai_request(
        "chat/completions",
        provider;
        method = "POST",
        http_kwargs = http_kwargs,
        messages = conversation,
        query = Dict("api-version" => provider.api_version),
        streamcallback = streamcallback,
        kwargs...
    )
end

# Extend OpenAI create_embeddings to allow for testing
function OpenAI.create_embeddings(schema::AbstractOpenAISchema,
        api_key::AbstractString,
        docs,
        model::AbstractString;
        kwargs...)
    api_key = !isempty(api_key) ? api_key : OPENAI_API_KEY
    OpenAI.create_embeddings(api_key, docs, model; kwargs...)
end
function OpenAI.create_embeddings(schema::TestEchoOpenAISchema, api_key::AbstractString,
        docs,
        model::AbstractString; kwargs...)
    schema.model_id = model
    schema.inputs = docs
    return schema
end
function OpenAI.create_embeddings(schema::CustomOpenAISchema,
        api_key::AbstractString,
        docs,
        model::AbstractString;
        url::String = "http://localhost:8080",
        kwargs...)
    # Build the corresponding provider object
    # Create chat will automatically pass our data to endpoint `/embeddings`
    provider = CustomProvider(; api_key, base_url = url)
    OpenAI.create_embeddings(provider, docs, model; kwargs...)
end
# Set url and just forward to CustomOpenAISchema otherwise
# Note: Llama.cpp and hence Llama.jl DO NOT support the embeddings endpoint !! (they use `/embedding`)
function OpenAI.create_embeddings(schema::LocalServerOpenAISchema,
        api_key::AbstractString,
        docs,
        model::AbstractString;
        ## Strip the "v1" from the end of the url
        url::String = LOCAL_SERVER,
        kwargs...)
    OpenAI.create_embeddings(CustomOpenAISchema(),
        api_key,
        docs,
        model;
        url,
        kwargs...)
end
function OpenAI.create_embeddings(schema::MistralOpenAISchema,
        api_key::AbstractString,
        docs,
        model::AbstractString;
        url::String = "https://api.mistral.ai/v1",
        kwargs...)
    # Build the corresponding provider object
    # try to override provided api_key because the default is OpenAI key
    provider = CustomProvider(;
        api_key = !isempty(api_key) ? api_key : MISTRAL_API_KEY,
        base_url = url)
    OpenAI.create_embeddings(provider, docs, model; kwargs...)
end
function OpenAI.create_embeddings(schema::DatabricksOpenAISchema,
        api_key::AbstractString,
        docs,
        model::AbstractString;
        url::String = "https://<workspace_host>.databricks.com",
        kwargs...)
    # Build the corresponding provider object
    provider = CustomProvider(;
        api_key = !isempty(api_key) ? api_key : DATABRICKS_API_KEY,
        base_url = isempty(DATABRICKS_HOST) ? url : DATABRICKS_HOST)
    # Override standard OpenAI request endpoint
    OpenAI.openai_request("serving-endpoints/$model/invocations",
        provider;
        method = "POST",
        model,
        input = docs,
        kwargs...)
end
function OpenAI.create_embeddings(schema::TogetherOpenAISchema,
        api_key::AbstractString,
        docs,
        model::AbstractString;
        url::String = "https://api.together.xyz/v1",
        kwargs...)
    provider = CustomProvider(;
        api_key = !isempty(api_key) ? api_key : TOGETHER_API_KEY,
        base_url = url)
    OpenAI.create_embeddings(provider, docs, model; kwargs...)
end
function OpenAI.create_embeddings(schema::FireworksOpenAISchema,
        api_key::AbstractString,
        docs,
        model::AbstractString;
        url::String = "https://api.fireworks.ai/inference/v1",
        kwargs...)
    provider = CustomProvider(;
        api_key = !isempty(api_key) ? api_key : FIREWORKS_API_KEY,
        base_url = url)
    OpenAI.create_embeddings(provider, docs, model; kwargs...)
end
function OpenAI.create_embeddings(schema::XAIOpenAISchema,
        api_key::AbstractString,
        docs,
        model::AbstractString;
        url::String = "https://api.x.ai/v1",
        kwargs...)
    provider = CustomProvider(;
        api_key = !isempty(api_key) ? api_key : XAI_API_KEY,
        base_url = url)
    OpenAI.create_embeddings(provider, docs, model; kwargs...)
end
function OpenAI.create_embeddings(schema::GoogleOpenAISchema,
        api_key::AbstractString,
        docs,
        model::AbstractString;
        url::String = "https://generativelanguage.googleapis.com/v1beta",
        kwargs...)
    api_key = !isempty(api_key) ? api_key : GOOGLE_API_KEY
    provider = GoogleProvider(; api_key, base_url = url)
    OpenAI.openai_request("embeddings",
        provider;
        method = "POST",
        input = docs,
        model = model,
        kwargs...)
end
function OpenAI.create_embeddings(schema::AzureOpenAISchema,
        api_key::AbstractString,
        docs,
        model::AbstractString;
        api_version::String = "2023-03-15-preview",
        url::String = "https://<resource-name>.openai.azure.com",
        kwargs...)

    # Build the corresponding provider object
    provider = OpenAI.AzureProvider(;
        api_key = !isempty(api_key) ? api_key : AZURE_OPENAI_API_KEY,
        base_url = (isempty(AZURE_OPENAI_HOST) ? url : AZURE_OPENAI_HOST) *
                   "/openai/deployments/$model",
        api_version = api_version)
    # Override standard OpenAI request endpoint
    OpenAI.openai_request(
        "embeddings",
        provider;
        method = "POST",
        input = docs,
        query = Dict("api-version" => provider.api_version),
        kwargs...
    )
end

## Temporary fix -- it will be moved upstream
function OpenAI.create_embeddings(provider::AbstractCustomProvider,
        input,
        model_id::String = OpenAI.DEFAULT_EMBEDDING_MODEL_ID;
        http_kwargs::NamedTuple = NamedTuple(),
        kwargs...)
    return OpenAI.openai_request("embeddings",
        provider;
        method = "POST",
        http_kwargs = http_kwargs,
        model = model_id,
        input,
        kwargs...)
end

## Wrap create_images for testing and routing
## Note: Careful, API is non-standard compared to other OAI functions
function OpenAI.create_images(schema::AbstractOpenAISchema,
        api_key::AbstractString,
        prompt,
        args...;
        kwargs...)
    api_key = !isempty(api_key) ? api_key : OPENAI_API_KEY
    OpenAI.create_images(api_key, prompt, args...; kwargs...)
end
function OpenAI.create_images(schema::TestEchoOpenAISchema,
        api_key::AbstractString,
        prompt,
        args...;
        kwargs...)
    schema.model_id = get(kwargs, :model, "")
    schema.inputs = prompt
    return schema
end
