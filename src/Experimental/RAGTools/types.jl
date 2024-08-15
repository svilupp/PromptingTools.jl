# More advanced index would be: HybridChunkIndex
using Base: parent

### Shared methods
Base.parent(index::AbstractDocumentIndex) = index
Base.parent(index::AbstractManagedIndex) = index
indexid(index::AbstractDocumentIndex) = index.id
chunkdata(index::AbstractChunkIndex) = index.chunkdata
"Access chunkdata for a subset of chunks, `chunk_idx` is a vector of chunk indices in the index"
Base.@propagate_inbounds function chunkdata(
        index::AbstractChunkIndex, chunk_idx::AbstractVector{<:Integer})
    ## We need this accessor because different chunk indices can have chunks in different dimensions!!
    chkdata = chunkdata(index)
    if isnothing(chkdata)
        return nothing
    end
    return view(chkdata, :, chunk_idx)
end

function chunkdata(index::AbstractDocumentIndex)
    throw(ArgumentError("`chunkdata` not implemented for $(typeof(index))"))
end
function chunkdata(index::AbstractDocumentIndex, chunk_idx::AbstractVector{<:Integer})
    throw(ArgumentError("`chunkdata` not implemented for $(typeof(index)) and chunk indices: $(typeof(chunk_idx))"))
end
function embeddings(index::AbstractDocumentIndex)
    throw(ArgumentError("`embeddings` not implemented for $(typeof(index))"))
end
function tags(index::AbstractDocumentIndex)
    throw(ArgumentError("`tags` not implemented for $(typeof(index))"))
end
function tags_vocab(index::AbstractDocumentIndex)
    throw(ArgumentError("`tags_vocab` not implemented for $(typeof(index))"))
end
function extras(index::AbstractDocumentIndex)
    throw(ArgumentError("`extras` not implemented for $(typeof(index))"))
end
HasEmbeddings(::AbstractChunkIndex) = false
HasKeywords(::AbstractChunkIndex) = false
chunks(index::AbstractChunkIndex) = index.chunks
Base.length(index::AbstractChunkIndex) = length(chunks(index))
tags(index::AbstractChunkIndex) = index.tags
tags_vocab(index::AbstractChunkIndex) = index.tags_vocab
sources(index::AbstractChunkIndex) = index.sources
extras(index::AbstractChunkIndex) = index.extras

"""
    translate_positions_to_parent(index::AbstractChunkIndex, positions::AbstractVector{<:Integer})

Translate positions to the parent index. Useful to convert between positions in a view and the original index.

Used whenever a `chunkdata()` is used to re-align positions in case index is a view.
"""
function translate_positions_to_parent(
        index::AbstractChunkIndex, positions::AbstractVector{<:Integer})
    return positions
end

Base.var"=="(i1::AbstractChunkIndex, i2::AbstractChunkIndex) = false
function Base.var"=="(i1::T, i2::T) where {T <: AbstractChunkIndex}
    ((sources(i1) == sources(i2)) && (tags_vocab(i1) == tags_vocab(i2)) &&
     (chunkdata(i1) == chunkdata(i2)) && (chunks(i1) == chunks(i2)) &&
     (tags(i1) == tags(i2)) && (extras(i1) == extras(i2)))
end

function Base.vcat(i1::AbstractDocumentIndex, i2::AbstractDocumentIndex)
    throw(ArgumentError("Not implemented"))
end
function Base.vcat(i1::AbstractChunkIndex, i2::AbstractChunkIndex)
    throw(ArgumentError("Not implemented"))
end
function Base.vcat(i1::T, i2::T) where {T <: AbstractChunkIndex}
    tags_, tags_vocab_ = if (isnothing(tags(i1)) || isnothing(tags(i2)))
        nothing, nothing
    elseif tags_vocab(i1) == tags_vocab(i2)
        vcat(tags(i1), tags(i2)), tags_vocab(i1)
    else
        vcat_labeled_matrices(tags(i1), tags_vocab(i1), tags(i2), tags_vocab(i2))
    end
    chunkdata_ = (isnothing(chunkdata(i1)) || isnothing(chunkdata(i2))) ? nothing :
                 hcat(chunkdata(i1), chunkdata(i2))
    extras_ = if isnothing(extras(i1)) || isnothing(extras(i2))
        nothing
    else
        vcat(extras(i1), extras(i2))
    end
    T(indexid(i1), vcat(chunks(i1), chunks(i2)),
        chunkdata_,
        tags_,
        tags_vocab_,
        vcat(sources(i1), sources(i2)),
        extras_)
end

# Stores document chunks and their embeddings
"""
    ChunkEmbeddingsIndex

Main struct for storing document chunks and their embeddings. It also stores tags and sources for each chunk.

Previously, this struct was called `ChunkIndex`.

# Fields
- `id::Symbol`: unique identifier of each index (to ensure we're using the right index with `CandidateChunks`)
- `chunks::Vector{<:AbstractString}`: underlying document chunks / snippets
- `embeddings::Union{Nothing, Matrix{<:Real}}`: for semantic search
- `tags::Union{Nothing, AbstractMatrix{<:Bool}}`: for exact search, filtering, etc. This is often a sparse matrix indicating which chunks have the given `tag` (see `tag_vocab` for the position lookup)
- `tags_vocab::Union{Nothing, Vector{<:AbstractString}}`: vocabulary for the `tags` matrix (each column in `tags` is one item in `tags_vocab` and rows are the chunks)
- `sources::Vector{<:AbstractString}`: sources of the chunks
- `extras::Union{Nothing, AbstractVector}`: additional data, eg, metadata, source code, etc.
"""
@kwdef struct ChunkEmbeddingsIndex{
    T1 <: AbstractString,
    T2 <: Union{Nothing, Matrix{<:Real}},
    T3 <: Union{Nothing, AbstractMatrix{<:Bool}},
    T4 <: Union{Nothing, AbstractVector}
} <: AbstractChunkIndex
    id::Symbol = gensym("ChunkEmbeddingsIndex")
    # underlying document chunks / snippets
    chunks::Vector{T1}
    # for semantic search
    embeddings::T2 = nothing
    # for exact search, filtering, etc.
    # expected to be some sparse structure, eg, sparse matrix or nothing
    # column oriented, ie, each column is one item in `tags_vocab` and rows are the chunks
    tags::T3 = nothing
    tags_vocab::Union{Nothing, Vector{<:AbstractString}} = nothing
    sources::Vector{<:AbstractString}
    extras::T4 = nothing
end
embeddings(index::ChunkEmbeddingsIndex) = index.embeddings
HasEmbeddings(::ChunkEmbeddingsIndex) = true
chunkdata(index::ChunkEmbeddingsIndex) = embeddings(index)
# It's column aligned so we don't have to re-define `chunkdata(index, chunk_idx)`

# For backward compatibility
const ChunkIndex = ChunkEmbeddingsIndex

abstract type AbstractManagedIndex end
indexid(index::AbstractManagedIndex) = index.id

