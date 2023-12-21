### For testing and eval
# This is a return_type for extraction when generating Q&A set with aiextract
@kwdef struct QAItem
    question::String
    answer::String
end
# This is for saving in JSON format for evaluation later
@kwdef struct QAEvalItem
    source::String = ""
    context::String = ""
    question::String = ""
    answer::String = ""
end

"Provide the `final_rating` between 1-5. Provide the rationale for it."
@kwdef struct JudgeRating
    rationale::Union{Nothing, String} = nothing
    final_rating::Int
end
"Explain the `final_rating` in `rationale`"
@kwdef struct JudgeAllScores
    relevance::Int
    completeness::Int
    clarity::Int
    consistency::Int
    helpfulness::Int
    rationale::Union{Nothing, String} = nothing
    final_rating::Int
end

function Base.isvalid(x::QAEvalItem)
    !isempty(x.question) && !isempty(x.answer) && !isempty(x.context)
end

# Nicer show method with some colors!
function Base.show(io::IO, t::Union{QAItem, QAEvalItem})
    printstyled(io, "$(nameof(typeof(t))):\n", color = :green, bold = true)
    for f in fieldnames(typeof(t))
        printstyled(io, " ", f, color = :blue, bold = true)
        println(io, ": ", getfield(t, f))
    end
end
# Define how JSON3 should serialize/deserialize the struct into JSON files
JSON3.StructTypes.StructType(::Type{QAEvalItem}) = JSON3.StructTypes.Struct()

"""
    build_qa_evals(doc_chunks::Vector{<:AbstractString}, sources::Vector{<:AbstractString};
                   model=PT.MODEL_CHAT, instructions="None.", qa_template::Symbol=:RAGCreateQAFromContext, verbose::Bool=true, kwargs...) -> Vector{QAEvalItem}

Create a collection of question and answer evaluations (`QAEvalItem`) from document chunks and sources. 
This function generates Q&A pairs based on the provided document chunks, using a specified AI model and template.

# Arguments
- `doc_chunks::Vector{<:AbstractString}`: A vector of document chunks, each representing a segment of text.
- `sources::Vector{<:AbstractString}`: A vector of source identifiers corresponding to each chunk in `doc_chunks` (eg, filenames or paths).
- `model`: The AI model used for generating Q&A pairs. Default is `PT.MODEL_CHAT`.
- `instructions::String`: Additional instructions or context to provide to the model generating QA sets. Defaults to "None.".
- `qa_template::Symbol`: A template symbol that dictates the AITemplate that will be used. It must have placeholder `context`. Default is `:CreateQAFromContext`.
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
        qa_template::Symbol = :RAGCreateQAFromContext, verbose::Bool = true, kwargs...)
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
                model)
            Threads.atomic_add!(cost_tracker, PT.call_cost(msg, model)) # track costs
            QAEvalItem(; context, msg.content.question, msg.content.answer, source)
        catch e
            QAEvalItem()
        end
    end
    verbose && @info "Q&A Sets built! (cost: \$$(round(cost_tracker[], digits=3)))"
    return filter(isvalid, output)
end
