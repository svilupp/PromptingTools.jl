## Preparation Stage

### Chunking Types

"""
    FileChunker <: AbstractChunker

Chunker when you provide file paths to `get_chunks` functions.

Ie, the inputs will be validated first (eg, file exists, etc) and then read into memory.

Set as default chunker in `get_chunks` functions.
"""
struct FileChunker <: AbstractChunker end

"""
    TextChunker <: AbstractChunker

Chunker when you provide text to `get_chunks` functions. Inputs are directly chunked
"""
struct TextChunker <: AbstractChunker end

### Embedding Types
"""
    NoEmbedder <: AbstractEmbedder

No-op embedder for `get_embeddings` functions. It returns `nothing`.
"""
struct NoEmbedder <: AbstractEmbedder end

"""
    BatchEmbedder <: AbstractEmbedder

Default embedder for `get_embeddings` functions. It passes individual documents to be embedded in chunks to `aiembed`.
"""
struct BatchEmbedder <: AbstractEmbedder end

"""
    KeywordsProcessor <: AbstractProcessor

Default keywords processor for `get_keywords` functions. It normalizes the documents, tokenizes them and builds a `DocumentTermMatrix`.
"""
struct KeywordsProcessor <: AbstractProcessor end

"""
    NoProcessor <: AbstractProcessor

No-op processor for `get_keywords` functions. It returns the inputs as is.
"""
struct NoProcessor <: AbstractProcessor end

"""
    BinaryBatchEmbedder <: AbstractEmbedder

Same as `BatchEmbedder` but reduces the embeddings matrix to a binary form (eg, `BitMatrix`). Defines a method for `get_embeddings`.

Reference: [HuggingFace: Embedding Quantization](https://huggingface.co/blog/embedding-quantization#binary-quantization-in-vector-databases).
"""
struct BinaryBatchEmbedder <: AbstractEmbedder end

"""
    BitPackedBatchEmbedder <: AbstractEmbedder

Same as `BatchEmbedder` but reduces the embeddings matrix to a binary form packed in UInt64 (eg, `BitMatrix.chunks`). Defines a method for `get_embeddings`.

See also utilities `pack_bits` and `unpack_bits` to move between packed/non-packed binary forms.

Reference: [HuggingFace: Embedding Quantization](https://huggingface.co/blog/embedding-quantization#binary-quantization-in-vector-databases).
"""
struct BitPackedBatchEmbedder <: AbstractEmbedder end

EmbedderEltype(::T) where {T} = EmbedderEltype(T)
EmbedderEltype(::Type{<:AbstractEmbedder}) = Float32
EmbedderEltype(::Type{NoEmbedder}) = Nothing
EmbedderEltype(::Type{BinaryBatchEmbedder}) = Bool
EmbedderEltype(::Type{BitPackedBatchEmbedder}) = UInt64

### Tagging Types
"""
    NoTagger <: AbstractTagger

No-op tagger for `get_tags` functions. It returns (`nothing`, `nothing`).
"""
struct NoTagger <: AbstractTagger end

"""
    PassthroughTagger <: AbstractTagger

Tagger for `get_tags` functions, which passes `tags` directly as Vector of Vectors of strings (ie, `tags[i]` is the tags for `docs[i]`).
"""
struct PassthroughTagger <: AbstractTagger end

"""
    OpenTagger <: AbstractTagger

Tagger for `get_tags` functions, which generates possible tags for each chunk via `aiextract`. 
You can customize it via prompt template (default: `:RAGExtractMetadataShort`), but it's quite open-ended (ie, AI decides the possible tags).
"""
struct OpenTagger <: AbstractTagger end

# Types used to extract `tags` from document chunks
@kwdef struct Tag
    value::String
    category::String
end
@kwdef struct MaybeTags
    items::Union{Nothing, Vector{Tag}}
end

### Overall types for build_index
"""
    SimpleIndexer <: AbstractIndexBuilder

Default implementation for `build_index`.

It uses `TextChunker`, `BatchEmbedder`, and `NoTagger` as default chunker, embedder, and tagger.
"""
@kwdef mutable struct SimpleIndexer <: AbstractIndexBuilder
    chunker::AbstractChunker = TextChunker()
    embedder::AbstractEmbedder = BatchEmbedder()
    tagger::AbstractTagger = NoTagger()
end

"""
    KeywordsIndexer <: AbstractIndexBuilder

Keyword-based index (BM25) to be returned by `build_index`.

It uses `TextChunker`, `KeywordsProcessor`, and `NoTagger` as default chunker, processor, and tagger.
"""
@kwdef mutable struct KeywordsIndexer <: AbstractIndexBuilder
    chunker::AbstractChunker = TextChunker()
    processor::AbstractProcessor = KeywordsProcessor()
    tagger::AbstractTagger = NoTagger()
end

"""
    PineconeIndexer <: AbstractIndexBuilder

Pinecone index to be returned by `build_index`.

It uses `FileChunker`, `BatchEmbedder` and `NoTagger` as default chunker, embedder and tagger.
"""
@kwdef mutable struct PineconeIndexer <: AbstractIndexBuilder
    chunker::AbstractChunker = FileChunker()
    embedder::AbstractEmbedder = BatchEmbedder()
    tagger::AbstractTagger = NoTagger()
end

### Functions

## "Build an index for RAG (Retriever-Augmented Generation) applications. REQUIRES SparseArrays and LinearAlgebra packages to be loaded!!"
## function build_index end

