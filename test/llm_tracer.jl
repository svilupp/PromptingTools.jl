using PromptingTools: TestEchoOpenAISchema, render, OpenAISchema, TracerSchema, SaverSchema
using PromptingTools: AIMessage, SystemMessage, AbstractMessage
using PromptingTools: UserMessage, UserMessageWithImages, DataMessage, TracerMessage,
                      AIToolRequest, ToolMessage
using PromptingTools: CustomProvider,
                      CustomOpenAISchema, MistralOpenAISchema, MODEL_EMBEDDING,
                      MODEL_IMAGE_GENERATION
using PromptingTools: initialize_tracer, finalize_tracer, isaimessage, istracermessage,
                      unwrap, meta, AITemplate, render, role4render

@testset "role4render-Tracer" begin
    schema = TracerSchema(OpenAISchema())

    # unwrapping schema
    @test role4render(schema, SystemMessage("System message 1")) == "system"
    @test role4render(schema, UserMessage("User message 1")) == "user"
    @test role4render(schema, UserMessageWithImages("User message 1"; image_url = "")) ==
          "user"
    @test role4render(schema, AIMessage("AI message 1")) == "assistant"

    # unwrapping TracerMessage
    @test role4render(OpenAISchema(), TracerMessage(SystemMessage("Abc123"))) == "system"
    @test role4render(OpenAISchema(), TracerMessage(UserMessage("Abc123"))) == "user"
    @test role4render(
        OpenAISchema(), TracerMessage(UserMessageWithImages("Abc123"; image_url = ""))) ==
          "user"
    @test role4render(OpenAISchema(), TracerMessage(AIMessage("Abc123"))) == "assistant"
    @test role4render(OpenAISchema(), TracerMessage(AIToolRequest())) == "assistant"
    @test role4render(OpenAISchema(),
        TracerMessage(ToolMessage(; tool_call_id = "Fruit", raw = "", args = Dict()))) ==
          "tool"
end
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

    ## other schema
    schema = SaverSchema(OpenAISchema())
    conv = render(schema, messages)
    @test conv == messages
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
    @test meta(finalized_msg)[:temperature] == 1.0

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
    @test meta(finalized_msgs[2])[:temperature] == 1.0

    ## other schema -- SaverSchema
    schema = SaverSchema(OpenAISchema())
    tracer = initialize_tracer(schema)
    msgs = [SystemMessage("Test message 1"), SystemMessage("Test message 2")]
    conv = finalize_tracer(schema, tracer, msgs)
    fn = filter(
        x -> occursin("conversation__$(hash(msgs[1].content))", x), readdir(
            PT.LOG_DIR; join = true)) |>
         first
    @test isfile(fn)
    @test PT.load_conversation(fn) == conv
    ## clean up
    isfile(fn) && rm(fn)

    # Passthrough for non-messages (dry-runs)
    schema = TracerSchema(OpenAISchema())
    conv = finalize_tracer(schema, tracer, [1, 2, 3, 4, 5])
    @test conv == [1, 2, 3, 4, 5]
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
        schema1, "Hello World"; model = "xyz",
        tracer_kwargs = (; thread_id = :ABC1, meta = Dict(:meta_key => "meta_value")))
    @test istracermessage(msg)
    @test unwrap(msg) |> isaimessage
    @test msg.content == "Hello!"
    @test msg.model == "xyz"
    @test msg.thread_id == :ABC1
    @test msg.meta[:meta_key] == "meta_value"

    msg = aigenerate(schema1, :BlankSystemUser; system = "abc", user = "xyz")
    @test istracermessage(msg)
    @test msg.meta[:template_name] == :BlankSystemUser
    @test msg.meta[:template_version] == aitemplates(:BlankSystemUser)[1].version

    ## other schema -- SaverSchema
    schema2 = schema1 |> SaverSchema
    msgs = [TracerMessage(SystemMessage("Test message 1")), UserMessage("Hello World")]
    msg = aigenerate(
        schema2, msgs; model = "xyz", tracer_kwargs = (; thread_id = :ABC1))
    @test istracermessage(msg)
    fn = filter(
        x -> occursin("conversation__$(hash(msgs[1].content))", x), readdir(
            PT.LOG_DIR; join = true)) |>
         last
    @test isfile(fn)
    load_conv = PT.load_conversation(fn)
    @test length(load_conv) == 3
    loaded_msg = load_conv[end]
    @test unwrap(loaded_msg) |> isaimessage
    @test loaded_msg.content == "Hello!"
    @test loaded_msg.model == "xyz"
    @test loaded_msg.thread_id == :ABC1
    ## clean up
    isfile(fn) && rm(fn)

    ## Use kwargs to define save path
    file, _ = mktemp()
    msgs = [SystemMessage("Test message 1"), UserMessage("Hello World")]
    msg = aigenerate(
        schema2, msgs; model = "xyz", tracer_kwargs = (;
            thread_id = :ABC1, log_file_path = file))
    @test istracermessage(msg)
    @test isfile(file)
    load_conv = PT.load_conversation(file)
    @test length(load_conv) == 3
    loaded_msg = load_conv[end]
    @test unwrap(loaded_msg) |> isaimessage
    @test loaded_msg.content == "Hello!"
    isfile(fn) && rm(fn)
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
                Dict(:function => Dict(
                :arguments => JSON3.write(Dict(:x => 1)), :name => "RandomType1235"))
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

    # Test return_all=false (default) returns single TracerMessage
    msg = aiextract(schema1, "Extract number 1"; return_type, model = "gpt4")
    @test istracermessage(msg)
    @test !(msg isa Vector)
    @test unwrap(msg) isa DataMessage

    # Test return_all=true returns vector of TracerMessages
    conv = aiextract(
        schema1, "Extract number 1"; return_type, model = "gpt4", return_all = true)
    @test conv isa Vector
    @test length(conv) >= 1
    @test all(istracermessage, conv)
    @test istracermessage(last(conv))
    @test unwrap(last(conv)) isa DataMessage
