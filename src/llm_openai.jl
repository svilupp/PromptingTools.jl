## Rendering of converation history for the OpenAI API
"""
    render(schema::AbstractOpenAISchema,
        messages::Vector{<:AbstractMessage};
        image_detail::AbstractString = "auto",
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        kwargs...)

Builds a history of the conversation to provide the prompt to the API. All unspecified kwargs are passed as replacements such that `{{key}}=>value` in the template.

# Keyword Arguments
- `image_detail`: Only for `UserMessageWithImages`. It represents the level of detail to include for images. Can be `"auto"`, `"high"`, or `"low"`.
- `conversation`: An optional vector of `AbstractMessage` objects representing the conversation history. If not provided, it is initialized as an empty vector.

"""
function render(schema::AbstractOpenAISchema,
        messages::Vector{<:AbstractMessage};
        image_detail::AbstractString = "auto",
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        kwargs...)
    ##
    @assert image_detail in ["auto", "high", "low"] "Image detail must be one of: auto, high, low"
    ## First pass: keep the message types but make the replacements provided in `kwargs`
    messages_replaced = render(NoSchema(), messages; conversation, kwargs...)

    ## Second pass: convert to the OpenAI schema
    conversation = Dict{String, Any}[]

    # replace any handlebar variables in the messages
    for msg in messages_replaced
        role = if msg isa SystemMessage
            "system"
        elseif msg isa UserMessage || msg isa UserMessageWithImages
            "user"
        elseif msg isa AIMessage
            "assistant"
        end
        ## Special case for images
        if msg isa UserMessageWithImages
            # Build message content
            content = Dict{String, Any}[Dict("type" => "text",
                "text" => msg.content)]
            # Add images
            for img in msg.image_url
                push!(content,
                    Dict("type" => "image_url",
                        "image_url" => Dict("url" => img,
                            "detail" => image_detail)))
            end
        else
            content = msg.content
        end
        push!(conversation, Dict("role" => role, "content" => content))
    end

    return conversation
end

## OpenAI.jl back-end
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
    OpenAI.auth_header(OpenAI.OpenAIProvider(provider.api_key,
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
        kwargs...)
    OpenAI.create_chat(api_key, model, conversation; kwargs...)
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
  url::String="http://localhost:8080",
  kwargs...)

Dispatch to the OpenAI.create_chat function, for any OpenAI-compatible API. 

It expects `url` keyword argument. Provide it to the `aigenerate` function via `api_kwargs=(; url="my-url")`

It will forward your query to the "chat/completions" endpoint of the base URL that you provided (=`url`).
"""
function OpenAI.create_chat(schema::CustomOpenAISchema,
        api_key::AbstractString,
        model::AbstractString,
        conversation;
        url::String = "http://localhost:8080",
        kwargs...)
    # Build the corresponding provider object
    # Create chat will automatically pass our data to endpoint `/chat/completions`
    provider = CustomProvider(; api_key, base_url = url)
    OpenAI.create_chat(provider, model, conversation; kwargs...)
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

It tries to access the `MISTRALAI_API_KEY` ENV variable, but you can also provide it via the `api_key` keyword argument.
"""
function OpenAI.create_chat(schema::MistralOpenAISchema,
        api_key::AbstractString,
        model::AbstractString,
        conversation;
        url::String = "https://api.mistral.ai/v1",
        kwargs...)
    # Build the corresponding provider object
    # try to override provided api_key because the default is OpenAI key
    provider = CustomProvider(;
        api_key = isempty(MISTRALAI_API_KEY) ? api_key : MISTRALAI_API_KEY,
        base_url = url)
    OpenAI.create_chat(provider, model, conversation; kwargs...)
end

# Extend OpenAI create_embeddings to allow for testing
function OpenAI.create_embeddings(schema::AbstractOpenAISchema,
        api_key::AbstractString,
        docs,
        model::AbstractString;
        kwargs...)
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
        api_key = isempty(MISTRALAI_API_KEY) ? api_key : MISTRALAI_API_KEY,
        base_url = url)
    OpenAI.create_embeddings(provider, docs, model; kwargs...)
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

