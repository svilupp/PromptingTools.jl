### USEFUL BUT NOT EXPORTED FUNCTIONS

"""
    replace_words(text::AbstractString, words::Vector{<:AbstractString}; replacement::AbstractString="ABC")

Replace all occurrences of words in `words` with `replacement` in `text`. Useful to quickly remove specific names or entities from a text.

# Arguments
- `text::AbstractString`: The text to be processed.
- `words::Vector{<:AbstractString}`: A vector of words to be replaced.
- `replacement::AbstractString="ABC"`: The replacement string to be used. Defaults to "ABC".

# Example
```julia
text = "Disney is a great company"
replace_words(text, ["Disney", "Snow White", "Mickey Mouse"])
# Output: "ABC is a great company"
```
"""
replace_words(text::AbstractString, words::Vector{<:AbstractString}; replacement::AbstractString = "ABC") = replace_words(text,
    Regex("\\b$(join(words, "\\b|\\b"))\\b", "i"),
    replacement)
function replace_words(text::AbstractString, pattern::Regex, replacement::AbstractString)
    replace(text, pattern => replacement)
end
# dispatch for single word
function replace_words(text::AbstractString,
        word::AbstractString;
        replacement::AbstractString = "ABC")
    replace_words(text, [word]; replacement)
end

"""
    split_by_length(text::String; separator::String=" ", max_length::Int=35000) -> Vector{String}

Split a given string `text` into chunks of a specified maximum length `max_length`. 
This is particularly useful for splitting larger documents or texts into smaller segments, suitable for models or systems with smaller context windows.

# Arguments
- `text::String`: The text to be split.
- `separator::String=" "`: The separator used to split the text into minichunks. Defaults to a space character.
- `max_length::Int=35000`: The maximum length of each chunk. Defaults to 35,000 characters, which should fit within 16K context window.

# Returns
`Vector{String}`: A vector of strings, each representing a chunk of the original text that is smaller than or equal to `max_length`.

# Notes

- The function ensures that each chunk is as close to `max_length` as possible without exceeding it.
- If the `text` is empty, the function returns an empty array.
- The `separator` is re-added to the text chunks after splitting, preserving the original structure of the text as closely as possible.

# Examples

Splitting text with the default separator (" "):
```julia
text = "Hello world. How are you?"
chunks = splitbysize(text; max_length=13)
length(chunks) # Output: 2
```

Using a custom separator and custom `max_length`
```julia
text = "Hello,World," ^ 2900 # length 34900 chars
split_by_length(text; separator=",", max_length=10000) # for 4K context window
length(chunks[1]) # Output: 4
```
"""
function split_by_length(text::String;
        separator::String = " ",
        max_length::Int = 35000)
    ## shortcut
    length(text) <= max_length && return [text]

    ## split by separator
    minichunks = split(text, separator)
    sep_length = length(separator)
    chunks = String[]
    current_chunk = IOBuffer()
    current_length = 0
    for i in eachindex(minichunks)
        sep_length_ = i < length(minichunks) ? sep_length : 0
        # Check if the current chunk is full
        if current_length + length(minichunks[i]) + sep_length_ > max_length
            # Save chunk, excluding the current mini chunk
            save_chunk = String(take!(current_chunk))
            if length(save_chunk) > 0
                push!(chunks, save_chunk)
            end
            current_length = 0
        end
        write(current_chunk, minichunks[i])
        current_length += length(minichunks[i])
        if i < length(minichunks)
            write(current_chunk, separator)
            current_length += sep_length
        end
    end

    # Add the last chunk if it's not empty
    final_chunk = String(take!(current_chunk))
    if length(final_chunk) > 0
        push!(chunks, final_chunk)
    end

    return chunks
end

# Overload for dispatch on multiple separators
function split_by_length(text::String,
        separator::String,
        max_length::Int = 35000)
    split_by_length(text; separator, max_length)
end

