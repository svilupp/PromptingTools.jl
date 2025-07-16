using PromptingTools.Experimental.AgentTools: remove_used_kwargs, truncate_conversation
using PromptingTools.Experimental.AgentTools: beta_sample,
                                              gamma_sample, extract_config,
                                              unwrap_aicall_args, split_multi_samples

@testset "remove_used_kwargs" begin
    # Test 1: No overlapping keys
    @test remove_used_kwargs((a = 1, b = 2), [PT.UserMessage("{{c}} {{d}}")]) ==
          (a = 1, b = 2)

    # Test 2: All keys used
    @test remove_used_kwargs((a = 1, b = 2), [PT.UserMessage("{{a}} {{b}}")]) ==
          NamedTuple()

    # Test 3: Some overlapping keys
    @test remove_used_kwargs((a = 1, b = 2, c = 3),
        [PT.UserMessage("{{a}} {{d}}"), PT.UserMessage("{{b}}")]) == (; c = 3)

    # Test 4: Empty conversation
    @test remove_used_kwargs((a = 1, b = 2), PT.AbstractMessage[]) == (a = 1, b = 2)

    # Test 5: Empty kwargs
    @test remove_used_kwargs(NamedTuple(), [PT.UserMessage("{{c}} {{d}}")]) == NamedTuple()
end

@testset "unwrap_aicall_args" begin

    # Test with too many arguments
    @test_throws AssertionError unwrap_aicall_args((1, 2, 3, 4))
    @test_throws AssertionError unwrap_aicall_args([
        "Hello", :ExampleTemplate, AITemplate(:AnotherExample)])

    # Test with one valid String argument (UserMessage)
    schema, conversation = unwrap_aicall_args(["Hello"])
    @test schema === nothing
    @test length(conversation) == 1
    @test isa(conversation[1], PT.UserMessage)
    @test conversation[1].content == "Hello"

    # Test with one valid Symbol argument (template-based conversion)
    schema, conversation = unwrap_aicall_args([PT.OpenAISchema(), :BlankSystemUser])
    @test schema == PT.OpenAISchema()
    @test length(conversation) == 2
    @test isa(conversation[1], PT.SystemMessage)
    @test isa(conversation[2], PT.UserMessage)
    schema,
    conversation = unwrap_aicall_args([
        PT.OpenAISchema(), AITemplate(:BlankSystemUser)])
    @test schema == PT.OpenAISchema()
    @test length(conversation) == 2

    # Test with an invalid argument type
    @test_throws ErrorException unwrap_aicall_args([123])

    # Test with two valid arguments in accepted combination (String and AITemplate)
    schema, conversation = unwrap_aicall_args([PT.OpenAISchema(), "text"])
    @test schema == PT.OpenAISchema()
    @test length(conversation) == 1
    @test isa(conversation[1], PT.UserMessage)
    @test conversation[1].content == "text"
end

@testset "extract_config" begin
    # With config in kwargs
    kwargs = (a = 1, b = 2, config = RetryConfig(; max_calls = 50))
    new_kwargs, config = extract_config(kwargs, RetryConfig())

    @test config.max_calls == 50
    @test !haskey(new_kwargs, :config)
    @test new_kwargs == (; a = 1, b = 2)

    # No config in kwargs
    kwargs = (d = 4, e = 5)
    new_kwargs, config = extract_config(kwargs, RetryConfig())
    @test config == RetryConfig()
    @test new_kwargs == kwargs

    # Empty kwargs
    kwargs = NamedTuple()
    new_kwargs, config = extract_config(kwargs, RetryConfig())
    @test config == RetryConfig()
    @test new_kwargs == NamedTuple()
end

@testset "split_multi_samples" begin

    # Test for handling a conversation with no AIMessages
    userMsg = PT.UserMessage("This is a user message.")
    @test split_multi_samples([userMsg]) == [[userMsg]]

    # Test for handling a single AIMessage with no sample ID
    conv = [userMsg,
        AIMessage(;
            content = "AI message with no sample ID", run_id = 1, sample_id = nothing)]
    @test split_multi_samples(conv) == [conv]

    # Splitting conversation
    conv = [PT.SystemMessage("Say hi!"), PT.SystemMessage("Hello!"),
        PT.AIMessage(; content = "hi1", run_id = 1, sample_id = 1),
        PT.AIMessage(; content = "hi2", run_id = 1, sample_id = 2)
    ]
    @test split_multi_samples(conv) == [conv[1:3], conv[[1, 2, 4]]]

    # Test for handling a conversation with only a single AIMessage sample
    conv = [userMsg,
        AIMessage(; content = "AI message with no sample ID", run_id = 1, sample_id = 1)]
    @test split_multi_samples(conv) == [conv]

    # No AI Message
    conv = [PT.SystemMessage("Say hi!"), PT.SystemMessage("Hello!"),
        PT.SystemMessage("Hello!"), PT.SystemMessage("Hello!")]
    @test split_multi_samples(conv) == [conv]

    # Do not change if AIMessage is not the last one
    conv = [PT.SystemMessage("Say hi!"), PT.SystemMessage("Hello!"),
        PT.AIMessage(; content = "hi1", run_id = 1, sample_id = 1),
        PT.AIMessage(; content = "hi2", run_id = 1, sample_id = 2),
        PT.SystemMessage("Hello")
    ]
    @test split_multi_samples(conv) == [conv]

    # Test for handling an empty conversation
    @test split_multi_samples([]) == [[]]
end