## User-Facing API
"""
    aigenerate(prompt_schema::AbstractOpenAISchema, prompt::ALLOWED_PROMPT_TYPE;
        verbose::Bool = true,
        api_key::String = OPENAI_API_KEY,
        model::String = MODEL_CHAT, return_all::Bool = false, dry_run::Bool = false,
        http_kwargs::NamedTuple = (retry_non_idempotent = true,
            retries = 5,
            readtimeout = 120), api_kwargs::NamedTuple = NamedTuple(),
        kwargs...)

Generate an AI response based on a given prompt using the OpenAI API.

# Arguments
- `prompt_schema`: An optional object to specify which prompt template should be applied (Default to `PROMPT_SCHEMA = OpenAISchema`)
- `prompt`: Can be a string representing the prompt for the AI conversation, a `UserMessage`, a vector of `AbstractMessage` or an `AITemplate`
- `verbose`: A boolean indicating whether to print additional information.
- `api_key`: A string representing the API key for accessing the OpenAI API.
- `model`: A string representing the model to use for generating the response. Can be an alias corresponding to a model ID defined in `MODEL_ALIASES`.
- `return_all::Bool=false`: If `true`, returns the entire conversation history, otherwise returns only the last message (the `AIMessage`).
- `dry_run::Bool=false`: If `true`, skips sending the messages to the model (for debugging, often used with `return_all=true`).
- `conversation`: An optional vector of `AbstractMessage` objects representing the conversation history. If not provided, it is initialized as an empty vector.
- `http_kwargs`: A named tuple of HTTP keyword arguments.
- `api_kwargs`: A named tuple of API keyword arguments.
- `kwargs`: Prompt variables to be used to fill the prompt/template

# Returns

If `return_all=false` (default):
- `msg`: An `AIMessage` object representing the generated AI message, including the content, status, tokens, and elapsed time.
 Use `msg.content` to access the extracted string.

If `return_all=true`:
- `conversation`: A vector of `AbstractMessage` objects representing the conversation history, including the response from the AI model (`AIMessage`).

See also: `ai_str`, `aai_str`, `aiembed`, `aiclassify`, `aiextract`, `aiscan`, `aitemplates`

# Example

Simple hello world to test the API:
```julia
result = aigenerate("Say Hi!")
# [ Info: Tokens: 29 @ Cost: \$0.0 in 1.0 seconds
# AIMessage("Hello! How can I assist you today?")
```

`result` is an `AIMessage` object. Access the generated string via `content` property:
```julia
typeof(result) # AIMessage{SubString{String}}
propertynames(result) # (:content, :status, :tokens, :elapsed
result.content # "Hello! How can I assist you today?"
```
___
You can use string interpolation:
```julia
a = 1
msg=aigenerate("What is `\$a+\$a`?")
msg.content # "The sum of `1+1` is `2`."
```
___
You can provide the whole conversation or more intricate prompts as a `Vector{AbstractMessage}`:
```julia
const PT = PromptingTools

conversation = [
    PT.SystemMessage("You're master Yoda from Star Wars trying to help the user become a Yedi."),
    PT.UserMessage("I have feelings for my iPhone. What should I do?")]
msg=aigenerate(conversation)
# AIMessage("Ah, strong feelings you have for your iPhone. A Jedi's path, this is not... <continues>")
```
"""
function aigenerate(prompt_schema::AbstractOpenAISchema, prompt::ALLOWED_PROMPT_TYPE;
        verbose::Bool = true,
        api_key::String = OPENAI_API_KEY,
        model::String = MODEL_CHAT, return_all::Bool = false, dry_run::Bool = false,
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        http_kwargs::NamedTuple = (retry_non_idempotent = true,
            retries = 5,
            readtimeout = 120), api_kwargs::NamedTuple = NamedTuple(),
        kwargs...)
    ##
    global MODEL_ALIASES
    ## Find the unique ID for the model alias provided
    model_id = get(MODEL_ALIASES, model, model)
    conv_rendered = render(prompt_schema, prompt; conversation, kwargs...)

    if !dry_run
        time = @elapsed r = create_chat(prompt_schema, api_key,
            model_id,
            conv_rendered;
            http_kwargs,
            api_kwargs...)
        msg = AIMessage(;
            content = r.response[:choices][begin][:message][:content] |> strip,
            status = Int(r.status),
            tokens = (r.response[:usage][:prompt_tokens],
                r.response[:usage][:completion_tokens]),
            elapsed = time)
        ## Reporting
        verbose && @info _report_stats(msg, model_id)
    else
        msg = nothing
    end
    ## Select what to return
    output = finalize_outputs(prompt,
        conv_rendered,
        msg;
        conversation,
        return_all,
        dry_run,
        kwargs...)

    return output
