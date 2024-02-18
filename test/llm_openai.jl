using PromptingTools: TestEchoOpenAISchema, render, OpenAISchema
using PromptingTools: AIMessage, SystemMessage, AbstractMessage
using PromptingTools: UserMessage, UserMessageWithImages, DataMessage
using PromptingTools: CustomProvider,
    CustomOpenAISchema, MistralOpenAISchema, MODEL_EMBEDDING
using PromptingTools: encode_choices, decode_choices

@testset "render-OpenAI" begin
    schema = OpenAISchema()
    # Given a schema and a vector of messages with handlebar variables, it should replace the variables with the correct values in the conversation dictionary.
    messages = [
        SystemMessage("Act as a helpful AI assistant"),
        UserMessage("Hello, my name is {{name}}"),
    ]
    expected_output = [
        Dict("role" => "system", "content" => "Act as a helpful AI assistant"),
        Dict("role" => "user", "content" => "Hello, my name is John"),
    ]
    conversation = render(schema, messages; name = "John")
    @test conversation == expected_output
    # Test with dry_run=true on ai* functions
    @test aigenerate(schema, messages; name = "John", dry_run = true) == nothing
    @test aigenerate(schema, messages; name = "John", dry_run = true, return_all = true) ==
          expected_output
    @test aiclassify(schema, messages; name = "John", dry_run = true) == nothing
    @test aiclassify(schema, messages; name = "John", dry_run = true, return_all = true) ==
          expected_output

    # AI message does NOT replace variables
    messages = [
        SystemMessage("Act as a helpful AI assistant"),
        AIMessage("Hello, my name is {{name}}"),
    ]
    expected_output = [
        Dict("role" => "system", "content" => "Act as a helpful AI assistant"),
        Dict("role" => "assistant", "content" => "Hello, my name is John"),
    ]
    conversation = render(schema, messages; name = "John")
    # Broken: AIMessage does not replace handlebar variables
    @test_broken conversation == expected_output

    # Given a schema and a vector of messages with no system messages, it should add a default system prompt to the conversation dictionary.
    messages = [
        UserMessage("User message"),
    ]
    conversation = render(schema, messages)
    expected_output = [
        Dict("role" => "system", "content" => "Act as a helpful AI assistant"),
        Dict("role" => "user", "content" => "User message"),
    ]
    @test conversation == expected_output

    # Given a schema and a vector of messages, it should return a conversation dictionary with the correct roles and contents for each message.
    messages = [
        UserMessage("Hello"),
        AIMessage("Hi there"),
        UserMessage("How are you?"),
        AIMessage("I'm doing well, thank you!"),
    ]
    expected_output = [
        Dict("role" => "system", "content" => "Act as a helpful AI assistant"),
        Dict("role" => "user", "content" => "Hello"),
        Dict("role" => "assistant", "content" => "Hi there"),
        Dict("role" => "user", "content" => "How are you?"),
        Dict("role" => "assistant", "content" => "I'm doing well, thank you!"),
    ]
    conversation = render(schema, messages)
    @test conversation == expected_output

    # Given a schema and a vector of messages with a system message, it should move the system message to the front of the conversation dictionary.
    messages = [
        UserMessage("Hello"),
        AIMessage("Hi there"),
        SystemMessage("This is a system message"),
    ]
    expected_output = [
        Dict("role" => "system", "content" => "This is a system message"),
        Dict("role" => "user", "content" => "Hello"),
        Dict("role" => "assistant", "content" => "Hi there"),
    ]
    conversation = render(schema, messages)
    @test conversation == expected_output

    # Given an empty vector of messages, it should return an empty conversation dictionary just with the system prompt
    messages = AbstractMessage[]
    expected_output = [
        Dict("role" => "system", "content" => "Act as a helpful AI assistant"),
    ]
    conversation = render(schema, messages)
    @test conversation == expected_output

    # Given a schema and a vector of messages with a system message containing handlebar variables not present in kwargs, it should replace the variables with empty strings in the conversation dictionary.
    messages = [
        SystemMessage("Hello, {{name}}!"),
        UserMessage("How are you?"),
    ]
    expected_output = [
        Dict("role" => "system", "content" => "Hello, !"),
        Dict("role" => "user", "content" => "How are you?"),
    ]
    conversation = render(schema, messages)
    # Broken because we do not remove any unused handlebar variables
    @test_broken conversation == expected_output

    # Given a schema and a vector of messages with an unknown message type, it should skip the message and continue building the conversation dictionary.
    messages = [
        UserMessage("Hello"),
        DataMessage(; content = ones(3, 3)),
        AIMessage("Hi there"),
    ]
    expected_output = [
        Dict("role" => "system", "content" => "Act as a helpful AI assistant"),
        Dict("role" => "user", "content" => "Hello"),
        Dict("role" => "assistant", "content" => "Hi there"),
    ]
    conversation = render(schema, messages)
    @test conversation == expected_output

    # Test UserMessageWithImages
    messages = [
        SystemMessage("System message 1"),
        UserMessageWithImages("User message"; image_url = "https://example.com/image.png"),
    ]
    conversation = render(schema, messages)
    expected_output = Dict{String, Any}[Dict("role" => "system",
            "content" => "System message 1"),
        Dict("role" => "user",
            "content" => Dict{String, Any}[Dict("text" => "User message", "type" => "text"),
                Dict("image_url" => Dict("detail" => "auto",
                        "url" => "https://example.com/image.png"),
                    "type" => "image_url")])]
    @test conversation == expected_output

    # With a list of images and detail="low"
    messages = [
        SystemMessage("System message 2"),
        UserMessageWithImages("User message";
            image_url = [
                "https://example.com/image1.png",
                "https://example.com/image2.png",
            ]),
    ]
    conversation = render(schema, messages; image_detail = "low")
    expected_output = Dict{String, Any}[Dict("role" => "system",
            "content" => "System message 2"),
        Dict("role" => "user",
            "content" => Dict{String, Any}[Dict("text" => "User message", "type" => "text"),
                Dict("image_url" => Dict("detail" => "low",
                        "url" => "https://example.com/image1.png"),
                    "type" => "image_url"),
                Dict("image_url" => Dict("detail" => "low",
                        "url" => "https://example.com/image2.png"),
                    "type" => "image_url")])]
    @test conversation == expected_output
    # Test with dry_run=true
    messages_alt = [
        SystemMessage("System message 2"),
        UserMessage("User message"),
    ]
    image_url = ["https://example.com/image1.png",
        "https://example.com/image2.png"]
    @test aiscan(schema,
        copy(messages_alt);
        image_detail = "low", image_url,
        dry_run = true,
        return_all = true) == expected_output
    @test aiscan(schema,
        copy(messages_alt);
        image_detail = "low",
        image_url,
        dry_run = true) ==
          nothing
