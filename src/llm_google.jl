## Rendering of converation history for the OpenAI API
"""
    render(schema::AbstractGoogleSchema,
        messages::Vector{<:AbstractMessage};
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        kwargs...)

Builds a history of the conversation to provide the prompt to the API. All unspecified kwargs are passed as replacements such that `{{key}}=>value` in the template.

# Keyword Arguments
- `conversation`: An optional vector of `AbstractMessage` objects representing the conversation history. If not provided, it is initialized as an empty vector.

"""
function render(schema::AbstractGoogleSchema,
        messages::Vector{<:AbstractMessage};
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        kwargs...)
    ##
    ## First pass: keep the message types but make the replacements provided in `kwargs`
    messages_replaced = render(NoSchema(), messages; conversation, kwargs...)

    ## Second pass: convert to the OpenAI schema
    conversation = Dict{String, Any}[]

    # replace any handlebar variables in the messages
    for msg in messages_replaced
        role = if msg isa SystemMessage
            ## No system message, we need to merge with UserMessage, see below
            "user"
        elseif msg isa UserMessage
            "user"
        elseif msg isa AIMessage
            "model"
        end
        push!(conversation, Dict("role" => role, "parts" => [Dict("text" => msg.content)]))
    end
    ## Merge any subsequent UserMessages
    merged_conversation = Dict{String, Any}[]
    # run n-1 times, look at the current item and the next one
    i = 1
    while i <= (length(conversation) - 1)
        next_i = i + 1
        if conversation[i]["role"] == "user" && conversation[next_i]["role"] == "user"
            ## Concat the user messages to together, put two newlines
            txt1 = conversation[i]["parts"][1]["text"]
            txt2 = conversation[next_i]["parts"][1]["text"]
            merged_text = isempty(txt1) || isempty(txt2) ? txt1 * txt2 :
                          txt1 * "\n\n" * txt2
            new_msg = Dict("role" => "user", "parts" => [Dict("text" => merged_text)])
            push!(merged_conversation, new_msg)
            i += 2
        else
            push!(merged_conversation, conversation[i])
            i += 1
        end
    end
    return merged_conversation
end

"Stub - to be extended in extension: GoogleGenAIPromptingToolsExt. `ggi` stands for GoogleGenAI"
function ggi_generate_content end
function ggi_generate_content(schema::TestEchoGoogleSchema, api_key::AbstractString,
        model::AbstractString,
        conversation; kwargs...)
    schema.model_id = model
    schema.inputs = conversation
    return schema
end

## User-Facing API
"""
    aigenerate(prompt_schema::AbstractGoogleSchema, prompt::ALLOWED_PROMPT_TYPE;
        verbose::Bool = true,
        api_key::String = GOOGLE_API_KEY,
        model::String = "gemini-pro", return_all::Bool = false, dry_run::Bool = false,
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
function aigenerate(prompt_schema::AbstractGoogleSchema, prompt::ALLOWED_PROMPT_TYPE;
        verbose::Bool = true,
        api_key::String = GOOGLE_API_KEY,
        model::String = "gemini-pro", return_all::Bool = false, dry_run::Bool = false,
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        http_kwargs::NamedTuple = (retry_non_idempotent = true,
            retries = 5,
            readtimeout = 120), api_kwargs::NamedTuple = NamedTuple(),
        kwargs...)
    ##
    global MODEL_ALIASES

    ## Check that package GoogleGenAI is loaded
    ext = Base.get_extension(PromptingTools, :GoogleGenAIPromptingToolsExt)
    if isnothing(ext)
        error("you need to also import GoogleGenAI package to use this function")
    end

    ## Find the unique ID for the model alias provided
    model_id = get(MODEL_ALIASES, model, model)
    conv_rendered = render(prompt_schema, prompt; conversation, kwargs...)

    if !dry_run
        time = @elapsed r = ggi_generate_content(prompt_schema, api_key,
            model_id,
            conv_rendered;
            http_kwargs,
            api_kwargs...)
        msg = AIMessage(;
            content = r.text |> strip,
            status = 200,
            tokens = (0, 0),
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