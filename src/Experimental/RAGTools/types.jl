### Types
# Defines three key types for RAG: ChunkIndex, MultiIndex, and CandidateChunks
# In addition, RAGContext is defined for debugging purposes

abstract type AbstractDocumentIndex end
abstract type AbstractMultiIndex <: AbstractDocumentIndex end
abstract type AbstractChunkIndex <: AbstractDocumentIndex end
# More advanced index would be: HybridChunkIndex

# Stores document chunks and their embeddings
"""
    ChunkIndex

Main struct for storing document chunks and their embeddings. It also stores tags and sources for each chunk.

# Fields
- `id::Symbol`: unique identifier of each index (to ensure we're using the right index with `CandidateChunks`)
- `chunks::Vector{<:AbstractString}`: underlying document chunks / snippets
- `embeddings::Union{Nothing, Matrix{<:Real}}`: for semantic search
- `tags::Union{Nothing, AbstractMatrix{<:Bool}}`: for exact search, filtering, etc. This is often a sparse matrix indicating which chunks have the given `tag` (see `tag_vocab` for the position lookup)
- `tags_vocab::Union{Nothing, Vector{<:AbstractString}}`: vocabulary for the `tags` matrix (each column in `tags` is one item in `tags_vocab` and rows are the chunks)
- `sources::Vector{<:AbstractString}`: sources of the chunks
- `extras::Union{Nothing, AbstractVector}`: additional data, eg, metadata, source code, etc.
"""
@kwdef struct ChunkIndex{
    T1 <: AbstractString,
    T2 <: Union{Nothing, Matrix{<:Real}},
    T3 <: Union{Nothing, AbstractMatrix{<:Bool}},
    T4 <: Union{Nothing, AbstractVector}
} <: AbstractChunkIndex
    id::Symbol = gensym("ChunkIndex")
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
embeddings(index::ChunkIndex) = index.embeddings
chunks(index::ChunkIndex) = index.chunks
tags(index::ChunkIndex) = index.tags
tags_vocab(index::ChunkIndex) = index.tags_vocab
sources(index::ChunkIndex) = index.sources

function Base.var"=="(i1::ChunkIndex, i2::ChunkIndex)
    ((i1.sources == i2.sources) && (i1.tags_vocab == i2.tags_vocab) &&
     (i1.embeddings == i2.embeddings) && (i1.chunks == i2.chunks) && (i1.tags == i2.tags))
end

function Base.vcat(i1::AbstractDocumentIndex, i2::AbstractDocumentIndex)
    throw(ArgumentError("Not implemented"))
end

function Base.vcat(i1::ChunkIndex, i2::ChunkIndex)
    tags_, tags_vocab_ = if (isnothing(tags(i1)) || isnothing(tags(i2)))
        nothing, nothing
    elseif tags_vocab(i1) == tags_vocab(i2)
        vcat(tags(i1), tags(i2)), tags_vocab(i1)
    else
        merge_labeled_matrices(tags(i1), tags_vocab(i1), tags(i2), tags_vocab(i2))
    end
    embeddings_ = (isnothing(embeddings(i1)) || isnothing(embeddings(i2))) ? nothing :
                  hcat(embeddings(i1), embeddings(i2))
    ChunkIndex(;
        chunks = vcat(chunks(i1), chunks(i2)),
        embeddings = embeddings_,
        tags = tags_,
        tags_vocab = tags_vocab_,
        sources = vcat(i1.sources, i2.sources))
end

"Composite index that stores multiple ChunkIndex objects and their embeddings"
@kwdef struct MultiIndex <: AbstractMultiIndex
    id::Symbol = gensym("MultiIndex")
    indexes::Vector{<:AbstractChunkIndex}
end
indexes(index::MultiIndex) = index.indexes
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

abstract type AbstractCandidateChunks end
@kwdef struct CandidateChunks{TP <: Union{Integer, AbstractCandidateChunks}, TD <: Real} <:
              AbstractCandidateChunks
    index_id::Symbol
    ## if TP is Int, then positions are indices into the index
    ## if TP is CandidateChunks, then positions are indices into the positions of the child index in MultiIndex
    positions::Vector{TP} = Int[]
    distances::Vector{TD} = Float32[]
