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

# Utility to detect if Pkg.* is called in a string (for `safe` code evaluation)
function detect_pkg_operation(input::AbstractString)
    m = match(r"^\s*\bPkg.[a-z]"ms, input)
    return !isnothing(m)
end
# Utility to detect dependencies in a string (for `safe` code evaluation / understand when we don't have a necessary package)
"""
    extract_julia_imports(input::AbstractString; base_or_main::Bool = false)

Detects any `using` or `import` statements in a given string and returns the package names as a vector of symbols. 

`base_or_main` is a boolean that determines whether to isolate only `Base` and `Main` OR whether to exclude them in the returned vector.
"""
function extract_julia_imports(input::AbstractString; base_or_main::Bool = false)
    package_names = Symbol[]
    for line in split(input, "\n")
        if occursin(r"(^using |^import )"m, line)
            subparts = replace(replace(line, "using" => ""), "import" => "")
            ## TODO: add split on .
            subparts = map(x -> contains(x, ':') ? split(x, ':')[1] : x,
                split(subparts, ","))
            subparts = replace(join(subparts, ' '), ',' => ' ')
            packages = filter(x -> !isempty(x), split(subparts, " "))
            if base_or_main
                ## keep only them
                packages = filter(
                    x -> startswith(x, "Base") ||
                        startswith(x, "Main"), packages)
            else
                ## exclude them
                packages = filter(
                    x -> !startswith(x, "Base") &&
                        !startswith(x, "Main"), packages)
            end
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
    filtered_positions = filter(
        inner -> !any(outer -> (outer[1] < inner[1]) &&
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

To capture all function names in the block, use `extract_function_names`.

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
    pattern_explicit = r"^\s*function\s+([\w\.\_]+)\("m
    # Regular expression for the concise function declaration
    pattern_concise = r"^\s*([\w\.\_]+)\(.*\)\s*="m

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
    extract_function_names(code_block::AbstractString)

Extract one or more names of functions defined in a given Julia code block. The function searches for two patterns:
    - The explicit function declaration pattern: `function name(...) ... end`
    - The concise function declaration pattern: `name(...) = ...`

It always returns a vector of strings, even if only one function name is found (it will be empty).

For only one function name match, use `extract_function_name`.
"""
function extract_function_names(code_block::AbstractString)
    # Regular expression for the explicit function declaration
    pattern_explicit = r"^\s*function\s+([\w\.\_]+)\("m
    # Regular expression for the concise function declaration
    pattern_concise = r"^\s*([\w\.\_]+)\(.*\)\s*="m

    matches = String[]

    # Searching for the explicit function declaration
    for m in eachmatch(pattern_explicit, code_block)
        push!(matches, m.captures[1])
    end
    # Searching for the concise function declaration
    for m in eachmatch(pattern_concise, code_block)
        push!(matches, m.captures[1])
    end

    return matches
end

"""
    detect_base_main_overrides(code_block::AbstractString)

Detects if a given code block overrides any Base or Main methods. 
    
Returns a tuple of a boolean and a vector of the overriden methods.
"""
function detect_base_main_overrides(code_block::AbstractString)
    funcs = extract_function_names(code_block)
    base_imports = extract_julia_imports(code_block; base_or_main = true) .|>
                   x -> split(string(x), ".")[end]
    ## check Base/Main method overrides
    overriden_methods = filter(
        f -> occursin("Base.", f) || occursin("Main.", f) ||
                 in(f, base_imports),
        funcs)
    detected = !isempty(overriden_methods)
    return detected, overriden_methods
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

function extract_package_name_from_argerror(error_msg::AbstractString)
    # Define a regex pattern to match the package name
    pattern = r"^Package\s+([^\s]+)\s+not found"

    # Search for the pattern in the error message
    match_result = match(pattern, error_msg)

    # Check if a match was found and return the captured group
    !isnothing(match_result) ? match_result.captures[1] : nothing
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
