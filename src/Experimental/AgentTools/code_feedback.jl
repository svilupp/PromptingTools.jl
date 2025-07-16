## Coding Feedback
abstract type AbstractCodeOutcome end
struct CodeEmpty <: AbstractCodeOutcome end
struct CodeFailedParse <: AbstractCodeOutcome end
struct CodeFailedEval <: AbstractCodeOutcome end
struct CodeFailedTimeout <: AbstractCodeOutcome end
struct CodeSuccess <: AbstractCodeOutcome end

# Feedback function skeleton
"""
    aicodefixer_feedback(cb::AICode; max_length::Int = 512) -> NamedTuple(; feedback::String)
    aicodefixer_feedback(conversation::AbstractVector{<:PT.AbstractMessage}; max_length::Int = 512) -> NamedTuple(; feedback::String)
    aicodefixer_feedback(msg::PT.AIMessage; max_length::Int = 512) -> NamedTuple(; feedback::String)
    aicodefixer_feedback(aicall::AICall; max_length::Int = 512) -> NamedTuple(; feedback::String)

Generate feedback for an AI code fixing session based on the AICode block /or conversation history (that will be used to extract and evaluate a code block).
Function is designed to be extensible for different types of feedback and code evaluation outcomes. 

The highlevel wrapper accepts a conversation and returns new kwargs for the AICall.

Individual feedback functions are dispatched on different subtypes of `AbstractCodeOutcome` and can be extended/overwritten to provide more detailed feedback.

See also: `AIGenerate`, `AICodeFixer`

# Arguments
- `cb::AICode`: AICode block to evaluate and provide feedback on.
- `max_length::Int=512`: An optional argument that specifies the maximum length of the feedback message.

# Returns
- `NamedTuple`: A feedback message as a kwarg in NamedTuple based on the analysis of the code provided in the conversation.

# Example
```julia
cb = AICode(msg; skip_unsafe = true, capture_stdout = true)
new_kwargs = aicodefixer_feedback(cb)

new_kwargs = aicodefixer_feedback(msg)
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
function aicodefixer_feedback(cb::AICode;
        max_length::Int = 512)
    @assert max_length>0 "max_length must be positive (provided: $max_length)"
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
function aicodefixer_feedback(msg::PT.AIMessage; kwargs...)
    # Extract the last message, evaluate code, determine outcome
    cb = AICode(msg; skip_unsafe = true, capture_stdout = true)
    aicodefixer_feedback(cb; kwargs...)
end
function aicodefixer_feedback(conversation::AbstractVector{<:PT.AbstractMessage}; kwargs...)
    aicodefixer_feedback(last(conversation); kwargs...)
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
        end_idx = min(length(temp), nextind(temp, 0, max_length))
        "\n\n**Output Captured:** $(temp[begin:end_idx])"
    end
    "Execution has been successful (no errors detected). Consider adding 1-2 challenging unit tests to improve the main function - use `@test` macro, organize them in `@testset begin .. end` block.$(stdout_str)"
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
    "**Parsing Error Detected:** $(error_[begin:end_idx])"
end

function aicodefixer_feedback(::CodeFailedEval,
        cb::AICode;
        max_length::Int = 512,
        kwargs...)
    feedback = AbstractString[]
    ## Grab the error message
    ## Decide how much space can be dedicated for this error (ie, do we have stdout as well?)
    chunk_length = isnothing(cb.stdout) || isempty(cb.stdout) ? max_length :
                   max_length ÷ 2
    error_str = error_feedback(cb.error; max_length = chunk_length)
    push!(feedback, "**Error Detected:**\n$(error_str)")

    ## Add the lines that caused it
    if !isempty(cb.error_lines)
        feedback_lines = String[]
        max_lines = 2 # max lines to send
        logged_lines = Set{Int}()
        code_lines = split(cb.code, "\n")
        for line in cb.error_lines
            if line ∉ logged_lines && line ≤ length(code_lines) &&
               length(logged_lines) <= max_lines
                push!(feedback_lines, "- " * code_lines[line])
                push!(logged_lines, line)
            end
        end
        push!(feedback,
            "\n\n**Lines that caused the error:**\n" * join(feedback_lines, "\n"))
    end

    if !isnothing(cb.stdout) && !isempty(string(cb.stdout))
        ## Add the optional STDOUT (for test failures)
        chunk_length = max_length - sum(length, feedback)
        end_idx = min(length(cb.stdout), nextind(cb.stdout, 0, chunk_length))
        push!(feedback, "**Output Captured:**\n $(cb.stdout[begin:end_idx])")
    end

    return isempty(feedback) ? "No feedback provided." : join(feedback, "\n\n")
end

function testset_feedback(msg::AIMessage;
        prefix::AbstractString = "",
        suffix::AbstractString = "", kwargs...)
    code = join(PT.extract_code_blocks(msg.content), "\n")
    test_f = PT.extract_testset_name(code)
    if !isnothing(test_f)
        test_f_mock = "$(replace(test_f, r"[\s\(\)]" => ""))(args...; kwargs...) = nothing"
        prefix = prefix * "\n" * test_f_mock
    end
    # Insert mock function, remove test items -- good test suite should pass
    cb = AICode(msg;
        skip_unsafe = true,
        prefix, suffix,
        expression_transform = :remove_test_items, kwargs...)
    feedback = if !isnothing(cb.error)
        aicodefixer_feedback(CodeFailedEval(), cb)
    else
        nothing
    end
    return feedback
end

### Feedback for individual errors
"""
    error_feedback(e::Any; max_length::Int = 512)