@testset "truncate_conversation" begin
    conversation = [
        PT.SystemMessage("Hello"),
        PT.UserMessage("World"),
        PT.AIMessage("Hello"),
        PT.UserMessage("World"),
        PT.AIMessage("Hello"),
        PT.UserMessage("World"),
        PT.AIMessage("Hello"),
        PT.UserMessage("World")
    ]
    #### Test 1: Short Conversation
    truncated = truncate_conversation(conversation, max_conversation_length = 32000)
    @test length(truncated) == length(conversation)
    @test truncated === conversation

    #### Test 2: Exactly Max Length Conversation
    truncated = truncate_conversation(conversation,
        max_conversation_length = 15)
    @test sum(x -> length(x.content), truncated) <= 15

    #### Test 3: Exactly Two Messages
    truncated = truncate_conversation(conversation, max_conversation_length = 1)
    @test length(truncated) == 2
    @test truncated == conversation[(end - 1):end]

    ### Test 4: Keep System Image and User Image
    truncated = truncate_conversation(conversation, max_conversation_length = 20)
    @test length(truncated) == 4
    @test truncated == vcat(conversation[begin:(begin + 1)], conversation[(end - 1):end])

    #### Test 5: No Messages
    conversation = PT.AbstractMessage[]
    truncated = truncate_conversation(conversation, max_conversation_length = 32000)
    @test isempty(truncated)
end

@testset "beta_sample,gamma_sample" begin
    N = 1000
    tolerance_mean = 0.05 # Tolerance for mean comparison
    tolerance_variance = 0.02 # A tighter tolerance for variance, adjust based on observed precision

    # Test 1: Alpha and Beta are integers > 1
    α, β = 2, 3
    expected_mean = α / (α + β)
    expected_variance = (α * β) / ((α + β)^2 * (α + β + 1))
    samples = [beta_sample(α, β) for _ in 1:N]
    sample_mean = mean(samples)
    sample_variance = var(samples, corrected = true)
    @test abs(sample_mean - expected_mean) < tolerance_mean
    @test abs(sample_variance - expected_variance) < tolerance_variance

    # Test 2: Alpha and Beta are large integers
    α, β = 10, 10
    expected_mean = α / (α + β)
    expected_variance = (α * β) / ((α + β)^2 * (α + β + 1))
    sample_values = [beta_sample(α, β) for _ in 1:N]
    @test abs(mean(sample_values) - expected_mean) < tolerance_mean
    @test abs(var(sample_values, corrected = true) - expected_variance) < tolerance_variance

    # Test 3: Alpha and Beta are floats > 1
    α, β = 2.5, 3.5
    expected_mean = α / (α + β)
    expected_variance = (α * β) / ((α + β)^2 * (α + β + 1))
    sample_values = [beta_sample(α, β) for _ in 1:N]
    @test abs(mean(sample_values) - expected_mean) < tolerance_mean
    @test abs(var(sample_values, corrected = true) - expected_variance) < tolerance_variance

    # Test 4: Alpha < 1 and Beta > 1
    α, β = 0.5, 5
    expected_mean = α / (α + β)
    expected_variance = (α * β) / ((α + β)^2 * (α + β + 1))
    sample_values = [beta_sample(α, β) for _ in 1:N]
    @test abs(mean(sample_values) - expected_mean) < tolerance_mean
    @test abs(var(sample_values, corrected = true) - expected_variance) < tolerance_variance

    # Test 5: Alpha > 1 and Beta < 1
    α, β = 5, 0.5
    expected_mean = α / (α + β)
    expected_variance = (α * β) / ((α + β)^2 * (α + β + 1))
    sample_values = [beta_sample(α, β) for _ in 1:N]
    @test abs(mean(sample_values) - expected_mean) < tolerance_mean
    @test abs(var(sample_values, corrected = true) - expected_variance) < tolerance_variance

    # Test 6: Alpha and Beta are both < 1
    α, β = 0.5, 0.5
    expected_mean = α / (α + β)
    expected_variance = (α * β) / ((α + β)^2 * (α + β + 1))
    sample_values = [beta_sample(α, β) for _ in 1:N]
    @test abs(mean(sample_values) - expected_mean) < tolerance_mean
    @test abs(var(sample_values, corrected = true) - expected_variance) < tolerance_variance

    # Test 7: Alpha = 1 and Beta = 1 (Uniform distribution)
    α, β = 1, 1
    expected_mean = α / (α + β)
    expected_variance = (α * β) / ((α + β)^2 * (α + β + 1))
    sample_values = [beta_sample(α, β) for _ in 1:N]
    @test abs(mean(sample_values) - expected_mean) < tolerance_mean
    @test abs(var(sample_values, corrected = true) - expected_variance) < tolerance_variance

    # Test 8: Very small Alpha and Beta
    α, β = 0.1, 0.1
    expected_mean = α / (α + β)
    expected_variance = (α * β) / ((α + β)^2 * (α + β + 1))
    sample_values = [beta_sample(α, β) for _ in 1:N]
    @test abs(mean(sample_values) - expected_mean) < tolerance_mean
    @test abs(var(sample_values, corrected = true) - expected_variance) < tolerance_variance

    # Test 9: Very large Alpha and Beta
    α, β = 100, 100
    expected_mean = α / (α + β)
    expected_variance = (α * β) / ((α + β)^2 * (α + β + 1))
    sample_values = [beta_sample(α, β) for _ in 1:N]
    @test abs(mean(sample_values) - expected_mean) < tolerance_mean
    @test abs(var(sample_values, corrected = true) - expected_variance) < tolerance_variance
end
