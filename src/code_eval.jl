# These are utilities to support code generation
# 
# Types defined (not exported!): 
# - AbstractCodeBlock
# - AICode
#
# Functions defined (not exported!): 
# - detect_pkg_operation, extract_julia_imports, detect_missing_packages
# - extract_code_blocks
# - eval!
#
# 
#
## # Types

abstract type AbstractCodeBlock end

"""
    AICode(code::AbstractString; auto_eval::Bool=true, safe_eval::Bool=false, 
    skip_unsafe::Bool=false, capture_stdout::Bool=true, verbose::Bool=false,
    prefix::AbstractString="", suffix::AbstractString="", remove_tests::Bool=false, execution_timeout::Int = 60)

    AICode(msg::AIMessage; auto_eval::Bool=true, safe_eval::Bool=false, 
    skip_unsafe::Bool=false, skip_invalid::Bool=false, capture_stdout::Bool=true,
    verbose::Bool=false, prefix::AbstractString="", suffix::AbstractString="", remove_tests::Bool=false, execution_timeout::Int = 60)

A mutable structure representing a code block (received from the AI model) with automatic parsing, execution, and output/error capturing capabilities.

Upon instantiation with a string, the `AICode` object automatically runs a code parser and executor (via `PromptingTools.eval!()`), capturing any standard output (`stdout`) or errors. 
This structure is useful for programmatically handling and evaluating Julia code snippets.

See also: `PromptingTools.extract_code_blocks`, `PromptingTools.eval!`

# Workflow
- Until `cb::AICode` has been evaluated, `cb.success` is set to `nothing` (and so are all other fields).
- The text in `cb.code` is parsed (saved to `cb.expression`).
- The parsed expression is evaluated.
- Outputs of the evaluated expression are captured in `cb.output`.
- Any `stdout` outputs (e.g., from `println`) are captured in `cb.stdout`.
- If an error occurs during evaluation, it is saved in `cb.error`.
- After successful evaluation without errors, `cb.success` is set to `true`. 
  Otherwise, it is set to `false` and you can inspect the `cb.error` to understand why.

# Properties
- `code::AbstractString`: The raw string of the code to be parsed and executed.
- `expression`: The parsed Julia expression (set after parsing `code`).
- `stdout`: Captured standard output from the execution of the code.
- `output`: The result of evaluating the code block.
- `success::Union{Nothing, Bool}`: Indicates whether the code block executed successfully (`true`), unsuccessfully (`false`), or has yet to be evaluated (`nothing`).
- `error::Union{Nothing, Exception}`: Any exception raised during the execution of the code block.

# Keyword Arguments
- `auto_eval::Bool`: If set to `true`, the code block is automatically parsed and evaluated upon instantiation. Defaults to `true`.
- `safe_eval::Bool`: If set to `true`, the code block checks for package operations (e.g., installing new packages) and missing imports, and then evaluates the code inside a bespoke scratch module. This is to ensure that the evaluation does not alter any user-defined variables or the global state. Defaults to `false`.
- `skip_unsafe::Bool`: If set to `true`, we skip any lines in the code block that are deemed unsafe (eg, `Pkg` operations). Defaults to `false`.
- `skip_invalid::Bool`: If set to `true`, we skip code blocks that do not even parse. Defaults to `false`.
- `verbose::Bool`: If set to `true`, we print out any lines that are skipped due to being unsafe. Defaults to `false`.
- `capture_stdout::Bool`: If set to `true`, we capture any stdout outputs (eg, test failures) in `cb.stdout`. Defaults to `true`.
- `prefix::AbstractString`: A string to be prepended to the code block before parsing and evaluation.
  Useful to add some additional code definition or necessary imports. Defaults to an empty string.
- `suffix::AbstractString`: A string to be appended to the code block before parsing and evaluation. 
  Useful to check that tests pass or that an example executes. Defaults to an empty string.
- `remove_tests::Bool`: If set to `true`, we remove any `@test` or `@testset` macros from the code block before parsing and evaluation. Defaults to `false`.
- `execution_timeout::Int`: The maximum time (in seconds) allowed for the code block to execute. Defaults to 60 seconds.

# Methods
- `Base.isvalid(cb::AICode)`: Check if the code block has executed successfully. Returns `true` if `cb.success == true`.

# Examples

```julia
code = AICode("println(\"Hello, World!\")") # Auto-parses and evaluates the code, capturing output and errors.
isvalid(code) # Output: true
code.stdout # Output: "Hello, World!\n"
```

We try to evaluate "safely" by default (eg, inside a custom module, to avoid changing user variables).
  You can avoid that with `save_eval=false`:

```julia
code = AICode("new_variable = 1"; safe_eval=false)
isvalid(code) # Output: true
new_variable # Output: 1
```

You can also call AICode directly on an AIMessage, which will extract the Julia code blocks, concatenate them and evaluate them:

```julia
msg = aigenerate("In Julia, how do you create a vector of 10 random numbers?")
code = AICode(msg)
# Output: AICode(Success: True, Parsed: True, Evaluated: True, Error Caught: N/A, StdOut: True, Code: 2 Lines)

# show the code
code.code |> println
# Output: 
# numbers = rand(10)
# numbers = rand(1:100, 10)

# or copy it to the clipboard
code.code |> clipboard

# or execute it in the current module (=Main)
eval(code.expression)
```
"""
@kwdef mutable struct AICode <: AbstractCodeBlock
    code::AbstractString
    expression = nothing
    stdout = nothing
    output = nothing
    success::Union{Nothing, Bool} = nothing
    error::Union{Nothing, Exception} = nothing
    error_lines::Vector{Int} = Int[]
