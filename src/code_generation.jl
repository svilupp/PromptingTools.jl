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
        eval!(cb;
            safe_eval,
            capture_stdout,
            prefix,
            suffix,
            expression_transform)
        # set to timeout in `execution_timeout` seconds
        # result = @timeout execution_timeout begin
        #     eval!(cb;
        #         safe_eval,
        #         capture_stdout,
        #         prefix,
        #         suffix,
        #         expression_transform)
        # end nothing # set to nothing if it fails
        # # Check if we timed out
        # if isnothing(result)
        #     cb.success = false
        #     cb.error = InterruptException()
        # end
    end
    if !isempty(removed)
        ## Add to STDOUT what we removed
        warning = string("!!! IMPORTANT: Unsafe lines blocked from execution (eg, Pkg operations or imports of non-existent packages):",
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
    AICode(cb.code, cb.expression, cb.stdout, cb.output, cb.success, cb.error)
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

## Parsing error detection
function isparsed(ex::Expr)
    parse_error = Meta.isexpr(ex, :toplevel) && !isempty(ex.args) &&
                  Meta.isexpr(ex.args[end], (:error, :incomplete))
    return !parse_error
end
function isparsed(ex::Nothing)
    return false
end
function isparseerror(err::Exception)
    return err isa Base.Meta.ParseError ||
           (err isa ErrorException && startswith(err.msg, "syntax:"))
end
function isparseerror(err::Nothing)
    return false
end
function isparsed(cb::AICode)
    return isparsed(cb.expression) && !isparseerror(cb.error)
end

## Parsing Helpers
JULIA_EXPR_HEADS = [
    :block,
    :quote,
    :call,
    :macrocall,
    :(=),
    :function,
    :for,
    :if,
    :while,
    :let,
    :try,
    :catch,
    :finally,
    :method,
    :tuple,
    :array,
    :index,
    :ref,
    :.,
    :do,
    :curly,
    :typed_vcat,
    :typed_hcat,
    :typed_vcat,
    :comprehension,
    :generator,
    :kw,
    :where,
]
# Checks if the provided expression `ex` has some hallmarks of Julia code. Very naive!
# Serves as a quick check to avoid trying to eval output cells (```plaintext ... ```)
is_julia_expr(ex::Any) = false
function is_julia_expr(ex::Expr)
    ## Expression itself
    Meta.isexpr(ex, JULIA_EXPR_HEADS) && return true
    ## Its arguments
    for arg in ex.args
        Meta.isexpr(arg, JULIA_EXPR_HEADS) && return true
    end
    ## Nothing found...
    return false
end

# Remove any given macro expression from the expression tree, used to remove tests
function remove_macro_expr!(expr, sym::Symbol = Symbol("@testset"))
    if expr isa Expr && expr.head == :macrocall && !isempty(expr.args) &&
       expr.args[1] == sym
        return Expr(:block)
    elseif expr isa Expr && !isempty(expr.args)
        expr.args = filter(x -> !(x isa Expr && x.head == :macrocall && !isempty(x.args) &&
                                  x.args[1] == sym),
            expr.args)
        foreach(x -> remove_macro_expr!(x, sym), expr.args)
    end
    expr
end

# Remove testsets and sets from the expression tree
function remove_test_items_from_expr!(expr)
    # Focus only on the three most common test macros 
    expr = remove_macro_expr!(expr, Symbol("@test"))
    expr = remove_macro_expr!(expr, Symbol("@test_throws"))
    return expr
end
function remove_all_tests_from_expr!(expr)
    # Focus only on the three most common test macros 
    expr = remove_macro_expr!(expr, Symbol("@testset"))
    expr = remove_test_items_from_expr!(expr)
    return expr
end

# Utility to identify the module name in a given expression (to evaluate subsequent calls in it)
function extract_module_name(expr)
    if isa(expr, Expr) && expr.head == :module
        return expr.args[2] # The second argument is typically the module name
    elseif isa(expr, Expr) && !isempty(expr.args)
        output = extract_module_name.(expr.args)
        for item in output
            if !isnothing(item)
                return item
            end
        end
    end
    nothing
end

## Check if a given String seems to be a valid Julia expression (simple heuristics)
function is_julia_code(code::AbstractString)
    # Try to parse the expression, return false if parsing fails
    expr = try
        Meta.parseall(code)
    catch
        return false
    end

    if isparsed(expr) && is_julia_expr(expr)
        return true
    else
        return false
    end
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

# Utility to detect if Pkg.* is called in a string (for `safe` code evaluation)
function detect_pkg_operation(input::AbstractString)
    m = match(r"^\s*\bPkg.[a-z]"ms, input)
    return !isnothing(m)
end
# Utility to detect dependencies in a string (for `safe` code evaluation / understand when we don't have a necessary package)
function extract_julia_imports(input::AbstractString)
    package_names = Symbol[]
    for line in split(input, "\n")
        if occursin(r"(^using |^import )"m, line)
            subparts = replace(replace(line, "using" => ""), "import" => "")
            ## TODO: add split on .
            subparts = map(x -> contains(x, ':') ? split(x, ':')[1] : x,
                split(subparts, ","))
            subparts = replace(join(subparts, ' '), ',' => ' ')
            packages = filter(x -> !isempty(x) && !startswith(x, "Base") &&
                                       !startswith(x, "Main"),
                split(subparts, " "))
            append!(package_names, Symbol.(packages))
        end
    end
    return package_names
end

# Utility to pinpoint unavailable dependencies
function detect_missing_packages(imports_required::AbstractVector{<:Symbol})
    # shortcut if no packages are required
    isempty(imports_required) && return false, Symbol[]
    #
    available_packages = Base.loaded_modules |> values .|> Symbol
    dependencies = Symbol[Symbol(p.name) for p in values(Pkg.dependencies())]
    missing_packages = Symbol[]
    for pkg in imports_required
        if !(pkg in available_packages || pkg in dependencies || hasproperty(Base, pkg) ||
             hasproperty(Main, pkg))
            push!(missing_packages, pkg)
        end
    end

    if length(missing_packages) > 0
        return true, missing_packages
    else
        return false, missing_packages
    end
end

"Iterates over the lines of a string and removes those that contain a package operation or a missing import."
function remove_unsafe_lines(code::AbstractString; verbose::Bool = false)
    io_keep, io_remove = IOBuffer(), IOBuffer()
    for line in readlines(IOBuffer(code))
        if !detect_pkg_operation(line) &&
           !detect_missing_packages(extract_julia_imports(line))[1]
            println(io_keep, line)
        else
            verbose && @info "Unsafe line removed: $line"
            println(io_remove, line)
        end
    end
    return String(take!(io_keep)), String(take!(io_remove))
end

"Checks if a given string has a Julia prompt (`julia> `) at the beginning of a line."
has_julia_prompt(s::T) where {T <: AbstractString} = occursin(r"(:?^julia> |^> )"m, s)

"""
    remove_julia_prompt(s::T) where {T<:AbstractString}

If it detects a julia prompt, it removes it and all lines that do not have it (except for those that belong to the code block).
"""
function remove_julia_prompt(s::T) where {T <: AbstractString}
    if !has_julia_prompt(s)
        return s
    end
    # Has julia prompt, so we need to parse it line by line
    lines = split(s, '\n')
    code_line = false
    io = IOBuffer()
    for line in lines
        if startswith(line, r"^julia> ")
            code_line = true
            # remove the prompt
            println(io, replace(line, "julia> " => ""))
        elseif startswith(line, r"^> ")
            code_line = true
            # remove the prompt
            println(io, replace(line, "> " => ""))
        elseif code_line && startswith(line, r"^ ")
            # continuation of the code line
            println(io, line)
        else
            code_line = false
        end
    end
    # strip removes training whitespace and newlines
    String(take!(io)) |> strip
end

# escape dollar sign only if not preceeded by backslash already, ie, unescaped -- use negative lookbehind
# Useful in cases where we have double nested interpolation, eg, string code -> has string literal -> function with interpolation inside it
escape_interpolation(s::AbstractString) = replace(s, r"(?<!\\)\$" => String(['\\', '$']))

"""
    find_subsequence_positions(subseq, seq) -> Vector{Int}

Find all positions of a subsequence `subseq` within a larger sequence `seq`. Used to lookup positions of code blocks in markdown.

This function scans the sequence `seq` and identifies all starting positions where the subsequence `subseq` is found. Both `subseq` and `seq` should be vectors of integers, typically obtained using `codeunits` on strings.

# Arguments
- `subseq`: A vector of integers representing the subsequence to search for.
- `seq`: A vector of integers representing the larger sequence in which to search.

# Returns
- `Vector{Int}`: A vector of starting positions (1-based indices) where the subsequence is found in the sequence.

# Examples
```julia
find_subsequence_positions(codeunits("ab"), codeunits("cababcab")) # Returns [2, 5]
```
"""
function find_subsequence_positions(subseq, seq)
    positions = Int[]
    len_subseq = length(subseq)
    len_seq = length(seq)
    lim = len_seq - len_subseq + 1
    cur = 1
    while cur <= lim
        match = true
        @inbounds for i in 1:len_subseq
            if seq[cur + i - 1] != subseq[i]
                match = false
                break
            end
        end
        if match
            push!(positions, cur)
        end
        cur += 1
    end
    return positions
end

"""
    extract_code_blocks(markdown_content::String) -> Vector{String}

Extract Julia code blocks from a markdown string.

This function searches through the provided markdown content, identifies blocks of code specifically marked as Julia code 
(using the ```julia ... ``` code fence patterns), and extracts the code within these blocks. 
The extracted code blocks are returned as a vector of strings, with each string representing one block of Julia code. 

Note: Only the content within the code fences is extracted, and the code fences themselves are not included in the output.

See also: `extract_code_blocks_fallback`

# Arguments
- `markdown_content::String`: A string containing the markdown content from which Julia code blocks are to be extracted.

# Returns
- `Vector{String}`: A vector containing strings of extracted Julia code blocks. If no Julia code blocks are found, an empty vector is returned.

# Examples

Example with a single Julia code block
```julia
markdown_single = \"""
```julia
println("Hello, World!")
```
\"""
extract_code_blocks(markdown_single)
# Output: [\"Hello, World!\"]
```

```julia
# Example with multiple Julia code blocks
markdown_multiple = \"""
```julia
x = 5
```
Some text in between
```julia
y = x + 2
```
\"""
extract_code_blocks(markdown_multiple)
# Output: ["x = 5", "y = x + 2"]
```
"""
function extract_code_blocks(markdown_content::T) where {T <: AbstractString}
    # Convert content and delimiters to codeunits
    content_units = codeunits(markdown_content)
    # Ideal code fences
    start_delim_units1 = codeunits("\n```julia\n")
    start_delim_units2 = codeunits("```julia\n")
    start_delim_units3 = codeunits("```julia ") # happens to small models
    end_delim_units1 = codeunits("\n```\n")
    end_delim_units2 = codeunits("\n```")

    # Find all starting and ending positions of code blocks
    pos = find_subsequence_positions(start_delim_units1, content_units)
    pos2 = find_subsequence_positions(start_delim_units2, content_units)
    pos3 = find_subsequence_positions(start_delim_units3, content_units)
    # the +1 offset is because the first pattern starts 1 character earlier
    start_positions = vcat(pos2, pos .+ 1, pos3) |> unique |> sort

    pos = find_subsequence_positions(end_delim_units1, content_units)
    pos2 = find_subsequence_positions(end_delim_units2, content_units)
    end_positions = vcat(pos, pos2) |> unique
    unused_end_positions = trues(length(end_positions))

    # Generate code block position pairs
    block_positions = Tuple{Int, Int}[]
    for start_pos in reverse(start_positions)
        for (i, end_pos) in enumerate(end_positions)
            if end_pos > start_pos && unused_end_positions[i]
                push!(block_positions, (start_pos, end_pos))
                unused_end_positions[i] = false
                break
            end
        end
    end

    # Filter out nested blocks (only if they have full overlap)
    filtered_positions = filter(inner -> !any(outer -> (outer[1] < inner[1]) &&
                (inner[2] < outer[2]),
            block_positions),
        block_positions)

    # Extract code blocks
    eltype_ = typeof(@view(markdown_content[begin:end]))
    code_blocks = Vector{eltype_}()
    for (start_pos, end_pos) in filtered_positions
        start_ = (start_pos + length(start_delim_units2))
        end_ = prevind(markdown_content, end_pos)
        code_block = markdown_content[start_:end_]
        # Also remove the julia prompt
        push!(code_blocks, remove_julia_prompt(strip(code_block)))
    end

    return reverse(code_blocks) # Reverse to maintain original order
end

"""
    extract_code_blocks_fallback(markdown_content::String, delim::AbstractString="\\n```\\n")

Extract Julia code blocks from a markdown string using a fallback method (splitting by arbitrary `delim`-iters).
Much more simplistic than `extract_code_blocks` and does not support nested code blocks.

It is often used as a fallback for smaller LLMs that forget to code fence ```julia ... ```.

# Example

```julia
code = \"\"\"
\`\`\`
println("hello")
\`\`\`

Some text

\`\`\`
println("world")
\`\`\`
\"\"\"

# We extract text between triple backticks and check each blob if it looks like a valid Julia code
code_parsed = extract_code_blocks_fallback(code) |> x -> filter(is_julia_code, x) |> x -> join(x, "\n")
```
"""
function extract_code_blocks_fallback(markdown_content::T,
        delim::AbstractString = "\n```\n") where {T <: AbstractString}
    # Convert content and delimiters to codeunits
    content_units = codeunits(markdown_content)
    content_length = length(content_units)
    delim_units = codeunits(delim)
    delim_positions = find_subsequence_positions(delim_units, content_units)

    # Extract code blocks
    eltype_ = typeof(@view(markdown_content[begin:end]))
    code_blocks = Vector{eltype_}()
    isempty(delim_positions) && !startswith(markdown_content, lstrip(delim)) &&
        return code_blocks

    # Run the extraction
    # catch if we're missing the opening mark because of document start
    no_newline_start = lstrip(delim)
    start_pos = if no_newline_start != delim &&
                   startswith(markdown_content, no_newline_start)
        (length(codeunits(no_newline_start)) - length(delim_units))
    else
        delim_positions[1]
    end
    no_new_line_end = rstrip(delim)
    if no_new_line_end != delim && endswith(markdown_content, no_new_line_end)
        last_end = 1 + content_length - length(codeunits(no_new_line_end))
        push!(delim_positions, last_end)
    end
    # start the iteration
    for end_pos in unique(delim_positions)
        if end_pos > start_pos && end_pos <= content_length
            end_ = prevind(markdown_content, end_pos)
            code_block = markdown_content[(start_pos + length(delim_units)):end_]
            # Also remove the julia prompt
            push!(code_blocks, remove_julia_prompt(strip(code_block)))
            # Reset the start
            start_pos = end_pos
        end
    end

    return code_blocks
end

"""
    extract_function_name(code_block::String) -> Union{String, Nothing}

Extract the name of a function from a given Julia code block. The function searches for two patterns:
- The explicit function declaration pattern: `function name(...) ... end`
- The concise function declaration pattern: `name(...) = ...`

If a function name is found, it is returned as a string. If no function name is found, the function returns `nothing`.

# Arguments
- `code_block::String`: A string containing Julia code.

# Returns
- `Union{String, Nothing}`: The extracted function name or `nothing` if no name is found.

# Example
```julia
code = \"""
function myFunction(arg1, arg2)
    # Function body
end
\"""
extract_function_name(code)
# Output: "myFunction"
```
"""
function extract_function_name(code_block::AbstractString)
    # Regular expression for the explicit function declaration
    pattern_explicit = r"function\s+(\w+)\("
    # Regular expression for the concise function declaration
    pattern_concise = r"^(\w+)\(.*\)\s*="

    # Searching for the explicit function declaration
    match_explicit = match(pattern_explicit, code_block)
    if match_explicit !== nothing
        return match_explicit.captures[1]
    end

    # Searching for the concise function declaration
    match_concise = match(pattern_concise, code_block)
    if match_concise !== nothing
        return match_concise.captures[1]
    end

    # Return nothing if no function name is found
    return nothing
end

function extract_testset_name(testset_str::AbstractString)
    # Define a regex pattern to match the function name
    pattern = r"^\s*@testset\s*\"([^\"]+)\"\s* begin"ms

    # Search for the pattern in the test set string
    match_result = match(pattern, testset_str)

    # Check if a match was found and return the captured group
    result = if match_result !== nothing
        match_result.captures[1]
    else
        nothing
    end
    return result
end
# testset_str = """
# @testset "pig_latinify" begin
#     output = pig_latinify("hello")
#     expected = "ellohay"
#     @test output == expected
# end
# """
# @test extract_testset_name(testset_str) == "pig_latinify"

function extract_package_name_from_argerror(error_msg::AbstractString)
    # Define a regex pattern to match the package name
    pattern = r"^Package\s+([^\s]+)\s+not found"

    # Search for the pattern in the error message
    match_result = match(pattern, error_msg)

    # Check if a match was found and return the captured group
    !isnothing(match_result) ? match_result.captures[1] : nothing
end
# error_msg = "Package Threads not found in current path, maybe you meant `import/using .Threads`.\n- Otherwise, run `import Pkg; Pkg.add(\"Threads\")` to install the Threads package."
# extract_package_name_from_argerror(error_msg) == "Threads"

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

    io = IOBuffer()
    module_name = safe_eval ? replace(string(gensym("SafeMod")), "#" => "") : "Main"
    safe_eval && write(io, "module $module_name\n")
    write(io, "using Test\nimport PromptingTools\n")
    write(io, prefix, "\n")
    write(io,
        "include_string($_transform, $module_name,\"\"\"$(escape_string(code))\"\"\", \"__code_string_eval\")\n")
    write(io, suffix, "\n")
    safe_eval && write(io, "end")
    code_full = String(take!(io))

    ## Eval (we parse the full code now, including the prefix and suffix)
    # TODO: can fail if prefix/suffix are invalid
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
    ## unwrap load error
    if cb.error isa LoadError
        push!(cb.error_lines, cb.error.line)
        append!(cb.error_lines, extract_stacktrace_lines(cb.error.file, cb.stdout))
        cb.error = cb.error.error
    elseif !isnothing(cb.error)
        append!(cb.error_lines, extract_stacktrace_lines("__code_string_eval", cb.stdout))
    end
    return cb
end

# overload for missing stdout
extract_stacktrace_lines(filename::String, stacktrace::Nothing) = Int[]
function extract_stacktrace_lines(filename::String, stacktrace::String)
    # Pattern to match the filename and line numbers
    pattern = Regex(escape_string(filename) * ":(\\d+)")

    # Extracting line numbers from the matches
    line_numbers = Int[parse(Int, m.captures[1]) for m in eachmatch(pattern, stacktrace)]

    return line_numbers
end
