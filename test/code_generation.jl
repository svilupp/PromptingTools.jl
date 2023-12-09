using PromptingTools: extract_julia_imports
using PromptingTools: detect_pkg_operation, detect_missing_packages, extract_function_name
using PromptingTools: has_julia_prompt, remove_julia_prompt, extract_code_blocks, eval!
using PromptingTools: escape_interpolation, find_subsequence_positions

@testset "extract_imports tests" begin
    @test extract_julia_imports("using Test, LinearAlgebra") ==
          Symbol.(["Test", "LinearAlgebra"])
    @test extract_julia_imports("import Test\nimport ABC,DEF\nusing GEM: func") ==
          Symbol.(["Test", "ABC", "DEF", "GEM"])
    @test extract_julia_imports("import PackageA.PackageB: funcA\nimport PackageC") ==
          Symbol.(["PackageA.PackageB", "PackageC"])
end

@testset "detect_missing_packages" begin
    @test detect_missing_packages(Symbol[]) == (false, Symbol[])
    @test detect_missing_packages(Symbol.(["Test"])) == (false, Symbol[])
    @test detect_missing_packages(Symbol.(["Test", "Base", "Main"])) == (false, Symbol[])
    @test detect_missing_packages(Symbol.(["Test",
        "Base",
        "Main",
        "SpecialPackage12345678", "SpecialPackage123456789"])) == (true, [:SpecialPackage12345678, :SpecialPackage123456789])
end

@testset "detect_pkg_operation" begin
    @test detect_pkg_operation("Pkg.activate(\".\")") == true
    @test detect_pkg_operation("Pkg.add(\"SomePkg\")") == true
    @test detect_pkg_operation("blabla Pkg.activate(\".\")") == true
    @test detect_pkg_operation("hello world;") == false
    @test detect_pkg_operation("import Pkg;") == false
end

@testset "has_julia_prompt" begin
    @test has_julia_prompt("julia> a=1")
    @test has_julia_prompt("""
# something else first
julia> a=1
""")
    @test !has_julia_prompt("""
    # something
    # new
    a=1
    """)
end

@testset "remove_julia_prompt" begin
    @test remove_julia_prompt("julia> a=1") == "a=1"
    @test remove_julia_prompt("""
# something else first
julia> a=1
# output
""") == "a=1"
    @test remove_julia_prompt("""
    # something
    # new
    a=1
    """) == """
    # something
    # new
    a=1
    """
    @test remove_julia_prompt("""
julia> a=\"\"\"
 hey
 there
 \"\"\"
"hey\nthere\n"
  """) == """
a=\"\"\"
 hey
 there
 \"\"\""""
end

@testset "escape_interpolation" begin
    @test escape_interpolation("aaa") == "aaa"
    @test escape_interpolation("\$") == String(['\\', '$'])
end

@testset "find_subsequence_positions" begin
    # Test 1: Basic functionality
    @test find_subsequence_positions(codeunits("ab"), codeunits("cababcab")) == [2, 4, 7]

    # Test 2: Subsequence not in sequence
    @test find_subsequence_positions(codeunits("xyz"), codeunits("hello")) == []

    # Test 3: Empty subsequence -- should return all positions+1
    @test find_subsequence_positions(codeunits(""), codeunits("hello")) == 1:6

    # Test 4: Subsequence longer than sequence
    @test find_subsequence_positions(codeunits("longsubsequence"), codeunits("short")) == []

    # Test 5: Repeated characters
    @test find_subsequence_positions(codeunits("ana"), codeunits("banana")) == [2, 4]
    @test find_subsequence_positions(codeunits("a"), codeunits("a"^6)) == 1:6
end

@testset "extract_code_blocks" begin
    # Single Julia Code Block
    markdown_content = """
    # Example
    ```julia
    println("Hello, World!")
    ```
    """
    @test extract_code_blocks(markdown_content) ==
          SubString{String}["println(\"Hello, World!\")"]

    # Multiple Julia Code Blocks
    markdown_content = """
    ```julia
    println("First Block")
    ```
    Some text here.
    ```julia
    println("Second Block")
    ```
    """
    @test extract_code_blocks(markdown_content) ==
          SubString{String}["println(\"First Block\")", "println(\"Second Block\")"]

    # No Julia Code Blocks
    markdown_content = """
    This is a text without Julia code blocks.
    """
    @test isempty(extract_code_blocks(markdown_content))

    # Mixed Language Code Blocks
    markdown_content = """
    ```python
    print("This is Python")
    ```
    ```julia
    println("This is Julia")
    ```
    """
    @test extract_code_blocks(markdown_content) ==
          SubString{String}["println(\"This is Julia\")"]

    # Nested Blocks (plain block outer)
    markdown_content = """
    ```
    ```julia
    println("Nested Block")
    ```
    ```
    """
    @test extract_code_blocks(markdown_content) ==
          SubString{String}["println(\"Nested Block\")"]

    # Nested Julia code blocks
    markdown_example = """
    ```julia
    # Outer Julia code block

    # An example of a nested Julia code block in markdown
    \"\"\"
    ```julia
    x = 5
    println(x)
    ```
    \"\"\"

    y = 10
    println(y)
    ```
    """
    @test extract_code_blocks(markdown_example) ==
          SubString{String}["# Outer Julia code block\n\n# An example of a nested Julia code block in markdown\n\"\"\"\n```julia\nx = 5\nprintln(x)\n```\n\"\"\"\n\ny = 10\nprintln(y)"]
