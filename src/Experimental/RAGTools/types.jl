
# More advanced index would be: HybridChunkIndex

### Shared methods
chunkdata(index::AbstractChunkIndex) = index.chunkdata
function embeddings(index::AbstractChunkIndex)
    throw(ArgumentError("`embeddings` not implemented for $(typeof(index))"))
end
HasEmbeddings(::AbstractChunkIndex) = false
HasKeywords(::AbstractChunkIndex) = false
chunks(index::AbstractChunkIndex) = index.chunks
tags(index::AbstractChunkIndex) = index.tags
tags_vocab(index::AbstractChunkIndex) = index.tags_vocab
sources(index::AbstractChunkIndex) = index.sources
extras(index::AbstractChunkIndex) = index.extras

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
    T(i1.id, vcat(chunks(i1), chunks(i2)),
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

# For backward compatibility
const ChunkIndex = ChunkEmbeddingsIndex

"""
    DocumentTermMatrix{T<:AbstractString}

A sparse matrix of term frequencies and document lengths to allow calculation of BM25 similarity scores.
"""
struct DocumentTermMatrix{T1 <: AbstractMatrix{<:Real}, T2 <: AbstractString}
    ## assumed to be SparseMatrixCSC{Float32, Int64}
    tf::T1
    vocab::Vector{T2}
    vocab_lookup::Dict{T2, Int}
    idf::Vector{Float32}
    # |d|/avgDl
    doc_rel_length::Vector{Float32}
end

function Base.hcat(d1::DocumentTermMatrix, d2::DocumentTermMatrix)
    tf, vocab = vcat_labeled_matrices(d1.tf, d1.vocab, d2.tf, d2.vocab)
    vocab_lookup = Dict(t => i for (i, t) in enumerate(vocab))

    N, _ = size(tf)
    doc_freq = [count(x -> x > 0, col) for col in eachcol(tf)]
    idf = @. log(1.0f0 + (N - doc_freq + 0.5f0) / (doc_freq + 0.5f0))
    doc_lengths = [count(x -> x > 0, row) for row in eachrow(tf)]
    sumdl = sum(doc_lengths)
    doc_rel_length = sumdl == 0 ? zeros(Float32, N) : (doc_lengths ./ (sumdl / N))

    return DocumentTermMatrix(
        tf, vocab, vocab_lookup, idf, convert(Vector{Float32}, doc_rel_length))
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

You can also build the index via
```julia
# given some sentences and sources
index_keywords = build_index(KeywordsIndexer(), sentences; chunker_kwargs=(; sources))

# Retrive closest chunks with
retriever = SimpleBM25Retriever()
result = retrieve(retriever, index_keywords, "What are the best practices for parallel computing in Julia?")
result.context
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

## TODO: implement a view(), make sure to recover the output positions correctly
## TODO: fields: parent, positions

"Composite index that stores multiple ChunkIndex objects and their embeddings. It's not yet fully implemented."
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
Base.length(cc::CandidateChunks) = length(cc.positions)
function Base.first(cc::CandidateChunks, k::Integer)
    sorted_idxs = sortperm(cc.scores, rev = true) |> x -> first(x, k)
    CandidateChunks(cc.index_id, cc.positions[sorted_idxs], cc.scores[sorted_idxs])
end
function Base.copy(cc::CandidateChunks{TP, TD}) where {TP <: Integer, TD <: Real}
    CandidateChunks{TP, TD}(cc.index_id, copy(cc.positions), copy(cc.scores))
end
function Base.isempty(cc::CandidateChunks)
    isempty(cc.positions)
end
function Base.var"=="(cc1::CandidateChunks, cc2::CandidateChunks)
    all(
        getfield(cc1, f) == getfield(cc2, f) for f in fieldnames(CandidateChunks))
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
Base.length(cc::MultiCandidateChunks) = length(cc.positions)
function Base.first(cc::MultiCandidateChunks, k::Integer)
    sorted_idxs = sortperm(cc.scores, rev = true) |> x -> first(x, k)
    MultiCandidateChunks(
        cc.index_ids[sorted_idxs], cc.positions[sorted_idxs], cc.scores[sorted_idxs])
end
function Base.copy(cc::MultiCandidateChunks{TP, TD}) where {TP <: Integer, TD <: Real}
    MultiCandidateChunks{TP, TD}(copy(cc.index_ids), copy(cc.positions), copy(cc.scores))
end
function Base.isempty(cc::MultiCandidateChunks)
    isempty(cc.positions)
end
function Base.var"=="(cc1::MultiCandidateChunks, cc2::MultiCandidateChunks)
    all(
        getfield(cc1, f) == getfield(cc2, f) for f in fieldnames(MultiCandidateChunks))
end

# join and sort two candidate chunks
function Base.vcat(cc1::AbstractCandidateChunks, cc2::AbstractCandidateChunks)
    throw(ArgumentError("Not implemented for type $(typeof(cc1)) and $(typeof(cc2))"))
end

## function _vcat(cc1::T, cc2::T) where {T <: AbstractCandidateChunks}
## end

function Base.vcat(cc1::CandidateChunks{TP1, TD1},
        cc2::CandidateChunks{TP2, TD2}) where {
        TP1 <: Integer, TP2 <: Integer, TD1 <: Real, TD2 <: Real}
    ## Check validity
    cc1.index_id != cc2.index_id &&
        throw(ArgumentError("Index ids must match (provided: $(cc1.index_id) and $(cc2.index_id))"))

    positions = vcat(cc1.positions, cc2.positions)
    # operates on maximum similarity principle, ie, take the max similarity
    scores = if !isempty(cc1.scores) && !isempty(cc2.scores)
        vcat(cc1.scores, cc2.scores)
    else
        TD1[]
    end
    if !isempty(scores)
        ## Get sorted by maximum similarity (scores are similarity)
        sorted_idxs = sortperm(scores, rev = true)
        positions_sorted = @view(positions[sorted_idxs])
        ## get the positions of unique elements
        unique_idxs = unique(i -> positions_sorted[i], eachindex(positions_sorted))
        positions = positions_sorted[unique_idxs]
        ## apply the sorting and then the filtering
        scores = @view(scores[sorted_idxs])[unique_idxs]
    else
        positions = unique(positions)
    end
    CandidateChunks(cc1.index_id, positions, scores)
end

function Base.vcat(cc1::MultiCandidateChunks{TP1, TD1},
        cc2::MultiCandidateChunks{TP2, TD2}) where {
        TP1 <: Integer, TP2 <: Integer, TD1 <: Real, TD2 <: Real}
    # operates on maximum similarity principle, ie, take the max similarity
    scores = if !isempty(cc1.scores) && !isempty(cc2.scores)
        vcat(cc1.scores, cc2.scores)
    else
        TD1[]
    end
    positions = vcat(cc1.positions, cc2.positions)
    # pool the index ids
    index_ids = vcat(cc1.index_ids, cc2.index_ids)

    if !isempty(scores)
        ## Get sorted by maximum similarity (scores are similarity)
        sorted_idxs = sortperm(scores, rev = true)
        view_positions = @view(positions[sorted_idxs])
        view_indices = @view(index_ids[sorted_idxs])
        ## get the positions of unique elements
        unique_idxs = unique(
            i -> (view_indices[i], view_positions[i]), eachindex(
                view_positions, view_indices))
        positions = view_positions[unique_idxs]
        index_ids = view_indices[unique_idxs]
        ## apply the sorting and then the filtering
        scores = @view(scores[sorted_idxs])[unique_idxs]
    else
        unique_idxs = unique(
            i -> (positions[i], index_ids[i]), eachindex(positions, index_ids))
        positions = positions[unique_idxs]
        index_ids = index_ids[unique_idxs]
    end
    MultiCandidateChunks(index_ids, positions, scores)
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
    cc1.index_id != cc2.index_id && return CandidateChunks(; index_id = cc1.index_id)

    positions = intersect(cc1.positions, cc2.positions)

    scores = if !isempty(cc1.scores) && !isempty(cc2.scores)
        valid_scores = fill(TD1(-1), length(positions))
        # identify maximum scores from each CC
        # scan the first CC
        for i in eachindex(cc1.positions, cc1.scores)
            pos = cc1.positions[i]
            idx = findfirst(==(pos), positions)
            if !isnothing(idx)
                valid_scores[idx] = max(valid_scores[idx], cc1.scores[i])
            end
        end
        # scan the second CC
        for i in eachindex(cc2.positions, cc2.scores)
            pos = cc2.positions[i]
            idx = findfirst(==(pos), positions)
            if !isnothing(idx)
                valid_scores[idx] = max(valid_scores[idx], cc2.scores[i])
            end
        end
        valid_scores
    else
        TD1[]
    end
    ## Sort by maximum similarity
    if !isempty(scores)
        sorted_idxs = sortperm(scores, rev = true)
        positions = positions[sorted_idxs]
        scores = scores[sorted_idxs]
    end

    CandidateChunks(cc1.index_id, positions, scores)
end

function Base.var"&"(mc1::MultiCandidateChunks{TP1, TD1},
        mc2::MultiCandidateChunks{TP2, TD2}) where
        {TP1 <: Integer, TP2 <: Integer, TD1 <: Real, TD2 <: Real}
    ##
    # TODO: fix
    ## index_ids = intersect(mc1.index_ids, mc2.index_ids)
    ## for index_id in index_ids
    ##     positions1 = findall(==(index_id), mc1.index_ids)
    ##     positions2 = findall(==(index_id), mc2.index_ids)
    ##     positions = intersect(positions1, positions2)

    ##     scores = zeros(TD1, length(positions))
    ##     for i in eachindex(positions)
    ##         pos = positions[i]
    ##         scores[i] = max(mc1.scores[positions1[i]], mc2.scores[positions2[i]])
    ##     end
    ## end

    ## scores = if !isempty(mc1.scores) && !isempty(mc2.scores)
    ##     valid_scores = fill(TD1(-1), length(positions))
    ##     # scan the first MultiCandidateChunks
    ##     for i in eachindex(mc1.positions, mc1.scores)
    ##         pos = mc1.positions[i]
    ##         idx = findfirst(==(pos), positions)
    ##         if !isnothing(idx)
    ##             valid_scores[idx] = max(valid_scores[idx], mc1.scores[i])
    ##         end
    ##     end
    ##     # scan the second MultiCandidateChunks
    ##     for i in eachindex(mc2.positions, mc2.scores)
    ##         pos = mc2.positions[i]
    ##         idx = findfirst(==(pos), positions)
    ##         if !isnothing(idx)
    ##             valid_scores[idx] = max(valid_scores[idx], mc2.scores[i])
    ##         end
    ##     end
    ##     valid_scores
    ## else
    ##     TD1[]
    ## end
    ## ## Sort by maximum similarity
    ## if !isempty(scores)
    ##     sorted_idxs = sortperm(scores, rev = true)
    ##     positions = positions[sorted_idxs]
    ##     scores = scores[sorted_idxs]
    ## end

    ## MultiCandidateChunks(index_ids, positions, scores)
end

function Base.getindex(ci::AbstractDocumentIndex,
        candidate::AbstractCandidateChunks,
        field::Symbol)
    throw(ArgumentError("Not implemented"))
end
function Base.getindex(ci::AbstractChunkIndex,
        candidate::CandidateChunks{TP, TD},
        field::Symbol = :chunks) where {TP <: Integer, TD <: Real}
    @assert field in [:chunks, :embeddings, :chunkdata, :sources] "Only `chunks`, `embeddings`, `chunkdata`, `sources` fields are supported for now"
    field = field == :embeddings ? :chunkdata : field
    len_ = length(chunks(ci))
    @assert all(1 .<= candidate.positions .<= len_) "Some positions are out of bounds"
    if ci.id == candidate.index_id
        if field == :chunks
            @views chunks(ci)[candidate.positions]
        elseif field == :chunkdata
            @views chunkdata(ci)[:, candidate.positions]
        elseif field == :sources
            @views sources(ci)[candidate.positions]
        end
    else
        if field == :chunks
            eltype(chunks(ci))[]
        elseif field == :chunkdata
            eltype(chunkdata(ci))[]
        elseif field == :sources
            eltype(sources(ci))[]
        end
    end
end
function Base.getindex(mi::MultiIndex,
        candidate::CandidateChunks{TP, TD},
        field::Symbol = :chunks) where {TP <: Integer, TD <: Real}
    @assert field in [:chunks, :sources] "Only `chunks`, `sources` fields are supported for now"
    valid_index = findfirst(x -> x.id == candidate.index_id, indexes(mi))
    if isnothing(valid_index) && field == :chunks
        String[]
    elseif isnothing(valid_index) && field == :sources
        String[]
    else
        getindex(indexes(mi)[valid_index], candidate, field)
    end
end
# Dispatch for multi-candidate chunks
function Base.getindex(ci::AbstractChunkIndex,
        candidate::MultiCandidateChunks{TP, TD},
        field::Symbol = :chunks; sorted::Bool = false) where {TP <: Integer, TD <: Real}
    @assert field in [:chunks, :sources, :scores] "Only `chunks`, `sources`, and `scores` fields are supported for now"

    index_pos = findall(==(ci.id), candidate.index_ids)
    if isempty(index_pos) && field == :chunks
        eltype(chunks(ci))[]
    elseif isempty(index_pos) && field == :scores
        eltype(candidate.scores)[]
    elseif isempty(index_pos) && field == :sources
        eltype(sources(ci))[]
    else
        # Sort if requested
        idx = if sorted
            scores = @view(candidate.scores[index_pos])
            sorted_idx = sortperm(scores, rev = true)
            index_pos[sorted_idx]
        else
            index_pos
        end
        if field == :chunks
            getindex(chunks(ci), candidate.positions[idx])
        elseif field == :sources
            getindex(sources(ci), candidate.positions[idx])
        elseif field == :scores
            candidate.scores[idx]
        end
    end
end
# Getindex on Multiindex, pool the individual hits
function Base.getindex(mi::MultiIndex,
        candidate::MultiCandidateChunks{TP, TD},
        field::Symbol = :chunks; sorted::Bool = false) where {TP <: Integer, TD <: Real}
    @assert field in [:chunks, :sources, :scores] "Only `chunks`, `sources`, and `scores` fields are supported for now"
    if sorted
        # values can be either of chunks or sources
        values = mapreduce(idxs -> Base.getindex(idxs, candidate, field, sorted = false),
            vcat, indexes(mi))
        scores = mapreduce(idxs -> Base.getindex(idxs, candidate, :scores, sorted = false),
            vcat, indexes(mi))
        sorted_idx = sortperm(scores, rev = true)
        values[sorted_idx]
    else
        mapreduce(idxs -> Base.getindex(idxs, candidate, field, sorted = false),
            vcat, indexes(mi))
    end
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
    emb_candidates::CandidateChunks = CandidateChunks(
        index_id = :NOTINDEX, positions = Int[], scores = Float32[])
    tag_candidates::Union{Nothing, CandidateChunks} = CandidateChunks(
        index_id = :NOTINDEX, positions = Int[], scores = Float32[])
    filtered_candidates::CandidateChunks = CandidateChunks(
        index_id = :NOTINDEX, positions = Int[], scores = Float32[])
    reranked_candidates::CandidateChunks = CandidateChunks(
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
    if !isempty(r.final_answer)
        annotater = TrigramAnnotater()
        root = annotate_support(annotater, r; annotater_kwargs...)
        print(io, "-"^20, "\n")
        printstyled(io, "ANSWER", color = :blue, bold = true)
        print(io, "\n", "-"^20, "\n")
        pprint(io, root; text_width)
    end
    if add_context
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
        if haskey(obj, f)
            @info obj[f]
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
