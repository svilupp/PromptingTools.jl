# Example of custom API integration, eg, custom enterprise proxy with special headers
#
# This should NOT be necessary unless you have a private LLM / private proxy with specialized API structure and headers.
# For most new APIs, you should check out the FAQ on "Using Custom API Providers like Azure or Databricks"
# DatabricksOpenAISchema is a good example how to do simple API integration.
#
# For heavily customized APIs, follow the example below. Again, do this only if you have no other choice!!

# We will need to provide a custom "provider" and custom methods for `OpenAI.jl` to override how it builds the AUTH headers and URL.

using PromptingTools
const PT = PromptingTools
using HTTP
using JSON3

## OpenAI.jl work
# Define a custom provider for OpenAI to override the default behavior
abstract type MyCustomProvider <: PT.AbstractCustomProvider end

@kwdef struct MyModelProvider <: MyCustomProvider
    api_key::String = ""
    base_url::String = "https://api.example.com/v1239123/modelxyz/completions_that_are_not_standard"
    api_version::String = ""
end

# Tell OpenAI not to use "api" (=endpoints)
function PT.OpenAI.build_url(provider::MyCustomProvider, api::AbstractString = "")
    string(provider.base_url)
end

function PT.OpenAI.auth_header(
        provider::MyCustomProvider, api_key::AbstractString = provider.api_key)
    ## Note this DOES NOT have any Basic Auth! Assumes you use something custom
    ["Content-Type" => "application/json", "Extra-custom-authorization" => api_key]
end

## PromptingTools.jl work
# Define a custom schema
struct MyCustomSchema <: PT.AbstractOpenAISchema end

# Implement create_chat for the custom schema
function PT.OpenAI.create_chat(schema::MyCustomSchema,
        api_key::AbstractString,
        model::AbstractString,
        conversation;
        url::String = "",
        ## Add any required kwargs here, APIs may have different requirements
        max_tokens::Int = 2048,
        kwargs...)
    ## Depending on your needs, you can get api_key from ENV variable!!
    ## Eg, api_key = get(ENV, "CUSTOM_API_KEY", "")
    provider = MyModelProvider(; api_key, base_url = url)

    ## The first arg will be ignored, doesn't matter what you put there
    PT.OpenAI.openai_request("ignore-me", provider;
        method = "POST",
        messages = conversation,
        streamcallback = nothing,
        max_tokens = max_tokens,
        model = model,
        kwargs...)
end

## Model registration
## Any alias you like (can be many)
PromptingTools.MODEL_ALIASES["myprecious"] = "custom-model-xyz"
## Register the exact model name to send to your API
PromptingTools.register_model!(;
    name = "custom-model-xyz",
    schema = MyCustomSchema())

## Example usage
api_key = "..." # use ENV to provide this automatically
url = "..."  # use ENV to provide this or hardcode in your create_chat function!!
msg = aigenerate("Hello, how are you?"; model = "myprecious", api_kwargs = (; api_key, url))

## Custom usage - no need to register anything
function myai(msg::AbstractString)
    model = "custom-model-xyz"
    schema = MyCustomSchema()
    api_key = "..." # use ENV to provide this automatically
    url = "..."  # use ENV to provide this or hardcode in your create_chat function!!
    aigenerate(schema, msg; model, api_kwargs = (; api_key, url))
end
msg = myai("Hello, how are you?")
