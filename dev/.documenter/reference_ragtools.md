
# Reference for RAGTools {#Reference-for-RAGTools}
- [`PromptingTools.Experimental.RAGTools.ChunkIndex`](#PromptingTools.Experimental.RAGTools.ChunkIndex)
- [`PromptingTools.Experimental.RAGTools.JudgeAllScores`](#PromptingTools.Experimental.RAGTools.JudgeAllScores)
- [`PromptingTools.Experimental.RAGTools.JudgeRating`](#PromptingTools.Experimental.RAGTools.JudgeRating)
- [`PromptingTools.Experimental.RAGTools.MultiIndex`](#PromptingTools.Experimental.RAGTools.MultiIndex)
- [`PromptingTools.Experimental.RAGTools.RAGContext`](#PromptingTools.Experimental.RAGTools.RAGContext)
- [`PromptingTools.Experimental.RAGTools._normalize`](#PromptingTools.Experimental.RAGTools._normalize)
- [`PromptingTools.Experimental.RAGTools.airag`](#PromptingTools.Experimental.RAGTools.airag)
- [`PromptingTools.Experimental.RAGTools.build_context`](#PromptingTools.Experimental.RAGTools.build_context-Tuple{PromptingTools.Experimental.RAGTools.AbstractChunkIndex,%20CandidateChunks})
- [`PromptingTools.Experimental.RAGTools.build_index`](#PromptingTools.Experimental.RAGTools.build_index-Tuple{Vector{<:AbstractString}})
- [`PromptingTools.Experimental.RAGTools.build_index`](#PromptingTools.Experimental.RAGTools.build_index)
- [`PromptingTools.Experimental.RAGTools.build_qa_evals`](#PromptingTools.Experimental.RAGTools.build_qa_evals-Tuple{Vector{<:AbstractString},%20Vector{<:AbstractString}})
- [`PromptingTools.Experimental.RAGTools.build_tags`](#PromptingTools.Experimental.RAGTools.build_tags)
- [`PromptingTools.Experimental.RAGTools.cohere_api`](#PromptingTools.Experimental.RAGTools.cohere_api-Tuple{})
- [`PromptingTools.Experimental.RAGTools.find_closest`](#PromptingTools.Experimental.RAGTools.find_closest-Tuple{AbstractMatrix{<:Real},%20AbstractVector{<:Real}})
- [`PromptingTools.Experimental.RAGTools.get_chunks`](#PromptingTools.Experimental.RAGTools.get_chunks-Tuple{Vector{<:AbstractString}})
- [`PromptingTools.Experimental.RAGTools.get_embeddings`](#PromptingTools.Experimental.RAGTools.get_embeddings-Tuple{Vector{<:AbstractString}})
- [`PromptingTools.Experimental.RAGTools.get_metadata`](#PromptingTools.Experimental.RAGTools.get_metadata-Tuple{Vector{<:AbstractString}})
- [`PromptingTools.Experimental.RAGTools.metadata_extract`](#PromptingTools.Experimental.RAGTools.metadata_extract-Tuple{PromptingTools.Experimental.RAGTools.MetadataItem})
- [`PromptingTools.Experimental.RAGTools.rerank`](#PromptingTools.Experimental.RAGTools.rerank-Tuple{PromptingTools.Experimental.RAGTools.CohereRerank,%20PromptingTools.Experimental.RAGTools.AbstractChunkIndex,%20Any,%20Any})
- [`PromptingTools.Experimental.RAGTools.run_qa_evals`](#PromptingTools.Experimental.RAGTools.run_qa_evals-Tuple{PromptingTools.Experimental.RAGTools.QAEvalItem,%20PromptingTools.Experimental.RAGTools.RAGContext})
- [`PromptingTools.Experimental.RAGTools.run_qa_evals`](#PromptingTools.Experimental.RAGTools.run_qa_evals-Tuple{PromptingTools.Experimental.RAGTools.AbstractChunkIndex,%20AbstractVector{<:PromptingTools.Experimental.RAGTools.QAEvalItem}})
- [`PromptingTools.Experimental.RAGTools.score_retrieval_hit`](#PromptingTools.Experimental.RAGTools.score_retrieval_hit-Tuple{AbstractString,%20Vector{<:AbstractString}})
- [`PromptingTools.Experimental.RAGTools.score_retrieval_rank`](#PromptingTools.Experimental.RAGTools.score_retrieval_rank-Tuple{AbstractString,%20Vector{<:AbstractString}})

<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.RAGTools' href='#PromptingTools.Experimental.RAGTools'>#</a>&nbsp;<b><u>PromptingTools.Experimental.RAGTools</u></b> &mdash; <i>Module</i>.




```julia
RAGTools
```


Provides Retrieval-Augmented Generation (RAG) functionality.

Requires: LinearAlgebra, SparseArrays, PromptingTools for proper functionality.

This module is experimental and may change at any time. It is intended to be moved to a separate package in the future.


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/Experimental/RAGTools/RAGTools.jl#L1-L9)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.RAGTools.ChunkIndex' href='#PromptingTools.Experimental.RAGTools.ChunkIndex'>#</a>&nbsp;<b><u>PromptingTools.Experimental.RAGTools.ChunkIndex</u></b> &mdash; <i>Type</i>.




```julia
ChunkIndex
```


Main struct for storing document chunks and their embeddings. It also stores tags and sources for each chunk.

**Fields**
- `id::Symbol`: unique identifier of each index (to ensure we're using the right index with `CandidateChunks`)
  
- `chunks::Vector{<:AbstractString}`: underlying document chunks / snippets
  
- `embeddings::Union{Nothing, Matrix{<:Real}}`: for semantic search
  
- `tags::Union{Nothing, AbstractMatrix{<:Bool}}`: for exact search, filtering, etc. This is often a sparse matrix indicating which chunks have the given `tag` (see `tag_vocab` for the position lookup)
  
- `tags_vocab::Union{Nothing, Vector{<:AbstractString}}`: vocabulary for the `tags` matrix (each column in `tags` is one item in `tags_vocab` and rows are the chunks)
  
- `sources::Vector{<:AbstractString}`: sources of the chunks
  
- `extras::Union{Nothing, AbstractVector}`: additional data, eg, metadata, source code, etc.
  


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/Experimental/RAGTools/types.jl#L11-L24)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.RAGTools.JudgeAllScores' href='#PromptingTools.Experimental.RAGTools.JudgeAllScores'>#</a>&nbsp;<b><u>PromptingTools.Experimental.RAGTools.JudgeAllScores</u></b> &mdash; <i>Type</i>.




`final_rating` is the average of all scoring criteria. Explain the `final_rating` in `rationale`


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/Experimental/RAGTools/evaluation.jl#L32)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.RAGTools.JudgeRating' href='#PromptingTools.Experimental.RAGTools.JudgeRating'>#</a>&nbsp;<b><u>PromptingTools.Experimental.RAGTools.JudgeRating</u></b> &mdash; <i>Type</i>.




Provide the `final_rating` between 1-5. Provide the rationale for it.


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/Experimental/RAGTools/evaluation.jl#L26)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.RAGTools.MultiIndex' href='#PromptingTools.Experimental.RAGTools.MultiIndex'>#</a>&nbsp;<b><u>PromptingTools.Experimental.RAGTools.MultiIndex</u></b> &mdash; <i>Type</i>.




Composite index that stores multiple ChunkIndex objects and their embeddings


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/Experimental/RAGTools/types.jl#L77)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.RAGTools.RAGContext' href='#PromptingTools.Experimental.RAGTools.RAGContext'>#</a>&nbsp;<b><u>PromptingTools.Experimental.RAGTools.RAGContext</u></b> &mdash; <i>Type</i>.




```julia
RAGContext
```


A struct for debugging RAG answers. It contains the question, answer, context, and the candidate chunks at each step of the RAG pipeline.


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/Experimental/RAGTools/types.jl#L193-L197)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.RAGTools._normalize' href='#PromptingTools.Experimental.RAGTools._normalize'>#</a>&nbsp;<b><u>PromptingTools.Experimental.RAGTools._normalize</u></b> &mdash; <i>Function</i>.




Shortcut to LinearAlgebra.normalize. Provided in the package extension `RAGToolsExperimentalExt` (Requires SparseArrays and LinearAlgebra)


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/Experimental/RAGTools/preparation.jl#L37)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.RAGTools.airag' href='#PromptingTools.Experimental.RAGTools.airag'>#</a>&nbsp;<b><u>PromptingTools.Experimental.RAGTools.airag</u></b> &mdash; <i>Function</i>.




```julia
airag(index::AbstractChunkIndex, rag_template::Symbol = :RAGAnswerFromContext;
    question::AbstractString,
    top_k::Int = 100, top_n::Int = 5, minimum_similarity::AbstractFloat = -1.0,
    tag_filter::Union{Symbol, Vector{String}, Regex, Nothing} = :auto,
    rerank_strategy::RerankingStrategy = Passthrough(),
    model_embedding::String = PT.MODEL_EMBEDDING, model_chat::String = PT.MODEL_CHAT,
    model_metadata::String = PT.MODEL_CHAT,
    metadata_template::Symbol = :RAGExtractMetadataShort,
    chunks_window_margin::Tuple{Int, Int} = (1, 1),
    return_context::Bool = false, verbose::Bool = true,
    rerank_kwargs::NamedTuple = NamedTuple(),
    api_kwargs::NamedTuple = NamedTuple(),
    aiembed_kwargs::NamedTuple = NamedTuple(),
    aigenerate_kwargs::NamedTuple = NamedTuple(),
    aiextract_kwargs::NamedTuple = NamedTuple(),
    kwargs...)
```


Generates a response for a given question using a Retrieval-Augmented Generation (RAG) approach. 

The function selects relevant chunks from an `ChunkIndex`, optionally filters them based on metadata tags, reranks them, and then uses these chunks to construct a context for generating a response.

**Arguments**
- `index::AbstractChunkIndex`: The chunk index to search for relevant text.
  
- `rag_template::Symbol`: Template for the RAG model, defaults to `:RAGAnswerFromContext`.
  
- `question::AbstractString`: The question to be answered.
  
- `top_k::Int`: Number of top candidates to retrieve based on embedding similarity.
  
- `top_n::Int`: Number of candidates to return after reranking.
  
- `minimum_similarity::AbstractFloat`: Minimum similarity threshold (between -1 and 1) for filtering chunks based on embedding similarity. Defaults to -1.0.
  
- `tag_filter::Union{Symbol, Vector{String}, Regex}`: Mechanism for filtering chunks based on tags (either automatically detected, specific tags, or a regex pattern). Disabled by setting to `nothing`.
  
- `rerank_strategy::RerankingStrategy`: Strategy for reranking the retrieved chunks. Defaults to `Passthrough()`. Use `CohereRerank` for better results (requires `COHERE_API_KEY` to be set)
  
- `model_embedding::String`: Model used for embedding the question, default is `PT.MODEL_EMBEDDING`.
  
- `model_chat::String`: Model used for generating the final response, default is `PT.MODEL_CHAT`.
  
- `model_metadata::String`: Model used for extracting metadata, default is `PT.MODEL_CHAT`.
  
- `metadata_template::Symbol`: Template for the metadata extraction process from the question, defaults to: `:RAGExtractMetadataShort`
  
- `chunks_window_margin::Tuple{Int,Int}`: The window size around each chunk to consider for context building. See `?build_context` for more information.
  
- `return_context::Bool`: If `true`, returns the context used for RAG along with the response.
  
- `verbose::Bool`: If `true`, enables verbose logging.
  
- `api_kwargs`: API parameters that will be forwarded to ALL of the API calls (`aiembed`, `aigenerate`, and `aiextract`).
  
- `aiembed_kwargs`: API parameters that will be forwarded to the `aiembed` call. If you need to provide `api_kwargs` only to this function, simply add them as a keyword argument, eg, `aiembed_kwargs = (; api_kwargs = (; x=1))`.
  
- `aigenerate_kwargs`: API parameters that will be forwarded to the `aigenerate` call. If you need to provide `api_kwargs` only to this function, simply add them as a keyword argument, eg, `aigenerate_kwargs = (; api_kwargs = (; temperature=0.3))`.
  
- `aiextract_kwargs`: API parameters that will be forwarded to the `aiextract` call for the metadata extraction.
  

**Returns**
- If `return_context` is `false`, returns the generated message (`msg`).
  
- If `return_context` is `true`, returns a tuple of the generated message (`msg`) and the RAG context (`rag_context`).
  

**Notes**
- The function first finds the closest chunks to the question embedding, then optionally filters these based on tags. After that, it reranks the candidates and builds a context for the RAG model.
  
- The `tag_filter` can be used to refine the search. If set to `:auto`, it attempts to automatically determine relevant tags (if `index` has them available).
  
- The `chunks_window_margin` allows including surrounding chunks for richer context, considering they are from the same source.
  
- The function currently supports only single `ChunkIndex`. 
  

**Examples**

Using `airag` to get a response for a question:

```julia
index = build_index(...)  # create an index
question = "How to make a barplot in Makie.jl?"
msg = airag(index, :RAGAnswerFromContext; question)

# or simply
msg = airag(index; question)
```


See also `build_index`, `build_context`, `CandidateChunks`, `find_closest`, `find_tags`, `rerank`


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/Experimental/RAGTools/generation.jl#L39-L105)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.RAGTools.build_context-Tuple{PromptingTools.Experimental.RAGTools.AbstractChunkIndex, CandidateChunks}' href='#PromptingTools.Experimental.RAGTools.build_context-Tuple{PromptingTools.Experimental.RAGTools.AbstractChunkIndex, CandidateChunks}'>#</a>&nbsp;<b><u>PromptingTools.Experimental.RAGTools.build_context</u></b> &mdash; <i>Method</i>.




```julia
build_context(index::AbstractChunkIndex, reranked_candidates::CandidateChunks; chunks_window_margin::Tuple{Int, Int}) -> Vector{String}
```


Build context strings for each position in `reranked_candidates` considering a window margin around each position.

**Arguments**
- `reranked_candidates::CandidateChunks`: Candidate chunks which contain positions to extract context from.
  
- `index::ChunkIndex`: The index containing chunks and sources.
  
- `chunks_window_margin::Tuple{Int, Int}`: A tuple indicating the margin (before, after) around each position to include in the context.  Defaults to `(1,1)`, which means 1 preceding and 1 suceeding chunk will be included. With `(0,0)`, only the matching chunks will be included.
  

**Returns**
- `Vector{String}`: A vector of context strings, each corresponding to a position in `reranked_candidates`.
  

**Examples**

```julia
index = ChunkIndex(...)  # Assuming a proper index is defined
candidates = CandidateChunks(index.id, [2, 4], [0.1, 0.2])
context = build_context(index, candidates; chunks_window_margin=(0, 1)) # include only one following chunk for each matching chunk
```



[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/Experimental/RAGTools/generation.jl#L4-L24)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.RAGTools.build_index' href='#PromptingTools.Experimental.RAGTools.build_index'>#</a>&nbsp;<b><u>PromptingTools.Experimental.RAGTools.build_index</u></b> &mdash; <i>Function</i>.




Build an index for RAG (Retriever-Augmented Generation) applications. REQUIRES SparseArrays and LinearAlgebra packages to be loaded!!


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/Experimental/RAGTools/preparation.jl#L34)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.RAGTools.build_index-Tuple{Vector{<:AbstractString}}' href='#PromptingTools.Experimental.RAGTools.build_index-Tuple{Vector{<:AbstractString}}'>#</a>&nbsp;<b><u>PromptingTools.Experimental.RAGTools.build_index</u></b> &mdash; <i>Method</i>.




```julia
build_index(files_or_docs::Vector{<:AbstractString}; reader::Symbol = :files,
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
```


Build an index for RAG (Retriever-Augmented Generation) applications from the provided file paths.  The function processes each file, splits its content into chunks, embeds these chunks,  optionally extracts metadata, and then compiles this information into a retrievable index.

**Arguments**
- `files_or_docs`: A vector of valid file paths OR string documents to be indexed (chunked and embedded).
  
- `reader`: A symbol indicating the type of input, can be either `:files` or `:docs`. Default is `:files`.
  
- `separators`: A list of strings used as separators for splitting the text in each file into chunks. Default is `[\n\n, ". ", "\n"]`.
  
- `max_length`: The maximum length of each chunk (if possible with provided separators). Default is 256.
  
- `sources`: A vector of strings indicating the source of each chunk. Default is equal to `files_or_docs` (for `reader=:files`)
  
- `extras`: An optional vector of extra information to be stored with each chunk. Default is `nothing`.
  
- `extract_metadata`: A boolean flag indicating whether to extract metadata from each chunk (to build filter `tags` in the index). Default is `false`. Metadata extraction incurs additional cost and requires `model_metadata` and `metadata_template` to be provided.
  
- `verbose`: An Integer specifying the verbosity of the logs. Default is `1` (high-level logging). `0` is disabled.
  
- `metadata_template`: A symbol indicating the template to be used for metadata extraction. Default is `:RAGExtractMetadataShort`.
  
- `model_embedding`: The model to use for embedding.
  
- `model_metadata`: The model to use for metadata extraction.
  
- `api_kwargs`: Parameters to be provided to the API endpoint. Shared across all API calls.
  
- `embedding_kwargs`: Parameters to be provided to the `get_embedding` function. Useful to change the batch sizes (`target_batch_size_length`) or reduce asyncmap tasks (`ntasks`).
  
- `metadata_kwargs`: Parameters to be provided to the `get_metadata` function.
  

**Returns**
- `ChunkIndex`: An object containing the compiled index of chunks, embeddings, tags, vocabulary, and sources.
  

See also: `MultiIndex`, `CandidateChunks`, `find_closest`, `find_tags`, `rerank`, `airag`

**Examples**

```julia
# Assuming `test_files` is a vector of file paths
index = build_index(test_files; max_length=10, extract_metadata=true)

# Another example with metadata extraction and verbose output (`reader=:files` is implicit)
index = build_index(["file1.txt", "file2.txt"]; 
                    separators=[". "], 
                    extract_metadata=true, 
                    verbose=true)
```


**Notes**
- If you get errors about exceeding embedding input sizes, first check the `max_length` in your chunks.  If that does NOT resolve the issue, try changing the `embedding_kwargs`.  In particular, reducing the `target_batch_size_length` parameter (eg, 10_000) and number of tasks `ntasks=1`.  Some providers cannot handle large batch sizes (eg, Databricks).
  


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/Experimental/RAGTools/preparation.jl#L204-L263)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.RAGTools.build_qa_evals-Tuple{Vector{<:AbstractString}, Vector{<:AbstractString}}' href='#PromptingTools.Experimental.RAGTools.build_qa_evals-Tuple{Vector{<:AbstractString}, Vector{<:AbstractString}}'>#</a>&nbsp;<b><u>PromptingTools.Experimental.RAGTools.build_qa_evals</u></b> &mdash; <i>Method</i>.




```julia
build_qa_evals(doc_chunks::Vector{<:AbstractString}, sources::Vector{<:AbstractString};
               model=PT.MODEL_CHAT, instructions="None.", qa_template::Symbol=:RAGCreateQAFromContext, 
               verbose::Bool=true, api_kwargs::NamedTuple = NamedTuple(), kwargs...) -> Vector{QAEvalItem}
```


Create a collection of question and answer evaluations (`QAEvalItem`) from document chunks and sources.  This function generates Q&A pairs based on the provided document chunks, using a specified AI model and template.

**Arguments**
- `doc_chunks::Vector{<:AbstractString}`: A vector of document chunks, each representing a segment of text.
  
- `sources::Vector{<:AbstractString}`: A vector of source identifiers corresponding to each chunk in `doc_chunks` (eg, filenames or paths).
  
- `model`: The AI model used for generating Q&A pairs. Default is `PT.MODEL_CHAT`.
  
- `instructions::String`: Additional instructions or context to provide to the model generating QA sets. Defaults to "None.".
  
- `qa_template::Symbol`: A template symbol that dictates the AITemplate that will be used. It must have placeholder `context`. Default is `:CreateQAFromContext`.
  
- `api_kwargs::NamedTuple`: Parameters that will be forwarded to the API endpoint.
  
- `verbose::Bool`: If `true`, additional information like costs will be logged. Defaults to `true`.
  

**Returns**

`Vector{QAEvalItem}`: A vector of `QAEvalItem` structs, each containing a source, context, question, and answer. Invalid or empty items are filtered out.

**Notes**
- The function internally uses `aiextract` to generate Q&A pairs based on the provided `qa_template`. So you can use any kwargs that you want.
  
- Each `QAEvalItem` includes the context (document chunk), the generated question and answer, and the source.
  
- The function tracks and reports the cost of AI calls if `verbose` is enabled.
  
- Items where the question, answer, or context is empty are considered invalid and are filtered out.
  

**Examples**

Creating Q&A evaluations from a set of document chunks:

```julia
doc_chunks = ["Text from document 1", "Text from document 2"]
sources = ["source1", "source2"]
qa_evals = build_qa_evals(doc_chunks, sources)
```



[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/Experimental/RAGTools/evaluation.jl#L65-L100)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.RAGTools.build_tags' href='#PromptingTools.Experimental.RAGTools.build_tags'>#</a>&nbsp;<b><u>PromptingTools.Experimental.RAGTools.build_tags</u></b> &mdash; <i>Function</i>.




Builds a matrix of tags and a vocabulary list. REQUIRES SparseArrays and LinearAlgebra packages to be loaded!!


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/Experimental/RAGTools/preparation.jl#L30)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.RAGTools.cohere_api-Tuple{}' href='#PromptingTools.Experimental.RAGTools.cohere_api-Tuple{}'>#</a>&nbsp;<b><u>PromptingTools.Experimental.RAGTools.cohere_api</u></b> &mdash; <i>Method</i>.




```julia
cohere_api(;
api_key::AbstractString,
endpoint::String,
url::AbstractString="https://api.cohere.ai/v1",
http_kwargs::NamedTuple=NamedTuple(),
kwargs...)
```


Lightweight wrapper around the Cohere API. See https://cohere.com/docs for more details.

**Arguments**
- `api_key`: Your Cohere API key. You can get one from https://dashboard.cohere.com/welcome/register (trial access is for free).
  
- `endpoint`: The Cohere endpoint to call. 
  
- `url`: The base URL for the Cohere API. Default is `https://api.cohere.ai/v1`.
  
- `http_kwargs`: Any additional keyword arguments to pass to `HTTP.post`.
  
- `kwargs`: Any additional keyword arguments to pass to the Cohere API.
  


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/Experimental/RAGTools/api_services.jl#L1-L17)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.RAGTools.find_closest-Tuple{AbstractMatrix{<:Real}, AbstractVector{<:Real}}' href='#PromptingTools.Experimental.RAGTools.find_closest-Tuple{AbstractMatrix{<:Real}, AbstractVector{<:Real}}'>#</a>&nbsp;<b><u>PromptingTools.Experimental.RAGTools.find_closest</u></b> &mdash; <i>Method</i>.




```julia
find_closest(emb::AbstractMatrix{<:Real},
    query_emb::AbstractVector{<:Real};
    top_k::Int = 100, minimum_similarity::AbstractFloat = -1.0)
```


Finds the indices of chunks (represented by embeddings in `emb`) that are closest (cosine similarity) to query embedding (`query_emb`). 

If `minimum_similarity` is provided, only indices with similarity greater than or equal to it are returned.  Similarity can be between -1 and 1 (-1 = completely opposite, 1 = exactly the same).

Returns only `top_k` closest indices.


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/Experimental/RAGTools/retrieval.jl#L1-L12)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.RAGTools.get_chunks-Tuple{Vector{<:AbstractString}}' href='#PromptingTools.Experimental.RAGTools.get_chunks-Tuple{Vector{<:AbstractString}}'>#</a>&nbsp;<b><u>PromptingTools.Experimental.RAGTools.get_chunks</u></b> &mdash; <i>Method</i>.




```julia
get_chunks(files_or_docs::Vector{<:AbstractString}; reader::Symbol = :files,
    sources::Vector{<:AbstractString} = files_or_docs,
    verbose::Bool = true,
    separators = ["\n\n", ". ", "\n"], max_length::Int = 256)
```


Chunks the provided `files_or_docs` into chunks of maximum length `max_length` (if possible with provided `separators`).

Supports two modes of operation:
- `reader=:files`: The function opens each file in `files_or_docs` and reads its content.
  
- `reader=:docs`: The function assumes that `files_or_docs` is a vector of strings to be chunked.
  

**Arguments**
- `files_or_docs`: A vector of valid file paths OR string documents to be chunked.
  
- `reader`: A symbol indicating the type of input, can be either `:files` or `:docs`. Default is `:files`.
  
- `separators`: A list of strings used as separators for splitting the text in each file into chunks. Default is `[\n\n", ". ", "\n"]`.
  
- `max_length`: The maximum length of each chunk (if possible with provided separators). Default is 256.
  
- `sources`: A vector of strings indicating the source of each chunk. Default is equal to `files_or_docs` (for `reader=:files`)
  


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/Experimental/RAGTools/preparation.jl#L40-L59)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.RAGTools.get_embeddings-Tuple{Vector{<:AbstractString}}' href='#PromptingTools.Experimental.RAGTools.get_embeddings-Tuple{Vector{<:AbstractString}}'>#</a>&nbsp;<b><u>PromptingTools.Experimental.RAGTools.get_embeddings</u></b> &mdash; <i>Method</i>.




```julia
get_embeddings(docs::Vector{<:AbstractString};
    verbose::Bool = true,
    cost_tracker = Threads.Atomic{Float64}(0.0),
    target_batch_size_length::Int = 80_000,
    ntasks::Int = 4 * Threads.nthreads(),
    kwargs...)
```


Embeds a vector of `docs` using the provided model (kwarg `model`). 

Tries to batch embedding calls for roughly 80K characters per call (to avoid exceeding the API limit) but reduce network latency.

**Notes**
- `docs` are assumed to be already chunked to the reasonable sizes that fit within the embedding context limit.
  
- If you get errors about exceeding input sizes, first check the `max_length` in your chunks.  If that does NOT resolve the issue, try reducing the `target_batch_size_length` parameter (eg, 10_000) and number of tasks `ntasks=1`.  Some providers cannot handle large batch sizes.
  

**Arguments**
- `docs`: A vector of strings to be embedded.
  
- `verbose`: A boolean flag for verbose output. Default is `true`.
  
- `model`: The model to use for embedding. Default is `PT.MODEL_EMBEDDING`.
  
- `cost_tracker`: A `Threads.Atomic{Float64}` object to track the total cost of the API calls. Useful to pass the total cost to the parent call.
  
- `target_batch_size_length`: The target length (in characters) of each batch of document chunks sent for embedding. Default is 80_000 characters. Speeds up embedding process.
  
- `ntasks`: The number of tasks to use for asyncmap. Default is 4 * Threads.nthreads().
  


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/Experimental/RAGTools/preparation.jl#L101-L127)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.RAGTools.get_metadata-Tuple{Vector{<:AbstractString}}' href='#PromptingTools.Experimental.RAGTools.get_metadata-Tuple{Vector{<:AbstractString}}'>#</a>&nbsp;<b><u>PromptingTools.Experimental.RAGTools.get_metadata</u></b> &mdash; <i>Method</i>.




```julia
get_metadata(docs::Vector{<:AbstractString};
    verbose::Bool = true,
    cost_tracker = Threads.Atomic{Float64}(0.0),
    kwargs...)
```


Extracts metadata from a vector of `docs` using the provided model (kwarg `model`).

**Arguments**
- `docs`: A vector of strings to be embedded.
  
- `verbose`: A boolean flag for verbose output. Default is `true`.
  
- `model`: The model to use for metadata extraction. Default is `PT.MODEL_CHAT`.
  
- `metadata_template`: A template to be used for metadata extraction. Default is `:RAGExtractMetadataShort`.
  
- `cost_tracker`: A `Threads.Atomic{Float64}` object to track the total cost of the API calls. Useful to pass the total cost to the parent call.
  


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/Experimental/RAGTools/preparation.jl#L161-L176)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.RAGTools.metadata_extract-Tuple{PromptingTools.Experimental.RAGTools.MetadataItem}' href='#PromptingTools.Experimental.RAGTools.metadata_extract-Tuple{PromptingTools.Experimental.RAGTools.MetadataItem}'>#</a>&nbsp;<b><u>PromptingTools.Experimental.RAGTools.metadata_extract</u></b> &mdash; <i>Method</i>.




```julia
metadata_extract(item::MetadataItem)
metadata_extract(items::Vector{MetadataItem})
```


Extracts the metadata item into a string of the form `category:::value` (lowercased and spaces replaced with underscores).

**Example**

```julia
msg = aiextract(:RAGExtractMetadataShort; return_type=MaybeMetadataItems, text="I like package DataFrames", instructions="None.")
metadata = metadata_extract(msg.content.items)
```



[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/Experimental/RAGTools/preparation.jl#L11-L22)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.RAGTools.rerank-Tuple{PromptingTools.Experimental.RAGTools.CohereRerank, PromptingTools.Experimental.RAGTools.AbstractChunkIndex, Any, Any}' href='#PromptingTools.Experimental.RAGTools.rerank-Tuple{PromptingTools.Experimental.RAGTools.CohereRerank, PromptingTools.Experimental.RAGTools.AbstractChunkIndex, Any, Any}'>#</a>&nbsp;<b><u>PromptingTools.Experimental.RAGTools.rerank</u></b> &mdash; <i>Method</i>.




```julia
rerank(strategy::CohereRerank, index::AbstractChunkIndex, question,
    candidate_chunks;
    verbose::Bool = false,
    api_key::AbstractString = PT.COHERE_API_KEY,
    top_n::Integer = length(candidate_chunks.distances),
    model::AbstractString = "rerank-english-v2.0",
    return_documents::Bool = false,
    kwargs...)
```


Re-ranks a list of candidate chunks using the Cohere Rerank API. See https://cohere.com/rerank for more details. 

**Arguments**
- `query`: The query to be used for the search.
  
- `documents`: A vector of documents to be reranked.    The total max chunks (`length of documents * max_chunks_per_doc`) must be less than 10000. We recommend less than 1000 documents for optimal performance.
  
- `top_n`: The number of most relevant documents to return. Default is `length(documents)`.
  
- `model`: The model to use for reranking. Default is `rerank-english-v2.0`.
  
- `return_documents`: A boolean flag indicating whether to return the reranked documents in the response. Default is `false`.
  
- `max_chunks_per_doc`: The maximum number of chunks to use per document. Default is `10`.
  
- `verbose`: A boolean flag indicating whether to print verbose logging. Default is `false`.
  


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/Experimental/RAGTools/retrieval.jl#L96-L118)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.RAGTools.run_qa_evals-Tuple{PromptingTools.Experimental.RAGTools.AbstractChunkIndex, AbstractVector{<:PromptingTools.Experimental.RAGTools.QAEvalItem}}' href='#PromptingTools.Experimental.RAGTools.run_qa_evals-Tuple{PromptingTools.Experimental.RAGTools.AbstractChunkIndex, AbstractVector{<:PromptingTools.Experimental.RAGTools.QAEvalItem}}'>#</a>&nbsp;<b><u>PromptingTools.Experimental.RAGTools.run_qa_evals</u></b> &mdash; <i>Method</i>.




```julia
run_qa_evals(index::AbstractChunkIndex, qa_items::AbstractVector{<:QAEvalItem};
    api_kwargs::NamedTuple = NamedTuple(),
    airag_kwargs::NamedTuple = NamedTuple(),
    qa_evals_kwargs::NamedTuple = NamedTuple(),
    verbose::Bool = true, parameters_dict::Dict{Symbol, <:Any} = Dict{Symbol, Any}())
```


Evaluates a vector of `QAEvalItem`s and returns a vector `QAEvalResult`.  This function assesses the relevance and accuracy of the answers generated in a QA evaluation context.

See `?run_qa_evals` for more details.

**Arguments**
- `qa_items::AbstractVector{<:QAEvalItem}`: The vector of QA evaluation items containing the questions and their answers.
  
- `verbose::Bool`: If `true`, enables verbose logging. Defaults to `true`.
  
- `api_kwargs::NamedTuple`: Parameters that will be forwarded to the API calls. See `?aiextract` for details.
  
- `airag_kwargs::NamedTuple`: Parameters that will be forwarded to `airag` calls. See `?airag` for details.
  
- `qa_evals_kwargs::NamedTuple`: Parameters that will be forwarded to `run_qa_evals` calls. See `?run_qa_evals` for details.
  
- `parameters_dict::Dict{Symbol, Any}`: Track any parameters used for later evaluations. Keys must be Symbols.
  

**Returns**

`Vector{QAEvalResult}`: Vector of evaluation results that includes various scores and metadata related to the QA evaluation.

**Example**

```julia
index = "..." # Assuming a proper index is defined
qa_items = [QAEvalItem(question="What is the capital of France?", answer="Paris", context="France is a country in Europe."),
            QAEvalItem(question="What is the capital of Germany?", answer="Berlin", context="Germany is a country in Europe.")]

# Let's run a test with `top_k=5`
results = run_qa_evals(index, qa_items; airag_kwargs=(;top_k=5), parameters_dict=Dict(:top_k => 5))

# Filter out the "failed" calls
results = filter(x->!isnothing(x.answer_score), results);

# See average judge score
mean(x->x.answer_score, results)
```



[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/Experimental/RAGTools/evaluation.jl#L221-L260)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.RAGTools.run_qa_evals-Tuple{PromptingTools.Experimental.RAGTools.QAEvalItem, PromptingTools.Experimental.RAGTools.RAGContext}' href='#PromptingTools.Experimental.RAGTools.run_qa_evals-Tuple{PromptingTools.Experimental.RAGTools.QAEvalItem, PromptingTools.Experimental.RAGTools.RAGContext}'>#</a>&nbsp;<b><u>PromptingTools.Experimental.RAGTools.run_qa_evals</u></b> &mdash; <i>Method</i>.




```julia
run_qa_evals(qa_item::QAEvalItem, ctx::RAGContext; verbose::Bool = true,
             parameters_dict::Dict{Symbol, <:Any}, judge_template::Symbol = :RAGJudgeAnswerFromContext,
             model_judge::AbstractString, api_kwargs::NamedTuple = NamedTuple()) -> QAEvalResult
```


Evaluates a single `QAEvalItem` using a RAG context (`RAGContext`) and returns a `QAEvalResult` structure. This function assesses the relevance and accuracy of the answers generated in a QA evaluation context.

**Arguments**
- `qa_item::QAEvalItem`: The QA evaluation item containing the question and its answer.
  
- `ctx::RAGContext`: The context used for generating the QA pair, including the original context and the answers. Comes from `airag(...; return_context=true)`
  
- `verbose::Bool`: If `true`, enables verbose logging. Defaults to `true`.
  
- `parameters_dict::Dict{Symbol, Any}`: Track any parameters used for later evaluations. Keys must be Symbols.
  
- `judge_template::Symbol`: The template symbol for the AI model used to judge the answer. Defaults to `:RAGJudgeAnswerFromContext`.
  
- `model_judge::AbstractString`: The AI model used for judging the answer's quality.  Defaults to standard chat model, but it is advisable to use more powerful model GPT-4.
  
- `api_kwargs::NamedTuple`: Parameters that will be forwarded to the API endpoint.
  

**Returns**

`QAEvalResult`: An evaluation result that includes various scores and metadata related to the QA evaluation.

**Notes**
- The function computes a retrieval score and rank based on how well the context matches the QA context.
  
- It then uses the `judge_template` and `model_judge` to score the answer's accuracy and relevance.
  
- In case of errors during evaluation, the function logs a warning (if `verbose` is `true`) and the `answer_score` will be set to `nothing`.
  

**Examples**

Evaluating a QA pair using a specific context and model:

```julia
qa_item = QAEvalItem(question="What is the capital of France?", answer="Paris", context="France is a country in Europe.")
ctx = RAGContext(source="Wikipedia", context="France is a country in Europe.", answer="Paris")
parameters_dict = Dict("param1" => "value1", "param2" => "value2")

eval_result = run_qa_evals(qa_item, ctx, parameters_dict=parameters_dict, model_judge="MyAIJudgeModel")
```



[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/Experimental/RAGTools/evaluation.jl#L145-L181)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.RAGTools.score_retrieval_hit-Tuple{AbstractString, Vector{<:AbstractString}}' href='#PromptingTools.Experimental.RAGTools.score_retrieval_hit-Tuple{AbstractString, Vector{<:AbstractString}}'>#</a>&nbsp;<b><u>PromptingTools.Experimental.RAGTools.score_retrieval_hit</u></b> &mdash; <i>Method</i>.




Returns 1.0 if `context` overlaps or is contained within any of the `candidate_context`


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/Experimental/RAGTools/evaluation.jl#L131)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.RAGTools.score_retrieval_rank-Tuple{AbstractString, Vector{<:AbstractString}}' href='#PromptingTools.Experimental.RAGTools.score_retrieval_rank-Tuple{AbstractString, Vector{<:AbstractString}}'>#</a>&nbsp;<b><u>PromptingTools.Experimental.RAGTools.score_retrieval_rank</u></b> &mdash; <i>Method</i>.




Returns Integer rank of the position where `context` overlaps or is contained within a `candidate_context`


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/Experimental/RAGTools/evaluation.jl#L138)

</div>
<br>
