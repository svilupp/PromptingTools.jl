using PromptingTools.Experimental.AgentTools: add_feedback!,
                                              evaluate_condition!,
                                              SampleNode, expand!, AICallBlock

@testset "add_feedback!" begin
    # Test for adding feedback as a new message to the conversation
    sample = SampleNode(; data = nothing, feedback = "Test Feedback")
    conversation = [
        PT.UserMessage("User says hello"), PT.AIMessage(; content = "AI responds")]
    updated_conversation = add_feedback!(conversation, sample)

    @test length(updated_conversation) == 3
    @test updated_conversation[end].content ==
          "### Feedback from Evaluator\nTest Feedback\n"

    # Test for adding feedback inplace to the last user message
    sample = SampleNode(; data = nothing, feedback = "Inplace Feedback")
    conversation = [
        PT.UserMessage("Initial message"), PT.AIMessage(; content = "AI message")]
    updated_conversation = add_feedback!(conversation, sample; feedback_inplace = true)

    # remove AI message, so only 1 is left
    @test length(updated_conversation) == 1
    @test occursin("Inplace Feedback", updated_conversation[end].content)

    # Test with empty feedback should not alter conversation
    sample = SampleNode(; data = nothing, feedback = "")
    conversation = [PT.UserMessage("Empty feedback scenario"),
        PT.AIMessage(; content = "No feedback here")]
    updated_conversation = add_feedback!(conversation, sample)
    @test length(updated_conversation) == 2

    # Test with empty feedback should not alter anything
    sample = SampleNode(; data = nothing, feedback = "")
    conversation = [PT.UserMessage("Empty feedback scenario"),
        PT.AIMessage(; content = "No feedback here")]
    updated_conversation = add_feedback!(conversation, sample; feedback_inplace = true)
    @test length(updated_conversation) == 2

    # Test for adding feedback with multiple ancestors' feedback collected
    sample = SampleNode(; data = nothing, feedback = "Test Feedback")
    child = expand!(sample, nothing; feedback = "Extra test")
    conversation = [
        PT.UserMessage("User says hello"), PT.AIMessage(; content = "AI responds")]
    updated_conversation = add_feedback!(conversation, child; feedback_inplace = true)
    @test length(updated_conversation) == 1
    @test updated_conversation[end].content ==
          "User says hello\n\n### Feedback from Evaluator\nTest Feedback\n----------\nExtra test\n"

    # Test for attempting to add feedback inplace with no prior user message
    sample = SampleNode(; data = nothing, feedback = "Orphan Feedback")
    conversation = [AIMessage(; content = "Lonely AI message")]
    @test_throws Exception add_feedback!(conversation, sample; feedback_inplace = false)
end

@testset "evaluate_condition!" begin
    function mock_f_cond_positive(aicall::AICallBlock)
        return true
    end
    function mock_f_cond_negative(aicall::AICallBlock)
        return false
    end
    feedback_str = "Test Feedback"
    feedback_fun(aicall::AICallBlock) = "Function Feedback"

    # Test condition met, evaluate_all default (true)
    aicall = AIGenerate("Say hi!"; config = RetryConfig(; n_samples = 1))
    aicall.active_sample_id = aicall.samples.id # mimick what happens in run!
    condition_passed, suggested_sample = evaluate_condition!(mock_f_cond_positive, aicall)
    @test condition_passed == true
    @test suggested_sample === aicall.samples

    # Test condition not met, with string feedback, evaluate_all true
    aicall = AIGenerate("Say hi!"; config = RetryConfig(; n_samples = 1))
    aicall.samples.success = true
    aicall.active_sample_id = aicall.samples.id # mimick what happens in run!
    node_success = expand!(aicall.samples, PT.AbstractMessage[]; success = true)
    condition_passed,
    suggested_sample = evaluate_condition!(mock_f_cond_negative, aicall,
        feedback_str; evaluate_all = true)
    @test condition_passed == false
    ## all nodes were evaluated and set to false
    @test suggested_sample.feedback == "\n" * feedback_str
    @test suggested_sample == node_success
    @test suggested_sample.success == false
    @test aicall.samples.feedback == "\n" * feedback_str
    @test aicall.samples.success == false

    # Test condition not met, with function feedback, evaluate_all true
    aicall = AIGenerate("Say hi!"; config = RetryConfig(; n_samples = 1))
    aicall.samples.success = true
    aicall.active_sample_id = aicall.samples.id # mimick what happens in run!
    condition_passed,
    suggested_sample = evaluate_condition!(mock_f_cond_negative, aicall,
        feedback_fun, evaluate_all = true)
    @test condition_passed == false
    @test suggested_sample.feedback == "\n" * feedback_fun(aicall)

    # Test condition not met, feedback is expensive
    aicall = AIGenerate("Say hi!"; config = RetryConfig(; n_samples = 1))
    aicall.samples.success = true
    aicall.active_sample_id = aicall.samples.id # mimick what happens in run!
    node_success = expand!(aicall.samples, PT.AbstractMessage[]; success = true)
    condition_passed,
    suggested_sample = evaluate_condition!(mock_f_cond_negative, aicall,
        feedback_str, feedback_expensive = true)
    @test condition_passed == false
    @test suggested_sample.feedback == "\n" * feedback_str
    @test aicall.samples.feedback == "" # Not provided because marked as expensive!

    # Test condition not met, feedback is expensive -- with function feedback
    aicall = AIGenerate("Say hi!"; config = RetryConfig(; n_samples = 1))
    aicall.samples.success = true
    aicall.active_sample_id = aicall.samples.id # mimick what happens in run!
    node_success = expand!(aicall.samples, PT.AbstractMessage[]; success = true)
    condition_passed,
    suggested_sample = evaluate_condition!(mock_f_cond_negative, aicall,
        feedback_fun, feedback_expensive = true)
    @test condition_passed == false
    @test suggested_sample.feedback == "\n" * feedback_fun(aicall)
    @test aicall.samples.feedback == "" # Not provided because marked as expensive!

    # Test condition evaluated only on active sample, condition fails
    aicall = AIGenerate("Say hi!"; config = RetryConfig(; n_samples = 1))
    aicall.samples.success = true
    aicall.active_sample_id = aicall.samples.id # mimick what happens in run!
    node_success = expand!(aicall.samples, PT.AbstractMessage[]; success = true)
    condition_passed,
    suggested_sample = evaluate_condition!(mock_f_cond_negative, aicall,
        "", evaluate_all = false)
    @test condition_passed == false
    @test aicall.samples.success == false
    @test aicall.samples.children[1].success == true ## not actually checked!