end

@testset "OpenAI.build_url,OpenAI.auth_header" begin
    provider = CustomProvider(; base_url = "http://localhost:8082", api_version = "xyz")
    @test OpenAI.build_url(provider, "endpoint1") == "http://localhost:8082/endpoint1"
    @test OpenAI.auth_header(provider, "ABC") ==
          ["Authorization" => "Bearer ABC", "Content-Type" => "application/json"]
end

@testset "OpenAI.create_chat" begin
    # Test CustomOpenAISchema() with a mock server
    PORT = rand(1000:2000)
    echo_server = HTTP.serve!(PORT, verbose = -1) do req
        content = JSON3.read(req.body)
        user_msg = last(content[:messages])
        response = Dict(:choices => [Dict(:message => user_msg)],
            :model => content[:model],
            :usage => Dict(:total_tokens => length(user_msg[:content]),
                :prompt_tokens => length(user_msg[:content]),
                :completion_tokens => 0))
        return HTTP.Response(200, JSON3.write(response))
    end

    prompt = "Say Hi!"
    msg = aigenerate(CustomOpenAISchema(),
        prompt;
        model = "my_model",
        api_kwargs = (; url = "http://localhost:$(PORT)"),
        return_all = false)
    @test msg.content == prompt
    @test msg.tokens == (length(prompt), 0)

    # clean up
    close(echo_server)