end

"""
    aiembed(prompt_schema::AbstractOpenAISchema,
            doc_or_docs::Union{AbstractString, AbstractVector{<:AbstractString}},
            postprocess::F = identity;
            verbose::Bool = true,
            api_key::String = OPENAI_API_KEY,
            model::String = MODEL_EMBEDDING, 
            http_kwargs::NamedTuple = (retry_non_idempotent = true,
                                       retries = 5,
                                       readtimeout = 120),
            api_kwargs::NamedTuple = NamedTuple(),
            kwargs...) where {F <: Function}

The `aiembed` function generates embeddings for the given input using a specified model and returns a message object containing the embeddings, status, token count, and elapsed time.

## Arguments
- `prompt_schema::AbstractOpenAISchema`: The schema for the prompt.
- `doc_or_docs::Union{AbstractString, AbstractVector{<:AbstractString}}`: The document or list of documents to generate embeddings for.
- `postprocess::F`: The post-processing function to apply to each embedding. Defaults to the identity function.
- `verbose::Bool`: A flag indicating whether to print verbose information. Defaults to `true`.
- `api_key::String`: The API key to use for the OpenAI API. Defaults to `OPENAI_API_KEY`.
- `model::String`: The model to use for generating embeddings. Defaults to `MODEL_EMBEDDING`.
- `http_kwargs::NamedTuple`: Additional keyword arguments for the HTTP request. Defaults to `(retry_non_idempotent = true, retries = 5, readtimeout = 120)`.
- `api_kwargs::NamedTuple`: Additional keyword arguments for the OpenAI API. Defaults to an empty `NamedTuple`.
- `kwargs...`: Additional keyword arguments.

## Returns
- `msg`: A `DataMessage` object containing the embeddings, status, token count, and elapsed time. Use `msg.content` to access the embeddings.

# Example

```julia
msg = aiembed("Hello World")
msg.content # 1536-element JSON3.Array{Float64...
```

We can embed multiple strings at once and they will be `hcat` into a matrix 
 (ie, each column corresponds to one string)
```julia
msg = aiembed(["Hello World", "How are you?"])
msg.content # 1536×2 Matrix{Float64}:
```

If you plan to calculate the cosine distance between embeddings, you can normalize them first:
```julia
using LinearAlgebra
msg = aiembed(["embed me", "and me too"], LinearAlgebra.normalize)

# calculate cosine distance between the two normalized embeddings as a simple dot product
msg.content' * msg.content[:, 1] # [1.0, 0.787]
```

"""
function aiembed(prompt_schema::AbstractOpenAISchema,
        doc_or_docs::Union{AbstractString, AbstractVector{<:AbstractString}},
        postprocess::F = identity; verbose::Bool = true,
        api_key::String = OPENAI_API_KEY,
        model::String = MODEL_EMBEDDING,
        http_kwargs::NamedTuple = (retry_non_idempotent = true,
            retries = 5,
            readtimeout = 120), api_kwargs::NamedTuple = NamedTuple(),
        kwargs...) where {F <: Function}
    ##
    global MODEL_ALIASES
    ## Find the unique ID for the model alias provided
    model_id = get(MODEL_ALIASES, model, model)

    time = @elapsed r = create_embeddings(prompt_schema, api_key,
        doc_or_docs,
        model_id;
        http_kwargs,
        api_kwargs...)
    msg = DataMessage(;
        content = mapreduce(x -> postprocess(x[:embedding]), hcat, r.response[:data]),
        status = Int(r.status),
        tokens = (r.response[:usage][:prompt_tokens], 0),
        elapsed = time)
    ## Reporting
    verbose && @info _report_stats(msg, model_id)

    return msg
end

