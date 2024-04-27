@testset "RetryConfig" begin
    config = RetryConfig()
    config.retries = 1
    config.calls = 1

    # Show method
    io = IOBuffer()
    show(io, config)
    str = String(take!(io))
    @test str ==
          "RetryConfig\n  retries: Int64 1\n  calls: Int64 1\n  max_retries: Int64 10\n  max_calls: Int64 99\n  retry_delay: Int64 0\n  n_samples: Int64 1\n  scoring: PromptingTools.Experimental.AgentTools.UCT\n  ordering: Symbol PostOrderDFS\n  feedback_inplace: Bool false\n  feedback_template: Symbol FeedbackFromEvaluator\n  temperature: Float64 0.7\n  catch_errors: Bool false\n"

    ## copy
    config2 = copy(config)
    @test config2 == config
    @test config2 !== config
end

@testset "AICall" begin
    # Create AICall with default parameters
    default_call = AICall(identity)
    @test default_call.func === identity
    @test isnothing(default_call.schema)
    @test isempty(default_call.conversation)
    @test isempty(default_call.kwargs)
    @test isnothing(default_call.success)
    @test isnothing(default_call.error)

    # Custom function
    custom_func = x -> x * 2
    custom_call = AICall(custom_func)
    @test custom_call.func === custom_func

    # Different conversation types
    aicall = AICall(identity, [PT.UserMessage("Hi")])
    @test aicall.conversation == [PT.UserMessage("Hi")]
    aicall = AICall(identity, "Hi")
    @test aicall.conversation == [PT.UserMessage("Hi")]
    aicall = AICall(identity, :BlankSystemUser)
    @test aicall.conversation == [PT.SystemMessage("{{system}}")
                                  PT.UserMessage("{{user}}")]
    aicall = AICall(identity, AITemplate(:BlankSystemUser))
    @test aicall.conversation == [PT.SystemMessage("{{system}}")
                                  PT.UserMessage("{{user}}")]

    # derived methods
    aicall = AIGenerate()
    @test aicall.func == aigenerate
    aicall = AIExtract()
    @test aicall.func == aiextract
    aicall = AIEmbed()
    @test aicall.func == aiembed
    aicall = AIScan()
    @test aicall.func == aiscan
    aicall = AIClassify()
    @test aicall.func == aiclassify

    # Wrong arguments
    @test_throws AssertionError AICall(identity, "arg1", "arg2", "arg3")

    # run! method
    response = Dict(:choices => [Dict(:message => Dict(:content => "Hello!"))],
        :usage => Dict(:total_tokens => 3, :prompt_tokens => 2, :completion_tokens => 1))
    schema = PT.TestEchoOpenAISchema(; response, status = 200)
    aicall = AICall(aigenerate, schema)
    run!(aicall)
    @test isa(aicall, AICall)
    @test aicall.conversation[end].content == "Hello!"

    # catch_error
    pass_func(args...; kwargs...) = nothing
    @test_throws Exception run!(AICall(pass_func, PT.PROMPT_SCHEMA))

    # Functor with String
    response = Dict(:choices => [Dict(:message => Dict(:content => "Hello!"))],
        :usage => Dict(:total_tokens => 3, :prompt_tokens => 2, :completion_tokens => 1))
    schema = PT.TestEchoOpenAISchema(; response, status = 200)
    aicall = AICall(aigenerate, schema)
    result = aicall("test string")
    @test isa(result, AICall)
    @test result.conversation[2] == PT.UserMessage("test string")
    @test result.conversation[3].content == "Hello!"

    # Functor with UserMessage
    user_msg = PT.UserMessage("test message")
    result = aicall(user_msg)
    @test isa(result, AICall)
    @test result.conversation[end].content == "Hello!"
    @test result.conversation[end - 1] == PT.UserMessage("test message")
    # Invalid Argument Type
    @test_throws ErrorException AICall(identity, 123)

    # Show method
    aicall = AICall(identity, schema)
    aicall.conversation = [PT.UserMessage("Hi!"), PT.AIMessage("Test message")]
    aicall.success = true
    io = IOBuffer()
    show(io, aicall)
    output = String(take!(io))
    @test output ==
          "AICall{typeof(identity)}(Messages: 2, Success: true)\n- Preview of the Latest AIMessage (see property `:conversation`):\n Test message"

    ## last_message, last_output
    @test last_output(aicall) == aicall.conversation[end].content
    @test last_message(aicall) == aicall.conversation[end]

    ## isvalid
    @test isvalid(aicall) == aicall.success

    ## copy
    aicall = AICall(identity)
    aicall2 = copy(aicall)
    @test aicall == aicall2
    @test aicall !== aicall2
