using PromptingTools.Experimental.AgentTools: aicodefixer_feedback
using PromptingTools.Experimental.AgentTools: CodeEmpty,
    CodeFailedParse, CodeFailedEval, CodeFailedTimeout, CodeSuccess
using PromptingTools.Experimental.AgentTools: testset_feedback,
    error_feedback, score_feedback, extract_test_counts

@testset "aicodefixer_feedback" begin
    # Empty code
    conv = [PT.AIMessage("test")]
    feedback = aicodefixer_feedback(conv).feedback
    code_missing_err = "**Error Detected**: No Julia code found. Always enclose Julia code in triple backticks code fence (```julia\\n ... \\n```)."
    @test feedback == code_missing_err
    @test aicodefixer_feedback(CodeEmpty()) == code_missing_err

    # CodeFailedParse
    cb = AICode("println(\"a\"")
    feedback = aicodefixer_feedback(CodeFailedParse(), cb)
    @test occursin("**Parsing Error Detected:**", feedback)
    conv = [PT.AIMessage("""
    ```julia
    println(\"a\"
    ```
    """)]
    feedback = aicodefixer_feedback(conv).feedback
    @test occursin("**Parsing Error Detected:**", feedback)

    # CodeFailedEval -- for failed tasks and normal errors
    cb = AICode("""
    tsk=@task error("xx")
    schedule(tsk)
    fetch(tsk)
    """)
    cb.stdout = "STDOUT"
    feedback = aicodefixer_feedback(CodeFailedEval(), cb)
    @test feedback ==
          "**Error Detected:**\n**ErrorException**:\nxx\n\n\n\n**Lines that caused the error:**\n- fetch(tsk)\n\n**Output Captured:**\n STDOUT"
    cb = AICode("error(\"xx\")")
    cb.stdout = "STDOUT"
    feedback = aicodefixer_feedback(CodeFailedEval(), cb)
    @test feedback ==
          "**Error Detected:**\n**ErrorException**:\nxx\n\n\n\n**Lines that caused the error:**\n- error(\"xx\")\n\n**Output Captured:**\n STDOUT"
    conv = [PT.AIMessage("""
    ```julia
    error(\"xx\")
    ```
    """)]
    feedback = aicodefixer_feedback(conv).feedback
    @test feedback ==
          "**Error Detected:**\n**ErrorException**:\nxx\n\n\n\n**Lines that caused the error:**\n- error(\"xx\")"

    # CodeFailedTimeout
    cb = AICode("InterruptException()")
    feedback = aicodefixer_feedback(CodeFailedTimeout(), cb)
    @test feedback ==
          "**Error Detected**: Evaluation timed out. Please check your code for infinite loops or other issues."
    conv = [PT.AIMessage("""
    ```julia
    throw(InterruptException())
    ```
    """)]
    feedback = aicodefixer_feedback(conv).feedback
    @test feedback ==
          "**Error Detected**: Evaluation timed out. Please check your code for infinite loops or other issues."

    # CodeSuccess
    cb = AICode("1")
    cb.stdout = "STDOUT"
    feedback = aicodefixer_feedback(CodeSuccess(), cb)
    @test occursin("Execution has been successful", feedback)
    @test occursin("**Output Captured:**", feedback)
end

@testset "extract_test_counts" begin
    test_summary1 = """
    Test Summary: | Pass  Broken  Total  Time
    a             |    1       1      2  0.0s
    """
    @test extract_test_counts(test_summary1) ==
          Dict("pass" => 1, "broken" => 1, "total" => 2)

    test_summary2 = """
    Test Summary: | Pass  Fail  Error  Total  Time
    b             |    1     1      1      3  0.0s
    """
    @test extract_test_counts(test_summary2) ==
          Dict("pass" => 1, "fail" => 1, "error" => 1, "total" => 3)

    test_summary3 = """
    Test Summary: | Pass  Fail  Error  Broken  Total  Time
    two           |    2     1      1       1      5  0.0s
      a           |    1                    1      2  0.0s
      b           |    1     1      1              3  0.0s
    """
    @test extract_test_counts(test_summary3) ==
          Dict("fail" => 1, "error" => 1, "total" => 5, "broken" => 1, "pass" => 2)

    test_summary4 = """
    Test Summary: | Pass  Broken  Total  Time
    a             |    1       1      2  0.0s

    Test Summary: | Pass  Fail  Error  Total  Time
    b             |    1     1      1      3  0.0s
    """
    @test extract_test_counts(test_summary4) ==
          Dict("pass" => 2, "broken" => 1, "fail" => 1, "error" => 1, "total" => 5)
