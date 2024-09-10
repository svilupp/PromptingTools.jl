module RAGToolsExperimentalExt

using PromptingTools, SparseArrays, Unicode
using LinearAlgebra
const PT = PromptingTools

using PromptingTools.Experimental.RAGTools
using PromptingTools.Experimental.RAGTools: tf, vocab, vocab_lookup, idf, doc_rel_length
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
            <:AbstractVector{<:AbstractString},
        })

Builds a sparse matrix of tags and a vocabulary from the given vector of chunk metadata.
"""
function RT.build_tags(
        tagger::RT.AbstractTagger, chunk_metadata::AbstractVector{
            <:AbstractVector{<:AbstractString},
        })
    tags_vocab_ = vcat(chunk_metadata...) |> unique |> sort .|> String
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

function RT.vcat_labeled_matrices(mat1::AbstractSparseMatrix{T1},
        vocab1::AbstractVector{<:AbstractString},
        mat2::AbstractSparseMatrix{T2},
        vocab2::AbstractVector{<:AbstractString}) where {T1 <: Number, T2 <: Number}
    T = promote_type(T1, T2)
    new_words = setdiff(vocab2, vocab1)
    combined_vocab = [vocab1; new_words]
    vocab2_indices = Dict(word => i for (i, word) in enumerate(vocab2))

    ## more efficient composition
    I, J, V = findnz(mat1)
    aligned_mat1 = sparse(
        I, J, convert(Vector{T}, V), size(mat1, 1), length(combined_vocab))

    ## collect the mat2 more efficiently since it's sparse
    I, J, V = Int[], Int[], T[]
    nz_rows = rowvals(mat2)
    nz_vals = nonzeros(mat2)
    for (j, word) in enumerate(combined_vocab)
        if haskey(vocab2_indices, word)
            @inbounds @simd for k in nzrange(mat2, vocab2_indices[word])
                i = nz_rows[k]
                val = nz_vals[k]
                if !iszero(val)
                    push!(I, i)
                    push!(J, j)
                    push!(V, val)
                end
            end
        end
    end
    aligned_mat2 = sparse(I, J, V, size(mat2, 1), length(combined_vocab))

    return vcat(aligned_mat1, aligned_mat2), combined_vocab
end

function Base.hcat(d1::RT.DocumentTermMatrix{<:AbstractSparseMatrix},
        d2::RT.DocumentTermMatrix{<:AbstractSparseMatrix})
    tf_, vocab_ = RT.vcat_labeled_matrices(tf(d1), vocab(d1), tf(d2), vocab(d2))
    vocab_lookup_ = Dict(t => i for (i, t) in enumerate(vocab_))

    ## decompose tf for efficient ops
    N, M = size(tf_)
    I, J, V = findnz(tf_)
    doc_freq = zeros(Int, M)
    @inbounds for j in eachindex(J, V)
        if V[j] > 0
            doc_freq[J[j]] += 1
        end
    end
    idf = @. log(1.0f0 + (N - doc_freq + 0.5f0) / (doc_freq + 0.5f0))
    doc_lengths = zeros(Float32, N)
    @inbounds for i in eachindex(I, V)
        if V[i] > 0
            doc_lengths[I[i]] += V[i]
        end
    end
    sumdl = sum(doc_lengths)
    doc_rel_length_ = sumdl == 0 ? zeros(Float32, N) :
                      convert(Vector{Float32}, (doc_lengths ./ (sumdl / N)))
    return RT.DocumentTermMatrix(tf_, vocab_, vocab_lookup_, idf, doc_rel_length_)
end

"""
    RT.document_term_matrix(
        documents::AbstractVector{<:AbstractVector{T}};
        min_term_freq::Int = 1, max_terms::Int = typemax(Int)) where {T <: AbstractString}

Builds a sparse matrix of term frequencies and document lengths from the given vector of documents wrapped in type `DocumentTermMatrix`.

Expects a vector of preprocessed (tokenized) documents, where each document is a vector of strings (clean tokens).

Returns: `DocumentTermMatrix`

