using PromptingTools: extract_julia_imports
using PromptingTools: detect_pkg_operation,
                      detect_missing_packages, extract_function_name,
                      extract_function_names,
                      remove_unsafe_lines, detect_base_main_overrides
using PromptingTools: has_julia_prompt,
                      remove_julia_prompt, extract_code_blocks,
                      extract_code_blocks_fallback, eval!
using PromptingTools: escape_interpolation, find_subsequence_positions
using PromptingTools: AICode, is_julia_code, is_julia_expr
using PromptingTools: extract_testset_name,
                      extract_package_name_from_argerror, extract_stacktrace_lines

@testset "is_julia_code" begin

    # Valid Julia Code
    @test is_julia_code("x = 1 + 2") == true
    @test is_julia_code("println(\"Hello, world!\")") == true
    @test is_julia_code("function foo()\nreturn 42\nend") == true

    # Invalid Julia Code
    @test is_julia_code("x ==== y") == false

    # Empty String
    @test is_julia_code("") == false

    # Non-Code Strings
    @test is_julia_code("This is a plain text, not a code.") == false

    # Complex Julia Expressions
    @test is_julia_code("for i in 1:10\nprintln(i)\nend") == true
    @test is_julia_code("if x > 0\nprintln(\"positive\")\nelse\nprintln(\"non-positive\")\nend") ==
          true

    # Invalid Syntax
    @test is_julia_code("function foo() return 42") == false  # Missing 'end' keyword
end

@testset "extract_imports tests" begin
    @test extract_julia_imports("using Test, LinearAlgebra") ==
          Symbol.(["Test", "LinearAlgebra"])
    @test extract_julia_imports("import Test\nimport ABC,DEF\nusing GEM: func") ==
          Symbol.(["Test", "ABC", "DEF", "GEM"])
    @test extract_julia_imports("import PackageA.PackageB: funcA\nimport PackageC") ==
          Symbol.(["PackageA.PackageB", "PackageC"])
    @test extract_julia_imports("using Base.Threads\nusing Main.MyPkg") ==
          Symbol[]
    @test extract_julia_imports("using Base.Threads\nusing Main.MyPkg";
        base_or_main = true) == Symbol[Symbol("Base.Threads"), Symbol("Main.MyPkg")]
end

@testset "detect_missing_packages" begin
    @test detect_missing_packages(Symbol[]) == (false, Symbol[])
    @test detect_missing_packages(Symbol.(["Test"])) == (false, Symbol[])
    @test detect_missing_packages(Symbol.(["Test", "Base", "Main"])) == (false, Symbol[])
    @test detect_missing_packages(Symbol.(["Test",
        "Base",
        "Main",
        "SpecialPackage12345678", "SpecialPackage123456789"])) ==
          (true, [:SpecialPackage12345678, :SpecialPackage123456789])
end

@testset "detect_pkg_operation" begin
    @test detect_pkg_operation("Pkg.activate(\".\")") == true
    @test detect_pkg_operation("Pkg.add(\"SomePkg\")") == true
    @test detect_pkg_operation("   Pkg.activate(\".\")") == true
    @test detect_pkg_operation("hello world;") == false
    @test detect_pkg_operation("import Pkg;") == false
end

@testset "remove_unsafe_lines" begin
    @test remove_unsafe_lines("Pkg.activate(\".\")") == ("", "Pkg.activate(\".\")\n")
    @test remove_unsafe_lines("Pkg.add(\"SomePkg\")") == ("", "Pkg.add(\"SomePkg\")\n")
    s = """
    a=1
    Pkg.add("a")
    b=2
    Pkg.add("b")
    using 12315456NotExisting
    """
    @test remove_unsafe_lines(s) ==
          ("a=1\nb=2\n", "Pkg.add(\"a\")\nPkg.add(\"b\")\nusing 12315456NotExisting\n")
    @test remove_unsafe_lines("Nothing"; verbose = true) == ("Nothing\n", "")
end