using Pinecone: Pinecone, PineconeContextv3, PineconeIndexv3
@kwdef struct PineconeIndex <: AbstractManagedIndex
    id::Symbol  # namespace
    context::Pinecone.PineconeContextv3
    index::Pinecone.PineconeIndexv3
    namespace::String
end
HasKeywords(::PineconeIndex) = false
HasEmbeddings(::PineconeIndex) = true

abstract type AbstractDocumentTermMatrix end

"""
    DocumentTermMatrix{T<:AbstractString}

A sparse matrix of term frequencies and document lengths to allow calculation of BM25 similarity scores.
"""
struct DocumentTermMatrix{
    T1 <: AbstractMatrix{<:Real}, T2 <: AbstractString} <:
       AbstractDocumentTermMatrix
    ## assumed to be SparseMatrixCSC{Float32, Int64}
    tf::T1
    vocab::Vector{T2}
    vocab_lookup::Dict{T2, Int}
    idf::Vector{Float32} # length of vocab
    # |d|/avgDl
    doc_rel_length::Vector{Float32}
end
function Base.parent(dtm::AbstractDocumentTermMatrix)
    dtm
end
function tf(dtm::AbstractDocumentTermMatrix)
    dtm.tf
end
function vocab(dtm::AbstractDocumentTermMatrix)
    dtm.vocab
end
function vocab_lookup(dtm::AbstractDocumentTermMatrix)
    dtm.vocab_lookup
end
function idf(dtm::AbstractDocumentTermMatrix)
    dtm.idf
end
function doc_rel_length(dtm::AbstractDocumentTermMatrix)
    dtm.doc_rel_length
end

Base.var"=="(dtm1::AbstractDocumentTermMatrix, dtm2::AbstractDocumentTermMatrix) = false
# Must be the same type and same content
function Base.var"=="(dtm1::T, dtm2::T) where {T <: AbstractDocumentTermMatrix}
    tf(dtm1) == tf(dtm2) && vocab(dtm1) == vocab(dtm2) &&
        vocab_lookup(dtm1) == vocab_lookup(dtm2) && idf(dtm1) == idf(dtm2) &&
        doc_rel_length(dtm1) == doc_rel_length(dtm2)
end

function Base.hcat(d1::AbstractDocumentTermMatrix, d2::AbstractDocumentTermMatrix)
    throw(ArgumentError("A hcat not implemented for DTMs of type $(typeof(d1)) and $(typeof(d2))"))
end
function Base.hcat(d1::DocumentTermMatrix, d2::DocumentTermMatrix)
    tf_, vocab_ = vcat_labeled_matrices(tf(d1), vocab(d1), tf(d2), vocab(d2))
    vocab_lookup_ = Dict(t => i for (i, t) in enumerate(vocab_))

    N, _ = size(tf_)
    doc_freq = [count(x -> x > 0, col) for col in eachcol(tf_)]
    idf = @. log(1.0f0 + (N - doc_freq + 0.5f0) / (doc_freq + 0.5f0))
    doc_lengths = [count(x -> x > 0, row) for row in eachrow(tf_)]
    sumdl = sum(doc_lengths)
    doc_rel_length_ = sumdl == 0 ? zeros(Float32, N) : (doc_lengths ./ (sumdl / N))

    return DocumentTermMatrix(
        tf_, vocab_, vocab_lookup_, idf, convert(Vector{Float32}, doc_rel_length_))
end

"A partial view of a DocumentTermMatrix, `tf` is MATERIALIZED for performance and fewer allocations."
struct SubDocumentTermMatrix{T <: DocumentTermMatrix,
    T1 <: AbstractMatrix{<:Real}} <: AbstractDocumentTermMatrix
    parent::T
    tf::T1 ## Materialize the sub-matrix, because it's too expensive to use otherwise (row-view of SparseMatrixCSC)
    positions::Vector{Int}
end
Base.parent(dtm::SubDocumentTermMatrix) = dtm.parent
positions(dtm::SubDocumentTermMatrix) = dtm.positions
tf(dtm::SubDocumentTermMatrix) = dtm.tf
vocab(dtm::SubDocumentTermMatrix) = Base.parent(dtm) |> vocab
vocab_lookup(dtm::SubDocumentTermMatrix) = Base.parent(dtm) |> vocab_lookup
idf(dtm::SubDocumentTermMatrix) = Base.parent(dtm) |> idf
Base.@propagate_inbounds function doc_rel_length(dtm::SubDocumentTermMatrix)
    view(doc_rel_length(Base.parent(dtm)), positions(dtm))
end
# hcat for SubDocumentTermMatrix does not make sense -> the vocabulary is the same / shared

function Base.view(
        dtm::AbstractDocumentTermMatrix, doc_idx::AbstractVector{<:Integer}, token_idx)
    throw(ArgumentError("A view not implemented for type $(typeof(dtm)) across docs: $(typeof(doc_idx)) and tokens: $(typeof(token_idx))"))
end
Base.@propagate_inbounds function Base.view(
        dtm::AbstractDocumentTermMatrix, doc_idx::AbstractVector{<:Integer}, token_idx::Colon)
    tf_mat = tf(parent(dtm))
    @boundscheck if !checkbounds(Bool, axes(tf_mat, 1), doc_idx)
        ## Avoid printing huge position arrays, show the extremas of the attempted range
        max_pos = extrema(doc_idx)
        throw(BoundsError(tf_mat, max_pos))
    end
    ## computations on top of views of sparse arrays are expensive, materialize the view
    ## Moreover, nonzeros and rowvals accessors for SparseCSCMatrix are not defined for views
    tf_ = tf_mat[doc_idx, :]
    SubDocumentTermMatrix(dtm, tf_, collect(doc_idx))
end
function Base.view(
        dtm::SubDocumentTermMatrix, doc_idx::AbstractVector{<:Integer}, token_idx::Colon)
    tf_mat = tf(parent(dtm))
    @boundscheck if !checkbounds(Bool, axes(tf_mat, 1), doc_idx)
        ## Avoid printing huge position arrays, show the extremas of the attempted range
        max_pos = extrema(doc_idx)
        throw(BoundsError(tf_mat, max_pos))
    end
    intersect_pos = intersect(positions(dtm), doc_idx)
    return SubDocumentTermMatrix(
        parent(dtm), tf_mat[intersect_pos, :], intersect_pos)
end