end
@testset "OpenAI.create_embeddings" begin
    # Test CustomOpenAISchema() with a mock server
    PORT = rand(1000:2000)
    echo_server = HTTP.serve!(PORT, verbose = -1) do req
        content = JSON3.read(req.body)
        response = Dict(:data => [Dict(:embedding => ones(128))],
            :usage => Dict(:total_tokens => length(content[:input]),
                :prompt_tokens => length(content[:input]),
                :completion_tokens => 0))
        return HTTP.Response(200, JSON3.write(response))
    end

    prompt = "Embed me!!"
    msg = aiembed(CustomOpenAISchema(),
        prompt;
        model = "my_model",
        api_kwargs = (; url = "http://localhost:$(PORT)"),
        return_all = false)
    @test msg.content == ones(128)
    @test msg.tokens == (length(prompt), 0)

    # clean up
    close(echo_server)
end

@testset "aigenerate-OpenAI" begin
    # corresponds to OpenAI API v1
    response = Dict(:choices => [Dict(:message => Dict(:content => "Hello!"))],
        :usage => Dict(:total_tokens => 3, :prompt_tokens => 2, :completion_tokens => 1))

    # Test the monkey patch
    schema = TestEchoOpenAISchema(; response, status = 200)
    msg = OpenAI.create_chat(schema, "", "", "Hello")
    @test msg isa TestEchoOpenAISchema

    # Real generation API
    schema1 = TestEchoOpenAISchema(; response, status = 200)
    msg = aigenerate(schema1, "Hello World")
    expected_output = AIMessage(;
        content = "Hello!" |> strip,
        status = 200,
        tokens = (2, 1),
        elapsed = msg.elapsed)
    @test msg == expected_output
    @test schema1.inputs ==
          [Dict("role" => "system", "content" => "Act as a helpful AI assistant")
        Dict("role" => "user", "content" => "Hello World")]
    @test schema1.model_id == "gpt-3.5-turbo"

    # Test different input combinations and different prompts
    schema2 = TestEchoOpenAISchema(; response, status = 200)
    msg = aigenerate(schema2, UserMessage("Hello {{name}}"),
        model = "gpt4", http_kwargs = (; verbose = 3), api_kwargs = (; temperature = 0),
        name = "World")
    expected_output = AIMessage(;
        content = "Hello!" |> strip,
        status = 200,
        tokens = (2, 1),
        elapsed = msg.elapsed)
    @test msg == expected_output
    @test schema1.inputs ==
          [Dict("role" => "system", "content" => "Act as a helpful AI assistant")
        Dict("role" => "user", "content" => "Hello World")]
    @test schema2.model_id == "gpt-4"
end

@testset "aiembed-OpenAI" begin
    # corresponds to OpenAI API v1
    response1 = Dict(:data => [Dict(:embedding => ones(128))],
        :usage => Dict(:total_tokens => 2, :prompt_tokens => 2, :completion_tokens => 0))

    # Real generation API
    schema1 = TestEchoOpenAISchema(; response = response1, status = 200)
    msg = aiembed(schema1, "Hello World")
    expected_output = DataMessage(;
        content = ones(128),
        status = 200,
        tokens = (2, 0),
        elapsed = msg.elapsed)
    @test msg == expected_output
    @test schema1.inputs == "Hello World"
    @test schema1.model_id == MODEL_EMBEDDING

    # Test different input combinations and multiple strings
    response2 = Dict(:data => [Dict(:embedding => ones(128, 2))],
        :usage => Dict(:total_tokens => 4, :prompt_tokens => 4, :completion_tokens => 0))
    schema2 = TestEchoOpenAISchema(; response = response2, status = 200)
    msg = aiembed(schema2, ["Hello World", "Hello back"],
        model = "gpt4", http_kwargs = (; verbose = 3), api_kwargs = (; temperature = 0))
    expected_output = DataMessage(;
        content = ones(128, 2),
        status = 200,
        tokens = (4, 0),
        elapsed = msg.elapsed)
    @test msg == expected_output
    @test schema2.inputs == ["Hello World", "Hello back"]
    @test schema2.model_id == "gpt-4" # not possible - just an example
    msg = aiembed(schema2, view(["Hello World", "Hello back"], :),
        model = "gpt4", http_kwargs = (; verbose = 3), api_kwargs = (; temperature = 0))
    expected_output = DataMessage(;
        content = ones(128, 2),
        status = 200,
        tokens = (4, 0),
        elapsed = msg.elapsed)
    @test msg == expected_output
    @test schema2.inputs == ["Hello World", "Hello back"]
    @test schema2.model_id == "gpt-4" # not possible - just an example
