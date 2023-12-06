## Schema dedicated to [Ollama's managed models](https://ollama.ai/), which also managed the prompts
## It's limited to 2 messages (system and user), because there are only two slots for `system` and `prompt`
##
## Rendering of converation history for the Ollama
"""
    render(schema::AbstractOllamaManagedSchema,
        messages::Vector{<:AbstractMessage};
        kwargs...)

Builds a history of the conversation to provide the prompt to the API. All unspecified kwargs are passed as replacements such that `{{key}}=>value` in the template.

Note: Due to its "managed" nature, at most 2 messages can be provided (`system` and `prompt` inputs in the API).
"""
function render(schema::AbstractOllamaManagedSchema,
        messages::Vector{<:AbstractMessage};
        kwargs...)
    ## 
    @assert length(messages)<=2 "Managed schema only supports 2 messages (eg, a system and user)"
    @assert count(isusermessage, messages)<=1 "Managed schema only supports at most 1 User message"
    @assert count(issystemmessage, messages)<=1 "Managed schema only supports at most 1 System message"
    ## API expects: system=SystemMessage, prompt=UserMessage
    system, prompt = nothing, nothing

    # replace any handlebar variables in the messages
    for msg in messages
        if msg isa SystemMessage
            replacements = ["{{$(key)}}" => value
                            for (key, value) in pairs(kwargs) if key in msg.variables]
            system = replace(msg.content, replacements...)
        elseif msg isa UserMessage
            replacements = ["{{$(key)}}" => value
                            for (key, value) in pairs(kwargs) if key in msg.variables]
            prompt = replace(msg.content, replacements...)
        elseif msg isa UserMessageWithImages
            error("Managed schema does not support UserMessageWithImages. Please use OpenAISchema instead.")
        elseif msg isa AIMessage
            error("Managed schema does not support AIMessage and multi-turn conversations. Please use OpenAISchema instead.")
        end
        # Note: Ignores any DataMessage or other types
    end
    ## Sense check
    @assert !isnothing(prompt) "Managed schema requires at least 1 User message, ie, no `prompt` provided!"
    ## Add default system prompt if not provided
    isnothing(system) && (system = "Act as a helpful AI assistant")

    return (; system, prompt)
end

## Model-calling
"""
    ollama_api(prompt_schema::AbstractOllamaManagedSchema, prompt::AbstractString,
        system::Union{Nothing, AbstractString} = nothing,
        endpoint::String = "generate";
        model::String = "llama2", http_kwargs::NamedTuple = NamedTuple(),
        stream::Bool = false,
        url::String = "localhost", port::Int = 11434,
        kwargs...)

Simple wrapper for a call to Ollama API.

# Keyword Arguments
- `prompt_schema`: Defines which prompt template should be applied.
- `prompt`: Can be a string representing the prompt for the AI conversation, a `UserMessage`, a vector of `AbstractMessage`
- `system`: An optional string representing the system message for the AI conversation. If not provided, a default message will be used.
- `endpoint`: The API endpoint to call, only "generate" and "embeddings" are currently supported. Defaults to "generate".
- `model`: A string representing the model to use for generating the response. Can be an alias corresponding to a model ID defined in `MODEL_ALIASES`.
- `http_kwargs::NamedTuple`: Additional keyword arguments for the HTTP request. Defaults to empty `NamedTuple`.
- `stream`: A boolean indicating whether to stream the response. Defaults to `false`.
- `url`: The URL of the Ollama API. Defaults to "localhost".
- `port`: The port of the Ollama API. Defaults to 11434.
- `kwargs`: Prompt variables to be used to fill the prompt/template
"""
function ollama_api(prompt_schema::AbstractOllamaManagedSchema, prompt::AbstractString;
        system::Union{Nothing, AbstractString} = nothing,
        endpoint::String = "generate",
        model::String = "llama2", http_kwargs::NamedTuple = NamedTuple(),
        stream::Bool = false,
        url::String = "localhost", port::Int = 11434,
        kwargs...)
    @assert endpoint in ["generate", "embeddings"] "Only 'generate' and 'embeddings' Ollama endpoints are supported."
    ##
    body = Dict("model" => model, "stream" => stream, "prompt" => prompt, kwargs...)
    if !isnothing(system)
        body["system"] = system
    end
    # eg, http://localhost:11434/api/generate
    api_url = string("http://", url, ":", port, "/api/", endpoint)
    resp = HTTP.post(api_url,
        [],# no headers
        JSON3.write(body); http_kwargs...)
    body = JSON3.read(resp.body)
    return (; response = body, resp.status)
