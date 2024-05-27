module RAGToolsExperimentalExt

using PromptingTools, SparseArrays, Unicode
using LinearAlgebra
const PT = PromptingTools

using PromptingTools.Experimental.RAGTools
const RT = PromptingTools.Experimental.RAGTools

# forward to LinearAlgebra.normalize
RT._normalize(arr::AbstractArray) = LinearAlgebra.normalize(arr)

# Forward to Unicode.normalize
function RT._unicode_normalize(text::AbstractString; kwargs...)
    Unicode.normalize(text; kwargs...)
end

"""
    RT.build_tags(
        tagger::RT.AbstractTagger, chunk_metadata::AbstractVector{
            <:AbstractVector{String},
        })

Builds a sparse matrix of tags and a vocabulary from the given vector of chunk metadata.
"""
function RT.build_tags(
        tagger::RT.AbstractTagger, chunk_metadata::AbstractVector{
            <:AbstractVector{String},
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

"""
    document_term_matrix(documents::AbstractVector{<:AbstractVector{<:AbstractString}})

Builds a sparse matrix of term frequencies and document lengths from the given vector of documents wrapped in type `DocumentTermMatrix`.

Expects a vector of preprocessed (tokenized) documents, where each document is a vector of strings (clean tokens).

Returns: `DocumentTermMatrix`

# Example
```
documents = [["this", "is", "a", "test"], ["this", "is", "another", "test"], ["foo", "bar", "baz"]]
dtm = document_term_matrix(documents)
```
"""
function RT.document_term_matrix(documents::AbstractVector{<:AbstractVector{<:AbstractString}})
    T = eltype(documents) |> eltype
    vocab = convert(Vector{T}, unique(vcat(documents...)))
    vocab_lookup = Dict{T, Int}(t => i for (i, t) in enumerate(vocab))
    N = length(documents)
    doc_freq = zeros(Int, length(vocab))
    term_freq = spzeros(Float32, N, length(vocab))
    doc_lengths = zeros(Float32, N)
    for di in eachindex(documents)
        unique_terms = Set{eltype(vocab)}()
        doc = documents[di]
        for t in doc
            doc_lengths[di] += 1
            tid = vocab_lookup[t]
            term_freq[di, tid] += 1
            if !(t in unique_terms)
                doc_freq[tid] += 1
                push!(unique_terms, t)
            end
        end
    end
    idf = @. log(1.0f0 + (N - doc_freq + 0.5f0) / (doc_freq + 0.5f0))
    sumdl = sum(doc_lengths)
    doc_rel_length = sumdl == 0 ? zeros(Float32, N) : doc_lengths ./ (sumdl / N)
    RT.DocumentTermMatrix(term_freq, vocab, vocab_lookup, idf, doc_rel_length)
end
"""
    RT.bm25(dtm::DocumentTermMatrix, query::Vector{String}; k1::Float32=1.2f0, b::Float32=0.75f0)

Scores all documents in `dtm` based on the `query`.

References: https://opensourceconnections.com/blog/2015/10/16/bm25-the-next-generation-of-lucene-relevation/

# Example
```
documents = [["this", "is", "a", "test"], ["this", "is", "another", "test"], ["foo", "bar", "baz"]]
dtm = document_term_matrix(documents)
query = ["this"]
scores = bm25(dtm, query)
# Returns array with 3 scores (one for each document)
```
"""
function RT.bm25(dtm::RT.DocumentTermMatrix, query::Vector{String};
        k1::Float32 = 1.2f0, b::Float32 = 0.75f0)
    scores = zeros(Float32, size(dtm.tf, 1))
    ## Identify non-zero items to leverage the sparsity
    nz_rows = rowvals(dtm.tf)
    nz_vals = nonzeros(dtm.tf)
    for i in eachindex(query)
        t = query[i]
        t_id = get(dtm.vocab_lookup, t, nothing)
        t_id === nothing && continue
        idf = dtm.idf[t_id]
        # Scan only documents that have this token
        @inbounds @simd for j in nzrange(dtm.tf, t_id)
            ## index into the sparse matrix
            di, tf = nz_rows[j], nz_vals[j]
            doc_len = dtm.doc_rel_length[di]
            tf_top = (tf * (k1 + 1.0f0))
            tf_bottom = (tf + k1 * (1.0f0 - b + b * doc_len))
            score = idf * tf_top / tf_bottom
            ## @info "di: $di, tf: $tf, doc_len: $doc_len, idf: $idf, tf_top: $tf_top, tf_bottom: $tf_bottom, score: $score"
            scores[di] += score
        end
    end
    scores
end

end # end of module