"""
    split_by_length(text::String, separators::Vector{String}; max_length::Int=35000) -> Vector{String}

Split a given string `text` into chunks using a series of separators, with each chunk having a maximum length of `max_length`. 
This function is useful for splitting large documents or texts into smaller segments that are more manageable for processing, particularly for models or systems with limited context windows.

# Arguments
- `text::String`: The text to be split.
- `separators::Vector{String}`: An ordered list of separators used to split the text. The function iteratively applies these separators to split the text.
- `max_length::Int=35000`: The maximum length of each chunk. Defaults to 35,000 characters. This length is considered after each iteration of splitting, ensuring chunks fit within specified constraints.

# Returns
`Vector{String}`: A vector of strings, where each string is a chunk of the original text that is smaller than or equal to `max_length`.

# Notes

- The function processes the text iteratively with each separator in the provided order. This ensures more nuanced splitting, especially in structured texts.
- Each chunk is as close to `max_length` as possible without exceeding it (unless we cannot split it any further)
- If the `text` is empty, the function returns an empty array.
- Separators are re-added to the text chunks after splitting, preserving the original structure of the text as closely as possible. Apply `strip` if you do not need them.

# Examples

Splitting text using multiple separators:
```julia
text = "Paragraph 1\n\nParagraph 2. Sentence 1. Sentence 2.\nParagraph 3"
separators = ["\n\n", ". ", "\n"]
chunks = split_by_length(text, separators, max_length=20)
```

Using a single separator:
```julia
text = "Hello,World," ^ 2900  # length 34900 characters
chunks = split_by_length(text, [","], max_length=10000)
```
"""
function split_by_length(text, separators::Vector{String}; max_length)
    @assert !isempty(separators) "`separators` can't be empty"
    separator = popfirst!(separators)
    chunks = split_by_length(text; separator, max_length)

    isempty(separators) && return chunks
    ## Iteratively split by separators
    for separator in separators
        chunks = mapreduce(text_ -> split_by_length(text_; max_length, separator),
            vcat,
            chunks)
    end

    return chunks
end

### INTERNAL FUNCTIONS - DO NOT USE DIRECTLY
# helper to extract handlebar variables (eg, `{{var}}`) from a prompt string
function _extract_handlebar_variables(s::AbstractString)
    Symbol[Symbol(m[1]) for m in eachmatch(r"\{\{([^\}]+)\}\}", s)]
end
# create a method for Vector{Dict} in UserMessageWithImage to extract handlebar variables for Dict keys
function _extract_handlebar_variables(vect::Vector{Dict{String, <:AbstractString}})
    unique([_extract_handlebar_variables(v) for d in vect for (k, v) in d if k == "text"])
end

"""
    call_cost(msg, model::String;
              cost_of_token_prompt::Number = default_prompt_cost,
              cost_of_token_generation::Number = default_generation_cost) -> Number

Calculate the cost of a call based on the number of tokens in the message and the cost per token.

# Arguments
- `msg`: The message object, which should contain a `tokens` field
  with two elements: [number_of_prompt_tokens, number_of_generation_tokens].
- `model::String`: The name of the model to use for determining token costs. If the model
  is not found in `MODEL_REGISTRY`, default costs are used.
- `cost_of_token_prompt::Number`: The cost per prompt token. Defaults to the cost in `MODEL_REGISTRY`
  for the given model, or 0.0 if the model is not found.
- `cost_of_token_generation::Number`: The cost per generation token. Defaults to the cost in
  `MODEL_REGISTRY` for the given model, or 0.0 if the model is not found.

# Returns
- `Number`: The total cost of the call.

# Examples
```julia
# Assuming MODEL_REGISTRY is set up with appropriate costs
MODEL_REGISTRY = Dict(
    "model1" => (cost_of_token_prompt = 0.05, cost_of_token_generation = 0.10),
    "model2" => (cost_of_token_prompt = 0.07, cost_of_token_generation = 0.02)
)

msg1 = AIMessage([10, 20])  # 10 prompt tokens, 20 generation tokens
cost1 = call_cost(msg1, "model1")
# cost1 = 10 * 0.05 + 20 * 0.10 = 2.5

msg2 = DataMessage([15, 30])  # 15 prompt tokens, 30 generation tokens
cost2 = call_cost(msg2, "model2")
# cost2 = 15 * 0.07 + 30 * 0.02 = 1.35

# Using custom token costs
msg3 = AIMessage([5, 10])
cost3 = call_cost(msg3, "model3", cost_of_token_prompt = 0.08, cost_of_token_generation = 0.12)
# cost3 = 5 * 0.08 + 10 * 0.12 = 1.6
```
"""
function call_cost(msg, model::String;
        cost_of_token_prompt::Number = get(MODEL_REGISTRY,
            model,
            (; cost_of_token_prompt = 0.0)).cost_of_token_prompt,
        cost_of_token_generation::Number = get(MODEL_REGISTRY, model,
            (; cost_of_token_generation = 0.0)).cost_of_token_generation)
    cost = msg.tokens[1] * cost_of_token_prompt +
           msg.tokens[2] * cost_of_token_generation
    return cost