"""
    ChunkKeywordsIndex

Struct for storing chunks of text and associated keywords for BM25 similarity search.

# Fields
- `id::Symbol`: unique identifier of each index (to ensure we're using the right index with `CandidateChunks`)
- `chunks::Vector{<:AbstractString}`: underlying document chunks / snippets
- `chunkdata::Union{Nothing, AbstractMatrix{<:Real}}`: for similarity search, assumed to be `DocumentTermMatrix`
- `tags::Union{Nothing, AbstractMatrix{<:Bool}}`: for exact search, filtering, etc. This is often a sparse matrix indicating which chunks have the given `tag` (see `tag_vocab` for the position lookup)
- `tags_vocab::Union{Nothing, Vector{<:AbstractString}}`: vocabulary for the `tags` matrix (each column in `tags` is one item in `tags_vocab` and rows are the chunks)
- `sources::Vector{<:AbstractString}`: sources of the chunks
- `extras::Union{Nothing, AbstractVector}`: additional data, eg, metadata, source code, etc.

# Example

We can easily create a keywords-based index from a standard embeddings-based index.

```julia

# Let's assume we have a standard embeddings-based index
index = build_index(SimpleIndexer(), texts; chunker_kwargs = (; max_length=10))

# Creating an additional index for keyword-based search (BM25), is as simple as
index_keywords = ChunkKeywordsIndex(index)

# We can immediately create a MultiIndex (a hybrid index holding both indices)
multi_index = MultiIndex([index, index_keywords])

```

You can also build the index via build_index
```julia
# given some sentences and sources
index_keywords = build_index(KeywordsIndexer(), sentences; chunker_kwargs=(; sources))

# Retrive closest chunks with
retriever = SimpleBM25Retriever()
result = retrieve(retriever, index_keywords, "What are the best practices for parallel computing in Julia?")
result.context
```

If you want to use airag, don't forget to specify the config to make sure keywords are processed (ie, tokenized)
 and that BM25 is used for searching candidates
```julia
cfg = RAGConfig(; retriever = SimpleBM25Retriever());
airag(cfg, index_keywords;
    question = "What are the best practices for parallel computing in Julia?")
```
"""
@kwdef struct ChunkKeywordsIndex{
    T1 <: AbstractString,
    T2 <: Union{Nothing, DocumentTermMatrix},
    T3 <: Union{Nothing, AbstractMatrix{<:Bool}},
    T4 <: Union{Nothing, AbstractVector}
} <: AbstractChunkIndex
    id::Symbol = gensym("ChunkKeywordsIndex")
    # underlying document chunks / snippets
    chunks::Vector{T1}
    # for similarity search
    chunkdata::T2 = nothing
    # for exact search, filtering, etc.
    # expected to be some sparse structure, eg, sparse matrix or nothing
    # column oriented, ie, each column is one item in `tags_vocab` and rows are the chunks
    tags::T3 = nothing
    tags_vocab::Union{Nothing, Vector{<:AbstractString}} = nothing
    sources::Vector{<:AbstractString}
    extras::T4 = nothing
end

HasKeywords(::ChunkKeywordsIndex) = true
"Access chunkdata for a subset of chunks, `chunk_idx` is a vector of chunk indices in the index"
Base.@propagate_inbounds function chunkdata(
        index::ChunkKeywordsIndex, chunk_idx::AbstractVector{<:Integer})
    chkdata = index.chunkdata
    if isnothing(chkdata)
        return nothing
    end
    ## Keyword index is row-oriented, ie, chunks are rows, tokens are columns 
    return view(chkdata, chunk_idx, :)
end

"""
    MultiIndex

Composite index that stores multiple ChunkIndex objects and their embeddings.

# Fields
- `id::Symbol`: unique identifier of each index (to ensure we're using the right index with `CandidateChunks`)
- `indexes::Vector{<:AbstractChunkIndex}`: the indexes to be combined

Use accesor `indexes` to access the individual indexes.

# Examples

We can create a `MultiIndex` from a vector of `AbstractChunkIndex` objects.
```julia
index = build_index(SimpleIndexer(), texts; chunker_kwargs = (; sources))
index_keywords = ChunkKeywordsIndex(index) # same chunks as above but adds BM25 instead of embeddings

multi_index = MultiIndex([index, index_keywords])
```

To use `airag` with different types of indices, we need to specify how to find the closest items for each index
```julia
# Cosine similarity for embeddings and BM25 for keywords, same order as indexes in MultiIndex
finder = RT.MultiFinder([RT.CosineSimilarity(), RT.BM25Similarity()])

# Notice that we add `processor` to make sure keywords are processed (ie, tokenized) as well
cfg = RAGConfig(; retriever = SimpleRetriever(; processor = RT.KeywordsProcessor(), finder))

# Ask questions
msg = airag(cfg, multi_index; question = "What are the best practices for parallel computing in Julia?")
pprint(msg) # prettify the answer
```

"""
@kwdef struct MultiIndex <: AbstractMultiIndex
    id::Symbol = gensym("MultiIndex")
    indexes::Vector{<:AbstractChunkIndex} = AbstractChunkIndex[]
end

indexes(index::MultiIndex) = index.indexes
HasEmbeddings(index::AbstractMultiIndex) = any(HasEmbeddings, indexes(index))
HasKeywords(index::AbstractMultiIndex) = any(HasKeywords, indexes(index))

function MultiIndex(indexes::AbstractChunkIndex...)
    MultiIndex(; indexes = collect(indexes))
end
function MultiIndex(indexes::AbstractVector{<:AbstractChunkIndex})
    MultiIndex(; indexes = indexes)
end

# check that each index has a counterpart in the other MultiIndex
function Base.var"=="(i1::MultiIndex, i2::MultiIndex)
    length(indexes(i1)) != length(indexes(i2)) && return false
    for i in i1.indexes
        if !(i in i2.indexes)
            return false
        end
    end
    for i in i2.indexes
        if !(i in i1.indexes)
            return false
        end
    end
    return true
end

# # Views
### SingleIndex view object
"""
    SubChunkIndex

A view of the parent index with respect to the `chunks` (and chunk-aligned fields). All methods and accessors working for `AbstractChunkIndex` also work for `SubChunkIndex`.
It does not yet work for `MultiIndex`.

# Fields
- `parent::AbstractChunkIndex`: the parent index from which the chunks are drawn (always the original index, never a view)
- `positions::Vector{Int}`: the positions of the chunks in the parent index (always refers to original PARENT index, even if we create a view of the view)

# Example
```julia
cc = CandidateChunks(index.id, 1:10)
sub_index = @view(index[cc])
```

You can use `SubChunkIndex` to access chunks or sources (and other fields) from a parent index, eg,
```julia
RT.chunks(sub_index)
RT.sources(sub_index)
RT.chunkdata(sub_index) # slice of embeddings
RT.embeddings(sub_index) # slice of embeddings
RT.tags(sub_index) # slice of tags
RT.tags_vocab(sub_index) # unchanged, identical to parent version
RT.extras(sub_index) # slice of extras
```

Access the parent index that the `positions` correspond to
```julia
parent(sub_index)
RT.positions(sub_index)
```
"""
@kwdef struct SubChunkIndex{T <: AbstractChunkIndex} <: AbstractChunkIndex
    parent::T
    positions::Vector{Int}
end

indexid(index::SubChunkIndex) = parent(index) |> indexid
positions(index::SubChunkIndex) = index.positions
Base.parent(index::SubChunkIndex) = index.parent
HasEmbeddings(index::SubChunkIndex) = HasEmbeddings(parent(index))
HasKeywords(index::SubChunkIndex) = HasKeywords(parent(index))

