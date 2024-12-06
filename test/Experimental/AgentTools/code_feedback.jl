using PromptingTools.Experimental.AgentTools: aicodefixer_feedback
using PromptingTools.Experimental.AgentTools: CodeEmpty,
                                              CodeFailedParse, CodeFailedEval,
                                              CodeFailedTimeout, CodeSuccess
using PromptingTools.Experimental.AgentTools: testset_feedback,
                                              error_feedback, score_feedback,
                                              extract_test_counts
using PromptingTools.Experimental.AgentTools: AIGenerate

@testset "aicodefixer_feedback" begin
    # Empty code
    conv = [PT.AIMessage("test")]
    feedback = aicodefixer_feedback(conv).feedback
    code_missing_err = "**Error Detected**: No Julia code found. Always enclose Julia code in triple backticks code fence (```julia\\n ... \\n```)."
    @test feedback == code_missing_err
    @test aicodefixer_feedback(CodeEmpty()) == code_missing_err

    # test with message directly
    feedback = aicodefixer_feedback(PT.AIMessage("test")).feedback
    @test feedback == code_missing_err

    # test with aicall
    aicall = AIGenerate()
    aicall.conversation = [PT.AIMessage("test")]
    feedback = aicodefixer_feedback(aicall).feedback
    @test feedback == code_missing_err

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

    # test codeblock only    
    cb = AICode("println(\"a\"")
    feedback = aicodefixer_feedback(cb).feedback
    @test occursin("**Parsing Error Detected:**", feedback)

    # CodeFailedEval -- for failed tasks and normal errors
    cb = AICode("""
    tsk=@task error("xx")
    schedule(tsk)
    fetch(tsk)
    """)
    feedback = aicodefixer_feedback(CodeFailedEval(), cb)
    @test occursin(
        "**Error Detected:**\n**ErrorException**:\nxx\n\n\n\n**Lines that caused the error:**\n- fetch(tsk)",
        feedback)

    cb = AICode("error(\"xx\")")
    feedback = aicodefixer_feedback(CodeFailedEval(), cb)
    @test feedback ==
          "**Error Detected:**\n**ErrorException**:\nxx\n\n\n\n**Lines that caused the error:**\n- error(\"xx\")\n\n**Output Captured:**\n xx"
    conv = [PT.AIMessage("""
    ```julia
    error(\"xx\")
    ```
    """)]
    feedback = aicodefixer_feedback(conv).feedback
    @test feedback ==
          "**Error Detected:**\n**ErrorException**:\nxx\n\n\n\n**Lines that caused the error:**\n- error(\"xx\")\n\n**Output Captured:**\n xx"

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

@testset "testset_feedback" begin
    # Test case 1: Test testset_feedback with valid test set name
    msg = AIMessage("""
    ```julia
    @testset "tester" begin
        @test 1 == 1
    end
    ```
    """)
    expected_feedback = nothing
    @test testset_feedback(msg) == expected_feedback
    # Test case 2: Test testset_feedback with invalid test set name
    msg = AIMessage("""
    ```julia
    @testset "tester" begin
          func(
        @test 1 == 1
    end
    ```
    """)
    expected_feedback = CodeFailedEval()
    feedback = testset_feedback(msg)
    @test occursin("**Error Detected:**\n**", feedback)
    # Mock some function
    msg = AIMessage("""
    ```julia
    @testset "tester" begin
          tester()
        @test 1 == 1
    end
    ```
    """)
    @test testset_feedback(msg) == nothing
end

@testset "error_feedback" begin
    # Test case 1: Test error feedback with package name
    e = ArgumentError("Package Threads not found in current path, maybe you meant `import/using .Threads`.\n- Otherwise, run `import Pkg; Pkg.add(\"Threads\")` to install the Threads package.")
    expected_feedback = "ArgumentError: Package Threads not found in current path, maybe you meant `import/using .Threads`.\n- Otherwise, run `import Pkg; Pkg.add(\"Threads\")` to install the Threads package.\nExpert Tip: I know that the package Threads is defined in Base module. You MUST use `import Base.Threads` to use it."
    @test error_feedback(e) == expected_feedback

    # Test case 2: Test error feedback without package name
    e = ArgumentError("Invalid argument")
    expected_feedback = "ArgumentError: Invalid argument"
    @test error_feedback(e) == expected_feedback

    # Test case 1: Test error_feedback with defined variable
    e = UndefVarError(:Threads)
    str = error_feedback(e)
    @test occursin("UndefVarError: `Threads` not defined", str)
    @test occursin(
        "Expert Tip: I know that the variable Threads is defined in Base module.", str)

    # Test case 2: Test error_feedback with undefined variable
    e = UndefVarError(:SomeVariable)
    expected_output = "UndefVarError: `SomeVariable` not defined\nTip: Does it even exist? Does it need to be imported? Or is it a typo?"
    @test error_feedback(e) == expected_output

    # Test case 1: Test error_feedback with valid input
    e = Base.Meta.ParseError("SyntaxError: unexpected symbol \"(\"")
    output = error_feedback(e)
    @test occursin("**ParseError**", output)

    # Test case 2: Test error_feedback with custom max_length
    e = Base.Meta.ParseError("SyntaxError: unexpected symbol \"(\"")
    output = error_feedback(e; max_length = 15)
    @test occursin("**ParseError**", output)

    # Test case 4: Test error_feedback function
    e = @task error("Error message")
    schedule(e)
    expected_output = "**ErrorException**:\nError message"
    @test error_feedback(e) == expected_output

    # No error
    e = @task a = 1
    schedule(e)
    @test error_feedback(e) == "No error found. Ignore."

    ## Testsetexception
    cb = AICode("""
    @testset "x" begin
          a + a
          @test x == 2
    end
    """)
    output = error_feedback(cb.error)
    @test occursin("**TestSetException**:\nSome tests did not pass", output)
    @test occursin("UndefVarError: `a` not defined", output)

    # Test case 1: Test error_feedback with no error
    expected_output = "No error found. Ignore."
    @test error_feedback(expected_output) == expected_output

    # Test case 2: Test error_feedback with Exception
    e = ErrorException("Test exception")
    expected_output = "**ErrorException**:\nTest exception"
    @test error_feedback(e) == expected_output

    # Test case 3: Test error_feedback with Exception and max_length
    e = ErrorException("Test exception")
    expected_output = "**ErrorException**:\nTest exception"
    max_length = 10
    @test error_feedback(e; max_length) == expected_output[1:10]
end

@testset "score_feedback" begin
    # Test case 1: Test score_feedback with empty code
    cb = AICode("")
    @test score_feedback(cb) == 0

    # Test case 2: Test score_feedback with unparsed code
    cb = AICode("x ===== 1")
    @test score_feedback(cb) == 1

    # Test case 3: Test score_feedback with TestSetException error
    cb = AICode("""
    @testset "x" begin
          x = 1
          @test x == 2
    end
    """)
    @test score_feedback(cb) == 9

    # Test case 6: Test score_feedback with invalid code feedback path
    cb = AICode("""
    @testset "x" begin
          x = 1
          @test x == 2
          @test x == 1
          error("a")
    end
    """)
    @test score_feedback(cb) == 8

    # normal exception
    cb = AICode("""
          error("a")
    """)
    @test score_feedback(cb) == 2
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
