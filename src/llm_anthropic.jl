## Anthropic API
#
## Schema dedicated to Claude models.
## See more information [here](https://docs.anthropic.com/claude/reference/getting-started-with-the-api).
##
## Rendering of converation history for the Anthropic API
"""
    render(schema::AbstractAnthropicSchema,
        messages::Vector{<:AbstractMessage};
        aiprefill::Union{Nothing, AbstractString} = nothing,
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        no_system_message::Bool = false,
        tools::Vector{<:Dict{String, <:Any}} = Dict{String, Any}[],
        cache::Union{Nothing, Symbol} = nothing,
        kwargs...)

Builds a history of the conversation to provide the prompt to the API. All unspecified kwargs are passed as replacements such that `{{key}}=>value` in the template.

# Keyword Arguments
- `aiprefill`: A string to be used as a prefill for the AI response. This steer the AI response in a certain direction (and potentially save output tokens).
- `conversation`: Past conversation to be included in the beginning of the prompt (for continued conversations).
- `no_system_message`: If `true`, do not include the default system message in the conversation history OR convert any provided system message to a user message.
- `tools`: A list of tools to be used in the conversation. Added to the end of the system prompt to enforce its use.
- `cache`: A symbol representing the caching strategy to be used. Currently only `nothing` (no caching), `:system`, `:tools`,`:last` and `:all` are supported.
"""
function render(schema::AbstractAnthropicSchema,
        messages::Vector{<:AbstractMessage};
        aiprefill::Union{Nothing, AbstractString} = nothing,
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        no_system_message::Bool = false,
        tools::Vector{<:Dict{String, <:Any}} = Dict{String, Any}[],
        cache::Union{Nothing, Symbol} = nothing,
        kwargs...)
    ## 
    @assert count(issystemmessage, messages)<=1 "AbstractAnthropicSchema only supports at most 1 System message"
    @assert (isnothing(cache)||cache in [:system, :tools, :last, :all]) "Currently only `:system`, `:tools`, `:last`, `:all` are supported for Anthropic Prompt Caching"

    system = nothing

    ## First pass: keep the message types but make the replacements provided in `kwargs`
    messages_replaced = render(
        NoSchema(), messages; conversation, no_system_message, kwargs...)

    ## Second pass: convert to the message-based schema
    conversation = Dict{String, Any}[]

    for msg in messages_replaced
        if msg isa SystemMessage
            system = msg.content
        elseif msg isa UserMessage || msg isa AIMessage
            content = msg.content
            push!(conversation,
                Dict("role" => role4render(schema, msg),
                    "content" => [Dict{String, Any}("type" => "text", "text" => content)]))
        elseif msg isa UserMessageWithImages
            error("AbstractAnthropicSchema does not yet support UserMessageWithImages. Please use OpenAISchema instead.")
        end
        # Note: Ignores any DataMessage or other types
    end

    ## Add Tool definitions to the System Prompt
    if !isempty(tools)
        length(tools) > 1 && @warn "Multiple tools provided. Using the first one only."
        ANTHROPIC_TOOL_SUFFIX = "Use the $(tools[1]["name"]) tool in your response."
        ## Add to system message
        if isnothing(system)
            system = ANTHROPIC_TOOL_SUFFIX
        else
            system *= "\n\n" * ANTHROPIC_TOOL_SUFFIX
        end
    end

    ## Apply cache for last message
    is_valid_conversation = length(conversation) > 0 &&
                            haskey(conversation[end], "content") &&
                            length(conversation[end]["content"]) > 0
    if is_valid_conversation && (cache == :last || cache == :all)
        conversation[end]["content"][end]["cache_control"] = Dict("type" => "ephemeral")
    end
    if !no_system_message && !isnothing(system) && (cache == :system || cache == :all)
        ## Apply cache for system message
        system = [Dict("type" => "text", "text" => system,
            "cache_control" => Dict("type" => "ephemeral"))]
    end

    ## Sense check
    @assert !isempty(conversation) "AbstractAnthropicSchema requires at least 1 User message, ie, no `prompt` provided!"

    ## Apply prefilling of responses
    if !isnothing(aiprefill) && !isempty(aiprefill)
        aimsg = AIMessage(aiprefill)
        push!(conversation,
            Dict("role" => role4render(schema, aimsg),
                "content" => [Dict{String, Any}("type" => "text", "text" => aiprefill)]))
    end
    return (; system, conversation)
