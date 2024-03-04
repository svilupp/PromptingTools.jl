# STOPWORDS - used for annotation highlighting
# Just a small list to
const STOPWORDS = [
    "a", "an", "the", "and", "is", "isn't", "are", "aren't", "be", "was", "wasn't", "been",
    "will", "won't", "would", "wouldn't",
    "have", "haven't", "has", "hasn't", "do", "don't", "does", "did", "to",
    "from", "go", "goes", "went", "gone", "at",
    "into", "on", "or", "but", "per", "so", "then", "than",
    "what", "why", "who", "where", "whom", "which", "that", "with",
    "its", "their"] |> x -> vcat(x, titlecase.(x))
# "if","else","elseif", "in", "for", "let","for", 

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