"Shortcut to LinearAlgebra.normalize. Provided in the package extension `RAGToolsExperimentalExt` (Requires SparseArrays, Unicode, and LinearAlgebra)"
function _normalize end

"""
    load_text(chunker::AbstractChunker, input;
        kwargs...)

Load text from `input` using the provided `chunker`. Called by `get_chunks`.

Available chunkers:
- `FileChunker`: The function opens each file in `input` and reads its contents.
- `TextChunker`: The function assumes that `input` is a vector of strings to be chunked, you MUST provide corresponding `sources`.
"""
function load_text(chunker::AbstractChunker, input;
        kwargs...)
    throw(ArgumentError("Not implemented for chunker $(typeof(chunker))"))
end
function load_text(chunker::FileChunker, input::AbstractString;
        source::AbstractString = input, kwargs...)
    @assert isfile(input) "Path $input does not exist"
    return read(input, String), source
end
function load_text(chunker::TextChunker, input::AbstractString;
        source::AbstractString = input, kwargs...)
    @assert length(source)<=512 "Each `source` should be less than 512 characters long. Detected: $(length(source)) characters. You must provide sources for each text when using `TextChunker`"
    return input, source
end

"""
    get_chunks(chunker::AbstractChunker,
        files_or_docs::Vector{<:AbstractString};
        sources::AbstractVector{<:AbstractString} = files_or_docs,
        verbose::Bool = true,
        separators = ["\\n\\n", ". ", "\\n", " "], max_length::Int = 256)

Chunks the provided `files_or_docs` into chunks of maximum length `max_length` (if possible with provided `separators`).

Supports two modes of operation:
- `chunker = FileChunker()`: The function opens each file in `files_or_docs` and reads its contents.
- `chunker = TextChunker()`: The function assumes that `files_or_docs` is a vector of strings to be chunked, you MUST provide corresponding `sources`.

# Arguments
- `files_or_docs`: A vector of valid file paths OR string documents to be chunked.
- `separators`: A list of strings used as separators for splitting the text in each file into chunks. Default is `[\\n\\n", ". ", "\\n", " "]`.
   See `recursive_splitter` for more details.
- `max_length`: The maximum length of each chunk (if possible with provided separators). Default is 256.
- `sources`: A vector of strings indicating the source of each chunk. Default is equal to `files_or_docs` (for `reader=:files`)

"""
function get_chunks(chunker::AbstractChunker,
        files_or_docs::Vector{<:AbstractString};
        sources::AbstractVector{<:AbstractString} = files_or_docs,
        verbose::Bool = true,
        separators = ["\n\n", ". ", "\n", " "], max_length::Int = 256)

    ## Check that all items must be existing files or strings
    @assert (length(sources)==length(files_or_docs)) "Length of `sources` must match length of `files_or_docs`"

    output_chunks = Vector{SubString{String}}()
    output_sources = Vector{eltype(sources)}()

    # Do chunking first
    for i in eachindex(files_or_docs, sources)
        doc_raw, source = load_text(chunker, files_or_docs[i]; source = sources[i])
        isempty(doc_raw) && continue
        # split into chunks by recursively trying the separators provided
        # if you want to start simple - just do `split(text,"\n\n")`
        doc_chunks = PT.recursive_splitter(doc_raw, separators; max_length) .|> strip |>
                     x -> filter(!isempty, x)
        # skip if no chunks found
        isempty(doc_chunks) && continue
        append!(output_chunks, doc_chunks)
        append!(output_sources, fill(source, length(doc_chunks)))
    end

    return output_chunks, output_sources
end

function get_embeddings(
        embedder::AbstractEmbedder, docs::AbstractVector{<:AbstractString}; kwargs...)
    throw(ArgumentError("Not implemented for embedder $(typeof(embedder))"))
end

function get_embeddings(
        embedder::NoEmbedder, docs::AbstractVector{<:AbstractString}; kwargs...)
    return nothing
end

