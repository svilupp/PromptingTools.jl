## Ollama Generation API
# - llm_olama.jl works by providing messages format to /api/chat
# - llm_managed_olama.jl works by providing 1 system prompt and 1 user prompt /api/generate
#
## Schema dedicated to [Ollama's managed models](https://ollama.ai/), which also managed the prompts
## It's limited to 2 messages (system and user), because there are only two slots for `system` and `prompt`
##
## Rendering of converation history for the Ollama
"""
    render(schema::AbstractOllamaManagedSchema,
        messages::Vector{<:AbstractMessage};
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        kwargs...)

Builds a history of the conversation to provide the prompt to the API. All unspecified kwargs are passed as replacements such that `{{key}}=>value` in the template.

Note: Due to its "managed" nature, at most 2 messages can be provided (`system` and `prompt` inputs in the API).

# Keyword Arguments
- `conversation`: Not allowed for this schema. Provided only for compatibility.
"""
function render(schema::AbstractOllamaManagedSchema,
        messages::Vector{<:AbstractMessage};
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        kwargs...)
    ## 
    @assert length(messages)<=2 "Managed schema only supports 2 messages (eg, a system and user)"
    @assert count(isusermessage, messages)<=1 "Managed schema only supports at most 1 User message"
    @assert count(issystemmessage, messages)<=1 "Managed schema only supports at most 1 System message"
    @assert length(conversation)==0 "OllamaManagedSchema does not allow providing past conversation history. Use the `prompt` argument or `ChatMLSchema`."
    ## API expects: system=SystemMessage, prompt=UserMessage
    system, prompt = nothing, nothing

    ## First pass: keep the message types but make the replacements provided in `kwargs`
    messages_replaced = render(NoSchema(), messages; conversation, kwargs...)

    # replace any handlebar variables in the messages
    for msg in messages_replaced
        if msg isa SystemMessage
            system = msg.content
        elseif msg isa UserMessage
            prompt = msg.content
        elseif isabstractannotationmessage(msg)
            continue
        elseif msg isa UserMessageWithImages
            error("Managed schema does not support UserMessageWithImages. Please use OpenAISchema instead.")
        elseif msg isa AIMessage
            error("Managed schema does not support AIMessage and multi-turn conversations. Please use OpenAISchema instead.")
        end
        # Note: Ignores any DataMessage or other types
    end
    ## Sense check
    @assert !isnothing(prompt) "Managed schema requires at least 1 User message, ie, no `prompt` provided!"

    return (; system, prompt)
end

## Model-calling
"""
    ollama_api(prompt_schema::Union{AbstractOllamaManagedSchema, AbstractOllamaSchema},
        prompt::Union{AbstractString, Nothing} = nothing;
        system::Union{Nothing, AbstractString} = nothing,
        messages::Vector{<:AbstractMessage} = AbstractMessage[],
        endpoint::String = "generate",
        model::String = "llama2", http_kwargs::NamedTuple = NamedTuple(),
        stream::Bool = false,
        url::String = "http://localhost", port::Int = 11434,
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
- `streamcallback::Any`: A callback function to handle streaming responses. Can be simply `stdout` or a `StreamCallback` object. See `?StreamCallback` for details.
- `url`: The URL of the Ollama API. Defaults to "http://localhost". If no protocol is specified, "http://" will be automatically added.
- `port`: The port of the Ollama API. Defaults to 11434.
- `kwargs`: Prompt variables to be used to fill the prompt/template
"""
function ollama_api(
        prompt_schema::Union{AbstractOllamaManagedSchema, AbstractOllamaSchema},
        prompt::Union{AbstractString, Nothing} = nothing;
        system::Union{Nothing, AbstractString} = nothing,
        messages::Vector{<:AbstractDict{String, <:Any}} = Vector{Dict{String, Any}}(),
        endpoint::String = "generate",
        model::String = "llama2", http_kwargs::NamedTuple = NamedTuple(),
        streamcallback::Any = nothing,
        stream::Bool = false,
        url::String = "http://localhost", port::Int = 11434,
        kwargs...)
    @assert endpoint in ["chat", "generate", "embeddings"] "Only 'chat', 'generate' and 'embeddings' Ollama endpoints are supported."
    ##
    body = if !isnothing(prompt)
        Dict("model" => model, "stream" => stream, "prompt" => prompt, kwargs...)
    elseif !isempty(messages)
        Dict("model" => model, "stream" => stream, "messages" => messages, kwargs...)
    else
        error("No prompt or messages provided! Stopping.")
    end
    if !isnothing(system)
        body["system"] = system
    end
    # eg, http://localhost:11434/api/generate
    api_url = string(ensure_http_prefix(url), ":", port, "/api/", endpoint)
    if !isnothing(streamcallback)
        ## Note: Works only for OllamaSchema, not OllamaManagedSchema
        streamcallback,
        new_kwargs = configure_callback!(
            streamcallback, prompt_schema; kwargs...)
        for (k, v) in pairs(new_kwargs)
            body[string(k)] = v
        end
        input = IOBuffer(JSON3.write(body))
        resp = streamed_request!(
            streamcallback, api_url, [], input; http_kwargs...)
    else
        resp = HTTP.post(api_url,
            [],# no headers
            JSON3.write(body); http_kwargs...)
    end
    body = JSON3.read(resp.body)
    return (; response = body, resp.status)
end
# For testing
function ollama_api(prompt_schema::TestEchoOllamaManagedSchema,
        prompt::Union{AbstractString, Nothing} = nothing;
        system::Union{Nothing, AbstractString} = nothing,
        messages = [],
        endpoint::String = "generate",
        model::String = "llama2", kwargs...)
    prompt_schema.model_id = model
    prompt_schema.inputs = (; system, prompt)
    return prompt_schema
