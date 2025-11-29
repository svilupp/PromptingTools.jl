# OpenAI user-facing functions (mostly)
#
# All ai* functions that interface with OpenAI-compatible APIs are defined here
#
# For custom schemas/providers, see llm_openai_schema_defs.jl
#
#

## Helper function for observability metadata extraction
"""
    _extract_openai_extras!(extras::Dict{Symbol, Any}, resp)

Extract observability metadata from OpenAI API response into the extras dict.
Populates provider metadata (model, response_id, system_fingerprint, service_tier)
and detailed usage statistics (cache tokens, reasoning tokens, audio tokens, etc.).
"""
function _extract_openai_extras!(extras::Dict{Symbol, Any}, resp)
    ## Provider metadata for observability (Logfire.jl integration)
    if haskey(resp.response, :model)
        extras[:model] = resp.response[:model]
    end
    if haskey(resp.response, :system_fingerprint) &&
       !isnothing(resp.response[:system_fingerprint])
        extras[:system_fingerprint] = resp.response[:system_fingerprint]
    end
    ## Detailed usage stats (OpenAI caching, reasoning tokens, etc.)
    if haskey(resp.response, :usage)
        response_usage = resp.response[:usage]
        ## Prompt token details
        if haskey(response_usage, :prompt_tokens_details)
            details = response_usage[:prompt_tokens_details]
            extras[:prompt_tokens_details] = details
            ## Unified keys for cross-provider compatibility
            haskey(details, :cached_tokens) &&
                (extras[:cache_read_tokens] = details[:cached_tokens])
            haskey(details, :audio_tokens) &&
                (extras[:audio_input_tokens] = details[:audio_tokens])
        end
        ## Completion token details
        if haskey(response_usage, :completion_tokens_details)
            details = response_usage[:completion_tokens_details]
            extras[:completion_tokens_details] = details
            ## Unified keys for cross-provider compatibility
            haskey(details, :reasoning_tokens) &&
                (extras[:reasoning_tokens] = details[:reasoning_tokens])
            haskey(details, :audio_tokens) &&
                (extras[:audio_output_tokens] = details[:audio_tokens])
            haskey(details, :accepted_prediction_tokens) &&
                (extras[:accepted_prediction_tokens] = details[:accepted_prediction_tokens])
            haskey(details, :rejected_prediction_tokens) &&
                (extras[:rejected_prediction_tokens] = details[:rejected_prediction_tokens])
        end
    end
    ## Response ID for observability
    haskey(resp.response, :id) && (extras[:response_id] = resp.response[:id])
    ## Service tier
    haskey(resp.response, :service_tier) &&
        (extras[:service_tier] = resp.response[:service_tier])
    return extras
end

## Rendering of converation history for the OpenAI API
"""
    render(schema::AbstractOpenAISchema,
        messages::Vector{<:AbstractMessage};
        image_detail::AbstractString = "auto",
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        no_system_message::Bool = false,
        name_user::Union{Nothing, String} = nothing,
        kwargs...)

Builds a history of the conversation to provide the prompt to the API. All unspecified kwargs are passed as replacements such that `{{key}}=>value` in the template.

# Keyword Arguments
- `image_detail`: Only for `UserMessageWithImages`. It represents the level of detail to include for images. Can be `"auto"`, `"high"`, or `"low"`.
- `conversation`: An optional vector of `AbstractMessage` objects representing the conversation history. If not provided, it is initialized as an empty vector.
- `no_system_message`: If `true`, do not include the default system message in the conversation history OR convert any provided system message to a user message.
- `name_user`: No-op for consistency.
"""
function render(schema::AbstractOpenAISchema,
        messages::Vector{<:AbstractMessage};
        image_detail::AbstractString = "auto",
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        no_system_message::Bool = false,
        name_user::Union{Nothing, String} = nothing,
        kwargs...)
    ##
    @assert image_detail in ["auto", "high", "low"] "Image detail must be one of: auto, high, low"

    # Filter out annotation messages before any processing
    messages = filter(!isabstractannotationmessage, messages)

    ## First pass: keep the message types but make the replacements provided in `kwargs`
    messages_replaced = render(
        NoSchema(), messages; conversation, no_system_message, kwargs...)

    ## Second pass: convert to the OpenAI schema
    conversation = Dict{String, Any}[]

    # replace any handlebar variables in the messages
    for msg in messages_replaced
        ## Special case for images
        new_msg = if isusermessagewithimages(msg)
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
            Dict("role" => role4render(schema, msg), "content" => content)
        elseif isaitoolrequest(msg)
            output = Dict{String, Any}(
                "role" => role4render(schema, msg),
                "content" => msg.content)
            if !isempty(msg.tool_calls)
                output["tool_calls"] = [Dict("id" => tool.tool_call_id,
                                            "type" => "function",
                                            "function" => Dict("name" => tool.name,
                                                "arguments" => tool.raw))
                                        for tool in msg.tool_calls]
            end
            output
        elseif istoolmessage(msg)
            content = msg.content isa AbstractString ? msg.content : string(msg.content)
            Dict("role" => role4render(schema, msg), "content" => content,
                "tool_call_id" => msg.tool_call_id)
        elseif isabstractannotationmessage(msg)
            continue
        else
            ## Vanilla assistant message
            Dict("role" => role4render(schema, msg),
                "content" => msg.content)
        end
        ## Add name if it exists
        if hasproperty(msg, :name) && !isnothing(msg.name)
            new_msg["name"] = msg.name
        end
        push!(conversation, new_msg)
    end

    return conversation
end

"""
    render(schema::AbstractOpenAISchema,
        tools::Vector{<:AbstractTool};
        json_mode::Union{Nothing, Bool} = nothing,
        kwargs...)

Renders the tool signatures into the OpenAI format.
"""
function render(schema::AbstractOpenAISchema,
        tools::Vector{<:AbstractTool};
        json_mode::Union{Nothing, Bool} = nothing,
        kwargs...)
    [render(schema, tool; json_mode, kwargs...) for tool in tools]
end
function render(schema::AbstractOpenAISchema,
        tool::AbstractTool;
        json_mode::Union{Nothing, Bool} = nothing,
        kwargs...)
    rendered = Dict(:type => "function",
        :function => Dict(
            :parameters => tool.parameters, :name => tool.name))
    ## Add strict flag
    tool.strict == true && (rendered[:function][:strict] = tool.strict)
    if json_mode == true
        rendered[:function][:schema] = pop!(rendered[:function], :parameters)
    else
        ## Add description if not in JSON mode
        !isnothing(tool.description) &&
            (rendered[:function][:description] = tool.description)
    end
    return rendered
end
function render(schema::AbstractOpenAISchema,
        tool::ToolRef;
        json_mode::Union{Nothing, Bool} = nothing,
        kwargs...)
    throw(ArgumentError("Function `render` is not implemented for the provided schema ($(typeof(schema))) and $(typeof(tool))."))
end