end
# Eager evaluation if instantiated with a string
function (CB::Type{T})(md::AbstractString;
        auto_eval::Bool = true,
        safe_eval::Bool = true,
        skip_unsafe::Bool = false,
        capture_stdout::Bool = true,
        verbose::Bool = false,
        prefix::AbstractString = "",
        suffix::AbstractString = "",
        expression_transform::Symbol = :nothing,
        execution_timeout::Int = 60) where {T <: AbstractCodeBlock}
    ##
    @assert execution_timeout>0 "execution_timeout must be positive"
    if skip_unsafe
        md, removed = remove_unsafe_lines(md; verbose)
    else
        removed = ""
    end
    cb = CB(; code = md)
    if auto_eval
        ## set to timeout in `execution_timeout` seconds
        result = @timeout execution_timeout begin
            eval!(cb;
                safe_eval,
                capture_stdout,
                prefix,
                suffix,
                expression_transform)
        end nothing # set to nothing if it fails
        # Check if we timed out
        if isnothing(result)
            cb.success = false
            cb.error = InterruptException()
        end
    end
    if !isempty(removed)
        ## Add to STDOUT what we removed
        warning = string(
            "!!! IMPORTANT: Unsafe lines blocked from execution (eg, Pkg operations or imports of non-existent packages):",
            "\n$removed\n",
            "Fix or find a workaround!")
        if isnothing(cb.stdout)
            cb.stdout = warning
        else
            cb.stdout = "$(cb.stdout)\n\n$warning"
        end
    end
    return cb
end
Base.isvalid(cb::AbstractCodeBlock) = cb.success == true
function Base.copy(cb::AbstractCodeBlock)
    AICode(cb.code,
        cb.expression,
        cb.stdout,
        cb.output,
        cb.success,
        cb.error,
        cb.error_lines)
end
# equality check for testing, only equal if all fields are equal and type is the same
function Base.var"=="(c1::T, c2::T) where {T <: AICode}
    all([getproperty(c1, f) == getproperty(c2, f) for f in fieldnames(T)])
