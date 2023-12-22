# # Building a Simple Retrieval-Augmented Generation (RAG) System with RAGTools

# Note: RAGTools is still experimental and will change in the future. Ideally, they will be cleaned up and moved to a dedicated package

## Imports
using LinearAlgebra, SparseArrays
using PromptingTools
using PromptingTools.Experimental.RAGTools # Experimental! May change
using JSON3, Serialization, DataFramesMeta
using Statistics: mean
const PT = PromptingTools
const RT = PromptingTools.Experimental.RAGTools

# ## Ask questions E2E
# Let's put together a few copy&pasted text files from DataFrames.jl docs
files = [
    joinpath("examples", "data", "database_style_joins.txt"),
    joinpath("examples", "data", "what_is_dataframes.txt"),
]
index = build_index(files; extract_metadata = false)

# Ask a question
answer = airag(index; question = "I like dplyr, what is the equivalent in Julia?")
# AIMessage("The equivalent package in Julia to the dplyr package in R is DataFrames.jl.")
# The equivalent package in Julia to the dplyr package in R is DataFrames.jl.

# First RAG in two lines? Done!
#
# What does it do?
# - `build_index` will chunk the documents into smaller pieces, embed them into numbers (to be able to judge similarity of chunks) and, optionally, create a lookup index of metadata/tags for each chunk)
#   - `index` is the result of this step and it holds your chunks, embeddings, and other metadata! Just show it :)
# - `airag` will
#   - embed your question
#   - find the closest chunks in the index
#   - [OPTIONAL] extract any potential tags/filters from the question and apply them to filter down the potential candidates
#   - [OPTIONAL] rerank the candidate chunks
# - generate an answer from the closest chunks

# You should save the index for later!
serialize("examples/index.jls", index)
index = deserialize("examples/index.jls")

# # Evaluations
# However, we want to evaluate the quality of the system. For that, we need a set of questions and answers.
# Ideally, we would hand-craft a set of high quality Q&A pairs. However, this is time consuming and expensive.
# Let's generate them from the chunks in our index!

# ## Generate Q&A pairs

# We need to provide: chunks and sources (filepaths for future reference)
evals = build_qa_evals(RT.chunks(index),
    RT.sources(index);
    instructions = "None.",
    verbose = true);
## Info: Q&A Sets built! (cost: $0.143) -- not bad!

# > [!TIP]
# > In practice, you would review each item in this golden evaluation set (and delete any generic/poor questions). 
# > It will determine the future success of your app, so you need to make sure it's good!

## Save the evals for later
JSON3.write("examples/evals.json", evals)
evals = JSON3.read("examples/evals.json", Vector{RT.QAEvalItem});

# ## Explore one Q&A pair
# Let's explore one evals item -- it's not the best but gives you the idea!
evals[1]
# QAEvalItem:
#  source: markdown/DataFrames/comparison_with_python.txt
#  context: Comparisons
# This section compares DataFrames.jl with other data manipulation frameworks in Python, R, and Stata.

# A sample data set can be created using the following code:

# using DataFrames
# using Statistics
#  question: What frameworks are compared with DataFrames.jl?
#  answer: Python, R, and Stata

# ## Evaluate this Q&A pair

## Let's answer and evaluate this QA item with the judge
## Note: that we used the same question, but generated a different context and answer via `airag`
msg, ctx = airag(index; evals[1].question, return_context = true);

## ctx is a RAGContext object that keeps all intermediate states of the RAG pipeline for easy evaluation
judged = aiextract(:RAGJudgeAnswerFromContext;
    ctx.context,
    ctx.question,
    ctx.answer,
    return_type = RT.JudgeAllScores)
judged.content
## Dict{Symbol, Any} with 7 entries:
##   :final_rating => 4.8
##   :clarity      => 5
##   :completeness => 5
##   :relevance    => 5
##   :consistency  => 4
##   :helpfulness  => 5
##   :rationale    => "The answer is highly relevant to the user's question, as it provides a comprehensive list of frameworks that are compared with DataFrames.jl. The answer is complete, covering all 

# We can also run the whole evaluation in a function (a few more metrics are available):
x = run_qa_evals(evals[10], ctx;
    parameters_dict = Dict(:top_k => 3), verbose = true, model_judge = "gpt4t")

# Fortunately, we don't have to do this one by one -- let's evaluate all our Q&A pairs at once.

# ## Evaluate the whole set

# Let's run each question&answer through our eval loop in async (we do it only for the first 10)
# See the `?airag` for which parameters you can tweak, eg, top_k
results = asyncmap(evals[1:10]) do qa_item
    ## Generate an answer -- often you want the model_judge to be the highest quality possible, eg, "GPT-4 Turbo" (alias "gpt4t)
    msg, ctx = airag(index; qa_item.question, return_context = true,
        top_k = 3, verbose = false, model_judge = "gpt4t")
    ## Evaluate the response
    ## Note: you can log key parameters for easier analysis later
    run_qa_evals(qa_item, ctx; parameters_dict = Dict(:top_k => 3), verbose = false)
end
## Note that the "failed" evals can show as "nothing", so make sure to handle them.
results = filter(!isnothing, results);

## Let's take a simple average to calculate our score
@info "RAG Evals: $(length(results)) results, Avg. score: $(round(mean(x->x.answer_score, results);digits=1)), Retrieval score: $(100*round(mean(x->x.retrieval_score,results);digits=1))%"
# [ Info: RAG Evals: 10 results, Avg. score: 4.5, Retrieval score: 70.0%

# or you can analyze it in a DataFrame
df = DataFrame(results)
# 10×8 DataFrame
#  Row │ source  context   ...

# We're done for today!

# # What would we do next?
# - Review your evaluation golden data set and keep only the good items
# - Play with the chunk sizes (max_length in build_index) and see how it affects the quality
# - Explore using metadata/key filters (`extract_metadata=true` in build_index)
# - Add filtering for semantic similarity (embedding distance) to make sure we don't pick up irrelevant chunks in the context
# - Use multiple indices or a hybrid index (add a simple BM25 lookup from TextAnalysis.jl)
# - Data processing is the most important step - properly parsed and split text could make wonders
# - Add re-ranking of context (see `rerank` function, you can use Cohere ReRank API)`)
# - Improve the question embedding (eg, rephrase it, generate hypothetical answers and use them to find better context)
#
# ... and much more! See some ideas in [Anyscale RAG tutorial](https://www.anyscale.com/blog/a-comprehensive-guide-for-building-rag-based-llm-applications-part-1)