end
# For testing
function ollama_api(prompt_schema::TestEchoOllamaManagedSchema, prompt::AbstractString;
        system::Union{Nothing, AbstractString} = nothing, endpoint::String = "generate",
        model::String = "llama2", kwargs...)
    prompt_schema.model_id = model
    prompt_schema.inputs = (; system, prompt)
    return prompt_schema
end

## User-Facing API
"""
    aigenerate(prompt_schema::AbstractOllamaManagedSchema, prompt::ALLOWED_PROMPT_TYPE; verbose::Bool = true,
        model::String = MODEL_CHAT,
        return_all::Bool = false, dry_run::Bool = false,
        http_kwargs::NamedTuple = NamedTuple(), api_kwargs::NamedTuple = NamedTuple(),
        kwargs...)

Generate an AI response based on a given prompt using the OpenAI API.

# Arguments
- `prompt_schema`: An optional object to specify which prompt template should be applied (Default to `PROMPT_SCHEMA = OpenAISchema` not `AbstractManagedSchema`)
- `prompt`: Can be a string representing the prompt for the AI conversation, a `UserMessage`, a vector of `AbstractMessage` or an `AITemplate`
- `verbose`: A boolean indicating whether to print additional information.
- `api_key`: Provided for interface consistency. Not needed for locally hosted Ollama.
- `model`: A string representing the model to use for generating the response. Can be an alias corresponding to a model ID defined in `MODEL_ALIASES`.
- `return_all::Bool=false`: If `true`, returns the entire conversation history, otherwise returns only the last message (the `AIMessage`).
- `dry_run::Bool=false`: If `true`, skips sending the messages to the model (for debugging, often used with `return_all=true`).
- `http_kwargs::NamedTuple`: Additional keyword arguments for the HTTP request. Defaults to empty `NamedTuple`.
- `api_kwargs::NamedTuple`: Additional keyword arguments for the Ollama API. Defaults to an empty `NamedTuple`.
- `kwargs`: Prompt variables to be used to fill the prompt/template

# Returns
- `msg`: An `AIMessage` object representing the generated AI message, including the content, status, tokens, and elapsed time.
 Use `msg.content` to access the extracted string.

See also: `ai_str`, `aai_str`, `aiembed`

# Example

Simple hello world to test the API:
```julia
const PT = PromptingTools
schema = PT.OllamaManagedSchema() # We need to explicit if we want Ollama, OpenAISchema is the default

msg = aigenerate(schema, "Say hi!"; model="openhermes2.5-mistral")
# [ Info: Tokens: 69 in 0.9 seconds
# AIMessage("Hello! How can I assist you today?")
```

`msg` is an `AIMessage` object. Access the generated string via `content` property:
```julia
typeof(msg) # AIMessage{SubString{String}}
propertynames(msg) # (:content, :status, :tokens, :elapsed
msg.content # "Hello! How can I assist you today?"
```

Note: We need to be explicit about the schema we want to use. If we don't, it will default to `OpenAISchema` (=`PT.DEFAULT_SCHEMA`)
___
You can use string interpolation:
```julia
const PT = PromptingTools
schema = PT.OllamaManagedSchema()
a = 1
msg=aigenerate(schema, "What is `\$a+\$a`?"; model="openhermes2.5-mistral")
msg.content # "The result of `1+1` is `2`."
```
___
You can provide the whole conversation or more intricate prompts as a `Vector{AbstractMessage}`:
```julia
const PT = PromptingTools
schema = PT.OllamaManagedSchema()

conversation = [
    PT.SystemMessage("You're master Yoda from Star Wars trying to help the user become a Yedi."),
    PT.UserMessage("I have feelings for my iPhone. What should I do?")]

msg = aigenerate(schema, conversation; model="openhermes2.5-mistral")
# [ Info: Tokens: 111 in 2.1 seconds
# AIMessage("Strong the attachment is, it leads to suffering it may. Focus on the force within you must, ...<continues>")
```

Note: Managed Ollama currently supports at most 1 User Message and 1 System Message given the API limitations. If you want more, you need to use the `ChatMLSchema`.
"""
function aigenerate(prompt_schema::AbstractOllamaManagedSchema, prompt::ALLOWED_PROMPT_TYPE;
        verbose::Bool = true,
        api_key::String = API_KEY,
        model::String = MODEL_CHAT,
        return_all::Bool = false, dry_run::Bool = false,
        http_kwargs::NamedTuple = NamedTuple(), api_kwargs::NamedTuple = NamedTuple(),
        kwargs...)
    ##
    global MODEL_ALIASES, MODEL_COSTS
    ## Find the unique ID for the model alias provided
    model_id = get(MODEL_ALIASES, model, model)
    conversation = render(prompt_schema, prompt; kwargs...)

    if !dry_run
        time = @elapsed resp = ollama_api(prompt_schema, conversation.prompt;
            conversation.system, endpoint = "generate", model, http_kwargs, api_kwargs...)
        msg = AIMessage(; content = resp.response[:response] |> strip,
            status = Int(resp.status),
            tokens = (resp.response[:prompt_eval_count],
                resp.response[:eval_count]),
            elapsed = time)
        ## Reporting
        verbose && @info _report_stats(msg, model_id, MODEL_COSTS)
    else
        msg = nothing
    end

    ## Select what to return
    output = finalize_outputs(prompt, conversation, msg; return_all, dry_run, kwargs...)
    return output
