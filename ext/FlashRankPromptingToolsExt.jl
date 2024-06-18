
module FlashRankPromptingToolsExt

using PromptingTools
const PT = PromptingTools
using PromptingTools.Experimental.RAGTools
const RT = PromptingTools.Experimental.RAGTools
using FlashRank

# Define the method for reranking with it
"""
    RT.rerank(
        reranker::RT.FlashRanker, index::RT.AbstractDocumentIndex, question::AbstractString,
        candidates::RT.AbstractCandidateChunks;
        verbose::Bool = false,
        top_n::Integer = length(candidates.scores),
        unique_chunks::Bool = true,
        kwargs...)

Re-ranks a list of candidate chunks using the FlashRank.jl local models.

# Arguments
- `reranker`: FlashRanker model to use (wrapper for `FlashRank.RankerModel`)
- `index`: The index that holds the underlying chunks to be re-ranked.
- `question`: The query to be used for the search.
- `candidates`: The candidate chunks to be re-ranked.
- `top_n`: The number of most relevant documents to return. Default is `length(documents)`.
- `verbose`: A boolean flag indicating whether to print verbose logging. Default is `false`.
- `unique_chunks`: A boolean flag indicating whether to remove duplicates from the candidate chunks prior to reranking (saves compute time). Default is `true`.
    
# Example

How to use FlashRank models in your RAG pipeline:
```julia
using FlashRank

# Wrap the model to be a valid Ranker recognized by RAGTools (FlashRanker is the dedicated type)
# It will be provided to the airag/rerank function to avoid instantiating it on every call
reranker = RankerModel(:mini) |> RT.FlashRanker
# You can choose :tiny or :mini

## Apply to the pipeline configuration, eg, 
cfg = RAGConfig(; retriever = AdvancedRetriever(; reranker))

# Ask a question
question = "What are the best practices for parallel computing in Julia?"
result = airag(cfg, index; question, return_all = true)

# Review the reranking step results
result.reranked_candidates
index[result.reranked_candidates]
```
"""
function RT.rerank(
        reranker::RT.FlashRanker, index::RT.AbstractDocumentIndex, question::AbstractString,
        candidates::RT.AbstractCandidateChunks;
        verbose::Bool = false,
        top_n::Integer = length(candidates.scores),
        unique_chunks::Bool = true,
        kwargs...)
    @assert top_n>0 "top_n must be a positive integer."
    documents = index[candidates, :chunks]
    @assert !(isempty(documents)) "The candidate chunks must not be empty for Cohere Reranker! Check the index IDs."

    is_multi_cand = candidates isa RT.MultiCandidateChunks
    index_ids = is_multi_cand ? candidates.index_ids : candidates.index_id
    positions = candidates.positions
    ## Find unique only items
    if unique_chunks
        verbose && @info "Removing duplicates from candidate chunks prior to reranking"
        unique_idxs = PT.unique_permutation(documents)
        documents = documents[unique_idxs]
        positions = positions[unique_idxs]
        index_ids = is_multi_cand ? index_ids[unique_idxs] : index_ids
    end

    ## Run re-ranker
    ranker = reranker.model
    result = ranker(question, documents; top_n)

    ## Unwrap re-ranked positions
    scores = result.scores
    positions = positions[result.positions]

    verbose && @info "Reranking done in $(round(result.elapsed; digits=1)) seconds."

    return is_multi_cand ?
           RT.MultiCandidateChunks(index_ids[result.positions], positions, scores) :
           RT.CandidateChunks(index_ids, positions, scores)
end

end #end of module