"""
    get_embeddings(embedder::BatchEmbedder, docs::AbstractVector{<:AbstractString};
        verbose::Bool = true,
        model::AbstractString = PT.MODEL_EMBEDDING,
        truncate_dimension::Union{Int, Nothing} = nothing,
        cost_tracker = Threads.Atomic{Float64}(0.0),
        target_batch_size_length::Int = 80_000,
        ntasks::Int = 4 * Threads.nthreads(),
        kwargs...)
      

Embeds a vector of `docs` using the provided model (kwarg `model`) in a batched manner - `BatchEmbedder`.

`BatchEmbedder` tries to batch embedding calls for roughly 80K characters per call (to avoid exceeding the API rate limit) to reduce network latency.

# Notes
- `docs` are assumed to be already chunked to the reasonable sizes that fit within the embedding context limit.
- If you get errors about exceeding input sizes, first check the `max_length` in your chunks. 
  If that does NOT resolve the issue, try reducing the `target_batch_size_length` parameter (eg, 10_000) and number of tasks `ntasks=1`. 
  Some providers cannot handle large batch sizes.

# Arguments
- `docs`: A vector of strings to be embedded.
- `verbose`: A boolean flag for verbose output. Default is `true`.
- `model`: The model to use for embedding. Default is `PT.MODEL_EMBEDDING`.
- `truncate_dimension`: The dimensionality of the embeddings to truncate to. Default is `nothing`, `0` will also do nothing.
- `cost_tracker`: A `Threads.Atomic{Float64}` object to track the total cost of the API calls. Useful to pass the total cost to the parent call.
- `target_batch_size_length`: The target length (in characters) of each batch of document chunks sent for embedding. Default is 80_000 characters. Speeds up embedding process.
- `ntasks`: The number of tasks to use for asyncmap. Default is 4 * Threads.nthreads().

"""
function get_embeddings(embedder::BatchEmbedder, docs::AbstractVector{<:AbstractString};
        verbose::Bool = true,
        model::AbstractString = PT.MODEL_EMBEDDING,
        truncate_dimension::Union{Int, Nothing} = nothing,
        cost_tracker = Threads.Atomic{Float64}(0.0),
        target_batch_size_length::Int = 80_000,
        ntasks::Int = 4 * Threads.nthreads(),
        kwargs...)
    @assert !isempty(docs) "The list of docs to get embeddings from should not be empty."

    ## check if extension is available
    ext = Base.get_extension(PromptingTools, :RAGToolsExperimentalExt)
    if isnothing(ext)
        error("You need to also import LinearAlgebra, Unicode, SparseArrays to use this function")
    end
    verbose && @info "Embedding $(length(docs)) documents..."
    # Notice that we embed multiple docs at once, not one by one
    # OpenAI supports embedding multiple documents to reduce the number of API calls/network latency time
    # We do batch them just in case the documents are too large (targeting at most 80K characters per call)
    avg_length = sum(length.(docs)) / length(docs)
    embedding_batch_size = floor(Int, target_batch_size_length / avg_length)
    embeddings = asyncmap(Iterators.partition(docs, embedding_batch_size);
        ntasks) do docs_chunk
        msg = aiembed(docs_chunk,
            # LinearAlgebra.normalize but imported in RAGToolsExperimentalExt
            _normalize;
            model,
            verbose = false,
            kwargs...)
        Threads.atomic_add!(cost_tracker, msg.cost) # track costs
        msg.content
    end
    ## Concat across documents and truncate if needed
    embeddings = hcat_truncate(embeddings, truncate_dimension; verbose)
    ## Normalize embeddings
    verbose && @info "Done embedding. Total cost: \$$(round(cost_tracker[],digits=3))"
    return embeddings
end

"""
    get_embeddings(embedder::BinaryBatchEmbedder, docs::AbstractVector{<:AbstractString};
        verbose::Bool = true,
        model::AbstractString = PT.MODEL_EMBEDDING,
        truncate_dimension::Union{Int, Nothing} = nothing,
        return_type::Type = Matrix{Bool},
        cost_tracker = Threads.Atomic{Float64}(0.0),
        target_batch_size_length::Int = 80_000,
        ntasks::Int = 4 * Threads.nthreads(),
        kwargs...)
      

Embeds a vector of `docs` using the provided model (kwarg `model`) in a batched manner and then returns the binary embeddings matrix - `BinaryBatchEmbedder`.

`BinaryBatchEmbedder` tries to batch embedding calls for roughly 80K characters per call (to avoid exceeding the API rate limit) to reduce network latency.

# Notes
- `docs` are assumed to be already chunked to the reasonable sizes that fit within the embedding context limit.
- If you get errors about exceeding input sizes, first check the `max_length` in your chunks. 
  If that does NOT resolve the issue, try reducing the `target_batch_size_length` parameter (eg, 10_000) and number of tasks `ntasks=1`. 
  Some providers cannot handle large batch sizes.

# Arguments
- `docs`: A vector of strings to be embedded.
- `verbose`: A boolean flag for verbose output. Default is `true`.
- `model`: The model to use for embedding. Default is `PT.MODEL_EMBEDDING`.
- `truncate_dimension`: The dimensionality of the embeddings to truncate to. Default is `nothing`.
- `return_type`: The type of the returned embeddings matrix. Default is `Matrix{Bool}`. Choose `BitMatrix` to minimize storage requirements, `Matrix{Bool}` to maximize performance in elementwise-ops.
- `cost_tracker`: A `Threads.Atomic{Float64}` object to track the total cost of the API calls. Useful to pass the total cost to the parent call.
- `target_batch_size_length`: The target length (in characters) of each batch of document chunks sent for embedding. Default is 80_000 characters. Speeds up embedding process.
- `ntasks`: The number of tasks to use for asyncmap. Default is 4 * Threads.nthreads().

"""
function get_embeddings(
        embedder::BinaryBatchEmbedder, docs::AbstractVector{<:AbstractString};
        verbose::Bool = true,
        model::AbstractString = PT.MODEL_EMBEDDING,
        truncate_dimension::Union{Int, Nothing} = nothing,
        return_type::Type = Matrix{Bool},
        cost_tracker = Threads.Atomic{Float64}(0.0),
        target_batch_size_length::Int = 80_000,
        ntasks::Int = 4 * Threads.nthreads(),
        kwargs...)
    @assert !isempty(docs) "The list of docs to get embeddings from should not be empty."

    emb = get_embeddings(BatchEmbedder(), docs; verbose, model, truncate_dimension,
        cost_tracker, target_batch_size_length, ntasks, kwargs...)
    # This will return Matrix{Bool}, eg, map(>(0),emb)
    emb = map(>(0), emb) |> x -> x isa return_type ? x : return_type(x)
end