end
function Base.show(io::IO, cb::AICode)
    success_str = cb.success === nothing ? "N/A" : titlecase(string(cb.success))
    expression_str = cb.expression === nothing ? "N/A" : titlecase(string(isparsed(cb)))
    stdout_str = cb.stdout === nothing ? "N/A" : "True"
    output_str = cb.output === nothing ? "N/A" : "True"
    error_str = cb.error === nothing ? "N/A" : "True"
    count_lines = count(==('\n'), collect(cb.code)) + 1 # there is always at least one line

    print(io,
        "AICode(Success: $success_str, Parsed: $expression_str, Evaluated: $output_str, Error Caught: $error_str, StdOut: $stdout_str, Code: $count_lines Lines)")
end
function isparsed(cb::AICode)
    return isparsed(cb.expression) && !isparseerror(cb.error)
end

## Overload for AIMessage - simply extracts the code blocks and concatenates them
function AICode(msg::AIMessage;
        verbose::Bool = false,
        skip_invalid::Bool = false,
        kwargs...)
    code = extract_code_blocks(msg.content)
    if isempty(code)
        ## Fallback option for generic code fence, we must check if the content is parseable
        code = extract_code_blocks_fallback(msg.content)
        skip_invalid = true # set to true if we use fallback option
    end
    if skip_invalid
        ## Filter out extracted code blocks that do not even parse
        filter!(is_julia_code, code)
    end
    code = join(code, "\n")
    return AICode(code; verbose, kwargs...)
end

## # Functions

"""
    eval!(cb::AbstractCodeBlock;
        safe_eval::Bool = true,
        capture_stdout::Bool = true,
        prefix::AbstractString = "",
        suffix::AbstractString = "")

Evaluates a code block `cb` in-place. It runs automatically when AICode is instantiated with a String.

Check the outcome of evaluation with `Base.isvalid(cb)`. If `==true`, provide code block has executed successfully.

Steps:
- If `cb::AICode` has not been evaluated, `cb.success = nothing`. 
  After the evaluation it will be either `true` or `false` depending on the outcome
- Parse the text in `cb.code`
- Evaluate the parsed expression
- Capture outputs of the evaluated in `cb.output`
- [OPTIONAL] Capture any stdout outputs (eg, test failures) in `cb.stdout`
- If any error exception is raised, it is saved in `cb.error`
- Finally, if all steps were successful, success is set to `cb.success = true`

# Keyword Arguments
- `safe_eval::Bool`: If `true`, we first check for any Pkg operations (eg, installing new packages) and missing imports, 
  then the code will be evaluated inside a bespoke scratch module (not to change any user variables)
- `capture_stdout::Bool`: If `true`, we capture any stdout outputs (eg, test failures) in `cb.stdout`
- `prefix::AbstractString`: A string to be prepended to the code block before parsing and evaluation.
  Useful to add some additional code definition or necessary imports. Defaults to an empty string.
- `suffix::AbstractString`: A string to be appended to the code block before parsing and evaluation. 
  Useful to check that tests pass or that an example executes. Defaults to an empty string.
"""
function eval!(cb::AbstractCodeBlock;
        safe_eval::Bool = true,
        capture_stdout::Bool = true,
        prefix::AbstractString = "",
        suffix::AbstractString = "",
        expression_transform::Symbol = :nothing)
    @assert expression_transform in (:nothing, :remove_all_tests, :remove_test_items) "expression_transform must be one of :nothing, :remove_all_tests, :remove_test_items"
    (; code) = cb
    # reset
    cb.expression = nothing
    cb.output = nothing
    cb.stdout = nothing

    ## Safety checks on `code` only -- treat it as a parsing failure
    if safe_eval
        detected, missing_packages = detect_missing_packages(extract_julia_imports(code))
        if detect_pkg_operation(code) || detected
            cb.success = false
            detect_pkg_operation(code) &&
                (cb.error = ErrorException("Safety Error: Use of package manager (`Pkg.*`) detected! Please verify the safety of the code or disable the safety check (`safe_eval=false`)"))
            detected &&
                (cb.error = ErrorException("Safety Error: Failed package import. Missing packages: $(join(string.(missing_packages),", ")). Please add them or disable the safety check (`safe_eval=false`)"))
            return cb
        end
        detected, overrides = detect_base_main_overrides(code)
        if detected
            ## DO NOT THROW ERROR
            @warn "Safety Warning: Base / Main overrides detected (functions: $(join(overrides,",")))! Please verify the safety of the code or disable the safety check (`safe_eval=false`)"
        end
    end
    ## Catch bad code extraction
    if isempty(code)
        cb.error = ErrorException("Parse Error: No code found!")
        cb.success = false
        return cb
    end

    ## Parsing test, if it fails, we skip the evaluation
    try
        ex = Meta.parseall(code)
        cb.expression = ex
        if !isparsed(ex)
            cb.error = @eval(Main, $(ex)) # show the error
            cb.success = false
            return cb
        end
    catch e
        cb.error = e
        cb.success = false
        return cb
    end

    ## Pick the right expression transform (if any)
    _transform = if expression_transform == :nothing
        "identity"
    elseif expression_transform == :remove_all_tests
        "PromptingTools.remove_all_tests_from_expr!"
    elseif expression_transform == :remove_test_items
        "PromptingTools.remove_test_items_from_expr!"
    end

    ## Add prefix and suffix
    ## Write the code as an `include_string` in a module (into `io`)
    io = IOBuffer()
    module_name = safe_eval ? replace(string(gensym("SafeMod")), "#" => "") : "Main"
    safe_eval && write(io, "module $module_name\n")
    write(io, "using Test\nimport PromptingTools\n")
    write(io, prefix, "\n")
    write(io,
        "include_string($_transform, $module_name,\"\"\"$(escape_string(code,'$'))\"\"\", \"__code_string_eval\")\n")
    write(io, suffix, "\n")
    safe_eval && write(io, "end")
    code_full = String(take!(io))

    ## Eval (we parse the full code now, including the prefix and suffix)
    # TODO: can fail if provided prefix/suffix are invalid and break the parsing, 
    # but they are assumed to be correct as they are user-provided
    cb.expression = Meta.parseall(code_full)
    eval!(cb, cb.expression; capture_stdout, eval_module = Main)
    return cb
