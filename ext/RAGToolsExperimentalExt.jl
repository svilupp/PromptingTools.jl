module RAGToolsExperimentalExt

using PromptingTools, SparseArrays
using LinearAlgebra: normalize
const PT = PromptingTools

using PromptingTools.Experimental.RAGTools

# forward to LinearAlgebra.normalize
PromptingTools.Experimental.RAGTools._normalize(arr::AbstractArray) = normalize(arr)

# "Builds a sparse matrix of tags and a vocabulary from the given vector of chunk metadata. Requires SparseArrays.jl to be loaded."
function PromptingTools.Experimental.RAGTools.build_tags(chunk_metadata::Vector{
        Vector{String},
    })
    tags_vocab_ = vcat(chunk_metadata...) |> unique |> sort
    tags_vocab_index = Dict{String, Int}(t => i for (i, t) in enumerate(tags_vocab_))
    Is, Js = Int[], Int[]
    for i in eachindex(chunk_metadata)
        for tag in chunk_metadata[i]
            push!(Is, i)
            push!(Js, tags_vocab_index[tag])
        end
    end
    tags_ = sparse(Is,
        Js,
        trues(length(Is)),
        length(chunk_metadata),
        length(tags_vocab_),
        &)
    return tags_, tags_vocab_
end

end