"""
    get_embeddings(embedder::BitPackedBatchEmbedder, docs::AbstractVector{<:AbstractString};
        verbose::Bool = true,
        model::AbstractString = PT.MODEL_EMBEDDING,
        truncate_dimension::Union{Int, Nothing} = nothing,
        cost_tracker = Threads.Atomic{Float64}(0.0),
        target_batch_size_length::Int = 80_000,
        ntasks::Int = 4 * Threads.nthreads(),
        kwargs...)
      

Embeds a vector of `docs` using the provided model (kwarg `model`) in a batched manner and then returns the binary embeddings matrix represented in UInt64 (bit-packed) - `BitPackedBatchEmbedder`.

`BitPackedBatchEmbedder` tries to batch embedding calls for roughly 80K characters per call (to avoid exceeding the API rate limit) to reduce network latency.

The best option for FAST and MEMORY-EFFICIENT storage of embeddings, for retrieval use `BitPackedCosineSimilarity`.

# Notes
- `docs` are assumed to be already chunked to the reasonable sizes that fit within the embedding context limit.
- If you get errors about exceeding input sizes, first check the `max_length` in your chunks. 
  If that does NOT resolve the issue, try reducing the `target_batch_size_length` parameter (eg, 10_000) and number of tasks `ntasks=1`. 
  Some providers cannot handle large batch sizes.

# Arguments
- `docs`: A vector of strings to be embedded.
- `verbose`: A boolean flag for verbose output. Default is `true`.
- `model`: The model to use for embedding. Default is `PT.MODEL_EMBEDDING`.
- `truncate_dimension`: The dimensionality of the embeddings to truncate to. Default is `nothing`.
- `cost_tracker`: A `Threads.Atomic{Float64}` object to track the total cost of the API calls. Useful to pass the total cost to the parent call.
- `target_batch_size_length`: The target length (in characters) of each batch of document chunks sent for embedding. Default is 80_000 characters. Speeds up embedding process.
- `ntasks`: The number of tasks to use for asyncmap. Default is 4 * Threads.nthreads().

See also: `unpack_bits`, `pack_bits`, `BitPackedCosineSimilarity`.
"""
function get_embeddings(
        embedder::BitPackedBatchEmbedder, docs::AbstractVector{<:AbstractString};
        verbose::Bool = true,
        model::AbstractString = PT.MODEL_EMBEDDING,
        truncate_dimension::Union{Int, Nothing} = nothing,
        cost_tracker = Threads.Atomic{Float64}(0.0),
        target_batch_size_length::Int = 80_000,
        ntasks::Int = 4 * Threads.nthreads(),
        kwargs...)
    @assert !isempty(docs) "The list of docs to get embeddings from should not be empty."

    emb = get_embeddings(BatchEmbedder(), docs; verbose, model, truncate_dimension,
        cost_tracker, target_batch_size_length, ntasks, kwargs...)
    # This will return Matrix{UInt64} to save space
    # Use unpack_bits to convert back to BitMatrix
    pack_bits(emb .> 0)
end
### Keywords Processing (for BM25)

## Supporting functions defined in RAGToolsExperimentalExt.jl because they require SparseArrays
function document_term_matrix(documents)
    throw(ArgumentError("You need to also import LinearAlgebra, Unicode, and SparseArrays to use this function"))
end

function bm25(dtm, query; kwargs...)
    throw(ArgumentError("You need to also import LinearAlgebra, Unicode, and SparseArrays to use this function"))
end

function get_keywords(processor::AbstractProcessor, docs::AbstractVector{<:AbstractString};
        verbose::Bool = true,
        kwargs...)
    ext = Base.get_extension(PromptingTools, :SnowballPromptingToolsExt)
    if processor isa KeywordsProcessor && isnothing(ext)
        throw(ArgumentError("You need to also import Snowball.jl to use this function"))
    else
        throw(ArgumentError("Not implemented for processor $(typeof(processor))."))
    end
end

function get_keywords(processor::NoProcessor, docs::AbstractVector{<:AbstractString};
        verbose::Bool = true,
        kwargs...)
    docs
end

### Tag Extraction

function get_tags(tagger::AbstractTagger, docs::AbstractVector{<:AbstractString};
        kwargs...)
    throw(ArgumentError("Not implemented for tagger $(typeof(tagger))"))
end

"""
    tags_extract(item::Tag)
    tags_extract(tags::Vector{Tag})

Extracts the `Tag` item into a string of the form `category:::value` (lowercased and spaces replaced with underscores).

# Example
```julia
msg = aiextract(:RAGExtractMetadataShort; return_type=MaybeTags, text="I like package DataFrames", instructions="None.")
metadata = tags_extract(msg.content.items)
```
"""
function tags_extract(item::Tag)
    "$(strip(item.category)):::$(strip(item.value))" |> lowercase |>
    x -> replace(x, " " => "_")
end
tags_extract(items::Nothing) = String[]
tags_extract(items::Vector{Tag}) = tags_extract.(items)

"""
    get_tags(tagger::NoTagger, docs::AbstractVector{<:AbstractString};
        kwargs...)

Simple no-op that skips any tagging of the documents
"""
function get_tags(tagger::NoTagger, docs::AbstractVector{<:AbstractString};
        kwargs...)
    nothing
end