@testset "has_julia_prompt" begin
    @test has_julia_prompt("julia> a=1")
    @test has_julia_prompt("> a=1")
    @test has_julia_prompt("""
# something else first
julia> a=1
""")
    @test has_julia_prompt("""
    > a=\"\"\"
     hey
     there
     \"\"\"
    """)
    @test !has_julia_prompt("""
    # something
    # new
    a=1
    """)
end

@testset "remove_julia_prompt" begin
    @test remove_julia_prompt("julia> a=1") == "a=1"
    @test remove_julia_prompt("> a=1") == "a=1"
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

    # at edges (no newlines)
    markdown_content = """```julia
println("hello")
```"""
    @test extract_code_blocks(markdown_content) ==
          SubString{String}["println(\"hello\")"]
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

    # Tough case of regex inside a function
    markdown_example = """
```julia
function find_match(md::AbstractString)
    return match(r"```\\n(?:(?!\\n```)\\s*.*\\n?)*\\s*```", md)
end
```
"""
    @test extract_code_blocks(markdown_example) ==
          SubString{String}["function find_match(md::AbstractString)\n    return match(r\"```\\n(?:(?!\\n```)\\s*.*\\n?)*\\s*```\", md)\nend"]

    # Some small models forget newlines
    no_newline = """
  ```julia function clean_column(col::AbstractString)
      col = strip(lowercase(col))
      col = replace(col, r"[-\\s]+", "_")
      col
  end
  ```
  """
    @test extract_code_blocks(no_newline) ==
          SubString{String}["function clean_column(col::AbstractString)\n    col = strip(lowercase(col))\n    col = replace(col, r\"[-\\s]+\", \"_\")\n    col\nend"]
end

@testset "extract_code_blocks_fallback" begin

    # Basic Functionality Test
    @test extract_code_blocks_fallback("```\ncode block\n```") == ["code block"]

    # No Code Blocks Test
    @test isempty(extract_code_blocks_fallback("Some text without code blocks"))

    # Adjacent Code Blocks Test
    @test extract_code_blocks_fallback("```\ncode1\n```\n \n```\ncode2\n```") ==
          ["code1", "", "code2"]

    # Special Characters Test
    @test extract_code_blocks_fallback("```\n<>&\"'\n```") == ["<>&\"'"]

    # Large Input Test
    large_input = "```\n" * repeat("large code block\n", 10) * "```"
    @test extract_code_blocks_fallback(large_input) ==
          [strip(repeat("large code block\n", 10))]

    # Empty String Test
    @test isempty(extract_code_blocks_fallback(""))

    # delimiter inside of code
    delim_in_middle = """
      ```
      function myadd(a, b)
          # here is a silly comment that ends with ```
          return a + b
      end
      ```
      """
    @test extract_code_blocks_fallback(delim_in_middle) ==
          SubString{String}["function myadd(a, b)\n    # here is a silly comment that ends with ```\n    return a + b\nend"]

    # Different Delimiter Test
    @test extract_code_blocks_fallback("~~~\ncode block\n~~~", "~~~") == ["code block"]
end

@testset "extract_function_name" begin
    # Test 1: Test an explicit function declaration
    @test extract_function_name("function testFunction1()\nend") == "testFunction1"
    # Test 2: Test a concise function declaration
    @test extract_function_name("testFunction2() = 42") == "testFunction2"
    @test extract_function_name("  test_Function_2() = 42") == "test_Function_2"

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

@testset "extract_function_names" begin
    code_block = """
        function add(x, y)
            return x + y
        end

        subtract(x, y) = x - y
    """
    expected_result = ["add", "subtract"]
    @test extract_function_names(code_block) == expected_result

    s = """
    import Base.splitx

    Base.splitx()=1

    splitx(aaa) = 2
    """
    @test extract_function_names(s) == ["Base.splitx", "splitx"]
    @test extract_function_names("") == String[]
end

