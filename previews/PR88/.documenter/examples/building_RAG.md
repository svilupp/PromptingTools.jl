


# Building a Simple Retrieval-Augmented Generation (RAG) System with RAGTools {#Building-a-Simple-Retrieval-Augmented-Generation-(RAG)-System-with-RAGTools}

Let's build a Retrieval-Augmented Generation (RAG) chatbot, tailored to navigate and interact with the DataFrames.jl documentation.  "RAG" is probably the most common and valuable pattern in Generative AI at the moment.

If you're not familiar with "RAG", start with this [article](https://towardsdatascience.com/add-your-own-data-to-an-llm-using-retrieval-augmented-generation-rag-b1958bf56a5a).

```julia
using LinearAlgebra, SparseArrays
using PromptingTools
using PromptingTools.Experimental.RAGTools
## Note: RAGTools module is still experimental and will change in the future. Ideally, they will be cleaned up and moved to a dedicated package
using JSON3, Serialization, DataFramesMeta
using Statistics: mean
const PT = PromptingTools
const RT = PromptingTools.Experimental.RAGTools
```


## RAG in Two Lines {#RAG-in-Two-Lines}

Let's put together a few text pages from DataFrames.jl docs.  Simply go to [DataFrames.jl docs](https://dataframes.juliadata.org/stable/) and copy&paste a few pages into separate text files. Save them in the `examples/data` folder (see some example pages provided). Ideally, delete all the noise (like headers, footers, etc.) and keep only the text you want to use for the chatbot. Remember, garbage in, garbage out!

```julia
files = [
    joinpath("examples", "data", "database_style_joins.txt"),
    joinpath("examples", "data", "what_is_dataframes.txt"),
]
# Build an index of chunks, embed them, and create a lookup index of metadata/tags for each chunk
index = build_index(files; extract_metadata = false);
```


Let's ask a question

```julia
# Embeds the question, finds the closest chunks in the index, and generates an answer from the closest chunks
answer = airag(index; question = "I like dplyr, what is the equivalent in Julia?")
```


```
AIMessage("The equivalent package in Julia to dplyr in R is DataFramesMeta.jl. It provides convenience functions for data manipulation with syntax similar to dplyr.")
```


First RAG in two lines? Done!

What does it do?
- `build_index` will chunk the documents into smaller pieces, embed them into numbers (to be able to judge the similarity of chunks) and, optionally, create a lookup index of metadata/tags for each chunk)
  - `index` is the result of this step and it holds your chunks, embeddings, and other metadata! Just show it :)
    
  
- `airag` will
  - embed your question
    
  - find the closest chunks in the index (use parameters `top_k` and `minimum_similarity` to tweak the "relevant" chunks)
    
  - [OPTIONAL] extracts any potential tags/filters from the question and applies them to filter down the potential candidates (use `extract_metadata=true` in `build_index`, you can also provide some filters explicitly via `tag_filter`)
    
  - [OPTIONAL] re-ranks the candidate chunks (define and provide your own `rerank_strategy`, eg Cohere ReRank API)
    
  - build a context from the closest chunks (use `chunks_window_margin` to tweak if we include preceding and succeeding chunks as well, see `?build_context` for more details)
    
  
- generate an answer from the closest chunks (use `return_context=true` to see under the hood and debug your application)
  

You should save the index for later to avoid re-embedding / re-extracting the document chunks!

```julia
serialize("examples/index.jls", index)
index = deserialize("examples/index.jls");
```


# Evaluations {#Evaluations}

However, we want to evaluate the quality of the system. For that, we need a set of questions and answers. Ideally, we would handcraft a set of high-quality Q&A pairs. However, this is time-consuming and expensive. Let's generate them from the chunks in our index!

## Generate Q&A pairs {#Generate-Q-and-A-pairs}

We need to provide: chunks and sources (file paths for future reference)