"""
    aiclassify(prompt_schema::AbstractOpenAISchema, prompt::ALLOWED_PROMPT_TYPE;
    api_kwargs::NamedTuple = (logit_bias = Dict(837 => 100, 905 => 100, 9987 => 100),
        max_tokens = 1, temperature = 0),
    kwargs...)

Classifies the given prompt/statement as true/false/unknown.

Note: this is a very simple classifier, it is not meant to be used in production. Credit goes to [AAAzzam](https://twitter.com/AAAzzam/status/1669753721574633473).

It uses Logit bias trick and limits the output to 1 token to force the model to output only true/false/unknown.

Output tokens used (via `api_kwargs`):
- 837: ' true'
- 905: ' false'
- 9987: ' unknown'

# Arguments
- `prompt_schema::AbstractOpenAISchema`: The schema for the prompt.
- `prompt`: The prompt/statement to classify if it's a `String`. If it's a `Symbol`, it is expanded as a template via `render(schema,template)`.

# Example

```julia
aiclassify("Is two plus two four?") # true
aiclassify("Is two plus three a vegetable on Mars?") # false
```
`aiclassify` returns only true/false/unknown. It's easy to get the proper `Bool` output type out with `tryparse`, eg,
```julia
tryparse(Bool, aiclassify("Is two plus two four?")) isa Bool # true
```
Output of type `Nothing` marks that the model couldn't classify the statement as true/false.

Ideally, we would like to re-use some helpful system prompt to get more accurate responses.
For this reason we have templates, eg, `:JudgeIsItTrue`. By specifying the template, we can provide our statement as the expected variable (`it` in this case)
See that the model now correctly classifies the statement as "unknown".
```julia
aiclassify(:JudgeIsItTrue; it = "Is two plus three a vegetable on Mars?") # unknown
```

For better results, use higher quality models like gpt4, eg, 
```julia
aiclassify(:JudgeIsItTrue;
    it = "If I had two apples and I got three more, I have five apples now.",
    model = "gpt4") # true
```

"""
function aiclassify(prompt_schema::AbstractOpenAISchema, prompt::ALLOWED_PROMPT_TYPE;
        api_kwargs::NamedTuple = (logit_bias = Dict(837 => 100, 905 => 100, 9987 => 100),
            max_tokens = 1, temperature = 0),
        kwargs...)
    ##
    msg = aigenerate(prompt_schema,
        prompt;
        api_kwargs,
        kwargs...)
    return msg
end