"""
    get_tags(tagger::PassthroughTagger, docs::AbstractVector{<:AbstractString};
        tags::AbstractVector{<:AbstractVector{<:AbstractString}},
        kwargs...)

Pass `tags` directly as Vector of Vectors of strings (ie, `tags[i]` is the tags for `docs[i]`).
It then builds the vocabulary from the tags and returns both the tags in matrix form and the vocabulary.
"""
function get_tags(tagger::PassthroughTagger, docs::AbstractVector{<:AbstractString};
        tags::AbstractVector{<:AbstractVector{<:AbstractString}},
        kwargs...)
    @assert length(docs)==length(tags) "Length of `docs` must match length of `tags`"
    return tags
end

"""
    get_tags(tagger::OpenTagger, docs::AbstractVector{<:AbstractString};
        verbose::Bool = true,
        cost_tracker = Threads.Atomic{Float64}(0.0),
        kwargs...)

Extracts "tags" (metadata/keywords) from a vector of `docs` using the provided model (kwarg `model`).

# Arguments
- `docs`: A vector of strings to be embedded.
- `verbose`: A boolean flag for verbose output. Default is `true`.
- `model`: The model to use for tags extraction. Default is `PT.MODEL_CHAT`.
- `template`: A template to be used for tags extraction. Default is `:RAGExtractMetadataShort`.
- `cost_tracker`: A `Threads.Atomic{Float64}` object to track the total cost of the API calls. Useful to pass the total cost to the parent call.
"""
function get_tags(tagger::OpenTagger, docs::AbstractVector{<:AbstractString};
        verbose::Bool = true,
        model::AbstractString = PT.MODEL_CHAT,
        template::Symbol = :RAGExtractMetadataShort,
        cost_tracker = Threads.Atomic{Float64}(0.0),
        kwargs...)
    _check_aiextract_capability(model)
    ## check if extension is available
    ext = Base.get_extension(PromptingTools, :RAGToolsExperimentalExt)
    if isnothing(ext)
        error("You need to also import LinearAlgebra, Unicode, and SparseArrays to use this function")
    end
    verbose && @info "Extracting metadata from $(length(docs)) documents..."
    tags_extracted = asyncmap(docs) do docs_chunk
        try
            msg = aiextract(template;
                return_type = MaybeTags,
                text = docs_chunk,
                instructions = "None.",
                verbose = false,
                model, kwargs...)
            Threads.atomic_add!(cost_tracker, msg.cost) # track costs
            items = tags_extract(msg.content.items)
        catch
            String[]
        end
    end

    verbose &&
        @info "Done extracting the tags. Total cost: \$$(round(cost_tracker[],digits=3))"

    return tags_extracted
end

"""
    build_tags(tagger::AbstractTagger, chunk_tags::Nothing; kwargs...)

No-op that skips any tag building, returning `nothing, nothing`

Otherwise, it would build the sparse matrix and the vocabulary (requires `SparseArrays` and `LinearAlgebra` packages to be loaded).
"""
function build_tags(tagger::AbstractTagger, chunk_tags::Nothing; kwargs...)
    nothing, nothing
end

