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
    AICode(code::AbstractString; auto_eval::Bool=true, safe_eval::Bool=false, prefix::AbstractString="", suffix::AbstractString="")

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
- `prefix::AbstractString`: A string to be prepended to the code block before parsing and evaluation.
  Useful to add some additional code definition or necessary imports. Defaults to an empty string.
- `suffix::AbstractString`: A string to be appended to the code block before parsing and evaluation. 
  Useful to check that tests pass or that an example executes. Defaults to an empty string.

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
end
# Eager evaluation if instantiated with a string
function (CB::Type{T})(md::AbstractString;
        auto_eval::Bool = true,
        safe_eval::Bool = true,
        prefix::AbstractString = "",
        suffix::AbstractString = "") where {T <: AbstractCodeBlock}
    cb = CB(; code = md)
    auto_eval && eval!(cb; safe_eval, prefix, suffix)
    return cb
end
Base.isvalid(cb::AbstractCodeBlock) = cb.success == true
function Base.copy(cb::AbstractCodeBlock)
    AICode(cb.code, cb.expression, cb.stdout, cb.output, cb.success, cb.error)
end
function Base.show(io::IO, cb::AICode)
    success_str = cb.success === nothing ? "N/A" : titlecase(string(cb.success))
    expression_str = cb.expression === nothing ? "N/A" : "True"
    stdout_str = cb.stdout === nothing ? "N/A" : "True"
    output_str = cb.output === nothing ? "N/A" : "True"
    error_str = cb.error === nothing ? "N/A" : "True"
    count_lines = count(==('\n'), collect(cb.code)) + 1 # there is always at least one line

    print(io,
        "AICode(Success: $success_str, Parsed: $expression_str, Evaluated: $output_str, Error Caught: $error_str, StdOut: $stdout_str, Code: $count_lines Lines)")
end

## Overload for AIMessage - simply extracts the code blocks and concatenates them
function AICode(msg::AIMessage; kwargs...)
    code = extract_code_blocks(msg.content) |> Base.Fix2(join, "\n")
    return AICode(code; kwargs...)
end

## # Functions

# Utility to detect if Pkg.* is called in a string (for `safe` code evaluation)
function detect_pkg_operation(input::AbstractString)
    m = match(r"\bPkg.[a-z]", input)
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
            packages = filter(!isempty, split(subparts, " ")) .|> Symbol
            append!(package_names, packages)
        end
    end
    return package_names
end

# Utility to pinpoint unavailable dependencies
function detect_missing_packages(imports_required::AbstractVector{<:Symbol})
    available_packages = Base.loaded_modules |> values .|> Symbol
    missing_packages = filter(pkg -> !in(pkg, available_packages), imports_required)
    if length(missing_packages) > 0
        return true, missing_packages
    else
        return false, Symbol[]
    end
end

"Checks if a given string has a Julia prompt (`julia> `) at the beginning of a line."
has_julia_prompt(s::T) where {T <: AbstractString} = occursin(r"^julia> "m, s)

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
    start_delim_units = codeunits("```julia")
    end_delim_units = codeunits("```")

    # Find all starting and ending positions of code blocks
    start_positions = find_subsequence_positions(start_delim_units, content_units)
    end_positions = setdiff(find_subsequence_positions(end_delim_units, content_units),
        start_positions)
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
    code_blocks = SubString{T}[]
    for (start_pos, end_pos) in filtered_positions
        code_block = markdown_content[(start_pos + length(start_delim_units)):(end_pos - 1)]
        # Also remove the julia prompt
        push!(code_blocks, remove_julia_prompt(strip(code_block)))
    end

    return reverse(code_blocks) # Reverse to maintain original order
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

"""
    eval!(cb::AICode; safe_eval::Bool=true, prefix::AbstractString="", suffix::AbstractString="")

Evaluates a code block `cb` in-place. It runs automatically when AICode is instantiated with a String.

Check the outcome of evaluation with `Base.isvalid(cb)`. If `==true`, provide code block has executed successfully.

Steps:
- If `cb::AICode` has not been evaluated, `cb.success = nothing`. 
  After the evaluation it will be either `true` or `false` depending on the outcome
- Parse the text in `cb.code`
- Evaluate the parsed expression
- Capture outputs of the evaluated in `cb.output`
- Capture any stdout outputs (eg, test failures) in `cb.stdout`
- If any error exception is raised, it is saved in `cb.error`
- Finally, if all steps were successful, success is set to `cb.success = true`

# Keyword Arguments
- `safe_eval::Bool`: If `true`, we first check for any Pkg operations (eg, installing new packages) and missing imports, 
  then the code will be evaluated inside a bespoke scratch module (not to change any user variables)
- `prefix::AbstractString`: A string to be prepended to the code block before parsing and evaluation.
  Useful to add some additional code definition or necessary imports. Defaults to an empty string.
- `suffix::AbstractString`: A string to be appended to the code block before parsing and evaluation. 
  Useful to check that tests pass or that an example executes. Defaults to an empty string.
"""
function eval!(cb::AbstractCodeBlock;
        safe_eval::Bool = true,
        prefix::AbstractString = "",
        suffix::AbstractString = "")
    (; code) = cb
    # reset
    cb.success = nothing
    cb.error = nothing
    cb.expression = nothing
    cb.output = nothing
    code_extra = string(prefix, "\n", code, "\n", suffix)
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
    ## Parse into an expression
    try
        ex = Meta.parseall(code_extra)
        cb.expression = ex
    catch e
        cb.error = e
        cb.success = false
        return cb
    end

    ## Eval
    safe_module = gensym("SafeCustomModule")
    # Prepare to catch any stdout
    pipe = Pipe()
    redirect_stdout(pipe) do
        try
            # eval in Main module to have access to std libs, but inside a custom module for safety
            if safe_eval
                cb.output = @eval(Main, module $safe_module
                using Test # just in case unit tests are provided
                $(cb.expression)
                end)
            else
                # Evaluate the code directly into Main
                cb.output = @eval(Main, begin
                    using Test # just in case unit tests are provided
                    $(cb.expression)
                end)
            end
            cb.success = true
        catch e
            cb.error = e
            cb.success = false
        end
    end
    close(Base.pipe_writer(pipe))
    cb.stdout = read(pipe, String)
    return cb
end