Base.@propagate_inbounds function chunks(index::SubChunkIndex)
    view(chunks(parent(index)), positions(index))
end
Base.@propagate_inbounds function sources(index::SubChunkIndex)
    view(sources(parent(index)), positions(index))
end
Base.@propagate_inbounds function chunkdata(index::SubChunkIndex)
    chunkdata(parent(index), positions(index))
end
"Access chunkdata for a subset of chunks, `chunk_idx` is a vector of chunk indices in the index"
Base.@propagate_inbounds function chunkdata(
        index::SubChunkIndex, chunk_idx::AbstractVector{<:Integer})
    ## We need this accessor because different chunk indices can have chunks in different dimensions!!
    index_chunk_idx = translate_positions_to_parent(index, chunk_idx)
    pos = intersect(positions(index), index_chunk_idx)
    chkdata = chunkdata(parent(index), pos)
end
function embeddings(index::SubChunkIndex)
    if HasEmbeddings(index)
        view(embeddings(parent(index)), :, positions(index))
    else
        throw(ArgumentError("`embeddings` not implemented for $(typeof(index))"))
    end
end
function tags(index::SubChunkIndex)
    tagsdata = tags(parent(index))
    isnothing(tagsdata) && return nothing
    view(tagsdata, positions(index), :)
end
function tags_vocab(index::SubChunkIndex)
    tags_vocab(parent(index))
end
function extras(index::SubChunkIndex)
    extrasdata = extras(parent(index))
    isnothing(extrasdata) && return nothing
    view(extrasdata, positions(index))
end
function Base.vcat(i1::SubChunkIndex, i2::SubChunkIndex)
    throw(ArgumentError("vcat not implemented for type $(typeof(i1)) and $(typeof(i2))"))
end
function Base.vcat(i1::T, i2::T) where {T <: SubChunkIndex}
    ## Check if can be merged
    if indexid(parent(i1)) != indexid(parent(i2))
        throw(ArgumentError("Parent indices must be the same (provided: $(indexid(parent(i1))) and $(indexid(parent(i2))))"))
    end
    return SubChunkIndex(parent(i1), vcat(positions(i1), positions(i2)))
end
function Base.unique(index::SubChunkIndex)
    return SubChunkIndex(parent(index), unique(positions(index)))
end
function Base.length(index::SubChunkIndex)
    return length(positions(index))
end
function Base.isempty(index::SubChunkIndex)
    return isempty(positions(index))
end
function Base.show(io::IO, index::SubChunkIndex)
    print(io,
        "A view of $(typeof(parent(index))|>nameof) (id: $(indexid(parent(index)))) with $(length(index)) chunks")
end

"""
    translate_positions_to_parent(
        index::SubChunkIndex, pos::AbstractVector{<:Integer})

Translate positions to the parent index. Useful to convert between positions in a view and the original index.

Used whenever a `chunkdata()` or `tags()` are used to re-align positions to the "parent" index.
"""
Base.@propagate_inbounds function translate_positions_to_parent(
        index::SubChunkIndex, pos::AbstractVector{<:Integer})
    sub_positions = positions(index)
    return sub_positions[pos]
end

# # CandidateChunks for Retrieval

"""
    CandidateChunks

A struct for storing references to chunks in the given index (identified by `index_id`) called `positions` and `scores` holding the strength of similarity (=1 is the highest, most similar).
It's the result of the retrieval stage of RAG.

# Fields
- `index_id::Symbol`: the id of the index from which the candidates are drawn
- `positions::Vector{Int}`: the positions of the candidates in the index (ie, `5` refers to the 5th chunk in the index - `chunks(index)[5]`)
- `scores::Vector{Float32}`: the similarity scores of the candidates from the query (higher is better)
"""
@kwdef struct CandidateChunks{TP <: Integer, TD <: Real} <:
              AbstractCandidateChunks
    index_id::Symbol
    ## if TP is Int, then positions are indices into the index
    positions::Vector{TP} = Int[]
    scores::Vector{TD} = Float32[]
end
indexid(cc::CandidateChunks) = cc.index_id
positions(cc::CandidateChunks) = cc.positions
scores(cc::CandidateChunks) = cc.scores
Base.length(cc::CandidateChunks) = length(cc.positions)
function Base.first(cc::CandidateChunks, k::Integer)
    sorted_idxs = sortperm(scores(cc), rev = true) |> x -> first(x, k)
    CandidateChunks(indexid(cc), positions(cc)[sorted_idxs], scores(cc)[sorted_idxs])
end
function Base.copy(cc::CandidateChunks{TP, TD}) where {TP <: Integer, TD <: Real}
    CandidateChunks{TP, TD}(indexid(cc), copy(positions(cc)), copy(scores(cc)))
end
function Base.isempty(cc::CandidateChunks)
    isempty(positions(cc))
end
function Base.var"=="(cc1::CandidateChunks, cc2::CandidateChunks)
    all(
        getfield(cc1, f) == getfield(cc2, f) for f in fieldnames(CandidateChunks))
end

function CandidateChunks(index::AbstractChunkIndex, positions::AbstractVector{<:Integer},
        scores::AbstractVector{<:Real} = fill(0.0f0, length(positions)))
    CandidateChunks(
        indexid(index), convert(Vector{Int}, positions), convert(Vector{Float32}, scores))
end

@kwdef struct CandidateWithChunks{TP <: Integer, TD <: Real} <:
              AbstractCandidateWithChunks
    index_id::Symbol
    positions::Vector{TP} = Int[]
    scores::Vector{TD} = Float32[]
    ## fields that we don't have in Index anymore -- so we get them "per question"
    chunks::Vector{String} = String[]
    metadata::AbstractVector = Dict{String, Any}[]
    sources::Vector{String} = String[]
end
indexid(cc::CandidateWithChunks) = cc.index_id
positions(cc::CandidateWithChunks) = cc.positions
scores(cc::CandidateWithChunks) = cc.scores
chunks(cc::CandidateWithChunks) = cc.chunks
metadata(cc::CandidateWithChunks) = cc.metadata
sources(cc::CandidateWithChunks) = cc.sources
Base.length(cc::CandidateWithChunks) = length(cc.positions)
function Base.first(cc::CandidateWithChunks, k::Integer)
    sorted_idxs = sortperm(scores(cc), rev = true) |> x -> first(x, k)
    CandidateWithChunks(indexid(cc), positions(cc)[sorted_idxs], scores(cc)[sorted_idxs], chunks(cc), metadata(cc), sources(cc))
end