end

"""
    anthropic_extra_headers

Adds API version and beta headers to the request.

# Kwargs / Beta headers
- `has_tools`: Enables tools in the conversation.
- `has_cache`: Enables prompt caching.
- `has_long_output`: Enables long outputs (up to 8K tokens) with Anthropic's Sonnet 3.5.
"""
function anthropic_extra_headers(;
        has_tools = false, has_cache = false, has_long_output = false)
    extra_headers = ["anthropic-version" => "2023-06-01"]
    beta_headers = String[]
    if has_tools
        push!(beta_headers, "tools-2024-04-04")
    end
    if has_cache
        push!(beta_headers, "prompt-caching-2024-07-31")
    end
    if has_long_output
        push!(beta_headers, "max-tokens-3-5-sonnet-2024-07-15")
    end
    if !isempty(beta_headers)
        extra_headers = [extra_headers..., "anthropic-beta" => join(beta_headers, ",")]
    end
    return extra_headers
end

## Model-calling
"""
    anthropic_api(
        prompt_schema::AbstractAnthropicSchema,
        messages::Vector{<:AbstractDict{String, <:Any}} = Vector{Dict{String, Any}}();
        api_key::AbstractString = ANTHROPIC_API_KEY,
        system::Union{Nothing, AbstractString, AbstractVector{<:AbstractDict}} = nothing,
        endpoint::String = "messages",
        max_tokens::Int = 2048,
        model::String = "claude-3-haiku-20240307", http_kwargs::NamedTuple = NamedTuple(),
        stream::Bool = false,
        url::String = "https://api.anthropic.com/v1",
        cache::Union{Nothing, Symbol} = nothing,
        kwargs...)

Simple wrapper for a call to Anthropic API.

# Keyword Arguments
- `prompt_schema`: Defines which prompt template should be applied.
- `messages`: a vector of `AbstractMessage` to send to the model
- `system`: An optional string representing the system message for the AI conversation. If not provided, a default message will be used.
- `endpoint`: The API endpoint to call, only "messages" are currently supported. Defaults to "messages".
- `model`: A string representing the model to use for generating the response. Can be an alias corresponding to a model ID defined in `MODEL_ALIASES`.
- `max_tokens`: The maximum number of tokens to generate. Defaults to 2048.
- `http_kwargs::NamedTuple`: Additional keyword arguments for the HTTP request. Defaults to empty `NamedTuple`.
- `stream`: A boolean indicating whether to stream the response. Defaults to `false`.
- `url`: The URL of the Ollama API. Defaults to "localhost".
- `cache`: A symbol representing the caching strategy to be used. Currently only `nothing` (no caching), `:system`, `:tools`,`:last` and `:all` are supported.
- `kwargs`: Prompt variables to be used to fill the prompt/template
"""
function anthropic_api(
        prompt_schema::AbstractAnthropicSchema,
        messages::Vector{<:AbstractDict{String, <:Any}} = Vector{Dict{String, Any}}();
        api_key::AbstractString = ANTHROPIC_API_KEY,
        system::Union{Nothing, AbstractString, AbstractVector{<:AbstractDict}} = nothing,
        endpoint::String = "messages",
        max_tokens::Int = 2048,
        model::String = "claude-3-haiku-20240307", http_kwargs::NamedTuple = NamedTuple(),
        stream::Bool = false,
        streamcallback::Any = nothing,
        url::String = "https://api.anthropic.com/v1",
        cache::Union{Nothing, Symbol} = nothing,
        kwargs...)
    @assert endpoint in ["messages"] "Only 'messages' endpoint is supported."
    ##
    body = Dict(:model => model, :max_tokens => max_tokens,
        :stream => stream, :messages => messages, kwargs...)
    ## provide system message
    if !isnothing(system)
        body[:system] = system
    end
    ## Build the headers
    extra_headers = anthropic_extra_headers(;
        has_tools = haskey(kwargs, :tools), has_cache = !isnothing(cache),
        has_long_output = (max_tokens > 4096 && model in ["claude-3-5-sonnet-20240620"]))
    headers = auth_header(
        api_key; bearer = false, x_api_key = true,
        extra_headers)
    api_url = string(url, "/", endpoint)
    if !isnothing(streamcallback)
        ## Route to the streaming function
        streamcallback, new_kwargs = configure_callback!(
            streamcallback, prompt_schema; kwargs...)
        input_buf = IOBuffer()
        JSON3.write(input_buf, merge(NamedTuple(body), new_kwargs))
        resp = streamed_request!(
            streamcallback, api_url, headers, input_buf; http_kwargs...)
    else
        resp = HTTP.post(api_url, headers, JSON3.write(body); http_kwargs...)
    end
    body = JSON3.read(resp.body)
    return (; response = body, resp.status)
