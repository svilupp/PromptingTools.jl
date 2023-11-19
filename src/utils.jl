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