end

## TODO: Add tests for: testset_feedback, error_feedback, score_feedback, extract_test_counts

## # Test case 1: Test score_feedback with empty code
## @testset "score_feedback" begin
##     cb = AICode("")
##     @test score_feedback(cb) == 0
## end

## # Test case 2: Test score_feedback with unparsed code
## @testset "score_feedback" begin
##     cb = AICode("x = 1")
##     @test score_feedback(cb) == 1
## end

## # Test case 3: Test score_feedback with TestSetException error
## @testset "score_feedback" begin
##     cb = AICode("x = 1; @test x == 2")
##     error = Test.TestSetException(1, 0, 1, 0)
##     cb.error = error
##     @test score_feedback(cb) == 9
## end

## # Test case 4: Test score_feedback with generic Exception error
## @testset "score_feedback" begin
##     cb = AICode("x = 1; y = 2; z = x + y")
##     error = Exception()
##     cb.error = error
##     @test score_feedback(cb) == 2
## end

## # Test case 5: Test score_feedback with valid code
## @testset "score_feedback" begin
##     cb = AICode("x = 1; y = 2; z = x + y; @test z == 3")
##     @test score_feedback(cb) == 10
## end

## # Test case 6: Test score_feedback with invalid code feedback path
## @testset "score_feedback" begin
##     cb = AICode("x = 1; y = 2; z = x + y; @test z == 3")
##     cb.code = ""
##     @test_throws ArgumentError score_feedback(cb)
## endusing Test

## # Test case 1: Test error feedback with package name
## @testset "error_feedback" begin
##     e = ArgumentError("Package Threads not found in current path, maybe you meant `import/using .Threads`.\n- Otherwise, run `import Pkg; Pkg.add(\"Threads\")` to install the Threads package.")
##     expected_feedback = "ArgumentError: Package Threads not found in current path, maybe you meant `import/using .Threads`.\n- Otherwise, run `import Pkg; Pkg.add(\"Threads\")` to install the Threads package.\nExpert Tip: I know that the package Threads is defined in Base module. You MUST use `import Base.Threads` to use it."
##     @test error_feedback(e) == expected_feedback
## end

## # Test case 2: Test error feedback without package name
## @testset "error_feedback" begin
##     e = ArgumentError("Invalid argument")
##     expected_feedback = "ArgumentError: Invalid argument"
##     @test error_feedback(e) == expected_feedback
## endusing Test

## # Test case 1: Test error_feedback with defined variable
## @testset "error_feedback" begin
##     e = UndefVarError(:Threads)
##     expected_output = "UndefVarError: `Threads` not defined\nExpert Tip: I know that the variable Threads is defined in Base module. Use `import Base.Threads` to use it."
##     @test error_feedback(e) == expected_output
## end

## # Test case 2: Test error_feedback with undefined variable
## @testset "error_feedback" begin
##     e = UndefVarError(:SomeVariable)
##     expected_output = "UndefVarError: `SomeVariable` not defined\nTip: Does it even exist? Does it need to be imported? Or is it a typo?"
##     @test error_feedback(e) == expected_output
## endusing Test

## # Test case 1: Test error_feedback with valid input
## @testset "error_feedback" begin
##     e = Base.Meta.ParseError("SyntaxError: unexpected symbol \"(\"")
##     expected_output = "**ParseError**:\nSyntaxError: unexpected symbol \"(\""
##     @test error_feedback(e) == expected_output
## end