end
# For testing
function anthropic_api(prompt_schema::TestEchoAnthropicSchema,
        messages::Vector{<:AbstractDict{String, <:Any}} = Vector{Dict{String, Any}}();
        api_key::AbstractString = ANTHROPIC_API_KEY,
        system::Union{Nothing, AbstractString, AbstractVector{<:AbstractDict}} = nothing,
        endpoint::String = "messages",
        cache::Union{Nothing, Symbol} = nothing,
        model::String = "claude-3-haiku-20240307", kwargs...)
    prompt_schema.model_id = model
    prompt_schema.inputs = (; system, messages = copy(messages))
    return prompt_schema
end

## User-Facing API
"""
    aigenerate(prompt_schema::AbstractAnthropicSchema, prompt::ALLOWED_PROMPT_TYPE; verbose::Bool = true,
        api_key::String = ANTHROPIC_API_KEY, model::String = MODEL_CHAT,
        return_all::Bool = false, dry_run::Bool = false,
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        streamcallback::Any = nothing,
        no_system_message::Bool = false,
        aiprefill::Union{Nothing, AbstractString} = nothing,
        http_kwargs::NamedTuple = NamedTuple(), api_kwargs::NamedTuple = NamedTuple(),
        cache::Union{Nothing, Symbol} = nothing,
        kwargs...)

Generate an AI response based on a given prompt using the Anthropic API.

# Arguments
- `prompt_schema`: An optional object to specify which prompt template should be applied (Default to `PROMPT_SCHEMA = OpenAISchema` not `AbstractAnthropicSchema`)
- `prompt`: Can be a string representing the prompt for the AI conversation, a `UserMessage`, a vector of `AbstractMessage` or an `AITemplate`
- `verbose`: A boolean indicating whether to print additional information.
- `api_key`: API key for the Antropic API. Defaults to `ANTHROPIC_API_KEY` (loaded via `ENV["ANTHROPIC_API_KEY"]`).
- `model`: A string representing the model to use for generating the response. Can be an alias corresponding to a model ID defined in `MODEL_ALIASES`, eg, "claudeh".
- `return_all::Bool=false`: If `true`, returns the entire conversation history, otherwise returns only the last message (the `AIMessage`).
- `dry_run::Bool=false`: If `true`, skips sending the messages to the model (for debugging, often used with `return_all=true`).
- `conversation::AbstractVector{<:AbstractMessage}=[]`: Not allowed for this schema. Provided only for compatibility.
- `streamcallback::Any`: A callback function to handle streaming responses. Can be simply `stdout` or `StreamCallback` object. See `?StreamCallback` for details.
  Note: We configure the `StreamCallback` (and necessary `api_kwargs`) for you, unless you specify the `flavor`. See `?configure_callback!` for details.
- `no_system_message::Bool=false`: If `true`, do not include the default system message in the conversation history OR convert any provided system message to a user message.
- `aiprefill::Union{Nothing, AbstractString}`: A string to be used as a prefill for the AI response. This steer the AI response in a certain direction (and potentially save output tokens). It MUST NOT end with a trailing with space. Useful for JSON formatting.
- `http_kwargs::NamedTuple`: Additional keyword arguments for the HTTP request. Defaults to empty `NamedTuple`.
- `api_kwargs::NamedTuple`: Additional keyword arguments for the Ollama API. Defaults to an empty `NamedTuple`.
    - `max_tokens::Int`: The maximum number of tokens to generate. Defaults to 2048, because it's a required parameter for the API.
- `cache`: A symbol indicating whether to use caching for the prompt. Supported values are `nothing` (no caching), `:system`, `:tools`, `:last` and `:all`. Note that COST estimate will be wrong (ignores the caching).
    - `:system`: Caches the system message
    - `:tools`: Caches the tool definitions (and everything before them)
    - `:last`: Caches the last message in the conversation (and everything before it)
    - `:all`: Cache trigger points are inserted in all of the above places (ie, higher likelyhood of cache hit, but also slightly higher cost)
- `kwargs`: Prompt variables to be used to fill the prompt/template

Note: At the moment, the cache is only allowed for prompt segments over 1024 tokens (in some cases, over 2048 tokens). You'll get an error if you try to cache short prompts.

# Returns
- `msg`: An `AIMessage` object representing the generated AI message, including the content, status, tokens, and elapsed time.
 Use `msg.content` to access the extracted string.

See also: `ai_str`, `aai_str`

# Example

Simple hello world to test the API:
```julia
const PT = PromptingTools
schema = PT.AnthropicSchema() # We need to explicit if we want Anthropic, otherwise OpenAISchema is the default

msg = aigenerate(schema, "Say hi!"; model="claudeh") #claudeh is the model alias for Claude 3 Haiku, fast and cheap model
[ Info: Tokens: 21 @ Cost: \$0.0 in 0.6 seconds
AIMessage("Hello!")
```

`msg` is an `AIMessage` object. Access the generated string via `content` property:
```julia
typeof(msg) # AIMessage{SubString{String}}
propertynames(msg) # (:content, :status, :tokens, :elapsed, :cost, :log_prob, :finish_reason, :run_id, :sample_id, :_type)
msg.content # "Hello!
```

Note: We need to be explicit about the schema we want to use. If we don't, it will default to `OpenAISchema` (=`PT.DEFAULT_SCHEMA`)
Alternatively, if you provide a known model name or alias (eg, `claudeh` for Claude 3 Haiku - see `MODEL_REGISTRY`), the schema will be inferred from the model name.

We will use Claude 3 Haiku model for the following examples, so not need to specify the schema. See also "claudeo" and "claudes" for other Claude 3 models.

You can use string interpolation:
```julia
const PT = PromptingTools

a = 1
msg=aigenerate("What is `\$a+\$a`?"; model="claudeh")
msg.content # "The answer to `1+1` is `2`."
```
___
You can provide the whole conversation or more intricate prompts as a `Vector{AbstractMessage}`. Claude models are good at completeling conversations that ended with an `AIMessage` (they just continue where it left off):

```julia
const PT = PromptingTools

conversation = [
    PT.SystemMessage("You're master Yoda from Star Wars trying to help the user become a Yedi."),
    PT.UserMessage("I have feelings for my iPhone. What should I do?"),
    PT.AIMessage("Hmm, strong the attachment is,")]

msg = aigenerate(conversation; model="claudeh")
AIMessage("I sense. But unhealthy it may be. Your iPhone, a tool it is, not a living being. Feelings of affection, understandable they are, <continues>")
```

Example of streaming:
```julia
# Simplest usage, just provide where to steam the text
msg = aigenerate("Count from 1 to 100."; streamcallback = stdout, model="claudeh")

streamcallback = PT.StreamCallback()
msg = aigenerate("Count from 1 to 100."; streamcallback, model="claudeh")
# this allows you to inspect each chunk with `streamcallback.chunks`. You can them empty it with `empty!(streamcallback)` in between repeated calls.

# Get verbose output with details of each chunk
streamcallback = PT.StreamCallback(; verbose=true, throw_on_error=true)
msg = aigenerate("Count from 1 to 10."; streamcallback, model="claudeh")
```

Note: Streaming support is only for Anthropic models and it doesn't yet support tool calling and a few other features (logprobs, refusals, etc.)

You can also provide a prefill for the AI response to steer the response in a certain direction (eg, formatting, style):
```julia
msg = aigenerate("Sum up 1 to 100."; aiprefill = "I'd be happy to answer in one number without any additional text. The answer is:", model="claudeh")
```
Note: It MUST NOT end with a trailing with space. You'll get an API error if you do.

"""
function aigenerate(
        prompt_schema::AbstractAnthropicSchema, prompt::ALLOWED_PROMPT_TYPE;
        verbose::Bool = true,
        api_key::String = ANTHROPIC_API_KEY,
        model::String = MODEL_CHAT,
        return_all::Bool = false, dry_run::Bool = false,
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        streamcallback::Any = nothing,
        no_system_message::Bool = false,
        aiprefill::Union{Nothing, AbstractString} = nothing,
        http_kwargs::NamedTuple = NamedTuple(), api_kwargs::NamedTuple = NamedTuple(),
        cache::Union{Nothing, Symbol} = nothing,
        kwargs...)
    ##
    global MODEL_ALIASES
    @assert (isnothing(cache)||cache in [:system, :tools, :last, :all]) "Currently only `:system`, `:tools`, `:last` and `:all` are supported for Anthropic Prompt Caching"
    @assert (isnothing(aiprefill)||!isempty(strip(aiprefill))) "`aiprefill` must not be empty`"
    ## Find the unique ID for the model alias provided
    model_id = get(MODEL_ALIASES, model, model)
    conv_rendered = render(
        prompt_schema, prompt; no_system_message, aiprefill, conversation, cache, kwargs...)

    if !dry_run
        @info conv_rendered.conversation
        time = @elapsed resp = anthropic_api(
            prompt_schema, conv_rendered.conversation; api_key,
            conv_rendered.system, endpoint = "messages", model = model_id, streamcallback, http_kwargs, cache,
            api_kwargs...)
        tokens_prompt = get(resp.response[:usage], :input_tokens, 0)
        tokens_completion = get(resp.response[:usage], :output_tokens, 0)
        content = mapreduce(x -> get(x, :text, ""), *, resp.response[:content]) |> strip
        ## add aiprefill to the content
        if !isnothing(aiprefill) && !isempty(aiprefill)
            content = aiprefill * content
            ## remove the prefill from the end of the conversation
            pop!(conv_rendered.conversation)
        end
        ## Build metadata
        extras = Dict{Symbol, Any}()
        haskey(resp.response[:usage], :cache_creation_input_tokens) &&
            (extras[:cache_creation_input_tokens] = resp.response[:usage][:cache_creation_input_tokens])
        haskey(resp.response[:usage], :cache_read_input_tokens) &&
            (extras[:cache_read_input_tokens] = resp.response[:usage][:cache_read_input_tokens])
        ## Build the message
        msg = AIMessage(; content,
            status = Int(resp.status),
            cost = call_cost(tokens_prompt, tokens_completion, model_id),
            finish_reason = get(resp.response, :stop_reason, nothing),
            tokens = (tokens_prompt, tokens_completion),
            extras,
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
        no_system_message,
        kwargs...)
    return output