end
# helper to produce summary message of how many tokens were used and for how much
function _report_stats(msg,
        model::String)
    cost = call_cost(msg, model)
    cost_str = iszero(cost) ? "" : " @ Cost: \$$(round(cost; digits=4))"
    return "Tokens: $(sum(msg.tokens))$(cost_str) in $(round(msg.elapsed;digits=1)) seconds"
end
# Loads and encodes the provided image path as a base64 string
function _encode_local_image(image_path::AbstractString; base64_only::Bool = false)
    @assert isfile(image_path) "`image_path` must be a valid path to an image file. File: $image_path not found."
    base64_image = open(image_path, "r") do image_bytes
        base64encode(image_bytes)
    end
    if base64_only
        return base64_image
    else
        image_suffix = split(image_path, ".")[end]
        image_url = "data:image/$image_suffix;base64,$(base64_image)"
    end
    return image_url
end
function _encode_local_image(image_path::Vector{<:AbstractString};
        base64_only::Bool = false)
    return _encode_local_image.(image_path; base64_only)
end
_encode_local_image(::Nothing) = String[]

# Used for image_url in aiscan to provided consistent output type
_string_to_vector(s::AbstractString) = [s]
_string_to_vector(v::Vector{<:AbstractString}) = v

### Conversation Management

"""
    push_conversation!(conv_history, conversation::AbstractVector, max_history::Union{Int, Nothing})

Add a new conversation to the conversation history and resize the history if necessary.

This function appends a conversation to the `conv_history`, which is a vector of conversations. Each conversation is represented as a vector of `AbstractMessage` objects. After adding the new conversation, the history is resized according to the `max_history` parameter to ensure that the size of the history does not exceed the specified limit.

## Arguments
- `conv_history`: A vector that stores the history of conversations. Typically, this is `PT.CONV_HISTORY`.
- `conversation`: The new conversation to be added. It should be a vector of `AbstractMessage` objects.
- `max_history`: The maximum number of conversations to retain in the history. If `Nothing`, the history is not resized.

## Returns
The updated conversation history.

## Example
```julia
new_conversation = aigenerate("Hello World"; return_all = true)
push_conversation!(PT.CONV_HISTORY, new_conversation, 10)
```

This is done automatically by the ai"" macros.
"""
function push_conversation!(conv_history::Vector{<:Vector{<:Any}},
        conversation::AbstractVector,
        max_history::Union{Int, Nothing})
    push!(conv_history, conversation)
    resize_conversation!(conv_history, max_history)
    return conv_history
end

"""
    resize_conversation!(conv_history, max_history::Union{Int, Nothing})

Resize the conversation history to a specified maximum length.

This function trims the `conv_history` to ensure that its size does not exceed `max_history`. It removes the oldest conversations first if the length of `conv_history` is greater than `max_history`.

## Arguments
- `conv_history`: A vector that stores the history of conversations. Typically, this is `PT.CONV_HISTORY`.
- `max_history`: The maximum number of conversations to retain in the history. If `Nothing`, the history is not resized.

## Returns
The resized conversation history.

## Example
```julia
resize_conversation!(PT.CONV_HISTORY, PT.MAX_HISTORY_LENGTH)
```

After the function call, `conv_history` will contain only the 10 most recent conversations.

This is done automatically by the ai"" macros.

"""
function resize_conversation!(conv_history,
        max_history::Union{Int, Nothing})
    if isnothing(max_history)
        return
    end

    while length(conv_history) > max_history
        popfirst!(conv_history)
    end
    return conv_history
end