"""
    build_index(
        indexer::AbstractIndexBuilder, files_or_docs::Vector{<:AbstractString};
        verbose::Integer = 1,
        extras::Union{Nothing, AbstractVector} = nothing,
        index_id = gensym("ChunkEmbeddingsIndex"),
        chunker::AbstractChunker = indexer.chunker,
        chunker_kwargs::NamedTuple = NamedTuple(),
        embedder::AbstractEmbedder = indexer.embedder,
        embedder_kwargs::NamedTuple = NamedTuple(),
        tagger::AbstractTagger = indexer.tagger,
        tagger_kwargs::NamedTuple = NamedTuple(),
        api_kwargs::NamedTuple = NamedTuple(),
        cost_tracker = Threads.Atomic{Float64}(0.0))

Build an INDEX for RAG (Retriever-Augmented Generation) applications from the provided file paths. 
INDEX is a object storing the document chunks and their embeddings (and potentially other information).

The function processes each file or document (depending on `chunker`), splits its content into chunks, embeds these chunks, 
optionally extracts metadata, and then combines this information into a retrievable index.

Define your own methods via `indexer` and its subcomponents (`chunker`, `embedder`, `tagger`).

# Arguments
- `indexer::AbstractIndexBuilder`: The indexing logic to use. Default is `SimpleIndexer()`.
- `files_or_docs`: A vector of valid file paths OR string documents to be indexed (chunked and embedded). Specify which mode to use via `chunker`.
- `verbose`: An Integer specifying the verbosity of the logs. Default is `1` (high-level logging). `0` is disabled.
- `extras`: An optional vector of extra information to be stored with each chunk. Default is `nothing`.
- `index_id`: A unique identifier for the index. Default is a generated symbol.
- `chunker`: The chunker logic to use for splitting the documents. Default is `TextChunker()`.
- `chunker_kwargs`: Parameters to be provided to the `get_chunks` function. Useful to change the `separators` or `max_length`.
  - `sources`: A vector of strings indicating the source of each chunk. Default is equal to `files_or_docs`.
- `embedder`: The embedder logic to use for embedding the chunks. Default is `BatchEmbedder()`.
- `embedder_kwargs`: Parameters to be provided to the `get_embeddings` function. Useful to change the `target_batch_size_length` or reduce asyncmap tasks `ntasks`.
  - `model`: The model to use for embedding. Default is `PT.MODEL_EMBEDDING`.
- `tagger`: The tagger logic to use for extracting tags from the chunks. Default is `NoTagger()`, ie, skip tag extraction. There are also `PassthroughTagger` and `OpenTagger`.
- `tagger_kwargs`: Parameters to be provided to the `get_tags` function.
  - `model`: The model to use for tags extraction. Default is `PT.MODEL_CHAT`.
  - `template`: A template to be used for tags extraction. Default is `:RAGExtractMetadataShort`.
  - `tags`: A vector of vectors of strings directly providing the tags for each chunk. Applicable for `tagger::PasstroughTagger`.
- `api_kwargs`: Parameters to be provided to the API endpoint. Shared across all API calls if provided.
- `cost_tracker`: A `Threads.Atomic{Float64}` object to track the total cost of the API calls. Useful to pass the total cost to the parent call.

# Returns
- `ChunkEmbeddingsIndex`: An object containing the compiled index of chunks, embeddings, tags, vocabulary, and sources.

See also: `ChunkEmbeddingsIndex`, `get_chunks`, `get_embeddings`, `get_tags`, `CandidateChunks`, `find_closest`, `find_tags`, `rerank`, `retrieve`, `generate!`, `airag`

# Examples
```julia
# Default is loading a vector of strings and chunking them (`TextChunker()`)
index = build_index(SimpleIndexer(), texts; chunker_kwargs = (; max_length=10))

# Another example with tags extraction, splitting only sentences and verbose output
# Assuming `test_files` is a vector of file paths
indexer = SimpleIndexer(chunker=FileChunker(), tagger=OpenTagger())
index = build_index(indexer, test_files; 
        chunker_kwargs(; separators=[". "]), verbose=true)
```

# Notes
- If you get errors about exceeding embedding input sizes, first check the `max_length` in your chunks. 
  If that does NOT resolve the issue, try changing the `embedding_kwargs`. 
  In particular, reducing the `target_batch_size_length` parameter (eg, 10_000) and number of tasks `ntasks=1`. 
  Some providers cannot handle large batch sizes (eg, Databricks).

"""
function build_index(
        indexer::AbstractIndexBuilder, files_or_docs::Vector{<:AbstractString};
        verbose::Integer = 1,
        extras::Union{Nothing, AbstractVector} = nothing,
        index_id = gensym("ChunkEmbeddingsIndex"),
        chunker::AbstractChunker = indexer.chunker,
        chunker_kwargs::NamedTuple = NamedTuple(),
        embedder::AbstractEmbedder = indexer.embedder,
        embedder_kwargs::NamedTuple = NamedTuple(),
        tagger::AbstractTagger = indexer.tagger,
        tagger_kwargs::NamedTuple = NamedTuple(),
        api_kwargs::NamedTuple = NamedTuple(),
        cost_tracker = Threads.Atomic{Float64}(0.0))

    ## Split into chunks
    chunks, sources = get_chunks(chunker, files_or_docs;
        chunker_kwargs...)

    ## Embed chunks
    embeddings = get_embeddings(embedder, chunks;
        verbose = (verbose > 1),
        cost_tracker,
        api_kwargs, embedder_kwargs...)

    ## Extract tags
    tags_extracted = get_tags(tagger, chunks;
        verbose = (verbose > 1),
        cost_tracker,
        api_kwargs, tagger_kwargs...)
    # Build the sparse matrix and the vocabulary
    tags, tags_vocab = build_tags(tagger, tags_extracted)

    (verbose > 0) && @info "Index built! (cost: \$$(round(cost_tracker[], digits=3)))"

    index = ChunkEmbeddingsIndex(; id = index_id, embeddings, tags, tags_vocab,
        chunks, sources, extras)
    return index
end

"""
    build_index(
        indexer::KeywordsIndexer, files_or_docs::Vector{<:AbstractString};
        verbose::Integer = 1,
        extras::Union{Nothing, AbstractVector} = nothing,
        index_id = gensym("ChunkKeywordsIndex"),
        chunker::AbstractChunker = indexer.chunker,
        chunker_kwargs::NamedTuple = NamedTuple(),
        processor::AbstractProcessor = indexer.processor,
        processor_kwargs::NamedTuple = NamedTuple(),
        tagger::AbstractTagger = indexer.tagger,
        tagger_kwargs::NamedTuple = NamedTuple(),
        api_kwargs::NamedTuple = NamedTuple(),
        cost_tracker = Threads.Atomic{Float64}(0.0))

Builds a `ChunkKeywordsIndex` from the provided files or documents to support keyword-based search (BM25).
"""
function build_index(
        indexer::KeywordsIndexer, files_or_docs::Vector{<:AbstractString};
        verbose::Integer = 1,
        extras::Union{Nothing, AbstractVector} = nothing,
        index_id = gensym("ChunkKeywordsIndex"),
        chunker::AbstractChunker = indexer.chunker,
        chunker_kwargs::NamedTuple = NamedTuple(),
        processor::AbstractProcessor = indexer.processor,
        processor_kwargs::NamedTuple = NamedTuple(),
        tagger::AbstractTagger = indexer.tagger,
        tagger_kwargs::NamedTuple = NamedTuple(),
        api_kwargs::NamedTuple = NamedTuple(),
        cost_tracker = Threads.Atomic{Float64}(0.0))

    ## Split into chunks
    chunks, sources = get_chunks(chunker, files_or_docs;
        chunker_kwargs...)

    ## Tokenize and DTM
    dtm = get_keywords(processor, chunks;
        verbose = (verbose > 1),
        cost_tracker,
        api_kwargs, processor_kwargs...)

    ## Extract tags
    tags_extracted = get_tags(tagger, chunks;
        verbose = (verbose > 1),
        cost_tracker,
        api_kwargs, tagger_kwargs...)
    # Build the sparse matrix and the vocabulary
    tags, tags_vocab = build_tags(tagger, tags_extracted)

    (verbose > 0) && @info "Index built! (cost: \$$(round(cost_tracker[], digits=3)))"

    index = ChunkKeywordsIndex(; id = index_id, chunkdata = dtm, tags, tags_vocab,
        chunks, sources, extras)
    return index
