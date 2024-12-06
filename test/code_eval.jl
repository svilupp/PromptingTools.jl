using PromptingTools: extract_code_blocks, extract_code_blocks_fallback, eval!
using PromptingTools: AICode, isparsed, isparseerror, is_julia_code, is_julia_expr
using PromptingTools: extract_module_name

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
        @test cb.error isa UndefVarError
        @test cb.error.var == :b
        @test !isnothing(cb.expression) # parsed
    end

    # expression-based eval!
    cb = AICode(; code = """
        a=1 + b # b not defined yet
        b=2
        """)
    cb = eval!(cb)
    eval!(cb, cb.expression; capture_stdout = false)
    @test cb.success == false
    @test cb.error isa UndefVarError
    @test cb.error.var == :b
    @test cb.error_lines == [1]
    # despite not capturing stdout, we always unwrap the error to be able to detect error lines
    @test occursin("UndefVarError", cb.stdout)

    # provide expression directly
    cb = AICode("""
    bad_func()=1
    """)
    expr = Meta.parseall("bad_func(1)")
    eval!(cb, expr; capture_stdout = false, eval_module = cb.output)
    @test cb.success == false
    @test cb.error isa MethodError
    @test cb.error_lines == [1]

    # test correct escaping of \$
    cb = AICode("""
        greet(s)="hi \$s"
        """)
    expr = Meta.parseall("greet(\"jan\")|>print")
    eval!(cb, expr; capture_stdout = true, eval_module = cb.output)
    @test cb.success == true
    @test cb.stdout == "hi jan"
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
    ## Base / Main overrides
    cb = AICode(; code = """
import Base.splitx

splitx(aaa) = 2
""")
    @test_logs (:warn,
        r"Safety Warning: Base / Main overrides detected \(functions: splitx\)") match_mode=:any eval!(
        cb;
        safe_eval = true)

    # Evaluate inside a gensym'd module
    cb = AICode(; code = "a=1") |> eval!
    @test occursin("SafeMod", string(cb.output))

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
    @test isvalid(cb)
    # Evaluate in Main directly
    cb = AICode(; code = "a123=123")
    eval!(cb; safe_eval = false)
    @test cb.output == 123
    @test a123 == 123

    cb = AICode("""
    module MyModule123
        function foo()
            println("Hello")
        end
    end
    """; safe_eval = false)
    @test cb.output == Main.MyModule123

    # Check that empty code is invalid
    cb = AICode("")
    @test !isvalid(cb)
    @test cb.error isa Exception

    # Test prefix and suffix
    cb = AICode(; code = "x=1")
    eval!(cb; prefix = "a=1", suffix = "b=2")
    @test cb.output.a == 1
    @test cb.output.b == 2

    # Whether to capture stdout
    cb = AICode(; code = "println(\"Hello\")")
    eval!(cb; capture_stdout = false)
    @test cb.stdout == nothing
    @test cb.code == "println(\"Hello\")"
    @test isvalid(cb)

    eval!(cb; capture_stdout = true)
    @test cb.stdout == "Hello\n"
    @test cb.code == "println(\"Hello\")"
    @test isvalid(cb)

    # Test execution_timeout
    cb = AICode("sleep(1.1)", execution_timeout = 1)
    @test cb.success == false
    @test isnothing(cb.output)
    @test cb.error isa InterruptException
    cb = AICode("sleep(1.1)", execution_timeout = 2)
    @test cb.success == true
    @test isnothing(cb.error)

    # expression-only method
    cb = AICode("""
    module MyModule
        function foo()
            println("Hello")
        end
    end
    """; safe_eval = false)
    eval_module = cb.output isa Module ? cb.output :
                  getfield(Main, extract_module_name(cb.expression))
    eval!(cb, Meta.parseall("foo()"); eval_module)
    @test isnothing(cb.error)
    @test cb.stdout == "Hello\n"
    cb = AICode("""
    function foo()
        println("Hello")
    end
    """; safe_eval = true)
    eval_module = cb.output isa Module ? cb.output :
                  getfield(Main, extract_module_name(cb.expression))
    eval!(cb, Meta.parseall("foo()"); eval_module)
    @test isnothing(cb.error)
    @test cb.stdout == "Hello\n"

    # Expression transformation
    cb = AICode("""
       @testset "Example Tests" begin
           x = 1 + 1
           @test x == 2
           @test y == 2
       end
       @test x == 3
       @test_throws AssertionError func(1)
       y = 3 + 3
       """; expression_transform = :nothing)
    @test occursin("Example Tests", cb.stdout)
    @test occursin("y == 2", cb.stdout)

    cb = AICode("""
       @testset "Example Tests" begin
           x = 1 + 1
           @test x == 2
           @test y == 2
       end
       @test x == 3
       @test_throws AssertionError func(1)
       y = 3 + 3
       """; expression_transform = :remove_all_tests)
    @test !occursin("Example Tests", cb.stdout)
    @test !occursin("y == 2", cb.stdout)
    @test !occursin("func(1)", cb.stdout)
    @test cb.stdout == ""
    @test isvalid(cb)
    println(cb.stdout)

    cb = AICode("""
       @testset "Example Tests" begin
           x = 1 + 1
           @test x == 2
           @test y == 2
       end
       @test x == 3
       @test_throws AssertionError func(1)
       y = 3 + 3
       """; expression_transform = :remove_test_items)
    @test occursin("Example Tests", cb.stdout)
    @test !occursin("y == 2", cb.stdout)
    @test !occursin("func(1)", cb.stdout)
    @test cb.stdout != ""
    @test isvalid(cb)
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

    # Fallback extraction method
    let msg = AIMessage("""
```
println(\"hello\")
```
Some text
```
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

    # skip_unsafe=true
    let msg = AIMessage("""
      ```julia
      a=1
      Pkg.add("a")
      b=2
      Pkg.add("b")
      using 12315456NotExisting
      ```
      """)
        cb = AICode(msg; skip_unsafe = true)
        @test cb.code == "a=1\nb=2\n"

        # dispatch on text
        code = extract_code_blocks(msg.content) |> x -> join(x, "\n")
        cb = AICode(code; skip_unsafe = true)
        @test cb.code == "a=1\nb=2\n"
    end

    # skip_invalid=true
    let msg = AIMessage("""
        ```julia
        println("Hello world!")
        ```

        ```julia
        println("Hello world!) # missing quote
        ```
        """)
        cb = AICode(msg; skip_invalid = true)
        @test cb.code == "println(\"Hello world!\")"

        # if it's not switched on
        cb = AICode(msg; skip_invalid = false)
        @test !isvalid(cb)
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

@testset "AICode-methods" begin
    ## SHOW
    # Test with All Fields as `nothing`
    code_block = AICode(""; auto_eval = false)
    buffer = IOBuffer()
    show(buffer, code_block)
    output = String(take!(buffer))
    @test output ==
          "AICode(Success: N/A, Parsed: N/A, Evaluated: N/A, Error Caught: N/A, StdOut: N/A, Code: 1 Lines)"

    # Test with All Fields Set
    code_block = AICode("println(\"Hello World\")")
    buffer = IOBuffer()
    show(buffer, code_block)
    output = String(take!(buffer))
    @test output ==
          "AICode(Success: True, Parsed: True, Evaluated: True, Error Caught: N/A, StdOut: True, Code: 1 Lines)"

    # Test with error
    code_block = AICode("error(\"Test Error\")\nprint(\"\")")
    buffer = IOBuffer()
    show(buffer, code_block)
    output = String(take!(buffer))
    @test output ==
          "AICode(Success: False, Parsed: True, Evaluated: N/A, Error Caught: True, StdOut: True, Code: 2 Lines)"

    ## EQUALITY
    # Test Comparing Two Identical Code Blocks -- if it's not safe_eval, it's not equal (gensym'd Safe module for output!)
    code1 = AICode("print(\"Hello\")"; safe_eval = false)
    code2 = AICode("print(\"Hello\")"; safe_eval = false)
    @test code1 == code2

    # Test Comparing Two Different Code Blocks
    code1 = AICode("print(\"Hello\")")
    code2 = AICode("print(\"World\")")
    @test code1 != code2

    # Different gensym!
    code1 = AICode("print(\"Hello\")"; safe_eval = true)
    code2 = AICode("print(\"Hello\")"; safe_eval = false)
    @test code1 != code2
end