"""
    MultiCandidateChunks

A struct for storing references to multiple sets of chunks across different indices. Each set of chunks is identified by an `index_id` in `index_ids`, with corresponding `positions` in the index and `scores` indicating the strength of similarity.

This struct is useful for scenarios where candidates are drawn from multiple indices, and there is a need to keep track of which candidates came from which index.

# Fields
- `index_ids::Vector{Symbol}`: the ids of the indices from which the candidates are drawn
- `positions::Vector{TP}`: the positions of the candidates in their respective indices
- `scores::Vector{TD}`: the similarity scores of the candidates from the query
"""
@kwdef struct MultiCandidateChunks{TP, TD} <:
              AbstractCandidateChunks
    # Records the indices that the candidate chunks are from
    index_ids::Vector{Symbol}
    # Records the positions of the candidate chunks in the index
    positions::Vector{TP} = Int[]
    scores::Vector{TD} = Float32[]
end
indexids(cc::MultiCandidateChunks) = cc.index_ids
## for compatibility
indexids(cc::CandidateChunks) = fill(indexid(cc), length(positions(cc)))
positions(cc::MultiCandidateChunks) = cc.positions
scores(cc::MultiCandidateChunks) = cc.scores
Base.length(cc::MultiCandidateChunks) = length(positions(cc))

function Base.first(cc::MultiCandidateChunks, k::Integer)
    sorted_idxs = sortperm(scores(cc), rev = true) |> x -> first(x, k)
    MultiCandidateChunks(
        indexids(cc)[sorted_idxs], positions(cc)[sorted_idxs], scores(cc)[sorted_idxs])
end
function Base.copy(cc::MultiCandidateChunks{TP, TD}) where {TP <: Integer, TD <: Real}
    MultiCandidateChunks{TP, TD}(copy(indexids(cc)), copy(positions(cc)), copy(scores(cc)))
end
function Base.isempty(cc::MultiCandidateChunks)
    isempty(positions(cc))
end
function Base.var"=="(cc1::MultiCandidateChunks, cc2::MultiCandidateChunks)
    all(
        getfield(cc1, f) == getfield(cc2, f) for f in fieldnames(MultiCandidateChunks))
end

function MultiCandidateChunks(
        index::AbstractChunkIndex, positions::AbstractVector{<:Integer},
        scores::AbstractVector{<:Real} = fill(0.0f0, length(positions)))
    index_ids = fill(indexid(index), length(positions))
    MultiCandidateChunks(
        index_ids, convert(Vector{Int}, positions), convert(Vector{Float32}, scores))
end

# join and sort two candidate chunks
function Base.vcat(cc1::AbstractCandidateChunks, cc2::AbstractCandidateChunks)
    throw(ArgumentError("Not implemented for type $(typeof(cc1)) and $(typeof(cc2))"))
end

function Base.vcat(cc1::CandidateChunks{TP1, TD1},
        cc2::CandidateChunks{TP2, TD2}) where {
        TP1 <: Integer, TP2 <: Integer, TD1 <: Real, TD2 <: Real}
    ## Check validity
    indexid(cc1) != indexid(cc2) &&
        throw(ArgumentError("Index ids must match (provided: $(indexid(cc1)) and $(indexid(cc2)))"))

    positions_ = vcat(positions(cc1), positions(cc2))
    # operates on maximum similarity principle, ie, take the max similarity
    scores_ = if !isempty(scores(cc1)) && !isempty(scores(cc2))
        vcat(scores(cc1), scores(cc2))
    else
        TD1[]
    end
    if !isempty(scores_)
        ## Get sorted by maximum similarity (scores are similarity)
        sorted_idxs = sortperm(scores_, rev = true)
        positions_sorted = view(positions_, sorted_idxs)
        ## get the positions of unique elements
        unique_idxs = unique(i -> positions_sorted[i], eachindex(positions_sorted))
        positions_ = positions_sorted[unique_idxs]
        ## apply the sorting and then the filtering
        scores_ = view(scores_, sorted_idxs)[unique_idxs]
    else
        positions_ = unique(positions_)
    end
    CandidateChunks(indexid(cc1), positions_, scores_)
end

function Base.vcat(cc1::MultiCandidateChunks{TP1, TD1},
        cc2::MultiCandidateChunks{TP2, TD2}) where {
        TP1 <: Integer, TP2 <: Integer, TD1 <: Real, TD2 <: Real}
    # operates on maximum similarity principle, ie, take the max similarity
    scores_ = if !isempty(scores(cc1)) && !isempty(scores(cc2))
        vcat(scores(cc1), scores(cc2))
    else
        TD1[]
    end
    positions_ = vcat(positions(cc1), positions(cc2))
    # pool the index ids
    index_ids = vcat(indexids(cc1), indexids(cc2))

    if !isempty(scores_)
        ## Get sorted by maximum similarity (scores are similarity)
        sorted_idxs = sortperm(scores_, rev = true)
        view_positions = view(positions_, sorted_idxs)
        view_indices = view(index_ids, sorted_idxs)
        ## get the positions of unique elements
        unique_idxs = unique(
            i -> (view_indices[i], view_positions[i]), eachindex(
                view_positions, view_indices))
        positions_ = view_positions[unique_idxs]
        index_ids = view_indices[unique_idxs]
        ## apply the sorting and then the filtering
        scores_ = view(scores_, sorted_idxs)[unique_idxs]
    else
        unique_idxs = unique(
            i -> (positions_[i], index_ids[i]), eachindex(positions_, index_ids))
        positions_ = positions_[unique_idxs]
        index_ids = index_ids[unique_idxs]
    end
    MultiCandidateChunks(index_ids, positions_, scores_)
end

# combine/intersect two candidate chunks. take the maximum of the score if available
function Base.var"&"(cc1::AbstractCandidateChunks,
        cc2::AbstractCandidateChunks)
    throw(ArgumentError("Not implemented for type $(typeof(cc1)) and $(typeof(cc2))"))
end
function Base.var"&"(cc1::CandidateChunks{TP1, TD1},
        cc2::CandidateChunks{TP2, TD2}) where
        {TP1 <: Integer, TP2 <: Integer, TD1 <: Real, TD2 <: Real}
    ##
    indexid(cc1) != indexid(cc2) && return CandidateChunks(; index_id = indexid(cc1))

    positions_ = intersect(positions(cc1), positions(cc2))

    scores_ = if !isempty(scores(cc1)) && !isempty(scores(cc2))
        # identify maximum scores from each CC
        scores_dict = Dict(pos => -Inf for pos in positions_)
        # scan the first CC
        for i in eachindex(positions(cc1), scores(cc1))
            pos = positions(cc1)[i]
            if haskey(scores_dict, pos)
                scores_dict[pos] = max(scores_dict[pos], scores(cc1)[i])
            end
        end
        # scan the second CC
        for i in eachindex(positions(cc2), scores(cc2))
            pos = positions(cc2)[i]
            if haskey(scores_dict, pos)
                scores_dict[pos] = max(scores_dict[pos], scores(cc2)[i])
            end
        end
        [scores_dict[pos] for pos in positions_]
    else
        TD1[]
    end
    ## Sort by maximum similarity
    if !isempty(scores_)
        sorted_idxs = sortperm(scores_, rev = true)
        positions_ = positions_[sorted_idxs]
        scores_ = scores_[sorted_idxs]
    end

    CandidateChunks(indexid(cc1), positions_, scores_)