end

"""
    aiembed(prompt_schema::AbstractOllamaManagedSchema,
            doc_or_docs::Union{AbstractString, Vector{<:AbstractString}},
            postprocess::F = identity;
            verbose::Bool = true,
            api_key::String = API_KEY,
            model::String = MODEL_EMBEDDING,
            http_kwargs::NamedTuple = (retry_non_idempotent = true,
                                       retries = 5,
                                       readtimeout = 120),
            api_kwargs::NamedTuple = NamedTuple(),
            kwargs...) where {F <: Function}

The `aiembed` function generates embeddings for the given input using a specified model and returns a message object containing the embeddings, status, token count, and elapsed time.

## Arguments
- `prompt_schema::AbstractOllamaManagedSchema`: The schema for the prompt.
- `doc_or_docs::Union{AbstractString, Vector{<:AbstractString}}`: The document or list of documents to generate embeddings for. The list of documents is processed sequentially, 
  so users should consider implementing an async version with with `Threads.@spawn`
- `postprocess::F`: The post-processing function to apply to each embedding. Defaults to the identity function, but could be `LinearAlgebra.normalize`.
- `verbose::Bool`: A flag indicating whether to print verbose information. Defaults to `true`.
- `api_key::String`: The API key to use for the OpenAI API. Defaults to `API_KEY`.
- `model::String`: The model to use for generating embeddings. Defaults to `MODEL_EMBEDDING`.
- `http_kwargs::NamedTuple`: Additional keyword arguments for the HTTP request. Defaults to empty `NamedTuple`.
- `api_kwargs::NamedTuple`: Additional keyword arguments for the Ollama API. Defaults to an empty `NamedTuple`.
- `kwargs`: Prompt variables to be used to fill the prompt/template

## Returns
- `msg`: A `DataMessage` object containing the embeddings, status, token count, and elapsed time.

Note: Ollama API currently does not return the token count, so it's set to `(0,0)`

# Example

```julia
const PT = PromptingTools
schema = PT.OllamaManagedSchema()

msg = aiembed(schema, "Hello World"; model="openhermes2.5-mistral")
msg.content # 4096-element JSON3.Array{Float64...
```

We can embed multiple strings at once and they will be `hcat` into a matrix 
 (ie, each column corresponds to one string)
```julia
const PT = PromptingTools
schema = PT.OllamaManagedSchema()

msg = aiembed(schema, ["Hello World", "How are you?"]; model="openhermes2.5-mistral")
msg.content # 4096×2 Matrix{Float64}:
```

If you plan to calculate the cosine distance between embeddings, you can normalize them first:
```julia
const PT = PromptingTools
using LinearAlgebra
schema = PT.OllamaManagedSchema()

msg = aiembed(schema, ["embed me", "and me too"], LinearAlgebra.normalize; model="openhermes2.5-mistral")

# calculate cosine distance between the two normalized embeddings as a simple dot product
msg.content' * msg.content[:, 1] # [1.0, 0.34]
```

Similarly, you can use the `postprocess` argument to materialize the data from JSON3.Object by using `postprocess = copy`
```julia
const PT = PromptingTools
schema = PT.OllamaManagedSchema()

msg = aiembed(schema, "Hello World", copy; model="openhermes2.5-mistral")
msg.content # 4096-element Vector{Float64}
```

"""
function aiembed(prompt_schema::AbstractOllamaManagedSchema,
        doc::AbstractString,
        postprocess::F = identity; verbose::Bool = true,
        api_key::String = API_KEY,
        model::String = MODEL_EMBEDDING,
        http_kwargs::NamedTuple = NamedTuple(), api_kwargs::NamedTuple = NamedTuple(),
        kwargs...) where {F <: Function}
    ##
    global MODEL_ALIASES, MODEL_COSTS
    ## Find the unique ID for the model alias provided
    model_id = get(MODEL_ALIASES, model, model)
    time = @elapsed resp = ollama_api(prompt_schema, doc;
        endpoint = "embeddings", model, http_kwargs, api_kwargs...)
    msg = DataMessage(;
        content = postprocess(resp.response[:embedding]),
        status = Int(resp.status),
        tokens = (0, 0), # token counts are not provided for embeddings
        elapsed = time)
    ## Reporting
    verbose && @info _report_stats(msg, model_id, MODEL_COSTS)

    return msg