```julia
evals = build_qa_evals(RT.chunks(index),
    RT.sources(index);
    instructions = "None.",
    verbose = true);
```


```
[ Info: Q&A Sets built! (cost: $0.102)

```

> 
> [!TIP] In practice, you would review each item in this golden evaluation set (and delete any generic/poor questions). It will determine the future success of your app, so you need to make sure it's good!
> 

```julia
# Save the evals for later
JSON3.write("examples/evals.json", evals)
evals = JSON3.read("examples/evals.json", Vector{RT.QAEvalItem});
```


## Explore one Q&A pair {#Explore-one-Q-and-A-pair}

Let's explore one evals item – it's not the best quality but gives you the idea!

```julia
evals[1]
```


```
QAEvalItem:
 source: examples/data/database_style_joins.txt
 context: Database-Style Joins
Introduction to joins
We often need to combine two or more data sets together to provide a complete picture of the topic we are studying. For example, suppose that we have the following two data sets:

julia> using DataFrames
 question: What is the purpose of joining two or more data sets together?
 answer: The purpose of joining two or more data sets together is to provide a complete picture of the topic being studied.

```


## Evaluate this Q&A pair {#Evaluate-this-Q-and-A-pair}

Let's evaluate this QA item with a "judge model" (often GPT-4 is used as a judge).

```julia
# Note: that we used the same question, but generated a different context and answer via `airag`
msg, ctx = airag(index; evals[1].question, return_context = true);
# ctx is a RAGContext object that keeps all intermediate states of the RAG pipeline for easy evaluation
judged = aiextract(:RAGJudgeAnswerFromContext;
    ctx.context,
    ctx.question,
    ctx.answer,
    return_type = RT.JudgeAllScores)
judged.content
```


```
Dict{Symbol, Any} with 6 entries:
  :final_rating => 4.8
  :clarity => 5
  :completeness => 4
  :relevance => 5
  :consistency => 5
  :helpfulness => 5
```


We can also run the generation + evaluation in a function (a few more metrics are available, eg, retrieval score):

```julia
x = run_qa_evals(evals[10], ctx;
    parameters_dict = Dict(:top_k => 3), verbose = true, model_judge = "gpt4t")
```


```
QAEvalResult:
 source: examples/data/database_style_joins.txt
 context: outerjoin: the output contains rows for values of the key that exist in any of the passed data frames.
semijoin: Like an inner join, but output is restricted to columns from the first (left) argument.
 question: What is the difference between outer join and semi join?
 answer: The purpose of joining two or more data sets together is to combine them in order to provide a complete picture or analysis of a specific topic or dataset. By joining data sets, we can combine information from multiple sources to gain more insights and make more informed decisions.
 retrieval_score: 0.0
 retrieval_rank: nothing
 answer_score: 5
 parameters: Dict(:top_k => 3)

```


Fortunately, we don't have to do this one by one – let's evaluate all our Q&A pairs at once.

## Evaluate the Whole Set {#Evaluate-the-Whole-Set}

Let's run each question & answer through our eval loop in async (we do it only for the first 10 to save time). See the `?airag` for which parameters you can tweak, eg, `top_k`

```julia
results = asyncmap(evals[1:10]) do qa_item
    # Generate an answer -- often you want the model_judge to be the highest quality possible, eg, "GPT-4 Turbo" (alias "gpt4t)
    msg, ctx = airag(index; qa_item.question, return_context = true,
        top_k = 3, verbose = false, model_judge = "gpt4t")
    # Evaluate the response
    # Note: you can log key parameters for easier analysis later
    run_qa_evals(qa_item, ctx; parameters_dict = Dict(:top_k => 3), verbose = false)
end
## Note that the "failed" evals can show as "nothing" (failed as in there was some API error or parsing error), so make sure to handle them.
results = filter(x->!isnothing(x.answer_score), results);
```


Note: You could also use the vectorized version `results = run_qa_evals(evals)` to evaluate all items at once.

