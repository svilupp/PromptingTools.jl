### Preparation
# Types used to extract `tags` from document chunks
@kwdef struct MetadataItem
    value::String
    category::String
end
@kwdef struct MaybeMetadataItems
    items::Union{Nothing, Vector{MetadataItem}}
end

"""
    metadata_extract(item::MetadataItem)
    metadata_extract(items::Vector{MetadataItem})

Extracts the metadata item into a string of the form `category:::value` (lowercased and spaces replaced with underscores).

# Example
```julia
msg = aiextract(:RAGExtractMetadataShort; return_type=MaybeMetadataItems, text="I like package DataFrames", instructions="None.")
metadata = metadata_extract(msg.content.items)
```
"""
function metadata_extract(item::MetadataItem)
    "$(strip(item.category)):::$(strip(item.value))" |> lowercase |>
    x -> replace(x, " " => "_")
end
metadata_extract(items::Nothing) = String[]
metadata_extract(items::Vector{MetadataItem}) = metadata_extract.(items)

"Builds a matrix of tags and a vocabulary list. REQUIRES SparseArrays and LinearAlgebra packages to be loaded!!"
function build_tags end
# Implementation in ext/RAGToolsExperimentalExt.jl

"Build an index for RAG (Retriever-Augmented Generation) applications. REQUIRES SparseArrays and LinearAlgebra packages to be loaded!!"
function build_index end

"Shortcut to LinearAlgebra.normalize. Provided in the package extension `RAGToolsExperimentalExt` (Requires SparseArrays and LinearAlgebra)"
function _normalize end

"""
    get_chunks(files_or_docs::Vector{<:AbstractString}; reader::Symbol = :files,
        sources::Vector{<:AbstractString} = files_or_docs,
        verbose::Bool = true,
        separators = ["\\n\\n", ". ", "\\n"], max_length::Int = 256)

Chunks the provided `files_or_docs` into chunks of maximum length `max_length` (if possible with provided `separators`).

Supports two modes of operation:
- `reader=:files`: The function opens each file in `files_or_docs` and reads its content.
- `reader=:docs`: The function assumes that `files_or_docs` is a vector of strings to be chunked.

# Arguments
- `files_or_docs`: A vector of valid file paths OR string documents to be chunked.
- `reader`: A symbol indicating the type of input, can be either `:files` or `:docs`. Default is `:files`.
- `separators`: A list of strings used as separators for splitting the text in each file into chunks. Default is `[\\n\\n", ". ", "\\n"]`.
- `max_length`: The maximum length of each chunk (if possible with provided separators). Default is 256.
- `sources`: A vector of strings indicating the source of each chunk. Default is equal to `files_or_docs` (for `reader=:files`)

"""
function get_chunks(files_or_docs::Vector{<:AbstractString}; reader::Symbol = :files,
        sources::Vector{<:AbstractString} = files_or_docs,
        verbose::Bool = true,
        separators = ["\n\n", ". ", "\n"], max_length::Int = 256)

    ## Check that all items must be existing files or strings
    @assert reader in [:files, :docs] "Invalid `read` argument. Must be one of [:files, :docs]"
    if reader == :files
        @assert all(isfile, files_or_docs) "Some paths in `files_or_docs` don't exist (Check: $(join(filter(!isfile,files_or_docs),", "))"
    else
        @assert sources!=files_or_docs "When `reader=:docs`, vector of `sources` must be provided"
    end
    @assert isnothing(sources)||(length(sources) == length(files_or_docs)) "Length of `sources` must match length of `files_or_docs`"
    @assert maximum(length.(sources))<=512 "Each source must be less than 512 characters long (Detected: $(maximum(length.(sources))))"

    output_chunks = Vector{SubString{String}}()
    output_sources = Vector{eltype(sources)}()

    # Do chunking first
    for i in eachindex(files_or_docs, sources)
        # if reader == :files, we open the files and read them
        doc_raw = if reader == :files
            fn = files_or_docs[i]
            (verbose > 0) && @info "Processing file: $fn"
            read(fn, String)
        else
            files_or_docs[i]
        end
        isempty(doc_raw) && continue
        # split into chunks, if you want to start simple - just do `split(text,"\n\n")`
        doc_chunks = PT.recursive_splitter(doc_raw, separators; max_length) .|> strip |>
                     x -> filter(!isempty, x)
        # skip if no chunks found
        isempty(doc_chunks) && continue
        append!(output_chunks, doc_chunks)
        append!(output_sources, fill(sources[i], length(doc_chunks)))
    end

    return output_chunks, output_sources
