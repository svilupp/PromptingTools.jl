## Anthropic API
#
## Schema dedicated to Claude models.
## See more information [here](https://docs.anthropic.com/claude/reference/getting-started-with-the-api).
##
## Rendering of converation history for the Anthropic API
"""
    render(schema::AbstractAnthropicSchema,
        messages::Vector{<:AbstractMessage};
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        kwargs...)

Builds a history of the conversation to provide the prompt to the API. All unspecified kwargs are passed as replacements such that `{{key}}=>value` in the template.

# Keyword Arguments
- `conversation`: Past conversation to be included in the beginning of the prompt (for continued conversations).
"""
function render(schema::AbstractAnthropicSchema,
        messages::Vector{<:AbstractMessage};
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        kwargs...)
    ## 
    @assert count(issystemmessage, messages)<=1 "AbstractAnthropicSchema only supports at most 1 System message"

    system = nothing

    ## First pass: keep the message types but make the replacements provided in `kwargs`
    messages_replaced = render(NoSchema(), messages; conversation, kwargs...)

    ## Second pass: convert to the message-based schema
    conversation = Dict{String, Any}[]

    for msg in messages_replaced
        role = if msg isa UserMessage || msg isa UserMessageWithImages
            "user"
        elseif msg isa AIMessage
            "assistant"
        end

        if msg isa SystemMessage
            system = msg.content
        elseif msg isa UserMessage || msg isa AIMessage
            content = msg.content
            push!(conversation, Dict("role" => role, "content" => content))
        elseif msg isa UserMessageWithImages
            error("AbstractAnthropicSchema does not yet support UserMessageWithImages. Please use OpenAISchema instead.")
        end
        # Note: Ignores any DataMessage or other types
    end
    ## Sense check
    @assert !isempty(conversation) "AbstractAnthropicSchema requires at least 1 User message, ie, no `prompt` provided!"

    return (; system, conversation)
end

## Model-calling
"""
    anthropic_api(prompt_schema::AbstractAnthropicSchema,
        messages::Vector{<:AbstractMessage} = AbstractMessage[];
        prompt::Union{AbstractString, Nothing} = nothing;
        system::Union{Nothing, AbstractString} = nothing,
        endpoint::String = "generate",
        model::String = "llama2", http_kwargs::NamedTuple = NamedTuple(),
        stream::Bool = false,
        url::String = "localhost", port::Int = 11434,
        kwargs...)

Simple wrapper for a call to Ollama API.

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
- `kwargs`: Prompt variables to be used to fill the prompt/template
"""
function anthropic_api(
        prompt_schema::AbstractAnthropicSchema,
        messages::Vector{<:AbstractDict{String, <:Any}} = Vector{Dict{String, Any}}();
        api_key::AbstractString = ANTHROPIC_API_KEY,
        system::Union{Nothing, AbstractString} = nothing,
        endpoint::String = "messages",
        max_tokens::Int = 2048,
        model::String = "claude-3-haiku-20240307", http_kwargs::NamedTuple = NamedTuple(),
        stream::Bool = false,
        url::String = "https://api.anthropic.com/v1",
        kwargs...)
    @assert endpoint in ["messages"] "Only 'messages' endpoint is supported."
    ## 
    body = Dict("model" => model, "max_tokens" => max_tokens,
        "stream" => stream, "messages" => messages, kwargs...)
    ## provide system message
    if !isnothing(system)
        body["system"] = system
    end
    ## 
    headers = auth_header(
        api_key; bearer = false, x_api_key = true,
        extra_headers = ["anthropic-version" => "2023-06-01"])
    api_url = string(url, "/", endpoint)
    resp = HTTP.post(api_url, headers, JSON3.write(body); http_kwargs...)
    body = JSON3.read(resp.body)
    return (; response = body, resp.status)
end
# For testing
function anthropic_api(prompt_schema::TestEchoAnthropicSchema,
        messages::Vector{<:AbstractDict{String, <:Any}} = Vector{Dict{String, Any}}();
        api_key::AbstractString = ANTHROPIC_API_KEY,
        system::Union{Nothing, AbstractString} = nothing,
        endpoint::String = "messages",
        model::String = "claude-3-haiku-20240307", kwargs...)
    prompt_schema.model_id = model
    prompt_schema.inputs = (; system, messages)
    return prompt_schema
end

## User-Facing API
"""
    aigenerate(prompt_schema::AbstractAnthropicSchema, prompt::ALLOWED_PROMPT_TYPE; verbose::Bool = true,
        api_key::String = ANTHROPIC_API_KEY, model::String = MODEL_CHAT,
        return_all::Bool = false, dry_run::Bool = false,
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        http_kwargs::NamedTuple = NamedTuple(), api_kwargs::NamedTuple = NamedTuple(),
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
- `http_kwargs::NamedTuple`: Additional keyword arguments for the HTTP request. Defaults to empty `NamedTuple`.
- `api_kwargs::NamedTuple`: Additional keyword arguments for the Ollama API. Defaults to an empty `NamedTuple`.
    - `max_tokens::Int`: The maximum number of tokens to generate. Defaults to 2048, because it's a required parameter for the API.
- `kwargs`: Prompt variables to be used to fill the prompt/template

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

"""
function aigenerate(
        prompt_schema::AbstractAnthropicSchema, prompt::ALLOWED_PROMPT_TYPE;
        verbose::Bool = true,
        api_key::String = ANTHROPIC_API_KEY,
        model::String = MODEL_CHAT,
        return_all::Bool = false, dry_run::Bool = false,
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        http_kwargs::NamedTuple = NamedTuple(), api_kwargs::NamedTuple = NamedTuple(),
        kwargs...)
    ##
    global MODEL_ALIASES
    ## Find the unique ID for the model alias provided
    model_id = get(MODEL_ALIASES, model, model)
    conv_rendered = render(prompt_schema, prompt; conversation, kwargs...)

    if !dry_run
        time = @elapsed resp = anthropic_api(
            prompt_schema, conv_rendered.conversation; api_key,
            conv_rendered.system, endpoint = "messages", model = model_id, http_kwargs,
            api_kwargs...)
        tokens_prompt = get(resp.response[:usage], :input_tokens, 0)
        tokens_completion = get(resp.response[:usage], :output_tokens, 0)
        content = mapreduce(x -> get(x, :text, ""), *, resp.response[:content]) |> strip
        msg = AIMessage(; content,
            status = Int(resp.status),
            cost = call_cost(tokens_prompt, tokens_completion, model_id),
            finish_reason = get(resp.response, :stop_reason, nothing),
            tokens = (tokens_prompt, tokens_completion),
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

function aiembed(prompt_schema::AbstractAnthropicSchema, prompt::ALLOWED_PROMPT_TYPE;
        kwargs...)
    error("Anthropic schema does not yet support aiembed. Please use OpenAISchema instead.")
end
function aiclassify(prompt_schema::AbstractAnthropicSchema, prompt::ALLOWED_PROMPT_TYPE;
        kwargs...)
    error("Anthropic schema does not yet support aiclassify. Please use OpenAISchema instead.")
end
function aiextract(prompt_schema::AbstractAnthropicSchema, prompt::ALLOWED_PROMPT_TYPE;
        kwargs...)
    error("Anthropic schema does not yet support aiextract. Please use OpenAISchema instead.")
end
function aiscan(prompt_schema::AbstractAnthropicSchema, prompt::ALLOWED_PROMPT_TYPE;
        kwargs...)
    error("Anthropic schema does not yet support aiscan. Please use OpenAISchema instead.")
end
