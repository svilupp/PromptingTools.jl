using PromptingTools: TestEchoOllamaSchema, render, OllamaSchema, ollama_api
using PromptingTools: AIMessage, SystemMessage, AbstractMessage
using PromptingTools: UserMessage, UserMessageWithImages, DataMessage, _encode_local_image

@testset "render-Ollama" begin
    schema = OllamaSchema()
    # Test simple message rendering
    messages = [UserMessage("Hello there!")]
    expected_output = [
        Dict("role" => "system", "content" => "Act as a helpful AI assistant"),
        Dict("role" => "user", "content" => "Hello there!")]
    @test render(schema, messages) == expected_output

    # Test message rendering with handlebar variables
    messages = [UserMessage("I am {{name}}")]
    expected_output = [
        Dict("role" => "system", "content" => "Act as a helpful AI assistant"),
        Dict("role" => "user", "content" => "I am John Doe")
    ]
    @test render(schema, messages; name = "John Doe") == expected_output

    # Test message rendering with system and user messages
    messages = [
        SystemMessage("This is a system generated message."),
        UserMessage("A user generated reply.")
    ]
    expected_output = [
        Dict("role" => "system", "content" => "This is a system generated message."),
        Dict("role" => "user", "content" => "A user generated reply.")
    ]
    @test render(schema, messages) == expected_output

    # Test message rendering with images
    messages = [
        UserMessageWithImages("User message with an image";
        image_url = ["https://example.com/image.jpg"])
    ]
    expected_output = [
        Dict("role" => "system", "content" => "Act as a helpful AI assistant"),
        Dict("role" => "user",
            "content" => "User message with an image",
            "images" => ["https://example.com/image.jpg"])
    ]
    @test render(schema, messages) == expected_output
    # Test message with local image
    messages = [
        UserMessageWithImages("User message with an image";
        image_path = joinpath(@__DIR__, "data", "julia.png"), base64_only = true)
    ]
    raw_img = _encode_local_image(joinpath(@__DIR__, "data", "julia.png");
        base64_only = true)
    expected_output = [
        Dict("role" => "system", "content" => "Act as a helpful AI assistant"),
        Dict("role" => "user",
            "content" => "User message with an image",
            "images" => [raw_img])
    ]
    @test render(schema, messages) == expected_output
end

@testset "ollama_api-echo" begin
    # corresponds to standard Ollama response format on api/chat endpoint
    response = Dict(:message => Dict(:content => "Prompt message"),
        :prompt_eval_count => 2,
        :eval_count => 1)
    schema = TestEchoOllamaSchema(; response, status = 200)
    msg = ollama_api(schema,
        nothing;
        endpoint = "chat",
        messages = [SystemMessage("Hi from system.")])
    @test msg.response == response
    @test msg.status == 200
    @test schema.inputs == [SystemMessage("Hi from system.")]
end

@testset "aigenerate-OllamaSchema" begin
    response = Dict(:message => Dict(:content => "Prompt message"),
        :prompt_eval_count => 2,
        :eval_count => 1)
    schema = TestEchoOllamaSchema(; response, status = 200)

    # Test aigenerate with a simple UserMessage
    prompt = UserMessage("Say hi!")
    # Mock dry run without actual API call should return nothing
    @test aigenerate(schema, prompt; dry_run = true) === nothing

    # Return the entire conversation (assume mocked result from full conversation from API)
    conversation = aigenerate(schema, "hi"; return_all = true)
    @test last(conversation).content == "Prompt message"
    @test schema.inputs ==
          [Dict("role" => "system", "content" => "Act as a helpful AI assistant"),
        Dict("role" => "user", "content" => "hi")]
    conversation = aigenerate(schema, "hi"; return_all = true, conversation)
    @test length(conversation) == 5
    @test last(conversation).content == "Prompt message"
    @test schema.inputs ==
          [Dict("role" => "system", "content" => "Act as a helpful AI assistant"),
        Dict("role" => "user", "content" => "hi"),
        Dict("role" => "assistant", "content" => "Prompt message"),
        Dict("role" => "user", "content" => "hi")]

    # Test aigenerate handling kwargs for template replacement
    conversation = [SystemMessage("Today's weather is {{weather}}.")]
    # Mock dry run replacing the template variable
    expected_convo_output = [
        SystemMessage(; content = "Today's weather is sunny.", variables = [:weather])
    ]
    @test aigenerate(schema,
        conversation;
        weather = "sunny",
        return_all = true)[1] == expected_convo_output[1]

    # Test if subsequent eval misses the prompt_eval_count key
    response = Dict(:message => Dict(:content => "Prompt message"))
    # :prompt_eval_count => 2,
    # :eval_count => 1)
    schema = TestEchoOllamaSchema(; response, status = 200)
    msg = [aigenerate(schema, "hi") for i in 1:3] |> last
    @test msg.tokens == (0, 0)
end

# @testset "aiembed-ollama" begin
# not testing, it just forwards to previous aiembed which is already tested
# end

@testset "aiscan-OllamaSchema" begin
    response = Dict(:message => Dict(:content => "Prompt message"),
        :prompt_eval_count => 2,
        :eval_count => 1)
    schema = TestEchoOllamaSchema(; response, status = 200)

    conversation = aiscan(schema,
        "hi";
        return_all = true,
        image_path = joinpath(@__DIR__, "data", "julia.png"))
    @test last(conversation).content == "Prompt message"
    @test schema.inputs ==
          [Dict("role" => "system", "content" => "Act as a helpful AI assistant"),
        Dict("role" => "user",
            "content" => "hi",
            "images" => [
                _encode_local_image(joinpath(@__DIR__, "data", "julia.png"),
                base64_only = true)
            ])]
    @test_throws AssertionError aiscan(schema,
        "hi";
        return_all = true,
        image_url = "not-allowed-url")
end
@testset "not implemented ai* functions" begin
    @test_throws ErrorException aiextract(OllamaSchema(), "prompt")
    @test_throws ErrorException aiclassify(OllamaSchema(), "prompt")
    @test_throws ErrorException aitools(OllamaSchema(), "prompt")
end
