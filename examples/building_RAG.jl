# # Building a Simple Retrieval-Augmented Generation (RAG) System with RAGTools

# Let's build a Retrieval-Augmented Generation (RAG) chatbot, tailored to navigate and interact with the DataFrames.jl documentation. 
# "RAG" is probably the most common and valuable pattern in Generative AI at the moment.

# If you're not familiar with "RAG", start with this [article](https://towardsdatascience.com/add-your-own-data-to-an-llm-using-retrieval-augmented-generation-rag-b1958bf56a5a).

## Imports
using PromptingTools
## Note: RAGTools has been moved to a dedicated package RAGTools.jl
using RAGTools
using JSON3, Serialization, DataFramesMeta
using Statistics: mean
const PT = PromptingTools
const RT = RAGTools

# ## RAG in Two Lines

# Let's put together a few text pages from DataFrames.jl docs. 
# Simply go to [DataFrames.jl docs](https://dataframes.juliadata.org/stable/) and copy&paste a few pages into separate text files. Save them in the `examples/data` folder (see some example pages provided). Ideally, delete all the noise (like headers, footers, etc.) and keep only the text you want to use for the chatbot. Remember, garbage in, garbage out!

files = [
    joinpath("examples", "data", "database_style_joins.txt"),
    joinpath("examples", "data", "what_is_dataframes.txt")
]
## Build an index of chunks and embed them
index = build_index(files)

# Let's ask a question
## Embeds the question, finds the closest chunks in the index, and generates an answer from the closest chunks
answer = airag(index; question = "I like dplyr, what is the equivalent in Julia?")

# First RAG in two lines? Done!
#
# What does it do?
# - `build_index` will chunk the documents into smaller pieces, embed them into numbers (to be able to judge the similarity of chunks) and, optionally, create a lookup index of metadata/tags for each chunk)
#   - `index` is the result of this step and it holds your chunks, embeddings, and other metadata! Just show it :)
# - `airag` will
#   - retrieve the best chunks from your index (based on the similarity of the question to the chunks)
#     - rephrase the question into a more "searchable" form
#     - embed your question
#     - find the closest chunks in the index (use parameters `top_k` and `minimum_similarity` to tweak the "relevant" chunks)
#     - [OPTIONAL] extract any potential tags/filters from the question and applies them to filter down the potential candidates (use `extract_metadata=true` in `build_index`, you can also provide some filters explicitly via `tag_filter`)
#     - [OPTIONAL] re-rank the candidate chunks (define and provide your own `rerank_strategy`, eg Cohere ReRank API)
#   - generate an answer from the closest chunks (use `return_all=true` to see under the hood and debug your application)
#     - build a context from the closest chunks (use `chunks_window_margin` to tweak if we include preceding and succeeding chunks as well, see `?build_context` for more details)
#     - answer the question with LLM
#     - [OPTIONAL] refine the answer (with the same or new context)
#    

# You should save the index for later to avoid re-embedding / re-extracting the document chunks!
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
#
evals[1]

# ## Evaluate this Q&A pair

# Let's evaluate this QA item with a "judge model" (often GPT-4 is used as a judge).

## Note: that we used the same question, but generated a different context and answer via `airag`
result = airag(index; evals[1].question, return_all = true);

## ctx is a RAGContext object that keeps all intermediate states of the RAG pipeline for easy evaluation
judged = aiextract(:RAGJudgeAnswerFromContext;
    result.context,
    result.question,
    result.final_answer,
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

# Let's run each question & answer through our eval loop in async (we do it only for the first 10 to save time). See the `?airag` for which parameters you can tweak, eg, `top_k`

results = asyncmap(evals[1:10]) do qa_item
    ## Generate an answer -- often you want the model_judge to be the highest quality possible, eg, "GPT-4 Turbo" (alias "gpt4t)
    result = airag(index; qa_item.question, return_all = true,
        top_k = 3, verbose = false, model_judge = "gpt4t")
    ## Evaluate the response
    ## Note: you can log key parameters for easier analysis later
    run_qa_evals(qa_item, result; parameters_dict = Dict(:top_k => 3), verbose = false)
end
## Note that the "failed" evals can show as "nothing", so make sure to handle them.
results = filter(x -> !isnothing(x.answer_score), results);

# Note: You could also use the vectorized version `results = run_qa_evals(evals)` to evaluate all items at once.

## Let's take a simple average to calculate our score
@info "RAG Evals: $(length(results)) results, Avg. score: $(round(mean(x->x.answer_score, results);digits=1)), Retrieval score: $(100*round(Int,mean(x->x.retrieval_score,results)))%"
## [ Info: RAG Evals: 10 results, Avg. score: 4.6, Retrieval score: 100%

# Note: The retrieval score is 100% only because we have two small documents and running on 10 items only. In practice, you would have a much larger document set and a much larger eval set, which would result in a more representative retrieval score.

# You can also analyze the results in a DataFrame:

df = DataFrame(results)
first(df, 5)

# We're done for today!

# # What would we do next?
# - Review your evaluation golden data set and keep only the good items
# - Play with the chunk sizes (max_length in `build_index.chunker`) and see how it affects the quality
# - Explore using metadata/key filters (`tagger` step in `build_index`)
# - Add filtering for semantic similarity (embedding distance) to make sure we don't pick up irrelevant chunks in the context
# - Use multiple indices or a hybrid index (add a simple BM25 lookup from TextAnalysis.jl)
# - Data processing is the most important step - properly parsed and split text could make wonders
# - Add re-ranking of context (see `rerank` function, you can use Cohere ReRank API)
# - Improve the question embedding (eg, rephrase it, generate hypothetical answers and use them to find better context)
#
# ... and much more! See some ideas in [Anyscale RAG tutorial](https://www.anyscale.com/blog/a-comprehensive-guide-for-building-rag-based-llm-applications-part-1)
