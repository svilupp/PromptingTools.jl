### For testing and eval
# This is a return_type for extraction when generating Q&A set with aiextract
@kwdef struct QAItem
    question::String = ""
    answer::String = ""
end
# This is for saving in JSON format for evaluation later
@kwdef struct QAEvalItem
    source::String = ""
    context::String = ""
    question::String = ""
    answer::String = ""
end

@kwdef struct QAEvalResult
    source::AbstractString
    context::AbstractString
    question::AbstractString
    answer::AbstractString
    retrieval_score::Union{Number, Nothing} = nothing
    retrieval_rank::Union{Int, Nothing} = nothing
    answer_score::Union{Number, Nothing} = nothing
    parameters::Dict{Symbol, Any} = Dict{Symbol, Any}()
end

"Provide the `final_rating` between 1-5. Provide the rationale for it."
@kwdef struct JudgeRating
    rationale::Union{Nothing, String} = nothing
    final_rating::Int
end

"`final_rating` is the average of all scoring criteria. Explain the `final_rating` in `rationale`"
@kwdef struct JudgeAllScores
    relevance::Int
    completeness::Int
    clarity::Int
    consistency::Int
    helpfulness::Int
    rationale::Union{Nothing, String} = nothing
    final_rating::Float64
end

function Base.isvalid(x::QAEvalItem)
    !isempty(x.question) && !isempty(x.answer) && !isempty(x.context)
end
# for equality tests
function Base.var"=="(x::Union{QAItem, QAEvalItem, QAEvalResult},
        y::Union{QAItem, QAEvalItem, QAEvalResult})
    typeof(x) == typeof(y) &&
        all([getfield(x, f) == getfield(y, f) for f in fieldnames(typeof(x))])
end

# Nicer show method with some colors!
function Base.show(io::IO, t::Union{QAItem, QAEvalItem, QAEvalResult})
    printstyled(io, "$(nameof(typeof(t))):\n", color = :green, bold = true)
    for f in fieldnames(typeof(t))
        printstyled(io, " ", f, color = :blue, bold = true)
        println(io, ": ", getfield(t, f))
    end
end
# Define how JSON3 should serialize/deserialize the struct into JSON files
JSON3.StructTypes.StructType(::Type{QAEvalItem}) = JSON3.StructTypes.Struct()
JSON3.StructTypes.StructType(::Type{QAEvalResult}) = JSON3.StructTypes.Struct()

"""
    build_qa_evals(doc_chunks::Vector{<:AbstractString}, sources::Vector{<:AbstractString};
                   model=PT.MODEL_CHAT, instructions="None.", qa_template::Symbol=:RAGCreateQAFromContext, 
                   verbose::Bool=true, api_kwargs::NamedTuple = NamedTuple(), kwargs...) -> Vector{QAEvalItem}

Create a collection of question and answer evaluations (`QAEvalItem`) from document chunks and sources. 
This function generates Q&A pairs based on the provided document chunks, using a specified AI model and template.

# Arguments
- `doc_chunks::Vector{<:AbstractString}`: A vector of document chunks, each representing a segment of text.
- `sources::Vector{<:AbstractString}`: A vector of source identifiers corresponding to each chunk in `doc_chunks` (eg, filenames or paths).
- `model`: The AI model used for generating Q&A pairs. Default is `PT.MODEL_CHAT`.
- `instructions::String`: Additional instructions or context to provide to the model generating QA sets. Defaults to "None.".
- `qa_template::Symbol`: A template symbol that dictates the AITemplate that will be used. It must have placeholder `context`. Default is `:CreateQAFromContext`.
- `api_kwargs::NamedTuple`: Parameters that will be forwarded to the API endpoint.
- `verbose::Bool`: If `true`, additional information like costs will be logged. Defaults to `true`.

# Returns
`Vector{QAEvalItem}`: A vector of `QAEvalItem` structs, each containing a source, context, question, and answer. Invalid or empty items are filtered out.

# Notes

- The function internally uses `aiextract` to generate Q&A pairs based on the provided `qa_template`. So you can use any kwargs that you want.
- Each `QAEvalItem` includes the context (document chunk), the generated question and answer, and the source.
- The function tracks and reports the cost of AI calls if `verbose` is enabled.
- Items where the question, answer, or context is empty are considered invalid and are filtered out.

# Examples

Creating Q&A evaluations from a set of document chunks:
```julia
doc_chunks = ["Text from document 1", "Text from document 2"]
sources = ["source1", "source2"]
qa_evals = build_qa_evals(doc_chunks, sources)
```
"""
function build_qa_evals(doc_chunks::Vector{<:AbstractString},
        sources::Vector{<:AbstractString};
        model = PT.MODEL_CHAT, instructions = "None.",
        qa_template::Symbol = :RAGCreateQAFromContext, verbose::Bool = true,
        api_kwargs::NamedTuple = NamedTuple(), kwargs...)
    ##
    @assert length(doc_chunks)==length(sources) "Length of `doc_chunks` and `sources` must be the same."
    placeholders = only(aitemplates(qa_template)).variables # only one template should be found
    @assert (:context in placeholders) "Provided Q&A Template $(qa_template) is not suitable. It must have placeholder: `context`."
    ##
    cost_tracker = Threads.Atomic{Float64}(0.0)
    output = asyncmap(zip(doc_chunks, sources)) do (context, source)
        try
            msg = aiextract(qa_template;
                return_type = QAItem,
                context,
                instructions,
                verbose,
                model, api_kwargs)
            Threads.atomic_add!(cost_tracker, PT.call_cost(msg, model)) # track costs
            QAEvalItem(; context, msg.content.question, msg.content.answer, source)
        catch e
            verbose && @warn e
            QAEvalItem()
        end
    end
    verbose && @info "Q&A Sets built! (cost: \$$(round(cost_tracker[], digits=3)))"
    return filter(isvalid, output)