end
Base.length(cc::CandidateChunks) = length(cc.positions)
function Base.first(cc::CandidateChunks, k::Integer)
    CandidateChunks(cc.index_id, first(cc.positions, k), first(cc.distances, k))
end
# combine/intersect two candidate chunks. average the score if available
function Base.var"&"(cc1::AbstractCandidateChunks,
        cc2::AbstractCandidateChunks)
    throw(ArgumentError("Not implemented"))
end
function Base.var"&"(cc1::CandidateChunks{TP1, TD1},
        cc2::CandidateChunks{TP2, TD2}) where
        {TP1 <: Integer, TP2 <: Integer, TD1 <: Real, TD2 <: Real}
    ##
    cc1.index_id != cc2.index_id && return CandidateChunks(; index_id = cc1.index_id)

    positions = intersect(cc1.positions, cc2.positions)
    distances = if !isempty(cc1.distances) && !isempty(cc2.distances)
        (cc1.distances[positions] .+ cc2.distances[positions]) ./ 2
    else
        Float32[]
    end
    CandidateChunks(cc1.index_id, positions, distances)
end

function Base.getindex(ci::AbstractDocumentIndex,
        candidate::AbstractCandidateChunks,
        field::Symbol)
    throw(ArgumentError("Not implemented"))
end
function Base.getindex(ci::ChunkIndex,
        candidate::CandidateChunks{TP, TD},
        field::Symbol = :chunks) where {TP <: Integer, TD <: Real}
    @assert field in [:chunks, :embeddings, :sources] "Only `chunks`, `embeddings`, `sources` fields are supported for now"
    len_ = length(chunks(ci))
    @assert all(1 .<= candidate.positions .<= len_) "Some positions are out of bounds"
    if ci.id == candidate.index_id
        if field == :chunks
            @views chunks(ci)[candidate.positions]
        elseif field == :embeddings
            @views embeddings(ci)[:, candidate.positions]
        elseif field == :sources
            @views sources(ci)[candidate.positions]
        end
    else
        if field == :chunks
            eltype(chunks(ci))[]
        elseif field == :embeddings
            eltype(embeddings(ci))[]
        elseif field == :sources
            eltype(sources(ci))[]
        end
    end
end
function Base.getindex(mi::MultiIndex,
        candidate::CandidateChunks{TP, TD},
        field::Symbol = :chunks) where {TP <: Integer, TD <: Real}
    @assert field==:chunks "Only `chunks` field is supported for now"
    valid_index = findfirst(x -> x.id == candidate.index_id, indexes(mi))
    if isnothing(valid_index)
        String[]
    else
        getindex(indexes(mi)[valid_index], candidate)
    end
end
# Dispatch for multi-candidate chunks
function Base.getindex(ci::ChunkIndex,
        candidate::CandidateChunks{TP, TD},
        field::Symbol = :chunks) where {TP <: AbstractCandidateChunks, TD <: Real}
    @assert field==:chunks "Only `chunks` field is supported for now"

    index_pos = findfirst(x -> x.index_id == ci.id, candidate.positions)
    @info index_pos
    if isnothing(index_pos)
        eltype(chunks(ci))[]
    else
        getindex(chunks(ci), candidate.positions[index_pos].positions)
    end
end
function Base.getindex(mi::MultiIndex,
        candidate::CandidateChunks{TP, TD},
        field::Symbol = :chunks) where {TP <: AbstractCandidateChunks, TD <: Real}
    @assert field==:chunks "Only `chunks` field is supported for now"
    mapreduce(idxs -> Base.getindex(idxs, candidate, field), vcat, indexes(mi))
end

"""
    RAGContext

A struct for debugging RAG answers. It contains the question, answer, context, and the candidate chunks at each step of the RAG pipeline.
"""
@kwdef struct RAGContext
    question::AbstractString
    answer::AbstractString
    context::Vector{<:AbstractString}
    sources::Vector{<:AbstractString}
    emb_candidates::CandidateChunks
    tag_candidates::Union{Nothing, CandidateChunks}
    filtered_candidates::CandidateChunks
    reranked_candidates::CandidateChunks
end

# Structured show method for easier reading (each kwarg on a new line)
function Base.show(io::IO,
        t::Union{AbstractDocumentIndex, AbstractCandidateChunks, RAGContext})
    dump(IOContext(io, :limit => true), t, maxdepth = 1)
end
