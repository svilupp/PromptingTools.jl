using PromptingTools: TestEchoOpenAISchema, render, OpenAISchema, TracerSchema
using PromptingTools: AIMessage, SystemMessage, AbstractMessage
using PromptingTools: UserMessage, UserMessageWithImages, DataMessage, TracerMessage
using PromptingTools: CustomProvider,
                      CustomOpenAISchema, MistralOpenAISchema, MODEL_EMBEDDING,
                      MODEL_IMAGE_GENERATION
using PromptingTools: initialize_tracer, finalize_tracer, isaimessage, istracermessage,
                      unwrap, AITemplate

@testset "render-Tracer" begin
    schema = TracerSchema(OpenAISchema())
    # Given a schema and a vector of messages with handlebar variables, it should replace the variables with the correct values in the conversation dictionary.
    messages = [
        SystemMessage("Act as a helpful AI assistant"),
        UserMessage("Hello, my name is {{name}}")
    ]
    conv = render(schema, messages)
    @test conv == messages

    conv = render(schema, AITemplate(:InputClassifier))
    @test conv isa Vector
end

@testset "initialize_tracer" begin
    schema = TracerSchema(OpenAISchema())
    time_before = now()

    ## default initialization
    tracer = initialize_tracer(schema; tracer_kwargs = (; a = 1))
    @test tracer.time_sent >= time_before
    @test tracer.model == ""
    @test tracer.a == 1
    @test isempty(tracer.meta)

    ## custom model and tracer_kwargs
    custom_model = "custom_model"
    custom_tracer_kwargs = (parent_id = :parent, thread_id = :thread, run_id = 1)
    tracer = initialize_tracer(
        schema; model = custom_model, api_kwargs = (; temperature = 1.0),
        tracer_kwargs = custom_tracer_kwargs, _tracer_template = AITemplate(:BlankSystemUser))
    @test tracer.time_sent >= time_before
    @test tracer.model == custom_model
    @test tracer.parent_id == :parent
    @test tracer.thread_id == :thread
    @test tracer.run_id == 1
    @test tracer.meta[:temperature] == 1.0
    @test tracer.meta[:template_name] == :BlankSystemUser
    @test tracer.meta[:template_version] == aitemplates(:BlankSystemUser)[1].version
end

@testset "finalize_tracer" begin
    schema = TracerSchema(OpenAISchema())
    tracer = initialize_tracer(schema; model = "test_model",
        api_kwargs = (; temperature = 1.0),
        tracer_kwargs = (parent_id = :parent, thread_id = :thread, run_id = 1))
    time_before = now()

    #  single non-tracer message
    msg = SystemMessage("Test message")
    finalized_msg = finalize_tracer(schema, tracer, msg)
    @test finalized_msg isa TracerMessage
    @test finalized_msg.object == msg
    @test finalized_msg.model == "test_model"
    @test finalized_msg.parent_id == :parent
    @test finalized_msg.thread_id == :thread
    @test finalized_msg.run_id == 1
    @test finalized_msg.time_received >= time_before
    @test finalized_msg.meta[:temperature] == 1.0

    # vector of non-tracer messages
    msgs = [SystemMessage("Test message 1"), SystemMessage("Test message 2")]
    finalized_msgs = finalize_tracer(schema, tracer, msgs)
    @test all(istracermessage, finalized_msgs)
    @test length(finalized_msgs) == 2
    @test finalized_msgs[1].object == msgs[1]
    @test finalized_msgs[2].object == msgs[2]
    @test all(finalized_msgs) do msg
        msg.model == "test_model"
    end
    @test all(finalized_msgs) do msg
        msg.time_received >= time_before
    end

    # mixed vector of tracer and non-tracer messages
    tracer_msg = TracerMessage(;
        object = SystemMessage("Already tracer"), tracer..., time_received = now())
    msgs = [UserMessage("Test message"), tracer_msg]
    finalized_msgs = finalize_tracer(schema, tracer, msgs)
    @test all(istracermessage, finalized_msgs)
    @test length(finalized_msgs) == 2
    @test finalized_msgs[1] isa TracerMessage
    @test finalized_msgs[2] === tracer_msg # should be the same object, not a new one
end

