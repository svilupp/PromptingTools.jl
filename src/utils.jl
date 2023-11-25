### USEFUL BUT NOT EXPORTED FUNCTIONS
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
function split_by_length(text::String; separator::String = " ", max_length::Int = 35000)
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
### INTERNAL FUNCTIONS - DO NOT USE DIRECTLY
# helper to extract handlebar variables (eg, `{{var}}`) from a prompt string
function _extract_handlebar_variables(s::AbstractString)
    Symbol[Symbol(m[1]) for m in eachmatch(r"\{\{([^\}]+)\}\}", s)]
end
# create a method for Vector{Dict} in UserMessageWithImage to extract handlebar variables for Dict keys
function _extract_handlebar_variables(vect::Vector{Dict{String, <:AbstractString}})
    unique([_extract_handlebar_variables(v) for d in vect for (k, v) in d if k == "text"])
end

# helper to produce summary message of how many tokens were used and for how much
function _report_stats(msg, model::String, model_costs::AbstractDict = Dict())
    token_prices = get(model_costs, model, (0.0, 0.0))
    cost = sum(msg.tokens ./ 1000 .* token_prices)
    cost_str = iszero(cost) ? "" : " @ Cost: \$$(round(cost; digits=4))"

    return "Tokens: $(sum(msg.tokens))$(cost_str) in $(round(msg.elapsed;digits=1)) seconds"
end
# Loads and encodes the provided image path as a base64 string
function _encode_local_image(image_path::AbstractString)
    @assert isfile(image_path) "`image_path` must be a valid path to an image file. File: $image_path not found."
    base64_image = open(image_path, "r") do image_bytes
        base64encode(image_bytes)
    end
    image_suffix = split(image_path, ".")[end]
    image_url = "data:image/$image_suffix;base64,$(base64_image)"
    return image_url
end
function _encode_local_image(image_path::Vector{<:AbstractString})
    return _encode_local_image.(image_path)
end
_encode_local_image(::Nothing) = String[]

# Used for image_url in aiscan to provided consistent output type
_string_to_vector(s::AbstractString) = [s]
_string_to_vector(v::Vector{<:AbstractString}) = v
