using PromptingTools: TestEchoOpenAISchema, render, OpenAISchema
using PromptingTools: AIMessage, SystemMessage, AbstractMessage
using PromptingTools: UserMessage, UserMessageWithImages, DataMessage
using PromptingTools: CustomProvider,
    CustomOpenAISchema, MistralOpenAISchema, MODEL_EMBEDDING
using PromptingTools: encode_choices, decode_choices, response_to_message, call_cost

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
    PORT = rand(10000:20000)
    echo_server = HTTP.serve!(PORT, verbose = -1) do req
        content = JSON3.read(req.body)
        user_msg = last(content[:messages])
        response = Dict(:choices => [
                Dict(:message => user_msg,
                    :logprobs => Dict(:content => [
                        Dict(:logprob => -0.1),
                        Dict(:logprob => -0.2),
                    ]),
                    :finish_reason => "stop"),
            ],
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
    @test msg.finish_reason == "stop"
    ## single message, must be nothing
    @test msg.sample_id |> isnothing
    ## sum up log probs when provided
    @test msg.log_prob ≈ -0.3

    # clean up
    close(echo_server)
end
@testset "OpenAI.create_embeddings" begin
    # Test CustomOpenAISchema() with a mock server
    PORT = rand(10000:20000)
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

@testset "response_to_message" begin
    # Mock the response and choice data
    mock_choice = Dict(:message => Dict(:content => "Hello!"),
        :logprobs => Dict(:content => [Dict(:logprob => -0.5), Dict(:logprob => -0.4)]),
        :finish_reason => "stop")
    mock_response = (;
        response = Dict(:choices => [mock_choice],
            :usage => Dict(:total_tokens => 3, :prompt_tokens => 2, :completion_tokens => 1)),
        status = 200)

    # Test with valid logprobs
    msg = response_to_message(OpenAISchema(),
        AIMessage,
        mock_choice,
        mock_response;
        model_id = "gpt4t")
    @test msg isa AIMessage
    @test msg.content == "Hello!"
    @test msg.tokens == (2, 1)
    @test msg.log_prob ≈ -0.9
    @test msg.finish_reason == "stop"
    @test msg.sample_id == nothing
    @test msg.cost == call_cost(2, 1, "gpt4t")

    # Test without logprobs
    choice = deepcopy(mock_choice)
    delete!(choice, :logprobs)
    msg = response_to_message(OpenAISchema(), AIMessage, choice, mock_response)
    @test isnothing(msg.log_prob)

    # with sample_id and run_id
    msg = response_to_message(OpenAISchema(),
        AIMessage,
        mock_choice,
        mock_response;
        run_id = 1,
        sample_id = 2,
        time = 2.0)
    @test msg.run_id == 1
    @test msg.sample_id == 2
    @test msg.elapsed == 2.0

    #### With DataMessage
    # Mock the response and choice data
    mock_choice = Dict(:message => Dict(:content => "Hello!",
            :tool_calls => [
                Dict(:function => Dict(:arguments => JSON3.write(Dict(:x => 1)))),
            ]),
        :logprobs => Dict(:content => [Dict(:logprob => -0.5), Dict(:logprob => -0.4)]),
        :finish_reason => "stop")
    mock_response = (;
        response = Dict(:choices => [mock_choice],
            :usage => Dict(:total_tokens => 3, :prompt_tokens => 2, :completion_tokens => 1)),
        status = 200)
    struct RandomType1235
        x::Int
    end
    return_type = RandomType1235
    # Catch missing return_type
    @test_throws AssertionError response_to_message(OpenAISchema(),
        DataMessage,
        mock_choice,
        mock_response;
        model_id = "gpt4t")

    # Test with valid logprobs
    msg = response_to_message(OpenAISchema(),
        DataMessage,
        mock_choice,
        mock_response;
        return_type,
        model_id = "gpt4t")
    @test msg isa DataMessage
    @test msg.content == RandomType1235(1)
    @test msg.tokens == (2, 1)
    @test msg.log_prob ≈ -0.9
    @test msg.finish_reason == "stop"
    @test msg.sample_id == nothing
    @test msg.cost == call_cost(2, 1, "gpt4t")

    # Test without logprobs
    choice = deepcopy(mock_choice)
    delete!(choice, :logprobs)
    msg = response_to_message(OpenAISchema(),
        DataMessage,
        choice,
        mock_response;
        return_type)
    @test isnothing(msg.log_prob)

    # with sample_id and run_id
    msg = response_to_message(OpenAISchema(),
        DataMessage,
        mock_choice,
        mock_response;
        return_type,
        run_id = 1,
        sample_id = 2,
        time = 2.0)
    @test msg.run_id == 1
    @test msg.sample_id == 2
    @test msg.elapsed == 2.0
end

@testset "aigenerate-OpenAI" begin
    # corresponds to OpenAI API v1
    response = Dict(:choices => [
            Dict(:message => Dict(:content => "Hello!"),
                :finish_reason => "stop"),
        ],
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
        finish_reason = "stop",
        cost = msg.cost,
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
        finish_reason = "stop",
        cost = msg.cost,
        elapsed = msg.elapsed)
    @test msg == expected_output
    @test schema1.inputs ==
          [Dict("role" => "system", "content" => "Act as a helpful AI assistant")
        Dict("role" => "user", "content" => "Hello World")]
    @test schema2.model_id == "gpt-4"

    ## Test multiple samples
    response = Dict(:choices => [
            Dict(:message => Dict(:content => "Hello1!"),
                :finish_reason => "stop"),
            Dict(:message => Dict(:content => "Hello2!"),
                :finish_reason => "stop"),
        ],
        :usage => Dict(:total_tokens => 3, :prompt_tokens => 2, :completion_tokens => 1))
    schema3 = TestEchoOpenAISchema(; response, status = 200)
    conv = aigenerate(schema3, UserMessage("Hello {{name}}"),
        model = "gpt4", http_kwargs = (; verbose = 3),
        api_kwargs = (; temperature = 0, n = 2),
        name = "World")
    @test conv[end - 1].content == "Hello1!"
    @test conv[end].content == "Hello2!"
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
        cost = msg.cost,
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
        cost = msg.cost,
        elapsed = msg.elapsed)
    @test msg == expected_output
    @test schema2.inputs == ["Hello World", "Hello back"]
    @test schema2.model_id == "gpt-4" # not possible - just an example
    msg = aiembed(schema2, view(["Hello World", "Hello back"], :),
        model = "gpt4", http_kwargs = (; verbose = 3), api_kwargs = (; temperature = 0))
    expected_output = DataMessage(;
        content = ones(128, 2),
        status = 200,
        cost = msg.cost,
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

    choices_prompt, logit_bias, ids = encode_choices(OpenAISchema(),
        [
            ("true", "If the statement is true"),
            ("false", "If the statement is false"),
        ])
    expected_prompt = "true for \"If the statement is true\"\nfalse for \"If the statement is false\""
    expected_logit_bias = Dict(837 => 100, 905 => 100)
    @test choices_prompt == expected_prompt
    @test logit_bias == expected_logit_bias
    @test ids == ["true", "false"]

    # Test encoding with an invalid number of choices
    @test_throws ArgumentError encode_choices(OpenAISchema(), string.(collect(1:100)))
    @test_throws ArgumentError encode_choices(OpenAISchema(), [("$i", "$i") for i in 1:50])

    @test_throws ArgumentError encode_choices(PT.OllamaSchema(), ["true", "false"])
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

    # Decode with multiple samples
    conv = [
        AIMessage("1"), # do not touch, different run
        AIMessage(; content = "1", run_id = 1, sample_id = 1),
        AIMessage(; content = "1", run_id = 1, sample_id = 2),
    ]
    decoded_conv = decode_choices(OpenAISchema(), ["true", "false"], conv)
    @test decoded_conv[1].content == "1"
    @test decoded_conv[2].content == "true"
    @test decoded_conv[3].content == "true"

    # Nothing (when dry_run=true)
    @test isnothing(decode_choices(OpenAISchema(), ["true", "false"], nothing))

    # unimplemented
    @test_throws ArgumentError decode_choices(PT.OllamaSchema(),
        ["true", "false"],
        AIMessage("invalid"))
end

@testset "aiclassify-OpenAI" begin
    # corresponds to OpenAI API v1
    response = Dict(:choices => [
            Dict(:message => Dict(:content => "1"),
                :finish_reason => "stop"),
        ],
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
        finish_reason = "stop",
        cost = msg.cost,
        elapsed = msg.elapsed)
    @test msg == expected_output
    @test schema1.inputs ==
          Dict{String, Any}[Dict("role" => "system",
            "content" => "You are a world-class classification specialist. \n\nYour task is to select the most appropriate label from the given choices for the given user input.\n\n**Available Choices:**\n---\n1. \"A\" for any animal or creature\n2. \"P\" for for any plant or tree\n3. \"O\" for for everything else\n---\n\n**Instructions:**\n- You must respond in one word. \n- You must respond only with the label ID (e.g., \"1\", \"2\", ...) that best fits the input.\n"),
        Dict("role" => "user", "content" => "User Input: pelican\n\nLabel:\n")]
end

@testset "aiextract-OpenAI" begin
    # mock return type
    struct RandomType1235
        x::Int
    end
    return_type = RandomType1235

    mock_choice = Dict(:message => Dict(:content => "Hello!",
            :tool_calls => [
                Dict(:function => Dict(:arguments => JSON3.write(Dict(:x => 1)))),
            ]),
        :logprobs => Dict(:content => [Dict(:logprob => -0.5), Dict(:logprob => -0.4)]),
        :finish_reason => "stop")
    ## Test with a single sample
    response = Dict(:choices => [mock_choice],
        :usage => Dict(:total_tokens => 3, :prompt_tokens => 2, :completion_tokens => 1))
    schema1 = TestEchoOpenAISchema(; response, status = 200)
    msg = aiextract(schema1, "Extract number 1"; return_type,
        model = "gpt4",
        api_kwargs = (; temperature = 0, n = 2))
    @test msg.content == RandomType1235(1)
    @test msg.log_prob ≈ -0.9

    ## Test multiple samples -- mock_choice is less probable
    mock_choice2 = Dict(:message => Dict(:content => "Hello!",
            :tool_calls => [
                Dict(:function => Dict(:arguments => JSON3.write(Dict(:x => 1)))),
            ]),
        :logprobs => Dict(:content => [Dict(:logprob => -1.2), Dict(:logprob => -0.4)]),
        :finish_reason => "stop")

    response = Dict(:choices => [mock_choice, mock_choice2],
        :usage => Dict(:total_tokens => 3, :prompt_tokens => 2, :completion_tokens => 1))
    schema2 = TestEchoOpenAISchema(; response, status = 200)
    conv = aiextract(schema2, "Extract number 1"; return_type,
        model = "gpt4",
        api_kwargs = (; temperature = 0, n = 2))
    @test conv[1].content == RandomType1235(1)
    @test conv[1].log_prob ≈ -1.6 # sorted first, despite sent later
    @test conv[2].content == RandomType1235(1)
    @test conv[2].log_prob ≈ -0.9

    ## Wrong return_type so it returns a Dict
    struct RandomType1236
        x::Int
        y::Int
    end
    return_type = RandomType1236
    conv = aiextract(schema2, "Extract number 1"; return_type,
        model = "gpt4",
        api_kwargs = (; temperature = 0, n = 2))
    conv[1].content isa AbstractDict
    conv[2].content isa AbstractDict
end

@testset "aiscan-OpenAI" begin
    ## Test with single sample and log_probs samples
    response = Dict(:choices => [
            Dict(:message => Dict(:content => "Hello1!"),
                :finish_reason => "stop",
                :logprobs => Dict(:content => [
                    Dict(:logprob => -0.1),
                    Dict(:logprob => -0.2),
                ])),
        ],
        :usage => Dict(:total_tokens => 3, :prompt_tokens => 2, :completion_tokens => 1))
    schema1 = TestEchoOpenAISchema(; response, status = 200)
    msg = aiscan(schema1, "Describe the image";
        image_url = "https://example.com/image.png",
        model = "gpt4", http_kwargs = (; verbose = 3),
        api_kwargs = (; temperature = 0))
    @test msg.content == "Hello1!"
    @test msg.log_prob ≈ -0.3

    ## Test multiple samples
    response = Dict(:choices => [
            Dict(:message => Dict(:content => "Hello1!"),
                :finish_reason => "stop"),
            Dict(:message => Dict(:content => "Hello2!"),
                :finish_reason => "stop"),
        ],
        :usage => Dict(:total_tokens => 3, :prompt_tokens => 2, :completion_tokens => 1))
    schema1 = TestEchoOpenAISchema(; response, status = 200)
    conv = aiscan(schema1, "Describe the image";
        image_url = "https://example.com/image.png",
        model = "gpt4", http_kwargs = (; verbose = 3),
        api_kwargs = (; temperature = 0, n = 2))
    @test conv[end - 1].content == "Hello1!"
    @test conv[end].content == "Hello2!"
end
