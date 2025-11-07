## Ollama Chat API
# - llm_olama.jl works by providing messages format to /api/chat
# - llm_managed_olama.jl works by providing 1 system prompt and 1 user prompt /api/generate
#
# TODO: switch to OpenAI-compatible endpoint!
#
## Schema dedicated to [Ollama's models](https://ollama.ai/), which also managed the prompt templates
#
## Rendering of converation history for the Ollama API (similar to OpenAI but not for the images)

"""
    render(schema::AbstractOllamaSchema,
        messages::Vector{<:AbstractMessage};
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        no_system_message::Bool = false,
        kwargs...)

Builds a history of the conversation to provide the prompt to the API. All unspecified kwargs are passed as replacements such that `{{key}}=>value` in the template.

# Keyword Arguments
- `conversation`: An optional vector of `AbstractMessage` objects representing the conversation history. If not provided, it is initialized as an empty vector.
- `no_system_message`: If `true`, do not include the default system message in the conversation history OR convert any provided system message to a user message.
"""
function render(schema::AbstractOllamaSchema,
        messages::Vector{<:AbstractMessage};
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        no_system_message::Bool = false,
        kwargs...)
    ##
    # Filter out annotation messages before any processing
    messages = filter(!isabstractannotationmessage, messages)

    ## First pass: keep the message types but make the replacements provided in `kwargs`
    messages_replaced = render(
        NoSchema(), messages; conversation, no_system_message, kwargs...)

    ## Second pass: convert to the OpenAI schema
    conversation = Dict{String, Any}[]

    # replace any handlebar variables in the messages
    for msg in messages_replaced
        if isabstractannotationmessage(msg)
            continue
        end
        new_message = Dict{String, Any}(
            "role" => role4render(schema, msg), "content" => msg.content)
        ## Special case for images
        if msg isa UserMessageWithImages
            new_message["images"] = msg.image_url
        end
        push!(conversation, new_message)
    end

    return conversation
end

## Ollama back-end
# uses ollama_api defined in src/llm_ollama_managed.jl
function ollama_api(prompt_schema::TestEchoOllamaSchema,
        prompt::Union{AbstractString, Nothing} = nothing;
        system::Union{Nothing, AbstractString} = nothing,
        messages = [],
        endpoint::String = "generate",
        model::String = "llama2", kwargs...)
    prompt_schema.model_id = model
    prompt_schema.inputs = messages
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
- `streamcallback`: A callback function to handle streaming responses. Can be simply `stdout` or a `StreamCallback` object. See `?StreamCallback` for details.
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
schema = PT.OllamaSchema() # We need to explicit if we want Ollama, OpenAISchema is the default

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
schema = PT.OllamaSchema()
a = 1
msg=aigenerate(schema, "What is `\$a+\$a`?"; model="openhermes2.5-mistral")
msg.content # "The result of `1+1` is `2`."
```
___
You can provide the whole conversation or more intricate prompts as a `Vector{AbstractMessage}`:
```julia
const PT = PromptingTools
schema = PT.OllamaSchema()

conversation = [
    PT.SystemMessage("You're master Yoda from Star Wars trying to help the user become a Yedi."),
    PT.UserMessage("I have feelings for my iPhone. What should I do?")]

msg = aigenerate(schema, conversation; model="openhermes2.5-mistral")
# [ Info: Tokens: 111 in 2.1 seconds
# AIMessage("Strong the attachment is, it leads to suffering it may. Focus on the force within you must, ...<continues>")
```

To add streaming, use the `streamcallback` argument.
```julia
msg = aigenerate("Count from 1 to 10."; streamcallback = stdout)
```

Or if you prefer to have more control, use a `StreamCallback` object. 
```julia
streamcallback = PT.StreamCallback()
msg = aigenerate("Count from 1 to 10."; streamcallback)
```

WARNING: If you provide a `StreamCallback` object with a `flavor`, we assume you want to configure everything yourself, so you need to make sure to set `stream = true` in the `api_kwargs`!
```julia
streamcallback = PT.StreamCallback(; flavor = PT.OllamaStream())
msg = aigenerate("Count from 1 to 10."; streamcallback, api_kwargs = (; stream = true))
```

"""
function aigenerate(prompt_schema::AbstractOllamaSchema, prompt::ALLOWED_PROMPT_TYPE;
        verbose::Bool = true,
        api_key::String = "",
        model::String = MODEL_CHAT,
        return_all::Bool = false, dry_run::Bool = false,
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        no_system_message::Bool = false,
        streamcallback::Any = nothing,
        http_kwargs::NamedTuple = NamedTuple(), api_kwargs::NamedTuple = NamedTuple(),
        kwargs...)
    ##
    global MODEL_ALIASES
    ## Find the unique ID for the model alias provided
    model_id = get(MODEL_ALIASES, model, model)
    conv_rendered = render(
        prompt_schema, prompt; conversation, no_system_message, kwargs...)

    if !dry_run
        time = @elapsed resp = ollama_api(prompt_schema, nothing;
            system = nothing, messages = conv_rendered, endpoint = "chat", model = model_id,
            http_kwargs, streamcallback,
            api_kwargs...)

        tokens_prompt = get(resp.response, :prompt_eval_count, 0)
        tokens_completion = get(resp.response, :eval_count, 0)
        msg = AIMessage(; content = resp.response[:message][:content] |> strip,
            status = Int(resp.status),
            cost = call_cost(tokens_prompt, tokens_completion, model_id),
            ## not coming through yet anyway
            ## finish_reason = get(resp.response, :finish_reason, nothing),
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
        no_system_message,
        kwargs...)
    return output
end

function aiembed(prompt_schema::AbstractOllamaSchema, args...; kwargs...)
    aiembed(OllamaManagedSchema(), args...; kwargs...)
end

"""
    aiscan([prompt_schema::AbstractOllamaSchema,] prompt::ALLOWED_PROMPT_TYPE; 
    image_url::Union{Nothing, AbstractString, Vector{<:AbstractString}} = nothing,
    image_path::Union{Nothing, AbstractString, Vector{<:AbstractString}} = nothing,
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
- `api_key`: A string representing the API key for accessing the API. Defaults to an empty string.
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
msg = aiscan("Describe the image"; image_path="julia.png", model="bakllava")
# [ Info: Tokens: 1141 @ Cost: \$0.0117 in 2.2 seconds
# AIMessage("The image shows a logo consisting of the word "julia" written in lowercase")
```