@testset "aigenerate-Tracer" begin
    # corresponds to OpenAI API v1
    response = Dict(
        :choices => [
            Dict(:message => Dict(:content => "Hello!"),
            :finish_reason => "stop")
        ],
        :usage => Dict(:total_tokens => 3, :prompt_tokens => 2, :completion_tokens => 1))

    # Real generation API
    schema1 = TestEchoOpenAISchema(; response, status = 200) |> TracerSchema
    msg = aigenerate(
        schema1, "Hello World"; model = "xyz", tracer_kwargs = (; thread_id = :ABC1))
    @test istracermessage(msg)
    @test unwrap(msg) |> isaimessage
    @test msg.content == "Hello!"
    @test msg.model == "xyz"
    @test msg.thread_id == :ABC1

    msg = aigenerate(schema1, :BlankSystemUser)
    @test istracermessage(msg)
    @test msg.meta[:template_name] == :BlankSystemUser
    @test msg.meta[:template_version] == aitemplates(:BlankSystemUser)[1].version
end

@testset "aiembed-Tracer" begin
    # corresponds to OpenAI API v1
    response1 = Dict(:data => [Dict(:embedding => ones(128))],
        :usage => Dict(:total_tokens => 2, :prompt_tokens => 2, :completion_tokens => 0))

    # Real generation API
    schema1 = TestEchoOpenAISchema(; response = response1, status = 200) |> TracerSchema
    msg = aiembed(schema1, "Hello World")
    @test istracermessage(msg)
    @test unwrap(msg) isa DataMessage
end

@testset "aiclassify-Tracer" begin
    # corresponds to OpenAI API v1
    response = Dict(
        :choices => [
            Dict(:message => Dict(:content => "1"),
            :finish_reason => "stop")
        ],
        :usage => Dict(:total_tokens => 3, :prompt_tokens => 2, :completion_tokens => 1))

    # Real generation API
    schema1 = TestEchoOpenAISchema(; response, status = 200) |> TracerSchema
    choices = [
        ("A", "any animal or creature"),
        ("P", "for any plant or tree"),
        ("O", "for everything else")
    ]
    msg = aiclassify(schema1, :InputClassifier; input = "pelican", choices)
    @test istracermessage(msg)
    @test unwrap(msg) isa AIMessage
    @test msg.content == "A"
end

@testset "aiextract-OpenAI" begin
    # mock return type
    struct RandomType1235
        x::Int
    end
    return_type = RandomType1235

    mock_choice = Dict(
        :message => Dict(:content => "Hello!",
            :tool_calls => [
                Dict(:function => Dict(:arguments => JSON3.write(Dict(:x => 1))))
            ]),
        :logprobs => Dict(:content => [Dict(:logprob => -0.5), Dict(:logprob => -0.4)]),
        :finish_reason => "stop")
    ## Test with a single sample
    response = Dict(:choices => [mock_choice],
        :usage => Dict(:total_tokens => 3, :prompt_tokens => 2, :completion_tokens => 1))
    schema1 = TestEchoOpenAISchema(; response, status = 200) |> TracerSchema
    msg = aiextract(schema1, "Extract number 1"; return_type,
        model = "gpt4",
        api_kwargs = (; temperature = 0, n = 2))
    @test istracermessage(msg)
    @test unwrap(msg) isa DataMessage
    @test msg.content == RandomType1235(1)
    @test msg.log_prob ≈ -0.9

    msg = aiextract(schema1, :BlankSystemUser; return_type)
    @test istracermessage(msg)
end

@testset "aiscan-Tracer" begin
    ## Test with single sample and log_probs samples
    response = Dict(
        :choices => [
            Dict(:message => Dict(:content => "Hello1!"),
            :finish_reason => "stop",
            :logprobs => Dict(:content => [
                Dict(:logprob => -0.1),
                Dict(:logprob => -0.2)
            ]))
        ],
        :usage => Dict(:total_tokens => 3, :prompt_tokens => 2, :completion_tokens => 1))
    schema1 = TestEchoOpenAISchema(; response, status = 200) |> TracerSchema
    msg = aiscan(schema1, "Describe the image";
        image_url = "https://example.com/image.png",
        model = "gpt4", http_kwargs = (; verbose = 3),
        api_kwargs = (; temperature = 0))
    @test istracermessage(msg)
    @test unwrap(msg) isa AIMessage
    @test msg.content == "Hello1!"
    @test msg.log_prob ≈ -0.3

    msg = aiscan(schema1, :BlankSystemUser; image_url = "https://example.com/image.png")
    @test istracermessage(msg)
end

@testset "aiimage-Tracer" begin
    # corresponds to OpenAI API v1 for create_images
    payload = Dict(:url => "xyz/url", :revised_prompt => "New prompt")
    response1 = Dict(:data => [payload])
    schema1 = TestEchoOpenAISchema(; response = response1, status = 200) |> TracerSchema

    msg = aiimage(schema1, "Hello World")
    @test istracermessage(msg)
    @test unwrap(msg) isa DataMessage

    msg = aiimage(schema1, :BlankSystemUser)
    @test istracermessage(msg)
end