end

"""
    get_embeddings(docs::Vector{<:AbstractString};
        verbose::Bool = true,
        cost_tracker = Threads.Atomic{Float64}(0.0),
        target_batch_size_length::Int = 80_000,
        ntasks::Int = 4 * Threads.nthreads(),
        kwargs...)

Embeds a vector of `docs` using the provided model (kwarg `model`). 

Tries to batch embedding calls for roughly 80K characters per call (to avoid exceeding the API limit) but reduce network latency.

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
function get_embeddings(docs::Vector{<:AbstractString};
        verbose::Bool = true,
        cost_tracker = Threads.Atomic{Float64}(0.0),
        target_batch_size_length::Int = 80_000,
        ntasks::Int = 4 * Threads.nthreads(),
        kwargs...)
    ## check if extension is available
    ext = Base.get_extension(PromptingTools, :RAGToolsExperimentalExt)
    if isnothing(ext)
        error("you need to also import LinearAlgebra and SparseArrays to use this function")
    end
    verbose && @info "Embedding $(length(docs)) documents..."
    model = hasproperty(kwargs, :model) ? kwargs.model : PT.MODEL_EMBEDDING
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
            verbose = false,
            kwargs...)
        Threads.atomic_add!(cost_tracker, PT.call_cost(msg, model)) # track costs
        msg.content
    end
    embeddings = hcat(embeddings...) .|> Float32 # flatten, columns are documents
    verbose && @info "Done embedding. Total cost: \$$(round(cost_tracker[],digits=3))"
    return embeddings
end

"""
    get_metadata(docs::Vector{<:AbstractString};
        verbose::Bool = true,
        cost_tracker = Threads.Atomic{Float64}(0.0),
        kwargs...)

Extracts metadata from a vector of `docs` using the provided model (kwarg `model`).

# Arguments
- `docs`: A vector of strings to be embedded.
- `verbose`: A boolean flag for verbose output. Default is `true`.
- `model`: The model to use for metadata extraction. Default is `PT.MODEL_CHAT`.
- `metadata_template`: A template to be used for metadata extraction. Default is `:RAGExtractMetadataShort`.
- `cost_tracker`: A `Threads.Atomic{Float64}` object to track the total cost of the API calls. Useful to pass the total cost to the parent call.

"""
function get_metadata(docs::Vector{<:AbstractString};
        verbose::Bool = true,
        metadata_template::Symbol = :RAGExtractMetadataShort,
        cost_tracker = Threads.Atomic{Float64}(0.0),
        kwargs...)
    model = hasproperty(kwargs, :model) ? kwargs.model : PT.MODEL_CHAT
    _check_aiextract_capability(model)
    verbose && @info "Extracting metadata from $(length(docs)) documents..."
    metadata = asyncmap(docs) do docs_chunk
        try
            msg = aiextract(metadata_template;
                return_type = MaybeMetadataItems,
                text = docs_chunk,
                instructions = "None.",
                verbose = false,
                model, kwargs...)
            Threads.atomic_add!(cost_tracker, PT.call_cost(msg, model)) # track costs
            items = metadata_extract(msg.content.items)
        catch
            String[]
        end
    end
    verbose &&
        @info "Done extracting the metadata. Total cost: \$$(round(cost_tracker[],digits=3))"
    return metadata
end

"""
    build_index(files_or_docs::Vector{<:AbstractString}; reader::Symbol = :files,
        separators = ["\\n\\n", ". ", "\\n"], max_length::Int = 256,
        sources::Vector{<:AbstractString} = files_or_docs,
        extras::Union{Nothing, AbstractVector} = nothing,
        extract_metadata::Bool = false, verbose::Integer = 1,
        index_id = gensym("ChunkIndex"),
        metadata_template::Symbol = :RAGExtractMetadataShort,
        model_embedding::String = PT.MODEL_EMBEDDING,
        model_metadata::String = PT.MODEL_CHAT,
        embedding_kwargs::NamedTuple = NamedTuple(),
        metadata_kwargs::NamedTuple = NamedTuple(),
        api_kwargs::NamedTuple = NamedTuple(),
        cost_tracker = Threads.Atomic{Float64}(0.0))

Build an index for RAG (Retriever-Augmented Generation) applications from the provided file paths. 
The function processes each file, splits its content into chunks, embeds these chunks, 
optionally extracts metadata, and then compiles this information into a retrievable index.