end

# TODO: where to put these?
using Pinecone: Pinecone, PineconeContextv3, PineconeIndexv3, init_v3, Index, PineconeVector, upsert
using UUIDs: UUIDs, uuid4
"""
    build_index(
        indexer::PineconeIndexer, files_or_docs::Vector{<:AbstractString};
        metadata::Vector{Dict{String, Any}} = Vector{Dict{String, Any}}(),
        pinecone_context::Pinecone.PineconeContextv3 = Pinecone.init_v3(""),
        pinecone_index::Pinecone.PineconeIndexv3 = nothing,
        pinecone_namespace::AbstractString = "",
        upsert::Bool = true,
        verbose::Integer = 1,
        index_id = gensym(pinecone_namespace),
        chunker::AbstractChunker = indexer.chunker,
        chunker_kwargs::NamedTuple = NamedTuple(),
        embedder::AbstractEmbedder = indexer.embedder,
        embedder_kwargs::NamedTuple = NamedTuple(),
        tagger::AbstractTagger = indexer.tagger,
        tagger_kwargs::NamedTuple = NamedTuple(),
        api_kwargs::NamedTuple = NamedTuple(),
        cost_tracker = Threads.Atomic{Float64}(0.0))

Builds a `PineconeIndex` containing a Pinecone context (API key, index and namespace).
The index stores the document chunks and their embeddings (and potentially other information).

The function processes each file or document (depending on `chunker`), splits its content into chunks, embeds these chunks
and then combines this information into a retrievable index. The chunks and embeddings are upsert to Pinecone using
the provided Pinecone context (unless the `upsert` flag is set to `false`).

# Arguments
- `indexer::PineconeIndexer`: The indexing logic for Pinecone operations.
- `files_or_docs`: A vector of valid file paths to be indexed (chunked and embedded).
- `metadata::Vector{Dict{String, Any}}`: A vector of metadata attributed to each docs file, given as dictionaries with `String` keys. Default is empty vector.
- `pinecone_context::Pinecone.PineconeContextv3`: The Pinecone API key generated using Pinecone.jl. Must be specified.
- `pinecone_index::Pinecone.PineconeIndexv3`: The Pinecone index generated using Pinecone.jl. Must be specified.
- `pinecone_namespace::AbstractString`: The Pinecone namespace associated to `pinecone_index`.
- `upsert::Bool = true`: A flag specifying whether to upsert the chunks and embeddings to Pinecone. Defaults to `true`.
- `verbose`: An Integer specifying the verbosity of the logs. Default is `1` (high-level logging). `0` is disabled.
- `index_id`: A unique identifier for the index. Default is a generated symbol.
- `chunker`: The chunker logic to use for splitting the documents. Default is `TextChunker()`.
- `chunker_kwargs`: Parameters to be provided to the `get_chunks` function. Useful to change the `separators` or `max_length`.
  - `sources`: A vector of strings indicating the source of each chunk. Default is equal to `files_or_docs`.
- `embedder`: The embedder logic to use for embedding the chunks. Default is `BatchEmbedder()`.
- `embedder_kwargs`: Parameters to be provided to the `get_embeddings` function. Useful to change the `target_batch_size_length` or reduce asyncmap tasks `ntasks`.
  - `model`: The model to use for embedding. Default is `PT.MODEL_EMBEDDING`.
- `tagger`: The tagger logic to use for extracting tags from the chunks. Default is `NoTagger()`, ie, skip tag extraction. There are also `PassthroughTagger` and `OpenTagger`.
- `tagger_kwargs`: Parameters to be provided to the `get_tags` function.
  - `model`: The model to use for tags extraction. Default is `PT.MODEL_CHAT`.
  - `template`: A template to be used for tags extraction. Default is `:RAGExtractMetadataShort`.
  - `tags`: A vector of vectors of strings directly providing the tags for each chunk. Applicable for `tagger::PasstroughTagger`.
- `api_kwargs`: Parameters to be provided to the API endpoint. Shared across all API calls if provided.
- `cost_tracker`: A `Threads.Atomic{Float64}` object to track the total cost of the API calls. Useful to pass the total cost to the parent call.

# Returns
- `PineconeIndex`: An object containing the compiled index of chunks, embeddings, tags, vocabulary, sources and metadata, together with the Pinecone connection data.

See also: `PineconeIndex`, `get_chunks`, `get_embeddings`, `get_tags`, `CandidateWithChunks`, `find_closest`, `find_tags`, `rerank`, `retrieve`, `generate!`, `airag`

# Examples
```julia
using Pinecone

# Prepare the Pinecone connection data
pinecone_context = Pinecone.init_v3(ENV["PINECONE_API_KEY"])
pindex = ENV["PINECONE_INDEX"]
pinecone_index = !isempty(pindex) ? Pinecone.Index(pinecone_context, pindex) : nothing
namespace = "my-namespace"

# Add metadata about the sources in Pinecone
metadata = [Dict{String, Any}("source" => doc_file) for doc_file in docs_files]

# Build the index. By default, the chunks and embeddings get upserted to Pinecone.
const RT = PromptingTools.Experimental.RAGTools
index_pinecone = RT.build_index(
    RT.PineconeIndexer(),
    docs_files;
    pinecone_context = pinecone_context,
    pinecone_index = pinecone_index,
    pinecone_namespace = namespace,
    metadata = metadata
)

# Notes
- If you get errors about exceeding embedding input sizes, first check the `max_length` in your chunks. 
  If that does NOT resolve the issue, try changing the `embedding_kwargs`. 
  In particular, reducing the `target_batch_size_length` parameter (eg, 10_000) and number of tasks `ntasks=1`. 
  Some providers cannot handle large batch sizes (eg, Databricks).

"""
function build_index(
        indexer::PineconeIndexer, files_or_docs::Vector{<:AbstractString};
        metadata::Vector{Dict{String, Any}} = Vector{Dict{String, Any}}(),
        pinecone_context::Pinecone.PineconeContextv3 = Pinecone.init_v3(""),
        pinecone_index::Pinecone.PineconeIndexv3 = nothing,
        pinecone_namespace::AbstractString = "",
        upsert::Bool = true,
        verbose::Integer = 1,
        index_id = gensym(pinecone_namespace),
        chunker::AbstractChunker = indexer.chunker,
        chunker_kwargs::NamedTuple = NamedTuple(),
        embedder::AbstractEmbedder = indexer.embedder,
        embedder_kwargs::NamedTuple = NamedTuple(),
        tagger::AbstractTagger = indexer.tagger,
        tagger_kwargs::NamedTuple = NamedTuple(),
        api_kwargs::NamedTuple = NamedTuple(),
        cost_tracker = Threads.Atomic{Float64}(0.0))
    @assert !isempty(pinecone_context.apikey) && !isnothing(pinecone_index) "Pinecone context and index not set"

    ## Split into chunks
    chunks, sources = get_chunks(chunker, files_or_docs;
        chunker_kwargs...)
    ## Get metadata for each chunk
    if isempty(metadata)
        metadata = [Dict{String, Any}() for _ in sources]
    else
        metadata = [metadata[findfirst(f -> f == source, files_or_docs)] for source in sources]
        [metadata[idx]["content"] = chunk for (idx, chunk) in enumerate(chunks)]
    end

    ## Embed chunks
    embeddings = get_embeddings(embedder, chunks;
        verbose = (verbose > 1),
        cost_tracker,
        api_kwargs, embedder_kwargs...)

    ## Extract tags
    tags_extracted = get_tags(tagger, chunks;
        verbose = (verbose > 1),
        cost_tracker,
        api_kwargs, tagger_kwargs...)
    # Build the sparse matrix and the vocabulary
    tags, tags_vocab = build_tags(tagger, tags_extracted)

    # Upsert to Pinecone
    if upsert
        embeddings_arr = [embeddings[:,i] for i in axes(embeddings,2)]
        for (idx, emb) in enumerate(embeddings_arr)
            pinevector = Pinecone.PineconeVector(string(UUIDs.uuid4()), emb, metadata[idx])
            Pinecone.upsert(pinecone_context, pinecone_index, [pinevector], pinecone_namespace)
            @info "Upsert #$idx complete"
        end
    end

    index = PineconeIndex(; id = index_id, pinecone_context, pinecone_index, pinecone_namespace, chunks, embeddings, tags, tags_vocab, metadata, sources)

    (verbose > 0) && @info "Index built! (cost: \$$(round(cost_tracker[], digits=3)))"

    return index