end

@testset "extract_function_name" begin
    # Test 1: Test an explicit function declaration
    @test extract_function_name("function testFunction1()\nend") == "testFunction1"

    # Test 2: Test a concise function declaration
    @test extract_function_name("testFunction2() = 42") == "testFunction2"

    # Test 3: Test a code block with no function
    @test extract_function_name("let a = 10\nb = 20\nend") === nothing

    # Test 4: Test a code block with a multiline function and comments
    @test extract_function_name("""
    # Comment line
    function testFunction3(arg1, arg2)
        # Function body
        return arg1 + arg2
    end
    """) == "testFunction3"

    # Test 5: Test a code block with multiple functions, should return the first function's name
    @test extract_function_name("""
    function firstFunction()
    end

    function secondFunction()
    end
    """) == "firstFunction"
end

@testset "eval!" begin
    # Test that it captures stdout and output
    let cb = AICode(; code = """
      println("Hello")
      a=1
      """)
        eval!(cb)
        @test !isnothing(cb.expression)
        @test isnothing(cb.error)
        @test cb.success == true
        @test isvalid(cb)
        @test cb.stdout == "Hello\n"
        @test cb.output.a == 1
    end
    # Test that it captures parsing errors
    let cb = AICode(; code = """
      a=1 +
      mla;sda b=2
      """)
        eval!(cb)
        @test cb.success == false
        @test !isvalid(cb)
        @test cb.error isa Exception # can be Base.Meta.ParseError or ErrorException depending on Julia version
    end
    # Test that it captures execution errors
    let cb = AICode(; code = """
      a=1 + b # b not defined yet
      b=2
      """)
        eval!(cb)
        @test cb.success == false
        @test cb.error == UndefVarError(:b)
        @test !isnothing(cb.expression) # parsed
    end
end
## Addition, needs to be outside of @testset
# Test that it captures test failures, we need to move it to the main file as it as it doesn't work inside a testset
# let cb = AICode(; code = """
#   @test 1==2
#   """)
#     eval!(cb)
#     @test cb.success == false
#     @info cb.error cb.output
#     @test cb.error isa Test.FallbackTestSetException
#     @test !isnothing(cb.expression) # parsed
#     @test occursin("Test Failed", cb.stdout) # capture details of the test failure
#     @test isnothing(cb.output) # because it failed
# end

@testset "eval! kwargs" begin
    ## Safe Eval == true mode
    # package that is not available
    cb = AICode(; code = "using ExoticPackage123") |> eval!
    @test cb.error isa Exception
    @test occursin("Safety Error", cb.error.msg)
    @test occursin("ExoticPackage123", cb.error.msg)
    # Pkg operations
    cb = AICode(; code = "Pkg.activate(\".\")") |> eval!
    @test cb.error isa Exception
    @test occursin("Safety Error", cb.error.msg)
    @test occursin("Use of package manager ", cb.error.msg)

    # Evaluate inside a gensym'd module
    cb = AICode(; code = "a=1") |> eval!
    @test occursin("SafeCustomModule", string(cb.output))

    ## Safe Eval == false mode
    # package that is not available
    cb = AICode(; code = "using ExoticPackage123")
    eval!(cb; safe_eval = false)
    @test !isvalid(cb)
    @test cb.error isa ArgumentError # now it's caught by REPL that we don't have the package
    # Pkg operations
    cb = AICode(; code = "import Pkg; Pkg.status()")
    eval!(cb; safe_eval = false)
    # This works but in test mode, Julia claims it doesn't have Pkg package...
    # @test isvalid(cb)
    # Evaluate in Main directly
    cb = AICode(; code = "a123=123")
    eval!(cb; safe_eval = false)
    @test cb.output == 123
    @test a123 == 123

    # Test prefix and suffix
    cb = AICode(; code = "")
    eval!(cb; prefix = "a=1", suffix = "b=2")
    @test cb.output.a == 1
    @test cb.output.b == 2
end

@testset "AICode constructors" begin
    # Initiate from provided text
    let cb = AICode("""
        println("Hello")
        a=1
        """)
        # eval! is automatic
        @test !isnothing(cb.expression)
        @test isnothing(cb.error)
        @test cb.success == true
        @test cb.stdout == "Hello\n"
        @test cb.output.a == 1
    end

    # Test auto-eval=false
    let cb = AICode("""
        println("Hello")
        a=1
        """; auto_eval = false)
        # eval! is automatic
        @test isnothing(cb.expression)
        @test isnothing(cb.error)
        @test cb.success == nothing
    end

    # From AI Message
    let msg = AIMessage("""
```julia
println(\"hello\")
```
Some text
```julia
println(\"world\")
b=2
```
""")
        cb = AICode(msg)
        @test !isnothing(cb.expression)
        @test isnothing(cb.error)
        @test cb.success == true
        @test cb.stdout == "hello\nworld\n"
        @test cb.output.b == 2
    end

    # Methods - copy
    let msg = AIMessage("""
        ```julia
        println(\"hello\")
        ```
        Some text
        ```julia
        println(\"world\")
        b=2
        ```
        """)
        cb = AICode(msg)
        cb_copy = Base.copy(cb)
        @test cb_copy.code == cb.code
        @test cb_copy !== cb
    end
end