end

@testset "airetry!" begin
    response = Dict(
        :choices => [
            Dict(:message => Dict(:content => "Hello!"),
            :finish_reason => "stop")
        ],
        :usage => Dict(:total_tokens => 3, :prompt_tokens => 2, :completion_tokens => 1))
    schema = PT.TestEchoOpenAISchema(; response, status = 200)

    ## Try to run before it's initialized
    aicall = AIGenerate(schema, "Say hi!";
        config = RetryConfig(max_retries = 0, retries = 0, calls = 0))
    @test_throws AssertionError airetry!(==(0), aicall)

    # Check condition passing without retries
    aicall = AIGenerate(schema, "Say hi!";
        config = RetryConfig(max_retries = 0, retries = 0, calls = 0))
    run!(aicall)
    # This condition should immediately pass
    condition_func = _ -> true
    airetry!(condition_func, aicall)
    @test aicall.success == true
    @test aicall.samples[aicall.active_sample_id].success == true
    @test length(aicall.conversation) == 3 # No retries, only initial the basic messages + 1 response
    @test aicall.config.retries == 0 # No retries performed

    # Fail condition and check retries
    aicall = AIGenerate(schema, "Say hi!";
        config = RetryConfig(max_retries = 2, retries = 0, calls = 0))
    run!(aicall)
    condition_not_met = _ -> false
    airetry!(condition_not_met, aicall)
    @test aicall.samples[aicall.active_sample_id].success == false
    @test length(aicall.conversation) == 5 # Retries, no feedback, but 3 AI calls
    @test count(PT.isaimessage, aicall.conversation) == 3
    @test count(PT.isusermessage, aicall.conversation) == 1
    @test aicall.config.retries == 2

    # Fail condition and throw error
    aicall = AIGenerate(schema, "Say hi!";
        config = RetryConfig(max_retries = 2, retries = 0, calls = 0))
    run!(aicall)
    condition_not_met = _ -> false
    @test_throws Exception airetry!(condition_not_met, aicall, throw = true)
    @test aicall.config.retries == 2

    # Fail condition and check retries
    aicall = AIGenerate(schema, "Say hi!";
        config = RetryConfig(max_retries = 2, retries = 0, calls = 0))
    run!(aicall)
    condition_not_met = _ -> false
    airetry!(condition_not_met, aicall, "Retry feedback")
    @test aicall.samples[aicall.active_sample_id].success == false
    @test length(aicall.conversation) == 7 # Retries, no feedback, but 3 AI calls, 2 feedback msg
    @test count(PT.isaimessage, aicall.conversation) == 3
    @test count(PT.isusermessage, aicall.conversation) == 3 # 1 initial, 2 feedbacks
    @test occursin("Retry feedback", aicall.conversation[end - 3].content)
    @test occursin("Retry feedback", aicall.conversation[end - 1].content)
    @test aicall.config.retries == 2
end
