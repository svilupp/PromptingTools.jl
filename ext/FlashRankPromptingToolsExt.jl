
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
        kwargs...)

Re-ranks a list of candidate chunks using the FlashRank.jl local models.

# Arguments
- `reranker`: FlashRanker model to use (wrapper for `FlashRank.RankerModel`)
- `index`: The index that holds the underlying chunks to be re-ranked.
- `question`: The query to be used for the search.
- `candidates`: The candidate chunks to be re-ranked.
- `top_n`: The number of most relevant documents to return. Default is `length(documents)`.
- `verbose`: A boolean flag indicating whether to print verbose logging. Default is `false`.
    
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
        kwargs...)
    @assert top_n>0 "top_n must be a positive integer."
    documents = index[candidates, :chunks]
    @assert !(isempty(documents)) "The candidate chunks must not be empty for Cohere Reranker! Check the index IDs."

    ## Run re-ranker
    ranker = reranker.model
    result = ranker(question, documents; top_n)

    ## Unwrap re-ranked positions
    scores = result.scores
    positions = candidates.positions[result.positions]
    index_ids = if candidates isa RT.MultiCandidateChunks
        candidates.index_ids[result.positions]
    else
        candidates.index_id
    end

    verbose && @info "Reranking done in $(round(res.elapsed; digits=1)) seconds."

    return candidates isa RT.MultiCandidateChunks ?
           RT.MultiCandidateChunks(index_ids, positions, scores) :
           RT.CandidateChunks(index_ids, positions, scores)
end

end #end of module