You can provide multiple images at once as a vector and ask for "low" level of detail (cheaper):
```julia
msg = aiscan("Describe the image"; image_path=["julia.png","python.png"] model="bakllava")
```

You can use this function as a nice and quick OCR (transcribe text in the image) with a template `:OCRTask`. 
Let's transcribe some SQL code from a screenshot (no more re-typing!):

```julia
using Downloads
# Screenshot of some SQL code -- we cannot use image_url directly, so we need to download it first
image_url = "https://www.sqlservercentral.com/wp-content/uploads/legacy/8755f69180b7ac7ee76a69ae68ec36872a116ad4/24622.png"
image_path = Downloads.download(image_url)
msg = aiscan(:OCRTask; image_path, model="bakllava", task="Transcribe the SQL code in the image.", api_kwargs=(; max_tokens=2500))

# AIMessage("```sql
# update Orders <continue>

# You can add syntax highlighting of the outputs via Markdown
using Markdown
msg.content |> Markdown.parse
```

Local models cannot handle image URLs directly (`image_url`), so you need to download the image first and provide it as `image_path`:

```julia
using Downloads
image_path = Downloads.download(image_url)
```

Notice that we set `max_tokens = 2500`. If your outputs seem truncated, it might be because the default maximum tokens on the server is set too low!

"""
function aiscan(prompt_schema::AbstractOllamaSchema, prompt::ALLOWED_PROMPT_TYPE;
        image_url::Union{Nothing, AbstractString, Vector{<:AbstractString}} = nothing,
        image_path::Union{Nothing, AbstractString, Vector{<:AbstractString}} = nothing,
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
    ## Checks
    @assert isnothing(image_url) "Keyword `image_url` currently is not allowed for local models. Please download the file locally first with `image_path = Downloads.download(image_url)` and provide it as an `image_path`."
    ##
    global MODEL_ALIASES
    ## Find the unique ID for the model alias provided
    model_id = get(MODEL_ALIASES, model, model)
    ## Vision-specific functionality
    msgs = attach_images_to_user_message(prompt;
        image_url,
        image_path,
        attach_to_latest,
        base64_only = true)

    ## Build the conversation, pass what image detail is required (if provided)
    conv_rendered = render(prompt_schema, msgs; conversation, kwargs...)
    if !dry_run
        ## Model call
        time = @elapsed resp = ollama_api(prompt_schema, nothing;
            system = nothing, messages = conv_rendered, endpoint = "chat", model = model_id,
            http_kwargs,
            api_kwargs...)
        tokens_prompt = get(resp.response, :prompt_eval_count, 0)
        tokens_completion = get(resp.response, :eval_count, 0)
        msg = AIMessage(; content = resp.response[:message][:content] |> strip,
            status = Int(resp.status),
            cost = call_cost(tokens_prompt, tokens_completion, model_id),
            tokens = (tokens_prompt, tokens_completion),
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

function aiclassify(prompt_schema::AbstractOllamaSchema, prompt::ALLOWED_PROMPT_TYPE;
        kwargs...)
    error("Managed schema does not support aiclassify. Please use OpenAISchema instead.")
end
function aiextract(prompt_schema::AbstractOllamaSchema, prompt::ALLOWED_PROMPT_TYPE;
        kwargs...)
    error("Managed schema does not support aiextract. Please use OpenAISchema instead.")
end
function aitools(prompt_schema::AbstractOllamaSchema, prompt::ALLOWED_PROMPT_TYPE;
        kwargs...)
    error("Managed schema does not support aitools. Please use OpenAISchema instead.")
end