end

"""
    aiextract(prompt_schema::AbstractAnthropicSchema, prompt::ALLOWED_PROMPT_TYPE;
        return_type::Union{Type, Vector},
        verbose::Bool = true,
        api_key::String = ANTHROPIC_API_KEY,
        model::String = MODEL_CHAT,
        return_all::Bool = false, dry_run::Bool = false,
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        http_kwargs::NamedTuple = (retry_non_idempotent = true,
            retries = 5,
            readtimeout = 120), api_kwargs::NamedTuple = NamedTuple(),
        cache::Union{Nothing, Symbol} = nothing,
        kwargs...)

Extract required information (defined by a struct **`return_type`**) from the provided prompt by leveraging Anthropic's function calling mode.

This is a perfect solution for extracting structured information from text (eg, extract organization names in news articles, etc.).

Read best practics [here](https://docs.anthropic.com/claude/docs/tool-use#tool-use-best-practices-and-limitations).

It's effectively a light wrapper around `aigenerate` call, which requires additional keyword argument `return_type` to be provided
 and will enforce the model outputs to adhere to it.

# Arguments
- `prompt_schema`: An optional object to specify which prompt template should be applied (Default to `PROMPT_SCHEMA = OpenAISchema`)
- `prompt`: Can be a string representing the prompt for the AI conversation, a `UserMessage`, a vector of `AbstractMessage` or an `AITemplate`
- `return_type`: A **struct** TYPE representing the the information we want to extract. Do not provide a struct instance, only the type.
  If the struct has a docstring, it will be provided to the model as well. It's used to enforce structured model outputs or provide more information.
  Alternatively, you can provide a vector of field names and their types (see `?generate_struct` function for the syntax).
- `verbose`: A boolean indicating whether to print additional information.
- `api_key`: A string representing the API key for accessing the OpenAI API.
- `model`: A string representing the model to use for generating the response. Can be an alias corresponding to a model ID defined in `MODEL_ALIASES`.
- `return_all::Bool=false`: If `true`, returns the entire conversation history, otherwise returns only the last message (the `AIMessage`).
- `dry_run::Bool=false`: If `true`, skips sending the messages to the model (for debugging, often used with `return_all=true`).
- `conversation`: An optional vector of `AbstractMessage` objects representing the conversation history. If not provided, it is initialized as an empty vector.
- `http_kwargs`: A named tuple of HTTP keyword arguments.
- `api_kwargs`: A named tuple of API keyword arguments. 
- `cache`: A symbol indicating whether to use caching for the prompt. Supported values are `nothing` (no caching), `:system`, `:tools`, `:last` and `:all`. Note that COST estimate will be wrong (ignores the caching).
    - `:system`: Caches the system message
    - `:tools`: Caches the tool definitions (and everything before them)
    - `:last`: Caches the last message in the conversation (and everything before it)
    - `:all`: Cache trigger points are inserted in all of the above places (ie, higher likelyhood of cache hit, but also slightly higher cost)
- `kwargs`: Prompt variables to be used to fill the prompt/template

Note: At the moment, the cache is only allowed for prompt segments over 1024 tokens (in some cases, over 2048 tokens). You'll get an error if you try to cache short prompts.

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
msg = aiextract("James is 30, weighs 80kg. He's 180cm tall."; model="claudeh", return_type=MyMeasurement)
# PromptingTools.DataMessage(MyMeasurement)
msg.content
# MyMeasurement(30, 180, 80.0)
```

The fields that allow `Nothing` are marked as optional in the schema:
```
msg = aiextract("James is 30."; model="claudeh", return_type=MyMeasurement)
# MyMeasurement(30, nothing, nothing)
```

If there are multiple items you want to extract, define a wrapper struct to get a Vector of `MyMeasurement`:
```
struct ManyMeasurements
    measurements::Vector{MyMeasurement}
end

msg = aiextract("James is 30, weighs 80kg. He's 180cm tall. Then Jack is 19 but really tall - over 190!"; model="claudeh", return_type=ManyMeasurements)

msg.content.measurements
# 2-element Vector{MyMeasurement}:
#  MyMeasurement(30, 180, 80.0)
#  MyMeasurement(19, 190, nothing)
```

Or you can use the convenience wrapper `ItemsExtract` to extract multiple measurements (zero, one or more):
```julia
using PromptingTools: ItemsExtract

return_type = ItemsExtract{MyMeasurement}
msg = aiextract("James is 30, weighs 80kg. He's 180cm tall. Then Jack is 19 but really tall - over 190!"; model="claudeh", return_type)

msg.content.items # see the extracted items
```

Or if you want your extraction to fail gracefully when data isn't found, use `MaybeExtract{T}` wrapper
 (this trick is inspired by the Instructor package!):
```
using PromptingTools: MaybeExtract

return_type = MaybeExtract{MyMeasurement}
# Effectively the same as:
# struct MaybeExtract{T}
#     result::Union{T, Nothing} // The result of the extraction
#     error::Bool // true if a result is found, false otherwise
#     message::Union{Nothing, String} // Only present if no result is found, should be short and concise
# end

# If LLM extraction fails, it will return a Dict with `error` and `message` fields instead of the result!
msg = aiextract("Extract measurements from the text: I am giraffe"; model="claudeo", return_type)
msg.content
# Output: MaybeExtract{MyMeasurement}(nothing, true, "I'm sorry, but your input of "I am giraffe" does not contain any information about a person's age, height or weight measurements that I can extract. To use this tool, please provide a statement that includes at least the person's age, and optionally their height in inches and weight in pounds. Without that information, I am unable to extract the requested measurements.")
```
That way, you can handle the error gracefully and get a reason why extraction failed (in `msg.content.message`).

However, this can fail with weaker models like `claudeh`, so we can apply some of our prompt templates with embedding reasoning step:
```julia
msg = aiextract(:ExtractDataCoTXML; data="I am giraffe", model="claudeh", return_type)
msg.content
# Output: MaybeExtract{MyMeasurement}(nothing, true, "The provided data does not contain the expected information about a person's age, height, and weight.")
```
Note that when using a prompt template, we provide `data` for the extraction as the corresponding placeholder (see `aitemplates("extract")` for documentation of this template).

Note that the error message refers to a giraffe not being a human, 
 because in our `MyMeasurement` docstring, we said that it's for people!

Example of using a vector of field names with `aiextract`
```julia
fields = [:location, :temperature => Float64, :condition => String]
msg = aiextract("Extract the following information from the text: location, temperature, condition. Text: The weather in New York is sunny and 72.5 degrees Fahrenheit."; 
return_type = fields, model="claudeh")
```

Or simply call `aiextract("some text"; return_type = [:reasoning,:answer], model="claudeh")` to get a Chain of Thought reasoning for extraction task.

It will be returned it a new generated type, which you can check with `PromptingTools.isextracted(msg.content) == true` to confirm the data has been extracted correctly.

This new syntax also allows you to provide field-level descriptions, which will be passed to the model.
```julia
fields_with_descriptions = [
    :location,
    :temperature => Float64,
    :temperature__description => "Temperature in degrees Fahrenheit",
    :condition => String,
    :condition__description => "Current weather condition (e.g., sunny, rainy, cloudy)"
]
msg = aiextract("The weather in New York is sunny and 72.5 degrees Fahrenheit."; return_type = fields_with_descriptions, model="claudeh")
```
"""
function aiextract(prompt_schema::AbstractAnthropicSchema, prompt::ALLOWED_PROMPT_TYPE;
        return_type::Union{Type, Vector},
        verbose::Bool = true,
        api_key::String = ANTHROPIC_API_KEY,
        model::String = MODEL_CHAT,
        return_all::Bool = false, dry_run::Bool = false,
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        http_kwargs::NamedTuple = (retry_non_idempotent = true,
            retries = 5,
            readtimeout = 120), api_kwargs::NamedTuple = NamedTuple(),
        cache::Union{Nothing, Symbol} = nothing,
        kwargs...)
    ##
    global MODEL_ALIASES
    @assert (isnothing(cache)||cache in [:system, :tools, :last, :all]) "Currently only `:system`, `:tools`, `:last` and `:all` are supported for Anthropic Prompt Caching"

    ## Find the unique ID for the model alias provided
    model_id = get(MODEL_ALIASES, model, model)

    ## Tools definition
    sig, datastructtype = function_call_signature(return_type; max_description_length = 100)
    tools = [Dict("name" => sig["name"], "description" => get(sig, "description", ""),
        "input_schema" => sig["parameters"])]
    ## update tools to use caching
    (cache == :tools || cache == :all) &&
        (tools[end]["cache_control"] = Dict("type" => "ephemeral"))

    ## Add the function call stopping sequence to the api_kwargs
    api_kwargs = merge(api_kwargs, (; tools))

    ## We provide the tool description to the rendering engine
    conv_rendered = render(prompt_schema, prompt; tools, conversation, cache, kwargs...)

    if !dry_run
        time = @elapsed resp = anthropic_api(
            prompt_schema, conv_rendered.conversation; api_key,
            conv_rendered.system, endpoint = "messages", model = model_id, cache, http_kwargs,
            api_kwargs...)
        tokens_prompt = get(resp.response[:usage], :input_tokens, 0)
        tokens_completion = get(resp.response[:usage], :output_tokens, 0)
        finish_reason = get(resp.response, :stop_reason, nothing)
        content = if finish_reason == "tool_use"
            contents = filter(x -> x[:type] == "tool_use", resp.response[:content])
            length(contents) > 1 &&
                @warn "Multiple tool_use found in the response. Using the first one."
            ## parse it into object
            arguments = JSON3.write(contents[1][:input])
            try
                Base.invokelatest(JSON3.read, arguments, datastructtype)
            catch e
                @warn "There was an error parsing the response: $e. Using the raw response instead."
                JSON3.read(arguments) |> copy
            end
        else
            ## fallback, return text
            @warn "No tool_use found in the response. Returning the raw text instead."
            mapreduce(x -> get(x, :text, ""), *, resp.response[:content]) |> strip
        end
        ## Build metadata
        extras = Dict{Symbol, Any}()
        haskey(resp.response[:usage], :cache_creation_input_tokens) &&
            (extras[:cache_creation_input_tokens] = resp.response[:usage][:cache_creation_input_tokens])
        haskey(resp.response[:usage], :cache_read_input_tokens) &&
            (extras[:cache_read_input_tokens] = resp.response[:usage][:cache_read_input_tokens])
        ## Build data message
        msg = DataMessage(; content,
            status = Int(resp.status),
            cost = call_cost(tokens_prompt, tokens_completion, model_id),
            finish_reason,
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

function aiembed(prompt_schema::AbstractAnthropicSchema, prompt::ALLOWED_PROMPT_TYPE;
        kwargs...)
    error("Anthropic schema does not yet support aiembed. Please use OpenAISchema instead.")
end
function aiclassify(prompt_schema::AbstractAnthropicSchema, prompt::ALLOWED_PROMPT_TYPE;
        kwargs...)
    error("Anthropic schema does not yet support aiclassify. Please use OpenAISchema instead.")
end
function aiscan(prompt_schema::AbstractAnthropicSchema, prompt::ALLOWED_PROMPT_TYPE;
        kwargs...)
    error("Anthropic schema does not yet support aiscan. Please use OpenAISchema instead.")
end
function aiimage(prompt_schema::AbstractAnthropicSchema, prompt::ALLOWED_PROMPT_TYPE;
        kwargs...)
    error("Anthropic schema does not yet support aiimage. Please use OpenAISchema instead.")
end