end

@testset "encode_choices" begin
    # Test encoding simple string choices
    choices_prompt, logit_bias, ids = encode_choices(OpenAISchema(), ["true", "false"])
    # Checks if the encoded choices format and logit_bias are correct
    @test choices_prompt == "true for \"true\"\nfalse for \"false\""
    @test logit_bias == Dict(837 => 100, 905 => 100)
    @test ids == ["true", "false"]

    # Test encoding more than two choices
    choices_prompt, logit_bias, ids = encode_choices(OpenAISchema(), ["animal", "plant"])
    # Checks the format for multiple choices and correct logit_bias mapping
    @test choices_prompt == "1. \"animal\"\n2. \"plant\""
    @test logit_bias == Dict(16 => 100, 17 => 100)
    @test ids == ["animal", "plant"]

    # with descriptions
    choices_prompt, logit_bias, ids = encode_choices(OpenAISchema(),
        [
            ("A", "any animal or creature"),
            ("P", "for any plant or tree"),
            ("O", "for everything else"),
        ])
    expected_prompt = "1. \"A\" for any animal or creature\n2. \"P\" for for any plant or tree\n3. \"O\" for for everything else"
    expected_logit_bias = Dict(16 => 100, 17 => 100, 18 => 100)
    @test choices_prompt == expected_prompt
    @test logit_bias == expected_logit_bias
    @test ids == ["A", "P", "O"]

    # Test encoding with an invalid number of choices
    @test_throws ArgumentError encode_choices(OpenAISchema(), collect(1:21))
end

@testset "decode_choices" begin
    # Test decoding a choice based on its ID
    msg = AIMessage("1")
    decoded_msg = decode_choices(OpenAISchema(), ["true", "false"], msg)
    @test decoded_msg.content == "true"

    # Test decoding with a direct mapping (e.g., true/false)
    msg = AIMessage("false")
    decoded_msg = decode_choices(OpenAISchema(), ["true", "false"], msg)
    @test decoded_msg.content == "false"

    # Test decoding failure (invalid content)
    msg = AIMessage("invalid")
    decoded_msg = decode_choices(OpenAISchema(), ["true", "false"], msg)
    @test isnothing(decoded_msg.content)

    # Decode from conversation
    conv = [AIMessage("1")]
    decoded_conv = decode_choices(OpenAISchema(), ["true", "false"], conv)
    @test decoded_conv[end].content == "true"

    # Nothing (when dry_run=true)
    @test isnothing(decode_choices(OpenAISchema(), ["true", "false"], nothing))
end

@testset "aiclassify-OpenAI" begin
    # corresponds to OpenAI API v1
    response = Dict(:choices => [Dict(:message => Dict(:content => "1"))],
        :usage => Dict(:total_tokens => 3, :prompt_tokens => 2, :completion_tokens => 1))

    # Real generation API
    schema1 = TestEchoOpenAISchema(; response, status = 200)
    choices = [
        ("A", "any animal or creature"),
        ("P", "for any plant or tree"),
        ("O", "for everything else"),
    ]
    msg = aiclassify(schema1, :InputClassifier; input = "pelican", choices)
    expected_output = AIMessage(;
        content = "A",
        status = 200,
        tokens = (2, 1),
        elapsed = msg.elapsed)
    @test msg == expected_output
    @test schema1.inputs ==
          Dict{String, Any}[Dict("role" => "system",
            "content" => "You are a world-class classification specialist. \n\nYour task is to select the most appropriate label from the given choices for the given user input.\n\n**Available Choices:**\n---\n1. \"A\" for any animal or creature\n2. \"P\" for for any plant or tree\n3. \"O\" for for everything else\n---\n\n**Instructions:**\n- You must respond in one word. \n- You must respond only with the label ID (e.g., \"1\", \"2\", ...) that best fits the input.\n"),
        Dict("role" => "user", "content" => "User Input: pelican\n\nLabel:\n")]
end
