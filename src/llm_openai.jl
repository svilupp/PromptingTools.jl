## Rendering of converation history for the OpenAI API
"Builds a history of the conversation to provide the prompt to the API. All kwargs are passed as replacements such that `{{key}}=>value` in the template.}}"
function render(schema::AbstractOpenAISchema,
        messages::Vector{<:AbstractMessage};
        kwargs...)
    ##
    conversation = Dict{String, String}[]
    # TODO: concat system messages together
    # TODO: move system msg to the front

    has_system_msg = false
    # replace any handlebar variables in the messages
    for msg in messages
        if msg isa SystemMessage
            replacements = ["{{$(key)}}" => value
                            for (key, value) in pairs(kwargs) if key in msg.variables]
            # move it to the front
            pushfirst!(conversation,
                Dict("role" => "system",
                    "content" => replace(msg.content, replacements...)))
            has_system_msg = true
        elseif msg isa UserMessage
            replacements = ["{{$(key)}}" => value
                            for (key, value) in pairs(kwargs) if key in msg.variables]
            push!(conversation,
                Dict("role" => "user", "content" => replace(msg.content, replacements...)))
        elseif msg isa AIMessage
            push!(conversation,
                Dict("role" => "assistant", "content" => msg.content))
        end
        # Note: Ignores any DataMessage or other types
    end
    ## Add default system prompt if not provided
    !has_system_msg && pushfirst!(conversation,
        Dict("role" => "system", "content" => "Act as a helpful AI assistant"))

    return conversation
end

## User-Facing API
"""
    aigenerate([prompt_schema::AbstractOpenAISchema,] prompt::ALLOWED_PROMPT_TYPE; verbose::Bool = true,
        model::String = MODEL_CHAT,
        http_kwargs::NamedTuple = (;
            retry_non_idempotent = true,
            retries = 5,
            readtimeout = 120), api_kwargs::NamedTuple = NamedTuple(),
        kwargs...)

Generate an AI response based on a given prompt using the OpenAI API.

# Arguments
- `prompt_schema`: An optional object to specify which prompt template should be applied (Default to `PROMPT_SCHEMA = OpenAISchema`)
- `prompt`: Can be a string representing the prompt for the AI conversation, a `UserMessage`, a vector of `AbstractMessage` or an `AITemplate`
- `verbose`: A boolean indicating whether to print additional information.
- `prompt_schema`: An abstract schema for the prompt.
- `api_key`: A string representing the API key for accessing the OpenAI API.
- `model`: A string representing the model to use for generating the response. Can be an alias corresponding to a model ID defined in `MODEL_ALIASES`.
- `http_kwargs`: A named tuple of HTTP keyword arguments.
- `api_kwargs`: A named tuple of API keyword arguments.
- `kwargs`: Prompt variables to be used to fill the prompt/template

# Returns
- `msg`: An `AIMessage` object representing the generated AI message, including the content, status, tokens, and elapsed time.

See also: `ai_str`

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
conversation = [
    SystemMessage("You're master Yoda from Star Wars trying to help the user become a Yedi."),
    UserMessage("I have feelings for my iPhone. What should I do?")]
msg=aigenerate(conversation)
# AIMessage("Ah, strong feelings you have for your iPhone. A Jedi's path, this is not... <continues>")
```
"""
function aigenerate(prompt_schema::AbstractOpenAISchema, prompt::ALLOWED_PROMPT_TYPE;
        verbose::Bool = true,
        api_key::String = API_KEY,
        model::String = MODEL_CHAT,
        http_kwargs::NamedTuple = (retry_non_idempotent = true,
            retries = 5,
            readtimeout = 120), api_kwargs::NamedTuple = NamedTuple(),
        kwargs...)
    ##
    global MODEL_ALIASES, MODEL_COSTS
    ## Find the unique ID for the model alias provided
    model_id = get(MODEL_ALIASES, model, model)
    conversation = render(prompt_schema, prompt; kwargs...)
    time = @elapsed r = create_chat(prompt_schema, api_key,
        model_id,
        conversation;
        http_kwargs,
        api_kwargs...)
    msg = AIMessage(; content = r.response[:choices][begin][:message][:content] |> strip,
        status = Int(r.status),
        tokens = (r.response[:usage][:prompt_tokens],
            r.response[:usage][:completion_tokens]),
        elapsed = time)
    ## Reporting
    verbose && @info _report_stats(msg, model_id, MODEL_COSTS)

    return msg
end
# Extend OpenAI create_chat to allow for testing/debugging
function OpenAI.create_chat(schema::AbstractOpenAISchema,
        api_key::AbstractString,
        model::AbstractString,
        conversation;
        kwargs...)
    OpenAI.create_chat(api_key, model, conversation; kwargs...)
end
function OpenAI.create_chat(schema::TestEchoOpenAISchema, api_key::AbstractString,
        model::AbstractString,
        conversation; kwargs...)
    schema.model_id = model
    schema.inputs = conversation
    return schema
end

"""
    aiembed(prompt_schema::AbstractOpenAISchema,
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
- `prompt_schema::AbstractOpenAISchema`: The schema for the prompt.
- `doc_or_docs::Union{AbstractString, Vector{<:AbstractString}}`: The document or list of documents to generate embeddings for.
- `postprocess::F`: The post-processing function to apply to each embedding. Defaults to the identity function.
- `verbose::Bool`: A flag indicating whether to print verbose information. Defaults to `true`.
- `api_key::String`: The API key to use for the OpenAI API. Defaults to `API_KEY`.
- `model::String`: The model to use for generating embeddings. Defaults to `MODEL_EMBEDDING`.
- `http_kwargs::NamedTuple`: Additional keyword arguments for the HTTP request. Defaults to `(retry_non_idempotent = true, retries = 5, readtimeout = 120)`.
- `api_kwargs::NamedTuple`: Additional keyword arguments for the OpenAI API. Defaults to an empty `NamedTuple`.
- `kwargs...`: Additional keyword arguments.

## Returns
- `msg`: A `DataMessage` object containing the embeddings, status, token count, and elapsed time.

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
        doc_or_docs::Union{AbstractString, Vector{<:AbstractString}},
        postprocess::F = identity; verbose::Bool = true,
        api_key::String = API_KEY,
        model::String = MODEL_EMBEDDING,
        http_kwargs::NamedTuple = (retry_non_idempotent = true,
            retries = 5,
            readtimeout = 120), api_kwargs::NamedTuple = NamedTuple(),
        kwargs...) where {F <: Function}
    ##
    global MODEL_ALIASES, MODEL_COSTS
    ## Find the unique ID for the model alias provided
    model_id = get(MODEL_ALIASES, model, model)
    time = @elapsed r = create_embeddings(prompt_schema, api_key,
        doc_or_docs,
        model_id;
        http_kwargs,
        api_kwargs...)
    @info r.response |> typeof
    msg = DataMessage(;
        content = mapreduce(x -> postprocess(x[:embedding]), hcat, r.response[:data]),
        status = Int(r.status),
        tokens = (r.response[:usage][:prompt_tokens], 0),
        elapsed = time)
    ## Reporting
    verbose && @info _report_stats(msg, model_id, MODEL_COSTS)

    return msg
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