```julia

# Let's take a simple average to calculate our score
@info "RAG Evals: $(length(results)) results, Avg. score: $(round(mean(x->x.answer_score, results);digits=1)), Retrieval score: $(100*round(Int,mean(x->x.retrieval_score,results)))%"
```


```
[ Info: RAG Evals: 10 results, Avg. score: 4.6, Retrieval score: 100%

```


Note: The retrieval score is 100% only because we have two small documents and running on 10 items only. In practice, you would have a much larger document set and a much larger eval set, which would result in a more representative retrieval score.

You can also analyze the results in a DataFrame:

```julia
df = DataFrame(results)
```

<div><div style = "float: left;"><span>10×8 DataFrame</span></div><div style = "clear: both;"></div></div><div class = "data-frame" style = "overflow-x: scroll;"><table class = "data-frame" style = "margin-bottom: 6px;"><thead><tr class = "header"><th class = "rowNumber" style = "font-weight: bold; text-align: right;">Row</th><th style = "text-align: left;">source</th><th style = "text-align: left;">context</th><th style = "text-align: left;">question</th><th style = "text-align: left;">answer</th><th style = "text-align: left;">retrieval_score</th><th style = "text-align: left;">retrieval_rank</th><th style = "text-align: left;">answer_score</th><th style = "text-align: left;">parameters</th></tr><tr class = "subheader headerLastRow"><th class = "rowNumber" style = "font-weight: bold; text-align: right;"></th><th title = "String" style = "text-align: left;">String</th><th title = "String" style = "text-align: left;">String</th><th title = "String" style = "text-align: left;">String</th><th title = "SubString{String}" style = "text-align: left;">SubStrin…</th><th title = "Float64" style = "text-align: left;">Float64</th><th title = "Int64" style = "text-align: left;">Int64</th><th title = "Float64" style = "text-align: left;">Float64</th><th title = "Dict{Symbol, Int64}" style = "text-align: left;">Dict…</th></tr></thead><tbody><tr><td class = "rowNumber" style = "font-weight: bold; text-align: right;">1</td><td style = "text-align: left;">examples/data/database_style_joins.txt</td><td style = "text-align: left;">Database-Style Joins\nIntroduction to joins\nWe often need to combine two or more data sets together to provide a complete picture of the topic we are studying. For example, suppose that we have the following two data sets:\n\njulia&gt; using DataFrames</td><td style = "text-align: left;">What is the purpose of joining two or more data sets together?</td><td style = "text-align: left;">The purpose of joining two or more data sets together is to combine the data sets based on a common key and provide a complete picture of the topic being studied.</td><td style = "text-align: right;">1.0</td><td style = "text-align: right;">1</td><td style = "text-align: right;">5.0</td><td style = "text-align: left;">Dict(:top_k=&gt;3)</td></tr><tr><td class = "rowNumber" style = "font-weight: bold; text-align: right;">2</td><td style = "text-align: left;">examples/data/database_style_joins.txt</td><td style = "text-align: left;">julia&gt; people = DataFrame(ID=[20, 40], Name=[&quot;John Doe&quot;, &quot;Jane Doe&quot;])\n2×2 DataFrame\n Row │ ID     Name\n     │ Int64  String\n─────┼─────────────────\n   1 │    20  John Doe\n   2 │    40  Jane Doe</td><td style = "text-align: left;">What is the DataFrame called &apos;people&apos; composed of?</td><td style = "text-align: left;">The DataFrame called &apos;people&apos; consists of two columns: &apos;ID&apos; and &apos;Name&apos;. The &apos;ID&apos; column contains integers, and the &apos;Name&apos; column contains strings.</td><td style = "text-align: right;">1.0</td><td style = "text-align: right;">1</td><td style = "text-align: right;">4.0</td><td style = "text-align: left;">Dict(:top_k=&gt;3)</td></tr><tr><td class = "rowNumber" style = "font-weight: bold; text-align: right;">3</td><td style = "text-align: left;">examples/data/database_style_joins.txt</td><td style = "text-align: left;">julia&gt; jobs = DataFrame(ID=[20, 40], Job=[&quot;Lawyer&quot;, &quot;Doctor&quot;])\n2×2 DataFrame\n Row │ ID     Job\n     │ Int64  String\n─────┼───────────────\n   1 │    20  Lawyer\n   2 │    40  Doctor</td><td style = "text-align: left;">What are the jobs and IDs listed in the dataframe?</td><td style = "text-align: left;">The jobs and IDs listed in the dataframe are as follows:\n\nID: 20\nJob: Lawyer\n\nID: 40\nJob: Doctor</td><td style = "text-align: right;">1.0</td><td style = "text-align: right;">1</td><td style = "text-align: right;">4.67</td><td style = "text-align: left;">Dict(:top_k=&gt;3)</td></tr><tr><td class = "rowNumber" style = "font-weight: bold; text-align: right;">4</td><td style = "text-align: left;">examples/data/database_style_joins.txt</td><td style = "text-align: left;">We might want to work with a larger data set that contains both the names and jobs for each ID. We can do this using the innerjoin function:</td><td style = "text-align: left;">How can we combine the names and jobs for each ID in a larger data set?</td><td style = "text-align: left;">We can use the `innerjoin` function to combine the names and jobs for each ID in a larger data set.</td><td style = "text-align: right;">1.0</td><td style = "text-align: right;">1</td><td style = "text-align: right;">4.33333</td><td style = "text-align: left;">Dict(:top_k=&gt;3)</td></tr><tr><td class = "rowNumber" style = "font-weight: bold; text-align: right;">5</td><td style = "text-align: left;">examples/data/database_style_joins.txt</td><td style = "text-align: left;">julia&gt; innerjoin(people, jobs, on = :ID)\n2×3 DataFrame\n Row │ ID     Name      Job\n     │ Int64  String    String\n─────┼─────────────────────────\n   1 │    20  John Doe  Lawyer\n   2 │    40  Jane Doe  Doctor</td><td style = "text-align: left;">What is the name of the person with the ID 40 and their job?</td><td style = "text-align: left;">The name of the person with the ID 40 is Jane Doe and their job is Doctor.</td><td style = "text-align: right;">1.0</td><td style = "text-align: right;">2</td><td style = "text-align: right;">4.67</td><td style = "text-align: left;">Dict(:top_k=&gt;3)</td></tr><tr><td class = "rowNumber" style = "font-weight: bold; text-align: right;">6</td><td style = "text-align: left;">examples/data/database_style_joins.txt</td><td style = "text-align: left;">In relational database theory, this operation is generally referred to as a join. The columns used to determine which rows should be combined during a join are called keys.\n\nThe following functions are provided to perform seven kinds of joins:</td><td style = "text-align: left;">What are the different kinds of joins?</td><td style = "text-align: left;">The different kinds of joins are:\n\n1. Inner Join: Returns only the rows that have matching values in both data frames.\n2. Left Join: Returns all rows from the left data frame and the matching rows from the right data frame.\n3. Right Join: Returns all rows from the right data frame and the matching rows from the left data frame.\n4. Full Outer Join: Returns all rows from both data frames and fills in missing values with null.\n5. Cross Join: Returns the cartesian product of the rows from both data frames.\n6. Semi Join: Returns only the rows from the left data frame that have matching values in the right data frame.\n7. Anti Join: Returns only the rows from the left data frame that do not have matching values in the right data frame.</td><td style = "text-align: right;">1.0</td><td style = "text-align: right;">1</td><td style = "text-align: right;">4.66667</td><td style = "text-align: left;">Dict(:top_k=&gt;3)</td></tr><tr><td class = "rowNumber" style = "font-weight: bold; text-align: right;">7</td><td style = "text-align: left;">examples/data/database_style_joins.txt</td><td style = "text-align: left;">innerjoin: the output contains rows for values of the key that exist in all passed data frames.</td><td style = "text-align: left;">What does the output of the inner join operation contain?</td><td style = "text-align: left;">The output of the inner join operation contains only the rows for values of the key that exist in all passed data frames.</td><td style = "text-align: right;">1.0</td><td style = "text-align: right;">1</td><td style = "text-align: right;">5.0</td><td style = "text-align: left;">Dict(:top_k=&gt;3)</td></tr><tr><td class = "rowNumber" style = "font-weight: bold; text-align: right;">8</td><td style = "text-align: left;">examples/data/database_style_joins.txt</td><td style = "text-align: left;">leftjoin: the output contains rows for values of the key that exist in the first (left) argument, whether or not that value exists in the second (right) argument.</td><td style = "text-align: left;">What is the purpose of the left join operation?</td><td style = "text-align: left;">The purpose of the left join operation is to combine data from two tables based on a common key, where all rows from the left (first) table are included in the output, regardless of whether there is a match in the right (second) table.</td><td style = "text-align: right;">1.0</td><td style = "text-align: right;">1</td><td style = "text-align: right;">4.66667</td><td style = "text-align: left;">Dict(:top_k=&gt;3)</td></tr><tr><td class = "rowNumber" style = "font-weight: bold; text-align: right;">9</td><td style = "text-align: left;">examples/data/database_style_joins.txt</td><td style = "text-align: left;">rightjoin: the output contains rows for values of the key that exist in the second (right) argument, whether or not that value exists in the first (left) argument.</td><td style = "text-align: left;">What is the purpose of the right join operation?</td><td style = "text-align: left;">The purpose of the right join operation is to include all the rows from the second (right) argument, regardless of whether a match is found in the first (left) argument.</td><td style = "text-align: right;">1.0</td><td style = "text-align: right;">1</td><td style = "text-align: right;">4.67</td><td style = "text-align: left;">Dict(:top_k=&gt;3)</td></tr><tr><td class = "rowNumber" style = "font-weight: bold; text-align: right;">10</td><td style = "text-align: left;">examples/data/database_style_joins.txt</td><td style = "text-align: left;">outerjoin: the output contains rows for values of the key that exist in any of the passed data frames.\nsemijoin: Like an inner join, but output is restricted to columns from the first (left) argument.</td><td style = "text-align: left;">What is the difference between outer join and semi join?</td><td style = "text-align: left;">The difference between outer join and semi join is that outer join includes rows for values of the key that exist in any of the passed data frames, whereas semi join is like an inner join but only outputs columns from the first argument.</td><td style = "text-align: right;">1.0</td><td style = "text-align: right;">1</td><td style = "text-align: right;">4.66667</td><td style = "text-align: left;">Dict(:top_k=&gt;3)</td></tr></tbody></table></div>


We're done for today!

# What would we do next? {#What-would-we-do-next?}
- Review your evaluation golden data set and keep only the good items
  
- Play with the chunk sizes (max_length in build_index) and see how it affects the quality
  
- Explore using metadata/key filters (`extract_metadata=true` in build_index)
  
- Add filtering for semantic similarity (embedding distance) to make sure we don't pick up irrelevant chunks in the context
  
- Use multiple indices or a hybrid index (add a simple BM25 lookup from TextAnalysis.jl)
  
- Data processing is the most important step - properly parsed and split text could make wonders
  
- Add re-ranking of context (see `rerank` function, you can use Cohere ReRank API)
  
- Improve the question embedding (eg, rephrase it, generate hypothetical answers and use them to find better context)
  

... and much more! See some ideas in [Anyscale RAG tutorial](https://www.anyscale.com/blog/a-comprehensive-guide-for-building-rag-based-llm-applications-part-1)


---


_This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl)._