"""
    response_to_message(schema::AbstractOpenAISchema,
        MSG::Type{AIMessage},
        choice,
        resp;
        model_id::AbstractString = "",
        time::Float64 = 0.0,
        run_id::Int = Int(rand(Int32)),
        sample_id::Union{Nothing, Integer} = nothing,
        name_assistant::Union{Nothing, String} = nothing)

Utility to facilitate unwrapping of HTTP response to a message type `MSG` provided for OpenAI-like responses

Note: Extracts `finish_reason` and `log_prob` if available in the response.

# Arguments
- `schema::AbstractOpenAISchema`: The schema for the prompt.
- `MSG::Type{AIMessage}`: The message type to be returned.
- `choice`: The choice from the response (eg, one of the completions).
- `resp`: The response from the OpenAI API.
- `model_id::AbstractString`: The model ID to use for generating the response. Defaults to an empty string.
- `time::Float64`: The elapsed time for the response. Defaults to `0.0`.
- `run_id::Integer`: The run ID for the response. Defaults to a random integer.
- `sample_id::Union{Nothing, Integer}`: The sample ID for the response (if there are multiple completions). Defaults to `nothing`.
- `name_assistant::Union{Nothing, String}`: The name to use for the assistant in the conversation history. Defaults to `nothing`.
"""
function response_to_message(schema::AbstractOpenAISchema,
        MSG::Type{AIMessage},
        choice,
        resp;
        model_id::AbstractString = "",
        time::Float64 = 0.0,
        run_id::Int = Int(rand(Int32)),
        sample_id::Union{Nothing, Integer} = nothing,
        name_assistant::Union{Nothing, String} = nothing)
    ## extract sum log probability
    has_log_prob = haskey(choice, :logprobs) &&
                   !isnothing(get(choice, :logprobs, nothing)) &&
                   haskey(choice[:logprobs], :content) &&
                   !isnothing(choice[:logprobs][:content])
    log_prob = if has_log_prob
        sum([get(c, :logprob, 0.0) for c in choice[:logprobs][:content]])
    else
        nothing
    end
    ## Has reasoning content -- currently only provided by DeepSeek API
    has_reasoning_content = haskey(choice, :message) &&
                            haskey(choice[:message], :reasoning_content)
    reasoning_content = if has_reasoning_content
        choice[:message][:reasoning_content]
    else
        nothing
    end
    # Extract usage information with default values for tokens
    tokens_prompt = 0
    tokens_completion = 0
    # Merge with response usage if available
    if haskey(resp.response, :usage)
        response_usage = resp.response[:usage]
        # Handle both snake_case and camelCase keys
        tokens_prompt = get(response_usage, :prompt_tokens,
            get(response_usage, :promptTokens, 0))
        tokens_completion = get(response_usage, :completion_tokens,
            get(response_usage, :completionTokens, 0))
    end
    ## calculate cost
    cost = call_cost(tokens_prompt, tokens_completion, model_id)
    ## Add extras, usually keys that are provider-specific
    extras = Dict{Symbol, Any}()
    if has_log_prob
        extras[:log_prob] = choice[:logprobs]
    end
    if has_reasoning_content
        extras[:reasoning_content] = reasoning_content
    end
    _extract_openai_extras!(extras, resp)
    ## build AIMessage object
    msg = MSG(;
        content = choice[:message][:content] |> strip,
        status = Int(resp.status),
        name = name_assistant,
        cost,
        run_id,
        sample_id,
        log_prob,
        finish_reason = get(choice, :finish_reason, nothing),
        tokens = (tokens_prompt,
            tokens_completion),
        elapsed = time,
        extras)
end

