## Coding Feedback
abstract type AbstractCodeOutcome end
struct CodeEmpty <: AbstractCodeOutcome end
struct CodeFailedParse <: AbstractCodeOutcome end
struct CodeFailedEval <: AbstractCodeOutcome end
struct CodeFailedTimeout <: AbstractCodeOutcome end
struct CodeSuccess <: AbstractCodeOutcome end

# Feedback function skeleton
"""
    aicodefixer_feedback(conversation::AbstractVector{<:PT.AbstractMessage}; max_length::Int = 512) -> NamedTuple(; feedback::String)

Generate feedback for an AI code fixing session based on the conversation history.
Function is designed to be extensible for different types of feedback and code evaluation outcomes. 

The highlevel wrapper accepts a conversation and returns new kwargs for the AICall.

Individual feedback functions are dispatched on different subtypes of `AbstractCodeOutcome` and can be extended/overwritten to provide more detailed feedback.

See also: `AIGenerate`, `AICodeFixer`

# Arguments
- `conversation::AbstractVector{<:PT.AbstractMessage}`: A vector of messages representing the conversation history, where the last message is expected to contain the code to be analyzed.
- `max_length::Int=512`: An optional argument that specifies the maximum length of the feedback message.

# Returns
- `NamedTuple`: A feedback message as a kwarg in NamedTuple based on the analysis of the code provided in the conversation.

# Example
```julia
new_kwargs = aicodefixer_feedback(conversation)
```

# Notes
This function is part of the AI code fixing system, intended to interact with code in AIMessage and provide feedback on improving it.

The highlevel wrapper accepts a conversation and returns new kwargs for the AICall.

It dispatches for the code feedback based on the subtypes of `AbstractCodeOutcome` below:
- `CodeEmpty`: No code found in the message.
- `CodeFailedParse`: Code parsing error.
- `CodeFailedEval`: Runtime evaluation error.
- `CodeFailedTimeout`: Code execution timed out.
- `CodeSuccess`: Successful code execution.

You can override the individual methods to customize the feedback.
"""
function aicodefixer_feedback(conversation::AbstractVector{<:PT.AbstractMessage};
        max_length::Int = 512)
    @assert max_length>0 "max_length must be positive (provided: $max_length)"
    # Extract the last message, evaluate code, determine outcome
    cb = AICode(last(conversation); skip_unsafe = true, capture_stdout = true)
    outcome = if isempty(cb.code)
        CodeEmpty() # No code provided
    elseif !PT.isparsed(cb)
        CodeFailedParse() # Failed to parse
    elseif !isnothing(cb.error) && isa(cb.error, InterruptException)
        CodeFailedTimeout() # Failed to evaluate in time provided
    elseif !isnothing(cb.error)
        CodeFailedEval() # Failed to evaluate
    else
        CodeSuccess() # Success
    end
    # Return new kwargs or adjustments based on the outcome
    new_kwargs = (; feedback = aicodefixer_feedback(outcome, cb; max_length))
    return new_kwargs
end

function aicodefixer_feedback(::CodeEmpty, args...; kwargs...)
    "**Error Detected**: No Julia code found. Always enclose Julia code in triple backticks code fence (\`\`\`julia\\n ... \\n\`\`\`)."
end
function aicodefixer_feedback(::CodeFailedTimeout, args...; kwargs...)
    "**Error Detected**: Evaluation timed out. Please check your code for infinite loops or other issues."
end
function aicodefixer_feedback(::CodeSuccess, cb::AICode;
        max_length::Int = 512,
        kwargs...)
    stdout_str = if isnothing(cb.stdout) || isempty(cb.stdout)
        ""
    else
        temp = string(cb.stdout)
        end_idx = min(length(stdout_str), nextind(stdout_str, 0, max_length))
        "\n\n**Output Captured:** $(temp[begin:end_idx])"
    end
    "Execution has been successful (no errors detected). Consider adding 1-2 challenging unit tests to improve the implementation - use @test macro, organize in a @testset block.$(stdout_str)"
end
function aicodefixer_feedback(::CodeFailedParse,
        cb::AICode;
        max_length::Int = 512,
        kwargs...)
    ## TODO: grab the parse error from expression?
    ## Simple method
    error_ = split(string(cb.error), "JuliaSyntax.SourceFile")[begin]
    chunk_length = isnothing(cb.stdout) || isempty(cb.stdout) ? max_length :
                   max_length ÷ 2
    end_idx = min(length(error_), nextind(error_, 0, chunk_length))
    "**Pasing Error Detected:** $(error_[begin:end_idx])"
end

function aicodefixer_feedback(::CodeFailedEval,
        cb::AICode;
        max_length::Int = 512,
        kwargs...)
    feedback = AbstractString[]
    ## Grab the error message
    error_ = split(string(cb.error), "JuliaSyntax.SourceFile")[begin]
    ## Decide how much space can be dedicated for this error (ie, do we have stdout as well?)
    chunk_length = isnothing(cb.stdout) || isempty(cb.stdout) ? max_length :
                   max_length ÷ 2
    end_idx = min(length(error_), nextind(error_, 0, chunk_length))
    push!(feedback, "**Error Detected:** $(error_[begin:end_idx])")

    if !isnothing(cb.stdout) && !isempty(string(cb.stdout))
        ## Add the optional STDOUT (for test failures)
        chunk_length = max_length - sum(length, feedback)
        end_idx = min(length(cb.stdout), nextind(cb.stdout, 0, chunk_length))
        push!(feedback, "**Output Captured:** $(cb.stdout[begin:end_idx])")
    end

    return isempty(feedback) ? "No feedback provided." : join(feedback, "\n\n")
end