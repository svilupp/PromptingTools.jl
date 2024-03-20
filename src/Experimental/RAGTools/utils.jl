# Utility to check model suitability
function _check_aiextract_capability(model::AbstractString)
    # Check that the provided model is known and that it is an OpenAI model (for the aiextract function to work)
    @assert haskey(PT.MODEL_REGISTRY,
        model)&&PT.MODEL_REGISTRY[model].schema isa PT.AbstractOpenAISchema "Only OpenAI models support the metadata extraction now. $model is not a registered OpenAI model."
end
# Utitity to be able to combine indices from different sources/documents easily
function merge_labeled_matrices(mat1::AbstractMatrix{T1},
        vocab1::Vector{String},
        mat2::AbstractMatrix{T2},
        vocab2::Vector{String}) where {T1 <: Number, T2 <: Number}
    T = promote_type(T1, T2)
    new_words = setdiff(vocab2, vocab1)
    combined_vocab = [vocab1; new_words]
    vocab2_indices = Dict(word => i for (i, word) in enumerate(vocab2))

    aligned_mat1 = hcat(mat1, zeros(T, size(mat1, 1), length(new_words)))
    aligned_mat2 = [haskey(vocab2_indices, word) ? @view(mat2[:, vocab2_indices[word]]) :
                    zeros(T, size(mat2, 1)) for word in combined_vocab]
    aligned_mat2 = aligned_mat2 |> Base.Splat(hcat)

    return vcat(aligned_mat1, aligned_mat2), combined_vocab
end

### Text Utilities
# STOPWORDS - used for annotation highlighting
# Just a small list to get started
const STOPWORDS = [
    "a", "an", "the", "and", "is", "isn't", "are", "aren't", "be", "was", "wasn't", "been",
    "will", "won't", "would", "wouldn't",
    "have", "haven't", "has", "hasn't", "do", "don't", "does", "did", "to",
    "from", "go", "goes", "went", "gone", "at",
    "into", "on", "or", "but", "per", "so", "then", "than",
    "what", "why", "who", "where", "whom", "which", "that", "with",
    "its", "their"] |> x -> vcat(x, titlecase.(x))
# Some stop words intentionally omitted as we want to track them for code:
# "if","else","elseif", "in", "for", "let","for",  

"""
    tokenize(input::Union{String, SubString{String}})

Tokenizes provided `input` by spaces, special characters or Julia symbols (eg, `=>`).

Unlike other tokenizers, it aims to lossless - ie, keep both the separated text and the separators.
"""
function tokenize(input::Union{String, SubString{String}})
    # specific to Julia language pattern, eg, capture macros (@xyz) or common operators (=>)
    pattern = r"(\s+|=>|\(;|,|\.|\(|\)|\{|\}|\[|\]|;|:|\+|-|\*|/|<|>|=|&|\||!|@\w+|@|#|\$|%|\^|~|`|\"|'|\w+)"
    SubString{String}[m.match for m in eachmatch(pattern, input)]
end

"""
    trigrams(input_string::AbstractString; add_word::AbstractString = "")

Splits provided `input_string` into a vector of trigrams (combination of three consecutive characters found in the `input_string`).

If `add_word` is provided, it is added to the resulting array. Useful to add the full word itself to the resulting array for exact match.
"""
function trigrams(input_string::AbstractString; add_word::AbstractString = "")
    trigrams = SubString{String}[]
    # Ensure the input string length is at least 3 to form a trigram
    if length(input_string) >= 3
        nunits = ncodeunits(input_string)
        i = 1
        while i <= nunits
            j = nextind(input_string, i, 2)
            if j <= nunits
                push!(trigrams, @views input_string[i:j])
                ## next starter
                i = nextind(input_string, i)
            else
                break
            end
        end
        ## else
        ##     push!(trigrams, convert(SubString{String}, input_string))
    end
    !isempty(add_word) && push!(trigrams, convert(SubString{String}, add_word))
    return trigrams
end

"""
    trigrams_hashed(input_string::AbstractString; add_word::AbstractString = "")

Splits provided `input_string` into a Set of hashed trigrams (combination of three consecutive characters found in the `input_string`).

It is more efficient for lookups in large strings (eg, >100K characters).

If `add_word` is provided, it is added to the resulting array to hash. Useful to add the full word itself to the resulting array for exact match.
"""
function trigrams_hashed(input_string::AbstractString; add_word::AbstractString = "")
    trigrams = Set{UInt64}()
    # Ensure the input string length is at least 3 to form a trigram
    if length(input_string) >= 3
        nunits = ncodeunits(input_string)
        i = 1
        while i <= nunits
            j = nextind(input_string, i, 2)
            if j <= nunits
                push!(trigrams, hash(@views input_string[i:j]))
                ## next starter
                i = nextind(input_string, i)
            else
                break
            end
        end
        ## else
        ##     push!(trigrams, hash(input_string))
    end
    !isempty(add_word) && push!(trigrams, hash(add_word))
    return trigrams