@testset "detect_base_main_overrides" begin
    # Test case 1: No overrides detected
    code_block_1 = """
    function foo()
        println("Hello, World!")
    end
    """
    @test detect_base_main_overrides(code_block_1) == (false, [])

    # Test case 2: Overrides detected
    code_block_2 = """
    function Base.bar()
        println("Override Base.bar()")
    end

    function Main.baz()
        println("Override Main.baz()")
    end
    """
    @test detect_base_main_overrides(code_block_2) == (true, ["Base.bar", "Main.baz"])

    # Test case 3: Overrides with base imports
    code_block_3 = """
    using Base: sin

    function Main.qux()
        println("Override Main.qux()")
    end
    """
    @test detect_base_main_overrides(code_block_3) == (true, ["Main.qux"])

    s4 = """
    import Base.splitx

    splitx(aaa) = 2
    """
    @test detect_base_main_overrides(s4) == (true, ["splitx"])
end

@testset "extract_testset_name" begin
    @test extract_testset_name("@testset \"TestSet1\" begin") == "TestSet1"
    testset_str = """
    @testset "pig_latinify" begin
        output = pig_latinify("hello")
        expected = "ellohay"
        @test output == expected
    end
    """
    @test extract_testset_name(testset_str) == "pig_latinify"
    @test extract_testset_name("    " * testset_str) == "pig_latinify"
    @test extract_testset_name("@testset  \"TestSet1\"   begin") == "TestSet1"
    @test extract_testset_name("@testset   begin") == nothing
end

@testset "extract_package_name_from_argerror" begin
    @test extract_package_name_from_argerror("Package MyPackage not found") == "MyPackage"
    error_msg = "Package Threads not found in current path, maybe you meant `import/using .Threads`.\n- Otherwise, run `import Pkg; Pkg.add(\"Threads\")` to install the Threads package."
    @test extract_package_name_from_argerror(error_msg) == "Threads"
    error_msg = "Package Main.Base.Something.Package not found in current path..."
    @test extract_package_name_from_argerror(error_msg) == "Main.Base.Something.Package"
    @test extract_package_name_from_argerror("asdl;asdas Package Threads not found in my living room :)") ==
          nothing
end

@testset "extract_stacktrace_lines" begin
    @test extract_stacktrace_lines("filename1.jl", nothing) == Int[]
    @test extract_stacktrace_lines("filename1.jl", "nothing") == Int[]
    @test extract_stacktrace_lines("filename1.jl", "filename1.jl:10\nfilename1.jl:20\n") ==
          [10, 20]
    s = """
        Test Summary:        | Pass  Total  Time
    detect_pkg_operation |    5      5  0.0s
    Test.DefaultTestSet("detect_pkg_operation", Any[], 5, false, false, true, 1.706440939410623e9, 1.706440939410673e9, false, "/Users/xyz/test/code_parsing.jl")

    remove_unsafe_lines: Test Failed at /Users/xyz/test/code_parsing.jl:66
      Expression: remove_unsafe_lines("Pkg.activate(\".\")") == ""
       Evaluated: ("", "Pkg.activate(\".\")\n") == ""

    Stacktrace:
     [1] macro expansion
       @ ~/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/share/julia/stdlib/v1.10/Test/src/Test.jl:672 [inlined]
     [2] macro expansion
       @ ~/test/code_parsing.jl:66 [inlined]
     [3] macro expansion
       @ ~/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/share/julia/stdlib/v1.10/Test/src/Test.jl:1577 [inlined]
     [4] top-level scope
       @ ~/test/code_parsing.jl:66
    remove_unsafe_lines: Test Failed at /Users/xyz/test/code_parsing.jl:67
      Expression: remove_unsafe_lines("Pkg.add(\"SomePkg\")") == ""
       Evaluated: ("", "Pkg.add(\"SomePkg\")\n") == ""
       """
    @test extract_stacktrace_lines("code_parsing.jl", s) == [66, 66, 66, 67]
    @test extract_stacktrace_lines("Test.jl", s) == [672, 1577]
    @test extract_stacktrace_lines("notexisting.jl", s) == Int[]
end
