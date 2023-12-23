### Types
# Defines three key types for RAG: ChunkIndex, MultiIndex, and CandidateChunks
# In addition, RAGContext is defined for debugging purposes

abstract type AbstractDocumentIndex end
abstract type AbstractChunkIndex <: AbstractDocumentIndex end
# More advanced index would be: HybridChunkIndex

# Stores document chunks and their embeddings
@kwdef struct ChunkIndex{
    T1 <: AbstractString,
    T2 <: Union{Nothing, Matrix{<:Real}},
    T3 <: Union{Nothing, AbstractMatrix{<:Bool}},
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
@kwdef struct MultiIndex <: AbstractDocumentIndex
    id::Symbol = gensym("MultiIndex")
    indexes::Vector{<:ChunkIndex}
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
@kwdef struct CandidateChunks{T <: Real} <: AbstractCandidateChunks
    index_id::Symbol
    positions::Vector{Int} = Int[]
    distances::Vector{T} = Float32[]
end
# combine/intersect two candidate chunks. average the score if available
function Base.var"&"(cc1::CandidateChunks, cc2::CandidateChunks)
    cc1.index_id != cc2.index_id && return CandidateChunks(; index_id = cc1.index_id)

    positions = intersect(cc1.positions, cc2.positions)
    distances = if !isempty(cc1.distances) && !isempty(cc2.distances)
        (cc1.distances[positions] .+ cc2.distances[positions]) ./ 2
    else
        Float32[]
    end
    CandidateChunks(cc1.index_id, positions, distances)
end
function Base.getindex(ci::ChunkIndex, candidate::CandidateChunks, field::Symbol = :chunks)
    @assert field==:chunks "Only `chunks` field is supported for now"
    len_ = length(chunks(ci))
    @assert all(1 .<= candidate.positions .<= len_) "Some positions are out of bounds"
    if ci.id == candidate.index_id
        chunks(ci)[candidate.positions]
    else
        eltype(chunks(ci))[]
    end
end
function Base.getindex(mi::MultiIndex, candidate::CandidateChunks, field::Symbol = :chunks)
    @assert field==:chunks "Only `chunks` field is supported for now"
    valid_index = findfirst(x -> x.id == candidate.index_id, indexes(mi))
    if isnothing(valid_index)
        String[]
    else
        getindex(indexes(mi)[valid_index], candidate)
    end
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