end

# Convenience for easy index creation
"""
    ChunkKeywordsIndex(
        [processor::AbstractProcessor=KeywordsProcessor(),] index::ChunkEmbeddingsIndex; verbose::Int = 1,
        index_id = gensym("ChunkKeywordsIndex"), processor_kwargs...)

Convenience method to quickly create a `ChunkKeywordsIndex` from an existing `ChunkEmbeddingsIndex`.

# Example
```julia

# Let's assume we have a standard embeddings-based index
index = build_index(SimpleIndexer(), texts; chunker_kwargs = (; max_length=10))

# Creating an additional index for keyword-based search (BM25), is as simple as
index_keywords = ChunkKeywordsIndex(index)

# We can immediately create a MultiIndex (a hybrid index holding both indices)
multi_index = MultiIndex([index, index_keywords])

```
"""
function ChunkKeywordsIndex(
        processor::AbstractProcessor, index::ChunkEmbeddingsIndex; verbose::Int = 1,
        index_id = gensym("ChunkKeywordsIndex"), processor_kwargs...)
    dtm = get_keywords(processor, chunks(index);
        verbose = (verbose > 1),
        processor_kwargs...)

    (verbose > 0) && @info "Index built!"
    ChunkKeywordsIndex(index_id,
        chunks(index), dtm, tags(index), tags_vocab(index), sources(index), extras(index))
end
function ChunkKeywordsIndex(
        index::ChunkEmbeddingsIndex; kwargs...)
    ChunkKeywordsIndex(KeywordsProcessor(), index; kwargs...)
end

# Default dispatch
const DEFAULT_INDEXER = SimpleIndexer()
function build_index(files_or_docs::Vector{<:AbstractString}; kwargs...)
    build_index(DEFAULT_INDEXER, files_or_docs; kwargs...)
end
