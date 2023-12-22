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

"""
    build_index(files::Vector{<:AbstractString};
        separators = ["\n\n", ". ", "\n"], max_length::Int = 256,
        extract_metadata::Bool = false, verbose::Bool = true,
        metadata_template::Symbol = :RAGExtractMetadataShort,
        model_embedding::String = PT.MODEL_EMBEDDING,
        model_metadata::String = PT.MODEL_CHAT,
        api_kwargs::NamedTuple = NamedTuple())

Build an index for RAG (Retriever-Augmented Generation) applications from the provided file paths. 
The function processes each file, splits its content into chunks, embeds these chunks, 
optionally extracts metadata, and then compiles this information into a retrievable index.

# Arguments
- `files`: A vector of valid file paths to be indexed.
- `separators`: A list of strings used as separators for splitting the text in each file into chunks. Default is `["\n\n", ". ", "\n"]`.
- `max_length`: The maximum length of each chunk (if possible with provided separators). Default is 256.
- `extract_metadata`: A boolean flag indicating whether to extract metadata from each chunk (to build filter `tags` in the index). Default is `false`.
  Metadata extraction incurs additional cost and requires `model_metadata` and `metadata_template` to be provided.
- `verbose`: A boolean flag for verbose output. Default is `true`.
- `metadata_template`: A symbol indicating the template to be used for metadata extraction. Default is `:RAGExtractMetadataShort`.
- `model_embedding`: The model to use for embedding.
- `model_metadata`: The model to use for metadata extraction.
- `api_kwargs`: Parameters to be provided to the API endpoint.

# Returns
- `ChunkIndex`: An object containing the compiled index of chunks, embeddings, tags, vocabulary, and sources.

See also: `MultiIndex`, `CandidateChunks`, `find_closest`, `find_tags`, `rerank`, `airag`

# Examples
```julia
# Assuming `test_files` is a vector of file paths
index = build_index(test_files; max_length=10, extract_metadata=true)

# Another example with metadata extraction and verbose output
index = build_index(["file1.txt", "file2.txt"]; 
                    separators=[". "], 
                    extract_metadata=true, 
                    verbose=true)
```
"""
function build_index(files::Vector{<:AbstractString};
        separators = ["\n\n", ". ", "\n"], max_length::Int = 256,
        extract_metadata::Bool = false, verbose::Bool = true,
        metadata_template::Symbol = :RAGExtractMetadataShort,
        model_embedding::String = PT.MODEL_EMBEDDING,
        model_metadata::String = PT.MODEL_CHAT,
        api_kwargs::NamedTuple = NamedTuple())
    ##
    @assert all(isfile, files) "Some `files` don't exist (Check: $(join(filter(!isfile,files),", "))"

    output_chunks = Vector{Vector{SubString{String}}}()
    output_embeddings = Vector{Matrix{Float32}}()
    output_metadata = Vector{Vector{Vector{String}}}()
    output_sources = Vector{Vector{eltype(files)}}()
    cost_tracker = Threads.Atomic{Float64}(0.0)

    for fn in files
        verbose && @info "Processing file: $fn"
        doc_raw = read(fn, String)
        isempty(doc_raw) && continue
        # split into chunks, if you want to start simple - just do `split(text,"\n\n")`
        doc_chunks = PT.split_by_length(doc_raw, separators; max_length) .|> strip |>
                     x -> filter(!isempty, x)
        # skip if no chunks found
        isempty(doc_chunks) && continue
        push!(output_chunks, doc_chunks)
        push!(output_sources, fill(fn, length(doc_chunks)))

        # Notice that we embed all doc_chunks at once, not one by one
        # OpenAI supports embedding multiple documents to reduce the number of API calls/network latency time
        emb = aiembed(doc_chunks, _normalize; model = model_embedding, verbose, api_kwargs)
        Threads.atomic_add!(cost_tracker, PT.call_cost(emb, model_embedding)) # track costs
        push!(output_embeddings, Float32.(emb.content))

        if extract_metadata && !isempty(model_metadata)
            _check_aiextract_capability(model_metadata)
            metadata_ = asyncmap(doc_chunks) do chunk
                try
                    msg = aiextract(metadata_template;
                        return_type = MaybeMetadataItems,
                        text = chunk,
                        instructions = "None.",
                        verbose,
                        model = model_metadata, api_kwargs)
                    Threads.atomic_add!(cost_tracker, PT.call_cost(msg, model_metadata)) # track costs
                    items = metadata_extract(msg.content.items)
                catch
                    String[]
                end
            end
            push!(output_metadata, metadata_)
        end
    end
    ## Create metadata tags and associated vocabulary
    tags, tags_vocab = if !isempty(output_metadata)
        # Requires SparseArrays.jl!
        build_tags(vcat(output_metadata...)) # need to vcat to be on the "chunk-level"
    else
        tags, tags_vocab = nothing, nothing
    end
    verbose && @info "Index built! (cost: \$$(round(cost_tracker[], digits=3)))"

    index = ChunkIndex(;
        embeddings = hcat(output_embeddings...),
        tags, tags_vocab,
        chunks = vcat(output_chunks...),
        sources = vcat(output_sources...))
    return index
end