## User-Facing API
"""
    aigenerate(prompt_schema::AbstractOpenAISchema, prompt::ALLOWED_PROMPT_TYPE;
        verbose::Bool = true,
        api_key::String = "",
        model::String = MODEL_CHAT, return_all::Bool = false, dry_run::Bool = false,
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        streamcallback::Any = nothing,
        no_system_message::Bool = false,
        name_user::Union{Nothing, String} = nothing,
        name_assistant::Union{Nothing, String} = nothing,
        http_kwargs::NamedTuple = (retry_non_idempotent = true,
            retries = 5,
            readtimeout = 120), api_kwargs::NamedTuple = NamedTuple(),
        kwargs...)

Generate an AI response based on a given prompt using the OpenAI API.

# Arguments
- `prompt_schema`: An optional object to specify which prompt template should be applied (Default to `PROMPT_SCHEMA = OpenAISchema`)
- `prompt`: Can be a string representing the prompt for the AI conversation, a `UserMessage`, a vector of `AbstractMessage` or an `AITemplate`
- `verbose`: A boolean indicating whether to print additional information.
- `api_key`: A string representing the API key for accessing the OpenAI API, if not provided, the function will use the `OPENAI_API_KEY` environment variable.
- `model`: A string representing the model to use for generating the response. Can be an alias corresponding to a model ID defined in `MODEL_ALIASES`.
- `return_all::Bool=false`: If `true`, returns the entire conversation history, otherwise returns only the last message (the `AIMessage`).
- `dry_run::Bool=false`: If `true`, skips sending the messages to the model (for debugging, often used with `return_all=true`).
- `conversation`: An optional vector of `AbstractMessage` objects representing the conversation history. If not provided, it is initialized as an empty vector.
- `streamcallback`: A callback function to handle streaming responses. Can be simply `stdout` or a `StreamCallback` object. See `?StreamCallback` for details.
  Note: We configure the `StreamCallback` (and necessary `api_kwargs`) for you, unless you specify the `flavor`. See `?configure_callback!` for details.
- `no_system_message::Bool=false`: If `true`, the default system message is not included in the conversation history. Any existing system message is converted to a `UserMessage`.
- `name_user::Union{Nothing, String} = nothing`: The name to use for the user in the conversation history. Defaults to `nothing`.
- `name_assistant::Union{Nothing, String} = nothing`: The name to use for the assistant in the conversation history. Defaults to `nothing`.
- `http_kwargs`: A named tuple of HTTP keyword arguments.
- `api_kwargs`: A named tuple of API keyword arguments. Useful parameters include:
    - `temperature`: A float representing the temperature for sampling (ie, the amount of "creativity"). Often defaults to `0.7`.
    - `logprobs`: A boolean indicating whether to return log probabilities for each token. Defaults to `false`.
    - `n`: An integer representing the number of completions to generate at once (if supported).
    - `stop`: A vector of strings representing the stop conditions for the conversation. Defaults to an empty vector.
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

Example of streaming:

```julia
# Simplest usage, just provide where to steam the text
msg = aigenerate("Count from 1 to 100."; streamcallback = stdout)

streamcallback = PT.StreamCallback()
msg = aigenerate("Count from 1 to 100."; streamcallback)
# this allows you to inspect each chunk with `streamcallback.chunks`. You can them empty it with `empty!(streamcallback)` in between repeated calls.

# Get verbose output with details of each chunk
streamcallback = PT.StreamCallback(; verbose=true, throw_on_error=true)
msg = aigenerate("Count from 1 to 10."; streamcallback)
```

WARNING: If you provide a `StreamCallback` object, we assume you want to configure everything yourself, so you need to make sure to set `stream = true` in the `api_kwargs`!

Learn more in `?StreamCallback`.
Note: Streaming support is only for OpenAI models and it doesn't yet support tool calling and a few other features (logprobs, refusals, etc.)
"""
function aigenerate(prompt_schema::AbstractOpenAISchema, prompt::ALLOWED_PROMPT_TYPE;
        verbose::Bool = true,
        api_key::String = "",
        model::String = MODEL_CHAT, return_all::Bool = false, dry_run::Bool = false,
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        streamcallback::Any = nothing,
        no_system_message::Bool = false,
        name_user::Union{Nothing, String} = nothing,
        name_assistant::Union{Nothing, String} = nothing,
        http_kwargs::NamedTuple = (retry_non_idempotent = true,
            retries = 5,
            readtimeout = 120), api_kwargs::NamedTuple = NamedTuple(),
        kwargs...)
    ##
    global MODEL_ALIASES
    ## Find the unique ID for the model alias provided
    model_id = get(MODEL_ALIASES, model, model)
    conv_rendered = render(
        prompt_schema, prompt; conversation, no_system_message, name_user, kwargs...)

    if !dry_run
        time = @elapsed r = create_chat(prompt_schema, api_key,
            model_id,
            conv_rendered;
            streamcallback,
            http_kwargs,
            api_kwargs...)
        ## Process one of more samples returned
        has_many_samples = length(r.response[:choices]) > 1
        run_id = Int(rand(Int32)) # remember one run ID
        ## extract all message
        msg = [response_to_message(prompt_schema, AIMessage, choice, r;
                   time, model_id, run_id, name_assistant,
                   sample_id = has_many_samples ? i : nothing)
               for (i, choice) in enumerate(r.response[:choices])]
        ## Order by log probability if available
        ## bigger is better, keep it last
        msg = if has_many_samples && all(x -> !isnothing(x.log_prob), msg)
            sort(msg, by = x -> x.log_prob)
        elseif has_many_samples
            msg
        else
            only(msg)
        end
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
    aiembed(prompt_schema::AbstractOpenAISchema,
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
- `prompt_schema::AbstractOpenAISchema`: The schema for the prompt.
- `doc_or_docs::Union{AbstractString, AbstractVector{<:AbstractString}}`: The document or list of documents to generate embeddings for.
- `postprocess::F`: The post-processing function to apply to each embedding. Defaults to the identity function.
- `verbose::Bool`: A flag indicating whether to print verbose information. Defaults to `true`.
- `api_key::String`: The API key to use for the OpenAI API. Defaults to `""`, which will use `OPENAI_API_KEY` from environment.
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
        api_key::String = "",
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
    tokens_prompt = haskey(r.response, :usage) ?
                    get(
        r.response[:usage], :prompt_tokens, get(r.response[:usage], :promptTokens, 0)) : 0
    msg = DataMessage(;
        content = mapreduce(x -> postprocess(x[:embedding]), hcat, r.response[:data]),
        status = Int(r.status),
        cost = call_cost(tokens_prompt, 0, model_id),
        tokens = (tokens_prompt, 0),
        elapsed = time)
    ## Reporting
    verbose && @info _report_stats(msg, model_id)

    return msg
end

### Tokenization
# The following files are to support logit bias in aiclassify function

"Token IDs for GPT3.5 and GPT4 from https://platform.openai.com/tokenizer"
const OPENAI_TOKEN_IDS_GPT35_GPT4 = Dict("true" => 837,
    "false" => 905,
    "unknown" => 9987,
    "other" => 1023,
    "1" => 16,
    "2" => 17,
    "3" => 18,
    "4" => 19,
    "5" => 20,
    "6" => 21,
    "7" => 22,
    "8" => 23,
    "9" => 24,
    "10" => 605,
    "11" => 806,
    "12" => 717,
    "13" => 1032,
    "14" => 975,
    "15" => 868,
    "16" => 845,
    "17" => 1114,
    "18" => 972,
    "19" => 777,
    "20" => 508,
    "21" => 1691,
    "22" => 1313,
    "23" => 1419,
    "24" => 1187,
    "25" => 914,
    "26" => 1627,
    "27" => 1544,
    "28" => 1591,
    "29" => 1682,
    "30" => 966,
    "31" => 2148,
    "32" => 843,
    "33" => 1644,
    "34" => 1958,
    "35" => 1758,
    "36" => 1927,
    "37" => 1806,
    "38" => 1987,
    "39" => 2137,
    "40" => 1272
)
# GPT-4o token IDs as per tiktoken
const OPENAI_TOKEN_IDS_GPT4O = Dict(
    "true" => 3309,
    "false" => 7556,
    "unknown" => 33936,
    "other" => 2141,
    "1" => 16,
    "2" => 17,
    "3" => 18,
    "4" => 19,
    "5" => 20,
    "6" => 21,
    "7" => 22,
    "8" => 23,
    "9" => 24,
    "10" => 702,
    "11" => 994,
    "12" => 899,
    "13" => 1311,
    "14" => 1265,
    "15" => 1055,
    "16" => 1125,
    "17" => 1422,
    "18" => 1157,
    "19" => 858,
    "20" => 455,
    "21" => 2040,
    "22" => 1709,
    "23" => 1860,
    "24" => 1494,
    "25" => 1161,
    "26" => 2109,
    "27" => 2092,
    "28" => 2029,
    "29" => 2270,
    "30" => 1130,
    "31" => 2911,
    "32" => 1398,
    "33" => 2546,
    "34" => 3020,
    "35" => 2467,
    "36" => 2636,
    "37" => 2991,
    "38" => 3150,
    "39" => 3255,
    "40" => 1723)
## Note: You can provide your own token IDs map to `encode_choices` to use a custom mapping via kwarg: token_ids_map

function pick_tokenizer(model::AbstractString;
        token_ids_map::Union{Nothing, Dict{<:AbstractString, <:Integer}} = nothing)
    global OPENAI_TOKEN_IDS_GPT35_GPT4, OPENAI_TOKEN_IDS_GPT4O
    OPENAI_TOKEN_IDS = if !isnothing(token_ids_map)
        token_ids_map
    elseif (model == "gpt-4" || startswith(model, "gpt-3.5") ||
            startswith(model, "gpt-4-"))
        OPENAI_TOKEN_IDS_GPT35_GPT4
    elseif startswith(model, "gpt-4o")
        OPENAI_TOKEN_IDS_GPT4O
    else
        throw(ArgumentError("Model $model is not supported by `encode_choices`. We don't have token IDs for it."))
    end
    return OPENAI_TOKEN_IDS
end

"""
    encode_choices(schema::OpenAISchema, choices::AbstractVector{<:AbstractString};
        model::AbstractString,
        token_ids_map::Union{Nothing, Dict{<:AbstractString, <:Integer}} = nothing,
        kwargs...)

    encode_choices(schema::OpenAISchema, choices::AbstractVector{T};
        model::AbstractString,
        token_ids_map::Union{Nothing, Dict{<:AbstractString, <:Integer}} = nothing,
        kwargs...) where {T <: Tuple{<:AbstractString, <:AbstractString}}

Encode the choices into an enumerated list that can be interpolated into the prompt and creates the corresponding logit biases (to choose only from the selected tokens).

Optionally, can be a vector tuples, where the first element is the choice and the second is the description.

There can be at most 40 choices provided.

# Arguments
- `schema::OpenAISchema`: The OpenAISchema object.
- `choices::AbstractVector{<:Union{AbstractString,Tuple{<:AbstractString, <:AbstractString}}}`: The choices to be encoded, represented as a vector of the choices directly, or tuples where each tuple contains a choice and its description.
- `model::AbstractString`: The model to use for encoding. Can be an alias corresponding to a model ID defined in `MODEL_ALIASES`.
- `token_ids_map::Union{Nothing, Dict{<:AbstractString, <:Integer}} = nothing`: A dictionary mapping custom token IDs to their corresponding integer values. If `nothing`, it will use the default token IDs for the given model.
- `kwargs...`: Additional keyword arguments.

# Returns
- `choices_prompt::AbstractString`: The encoded choices as a single string, separated by newlines.
- `logit_bias::Dict`: The logit bias dictionary, where the keys are the token IDs and the values are the bias values.
- `decode_ids::AbstractVector{<:AbstractString}`: The decoded IDs of the choices.

# Examples
```julia
choices_prompt, logit_bias, _ = PT.encode_choices(PT.OpenAISchema(), ["true", "false"])
choices_prompt # Output: "true for \"true\"\nfalse for \"false\"
logit_bias # Output: Dict(837 => 100, 905 => 100)

choices_prompt, logit_bias, _ = PT.encode_choices(PT.OpenAISchema(), ["animal", "plant"])
choices_prompt # Output: "1. \"animal\"\n2. \"plant\""
logit_bias # Output: Dict(16 => 100, 17 => 100)
```

Or choices with descriptions:
```julia
choices_prompt, logit_bias, _ = PT.encode_choices(PT.OpenAISchema(), [("A", "any animal or creature"), ("P", "for any plant or tree"), ("O", "for everything else")])
choices_prompt # Output: "1. \"A\" for any animal or creature\n2. \"P\" for any plant or tree\n3. \"O\" for everything else"
logit_bias # Output: Dict(16 => 100, 17 => 100, 18 => 100)
```
"""
function encode_choices(schema::OpenAISchema,
        choices::AbstractVector{<:AbstractString};
        model::AbstractString,
        token_ids_map::Union{Nothing, Dict{<:AbstractString, <:Integer}} = nothing,
        kwargs...)
    OPENAI_TOKEN_IDS = pick_tokenizer(model; token_ids_map)
    ## if all choices are in the dictionary, use the dictionary
    if all(Base.Fix1(haskey, OPENAI_TOKEN_IDS), choices)
        choices_prompt = ["$c for \"$c\"" for c in choices]
        logit_bias = Dict(OPENAI_TOKEN_IDS[c] => 100 for c in choices)
    elseif length(choices) <= 40
        ## encode choices to IDs 1..40
        choices_prompt = ["$(i). \"$c\"" for (i, c) in enumerate(choices)]
        logit_bias = Dict(OPENAI_TOKEN_IDS[string(i)] => 100 for i in 1:length(choices))
    else
        throw(ArgumentError("The number of choices must be less than or equal to 20."))
    end

    return join(choices_prompt, "\n"), logit_bias, choices
end
function encode_choices(schema::OpenAISchema,
        choices::AbstractVector{T};
        model::AbstractString,
        token_ids_map::Union{Nothing, Dict{<:AbstractString, <:Integer}} = nothing,
        kwargs...) where {T <: Tuple{<:AbstractString, <:AbstractString}}
    OPENAI_TOKEN_IDS = pick_tokenizer(model; token_ids_map)
    ## if all choices are in the dictionary, use the dictionary
    if all(Base.Fix1(haskey, OPENAI_TOKEN_IDS), first.(choices))
        choices_prompt = ["$c for \"$desc\"" for (c, desc) in choices]
        logit_bias = Dict(OPENAI_TOKEN_IDS[c] => 100 for (c, desc) in choices)
    elseif length(choices) <= 40
        ## encode choices to IDs 1..20
        choices_prompt = ["$(i). \"$c\" for $desc" for (i, (c, desc)) in enumerate(choices)]
        logit_bias = Dict(OPENAI_TOKEN_IDS[string(i)] => 100 for i in 1:length(choices))
    else
        throw(ArgumentError("The number of choices must be less than or equal to 40."))
    end

    return join(choices_prompt, "\n"), logit_bias, first.(choices)
end

# For testing
function encode_choices(schema::TestEchoOpenAISchema, choices; kwargs...)
    return encode_choices(OpenAISchema(), choices; kwargs...)
end
# For testing
function decode_choices(schema::TestEchoOpenAISchema,
        choices,
        conv::Union{AbstractVector, AIMessage};
        kwargs...)
    return decode_choices(OpenAISchema(), choices, conv; kwargs...)
end

function decode_choices(schema::OpenAISchema, choices, conv::AbstractVector;
        model::AbstractString,
        token_ids_map::Union{Nothing, Dict{<:AbstractString, <:Integer}} = nothing,
        kwargs...)
    conv_output = if length(conv) > 0 && last(conv) isa AIMessage &&
                     hasproperty(last(conv), :run_id)
        ## if it is a multi-sample response, 
        ## Remember its run ID and convert all samples in that run
        run_id = last(conv).run_id
        ## Need to re-render the conversation history if the types changed
        [if isaimessage(conv[i]) && conv[i].run_id == run_id
             decode_choices(schema, choices, conv[i]; model, token_ids_map)
         else
             conv[i]
         end
         for i in eachindex(conv)]
    else
        conv
    end
    return conv_output
end

"""
    decode_choices(schema::OpenAISchema,
        choices::AbstractVector{<:AbstractString},
        msg::AIMessage; model::AbstractString,
        token_ids_map::Union{Nothing, Dict{<:AbstractString, <:Integer}} = nothing,
        kwargs...)

Decodes the underlying AIMessage against the original choices to lookup what the category name was.

If it fails, it will return `msg.content == nothing`
"""
function decode_choices(schema::OpenAISchema,
        choices::AbstractVector{<:AbstractString},
        msg::AIMessage; model::AbstractString,
        token_ids_map::Union{Nothing, Dict{<:AbstractString, <:Integer}} = nothing,
        kwargs...)
    OPENAI_TOKEN_IDS = pick_tokenizer(model; token_ids_map)
    parsed_digit = tryparse(Int, strip(msg.content))
    if !isnothing(parsed_digit) && haskey(OPENAI_TOKEN_IDS, strip(msg.content))
        ## It's encoded
        content = choices[parsed_digit]
    elseif haskey(OPENAI_TOKEN_IDS, strip(msg.content))
        ## if it's NOT a digit, but direct mapping (eg, true/false), no changes!
        content = strip(msg.content)
    else
        ## failed decoding
        content = nothing
    end
    ## create a new object with all the same fields except for content
    return AIMessage(; [f => getfield(msg, f) for f in fieldnames(typeof(msg))]..., content)
end

"""
    aiclassify(prompt_schema::AbstractOpenAISchema, prompt::ALLOWED_PROMPT_TYPE;
        choices::AbstractVector{T} = ["true", "false", "unknown"],
        model::AbstractString = "gpt-4o-mini,
        api_kwargs::NamedTuple = NamedTuple(),
        token_ids_map::Union{Nothing, Dict{<:AbstractString, <:Integer}} = nothing,
        kwargs...) where {T <: Union{AbstractString, Tuple{<:AbstractString, <:AbstractString}}}

Classifies the given prompt/statement into an arbitrary list of `choices`, which must be only the choices (vector of strings) or choices and descriptions are provided (vector of tuples, ie, `("choice","description")`).

It's quick and easy option for "routing" and similar use cases, as it exploits the logit bias trick and outputs only 1 token.
classify into an arbitrary list of categories (including with descriptions). It's quick and easy option for "routing" and similar use cases, as it exploits the logit bias trick, so it outputs only 1 token.

!!! Note: The prompt/AITemplate must have a placeholder `choices` (ie, `{{choices}}`) that will be replaced with the encoded choices

Choices are rewritten into an enumerated list and mapped to a few known OpenAI tokens (maximum of 40 choices supported). Mapping of token IDs for GPT3.5/4 are saved in variable `OPENAI_TOKEN_IDS`.

It uses Logit bias trick and limits the output to 1 token to force the model to output only true/false/unknown. Credit for the idea goes to [AAAzzam](https://twitter.com/AAAzzam/status/1669753721574633473).

# Arguments
- `prompt_schema::AbstractOpenAISchema`: The schema for the prompt.
- `prompt`: The prompt/statement to classify if it's a `String`. If it's a `Symbol`, it is expanded as a template via `render(schema,template)`. Eg, templates `:JudgeIsItTrue` or `:InputClassifier`
- `choices::AbstractVector{T}`: The choices to be classified into. It can be a vector of strings or a vector of tuples, where the first element is the choice and the second is the description.
- `model::AbstractString = "gpt-4o-mini"`: The model to use for classification. Can be an alias corresponding to a model ID defined in `MODEL_ALIASES`.
- `api_kwargs::NamedTuple = NamedTuple()`: Additional keyword arguments for the API call.
- `token_ids_map::Union{Nothing, Dict{<:AbstractString, <:Integer}} = nothing`: A dictionary mapping custom token IDs to their corresponding integer values. If `nothing`, it will use the default token IDs for the given model.
- `kwargs`: Additional keyword arguments for the prompt template.

# Example

Given a user input, pick one of the two provided categories:
```julia
choices = ["animal", "plant"]
input = "Palm tree"
aiclassify(:InputClassifier; choices, input)
```

Choices with descriptions provided as tuples:
```julia
choices = [("A", "any animal or creature"), ("P", "any plant or tree"), ("O", "anything else")]

# try the below inputs:
input = "spider" # -> returns "A" for any animal or creature
input = "daphodil" # -> returns "P" for any plant or tree
input = "castle" # -> returns "O" for everything else
aiclassify(:InputClassifier; choices, input)
```

You could also use this function for routing questions to different endpoints (notice the different template and placeholder used), eg, 
```julia
choices = [("A", "any question about animal or creature"), ("P", "any question about plant or tree"), ("O", "anything else")]
question = "how many spiders are there?"
msg = aiclassify(:QuestionRouter; choices, question)
# "A"
```

You can still use a simple true/false classification:
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
        choices::AbstractVector{T} = ["true", "false", "unknown"],
        model::AbstractString = "gpt-4o-mini",
        api_kwargs::NamedTuple = NamedTuple(),
        token_ids_map::Union{Nothing, Dict{<:AbstractString, <:Integer}} = nothing,
        kwargs...) where {T <:
                          Union{AbstractString, Tuple{<:AbstractString, <:AbstractString}}}
    ## Encode the choices and the corresponding prompt 
    model_id = get(MODEL_ALIASES, model, model)
    choices_prompt, logit_bias,
    decode_ids = encode_choices(
        prompt_schema, choices; model = model_id, token_ids_map)
    ## We want only 1 token
    api_kwargs = merge(api_kwargs, (; logit_bias, max_tokens = 1, temperature = 0))
    msg_or_conv = aigenerate(prompt_schema,
        prompt;
        choices = choices_prompt,
        model = model_id,
        api_kwargs,
        kwargs...)
    return decode_choices(
        prompt_schema, decode_ids, msg_or_conv; model = model_id, token_ids_map)
end

function response_to_message(schema::AbstractOpenAISchema,
        MSG::Type{DataMessage},
        choice,
        resp;
        tool_map = nothing,
        model_id::AbstractString = "",
        time::Float64 = 0.0,
        run_id::Int = Int(rand(Int32)),
        sample_id::Union{Nothing, Integer} = nothing,
        json_mode::Union{Nothing, Bool} = nothing)
    @assert !isnothing(tool_map) "You must provide a tool_map for DataMessage construction"
    ## extract sum log probability
    has_log_prob = haskey(choice, :logprobs) &&
                   !isnothing(get(choice, :logprobs, nothing)) &&
                   haskey(choice[:logprobs], :content) &&
                   !isnothing(choice[:logprobs][:content])
    log_prob = if has_log_prob
        sum([get(c, :logprob, 0.0) for c in choice[:logprobs][:content]])
    else
        nothing
    end
    ## Has reasoning content -- currently only provided by DeepSeek API
    has_reasoning_content = haskey(choice, :message) &&
                            haskey(choice[:message], :reasoning_content)
    reasoning_content = if has_reasoning_content
        choice[:message][:reasoning_content]
    else
        nothing
    end
    # Extract usage information with default values for tokens
    tokens_prompt = 0
    tokens_completion = 0
    # Merge with response usage if available
    if haskey(resp.response, :usage)
        response_usage = resp.response[:usage]
        # Handle both snake_case and camelCase keys
        tokens_prompt = get(response_usage, :prompt_tokens,
            get(response_usage, :promptTokens, 0))
        tokens_completion = get(response_usage, :completion_tokens,
            get(response_usage, :completionTokens, 0))
    end
    ## calculate cost
    cost = call_cost(tokens_prompt, tokens_completion, model_id)
    # "Safe" parsing of the response - it still fails if JSON is invalid
    tools_array = if json_mode == true
        name, tool = only(tool_map)
        content_blob = choice[:message][:content]
        content_obj = content_blob isa String ? JSON3.read(content_blob) : content_blob
        [parse_tool(
            tool.callable, content_obj)]
    else
        @assert haskey(choice[:message], :tool_calls) "`:tool_calls` key is missing in the response message! Retry the request."
        ## If name does not match, we use the callable from the tool_map 
        ## Can happen only in testing with auto-generated struct
        [parse_tool(
             get(tool_map, tool_call[:function][:name], (; callable = Dict)).callable,
             tool_call[:function][:arguments])
         for tool_call in choice[:message][:tool_calls]]
    end
    ## Remember the tools
    extras = Dict{Symbol, Any}()
    if haskey(choice[:message], :tool_calls) && !isempty(choice[:message][:tool_calls])
        extras[:tool_calls] = choice[:message][:tool_calls]
    end
    if has_log_prob
        extras[:log_prob] = choice[:logprobs]
    end
    if has_reasoning_content
        extras[:reasoning_content] = reasoning_content
    end
    _extract_openai_extras!(extras, resp)

    ## build DataMessage object
    msg = MSG(;
        content = length(tools_array) == 1 ? only(tools_array) : tools_array,
        status = Int(resp.status),
        cost,
        run_id,
        sample_id,
        log_prob,
        finish_reason = get(choice, :finish_reason, nothing),
        tokens = (tokens_prompt,
            tokens_completion),
        elapsed = time,
        extras)
end

"""
    aiextract(prompt_schema::AbstractOpenAISchema, prompt::ALLOWED_PROMPT_TYPE;
        return_type::Union{Type, AbstractTool, Vector},
        verbose::Bool = true,
        api_key::String = "",
        model::String = MODEL_CHAT,
        return_all::Bool = false, dry_run::Bool = false,
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        http_kwargs::NamedTuple = (retry_non_idempotent = true,
            retries = 5,
            readtimeout = 120), api_kwargs::NamedTuple = (;
            tool_choice = nothing),
        strict::Union{Nothing, Bool} = nothing,
        kwargs...)

Extract required information (defined by a struct **`return_type`**) from the provided prompt by leveraging OpenAI function calling mode.

This is a perfect solution for extracting structured information from text (eg, extract organization names in news articles, etc.)

It's effectively a light wrapper around `aigenerate` call, which requires additional keyword argument `return_type` to be provided
 and will enforce the model outputs to adhere to it.

!!! Note: The types must be CONCRETE, it helps with correct conversion to JSON schema and then conversion back to the struct.

# Arguments
- `prompt_schema`: An optional object to specify which prompt template should be applied (Default to `PROMPT_SCHEMA = OpenAISchema`)
- `prompt`: Can be a string representing the prompt for the AI conversation, a `UserMessage`, a vector of `AbstractMessage` or an `AITemplate`
- `return_type`: A **struct** TYPE (or a Tool, vector of Types) representing the the information we want to extract. Do not provide a struct instance, only the type. Alternatively, you can provide a vector of field names and their types (see `?generate_struct` function for the syntax).
  If the struct has a docstring, it will be provided to the model as well. It's used to enforce structured model outputs or provide more information.
- `verbose`: A boolean indicating whether to print additional information.
- `api_key`: A string representing the API key for accessing the OpenAI API. If not provided, the function will use the `OPENAI_API_KEY` environment variable.
- `model`: A string representing the model to use for generating the response. Can be an alias corresponding to a model ID defined in `MODEL_ALIASES`.
- `return_all::Bool=false`: If `true`, returns the entire conversation history, otherwise returns only the last message (the `AIMessage`).
- `dry_run::Bool=false`: If `true`, skips sending the messages to the model (for debugging, often used with `return_all=true`).
- `conversation`: An optional vector of `AbstractMessage` objects representing the conversation history. If not provided, it is initialized as an empty vector.
- `http_kwargs`: A named tuple of HTTP keyword arguments.
- `api_kwargs`: A named tuple of API keyword arguments. 
  - `tool_choice`: Specifies which tool to use for the API call. Usually, one of "auto","any","exact" // `nothing` will pick a default. 
    Defaults to `"exact"` for 1 tool and `"auto"` for many tools, which is a made-up value to enforce the OpenAI requirements if we want one exact function.
    Providers like Mistral, Together, etc. use `"any"` instead.
- `strict::Union{Nothing, Bool} = nothing`: A boolean indicating whether to enforce strict generation of the response (supported only for OpenAI models). It has additional latency for the first request. If `nothing`, standard function calling is used.
- `json_mode::Union{Nothing, Bool} = nothing`: If `json_mode = true`, we use JSON mode for the response (supported only for OpenAI models). If `nothing`, standard function calling is used.
    JSON mode is understood to be more creative and smarter than function calling mode, as it's not mascarading as a function call,
    but there is extra latency for the first request to produce grammar for constrained sampling.
- `kwargs`: Prompt variables to be used to fill the prompt/template

# Returns
If `return_all=false` (default):
- `msg`: An `DataMessage` object representing the extracted data, including the content, status, tokens, and elapsed time. 
  Use `msg.content` to access the extracted data.

If `return_all=true`:
- `conversation`: A vector of `AbstractMessage` objects representing the full conversation history, including the response from the AI model (`DataMessage`).

Note: `msg.content` can be a single object (if a single tool is used) or a vector of objects (if multiple tools are used)!

See also: `tool_call_signature`, `MaybeExtract`, `ItemsExtract`, `aigenerate`, `generate_struct`

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
struct ManyMeasurements
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

return_type = MaybeExtract{MyMeasurement}
# Effectively the same as:
# struct MaybeExtract{T}
#     result::Union{T, Nothing} // The result of the extraction
#     error::Bool // true if a result is found, false otherwise
#     message::Union{Nothing, String} // Only present if no result is found, should be short and concise
# end

# If LLM extraction fails, it will return a Dict with `error` and `message` fields instead of the result!
msg = aiextract("Extract measurements from the text: I am giraffe"; return_type)
msg.content
# MaybeExtract{MyMeasurement}(nothing, true, "I'm sorry, but I can only assist with human measurements.")
```

That way, you can handle the error gracefully and get a reason why extraction failed (in `msg.content.message`).

Note that the error message refers to a giraffe not being a human, 
 because in our `MyMeasurement` docstring, we said that it's for people!

Some non-OpenAI providers require a different specification of the "tool choice" than OpenAI. 
For example, to use Mistral models ("mistrall" for mistral large), do:
```julia
"Some fruit"
struct Fruit
    name::String
end
aiextract("I ate an apple",return_type=Fruit,api_kwargs=(;tool_choice="any"),model="mistrall")
# Notice two differences: 1) struct MUST have a docstring, 2) tool_choice is set explicitly set to "any"
```

Example of using a vector of field names with `aiextract`
```julia
fields = [:location, :temperature => Float64, :condition => String]
msg = aiextract("Extract the following information from the text: location, temperature, condition. Text: The weather in New York is sunny and 72.5 degrees Fahrenheit."; return_type = fields)
```

Or simply call `aiextract("some text"; return_type = [:reasoning,:answer])` to get a Chain of Thought reasoning for extraction task.

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
msg = aiextract("The weather in New York is sunny and 72.5 degrees Fahrenheit."; return_type = fields_with_descriptions)
```

If you feel that the extraction is not smart/creative enough, you can use `json_mode = true` to enforce the JSON mode, 
which automatically enables the structured output mode (as opposed to function calling mode).

The JSON mode is useful for cases when you want to enforce a specific output format, such as JSON, and want the model to adhere to that format, but don't want to pretend it's a "function call".
Expect a few second delay on the first call for a specific struct, as the provider has to produce the constrained grammer first.

```julia
msg = aiextract("Extract the following information from the text: location, temperature, condition. Text: The weather in New York is sunny and 72.5 degrees Fahrenheit."; 
return_type = fields_with_descriptions, json_mode = true)
# PromptingTools.DataMessage(NamedTuple)

msg.content
# (location = "New York", temperature = 72.5, condition = "sunny")
```

It works equally well for structs provided as return types:
```julia
msg = aiextract("James is 30, weighs 80kg. He's 180cm tall."; return_type=MyMeasurement, json_mode=true)
```
"""
function aiextract(prompt_schema::AbstractOpenAISchema, prompt::ALLOWED_PROMPT_TYPE;
        return_type::Union{Type, AbstractTool, Vector},
        verbose::Bool = true,
        api_key::String = "",
        model::String = MODEL_CHAT,
        return_all::Bool = false, dry_run::Bool = false,
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        http_kwargs::NamedTuple = (retry_non_idempotent = true,
            retries = 5,
            readtimeout = 120), api_kwargs::NamedTuple = (;
            tool_choice = nothing),
        strict::Union{Nothing, Bool} = nothing,
        json_mode::Union{Nothing, Bool} = nothing,
        kwargs...)
    ##
    global MODEL_ALIASES
    ## Function calling specifics
    ## Check that no functions or methods are provided, that is not supported
    @assert !(return_type isa Vector)||!any(x -> x isa Union{Function, Method}, return_type) "Functions and Methods are not supported in `aiextract`!"
    ## Set strict mode on for JSON mode
    strict_ = json_mode == true ? true : strict
    tool_map = tool_call_signature(return_type; strict = strict_)
    tools = render(prompt_schema, tool_map; json_mode)
    ## force our function to be used
    tool_choice_ = get(api_kwargs, :tool_choice, nothing)
    tool_choice = if tool_choice_ == "exact" ||
                     (isnothing(tool_choice_) && length(tools) == 1)
        ## Standard for OpenAI API
        Dict(:type => "function",
            :function => Dict(:name => only(tools)[:function][:name]))
    elseif tool_choice_ == "auto" || (isnothing(tool_choice_) && length(tools) > 1)
        # User provided value, eg, "auto", "any" for various providers like Mistral, Together, etc.
        "auto"
    else
        # User provided value
        tool_choice_
    end

    ## Build the API kwargs
    api_kwargs = if json_mode == true
        @assert length(tools)==1 "Only 1 tool definition is allowed in JSON mode."
        (; [k => v for (k, v) in pairs(api_kwargs) if k != :tool_choice]...,
            response_format = (;
                type = "json_schema", json_schema = only(tools)[:function]))
    else
        merge(api_kwargs, (; tools, tool_choice))
    end

    ## Find the unique ID for the model alias provided
    model_id = get(MODEL_ALIASES, model, model)
    conv_rendered = render(prompt_schema, prompt; conversation, kwargs...)

    if !dry_run
        time = @elapsed r = create_chat(prompt_schema, api_key,
            model_id,
            conv_rendered;
            http_kwargs,
            api_kwargs...)
        ## Process one of more samples returned
        has_many_samples = length(r.response[:choices]) > 1
        run_id = Int(rand(Int32)) # remember one run ID
        msg = [response_to_message(prompt_schema, DataMessage, choice, r;
                   tool_map = tool_map, time, model_id, run_id, json_mode,
                   sample_id = has_many_samples ? i : nothing)
               for (i, choice) in enumerate(r.response[:choices])]
        ## Order by log probability if available
        ## bigger is better, keep it last
        msg = if has_many_samples && all(x -> !isnothing(x.log_prob), msg)
            sort(msg, by = x -> x.log_prob)
        elseif has_many_samples
            msg
        else
            only(msg)
        end

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
    verbose::Bool = true, api_key::String = "",
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
- `api_key`: A string representing the API key for accessing the OpenAI API. If not provided, the function will use the `OPENAI_API_KEY` environment variable.
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
        api_key::String = "",
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
        ## Process one of more samples returned
        msg = if length(r.response[:choices]) > 1
            run_id = Int(rand(Int32)) # remember one run ID
            ## extract all message
            msgs = [response_to_message(prompt_schema, AIMessage, choice, r;
                        time, model_id, run_id, sample_id = i)
                    for (i, choice) in enumerate(r.response[:choices])]
            ## Order by log probability if available
            ## bigger is better, keep it last
            if all(x -> !isnothing(x.log_prob), msgs)
                sort(msgs, by = x -> x.log_prob)
            else
                msgs
            end
        else
            ## only 1 sample / 1 completion
            choice = r.response[:choices][begin]
            response_to_message(prompt_schema, AIMessage, choice, r;
                time, model_id)
        end
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

"""
    aiimage(prompt_schema::AbstractOpenAISchema, prompt::ALLOWED_PROMPT_TYPE;
        image_size::AbstractString = "1024x1024",
        image_quality::AbstractString = "standard",
        image_n::Integer = 1,
        verbose::Bool = true,
        api_key::String = "",
        model::String = MODEL_IMAGE_GENERATION,
        return_all::Bool = false, dry_run::Bool = false,
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        http_kwargs::NamedTuple = (retry_non_idempotent = true,
            retries = 5,
            readtimeout = 120), api_kwargs::NamedTuple = NamedTuple(),
        kwargs...)

Generates an image from the provided `prompt`. If multiple "messages" are provided in `prompt`, it extracts the text ONLY from the last message!

Image (or the reference to it) will be returned in a `DataMessage.content`, the format will depend on the `api_kwargs.response_format` you set.

Can be used for generating images of varying quality and style with `dall-e-*` models.
This function DOES NOT SUPPORT multi-turn conversations (ie, do not provide previous conversation via `conversation` argument).

# Arguments
- `prompt_schema`: An optional object to specify which prompt template should be applied (Default to `PROMPT_SCHEMA = OpenAISchema`)
- `prompt`: Can be a string representing the prompt for the AI conversation, a `UserMessage`, a vector of `AbstractMessage` or an `AITemplate`
- `image_size`: String-based resolution of the image, eg, "1024x1024". Only some resolutions are supported - see the [API docs](https://platform.openai.com/docs/api-reference/images/create).
- `image_quality`: It can be either "standard" or "hd". Defaults to "standard".
- `image_n`: The number of images to generate. Currently, only single image generation is allowed (`image_n = 1`).
- `verbose`: A boolean indicating whether to print additional information.
- `api_key`: A string representing the API key for accessing the OpenAI API. If not provided, the function will use the `OPENAI_API_KEY` environment variable.
- `model`: A string representing the model to use for generating the response. Can be an alias corresponding to a model ID defined in `MODEL_IMAGE_GENERATION`.
- `return_all::Bool=false`: If `true`, returns the entire conversation history, otherwise returns only the last message (the `AIMessage`).
- `dry_run::Bool=false`: If `true`, skips sending the messages to the model (for debugging, often used with `return_all=true`).
- `conversation`: An optional vector of `AbstractMessage` objects representing the conversation history. Currently, NOT ALLOWED.
- `http_kwargs`: A named tuple of HTTP keyword arguments.
- `api_kwargs`: A named tuple of API keyword arguments. Several important arguments are highlighted below:
    - `response_format`: The format image should be returned in. Can be one of "url" or "b64_json". Defaults to "url" (the link will be inactived in 60 minutes).
    - `style`: The style of generated images (DALL-E 3 only). Can be either "vidid" or "natural". Defauls to "vidid".
- `kwargs`: Prompt variables to be used to fill the prompt/template

# Returns
If `return_all=false` (default):
- `msg`: A `DataMessage` object representing one or more generated images, including the rewritten prompt if relevant, status, and elapsed time.
 Use `msg.content` to access the extracted string.

If `return_all=true`:
- `conversation`: A vector of `AbstractMessage` objects representing the full conversation history, including the response from the AI model (`AIMessage`).

See also: `ai_str`, `aai_str`, `aigenerate`, `aiembed`, `aiclassify`, `aiextract`, `aiscan`, `aitemplates`

# Notes
- This function DOES NOT SUPPORT multi-turn conversations (ie, do not provide previous conversation via `conversation` argument).
- There is no token tracking provided by the API, so the messages will NOT report any cost despite costing you money!
- You MUST download any URL-based images within 60 minutes. The links will become inactive.

# Example

Generate an image:
```julia
# You can experiment with `image_size`, `image_quality` kwargs!
msg = aiimage("A white cat on a car")

# Download the image into a file
using Downloads
Downloads.download(msg.content[:url], "cat_on_car.png")

# You can also see the revised prompt that DALL-E 3 used
msg.content[:revised_prompt]
# Output: "Visualize a pristine white cat gracefully perched atop a shiny car. 
# The cat's fur is stark white and its eyes bright with curiosity. 
# As for the car, it could be a contemporary sedan, glossy and in a vibrant color. 
# The scene could be set under the blue sky, enhancing the contrast between the white cat, the colorful car, and the bright blue sky."
```

Note that you MUST download any URL-based images within 60 minutes. The links will become inactive.

If you wanted to download image directly into the DataMessage, provide `response_format="b64_json"` in `api_kwargs`:
```julia
msg = aiimage("A white cat on a car"; image_quality="hd", api_kwargs=(; response_format="b64_json"))

# Then you need to use Base64 package to decode it and save it to a file:
using Base64
write("cat_on_car_hd.png", base64decode(msg.content[:b64_json]));
```

"""
function aiimage(prompt_schema::AbstractOpenAISchema, prompt::ALLOWED_PROMPT_TYPE;
        image_size::AbstractString = "1024x1024",
        image_quality::AbstractString = "standard",
        image_n::Integer = 1,
        verbose::Bool = true,
        api_key::String = "",
        model::String = MODEL_IMAGE_GENERATION,
        return_all::Bool = false, dry_run::Bool = false,
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        http_kwargs::NamedTuple = (retry_non_idempotent = true,
            retries = 5,
            readtimeout = 120), api_kwargs::NamedTuple = NamedTuple(),
        kwargs...)
    @assert isempty(conversation) "Multi-turn `conversation` is not supported for image generation."
    @assert image_n==1 "Only single image generation is currently supported."
    @assert !isnothing(match(r"\d{3,4}x\d{3,4}", image_size)) "`image_size` must be in format \"1024x1024\"!"
    ##
    global MODEL_ALIASES
    ## Find the unique ID for the model alias provided
    model_id = get(MODEL_ALIASES, model, model)
    conv_rendered = render(prompt_schema, prompt; conversation, kwargs...)
    ## conv_rendered is a vector of dictionaries
    ## prompt must be a string, so we extract from last message
    prompt = last(conv_rendered)["content"]
    if !dry_run
        ## Model call
        time = @elapsed r = create_images(prompt_schema, api_key,
            prompt;
            model = model_id,
            http_kwargs,
            quality = image_quality,
            n = image_n,
            size = image_size,
            api_kwargs...)
        msg = DataMessage(;
            ## currently extracts only the first response
            content = r.response[:data][begin],
            status = Int(r.status),
            cost = call_cost_alternative(image_n, model_id; image_quality, image_size),
            tokens = (0, 0),
            elapsed = time)

        ## Reporting
        verbose && @info _report_stats(msg, model_id)
    else
        msg = nothing
    end

    ## Select what to return // input `msgs` to preserve the image attachments
    output = finalize_outputs(prompt,
        conv_rendered,
        msg;
        conversation,
        return_all,
        dry_run,
        kwargs...)

    return output
end

## Standardizes parsing of 1 or more samples returned from OpenAI-compatible APIs into AIToolRequest objects
function response_to_message(schema::AbstractOpenAISchema,
        MSG::Type{AIToolRequest},
        choice,
        resp;
        tool_map = nothing,
        model_id::AbstractString = "",
        time::Float64 = 0.0,
        run_id::Int = Int(rand(Int32)),
        sample_id::Union{Nothing, Integer} = nothing,
        json_mode::Union{Nothing, Bool} = nothing,
        name_user::Union{Nothing, String} = nothing,
        name_assistant::Union{Nothing, String} = nothing)
    @assert !isnothing(tool_map) "You must provide a tool_map for AIToolRequest construction"
    ## extract sum log probability
    has_log_prob = haskey(choice, :logprobs) &&
                   !isnothing(get(choice, :logprobs, nothing)) &&
                   haskey(choice[:logprobs], :content) &&
                   !isnothing(choice[:logprobs][:content])
    log_prob = if has_log_prob
        sum([get(c, :logprob, 0.0) for c in choice[:logprobs][:content]])
    else
        nothing
    end
    ## Has reasoning content -- currently only provided by DeepSeek API
    has_reasoning_content = haskey(choice, :message) &&
                            haskey(choice[:message], :reasoning_content)
    reasoning_content = if has_reasoning_content
        choice[:message][:reasoning_content]
    else
        nothing
    end
    # Extract usage information with default values for tokens
    tokens_prompt = 0
    tokens_completion = 0
    # Merge with response usage if available
    if haskey(resp.response, :usage)
        response_usage = resp.response[:usage]
        # Handle both snake_case and camelCase keys
        tokens_prompt = get(response_usage, :prompt_tokens,
            get(response_usage, :promptTokens, 0))
        tokens_completion = get(response_usage, :completion_tokens,
            get(response_usage, :completionTokens, 0))
    end
    ## calculate cost
    cost = call_cost(tokens_prompt, tokens_completion, model_id)
    # "Safe" parsing of the response - it still fails if JSON is invalid
    has_tools = haskey(choice[:message], :tool_calls) &&
                !isempty(choice[:message][:tool_calls])
    tools_array = if json_mode == true
        tool_name, tool = only(tool_map)
        ## Note, JSON mode doesn't have tool_call_id so we mock it
        content_blob = choice[:message][:content]
        [ToolMessage(;
            content = nothing, req_id = run_id, tool_call_id = string("call_", run_id),
            raw = content_blob isa String ? content_blob : JSON3.write(content_blob),
            args = content_blob isa String ? JSON3.read(content_blob) : content_blob,
            name = tool_name)]
    elseif has_tools
        [ToolMessage(; raw = tool_call[:function][:arguments],
             args = JSON3.read(tool_call[:function][:arguments]),
             name = tool_call[:function][:name],
             content = nothing,
             req_id = run_id,
             tool_call_id = tool_call[:id]
         )
         for tool_call in choice[:message][:tool_calls]]
    else
        ToolMessage[]
    end
    ## Check if content key was provided (not required for tool calls)
    content = json_mode != true && haskey(choice[:message], :content) ?
              choice[:message][:content] : nothing
    ## Remember the tools
    extras = Dict{Symbol, Any}()
    if has_tools
        extras[:tool_calls] = choice[:message][:tool_calls]
    end
    if has_log_prob
        extras[:log_prob] = choice[:logprobs]
    end
    if has_reasoning_content
        extras[:reasoning_content] = reasoning_content
    end
    _extract_openai_extras!(extras, resp)

    ## build AIToolRequest object
    msg = MSG(;
        content = content,
        name = name_assistant,
        tool_calls = tools_array,
        status = Int(resp.status),
        cost,
        run_id,
        sample_id,
        log_prob,
        finish_reason = get(choice, :finish_reason, nothing),
        tokens = (tokens_prompt,
            tokens_completion),
        elapsed = time,
        extras)
end

"""
    aitools(prompt_schema::AbstractOpenAISchema, prompt::ALLOWED_PROMPT_TYPE;
        tools::Union{Type, Function, Method, AbstractTool, Vector} = Tool[],
        verbose::Bool = true,
        api_key::String = "",
        model::String = MODEL_CHAT,
        return_all::Bool = false, dry_run::Bool = false,
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        no_system_message::Bool = false,
        image_path::Union{Nothing, AbstractString, Vector{<:AbstractString}} = nothing,
        http_kwargs::NamedTuple = (retry_non_idempotent = true,
            retries = 5,
            readtimeout = 120), api_kwargs::NamedTuple = (;
            tool_choice = nothing),
        strict::Union{Nothing, Bool} = nothing,
        json_mode::Union{Nothing, Bool} = nothing,
        name_user::Union{Nothing, String} = nothing,
        name_assistant::Union{Nothing, String} = nothing,
        kwargs...)

Calls chat completion API with an optional tool call signature. It can receive both `tools` and standard string-based content.
Ideal for agentic workflows with more complex cognitive architectures.

Difference to `aigenerate`: Response can be a tool call (structured)

Differences to `aiextract`: Can provide infinitely many tools (including Functions!) and then respond with the tool call's output.

# Arguments
- `prompt_schema`: An optional object to specify which prompt template should be applied (Default to `PROMPT_SCHEMA = OpenAISchema`)
- `prompt`: Can be a string representing the prompt for the AI conversation, a `UserMessage`, a vector of `AbstractMessage` or an `AITemplate`
- `tools`: A vector of tools to be used in the conversation. Can be a vector of types, instances of `AbstractTool`, or a mix of both.
- `verbose`: A boolean indicating whether to print additional information.
- `api_key`: A string representing the API key for accessing the OpenAI API. If not provided, the function will use the `OPENAI_API_KEY` environment variable.
- `model`: A string representing the model to use for generating the response. Can be an alias corresponding to a model ID defined in `MODEL_CHAT`.
- `return_all`: If `true`, returns the entire conversation history, otherwise returns only the last message (the `AIMessage`).
- `dry_run`: If `true`, skips sending the messages to the model (for debugging, often used with `return_all=true`).
- `conversation`: An optional vector of `AbstractMessage` objects representing the conversation history.
- `no_system_message::Bool = false`: Whether to exclude the system message from the conversation history.
- `image_path`: A path to a local image file, or a vector of paths to local image files. Always attaches images to the latest user message.
- `name_user`: The name of the user in the conversation history. Defaults to "User".
- `name_assistant`: The name of the assistant in the conversation history. Defaults to "Assistant".
- `http_kwargs`: A named tuple of HTTP keyword arguments.
- `api_kwargs`: A named tuple of API keyword arguments. Several important arguments are highlighted below:
    - `tool_choice`: The choice of tool mode. Can be "auto", "exact", or can depend on the provided.. Defaults to `nothing`, which translates to "auto".
    - `response_format`: The format of the response. Can be "json_schema" for JSON mode, or "text" for standard text output. Defaults to "text".
- `strict`: Whether to enforce strict mode for the schema. Defaults to `nothing`.
- `json_mode`: Whether to enforce JSON mode for the schema. Defaults to `nothing`.

# Example

```julia
## Let's define a tool
get_weather(location, date) = "The weather in \$location on \$date is 70 degrees."

## JSON mode request
msg = aitools("What's the weather in Tokyo on May 3rd, 2023?";
    tools = get_weather,
    json_mode = true)
PT.execute_tool(get_weather, msg.tool_calls[1].args)
# "The weather in Tokyo on 2023-05-03 is 70 degrees."

# Function calling request
msg = aitools("What's the weather in Tokyo on May 3rd, 2023?";
    tools = get_weather)
PT.execute_tool(get_weather, msg.tool_calls[1].args)
# "The weather in Tokyo on 2023-05-03 is 70 degrees."

# Ignores the tool
msg = aitools("What's your name?";
    tools = get_weather)
# I don't have a personal name, but you can call me your AI assistant!
```

How to have a multi-turn conversation with tools:
```julia
conv = aitools("What's the weather in Tokyo on May 3rd, 2023?";
    tools = get_weather, return_all = true)

tool_msg = conv[end].tool_calls[1] # there can be multiple tool calls requested!!

# Execute the output to the tool message content
tool_msg.content = PT.execute_tool(get_weather, tool_msg.args)

# Add the tool message to the conversation
push!(conv, tool_msg)

# Call LLM again with the updated conversation
conv = aitools(
    "And in New York?"; tools = get_weather, return_all = true, conversation = conv)
# 6-element Vector{AbstractMessage}:
# SystemMessage("Act as a helpful AI assistant")
# UserMessage("What's the weather in Tokyo on May 3rd, 2023?")
# AIToolRequest("-"; Tool Requests: 1)
# ToolMessage("The weather in Tokyo on 2023-05-03 is 70 degrees.")
# UserMessage("And in New York?")
# AIToolRequest("-"; Tool Requests: 1)
```
"""
function aitools(prompt_schema::AbstractOpenAISchema, prompt::ALLOWED_PROMPT_TYPE;
        tools::Union{Type, Function, Method, AbstractTool, Vector} = Tool[],
        verbose::Bool = true,
        api_key::String = "",
        model::String = MODEL_CHAT,
        return_all::Bool = false, dry_run::Bool = false,
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        no_system_message::Bool = false, name_user::Union{Nothing, String} = nothing,
        image_path::Union{Nothing, AbstractString, Vector{<:AbstractString}} = nothing,
        name_assistant::Union{Nothing, String} = nothing,
        http_kwargs::NamedTuple = (retry_non_idempotent = true,
            retries = 5,
            readtimeout = 120), api_kwargs::NamedTuple = (;
            tool_choice = nothing),
        strict::Union{Nothing, Bool} = nothing,
        json_mode::Union{Nothing, Bool} = nothing,
        kwargs...)
    ##
    global MODEL_ALIASES
    ## Function calling specifics // get the tool map (signatures)
    ## Set strict mode on for JSON mode as Structured outputs
    strict_ = json_mode == true ? true : strict
    tool_map = tool_call_signature(tools; strict = strict_)
    tools = render(prompt_schema, tool_map; json_mode)
    ## force our function to be used
    tool_choice_ = get(api_kwargs, :tool_choice, nothing)
    tool_choice = if tool_choice_ == "exact"
        ## Standard for OpenAI API
        Dict(:type => "function",
            :function => Dict(:name => only(tools)[:function][:name]))
    elseif isnothing(tool_choice_)
        "auto"
    else
        # User provided value, eg, "auto", "any" for various providers like Mistral, Together, etc.
        tool_choice_
    end

    ## Build the API kwargs
    api_kwargs = if json_mode == true
        @assert length(tools)==1 "Only 1 tool definition is allowed in JSON mode."
        (; [k => v for (k, v) in pairs(api_kwargs) if k != :tool_choice]...,
            response_format = (;
                type = "json_schema", json_schema = only(tools)[:function]))
    elseif isempty(tools)
        api_kwargs
    else
        merge(api_kwargs, (; tools, tool_choice))
    end

    ## Find the unique ID for the model alias provided
    model_id = get(MODEL_ALIASES, model, model)
    ## Vision-specific functionality -- if `image_path` is provided, attach images to the latest user message
    !isnothing(image_path) &&
        (prompt = attach_images_to_user_message(
            prompt; image_path, attach_to_latest = true))
    ## Render the conversation history from messages
    conv_rendered = render(
        prompt_schema, prompt; conversation, no_system_message, name_user, kwargs...)

    if !dry_run
        time = @elapsed r = create_chat(prompt_schema, api_key,
            model_id,
            conv_rendered;
            http_kwargs,
            api_kwargs...)
        ## Process one of more samples returned
        has_many_samples = length(r.response[:choices]) > 1
        run_id = Int(rand(Int32)) # remember one run ID
        ## extract all message
        msg = [response_to_message(prompt_schema, AIToolRequest, choice, r;
                   tool_map = tool_map, time, model_id, run_id, json_mode,
                   sample_id = has_many_samples ? i : nothing, name_assistant)
               for (i, choice) in enumerate(r.response[:choices])]
        ## Order by log probability if available
        ## bigger is better, keep it last
        msg = if has_many_samples && all(x -> !isnothing(x.log_prob), msg)
            sort(msg, by = x -> x.log_prob)
        elseif has_many_samples
            msg
        else
            only(msg)
        end
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
        no_system_message,
        dry_run,
        kwargs...)

    return output
end