# Arguments
- `files_or_docs`: A vector of valid file paths OR string documents to be indexed (chunked and embedded).
- `reader`: A symbol indicating the type of input, can be either `:files` or `:docs`. Default is `:files`.
- `separators`: A list of strings used as separators for splitting the text in each file into chunks. Default is `[\\n\\n, ". ", "\\n"]`.
- `max_length`: The maximum length of each chunk (if possible with provided separators). Default is 256.
- `sources`: A vector of strings indicating the source of each chunk. Default is equal to `files_or_docs` (for `reader=:files`)
- `extras`: An optional vector of extra information to be stored with each chunk. Default is `nothing`.
- `extract_metadata`: A boolean flag indicating whether to extract metadata from each chunk (to build filter `tags` in the index). Default is `false`.
  Metadata extraction incurs additional cost and requires `model_metadata` and `metadata_template` to be provided.
- `verbose`: An Integer specifying the verbosity of the logs. Default is `1` (high-level logging). `0` is disabled.
- `metadata_template`: A symbol indicating the template to be used for metadata extraction. Default is `:RAGExtractMetadataShort`.
- `model_embedding`: The model to use for embedding.
- `model_metadata`: The model to use for metadata extraction.
- `api_kwargs`: Parameters to be provided to the API endpoint. Shared across all API calls.
- `embedding_kwargs`: Parameters to be provided to the `get_embedding` function. Useful to change the batch sizes (`target_batch_size_length`) or reduce asyncmap tasks (`ntasks`).
- `metadata_kwargs`: Parameters to be provided to the `get_metadata` function.

# Returns
- `ChunkIndex`: An object containing the compiled index of chunks, embeddings, tags, vocabulary, and sources.

See also: `MultiIndex`, `CandidateChunks`, `find_closest`, `find_tags`, `rerank`, `airag`

# Examples
```julia
# Assuming `test_files` is a vector of file paths
index = build_index(test_files; max_length=10, extract_metadata=true)

# Another example with metadata extraction and verbose output (`reader=:files` is implicit)
index = build_index(["file1.txt", "file2.txt"]; 
                    separators=[". "], 
                    extract_metadata=true, 
                    verbose=true)
```

# Notes
- If you get errors about exceeding embedding input sizes, first check the `max_length` in your chunks. 
  If that does NOT resolve the issue, try changing the `embedding_kwargs`. 
  In particular, reducing the `target_batch_size_length` parameter (eg, 10_000) and number of tasks `ntasks=1`. 
  Some providers cannot handle large batch sizes (eg, Databricks).

"""
function build_index(files_or_docs::Vector{<:AbstractString}; reader::Symbol = :files,
        separators = ["\n\n", ". ", "\n"], max_length::Int = 256,
        sources::Vector{<:AbstractString} = files_or_docs,
        extras::Union{Nothing, AbstractVector} = nothing,
        extract_metadata::Bool = false, verbose::Integer = 1,
        index_id = gensym("ChunkIndex"),
        metadata_template::Symbol = :RAGExtractMetadataShort,
        model_embedding::String = PT.MODEL_EMBEDDING,
        model_metadata::String = PT.MODEL_CHAT,
        embedding_kwargs::NamedTuple = NamedTuple(),
        metadata_kwargs::NamedTuple = NamedTuple(),
        api_kwargs::NamedTuple = NamedTuple(),
        cost_tracker = Threads.Atomic{Float64}(0.0))

    ## Split into chunks
    output_chunks, output_sources = get_chunks(files_or_docs;
        reader, sources, separators, max_length)

    ## Embed chunks
    embeddings = get_embeddings(output_chunks;
        verbose = (verbose > 1),
        cost_tracker,
        model = model_embedding,
        api_kwargs, embedding_kwargs...)

    ## Extract metadata
    tags, tags_vocab = if extract_metadata
        output_metadata = get_metadata(output_chunks;
            verbose = (verbose > 1),
            cost_tracker,
            model = model_metadata,
            metadata_template,
            api_kwargs, metadata_kwargs...)
        # Requires SparseArrays.jl to be loaded
        build_tags(output_metadata)
    else
        nothing, nothing
    end
    ## Create metadata tag array and associated vocabulary
    (verbose > 0) && @info "Index built! (cost: \$$(round(cost_tracker[], digits=3)))"

    index = ChunkIndex(;
        id = index_id,
        embeddings,
        tags, tags_vocab,
        chunks = output_chunks,
        sources = output_sources,
        extras)
    return index
end