end

# Evaluation of any arbitrary expression with result recorded in `cb`
function eval!(cb::AbstractCodeBlock, expr::Expr;
        capture_stdout::Bool = true,
        eval_module::Module = Main)
    ## Reset
    cb.success = nothing
    cb.error = nothing
    cb.output = nothing
    cb.stdout = nothing
    empty!(cb.error_lines)

    # Prepare to catch any stdout
    if capture_stdout
        pipe = Pipe()
        redirect_stdout(pipe) do
            try
                cb.output = @eval(eval_module, $(expr))
                cb.success = true
            catch e
                cb.error = e
                cb.success = false
            end
        end
        close(Base.pipe_writer(pipe))
        cb.stdout = read(pipe, String)
    else
        # Ignore stdout, just eval
        try
            cb.output = @eval(eval_module, $(expr))
            cb.success = true
        catch e
            cb.error = e
            cb.success = false
        end
    end
    ## showerror if stdout capture failed
    if (isnothing(cb.stdout) || isempty(cb.stdout)) && !isnothing(cb.error)
        io = IOBuffer()
        showerror(io, cb.error isa LoadError ? cb.error.error : cb.error)
        cb.stdout = String(take!(io))
    end
    ## unwrap load error
    if cb.error isa LoadError
        push!(cb.error_lines, cb.error.line)
        for line in extract_stacktrace_lines(cb.error.file, cb.stdout)
            (line ∉ cb.error_lines) && push!(cb.error_lines, line)
        end
        cb.error = cb.error.error
    elseif !isnothing(cb.error)
        ## fallback, looks for errors only in the original code (cb.code)
        lines = extract_stacktrace_lines("__code_string_eval", cb.stdout)
        for line in lines
            (line ∉ cb.error_lines) && push!(cb.error_lines, line)
        end
    end
    return cb
end