## # Test case 2: Test error_feedback with custom max_length
## @testset "error_feedback" begin
##     e = Base.Meta.ParseError("SyntaxError: unexpected symbol \"(\"")
##     expected_output = "**ParseError**:\nSyntaxError: unexpected symbol \"(\""
##     @test error_feedback(e, max_length = 20) == expected_output[1:20]
## endusing Test

## # Test case 4: Test error_feedback function
## @testset "error_feedback" begin
##     # Test case 4.1: Test error_feedback with valid input
##     @testset "valid input" begin
##         e = TaskFailedException(1, "Error message")
##         expected_output = "Error message"
##         @test error_feedback(e) == expected_output
##     end

##     # Test case 4.2: Test error_feedback with long error message
##     @testset "long error message" begin
##         e = TaskFailedException(1, "This is a very long error message that exceeds the maximum length")
##         expected_output = "This is a very long error message that exceeds the maximum length"
##         @test error_feedback(e, max_length = 50) == expected_output
##     end
## endusing Test

## # Test case 1: Test error_feedback function
## @testset "error_feedback" begin
##     # Test input
##     e = TestSetException("Test error")
##     expected_output = "Test error"

##     # Test function
##     @test error_feedback(e) == expected_output
## endusing Test

## # Test case 1: Test error_feedback with no error
## @testset "error_feedback" begin
##     e = "No error found. Ignore."
##     expected_output = "No error found. Ignore."
##     @test error_feedback(e) == expected_output
## end

## # Test case 2: Test error_feedback with Exception
## @testset "error_feedback" begin
##     e = Exception("Test exception")
##     expected_output = "**Exception**:\nTest exception"
##     @test error_feedback(e) == expected_output
## end

## # Test case 3: Test error_feedback with Exception and max_length
## @testset "error_feedback" begin
##     e = Exception("Test exception")
##     max_length = 10
##     expected_output = "**Exception**:\nTest exce..."
##     @test error_feedback(e, max_length) == expected_output
## endusing Test

## # Test case 1: Test testset_feedback with valid test set name
## @testset "testset_feedback" begin
##     msg = AIMessage(content="function testset_feedback(msg::AIMessage; prefix::AbstractString = \"\", suffix::AbstractString = \"\", kwargs...)\n    code = join(PT.extract_code_blocks(msg.content), \"\\n\")\n    test_f = PT.extract_testset_name(code)\n    if !isnothing(test_f)\n        test_f_mock = \"$(replace(test_f, r\"[\\s\\(\\)]\" => \"\"))(args...; kwargs...) = nothing\"\n        prefix = prefix * \"\\n\" * test_f_mock\n    end\n    # Insert mock function, remove test items -- good test suite should pass\n    cb = AICode(msg;\n        skip_unsafe = true,\n        prefix, suffix,\n        expression_transform = :remove_test_items, kwargs...)\n    feedback = if !isnothing(cb.error)\n        aicodefixer_feedback(CodeFailedEval(), cb)\n    else\n        nothing\n    end\n    return feedback\nend")
##     expected_feedback = nothing
##     @test testset_feedback(msg) == expected_feedback
## end

## # Test case 2: Test testset_feedback with invalid test set name
## @testset "testset_feedback" begin
##     msg = AIMessage(content="function testset_feedback(msg::AIMessage; prefix::AbstractString = \"\", suffix::AbstractString = \"\", kwargs...)\n    code = join(PT.extract_code_blocks(msg.content), \"\\n\")\n    test_f = PT.extract_testset_name(code)\n    if !isnothing(test_f)\n        test_f_mock = \"$(replace(test_f, r\"[\\s\\(\\)]\" => \"\"))(args...; kwargs...) = nothing\"\n        prefix = prefix * \"\\n\" * test_f_mock\n    end\n    # Insert mock function, remove test items -- good test suite should pass\n    cb = AICode(msg;\n        skip_unsafe = true,\n        prefix, suffix,\n        expression_transform = :remove_test_items, kwargs...)\n    feedback = if !isnothing(cb.error)\n        aicodefixer_feedback(CodeFailedEval(), cb)\n    else\n        nothing\n    end\n    return feedback\nend")
##     expected_feedback = CodeFailedEval()
##     @test testset_feedback(msg) == expected_feedback
## end