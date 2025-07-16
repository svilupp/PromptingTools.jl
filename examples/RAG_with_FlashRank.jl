# # RAG with FlashRank.jl

# This file contains examples of how to use FlashRank rankers.
#
# First, let's import the package and define a helper link for calling un-exported functions:
using FlashRank
using PromptingTools
const PT = PromptingTools
# Note: RAGTools has been moved to a dedicated package RAGTools.jl
using RAGTools
const RT = RAGTools

# Enable model downloading, otherwise you always have to approve it
# see https://www.oxinabox.net/DataDeps.jl/dev/z10-for-end-users/
ENV["DATADEPS_ALWAYS_ACCEPT"] = true

## Sample data
sentences = [
    "Search for the latest advancements in quantum computing using Julia language.",
    "How to implement machine learning algorithms in Julia with examples.",
    "Looking for performance comparison between Julia, Python, and R for data analysis.",
    "Find Julia language tutorials focusing on high-performance scientific computing.",
    "Search for the top Julia language packages for data visualization and their documentation.",
    "How to set up a Julia development environment on Windows 10.",
    "Discover the best practices for parallel computing in Julia.",
    "Search for case studies of large-scale data processing using Julia.",
    "Find comprehensive resources for mastering metaprogramming in Julia.",
    "Looking for articles on the advantages of using Julia for statistical modeling.",
    "How to contribute to the Julia open-source community: A step-by-step guide.",
    "Find the comparison of numerical accuracy between Julia and MATLAB.",
    "Looking for the latest Julia language updates and their impact on AI research.",
    "How to efficiently handle big data with Julia: Techniques and libraries.",
    "Discover how Julia integrates with other programming languages and tools.",
    "Search for Julia-based frameworks for developing web applications.",
    "Find tutorials on creating interactive dashboards with Julia.",
    "How to use Julia for natural language processing and text analysis.",
    "Discover the role of Julia in the future of computational finance and econometrics."
]
## Build the index
index = build_index(
    sentences; chunker_kwargs = (; sources = map(i -> "Doc$i", 1:length(sentences))))

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