end

function Base.var"&"(mc1::MultiCandidateChunks{TP1, TD1},
        mc2::MultiCandidateChunks{TP2, TD2}) where
        {TP1 <: Integer, TP2 <: Integer, TD1 <: Real, TD2 <: Real}
    ## if empty, skip the work
    if isempty(scores(mc1)) || isempty(scores(mc2))
        return MultiCandidateChunks(;
            index_ids = Symbol[], positions = TP1[], scores = TD1[])
    end

    keep_indexes = intersect(indexids(mc1), indexids(mc2))

    ## Build the scores dict from first candidates
    ## Structure: id=>position=>max_score
    scores_dict = Dict(id => Dict(pos => score
                       for (pos, score, id_) in zip(
                               positions(mc1), scores(mc1), indexids(mc1))
                       if id_ == id)
    for id in keep_indexes)

    ## Iterate the second candidate set and directly save to output arrays
    index_ids = Symbol[]
    positions_ = TP1[]
    scores_ = TD1[]
    for i in eachindex(positions(mc2), indexids(mc2), scores(mc2))
        pos, score, id = positions(mc2)[i], scores(mc2)[i], indexids(mc2)[i]
        if haskey(scores_dict, id)
            index_dict = scores_dict[id]
            if haskey(index_dict, pos)
                ## This item was found in both -> set to true as intersection
                push!(index_ids, id)
                push!(positions_, pos)
                push!(scores_, max(index_dict[pos], score))
            end
        end
    end

    ## Sort by maximum similarity
    if !isempty(scores_)
        sorted_idxs = sortperm(scores_, rev = true)
        positions_ = positions_[sorted_idxs]
        index_ids = index_ids[sorted_idxs]
        scores_ = scores_[sorted_idxs]
    else
        ## take as is
        index_ids = Symbol[]
        positions_ = TP1[]
    end

    return MultiCandidateChunks(index_ids, positions_, scores_)
end

# # Index Views and Getindex
function Base.view(index::AbstractDocumentIndex, cc::AbstractCandidateChunks)
    throw(ArgumentError("Not implemented for type $(typeof(index)) and $(typeof(cc))"))
end
Base.@propagate_inbounds function Base.view(index::AbstractChunkIndex, cc::CandidateChunks)
    @boundscheck let chk_vector = chunks(parent(index))
        if !checkbounds(Bool, axes(chk_vector, 1), positions(cc))
            ## Avoid printing huge position arrays, show the extremas of the attempted range
            max_pos = extrema(positions(cc))
            throw(BoundsError(chk_vector, max_pos))
        end
    end
    pos = indexid(index) == indexid(cc) ? positions(cc) : Int[]
    return SubChunkIndex(parent(index), pos)
end
Base.@propagate_inbounds function Base.view(index::SubChunkIndex, cc::CandidateChunks)
    SubChunkIndex(index, cc)
end
Base.@propagate_inbounds function Base.view(
        index::AbstractChunkIndex, cc::MultiCandidateChunks)
    valid_items = findall(==(indexid(index)), indexids(cc))
    valid_positions = positions(cc)[valid_items]
    @boundscheck let chk_vector = chunks(parent(index))
        if !checkbounds(Bool, axes(chk_vector, 1), valid_positions)
            ## Avoid printing huge position arrays, show the extremas of the attempted range
            max_pos = extrema(valid_positions)
            throw(BoundsError(chk_vector, max_pos))
        end
    end
    return SubChunkIndex(parent(index), valid_positions)
end
Base.@propagate_inbounds function Base.view(index::SubChunkIndex, cc::MultiCandidateChunks)
    SubChunkIndex(index, cc)
end
# TODO: proper `view` -- `SubManagedIndex`?
Base.@propagate_inbounds function Base.view(index::AbstractManagedIndex, cc::CandidateWithChunks)
    return cc
end
Base.@propagate_inbounds function SubChunkIndex(index::SubChunkIndex, cc::CandidateChunks)
    pos = indexid(index) == indexid(cc) ? positions(cc) : Int[]
    intersect_pos = intersect(pos, positions(index))
    @boundscheck let chk_vector = chunks(parent(index))
        if !checkbounds(Bool, axes(chk_vector, 1), intersect_pos)
            ## Avoid printing huge position arrays, show the extremas of the attempted range
            max_pos = extrema(intersect_pos)
            throw(BoundsError(chk_vector, max_pos))
        end
    end
    return SubChunkIndex(parent(index), intersect_pos)
end
Base.@propagate_inbounds function SubChunkIndex(
        index::SubChunkIndex, cc::MultiCandidateChunks)
    valid_items = findall(==(indexid(index)), indexids(cc))
    valid_positions = positions(cc)[valid_items]
    intersect_pos = intersect(valid_positions, positions(index))
    @boundscheck let chk_vector = chunks(parent(index))
        if !checkbounds(Bool, axes(chk_vector, 1), intersect_pos)
            ## Avoid printing huge position arrays, show the extremas of the attempted range
            max_pos = extrema(intersect_pos)
            throw(BoundsError(chk_vector, max_pos))
        end
    end
    return SubChunkIndex(parent(index), intersect_pos)
end

## Getindex

function Base.getindex(ci::AbstractDocumentIndex,
        candidate::AbstractCandidateChunks,
        field::Symbol)
    throw(ArgumentError("Not implemented"))
end
function Base.getindex(ci::AbstractChunkIndex,
        candidate::CandidateChunks{TP, TD},
        field::Symbol = :chunks; sorted::Bool = false) where {TP <: Integer, TD <: Real}
    @assert field in [:chunks, :embeddings, :chunkdata, :sources, :scores] "Only `chunks`, `embeddings`, `chunkdata`, `sources`, `scores` fields are supported for now"
    ## embeddings is a compatibility alias, use chunkdata
    field = field == :embeddings ? :chunkdata : field

    if indexid(ci) == indexid(candidate)
        # Sort if requested
        sorted_idx = sorted ? sortperm(scores(candidate), rev = true) :
                     eachindex(scores(candidate))
        sub_index = view(ci, candidate)
        if field == :chunks
            chunks(sub_index)[sorted_idx]
        elseif field == :chunkdata
            ## If embeddings, chunks are columns
            ## If keywords (DTM), chunks are rows
            chkdata = chunkdata(sub_index, sorted_idx)
        elseif field == :sources
            sources(sub_index)[sorted_idx]
        elseif field == :scores
            scores(candidate)[sorted_idx]
        end
    else
        if field == :chunks
            eltype(chunks(ci))[]
        elseif field == :chunkdata
            chkdata = chunkdata(ci)
            isnothing(chkdata) && return nothing
            TypeItem = typeof(chkdata)
            init_dim = ntuple(i -> 0, ndims(chkdata))
            TypeItem(undef, init_dim)
        elseif field == :sources
            eltype(sources(ci))[]
        elseif field == :scores
            TD[]
        end
    end