end

## User-Facing API
"""
    aigenerate(prompt_schema::AbstractOllamaManagedSchema, prompt::ALLOWED_PROMPT_TYPE; verbose::Bool = true,
        api_key::String = "", model::String = MODEL_CHAT,
        return_all::Bool = false, dry_run::Bool = false,
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        streamcallback::Any = nothing,
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
- `conversation::AbstractVector{<:AbstractMessage}=[]`: Not allowed for this schema. Provided only for compatibility.
- `streamcallback::Any`: Just for compatibility. Not supported for this schema.
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
function aigenerate(
        prompt_schema::AbstractOllamaManagedSchema, prompt::ALLOWED_PROMPT_TYPE;
        verbose::Bool = true,
        api_key::String = "",
        model::String = MODEL_CHAT,
        return_all::Bool = false, dry_run::Bool = false,
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        streamcallback::Any = nothing,
        http_kwargs::NamedTuple = NamedTuple(), api_kwargs::NamedTuple = NamedTuple(),
        kwargs...)
    ##
    global MODEL_ALIASES
    ## Find the unique ID for the model alias provided
    model_id = get(MODEL_ALIASES, model, model)
    conv_rendered = render(prompt_schema, prompt; conversation, kwargs...)
    @assert isnothing(streamcallback) "streamcallback is not supported for this schema."

    if !dry_run
        time = @elapsed resp = ollama_api(prompt_schema, conv_rendered.prompt;
            conv_rendered.system, endpoint = "generate", model = model_id, http_kwargs,
            streamcallback, api_kwargs...)
        tokens_prompt = get(resp.response, :prompt_eval_count, 0)
        tokens_completion = get(resp.response, :eval_count, 0)
        ## Build extras for observability (Logfire.jl integration)
        extras = Dict{Symbol, Any}()
        haskey(resp.response, :model) && (extras[:model] = resp.response[:model])
        msg = AIMessage(; content = resp.response[:response] |> strip,
            status = Int(resp.status),
            cost = call_cost(tokens_prompt, tokens_completion, model_id),
            tokens = (tokens_prompt, tokens_completion),
            elapsed = time,
            extras)
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
    aiembed(prompt_schema::AbstractOllamaManagedSchema,
            doc_or_docs::Union{AbstractString, AbstractVector{<:AbstractString}},
            postprocess::F = identity;
            verbose::Bool = true,
            api_key::String = "",
            model::String = MODEL_EMBEDDING,
            http_kwargs::NamedTuple = (retry_non_idempotent = true,
                                       retries = 5,
                                       readtimeout = 120),
            api_kwargs::NamedTuple = NamedTuple(),
            kwargs...) where {F <: Function}

The `aiembed` function generates embeddings for the given input using a specified model and returns a message object containing the embeddings, status, token count, and elapsed time.

## Arguments
- `prompt_schema::AbstractOllamaManagedSchema`: The schema for the prompt.
- `doc_or_docs::Union{AbstractString, AbstractVector{<:AbstractString}}`: The document or list of documents to generate embeddings for. The list of documents is processed sequentially, 
  so users should consider implementing an async version with with `Threads.@spawn`
- `postprocess::F`: The post-processing function to apply to each embedding. Defaults to the identity function, but could be `LinearAlgebra.normalize`.
- `verbose::Bool`: A flag indicating whether to print verbose information. Defaults to `true`.
- `api_key::String`: The API key to use for the OpenAI API. Defaults to `""`.
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
        api_key::String = "",
        model::String = MODEL_EMBEDDING,
        http_kwargs::NamedTuple = NamedTuple(), api_kwargs::NamedTuple = NamedTuple(),
        kwargs...) where {F <: Function}
    ##
    global MODEL_ALIASES
    ## Find the unique ID for the model alias provided
    model_id = get(MODEL_ALIASES, model, model)
    time = @elapsed resp = ollama_api(prompt_schema, doc;
        endpoint = "embeddings", model = model_id, http_kwargs, api_kwargs...)
    msg = DataMessage(;
        content = postprocess(resp.response[:embedding]),
        status = Int(resp.status),
        cost = call_cost(0, 0, model_id),
        tokens = (0, 0), # token counts are not provided for embeddings
        elapsed = time)
    ## Reporting
    verbose && @info _report_stats(msg, model_id)

    return msg
end
function aiembed(prompt_schema::AbstractOllamaManagedSchema,
        docs::AbstractVector{<:AbstractString},
        postprocess::F = identity; verbose::Bool = true,
        api_key::String = "",
        model::String = MODEL_EMBEDDING,
        kwargs...) where {F <: Function}
    ##
    global MODEL_ALIASES
    ## Find the unique ID for the model alias provided
    model_id = get(MODEL_ALIASES, model, model)
    ## Send each document individually (no parallelism)
    messages = [aiembed(prompt_schema,
                    doc,
                    postprocess;
                    verbose = false,
                    api_key,
                    model = model_id,
                    kwargs...)
                for doc in docs]
    ## Aggregate results
    msg = DataMessage(;
        content = mapreduce(x -> x.content, hcat, messages),
        status = mapreduce(x -> x.status, max, messages),
        cost = mapreduce(x -> x.cost, +, messages),
        tokens = (0, 0),# not tracked for embeddings in Ollama
        elapsed = sum(x -> x.elapsed, messages))
    ## Reporting
    verbose && @info _report_stats(msg, model_id)

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
function aitools(prompt_schema::AbstractManagedSchema, prompt::ALLOWED_PROMPT_TYPE;
        kwargs...)
    error("Managed schema does not support aitools. Please use OpenAISchema instead.")
end