"""
    aiextract([prompt_schema::AbstractOpenAISchema,] prompt::ALLOWED_PROMPT_TYPE; 
    return_type::Type,
    verbose::Bool = true,
        model::String = MODEL_CHAT,
        return_all::Bool = false, dry_run::Bool = false,  
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        http_kwargs::NamedTuple = (;
            retry_non_idempotent = true,
            retries = 5,
            readtimeout = 120), api_kwargs::NamedTuple = NamedTuple(),
        kwargs...)

Extract required information (defined by a struct **`return_type`**) from the provided prompt by leveraging OpenAI function calling mode.

This is a perfect solution for extracting structured information from text (eg, extract organization names in news articles, etc.)

It's effectively a light wrapper around `aigenerate` call, which requires additional keyword argument `return_type` to be provided
 and will enforce the model outputs to adhere to it.

# Arguments
- `prompt_schema`: An optional object to specify which prompt template should be applied (Default to `PROMPT_SCHEMA = OpenAISchema`)
- `prompt`: Can be a string representing the prompt for the AI conversation, a `UserMessage`, a vector of `AbstractMessage` or an `AITemplate`
- `return_type`: A **struct** TYPE representing the the information we want to extract. Do not provide a struct instance, only the type.
  If the struct has a docstring, it will be provided to the model as well. It's used to enforce structured model outputs or provide more information.
- `verbose`: A boolean indicating whether to print additional information.
- `api_key`: A string representing the API key for accessing the OpenAI API.
- `model`: A string representing the model to use for generating the response. Can be an alias corresponding to a model ID defined in `MODEL_ALIASES`.
- `return_all::Bool=false`: If `true`, returns the entire conversation history, otherwise returns only the last message (the `AIMessage`).
- `dry_run::Bool=false`: If `true`, skips sending the messages to the model (for debugging, often used with `return_all=true`).
- `conversation`: An optional vector of `AbstractMessage` objects representing the conversation history. If not provided, it is initialized as an empty vector.
- `http_kwargs`: A named tuple of HTTP keyword arguments.
- `api_kwargs`: A named tuple of API keyword arguments.
- `kwargs`: Prompt variables to be used to fill the prompt/template

# Returns
If `return_all=false` (default):
- `msg`: An `DataMessage` object representing the extracted data, including the content, status, tokens, and elapsed time. 
  Use `msg.content` to access the extracted data.

If `return_all=true`:
- `conversation`: A vector of `AbstractMessage` objects representing the full conversation history, including the response from the AI model (`DataMessage`).


See also: `function_call_signature`, `MaybeExtract`, `ItemsExtract`, `aigenerate`

# Example

Do you want to extract some specific measurements from a text like age, weight and height?
You need to define the information you need as a struct (`return_type`):
```
"Person's age, height, and weight."
struct MyMeasurement
    age::Int # required
    height::Union{Int,Nothing} # optional
    weight::Union{Nothing,Float64} # optional
end
msg = aiextract("James is 30, weighs 80kg. He's 180cm tall."; return_type=MyMeasurement)
# [ Info: Tokens: 129 @ Cost: \$0.0002 in 1.0 seconds
# PromptingTools.DataMessage(MyMeasurement)
msg.content
# MyMeasurement(30, 180, 80.0)
```

The fields that allow `Nothing` are marked as optional in the schema:
```
msg = aiextract("James is 30."; return_type=MyMeasurement)
# MyMeasurement(30, nothing, nothing)
```

If there are multiple items you want to extract, define a wrapper struct to get a Vector of `MyMeasurement`:
```
struct MyMeasurementWrapper
    measurements::Vector{MyMeasurement}
end

msg = aiextract("James is 30, weighs 80kg. He's 180cm tall. Then Jack is 19 but really tall - over 190!"; return_type=ManyMeasurements)

msg.content.measurements
# 2-element Vector{MyMeasurement}:
#  MyMeasurement(30, 180, 80.0)
#  MyMeasurement(19, 190, nothing)
```

Or you can use the convenience wrapper `ItemsExtract` to extract multiple measurements (zero, one or more):
```julia
using PromptingTools: ItemsExtract

return_type = ItemsExtract{MyMeasurement}
msg = aiextract("James is 30, weighs 80kg. He's 180cm tall. Then Jack is 19 but really tall - over 190!"; return_type)

msg.content.items # see the extracted items
```

Or if you want your extraction to fail gracefully when data isn't found, use `MaybeExtract{T}` wrapper
 (this trick is inspired by the Instructor package!):
```
using PromptingTools: MaybeExtract

type = MaybeExtract{MyMeasurement}
# Effectively the same as:
# struct MaybeExtract{T}
#     result::Union{T, Nothing} // The result of the extraction
#     error::Bool // true if a result is found, false otherwise
#     message::Union{Nothing, String} // Only present if no result is found, should be short and concise
# end

# If LLM extraction fails, it will return a Dict with `error` and `message` fields instead of the result!
msg = aiextract("Extract measurements from the text: I am giraffe", type)
msg.content
# MaybeExtract{MyMeasurement}(nothing, true, "I'm sorry, but I can only assist with human measurements.")
```

That way, you can handle the error gracefully and get a reason why extraction failed (in `msg.content.message`).

Note that the error message refers to a giraffe not being a human, 
 because in our `MyMeasurement` docstring, we said that it's for people!
"""
function aiextract(prompt_schema::AbstractOpenAISchema, prompt::ALLOWED_PROMPT_TYPE;
        return_type::Type,
        verbose::Bool = true,
        api_key::String = OPENAI_API_KEY,
        model::String = MODEL_CHAT,
        return_all::Bool = false, dry_run::Bool = false,
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        http_kwargs::NamedTuple = (retry_non_idempotent = true,
            retries = 5,
            readtimeout = 120), api_kwargs::NamedTuple = NamedTuple(),
        kwargs...)
    ##
    global MODEL_ALIASES
    ## Function calling specifics
    functions = [function_call_signature(return_type)]
    function_call = Dict(:name => only(functions)["name"])
    ## Add the function call signature to the api_kwargs
    api_kwargs = merge(api_kwargs, (; functions, function_call))
    ## Find the unique ID for the model alias provided
    model_id = get(MODEL_ALIASES, model, model)
    conv_rendered = render(prompt_schema, prompt; conversation, kwargs...)

    if !dry_run
        time = @elapsed r = create_chat(prompt_schema, api_key,
            model_id,
            conv_rendered;
            http_kwargs,
            api_kwargs...)
        # "Safe" parsing of the response - it still fails if JSON is invalid
        content = try
            r.response[:choices][begin][:message][:function_call][:arguments] |>
            x -> JSON3.read(x, return_type)
        catch e
            @warn "There was an error parsing the response: $e. Using the raw response instead."
            r.response[:choices][begin][:message][:function_call][:arguments] |>
            JSON3.read |> copy
        end
        msg = DataMessage(; content,
            status = Int(r.status),
            tokens = (r.response[:usage][:prompt_tokens],
                r.response[:usage][:completion_tokens]),
            elapsed = time)
        ## Reporting
        verbose && @info _report_stats(msg, model_id)
    else
        msg = nothing
    end
    ## Select what to return
    output = finalize_outputs(prompt,
        conv_rendered,
        msg;
        conversation,
        return_all,
        dry_run,
        kwargs...)

    return output