end
function Base.getindex(pidx::AbstractManagedIndex,
        candidate::CandidateWithChunks{TP, TD},
        field::Symbol = :chunks; sorted::Bool = false) where {TP <: Integer, TD <: Real}
    @assert field in [:chunks, :embeddings, :chunkdata, :sources, :scores] "Only `chunks`, `embeddings`, `chunkdata`, `sources`, `scores` fields are supported for now"
    ## embeddings is a compatibility alias, use chunkdata
    field = field == :embeddings ? :chunkdata : field

    if indexid(pidx) == indexid(candidate)
        # Sort if requested
        sorted_idx = sorted ? sortperm(scores(candidate), rev = true) :
                     eachindex(scores(candidate))
        sub_index = view(pidx, candidate)
        if field == :chunks
            chunks(sub_index)[sorted_idx]
        elseif field == :chunkdata
            ## If embeddings, chunks are columns
            ## If keywords (DTM), chunks are rows
            chkdata = chunkdata(sub_index, sorted_idx)
        elseif field == :sources
            sources(sub_index)[sorted_idx]
        elseif field == :scores
            scores(candidate)[sorted_idx]
        end
    else
        if field == :chunks
            eltype(chunks(pidx))[]
        elseif field == :chunkdata
            chkdata = chunkdata(pidx)
            isnothing(chkdata) && return nothing
            TypeItem = typeof(chkdata)
            init_dim = ntuple(i -> 0, ndims(chkdata))
            TypeItem(undef, init_dim)
        elseif field == :sources
            eltype(sources(pidx))[]
        elseif field == :scores
            TD[]
        end
    end
end
function Base.getindex(mi::MultiIndex,
        candidate::CandidateChunks{TP, TD},
        field::Symbol = :chunks; sorted::Bool = false) where {TP <: Integer, TD <: Real}
    ## Always sorted!
    @assert field in [:chunks, :sources, :scores] "Only `chunks`, `sources`, `scores` fields are supported for now"
    valid_index = findfirst(x -> indexid(x) == indexid(candidate), indexes(mi))
    if isnothing(valid_index) && field == :chunks
        String[]
    elseif isnothing(valid_index) && field == :sources
        String[]
    elseif isnothing(valid_index) && field == :scores
        TD[]
    else
        getindex(indexes(mi)[valid_index], candidate, field)
    end
end
# Dispatch for multi-candidate chunks
function Base.getindex(ci::AbstractChunkIndex,
        candidate::MultiCandidateChunks{TP, TD},
        field::Symbol = :chunks; sorted::Bool = false) where {TP <: Integer, TD <: Real}
    @assert field in [:chunks, :embeddings, :chunkdata, :sources, :scores] "Only `chunks`, `embeddings`, `chunkdata`, `sources`, `scores` fields are supported for now"

    index_pos = findall(==(indexid(ci)), indexids(candidate))
    ## Convert to CandidateChunks and re-use method above
    cc = CandidateChunks(
        indexid(ci), positions(candidate)[index_pos], scores(candidate)[index_pos])
    getindex(ci, cc, field; sorted)
end
# Getindex on Multiindex, pool the individual hits
# Sorted defaults to true because we need to guarantee that potential `context` is sorted by score across different indices
function Base.getindex(mi::MultiIndex,
        candidate::MultiCandidateChunks{TP, TD},
        field::Symbol = :chunks; sorted::Bool = true) where {TP <: Integer, TD <: Real}
    @assert field in [:chunks, :sources, :scores] "Only `chunks`, `sources`, and `scores` fields are supported for now"
    if sorted
        # values can be either of chunks or sources
        # ineffective but easier to implement
        # TODO: remove the duplication later
        values = mapreduce(idxs -> Base.getindex(idxs, candidate, field, sorted = false),
            vcat, indexes(mi))
        scores_ = mapreduce(
            idxs -> Base.getindex(idxs, candidate, :scores, sorted = false),
            vcat, indexes(mi))
        sorted_idx = sortperm(scores_, rev = true)
        values[sorted_idx]
    else
        mapreduce(idxs -> Base.getindex(idxs, candidate, field, sorted = false),
            vcat, indexes(mi))
    end
end

function Base.getindex(index::AbstractChunkIndex, id::Symbol)
    id == indexid(index) ? index : nothing
end
function Base.getindex(index::AbstractManagedIndex, id::Symbol)
    id == indexid(index) ? index : nothing
end
function Base.getindex(index::AbstractMultiIndex, id::Symbol)
    id == indexid(index) && return index
    idx = findfirst(x -> indexid(x) == id, indexes(index))
    isnothing(idx) ? nothing : indexes(index)[idx]
end

"""
    RAGResult

A struct for debugging RAG answers. It contains the question, answer, context, and the candidate chunks at each step of the RAG pipeline.

Think of the flow as `question` -> `rephrased_questions` -> `answer` -> `final_answer` with the context and candidate chunks helping along the way.

# Fields
- `question::AbstractString`: the original question
- `rephrased_questions::Vector{<:AbstractString}`: a vector of rephrased questions (eg, HyDe, Multihop, etc.)
- `answer::AbstractString`: the generated answer
- `final_answer::AbstractString`: the refined final answer (eg, after CorrectiveRAG), also considered the FINAL answer (it must be always available)
- `context::Vector{<:AbstractString}`: the context used for retrieval (ie, the vector of chunks and their surrounding window if applicable)
- `sources::Vector{<:AbstractString}`: the sources of the context (for the original matched chunks)
- `emb_candidates::CandidateChunks`: the candidate chunks from the embedding index (from `find_closest`)
- `tag_candidates::Union{Nothing, CandidateChunks}`: the candidate chunks from the tag index (from `find_tags`)
- `filtered_candidates::CandidateChunks`: the filtered candidate chunks (intersection of `emb_candidates` and `tag_candidates`)
- `reranked_candidates::CandidateChunks`: the reranked candidate chunks (from `rerank`)
- `conversations::Dict{Symbol,Vector{<:AbstractMessage}}`: the conversation history for AI steps of the RAG pipeline, use keys that correspond to the function names, eg, `:answer` or `:refine`

See also: `pprint` (pretty printing), `annotate_support` (for annotating the answer)
"""
@kwdef mutable struct RAGResult <: AbstractRAGResult
    question::AbstractString
    rephrased_questions::AbstractVector{<:AbstractString} = [question]
    answer::Union{Nothing, AbstractString} = nothing
    final_answer::Union{Nothing, AbstractString} = nothing
    context::Vector{<:AbstractString} = String[]
    sources::Vector{<:AbstractString} = String[]
    emb_candidates::Union{CandidateChunks, CandidateWithChunks, MultiCandidateChunks} = CandidateChunks(
        index_id = :NOTINDEX, positions = Int[], scores = Float32[])
    tag_candidates::Union{Nothing, CandidateChunks, CandidateWithChunks, MultiCandidateChunks} = CandidateChunks(
        index_id = :NOTINDEX, positions = Int[], scores = Float32[])
    filtered_candidates::Union{CandidateChunks, CandidateWithChunks, MultiCandidateChunks} = CandidateChunks(
        index_id = :NOTINDEX, positions = Int[], scores = Float32[])
    reranked_candidates::Union{CandidateChunks, CandidateWithChunks, MultiCandidateChunks} = CandidateChunks(
        index_id = :NOTINDEX, positions = Int[], scores = Float32[])
    conversations::Dict{Symbol, Vector{<:AbstractMessage}} = Dict{
        Symbol, Vector{<:AbstractMessage}}()
