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
replace_words(text::AbstractString, words::Vector{<:AbstractString}; replacement::AbstractString = "ABC") = replace_words(
    text,
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
    recursive_splitter(text::String; separator::String=" ", max_length::Int=35000) -> Vector{String}

Split a given string `text` into chunks of a specified maximum length `max_length`. 
This is particularly useful for splitting larger documents or texts into smaller segments, suitable for models or systems with smaller context windows.

There is a method for dispatching on multiple separators, `recursive_splitter(text::String, separators::Vector{String}; max_length::Int=35000) -> Vector{String}` that mimics the logic of Langchain's `RecursiveCharacterTextSplitter`.

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
chunks = recursive_splitter(text; max_length=13)
length(chunks) # Output: 2
```

Using a custom separator and custom `max_length`
```julia
text = "Hello,World," ^ 2900 # length 34900 chars
recursive_splitter(text; separator=",", max_length=10000) # for 4K context window
length(chunks[1]) # Output: 4
```
"""
function recursive_splitter(text::String;
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
function recursive_splitter(text::String,
        separator::String,
        max_length::Int = 35000)
    recursive_splitter(text; separator, max_length)
end

"""
    recursive_splitter(text::AbstractString, separators::Vector{String}; max_length::Int=35000) -> Vector{String}

Split a given string `text` into chunks recursively using a series of separators, with each chunk having a maximum length of `max_length` (if it's achievable given the `separators` provided). 
This function is useful for splitting large documents or texts into smaller segments that are more manageable for processing, particularly for models or systems with limited context windows.

It was previously known as `split_by_length`.

This is similar to Langchain's [`RecursiveCharacterTextSplitter`](https://python.langchain.com/docs/modules/data_connection/document_transformers/recursive_text_splitter).
To achieve the same behavior, use `separators=["\\n\\n", "\\n", " ", ""]`.

# Arguments
- `text::AbstractString`: The text to be split.
- `separators::Vector{String}`: An ordered list of separators used to split the text. The function iteratively applies these separators to split the text. Recommend to use `["\\n\\n", ". ", "\\n", " "]`
- `max_length::Int`: The maximum length of each chunk. Defaults to 35,000 characters. This length is considered after each iteration of splitting, ensuring chunks fit within specified constraints.

# Returns
`Vector{String}`: A vector of strings, where each string is a chunk of the original text that is smaller than or equal to `max_length`.

# Usage Tips
- I tend to prefer splitting on sentences (`". "`) before splitting on newline characters (`"\\n"`) to preserve the structure of the text. 
- What's the difference between `separators=["\\n"," ",""]` and `separators=["\\n"," "]`? 
  The former will split down to character level (`""`), so it will always achieve the `max_length` but it will split words (bad for context!)
  I prefer to instead set slightly smaller `max_length` but not split words.

# How It Works

- The function processes the text iteratively with each separator in the provided order. It then measures the length of each chunk and splits it further if it exceeds the `max_length`.
  If the chunks is "short enough", the subsequent separators are not applied to it.
- Each chunk is as close to `max_length` as possible (unless we cannot split it any further, eg, if the splitters are "too big" / there are not enough of them)
- If the `text` is empty, the function returns an empty array.
- Separators are re-added to the text chunks after splitting, preserving the original structure of the text as closely as possible. Apply `strip` if you do not need them.
- The function provides `separators` as the second argument to distinguish itself from its single-separator counterpart dispatch.

# Examples

Splitting text using multiple separators:
```julia
text = "Paragraph 1\\n\\nParagraph 2. Sentence 1. Sentence 2.\\nParagraph 3"
separators = ["\\n\\n", ". ", "\\n"] # split by paragraphs, sentences, and newlines (not by words)
chunks = recursive_splitter(text, separators, max_length=20)
```

Splitting text using multiple separators - with splitting on words:
```julia
text = "Paragraph 1\\n\\nParagraph 2. Sentence 1. Sentence 2.\\nParagraph 3"
separators = ["\\n\\n", ". ", "\\n", " "] # split by paragraphs, sentences, and newlines, words
chunks = recursive_splitter(text, separators, max_length=10)
```

Using a single separator:
```julia
text = "Hello,World," ^ 2900  # length 34900 characters
chunks = recursive_splitter(text, [","], max_length=10000)
```

To achieve the same behavior as Langchain's `RecursiveCharacterTextSplitter`, use `separators=["\\n\\n", "\\n", " ", ""]`.
```julia
text = "Paragraph 1\\n\\nParagraph 2. Sentence 1. Sentence 2.\\nParagraph 3"
separators = ["\\n\\n", "\\n", " ", ""]
chunks = recursive_splitter(text, separators, max_length=10)

```
"""
function recursive_splitter(
        text::AbstractString, separators::Vector{String};
        max_length::Int = 35000)
    @assert !isempty(separators) "`separators` can't be empty"
    separators_ = copy(separators)
    separator = popfirst!(separators_)
    chunks = recursive_splitter(text; separator, max_length)

    isempty(separators_) && return chunks
    ## Iteratively split by separators
    for separator in separators_
        chunks = mapreduce(text_ -> recursive_splitter(text_; max_length, separator),
            vcat,
            chunks)
    end

    return chunks
end
# Alias to keep compatibility
const split_by_length = recursive_splitter

"""
    wrap_string(str::String,
        text_width::Int = 20;
        newline::Union{AbstractString, AbstractChar} = '\n')

Breaks a string into lines of a given `text_width`.
Optionally, you can specify the `newline` character or string to use.

# Example:

```julia
wrap_string("Certainly, here's a function in Julia that will wrap a string according to the specifications:", 10) |> print
```
"""
function wrap_string(str::AbstractString,
        text_width::Int = 20;
        newline::Union{AbstractString, AbstractChar} = '\n')
    ## split only on spaces to make sure it doesn't remove newlines already in the text!
    words = split(str, " ")
    output = IOBuffer()
    current_line_length = 0

    for word in words
        word_length = length(word)
        if current_line_length + word_length > text_width
            if current_line_length > 0
                write(output, newline)
                current_line_length = 0
            end
            while word_length > text_width
                chop_idx = prevind(word, text_width, 1)
                write(output, word[1:(chop_idx)], "-$newline")
                start_idx = nextind(word, chop_idx, 1)
                word = word[start_idx:end]
                word_length -= text_width - 1
            end
        end
        if current_line_length > 0
            write(output, ' ')
            current_line_length += 1
        end
        write(output, word)
        current_line_length += word_length
    end

    return String(take!(output))
end;

"""
    length_longest_common_subsequence(itr1::AbstractString, itr2::AbstractString)

Compute the length of the longest common subsequence between two string sequences (ie, the higher the number, the better the match).

Source: https://cn.julialang.org/LeetCode.jl/dev/democards/problems/problems/1143.longest-common-subsequence/

# Arguments
- `itr1`: The first sequence, eg, a String.
- `itr2`: The second sequence, eg, a String.

# Returns
The length of the longest common subsequence.

# Examples
```julia
text1 = "abc-abc----"
text2 = "___ab_c__abc"
longest_common_subsequence(text1, text2)
# Output: 6 (-> "abcabc")
```

It can be used to fuzzy match strings and find the similarity between them (Tip: normalize the match)
```julia
commands = ["product recommendation", "emotions", "specific product advice", "checkout advice"]
query = "Which product can you recommend for me?"
let pos = argmax(length_longest_common_subsequence.(Ref(query), commands))
    dist = length_longest_common_subsequence(query, commands[pos])
    norm = dist / min(length(query), length(commands[pos]))
    @info "The closest command to the query: \"\$(query)\" is: \"\$(commands[pos])\" (distance: \$(dist), normalized: \$(norm))"
end
```

But it might be easier to use directly the convenience wrapper `distance_longest_common_subsequence`!

```
"""
function length_longest_common_subsequence(itr1::AbstractString, itr2::AbstractString)
    m, n = length(itr1) + 1, length(itr2) + 1
    dp = fill(0, m, n)

    for (i, x) in enumerate(itr1), (j, y) in enumerate(itr2)
        dp[i + 1, j + 1] = (x == y) ? (dp[i, j] + 1) :
                           max(dp[i, j + 1], dp[i + 1, j])
    end
    return dp[m, n]
end

"""
    distance_longest_common_subsequence(
        input1::AbstractString, input2::AbstractString)

    distance_longest_common_subsequence(
        input1::AbstractString, input2::AbstractVector{<:AbstractString})

Measures distance between two strings using the length of the longest common subsequence (ie, the lower the number, the better the match). Perfect match is `distance = 0.0`

Convenience wrapper around `length_longest_common_subsequence` to normalize the distances to 0-1 range.
There is a also a dispatch for comparing a string vs an array of strings.


# Notes
- Use `argmin` and `minimum` to find the position of the closest match and the distance, respectively.
- Matching with an empty string will always return 1.0 (worst match), even if the other string is empty as well (safety mechanism to avoid division by zero).


# Arguments
- `input1::AbstractString`: The first string to compare.
- `input2::AbstractString`: The second string to compare.

# Example

You can also use it to find the closest context for some AI generated summary/story:

```julia
context = ["The enigmatic stranger vanished as swiftly as a wisp of smoke, leaving behind a trail of unanswered questions.",
    "Beneath the shimmering moonlight, the ocean whispered secrets only the stars could hear.",
    "The ancient tree stood as a silent guardian, its gnarled branches reaching for the heavens.",
    "The melody danced through the air, painting a vibrant tapestry of emotions.",
    "Time flowed like a relentless river, carrying away memories and leaving imprints in its wake."]

story = \"\"\"
    Beneath the shimmering moonlight, the ocean whispered secrets only the stars could hear.

    Under the celestial tapestry, the vast ocean whispered its secrets to the indifferent stars. Each ripple, a murmured confidence, each wave, a whispered lament. The glittering celestial bodies listened in silent complicity, their enigmatic gaze reflecting the ocean's unspoken truths. The cosmic dance between the sea and the sky, a symphony of shared secrets, forever echoing in the ethereal expanse.
    \"\"\"

dist = distance_longest_common_subsequence(story, context)
@info "The closest context to the query: \"\$(first(story,20))...\" is: \"\$(context[argmin(dist)])\" (distance: \$(minimum(dist)))"
```
"""
function distance_longest_common_subsequence(
        input1::AbstractString, input2::AbstractString)
    if isempty(input1) || isempty(input2)
        return 1.0
    end
    similarity = length_longest_common_subsequence(input1, input2)
    shortest_length = min(length(input1), length(input2))
    # it's a distance, so 1.0 is the worst match, 0.0 is the best match (=no distance)
    return 1.0 - similarity / shortest_length
end
# Dispatch for arrays (eg, context)
function distance_longest_common_subsequence(
        input1::AbstractString, input2::AbstractVector{<:AbstractString})
    distance_longest_common_subsequence.(Ref(input1), input2)
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
    call_cost(prompt_tokens::Int, completion_tokens::Int, model::String;
        cost_of_token_prompt::Number = get(MODEL_REGISTRY,
            model,
            (; cost_of_token_prompt = 0.0)).cost_of_token_prompt,
        cost_of_token_generation::Number = get(MODEL_REGISTRY, model,
            (; cost_of_token_generation = 0.0)).cost_of_token_generation)

    call_cost(msg, model::String)

Calculate the cost of a call based on the number of tokens in the message and the cost per token.

# Arguments
- `prompt_tokens::Int`: The number of tokens used in the prompt.
- `completion_tokens::Int`: The number of tokens used in the completion.
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

cost1 = call_cost(10, 20, "model1")

# from message
msg1 = AIMessage(;tokens=[10, 20])  # 10 prompt tokens, 20 generation tokens
cost1 = call_cost(msg1, "model1")
# cost1 = 10 * 0.05 + 20 * 0.10 = 2.5

# Using custom token costs
cost2 = call_cost(10, 20, "model3"; cost_of_token_prompt = 0.08, cost_of_token_generation = 0.12)
# cost2 = 10 * 0.08 + 20 * 0.12 = 3.2
```
"""
function call_cost(prompt_tokens::Int, completion_tokens::Int, model::String;
        cost_of_token_prompt::Number = get(MODEL_REGISTRY,
            model,
            (; cost_of_token_prompt = 0.0)).cost_of_token_prompt,
        cost_of_token_generation::Number = get(MODEL_REGISTRY, model,
            (; cost_of_token_generation = 0.0)).cost_of_token_generation)
    cost = prompt_tokens * cost_of_token_prompt +
           completion_tokens * cost_of_token_generation
    return cost
end
function call_cost(msg, model::String)
    cost = if !isnothing(msg.cost)
        msg.cost
    else
        call_cost(msg.tokens[1], msg.tokens[2], model)
    end
    return cost
end
## dispatch for array -> take unique messages only (eg, for multiple samples we count only once)
function call_cost(conv::AbstractVector, model::String)
    sum_ = 0.0
    visited_runs = Set{Int}()
    for msg in conv
        if isnothing(msg.run_id) || (msg.run_id ∉ visited_runs)
            sum_ += call_cost(msg, model)
            push!(visited_runs, msg.run_id)
        end
    end
    return sum_
end

"""
call_cost_alternative()

Alternative cost calculation. Used to calculate cost of image generation with DALL-E 3 and similar.
"""
function call_cost_alternative(
        count_images, model; image_quality::Union{AbstractString, Nothing} = nothing,
        image_size::Union{AbstractString, Nothing} = nothing)
    global ALTERNATIVE_GENERATION_COSTS
    default_img_cost = 0.0 # per image
    if haskey(ALTERNATIVE_GENERATION_COSTS, model) && !isnothing(image_quality) &&
       !isnothing(image_size)
        model_costs = get(
            ALTERNATIVE_GENERATION_COSTS, model, Dict())
        quality_costs = get(model_costs, image_quality, Dict())
        size_costs = get(quality_costs, image_size, default_img_cost) * count_images
    else
        default_img_cost * count_images
    end
end

# helper to produce summary message of how many tokens were used and for how much
function _report_stats(msg,
        model::String)
    cost = call_cost(msg, model)
    cost_str = iszero(cost) ? "" : " @ Cost: \$$(round(cost; digits=4))"
    metadata_str = if !isnothing(msg.meta) && !isempty(msg.meta)
        " (Metadata: $(join([string(k, " => ", v) for (k, v) in msg.meta if v isa Number && !iszero(v)], ", ")))"
    else
        ""
    end
    return "Tokens: $(sum(msg.tokens))$(cost_str) in $(round(msg.elapsed;digits=1)) seconds$(metadata_str)"
end
## dispatch for array -> take last message
function _report_stats(msg::AbstractVector,
        model::String)
    _report_stats(last(msg), model)
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

"""
    @timeout(seconds, expr_to_run, expr_when_fails)

Simple macro to run an expression with a timeout of `seconds`. If the `expr_to_run` fails to finish in `seconds` seconds, `expr_when_fails` is returned.

# Example
```julia
x = @timeout 1 begin
    sleep(1.1)
    println("done")
    1
end "failed"

```
"""
macro timeout(seconds, expr_to_run, expr_when_fails)
    quote
        tsk = @task $(esc(expr_to_run))
        schedule(tsk)
        Timer($(esc(seconds))) do timer
            istaskdone(tsk) || Base.throwto(tsk, InterruptException())
        end
        try
            fetch(tsk)
        catch _
            $(esc(expr_when_fails))
        end
    end
end

"Utility for rendering the conversation (vector of messages) as markdown. REQUIRES the Markdown package to load the extension! See also `pprint`"
function preview end

"Utility for pretty printing PromptingTools types in REPL."
function pprint end

# show fallback
function pprint(io::IO, anything::Any; text_width::Int = displaysize(io)[2])
    show(io, anything)
end

function pprint(anything::Any;
        text_width = displaysize(stdout)[2], kwargs...)
    pprint(stdout, anything; text_width, kwargs...)
end

"""
    auth_header(api_key::Union{Nothing, AbstractString};
        bearer::Bool = true,
        x_api_key::Bool = false,
        extra_headers::AbstractVector = Vector{
            Pair{String, String},
        }[],
        kwargs...)

Creates the authentication headers for any API request. Assumes that the communication is done in JSON format.

# Arguments
- `api_key::Union{Nothing, AbstractString}`: The API key to be used for authentication. If `Nothing`, no authentication is used.
- `bearer::Bool`: Provide the API key in the `Authorization: Bearer ABC` format. Defaults to `true`.
- `x_api_key::Bool`: Provide the API key in the `Authorization: x-api-key: ABC` format. Defaults to `false`.
"""
function auth_header(api_key::Union{Nothing, AbstractString};
        bearer::Bool = true,
        x_api_key::Bool = false,
        extra_headers::AbstractVector = Vector{
            Pair{String, String},
        }[],
        kwargs...)
    @assert !(bearer && x_api_key) "Cannot use both `bearer` and `x_api_key`. Select only one format."
    @assert (bearer||x_api_key) "At least one of `bearer` and `x_api_key` must be selected."
    !isnothing(api_key) && isempty(api_key) &&
        throw(ArgumentError("`api_key` cannot be empty"))
    headers = [
        "Content-Type" => "application/json",
        "Accept" => "application/json",
        extra_headers...
    ]
    !isnothing(api_key) && bearer &&
        pushfirst!(headers, "Authorization" => "Bearer $api_key")
    !isnothing(api_key) && x_api_key &&
        pushfirst!(headers, "x-api-key" => "$api_key")
    return headers
end

"""
    unique_permutation(inputs::AbstractVector)

Returns indices of unique items in a vector `inputs`. Access the unique values as `inputs[unique_permutation(inputs)]`.
"""
function unique_permutation(inputs::AbstractVector)
    return unique(i -> inputs[i], eachindex(inputs))
end