end

@testset "AICodeFixer" begin
    # default constructor
    response = Dict(:choices => [Dict(:message => Dict(:content => "Hello!"))],
        :usage => Dict(:total_tokens => 3, :prompt_tokens => 2, :completion_tokens => 1))
    schema = PT.TestEchoOpenAISchema(; response, status = 200)
    aicall = AICall(aigenerate, schema)
    codefixer = AICodeFixer(aicall, [PT.UserMessage("Test")])
    @test codefixer.call === aicall
    @test length(codefixer.templates) == 1
    @test codefixer.num_rounds == 3  # Default value
    @test codefixer.round_counter == 0
    @test codefixer.feedback_func === aicodefixer_feedback
    @test isempty(codefixer.kwargs)

    # Custom Constructor
    custom_func = x -> x * 2
    aicall = AICall(custom_func)
    custom_template = [PT.UserMessage("Custom Test")]
    custom_rounds = 5
    codefixer = AICodeFixer(aicall, custom_template; num_rounds = custom_rounds)
    @test codefixer.call.func == custom_func
    @test codefixer.templates == custom_template
    @test codefixer.num_rounds == custom_rounds

    # run! Method
    response = Dict(:choices => [Dict(:message => Dict(:content => "Hello!"))],
        :usage => Dict(:total_tokens => 3, :prompt_tokens => 2, :completion_tokens => 1))
    schema = PT.TestEchoOpenAISchema(; response, status = 200)
    aicall = AICall(aigenerate, schema)
    codefixer = AICodeFixer(aicall, [PT.UserMessage("Test")])
    run!(codefixer)
    @test codefixer.round_counter == codefixer.num_rounds
    @test codefixer.call.success == true
    @test codefixer.call.conversation[end - 1] == PT.UserMessage("Test")
    @test codefixer.call.conversation[end].content == PT.AIMessage("Hello!").content

    ## Run for a few more iterations
    run!(codefixer; num_rounds = 2)
    @test codefixer.round_counter == codefixer.num_rounds + 2

    # symbol template
    response = Dict(:choices => [Dict(:message => Dict(:content => "Hello!"))],
        :usage => Dict(:total_tokens => 3, :prompt_tokens => 2, :completion_tokens => 1))
    schema = PT.TestEchoOpenAISchema(; response, status = 200)
    aicall = AICall(aigenerate, schema)
    codefixer = AICodeFixer(aicall, :CodeFixerShort)
    run!(codefixer)
    @test codefixer.round_counter == codefixer.num_rounds
    @test codefixer.call.success == true
    @test codefixer.call.conversation[end].content == PT.AIMessage("Hello!").content
    # AITemplate template
    codefixer = AICodeFixer(aicall, AITemplate(:CodeFixerShort))
    @test length(codefixer.templates) == 1

    # Zero Rounds
    response = Dict(:choices => [Dict(:message => Dict(:content => "Hello!"))],
        :usage => Dict(:total_tokens => 3, :prompt_tokens => 2, :completion_tokens => 1))
    schema = PT.TestEchoOpenAISchema(; response, status = 200)
    aicall = AICall(aigenerate, schema)
    codefixer = AICodeFixer(aicall, [PT.UserMessage("Test")]; num_rounds = 0)
    run!(codefixer)
    @test codefixer.round_counter == 0
    @test codefixer.num_rounds == 0
    ## No Test
    @test codefixer.call.conversation[end].content == PT.AIMessage("Hello!").content

    # Invalid Template
    aicall = AICall(identity)
    @test_throws AssertionError AICodeFixer(aicall, :InvalidSymbol; num_rounds = 0)

    # Show method
    aicall = AICall(identity)
    codefixer = AICodeFixer(aicall, [PT.UserMessage("Fix this")], num_rounds = 5)

    # Capture the output of show
    io = IOBuffer()
    show(io, codefixer)
    output = String(take!(io))
    @test output == "AICodeFixer(Rounds: 0/5)"
end
