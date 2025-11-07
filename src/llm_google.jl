## Rendering of converation history for the OpenAI API
## No system message, we need to merge with UserMessage, see below
function role4render(schema::AbstractGoogleSchema, msg::SystemMessage)
    "user"
end
function role4render(schema::AbstractGoogleSchema, msg::AIMessage)
    "model"
end
"""
    render(schema::AbstractGoogleSchema,
        messages::Vector{<:AbstractMessage};
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        no_system_message::Bool = false,
        kwargs...)

Builds a history of the conversation to provide the prompt to the API. All unspecified kwargs are passed as replacements such that `{{key}}=>value` in the template.

# Keyword Arguments
- `conversation`: An optional vector of `AbstractMessage` objects representing the conversation history. If not provided, it is initialized as an empty vector.
- `no_system_message::Bool=false`: If `true`, do not include the default system message in the conversation history OR convert any provided system message to a user message.
"""
function render(schema::AbstractGoogleSchema,
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

    ## Second pass: convert to the Google schema
    conversation = Dict{Symbol, Any}[]
    system_instruction = nothing

    # Extract system message if present
    for (idx, msg) in enumerate(messages_replaced)
        if isabstractannotationmessage(msg)
            continue
        elseif isa(msg, SystemMessage) && idx == 1 && !no_system_message
            # Extract system instruction from first message if it's a SystemMessage
            system_instruction = msg.content
        else
            push!(conversation,
                Dict(
                    :role => role4render(schema, msg), :parts => [Dict("text" => msg.content)]))
        end
    end

    ## Merge any subsequent UserMessages
    merged_conversation = Dict{Symbol, Any}[]
    # run n-1 times, look at the current item and the next one
    i = 1
    while i <= (length(conversation) - 1)
        next_i = i + 1
        if conversation[i][:role] == "user" && conversation[next_i][:role] == "user"
            ## Concat the user messages to together, put two newlines
            txt1 = conversation[i][:parts][1]["text"]
            txt2 = conversation[next_i][:parts][1]["text"]
            merged_text = isempty(txt1) || isempty(txt2) ? txt1 * txt2 :
                          txt1 * "\n\n" * txt2
            new_msg = Dict(:role => "user", :parts => [Dict("text" => merged_text)])
            push!(merged_conversation, new_msg)
            i += 2
        else
            push!(merged_conversation, conversation[i])
            i += 1
        end
    end
    ## Add last message
    if i == length(conversation)
        push!(merged_conversation, conversation[end])
    end

    # Return both conversation and system instruction
    return (; conversation = merged_conversation, system_instruction = system_instruction)
end

"""
Process Google API configuration arguments and create config dictionary.
Returns a dictionary of config arguments that can be used to create GoogleGenAI.GenerateContentConfig.
"""
function process_google_config(api_kwargs, system_instruction, http_kwargs)
    config_kwargs = Dict{Symbol, Any}()

    ext = Base.get_extension(PromptingTools, :GoogleGenAIPromptingToolsExt)
    if !isnothing(ext)
        GoogleGenAI = ext.GoogleGenAI

        unsupported_kwargs = Symbol[]
        for (k, v) in pairs(api_kwargs)
            if hasfield(GoogleGenAI.GenerateContentConfig, k)
                config_kwargs[k] = v
            else
                push!(unsupported_kwargs, k)
            end
        end

        if !isempty(unsupported_kwargs)
            @warn "The following api_kwargs are not supported in the new GoogleGenAI interface and will be ignored: $(join(unsupported_kwargs, ", "))"
        end
    else
        for (k, v) in pairs(api_kwargs)
            config_kwargs[k] = v
        end
    end

    if !isnothing(system_instruction)
        config_kwargs[:system_instruction] = system_instruction
    end

    config_kwargs[:http_options] = http_kwargs

    return config_kwargs
end

"Stub - to be extended in extension: GoogleGenAIPromptingToolsExt. `ggi` stands for GoogleGenAI"
function ggi_generate_content end
function ggi_generate_content(schema::TestEchoGoogleSchema, api_key::AbstractString,
        model::AbstractString,
        conversation; system_instruction = nothing, http_kwargs = NamedTuple(),
        api_kwargs = NamedTuple(), kwargs...)
    schema.model_id = model
    schema.inputs = conversation
    config_kwargs = process_google_config(api_kwargs, system_instruction, http_kwargs)
    schema.config_kwargs = config_kwargs
    return schema
end

## User-Facing API
"""
    aigenerate(prompt_schema::AbstractGoogleSchema, prompt::ALLOWED_PROMPT_TYPE;
        verbose::Bool = true,
        api_key::String = "",
        model::String = "gemini-pro", return_all::Bool = false, dry_run::Bool = false,
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        no_system_message::Bool = false,
        http_kwargs::NamedTuple = (retry_non_idempotent = true,
            retries = 5,
            readtimeout = 120), api_kwargs::NamedTuple = NamedTuple(),
        kwargs...)

Generate an AI response based on a given prompt using the Google Gemini API. Get the API key [here](https://ai.google.dev/).

Note: 
- There is no "cost" reported as of February 2024, as all access seems to be free-of-charge. See the details [here](https://ai.google.dev/pricing).
- `tokens` in the returned AIMessage are actually characters, not tokens. We use a _conservative_ estimate as they are not provided by the API yet.

# Arguments
- `prompt_schema`: An optional object to specify which prompt template should be applied (Default to `PROMPT_SCHEMA = OpenAISchema`)
- `prompt`: Can be a string representing the prompt for the AI conversation, a `UserMessage`, a vector of `AbstractMessage` or an `AITemplate`
- `verbose`: A boolean indicating whether to print additional information.
- `api_key`: A string representing the API key for accessing the Google Gemini API. If not provided, loads from `GOOGLE_API_KEY` environment variable.
- `model`: A string representing the model to use for generating the response. Can be an alias corresponding to a model ID defined in `MODEL_ALIASES`. Defaults to 
- `return_all::Bool=false`: If `true`, returns the entire conversation history, otherwise returns only the last message (the `AIMessage`).
- `dry_run::Bool=false`: If `true`, skips sending the messages to the model (for debugging, often used with `return_all=true`).
- `conversation`: An optional vector of `AbstractMessage` objects representing the conversation history. If not provided, it is initialized as an empty vector.
- `no_system_message::Bool=false`: If `true`, do not include the default system message in the conversation history OR convert any provided system message to a user message.
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
result = aigenerate("Say Hi!"; model="gemini-pro")
# AIMessage("Hi there! 👋 I'm here to help you with any questions or tasks you may have. Just let me know what you need, and I'll do my best to assist you.")
```

`result` is an `AIMessage` object. Access the generated string via `content` property:
```julia
typeof(result) # AIMessage{SubString{String}}
propertynames(result) # (:content, :status, :tokens, :elapsed
result.content # "Hi there! ...
```
___
You can use string interpolation and alias "gemini":
```julia
a = 1
msg=aigenerate("What is `\$a+\$a`?"; model="gemini")
msg.content # "1+1 is 2."
```
___
You can provide the whole conversation or more intricate prompts as a `Vector{AbstractMessage}`:
```julia
const PT = PromptingTools

conversation = [
    PT.SystemMessage("You're master Yoda from Star Wars trying to help the user become a Yedi."),
    PT.UserMessage("I have feelings for my iPhone. What should I do?")]
msg=aigenerate(conversation; model="gemini")
# AIMessage("Young Padawan, you have stumbled into a dangerous path.... <continues>")
```
"""
function aigenerate(prompt_schema::AbstractGoogleSchema, prompt::ALLOWED_PROMPT_TYPE;
        verbose::Bool = true,
        api_key::String = "",
        model::String = "gemini-pro", return_all::Bool = false, dry_run::Bool = false,
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        no_system_message::Bool = false,
        http_kwargs::NamedTuple = (retry_non_idempotent = true,
            retries = 5,
            readtimeout = 120), api_kwargs::NamedTuple = NamedTuple(),
        kwargs...)
    ##
    global MODEL_ALIASES
    ## Use explicit api_key if provided, otherwise fall back to environment variable
    api_key = !isempty(api_key) ? api_key : GOOGLE_API_KEY

    ## Check that package GoogleGenAI is loaded
    ext = Base.get_extension(PromptingTools, :GoogleGenAIPromptingToolsExt)
    if isnothing(ext) && !(prompt_schema isa TestEchoGoogleSchema)
        throw(ArgumentError("You need to also import GoogleGenAI package to use this function"))
    end

    ## Check for valid API key (skip validation for test schemas)
    if !isa(prompt_schema, TestEchoGoogleSchema) &&
       (isempty(api_key) || api_key == "invalid-key-just-for-testing")
        throw(ArgumentError("Google API key is required. Get your key from https://ai.google.dev/"))
    end

    ## Find the unique ID for the model alias provided
    model_id = get(MODEL_ALIASES, model, model)
    rendered = render(
        prompt_schema, prompt; conversation, no_system_message, kwargs...)
    conv_rendered = rendered.conversation
    system_instruction = rendered.system_instruction

    if !dry_run
        time = @elapsed r = ggi_generate_content(prompt_schema, api_key,
            model_id,
            conv_rendered;
            system_instruction,
            http_kwargs,
            api_kwargs...)
        ## Big overestimate
        input_token_estimate = length(JSON3.write(conv_rendered))
        output_token_estimate = length(r.text)
        msg = AIMessage(;
            content = r.text |> strip,
            status = convert(Int, r.response_status),
            ## for google it's CHARACTERS, not tokens
            tokens = (input_token_estimate, output_token_estimate),
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

function aitools(prompt_schema::AbstractGoogleSchema, prompt::ALLOWED_PROMPT_TYPE;
        kwargs...)
    error("Google schema does not yet support aitools. Please use OpenAISchema instead.")
end
function aiembed(prompt_schema::AbstractGoogleSchema, prompt::ALLOWED_PROMPT_TYPE;
        kwargs...)
    error("Google schema does not yet support aiembed. Please use OpenAISchema instead.")
end
function aiclassify(prompt_schema::AbstractGoogleSchema, prompt::ALLOWED_PROMPT_TYPE;
        kwargs...)
    error("Google schema does not yet support aiclassify. Please use OpenAISchema instead.")
end
function aiextract(prompt_schema::AbstractGoogleSchema, prompt::ALLOWED_PROMPT_TYPE;
        kwargs...)
    error("Google schema does not yet support aiextract. Please use OpenAISchema instead.")
end
function aiscan(prompt_schema::AbstractGoogleSchema, prompt::ALLOWED_PROMPT_TYPE;
        kwargs...)
    error("Google schema does not yet support aiscan. Please use OpenAISchema instead.")
end
function aiimage(prompt_schema::AbstractGoogleSchema, prompt::ALLOWED_PROMPT_TYPE;
        kwargs...)
    error("Google schema does not yet support aiimage. Please use OpenAISchema instead.")
end