end
function aiembed(prompt_schema::AbstractOllamaManagedSchema,
        docs::Vector{<:AbstractString},
        postprocess::F = identity; verbose::Bool = true,
        api_key::String = API_KEY,
        model::String = MODEL_EMBEDDING,
        kwargs...) where {F <: Function}
    ##
    global MODEL_ALIASES, MODEL_COSTS
    ## Find the unique ID for the model alias provided
    model_id = get(MODEL_ALIASES, model, model)
    ## Send each document individually (no parallelism)
    messages = [aiembed(prompt_schema,
        doc,
        postprocess;
        verbose = false,
        api_key,
        model,
        kwargs...)
                for doc in docs]
    ## Aggregate results
    msg = DataMessage(;
        content = mapreduce(x -> x.content, hcat, messages),
        status = mapreduce(x -> x.status, max, messages),
        tokens = (0, 0),# not tracked for embeddings in Ollama
        elapsed = sum(x -> x.elapsed, messages))
    ## Reporting
    verbose && @info _report_stats(msg, model_id, MODEL_COSTS)

    return msg
end

function aiclassify(prompt_schema::AbstractManagedSchema, prompt::ALLOWED_PROMPT_TYPE;
        kwargs...)
    error("Managed schema does not support aiclassify. Please use OpenAISchema instead.")
end
function aiextract(prompt_schema::AbstractManagedSchema, prompt::ALLOWED_PROMPT_TYPE;
        kwargs...)
    error("Managed schema does not support aiextract. Please use OpenAISchema instead.")
end
function aiscan(prompt_schema::AbstractManagedSchema, prompt::ALLOWED_PROMPT_TYPE;
        kwargs...)
    error("Managed schema does not support aiscan. Please use OpenAISchema instead.")
end