end

"Returns 1.0 if `context` overlaps or is contained within any of the `candidate_context`"
function score_retrieval_hit(orig_context::AbstractString,
        candidate_context::Vector{<:AbstractString})
    1.0 * (any(occursin.(Ref(orig_context), candidate_context)) ||
     any(occursin.(candidate_context, Ref(orig_context))))
end

"Returns Integer rank of the position where `context` overlaps or is contained within a `candidate_context`"
function score_retrieval_rank(orig_context::AbstractString,
        candidate_context::Vector{<:AbstractString})
    findfirst((occursin.(Ref(orig_context), candidate_context)) .||
              (occursin.(candidate_context, Ref(orig_context))))
end

"""
    run_qa_evals(qa_item::QAEvalItem, ctx::RAGDetails; verbose::Bool = true,
                 parameters_dict::Dict{Symbol, <:Any}, judge_template::Symbol = :RAGJudgeAnswerFromContext,
                 model_judge::AbstractString, api_kwargs::NamedTuple = NamedTuple()) -> QAEvalResult

Evaluates a single `QAEvalItem` using RAG details (`RAGDetails`) and returns a `QAEvalResult` structure. This function assesses the relevance and accuracy of the answers generated in a QA evaluation context.

# Arguments
- `qa_item::QAEvalItem`: The QA evaluation item containing the question and its answer.
- `ctx::RAGDetails`: The context used for generating the QA pair, including the original context and the answers.
  Comes from `airag(...; return_context=true)`
- `verbose::Bool`: If `true`, enables verbose logging. Defaults to `true`.
- `parameters_dict::Dict{Symbol, Any}`: Track any parameters used for later evaluations. Keys must be Symbols.
- `judge_template::Symbol`: The template symbol for the AI model used to judge the answer. Defaults to `:RAGJudgeAnswerFromContext`.
- `model_judge::AbstractString`: The AI model used for judging the answer's quality. 
  Defaults to standard chat model, but it is advisable to use more powerful model GPT-4.
- `api_kwargs::NamedTuple`: Parameters that will be forwarded to the API endpoint.

# Returns
`QAEvalResult`: An evaluation result that includes various scores and metadata related to the QA evaluation.

# Notes
- The function computes a retrieval score and rank based on how well the context matches the QA context.
- It then uses the `judge_template` and `model_judge` to score the answer's accuracy and relevance.
- In case of errors during evaluation, the function logs a warning (if `verbose` is `true`) and the `answer_score` will be set to `nothing`.

# Examples

Evaluating a QA pair using a specific context and model:
```julia
qa_item = QAEvalItem(question="What is the capital of France?", answer="Paris", context="France is a country in Europe.")
ctx = RAGDetails(source="Wikipedia", context="France is a country in Europe.", answer="Paris")
parameters_dict = Dict("param1" => "value1", "param2" => "value2")

eval_result = run_qa_evals(qa_item, ctx, parameters_dict=parameters_dict, model_judge="MyAIJudgeModel")
```
"""
function run_qa_evals(qa_item::QAEvalItem, ctx::RAGDetails;
        verbose::Bool = true, parameters_dict::Dict{Symbol, <:Any} = Dict{Symbol, Any}(),
        judge_template::Symbol = :RAGJudgeAnswerFromContextShort,
        model_judge::AbstractString = PT.MODEL_CHAT,
        api_kwargs::NamedTuple = NamedTuple())
    retrieval_score = score_retrieval_hit(qa_item.context, ctx.context)
    retrieval_rank = score_retrieval_rank(qa_item.context, ctx.context)

    # Note we could evaluate if RAGDetails and QAEvalItem are at least using the same sources etc. 

    answer_score = try
        msg = aiextract(judge_template; model = model_judge, verbose,
            ctx.context,
            ctx.question,
            ctx.answer,
            return_type = JudgeAllScores, api_kwargs)
        final_rating = if msg.content isa AbstractDict && haskey(msg.content, :final_rating)
            # if return type parsing failed
            msg.content[:final_rating]
        else
            # if return_type worked
            msg.content.final_rating
        end
    catch e
        verbose && @warn "Error in QA eval ($(qa_item.question)): $e"
        nothing
    end

    return QAEvalResult(;
        qa_item.source,
        qa_item.context,
        qa_item.question,
        ctx.answer,
        retrieval_score,
        retrieval_rank,
        answer_score,
        parameters = parameters_dict)