Set of specialized methods to provide feedback on different types of errors (`e`).
"""
error_feedback(e::Any; max_length::Int = 512) = "No error found. Ignore."
function error_feedback(e::Exception; max_length::Int = 512)
    io = IOBuffer()
    name_ = typeof(e) |> nameof |> string
    write(io, "**", name_, "**:\n")
    showerror(io, e)
    first(String(take!(io)), max_length)
end
# FallbackTestSetException will take the default path
# TODO: add with x==1; @test x==2
function error_feedback(e::Test.TestSetException; max_length::Int = 512)
    io = IOBuffer()
    name_ = typeof(e) |> nameof |> string
    write(io, "**", name_, "**:\n")
    showerror(io, e)
    ## Unpack the results in
    write(io, "\n")
    for error_ in e.errors_and_fails
        io_ = IOBuffer()
        showerror(io_, error_)
        out = split(String(take!(io_)), "Stacktrace")[begin]
        write(io, "\n", out)
    end

    first(String(take!(io)), max_length)
end
function error_feedback(e::Task; max_length::Int = 512)
    out = try
        fetch(e)
    catch e
        e
    end
    error_feedback(out; max_length)
end
function error_feedback(e::TaskFailedException; max_length::Int = 512)
    error_feedback(e.task.result; max_length)
end
function error_feedback(e::Base.Meta.ParseError; max_length::Int = 512)
    io = IOBuffer()
    name_ = typeof(e) |> nameof |> string
    write(io, "**", name_, "**:\n")
    showerror(io, e)
    first(String(take!(io)), max_length)
end
function error_feedback(e::UndefVarError; max_length::Int = 512)
    io = IOBuffer()
    showerror(io, e)
    # Simple heurisic - if's available in Main/Base
    found = false
    for mod in [Base, Main]
        if hasproperty(mod, e.var)
            write(io,
                "\nExpert Tip: I know that the variable $(e.var) is defined in $(nameof(mod)) module. Use `import $(mod).$(e.var)` to use it.")
            found = true
            break
        end
    end
    !found && write(io,
        "\nTip: Does it even exist? Does it need to be imported? Or is it a typo?")
    first(String(take!(io)), max_length)
end
function error_feedback(e::ArgumentError; max_length::Int = 512)
    io = IOBuffer()
    showerror(io, e)
    # Simple heurisic - if's available in Main/Base
    pkg = PT.extract_package_name_from_argerror(e.msg)
    if !isnothing(pkg)
        for mod in [Base, Main]
            hasproperty(mod, Symbol(pkg)) && (
                write(io,
                    "\nExpert Tip: I know that the package $pkg is defined in $(nameof(mod)) module. You MUST use `import $(mod).$(pkg)` to use it.");
                break)
        end
    end
    first(String(take!(io)), max_length)
end

## 
function score_feedback(cb::AICode, expr_to_run::Expr = Expr(:block))
    score = if isempty(cb.code)
        0
    elseif !PT.isparsed(cb)
        1
    elseif isa(cb.error, Test.TestSetException)
        # error outside of test is twice as bad
        10 + cb.error.pass - cb.error.fail - 2cb.error.error # ignore broken
    elseif isa(cb.error, Exception)
        2
    elseif isvalid(cb)
        10
    else
        throw(ArgumentError("Invalid code feedback path?"))
    end
    return score
end

function extract_test_counts(test_summary::String)
    # Split the test summary into lines
    lines = split(test_summary, '\n')
    length_ = length(lines)
    counts = Dict{String, Int}()

    # Find the line containing the column headers
    for i in eachindex(lines)
        # iterate only until penultimate, since we look ahead one line
        i == length_ && break
        m = match(r"Test Summary:\s*\|\s*([^|]*?)\s*Total", lines[i])
        if !isnothing(m) && !isnothing(m.captures)
            headers = [
                [lowercase(strip(col))
                 for col in split(m.captures[1], " ") if !isempty(col)]..., "total"]
            next_line = lines[i + 1]
            digits = [tryparse(Int, m.match)
                      for m in eachmatch(r"\b\d+\b", next_line)]
            for (header, score) in zip(headers, digits)
                if !isnothing(score)
                    counts[header] = get(counts, header, 0) + score
                end
            end
        end
    end
    return counts
end