end

"""
    token_with_boundaries(
        prev_token::Union{Nothing, AbstractString}, curr_token::AbstractString,
        next_token::Union{Nothing, AbstractString})

Joins the three tokens together. Useful to add boundary tokens (like spaces vs brackets) to the `curr_token` to improve the matched context (ie, separate partial matches from exact match)
"""
function token_with_boundaries(
        prev_token::Union{Nothing, AbstractString}, curr_token::AbstractString,
        next_token::Union{Nothing, AbstractString})
    ##
    len1 = isnothing(prev_token) ? 0 : length(prev_token)
    len2 = length(curr_token)
    len3 = isnothing(next_token) ? 0 : length(next_token)

    ## concat only if single token boundaries!
    token = if len2 == 1
        curr_token
    elseif len1 == 1 && len3 == 1
        prev_token * curr_token * next_token
    elseif len1 == 0 && len3 == 1
        ## no prev_token, but next_token
        curr_token * next_token
    elseif len3 == 1
        curr_token * next_token
    elseif len1 == 1
        ## convert both len3=0 and len3>1
        prev_token * curr_token
    else
        curr_token
    end
end

function text_to_trigrams(input::Union{String, SubString{String}}; add_word::Bool = true)
    tokens = tokenize(input)
    length_toks = length(tokens)
    trig = SubString{String}[]
    prev_token = nothing
    for i in eachindex(tokens)
        next_tok = i == length_toks ? nothing : tokens[i + 1]
        curr_tok = tokens[i]
        ## if too short, skip the token
        if length(curr_tok) > 1
            ##     push!(trig, curr_tok)
            ## else
            full_tok = token_with_boundaries(prev_token, curr_tok, next_tok)
            if add_word
                append!(trig, trigrams(full_tok; add_word = curr_tok))
            else
                append!(trig, trigrams(full_tok))
            end
        end
        prev_token = curr_tok
    end
    return trig
end
function text_to_trigrams_hashed(input::AbstractString; add_word::Bool = true)
    tokens = tokenize(input)
    length_toks = length(tokens)
    trig = Set{UInt64}()
    prev_token = nothing
    for i in eachindex(tokens)
        next_tok = i == length_toks ? nothing : tokens[i + 1]
        curr_tok = tokens[i]
        ## if too short, just skip the token
        if length(curr_tok) > 1
            ##     push!(trig, hash(curr_tok))
            ## else
            full_tok = token_with_boundaries(prev_token, curr_tok, next_tok)
            if add_word
                union!(trig, trigrams_hashed(full_tok; add_word = curr_tok))
            else
                union!(trig, trigrams_hashed(full_tok))
            end
        end
        prev_token = curr_tok
    end
    return trig
end

"""
    split_into_code_and_sentences(input::Union{String, SubString{String}})

Splits text block into code or text and sub-splits into units.

If code block, it splits by newline but keep the `group_id` the same (to have the same source)
If text block, splits into sentences, bullets, etc., provides different `group_id` (to have different source)
"""
function split_into_code_and_sentences(input::Union{String, SubString{String}})
    # Combining the patterns for code blocks, inline code, and sentences in one regex
    # This pattern aims to match code blocks first, then inline code, and finally any text outside of code blocks as sentences or parts thereof.
    pattern = r"(```[\s\S]+?```)|(`[^`]*?`)|([^`]+)"

    ## Patterns for sentences: newline, tab, bullet, enumerate list, sentence, any left out characters
    sentence_pattern = r"(\n|\t|^\s*[*+-]\s*|^\s*\d+\.\s+|[^\n\t\.!?]+[\.!?]*|[*+\-\.!?])"ms

    # Initialize an empty array to store the split sentences
    sentences = SubString{String}[]
    group_ids = Int[]

    # Loop over the input string, searching for matches to the pattern
    i = 1
    for m in eachmatch(pattern, input)
        ## number of sub-parts
        j = 1
        # Extract the full match, including any delimiters
        match_block = m.match
        # Check if the match is a code block with triple backticks
        if startswith(match_block, "```")
            # Split code block by newline, retaining the backticks
            block_lines = split(match_block, "\n", keepempty = false)
            for (cnt, block) in enumerate(block_lines)
                push!(sentences, block)
                # all the lines of the chode block are the same group to have one source annotation
                push!(group_ids, i)
                if cnt < length(block_lines)
                    ## return newlines
                    push!(sentences, "\n")
                    push!(group_ids, i)
                end
            end
        elseif startswith(match_block, "`")
            push!(sentences, match_block)
            push!(group_ids, i)
        else
            ## Split text further
            j = 0
            for m_sent in eachmatch(sentence_pattern, match_block)
                push!(sentences, m_sent.match)
                push!(group_ids, i + j) # all sentences to have separate group
                j += 1
            end
        end
        ## increment counter
        i += j
    end

    return sentences, group_ids
end