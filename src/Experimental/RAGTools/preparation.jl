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
    BatchEmbedder <: AbstractEmbedder

Default embedder for `get_embeddings` functions. It passes individual documents to be embedded in chunks to `aiembed`.
"""
struct BatchEmbedder <: AbstractEmbedder end

### Tagging Types
"""
    NoTagger <: AbstractTagger

No-op tagger for `get_tags` functions. It returns (`nothing`, `nothing`).
"""
struct NoTagger <: AbstractTagger end

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

It uses `FileChunker`, `BatchEmbedder`, and `NoTagger` as default chunker, embedder, and tagger.
"""
@kwdef mutable struct SimpleIndexer <: AbstractIndexBuilder
    chunker::AbstractChunker = FileChunker()
    embedder::AbstractEmbedder = BatchEmbedder()
    tagger::AbstractTagger = NoTagger()
end

### Functions

## "Build an index for RAG (Retriever-Augmented Generation) applications. REQUIRES SparseArrays and LinearAlgebra packages to be loaded!!"
## function build_index end

"Shortcut to LinearAlgebra.normalize. Provided in the package extension `RAGToolsExperimentalExt` (Requires SparseArrays and LinearAlgebra)"
function _normalize end

"""
    load_text(chunker::AbstractChunker, input;
        kwargs...)

Load text from `input` using the provided `chunker`

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
    @assert all(isfile, input) "Path $input does not exist"
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

"""
    get_embeddings(embedder::AbstractEmbedder = BatchEmbedder(), docs::Vector{<:AbstractString};
        verbose::Bool = true,
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
- `cost_tracker`: A `Threads.Atomic{Float64}` object to track the total cost of the API calls. Useful to pass the total cost to the parent call.
- `target_batch_size_length`: The target length (in characters) of each batch of document chunks sent for embedding. Default is 80_000 characters. Speeds up embedding process.
- `ntasks`: The number of tasks to use for asyncmap. Default is 4 * Threads.nthreads().

"""
function get_embeddings(embedder::AbstractEmbedder, docs::Vector{<:AbstractString};
        verbose::Bool = true,
        model::AbstractString = PT.MODEL_EMBEDDING,
        cost_tracker = Threads.Atomic{Float64}(0.0),
        target_batch_size_length::Int = 80_000,
        ntasks::Int = 4 * Threads.nthreads(),
        kwargs...)
    ## check if extension is available
    ext = Base.get_extension(PromptingTools, :RAGToolsExperimentalExt)
    if isnothing(ext)
        error("You need to also import LinearAlgebra and SparseArrays to use this function")
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
    embeddings = hcat(embeddings...) .|> Float32 # flatten, columns are documents
    verbose && @info "Done embedding. Total cost: \$$(round(cost_tracker[],digits=3))"
    return embeddings
end

### Tag Extraction

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
tags_extract(items::Vector{Tag}) = metadata_extract.(items)

"""
    get_tags(tagger::NoTagger, docs::Vector{<:AbstractString};
        kwargs...)

Simple no-op that skips any tagging of the documents
"""
function get_tags(tagger::NoTagger, docs::Vector{<:AbstractString};
        kwargs...)
    nothing, nothing
end

"""
    get_tags(tagger::AbstractTagger = OpenTagger(), docs::Vector{<:AbstractString};
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
function get_tags(tagger::AbstractTagger, docs::Vector{<:AbstractString};
        verbose::Bool = true,
        model::AbstractString = PT.MODEL_CHAT,
        template::Symbol = :RAGExtractMetadataShort,
        cost_tracker = Threads.Atomic{Float64}(0.0),
        kwargs...)
    _check_aiextract_capability(model)
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

    # Build the sparse matrix and the vocabulary
    tags, tags_vocab = build_tags(tagger, tags_extracted)

    verbose &&
        @info "Done extracting the metadata. Total cost: \$$(round(cost_tracker[],digits=3))"

    return tags, tags_vocab
end

"""
    build_index(
        indexer::AbstractIndexBuilder, files_or_docs::Vector{<:AbstractString};
        verbose::Integer = 1,
        extras::Union{Nothing, AbstractVector} = nothing,
        index_id = gensym("ChunkIndex"),
        chunker::AbstractChunker = indexer.chunker,
        chunker_kwargs::NamedTuple = NamedTuple(),
        embedder::AbstractEmbedder = indexer.embedder,
        embedder_kwargs::NamedTuple = NamedTuple(),
        tagger::AbstractTagger = indexer.tagger,
        tagger_kwargs::NamedTuple = NamedTuple(),
        api_kwargs::NamedTuple = NamedTuple(),
        cost_tracker = Threads.Atomic{Float64}(0.0))

Build an index for RAG (Retriever-Augmented Generation) applications from the provided file paths. 
The function processes each file, splits its content into chunks, embeds these chunks, 
optionally extracts metadata, and then compiles this information into a retrievable index.

Define your own methods via `indexer` and its subcomponents (`chunker`, `embedder`, `tagger`).

# Arguments
- `indexer::AbstractIndexBuilder`: The indexing logic to use. Default is `SimpleIndexer()`.
- `files_or_docs`: A vector of valid file paths OR string documents to be indexed (chunked and embedded).
- `verbose`: An Integer specifying the verbosity of the logs. Default is `1` (high-level logging). `0` is disabled.
- `extras`: An optional vector of extra information to be stored with each chunk. Default is `nothing`.
- `index_id`: A unique identifier for the index. Default is a generated symbol.
- `chunker`: The chunker logic to use for splitting the documents. Default is `FileChunker()`.
- `chunker_kwargs`: Parameters to be provided to the `get_chunks` function. Useful to change the `separators` or `max_length`.
  - `sources`: A vector of strings indicating the source of each chunk. Default is equal to `files_or_docs`.
- `embedder`: The embedder logic to use for embedding the chunks. Default is `BatchEmbedder()`.
- `embedder_kwargs`: Parameters to be provided to the `get_embeddings` function. Useful to change the `target_batch_size_length` or reduce asyncmap tasks `ntasks`.
  - `model`: The model to use for embedding. Default is `PT.MODEL_EMBEDDING`.
- `tagger`: The tagger logic to use for extracting tags from the chunks. Default is `NoTagger()`, ie, skip tag extraction.
- `tagger_kwargs`: Parameters to be provided to the `get_tags` function.
  - `model`: The model to use for tags extraction. Default is `PT.MODEL_CHAT`.
  - `template`: A template to be used for tags extraction. Default is `:RAGExtractMetadataShort`.
- `api_kwargs`: Parameters to be provided to the API endpoint. Shared across all API calls if provided.
- `cost_tracker`: A `Threads.Atomic{Float64}` object to track the total cost of the API calls. Useful to pass the total cost to the parent call.

# Returns
- `ChunkIndex`: An object containing the compiled index of chunks, embeddings, tags, vocabulary, and sources.

See also: `ChunkIndex`, `get_chunks`, `get_embeddings`, `get_tags`, `CandidateChunks`, `find_closest`, `find_tags`, `rerank`, `airag`

# Examples
```julia

# Assuming `test_files` is a vector of file paths
index = build_index(SimpleIndexer(), test_files; chunker_kwargs = (; max_length=10))

# Another example with tags extraction, splitting only sentences and verbose output
indexer = SimpleIndexer(chunker=TextChunker(), tagger=OpenTagger())
index = build_index(indexer, texts; 
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
        index_id = gensym("ChunkIndex"),
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
    tags, tags_vocab = get_tags(tagger, chunks;
        verbose = (verbose > 1),
        cost_tracker,
        api_kwargs, tagger_kwargs...)

    (verbose > 0) && @info "Index built! (cost: \$$(round(cost_tracker[], digits=3)))"

    index = ChunkIndex(; id = index_id, embeddings, tags, tags_vocab,
        chunks, sources, extras)
    return index
end