end

"""
    run_qa_evals(index::AbstractChunkIndex, qa_items::AbstractVector{<:QAEvalItem};
        api_kwargs::NamedTuple = NamedTuple(),
        airag_kwargs::NamedTuple = NamedTuple(),
        qa_evals_kwargs::NamedTuple = NamedTuple(),
        verbose::Bool = true, parameters_dict::Dict{Symbol, <:Any} = Dict{Symbol, Any}())

Evaluates a vector of `QAEvalItem`s and returns a vector `QAEvalResult`. 
This function assesses the relevance and accuracy of the answers generated in a QA evaluation context.

See `?run_qa_evals` for more details.

# Arguments
- `qa_items::AbstractVector{<:QAEvalItem}`: The vector of QA evaluation items containing the questions and their answers.
- `verbose::Bool`: If `true`, enables verbose logging. Defaults to `true`.
- `api_kwargs::NamedTuple`: Parameters that will be forwarded to the API calls. See `?aiextract` for details.
- `airag_kwargs::NamedTuple`: Parameters that will be forwarded to `airag` calls. See `?airag` for details.
- `qa_evals_kwargs::NamedTuple`: Parameters that will be forwarded to `run_qa_evals` calls. See `?run_qa_evals` for details.
- `parameters_dict::Dict{Symbol, Any}`: Track any parameters used for later evaluations. Keys must be Symbols.

# Returns
`Vector{QAEvalResult}`: Vector of evaluation results that includes various scores and metadata related to the QA evaluation.

# Example
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

"""
function run_qa_evals(index::AbstractChunkIndex, qa_items::AbstractVector{<:QAEvalItem};
        api_kwargs::NamedTuple = NamedTuple(),
        airag_kwargs::NamedTuple = NamedTuple(),
        qa_evals_kwargs::NamedTuple = NamedTuple(),
        verbose::Bool = true, parameters_dict::Dict{Symbol, <:Any} = Dict{Symbol, Any}())
    # Run evaluations in parallel
    results = asyncmap(qa_items) do qa_item
        # Generate an answer -- often you want the model_judge to be the highest quality possible, eg, "GPT-4 Turbo" (alias "gpt4t)
        msg, ctx = airag(index; qa_item.question, return_details = true,
            verbose, api_kwargs, airag_kwargs...)

        # Evaluate the response
        # Note: you can log key parameters for easier analysis later
        run_qa_evals(qa_item,
            ctx;
            parameters_dict,
            verbose,
            api_kwargs,
            qa_evals_kwargs...)
    end
    success_count = count(x -> !isnothing(x.answer_score), results)
    verbose &&
        @info "QA Evaluations complete ($((success_count)/length(qa_items)) evals successful)!"
    return results
end