end

# TODO: add aitools tracer tests
function calculator(x::Float64, y::Float64; operation::String = "add")
    operation == "add" ?
    x + y :
    throw(ArgumentError("Unsupported operation"))
end
@testset "aitools-Tracer" begin

    # Mock response for aitools
    mock_choice = Dict(
        :message => Dict(:content => "I'll use the calculator tool to add 2 and 3.",
            :tool_calls => [
                Dict(:id => "1",
                :function => Dict(
                    :name => "calculator",
                    :arguments => JSON3.write(Dict(:x => 2, :y => 3, :operation => "add"))
                ))
            ]),
        :logprobs => Dict(:content => [Dict(:logprob => -0.3), Dict(:logprob => -0.2)]),
        :finish_reason => "stop")

    response = Dict(:choices => [mock_choice],
        :usage => Dict(:total_tokens => 10, :prompt_tokens => 5, :completion_tokens => 5))

    schema = TestEchoOpenAISchema(; response, status = 200) |> TracerSchema

    # Define a simple calculator tool

    msg = aitools(schema, "What is 2 + 3?";
        tools = [calculator],
        model = "gpt-4",
        api_kwargs = (; temperature = 0))

    @test istracermessage(msg)
    @test unwrap(msg) isa AIToolRequest
    @test msg.content == "I'll use the calculator tool to add 2 and 3."
    @test msg.log_prob ≈ -0.5
    @test length(msg.tool_calls) == 1
    @test msg.tool_calls[1].tool_call_id == "1"
    @test msg.tool_calls[1].name == "calculator"
    @test msg.tool_calls[1].args == Dict(:x => 2, :y => 3, :operation => "add")

    # Test with AITemplate
    msg = aitools(schema, :BlankSystemUser; tools = [calculator])
    @test istracermessage(msg)
    @test unwrap(msg) isa AIToolRequest

    # Test return_all=false (default) returns single TracerMessage
    msg = aitools(schema, "What is 2 + 3?"; tools = [calculator], model = "gpt-4")
    @test istracermessage(msg)
    @test !(msg isa Vector)
    @test unwrap(msg) isa AIToolRequest

    # Test return_all=true returns vector of TracerMessages
    conv = aitools(
        schema, "What is 2 + 3?"; tools = [calculator], model = "gpt-4", return_all = true)
    @test conv isa Vector
    @test length(conv) >= 1
    @test all(istracermessage, conv)
    @test istracermessage(last(conv))
    @test unwrap(last(conv)) isa AIToolRequest
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

    # Test return_all=false (default) returns single TracerMessage
    msg = aiscan(schema1, "Describe the image";
        image_url = "https://example.com/image.png", model = "gpt4")
    @test istracermessage(msg)
    @test !(msg isa Vector)
    @test unwrap(msg) isa AIMessage

    # Test return_all=true returns vector of TracerMessages
    conv = aiscan(schema1, "Describe the image";
        image_url = "https://example.com/image.png", model = "gpt4", return_all = true)
    @test conv isa Vector
    @test length(conv) >= 1
    @test all(istracermessage, conv)
    @test istracermessage(last(conv))
    @test unwrap(last(conv)) isa AIMessage
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

    # Test return_all=false (default) returns single TracerMessage
    msg = aiimage(schema1, "Hello World")
    @test istracermessage(msg)
    @test !(msg isa Vector)
    @test unwrap(msg) isa DataMessage

    # Test return_all=true returns vector of TracerMessages
    conv = aiimage(schema1, "Hello World"; return_all = true)
    @test conv isa Vector
    @test length(conv) >= 1
    @test all(istracermessage, conv)
    @test istracermessage(last(conv))
    @test unwrap(last(conv)) isa DataMessage
end