end

function Base.var"=="(r1::T, r2::T) where {T <: AbstractRAGResult}
    all(f -> getfield(r1, f) == getfield(r2, f),
        fieldnames(T))
end
function Base.copy(r::T) where {T <: AbstractRAGResult}
    T([deepcopy(getfield(r, f))

       for f in fieldnames(T)]...)
end

# Structured show method for easier reading (each kwarg on a new line)
function Base.show(io::IO,
        t::Union{AbstractDocumentIndex, AbstractCandidateChunks, AbstractRAGResult})
    dump(IOContext(io, :limit => true), t, maxdepth = 1)
end

# last_output, last_message for consistency with AICall / Message vectors
"""
    PT.last_message(result::RAGResult)

Extract the last message from the RAGResult. It looks for `final_answer` first, then `answer` fields in the `conversations` dictionary. Returns `nothing` if not found.
"""
function PT.last_message(result::RAGResult)
    (; conversations) = result
    if haskey(conversations, :final_answer) &&
       !isempty(conversations[:final_answer])
        conversations[:final_answer][end]
    elseif haskey(conversations, :answer) &&
           !isempty(conversations[:answer])
        conversations[:answer][end]
    else
        nothing
    end
end
"Extracts the last output (generated text answer) from the RAGResult."
function PT.last_output(result::RAGResult)
    msg = PT.last_message(result)
    isnothing(msg) ? result.final_answer : msg.content
end

# Pretty print
# TODO: add more customizations, eg, context itself
"""
    PT.pprint(
        io::IO, r::AbstractRAGResult; add_context::Bool = false,
        text_width::Int = displaysize(io)[2], annotater_kwargs...)

Pretty print the RAG result `r` to the given `io` stream. 

If `add_context` is `true`, the context will be printed as well. The `text_width` parameter can be used to control the width of the output.

You can provide additional keyword arguments to the annotater, eg, `add_sources`, `add_scores`, `min_score`, etc. See `annotate_support` for more details.
"""
function PT.pprint(
        io::IO, r::AbstractRAGResult; add_context::Bool = false,
        text_width::Int = displaysize(io)[2], annotater_kwargs...)
    if !isempty(r.rephrased_questions)
        content = PT.wrap_string("- " * join(r.rephrased_questions, "\n- "), text_width)
        print(io, "-"^20, "\n")
        printstyled(io, "QUESTION(s)", color = :blue, bold = true)
        print(io, "\n", "-"^20, "\n")
        print(io, content, "\n\n")
    end
    if !isnothing(r.final_answer) && !isempty(r.final_answer)
        annotater = TrigramAnnotater()
        root = annotate_support(annotater, r; annotater_kwargs...)
        print(io, "-"^20, "\n")
        printstyled(io, "ANSWER", color = :blue, bold = true)
        print(io, "\n", "-"^20, "\n")
        pprint(io, root; text_width)
    end
    if add_context && !isempty(r.context)
        print(io, "\n" * "-"^20, "\n")
        printstyled(io, "CONTEXT", color = :blue, bold = true)
        print(io, "\n", "-"^20, "\n")
        for (i, ctx) in enumerate(r.context)
            print(io, PT.wrap_string(ctx, text_width))
            print(io, "\n", "-"^20, "\n")
        end
    end
end

### Serialization for JSON3
StructTypes.StructType(::Type{RAGResult}) = StructTypes.Struct()
StructTypes.StructType(::Type{CandidateChunks}) = StructTypes.Struct()
StructTypes.StructType(::Type{MultiCandidateChunks}) = StructTypes.Struct()

## Constructor for serialization - opinionated for abstract types!
function StructTypes.constructfrom(::Type{T},
        obj::Union{Dict, JSON3.Object}) where {T <:
                                               Union{CandidateChunks, MultiCandidateChunks}}
    obj = copy(obj)
    haskey(obj, :index_id) && (obj[:index_id] = Symbol(obj[:index_id]))
    haskey(obj, :index_ids) && (obj[:index_ids] = convert(Vector{Symbol}, obj[:index_ids]))
    haskey(obj, :positions) && (obj[:positions] = convert(Vector{Int}, obj[:positions]))
    haskey(obj, :scores) && (obj[:scores] = convert(Vector{Float32}, obj[:scores]))
    T(; obj...)
end
## function StructTypes.constructfrom(::Type{CandidateChunks}, obj::JSON3.Object)
##     obj = copy(obj)
##     haskey(obj, :positions) && (obj[:positions] = convert(Vector{Int}, obj[:positions]))
##     haskey(obj, :scores) && (obj[:scores] = convert(Vector{Float32}, obj[:scores]))
##     CandidateChunks(; obj...)
## end
function JSON3.read(path::AbstractString,
        ::Type{T}) where {T <: Union{CandidateChunks, MultiCandidateChunks}}
    StructTypes.constructfrom(T, JSON3.read(path))
end

# Use as: StructTypes.constructfrom(RAGResult, JSON3.read(tmp)) 
function StructTypes.constructfrom(::Type{RAGResult}, obj::Union{Dict, JSON3.Object})
    obj = copy(obj)
    if haskey(obj, :conversations)
        obj[:conversations] = Dict(k => StructTypes.constructfrom(
                                       Vector{PT.AbstractMessage}, v)
        for (k, v) in pairs(obj[:conversations]))
    end
    ## Retype where necessary
    for f in [
        :emb_candidates, :tag_candidates, :filtered_candidates, :reranked_candidates]
        ## Check for nothing value, because tag_candidates can be empty
        if haskey(obj, f) && !isnothing(obj[f]) && haskey(obj[f], :index_ids)
            obj[f] = StructTypes.constructfrom(MultiCandidateChunks, obj[f])
        elseif haskey(obj, f) && !isnothing(obj[f])
            obj[f] = StructTypes.constructfrom(CandidateChunks, obj[f])
        end
    end
    obj[:context] = convert(Vector{String}, get(obj, :context, String[]))
    obj[:sources] = convert(Vector{String}, get(obj, :sources, String[]))
    RAGResult(; obj...)
end
function JSON3.read(path::AbstractString, ::Type{RAGResult})
    StructTypes.constructfrom(RAGResult, JSON3.read(path))
end