# Arguments
- `documents`: A vector of documents, where each document is a vector of terms (clean tokens).
- `min_term_freq`: The minimum frequency a term must have to be included in the vocabulary, eg, `min_term_freq = 2` means only terms that appear at least twice will be included.
- `max_terms`: The maximum number of terms to include in the vocabulary, eg, `max_terms = 100` means only the 100 most frequent terms will be included.

# Example
```
documents = [["this", "is", "a", "test"], ["this", "is", "another", "test"], ["foo", "bar", "baz"]]
dtm = document_term_matrix(documents)
```
"""
function RT.document_term_matrix(
        documents::AbstractVector{<:AbstractVector{T}};
        min_term_freq::Int = 1, max_terms::Int = typemax(Int)) where {T <: AbstractString}
    ## Calculate term frequencies, sort descending
    counts = Dict{T, Int}()
    @inbounds for doc in documents
        for term in doc
            counts[term] = get(counts, term, 0) + 1
        end
    end
    counts = sort(collect(counts), by = x -> -x[2]) |> Base.Fix2(first, max_terms) |>
             Base.Fix1(filter!, x -> x[2] >= min_term_freq)
    ## Create vocabulary
    vocab = convert(Vector{T}, getindex.(counts, 1))
    vocab_lookup = Dict{T, Int}(term => i for (i, term) in enumerate(vocab))
    N = length(documents)
    doc_freq = zeros(Int, length(vocab))
    doc_lengths = zeros(Float32, N)
    ## Term frequency matrix to be recorded via its sparse entries: I, J, V
    # term_freq = spzeros(Float32, N, length(vocab))
    I, J, V = Int[], Int[], Float32[]

    unique_terms = Set{eltype(vocab)}()
    sizehint!(unique_terms, 1000)
    for di in eachindex(documents)
        empty!(unique_terms)
        doc = documents[di]
        @inbounds for t in doc
            doc_lengths[di] += 1
            tid = get(vocab_lookup, t, nothing)
            tid === nothing && continue
            push!(I, di)
            push!(J, tid)
            push!(V, 1.0f0)
            if !(t in unique_terms)
                doc_freq[tid] += 1
                push!(unique_terms, t)
            end
        end
    end
    ## combine repeated terms with `+`
    term_freq = sparse(I, J, V, N, length(vocab), +)
    idf = @. log(1.0f0 + (N - doc_freq + 0.5f0) / (doc_freq + 0.5f0))
    sumdl = sum(doc_lengths)
    doc_rel_length = sumdl == 0 ? zeros(Float32, N) : doc_lengths ./ (sumdl / N)
    RT.DocumentTermMatrix(term_freq, vocab, vocab_lookup, idf, doc_rel_length)
end

function RT.document_term_matrix(documents::AbstractVector{<:AbstractString})
    RT.document_term_matrix(RT.preprocess_tokens(documents))
end

"""
    RT.bm25(dtm::AbstractDocumentTermMatrix, query::Vector{String}; k1::Float32=1.2f0, b::Float32=0.75f0)

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
function RT.bm25(
        dtm::RT.AbstractDocumentTermMatrix, query::AbstractVector{<:AbstractString};
        k1::Float32 = 1.2f0, b::Float32 = 0.75f0)
    scores = zeros(Float32, size(tf(dtm), 1))
    ## Identify non-zero items to leverage the sparsity
    nz_rows = rowvals(tf(dtm))
    nz_vals = nonzeros(tf(dtm))
    for i in eachindex(query)
        t = query[i]
        t_id = get(vocab_lookup(dtm), t, nothing)
        t_id === nothing && continue
        idf_ = idf(dtm)[t_id]
        # Scan only documents that have this token
        @inbounds @simd for j in nzrange(tf(dtm), t_id)
            ## index into the sparse matrix
            di, tf_ = nz_rows[j], nz_vals[j]
            doc_len = doc_rel_length(dtm)[di]
            tf_top = (tf_ * (k1 + 1.0f0))
            tf_bottom = (tf_ + k1 * (1.0f0 - b + b * doc_len))
            score = idf_ * tf_top / tf_bottom
            ## @info "di: $di, tf: $tf, doc_len: $doc_len, idf: $idf, tf_top: $tf_top, tf_bottom: $tf_bottom, score: $score"
            scores[di] += score
        end
    end

    return scores
end

end # end of module
