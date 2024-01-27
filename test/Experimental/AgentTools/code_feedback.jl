using PromptingTools.Experimental.AgentTools: aicodefixer_feedback
using PromptingTools.Experimental.AgentTools: CodeEmpty,
    CodeFailedParse, CodeFailedEval, CodeFailedTimeout, CodeSuccess

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
          "**Error Detected:** ErrorException(\"xx\")\n\n**Output Captured:** STDOUT"
    cb = AICode("error(\"xx\")")
    cb.stdout = "STDOUT"
    feedback = aicodefixer_feedback(CodeFailedEval(), cb)
    @test feedback ==
          "**Error Detected:** ErrorException(\"xx\")\n\n**Output Captured:** STDOUT"
    conv = [PT.AIMessage("""
    ```julia
    error(\"xx\")
    ```
    """)]
    feedback = aicodefixer_feedback(conv).feedback
    @test feedback ==
          "**Error Detected:** ErrorException(\"xx\")"

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