end

"""
aiscan([prompt_schema::AbstractOpenAISchema,] prompt::ALLOWED_PROMPT_TYPE; 
    image_url::Union{Nothing, AbstractString, Vector{<:AbstractString}} = nothing,
    image_path::Union{Nothing, AbstractString, Vector{<:AbstractString}} = nothing,
    image_detail::AbstractString = "auto",
    attach_to_latest::Bool = true,
    verbose::Bool = true, api_key::String = OPENAI_API_KEY,
        model::String = MODEL_CHAT,
        return_all::Bool = false, dry_run::Bool = false,
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        http_kwargs::NamedTuple = (;
            retry_non_idempotent = true,
            retries = 5,
            readtimeout = 120), 
        api_kwargs::NamedTuple = = (; max_tokens = 2500),
        kwargs...)

Scans the provided image (`image_url` or `image_path`) with the goal provided in the `prompt`.

Can be used for many multi-modal tasks, such as: OCR (transcribe text in the image), image captioning, image classification, etc.

It's effectively a light wrapper around `aigenerate` call, which uses additional keyword arguments `image_url`, `image_path`, `image_detail` to be provided. 
 At least one image source (url or path) must be provided.

# Arguments
- `prompt_schema`: An optional object to specify which prompt template should be applied (Default to `PROMPT_SCHEMA = OpenAISchema`)
- `prompt`: Can be a string representing the prompt for the AI conversation, a `UserMessage`, a vector of `AbstractMessage` or an `AITemplate`
- `image_url`: A string or vector of strings representing the URL(s) of the image(s) to scan.
- `image_path`: A string or vector of strings representing the path(s) of the image(s) to scan.
- `image_detail`: A string representing the level of detail to include for images. Can be `"auto"`, `"high"`, or `"low"`. See [OpenAI Vision Guide](https://platform.openai.com/docs/guides/vision) for more details.
- `attach_to_latest`: A boolean how to handle if a conversation with multiple `UserMessage` is provided. When `true`, the images are attached to the latest `UserMessage`.
- `verbose`: A boolean indicating whether to print additional information.
- `api_key`: A string representing the API key for accessing the OpenAI API.
- `model`: A string representing the model to use for generating the response. Can be an alias corresponding to a model ID defined in `MODEL_ALIASES`.
- `return_all::Bool=false`: If `true`, returns the entire conversation history, otherwise returns only the last message (the `AIMessage`).
- `dry_run::Bool=false`: If `true`, skips sending the messages to the model (for debugging, often used with `return_all=true`).
- `conversation`: An optional vector of `AbstractMessage` objects representing the conversation history. If not provided, it is initialized as an empty vector.
- `http_kwargs`: A named tuple of HTTP keyword arguments.
- `api_kwargs`: A named tuple of API keyword arguments.
- `kwargs`: Prompt variables to be used to fill the prompt/template

# Returns
If `return_all=false` (default):
- `msg`: An `AIMessage` object representing the generated AI message, including the content, status, tokens, and elapsed time.
 Use `msg.content` to access the extracted string.

If `return_all=true`:
- `conversation`: A vector of `AbstractMessage` objects representing the full conversation history, including the response from the AI model (`AIMessage`).

See also: `ai_str`, `aai_str`, `aigenerate`, `aiembed`, `aiclassify`, `aiextract`, `aitemplates`

# Notes

- All examples below use model "gpt4v", which is an alias for model ID "gpt-4-vision-preview"
- `max_tokens` in the `api_kwargs` is preset to 2500, otherwise OpenAI enforces a default of only a few hundred tokens (~300). If your output is truncated, increase this value

# Example

Describe the provided image:
```julia
msg = aiscan("Describe the image"; image_path="julia.png", model="gpt4v")
# [ Info: Tokens: 1141 @ Cost: \$0.0117 in 2.2 seconds
# AIMessage("The image shows a logo consisting of the word "julia" written in lowercase")
```

You can provide multiple images at once as a vector and ask for "low" level of detail (cheaper):
```julia
msg = aiscan("Describe the image"; image_path=["julia.png","python.png"], image_detail="low", model="gpt4v")
```

You can use this function as a nice and quick OCR (transcribe text in the image) with a template `:OCRTask`. 
Let's transcribe some SQL code from a screenshot (no more re-typing!):

```julia
# Screenshot of some SQL code
image_url = "https://www.sqlservercentral.com/wp-content/uploads/legacy/8755f69180b7ac7ee76a69ae68ec36872a116ad4/24622.png"
msg = aiscan(:OCRTask; image_url, model="gpt4v", task="Transcribe the SQL code in the image.", api_kwargs=(; max_tokens=2500))

# [ Info: Tokens: 362 @ Cost: \$0.0045 in 2.5 seconds
# AIMessage("```sql
# update Orders <continue>

# You can add syntax highlighting of the outputs via Markdown
using Markdown
msg.content |> Markdown.parse
```

Notice that we enforce `max_tokens = 2500`. That's because OpenAI seems to default to ~300 tokens, which provides incomplete outputs.
Hence, we set this value to 2500 as a default. If you still get truncated outputs, increase this value.

"""
function aiscan(prompt_schema::AbstractOpenAISchema, prompt::ALLOWED_PROMPT_TYPE;
        image_url::Union{Nothing, AbstractString, Vector{<:AbstractString}} = nothing,
        image_path::Union{Nothing, AbstractString, Vector{<:AbstractString}} = nothing,
        image_detail::AbstractString = "auto",
        attach_to_latest::Bool = true,
        verbose::Bool = true,
        api_key::String = OPENAI_API_KEY,
        model::String = MODEL_CHAT,
        return_all::Bool = false, dry_run::Bool = false,
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        http_kwargs::NamedTuple = (retry_non_idempotent = true,
            retries = 5,
            readtimeout = 120), api_kwargs::NamedTuple = (; max_tokens = 2500),
        kwargs...)
    ##
    global MODEL_ALIASES
    ## Find the unique ID for the model alias provided
    model_id = get(MODEL_ALIASES, model, model)
    ## Vision-specific functionality
    msgs = attach_images_to_user_message(prompt; image_url, image_path, attach_to_latest)
    ## Build the conversation, pass what image detail is required (if provided)
    conv_rendered = render(prompt_schema, msgs; conversation, image_detail, kwargs...)
    if !dry_run
        ## Model call
        time = @elapsed r = create_chat(prompt_schema, api_key,
            model_id,
            conv_rendered;
            http_kwargs,
            api_kwargs...)
        msg = AIMessage(;
            content = r.response[:choices][begin][:message][:content] |> strip,
            status = Int(r.status),
            tokens = (r.response[:usage][:prompt_tokens],
                r.response[:usage][:completion_tokens]),
            elapsed = time)
        ## Reporting
        verbose && @info _report_stats(msg, model_id)
    else
        msg = nothing
    end

    ## Select what to return // input `msgs` to preserve the image attachments
    output = finalize_outputs(msgs,
        conv_rendered,
        msg;
        conversation,
        return_all,
        dry_run,
        kwargs...)

    return output
end
