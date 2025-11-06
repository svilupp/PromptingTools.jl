using PromptingTools: TestEchoOpenAISchema, render, OpenAISchema, role4render
using PromptingTools: AIMessage, SystemMessage, AbstractMessage
using PromptingTools: UserMessage, UserMessageWithImages, DataMessage, AIToolRequest,
                      ToolMessage, Tool, ToolRef
using PromptingTools: CustomProvider,
                      CustomOpenAISchema, MistralOpenAISchema, MODEL_EMBEDDING,
                      MODEL_IMAGE_GENERATION
using PromptingTools: encode_choices, decode_choices, response_to_message, call_cost,
                      isextracted, isaitoolrequest, istoolmessage
using PromptingTools: pick_tokenizer, OPENAI_TOKEN_IDS_GPT35_GPT4, OPENAI_TOKEN_IDS_GPT4O

@testset "render-OpenAI" begin
    schema = OpenAISchema()

    @test role4render(schema, SystemMessage("System message 1")) == "system"
    @test role4render(schema, UserMessage("User message 1")) == "user"
    @test role4render(schema, UserMessageWithImages("User message 1"; image_url = "")) ==
          "user"
    @test role4render(schema, AIMessage("AI message 1")) == "assistant"
    @test role4render(schema, AIToolRequest()) == "assistant"
    @test role4render(schema, ToolMessage(; tool_call_id = "x", raw = "")) == "tool"

    # Given a schema and a vector of messages with handlebar variables, it should replace the variables with the correct values in the conversation dictionary.
    messages = [
        SystemMessage("Act as a helpful AI assistant"),
        UserMessage("Hello, my name is {{name}}")
    ]
    expected_output = [
        Dict("role" => "system", "content" => "Act as a helpful AI assistant"),
        Dict("role" => "user", "content" => "Hello, my name is John")
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
        AIMessage("Hello, my name is {{name}}")
    ]
    expected_output = [
        Dict("role" => "system", "content" => "Act as a helpful AI assistant"),
        Dict("role" => "assistant", "content" => "Hello, my name is John")
    ]
    conversation = render(schema, messages; name = "John")
    # Broken: AIMessage does not replace handlebar variables
    @test_broken conversation == expected_output

    # Given a schema and a vector of messages with no system messages, it should add a default system prompt to the conversation dictionary.
    messages = [
        UserMessage("User message")
    ]
    conversation = render(schema, messages)
    expected_output = [
        Dict("role" => "system", "content" => "Act as a helpful AI assistant"),
        Dict("role" => "user", "content" => "User message")
    ]
    @test conversation == expected_output

    # Given a schema and a vector of messages, it should return a conversation dictionary with the correct roles and contents for each message.
    messages = [
        UserMessage("Hello"),
        AIMessage("Hi there"),
        UserMessage("How are you?"),
        AIMessage("I'm doing well, thank you!")
    ]
    expected_output = [
        Dict("role" => "system", "content" => "Act as a helpful AI assistant"),
        Dict("role" => "user", "content" => "Hello"),
        Dict("role" => "assistant", "content" => "Hi there"),
        Dict("role" => "user", "content" => "How are you?"),
        Dict("role" => "assistant", "content" => "I'm doing well, thank you!")
    ]
    conversation = render(schema, messages)
    @test conversation == expected_output

    # Given a schema and a vector of messages with a system message, it should move the system message to the front of the conversation dictionary.
    messages = [
        UserMessage(; content = "Hello", name = "John"),
        AIMessage(; content = "Hi there", name = "AI"),
        SystemMessage("This is a system message")
    ]
    expected_output = [
        Dict("role" => "system", "content" => "This is a system message"),
        Dict("role" => "user", "content" => "Hello", "name" => "John"),
        Dict("role" => "assistant", "content" => "Hi there", "name" => "AI")
    ]
    conversation = render(schema, messages)
    @test conversation == expected_output

    # Given an empty vector of messages, it should return an empty conversation dictionary just with the system prompt
    messages = AbstractMessage[]
    expected_output = [
        Dict("role" => "system", "content" => "Act as a helpful AI assistant")
    ]
    conversation = render(schema, messages)
    @test conversation == expected_output

    # Given a schema and a vector of messages with a system message containing handlebar variables not present in kwargs, it should replace the variables with empty strings in the conversation dictionary.
    messages = [
        SystemMessage("Hello, {{name}}!"),
        UserMessage("How are you?")
    ]
    expected_output = [
        Dict("role" => "system", "content" => "Hello, !"),
        Dict("role" => "user", "content" => "How are you?")
    ]
    conversation = render(schema, messages)
    # Broken because we do not remove any unused handlebar variables
    @test_broken conversation == expected_output

    # Given a schema and a vector of messages with an unknown message type, it should skip the message and continue building the conversation dictionary.
    messages = [
        UserMessage("Hello"),
        DataMessage(; content = ones(3, 3)),
        AIMessage("Hi there")
    ]
    expected_output = [
        Dict("role" => "system", "content" => "Act as a helpful AI assistant"),
        Dict("role" => "user", "content" => "Hello"),
        Dict("role" => "assistant", "content" => "Hi there")
    ]
    conversation = render(schema, messages)
    @test conversation == expected_output

    # Test UserMessageWithImages
    messages = [
        SystemMessage("System message 1"),
        UserMessageWithImages("User message"; image_url = "https://example.com/image.png")
    ]
    conversation = render(schema, messages)
    expected_output = Dict{String, Any}[
    Dict("role" => "system",
        "content" => "System message 1"),
    Dict(
        "role" => "user",
        "content" => Dict{String, Any}[
            Dict("text" => "User message", "type" => "text"),
            Dict(
                "image_url" => Dict("detail" => "auto",
                    "url" => "https://example.com/image.png"),
                "type" => "image_url")])]
    @test conversation == expected_output

    # Test with ToolMessage
    messages = [
        SystemMessage("System message"),
        UserMessage("User message"),
        ToolMessage(;
            tool_call_id = "tool1", raw = "", name = "calculator", args = Dict(), content = "4+4=8")
    ]
    conversation = render(schema, messages)
    expected_output = Dict{String, Any}[
    Dict(
        "role" => "system", "content" => "System message"),
    Dict(
        "role" => "user", "content" => "User message"),
    Dict(
        "role" => "tool", "tool_call_id" => "tool1",
        "name" => "calculator", "content" => "4+4=8")
]
    @test conversation == expected_output

    # Test with AIToolRequest
    args = Dict(
        :location => "London",
        :unit => "celsius"
    )
    messages = [
        SystemMessage("System message"),
        UserMessage("User message"),
        AIToolRequest(;
            tool_calls = [ToolMessage(;
            tool_call_id = "call_123",
            raw = JSON3.write(args),
            name = "get_weather",
            args)
        ])
    ]
    conversation = render(schema, messages)
    expected_output = Dict{String, Any}[
    Dict(
        "role" => "system", "content" => "System message"),
    Dict(
        "role" => "user", "content" => "User message"),
    Dict(
        "role" => "assistant",
        "content" => nothing,
        "tool_calls" => [
            Dict("id" => "call_123",
            "type" => "function",
            "function" => Dict(
                "name" => "get_weather",
                "arguments" => "{\"location\":\"London\",\"unit\":\"celsius\"}"
            ))
        ])
]
    @test conversation == expected_output

    # With empty tools
    messages = [
        SystemMessage("System message"),
        UserMessage("User message"),
        AIToolRequest(; content = "content")
    ]
    conversation = render(schema, messages)
    expected_output = Dict{String, Any}[
    Dict(
        "role" => "system", "content" => "System message"),
    Dict(
        "role" => "user", "content" => "User message"),
    Dict(
        "role" => "assistant", "content" => "content")
]
    @test conversation == expected_output

    # With a list of images and detail="low"
    messages = [
        SystemMessage("System message 2"),
        UserMessageWithImages("User message";
            image_url = [
                "https://example.com/image1.png",
                "https://example.com/image2.png"
            ])
    ]
    conversation = render(schema, messages; image_detail = "low")
    expected_output = Dict{String, Any}[
    Dict("role" => "system",
        "content" => "System message 2"),
    Dict(
        "role" => "user",
        "content" => Dict{String, Any}[
            Dict("text" => "User message", "type" => "text"),
            Dict(
                "image_url" => Dict("detail" => "low",
                    "url" => "https://example.com/image1.png"),
                "type" => "image_url"),
            Dict(
                "image_url" => Dict("detail" => "low",
                    "url" => "https://example.com/image2.png"),
                "type" => "image_url")])]
    @test conversation == expected_output
    # Test with dry_run=true
    messages_alt = [
        SystemMessage("System message 2"),
        UserMessage("User message")
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

@testset "render-tools" begin
    schema = CustomOpenAISchema()

    # Test rendering a single tool
    tool = PromptingTools.Tool(
        name = "get_weather",
        description = "Get the current weather in a given location",
        parameters = Dict(
            "type" => "object",
            "properties" => Dict(
                "location" => Dict("type" => "string"),
                "unit" => Dict("type" => "string", "enum" => ["celsius", "fahrenheit"])
            ),
            "required" => ["location"]
        ),
        callable = identity
    )

    rendered = render(schema, [tool])
    @test length(rendered) == 1
    @test rendered[1][:type] == "function"
    @test rendered[1][:function][:name] == "get_weather"
    @test rendered[1][:function][:description] ==
          "Get the current weather in a given location"
    @test rendered[1][:function][:parameters] == tool.parameters

    # Test rendering multiple tools
    tool2 = PromptingTools.Tool(
        name = "get_time",
        description = "Get the current time in a given timezone",
        parameters = Dict(
            "type" => "object",
            "properties" => Dict(
                "timezone" => Dict("type" => "string")
            ),
            "required" => ["timezone"]
        ),
        callable = identity
    )

    rendered = render(schema, [tool, tool2])
    @test length(rendered) == 2
    @test rendered[1][:function][:name] == "get_weather"
    @test rendered[2][:function][:name] == "get_time"

    # Test rendering with json_mode=true
    rendered = render(schema, [tool]; json_mode = true)
    @test haskey(rendered[1][:function], :schema)
    @test !haskey(rendered[1][:function], :parameters)
    @test !haskey(rendered[1][:function], :description)

    # Test rendering with strict=true
    strict_tool = PromptingTools.Tool(
        name = "strict_function",
        description = "A function with strict input validation",
        parameters = Dict(
            "type" => "object",
            "properties" => Dict(
                "input" => Dict("type" => "string")
            ),
            "required" => ["input"]
        ),
        callable = identity,
        strict = true
    )

    rendered = render(schema, [strict_tool])
    @test rendered[1][:function][:strict] == true

    ## ToolRef rendering
    schema = OpenAISchema()

    # Test that rendering ToolRef throws ArgumentError
    tool = ToolRef(ref = :computer)
    @test_throws ArgumentError render(schema, tool)

    # Test with json_mode=true
    @test_throws ArgumentError render(schema, tool; json_mode = true)

    # Test with multiple tools
    tools = [ToolRef(ref = :computer), ToolRef(ref = :str_replace_editor)]
    @test_throws ArgumentError render(schema, tools)
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
        response = Dict(
            :choices => [
                Dict(:message => user_msg,
                :logprobs => Dict(:content => [
                    Dict(:logprob => -0.1),
                    Dict(:logprob => -0.2)
                ]),
                :finish_reason => "stop")
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
        api_key = "test_key",  # Provide a non-empty API key
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
        api_key = "test_key",
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
            :usage => Dict(
                :total_tokens => 3, :prompt_tokens => 2, :completion_tokens => 1)),
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

    ## CamelCase usage keys
    mock_response2 = (;
        response = Dict(:choices => [mock_choice],
            :usage => Dict(:totalTokens => 3, :promptTokens => 2, :completionTokens => 1)),
        status = 200)
    msg2 = response_to_message(OpenAISchema(),
        AIMessage,
        mock_choice,
        mock_response2;
        model_id = "gpt4t")
    @test msg.tokens == (2, 1)

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
    mock_choice = Dict(
        :message => Dict(:content => "Hello!",
            :tool_calls => [
                Dict(:function => Dict(
                :arguments => JSON3.write(Dict(:x => 1)), :name => "RandomType1235"))
            ]),
        :logprobs => Dict(:content => [Dict(:logprob => -0.5), Dict(:logprob => -0.4)]),
        :finish_reason => "stop")
    mock_response = (;
        response = Dict(:choices => [mock_choice],
            :usage => Dict(
                :total_tokens => 3, :prompt_tokens => 2, :completion_tokens => 1)),
        status = 200)
    struct RandomType1235
        x::Int
    end
    return_type = RandomType1235
    tool_map = Dict("RandomType1235" => Tool(; name = "x", callable = return_type))
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
        tool_map,
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
        tool_map)
    @test isnothing(msg.log_prob)

    # with sample_id and run_id
    msg = response_to_message(OpenAISchema(),
        DataMessage,
        mock_choice,
        mock_response;
        tool_map,
        run_id = 1,
        sample_id = 2,
        time = 2.0)
    @test msg.run_id == 1
    @test msg.sample_id == 2
    @test msg.elapsed == 2.0

    ## for AIToolRequest
    # Mock data
    mock_choice = Dict(
        :message => Dict(
            :content => "This is a tool request",
            :tool_calls => [
                Dict(
                :id => "call_abc123",
                :type => "function",
                :function => Dict(
                    :name => "get_weather",
                    :arguments => "{\"location\":\"New York\"}"
                )
            )
            ]
        ),
        :finish_reason => "tool_calls",
        :logprobs => Dict(:content => [Dict(:logprob => -0.5), Dict(:logprob => -0.3)])
    )

    mock_response = (
        status = 200,
        response = Dict(
            :usage => Dict(:prompt_tokens => 10, :completion_tokens => 15)
        )
    )

    get_weather(location) = "The weather in $location is nice"
    tool_map = Dict("get_weather" => Tool(; name = "get_weather", callable = get_weather))

    # Test basic functionality
    msg = response_to_message(OpenAISchema(),
        AIToolRequest,
        mock_choice,
        mock_response;
        tool_map,
        model_id = "gpt-4")

    @test msg isa AIToolRequest
    @test msg.content == "This is a tool request"
    @test msg.status == 200
    @test msg.tokens == (10, 15)
    @test msg.log_prob ≈ -0.8
    @test msg.finish_reason == "tool_calls"
    @test msg.cost == call_cost(10, 15, "gpt-4")
    @test length(msg.tool_calls) == 1
    @test msg.tool_calls[1].tool_call_id == "call_abc123"
    @test msg.tool_calls[1].name == "get_weather"
    @test msg.tool_calls[1].args == Dict(:location => "New York")

    # Test without logprobs
    choice_no_logprobs = deepcopy(mock_choice)
    delete!(choice_no_logprobs, :logprobs)
    msg_no_logprobs = response_to_message(OpenAISchema(),
        AIToolRequest,
        choice_no_logprobs,
        mock_response;
        tool_map)
    @test isnothing(msg_no_logprobs.log_prob)

    # Test with sample_id and run_id
    msg_with_ids = response_to_message(OpenAISchema(),
        AIToolRequest,
        mock_choice,
        mock_response;
        tool_map,
        run_id = 42,
        sample_id = 7,
        time = 1.5)
    @test msg_with_ids.run_id == 42
    @test msg_with_ids.sample_id == 7
    @test msg_with_ids.elapsed == 1.5

    # Test with multiple tool calls
    mock_choice_multi = deepcopy(mock_choice)
    push!(mock_choice_multi[:message][:tool_calls],
        Dict(
            :id => "call_def456",
            :type => "function",
            :function => Dict(
                :name => "get_time",
                :arguments => "{\"timezone\":\"UTC\"}"
            )
        )
    )
    tool_map_multi = Dict(
        "get_weather" => Tool(; name = "get_weather", callable = identity),
        "get_time" => Tool(; name = "get_time", callable = identity)
    )
    msg_multi = response_to_message(OpenAISchema(),
        AIToolRequest,
        mock_choice_multi,
        mock_response;
        tool_map = tool_map_multi)
    @test length(msg_multi.tool_calls) == 2
    @test msg_multi.tool_calls[2].tool_call_id == "call_def456"
    @test msg_multi.tool_calls[2].name == "get_time"
    @test msg_multi.tool_calls[2].args == Dict(:timezone => "UTC")
end

@testset "aigenerate-OpenAI" begin
    # corresponds to OpenAI API v1
    response = Dict(
        :choices => [
            Dict(:message => Dict(:content => "Hello!"),
            :finish_reason => "stop")
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
        extras = Dict{Symbol, Any}(),
        elapsed = msg.elapsed)
    @test msg == expected_output
    @test schema1.inputs ==
          [Dict("role" => "system", "content" => "Act as a helpful AI assistant")
           Dict("role" => "user", "content" => "Hello World")]
    @test schema1.model_id == "gpt-5-mini"

    # Test different input combinations and different prompts
    schema2 = TestEchoOpenAISchema(; response, status = 200)
    msg = aigenerate(schema2, UserMessage("Hello {{name}}"),
        model = "gpt4", http_kwargs = (; verbose = 3), api_kwargs = (; temperature = 0),
        name = "World")
    expected_output = AIMessage(;
        content = "Hello!" |> strip,
        status = 200,
        tokens = (2, 1),
        extras = Dict{Symbol, Any}(),
        finish_reason = "stop",
        cost = msg.cost,
        elapsed = msg.elapsed)
    @test msg == expected_output
    @test schema1.inputs ==
          [Dict("role" => "system", "content" => "Act as a helpful AI assistant")
           Dict("role" => "user", "content" => "Hello World")]
    @test schema2.model_id == "gpt-4"

    ## Test multiple samples
    response = Dict(
        :choices => [
            Dict(:message => Dict(:content => "Hello1!"),
                :finish_reason => "stop"),
            Dict(:message => Dict(:content => "Hello2!"),
                :finish_reason => "stop")
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

@testset "pick_tokenizer" begin
    # Test for GPT-3.5 models
    @test pick_tokenizer("gpt-3.5-turbo") == OPENAI_TOKEN_IDS_GPT35_GPT4
    @test pick_tokenizer("gpt-3.5-turbo-16k") == OPENAI_TOKEN_IDS_GPT35_GPT4

    # Test for GPT-4 models
    @test pick_tokenizer("gpt-4") == OPENAI_TOKEN_IDS_GPT35_GPT4
    @test pick_tokenizer("gpt-4-32k") == OPENAI_TOKEN_IDS_GPT35_GPT4

    # Test for GPT-4 Turbo models
    @test pick_tokenizer("gpt-4-1106-preview") == OPENAI_TOKEN_IDS_GPT35_GPT4
    @test pick_tokenizer("gpt-4-0125-preview") == OPENAI_TOKEN_IDS_GPT35_GPT4

    # Test for GPT-4 Vision models
    @test pick_tokenizer("gpt-4-vision-preview") == OPENAI_TOKEN_IDS_GPT35_GPT4

    # Test for GPT-4 Turbo with vision
    @test pick_tokenizer("gpt-4-all") == OPENAI_TOKEN_IDS_GPT35_GPT4

    # Test for GPT-4 Turbo with OpenAI organization
    @test pick_tokenizer("gpt-4o") == OPENAI_TOKEN_IDS_GPT4O
    @test pick_tokenizer("gpt-4o-xyz") == OPENAI_TOKEN_IDS_GPT4O

    # Test for unsupported model
    @test_throws ArgumentError pick_tokenizer("unsupported-model")
end

@testset "encode_choices" begin
    MODEL = "gpt-4-turbo"
    # Test encoding simple string choices
    choices_prompt, logit_bias,
    ids = encode_choices(
        OpenAISchema(), ["true", "false"], model = MODEL)
    # Checks if the encoded choices format and logit_bias are correct
    @test choices_prompt == "true for \"true\"\nfalse for \"false\""
    @test logit_bias == Dict(837 => 100, 905 => 100)
    @test ids == ["true", "false"]

    # Test encoding more than two choices
    choices_prompt, logit_bias,
    ids = encode_choices(
        OpenAISchema(), ["animal", "plant"], model = MODEL)
    # Checks the format for multiple choices and correct logit_bias mapping
    @test choices_prompt == "1. \"animal\"\n2. \"plant\""
    @test logit_bias == Dict(16 => 100, 17 => 100)
    @test ids == ["animal", "plant"]

    # with descriptions
    choices_prompt, logit_bias,
    ids = encode_choices(OpenAISchema(),
        [
            ("A", "any animal or creature"),
            ("P", "for any plant or tree"),
            ("O", "for everything else")
        ], model = MODEL)
    expected_prompt = "1. \"A\" for any animal or creature\n2. \"P\" for for any plant or tree\n3. \"O\" for for everything else"
    expected_logit_bias = Dict(16 => 100, 17 => 100, 18 => 100)
    @test choices_prompt == expected_prompt
    @test logit_bias == expected_logit_bias
    @test ids == ["A", "P", "O"]

    choices_prompt, logit_bias,
    ids = encode_choices(OpenAISchema(),
        [
            ("true", "If the statement is true"),
            ("false", "If the statement is false")
        ], model = MODEL)
    expected_prompt = "true for \"If the statement is true\"\nfalse for \"If the statement is false\""
    expected_logit_bias = Dict(837 => 100, 905 => 100)
    @test choices_prompt == expected_prompt
    @test logit_bias == expected_logit_bias
    @test ids == ["true", "false"]

    # Test encoding with an invalid number of choices
    @test_throws ArgumentError encode_choices(
        OpenAISchema(), string.(collect(1:100)), model = MODEL)
    @test_throws ArgumentError encode_choices(
        OpenAISchema(), [("$i", "$i") for i in 1:50], model = MODEL)

    @test_throws ArgumentError encode_choices(
        PT.OllamaSchema(), ["true", "false"], model = MODEL)

    ## Test a few token IDs for GPT4o models
    choices_prompt, logit_bias,
    ids = encode_choices(OpenAISchema(),
        ["A", "B", "C"], model = "gpt-4o-2024-07-18")
    @test choices_prompt == "1. \"A\"\n2. \"B\"\n3. \"C\""
    @test logit_bias == Dict(16 => 100, 17 => 100, 18 => 100)
    @test ids == ["A", "B", "C"]
end

@testset "decode_choices" begin
    MODEL = "gpt-4-turbo"
    # Test decoding a choice based on its ID
    msg = AIMessage("1")
    decoded_msg = decode_choices(OpenAISchema(), ["true", "false"], msg, model = MODEL)
    @test decoded_msg.content == "true"

    # Test decoding with a direct mapping (e.g., true/false)
    msg = AIMessage("false")
    decoded_msg = decode_choices(OpenAISchema(), ["true", "false"], msg, model = MODEL)
    @test decoded_msg.content == "false"

    # Test decoding failure (invalid content)
    msg = AIMessage("invalid")
    decoded_msg = decode_choices(OpenAISchema(), ["true", "false"], msg, model = MODEL)
    @test isnothing(decoded_msg.content)

    # Decode from conversation
    conv = [AIMessage("1")]
    decoded_conv = decode_choices(OpenAISchema(), ["true", "false"], conv, model = MODEL)
    @test decoded_conv[end].content == "true"

    # Decode with multiple samples
    conv = [
        AIMessage("1"), # do not touch, different run
        AIMessage(; content = "1", run_id = 1, sample_id = 1),
        AIMessage(; content = "1", run_id = 1, sample_id = 2)
    ]
    decoded_conv = decode_choices(OpenAISchema(), ["true", "false"], conv, model = MODEL)
    @test decoded_conv[1].content == "1"
    @test decoded_conv[2].content == "true"
    @test decoded_conv[3].content == "true"

    # Nothing (when dry_run=true)
    @test isnothing(decode_choices(
        OpenAISchema(), ["true", "false"], nothing, model = MODEL))

    # unimplemented
    @test_throws ArgumentError decode_choices(PT.OllamaSchema(),
        ["true", "false"],
        AIMessage("invalid"), model = MODEL)
end

@testset "aiclassify-OpenAI" begin
    # corresponds to OpenAI API v1
    response = Dict(
        :choices => [
            Dict(:message => Dict(:content => "1"),
            :finish_reason => "stop")
        ],
        :usage => Dict(:total_tokens => 3, :prompt_tokens => 2, :completion_tokens => 1))

    # Real generation API
    schema1 = TestEchoOpenAISchema(; response, status = 200)
    choices = [
        ("A", "any animal or creature"),
        ("P", "for any plant or tree"),
        ("O", "for everything else")
    ]
    msg = aiclassify(schema1, :InputClassifier; input = "pelican", choices)
    expected_output = AIMessage(;
        content = "A",
        status = 200,
        tokens = (2, 1),
        finish_reason = "stop",
        cost = msg.cost,
        elapsed = msg.elapsed,
        extras = Dict{Symbol, Any}())
    @test msg == expected_output
    @test schema1.inputs ==
          Dict{String, Any}[
        Dict("role" => "system",
            "content" => "You are a world-class classification specialist. \n\nYour task is to select the most appropriate label from the given choices for the given user input.\n\n**Available Choices:**\n---\n1. \"A\" for any animal or creature\n2. \"P\" for for any plant or tree\n3. \"O\" for for everything else\n---\n\n**Instructions:**\n- You must respond in one word. \n- You must respond only with the label ID (e.g., \"1\", \"2\", ...) that best fits the input.\n"),
        Dict("role" => "user", "content" => "User Input: pelican\n\nLabel:\n")]

    # Return the full conversation
    conv = aiclassify(
        schema1, :InputClassifier; input = "pelican", choices, return_all = true)
    expected_output = AIMessage(;
        content = "A",
        status = 200,
        tokens = (2, 1),
        finish_reason = "stop",
        cost = conv[end].cost,
        elapsed = conv[end].elapsed,
        extras = Dict{Symbol, Any}())
    @test conv[end] == expected_output
end

@testset "aiextract-OpenAI" begin
    # mock return type
    struct RandomType1235
        x::Int
    end
    return_type = RandomType1235

    mock_choice = Dict(
        :message => Dict(:content => "Hello!",
            :reasoning_content => "Reasoning content",
            :tool_calls => [
                Dict(:function => Dict(
                :arguments => JSON3.write(Dict(:x => 1)),
                :name => "RandomType1235"))
            ]),
        :logprobs => Dict(:content => [Dict(:logprob => -0.5), Dict(:logprob => -0.4)]), :finish_reason => "stop")
    ## Test with a single sample
    response = Dict(:choices => [mock_choice],
        :usage => Dict(:total_tokens => 3, :prompt_tokens => 2, :completion_tokens => 1))
    schema1 = TestEchoOpenAISchema(; response, status = 200)
    msg = aiextract(schema1, "Extract number 1"; return_type,
        model = "gpt4",
        api_kwargs = (; temperature = 0, n = 2))
    @test msg.content == RandomType1235(1)
    @test msg.log_prob ≈ -0.9
    @test msg.extras[:reasoning_content] == "Reasoning content"

    ## Test with field descriptions
    fields = [:x => Int, :x__description => "Field 1 description"]
    msg = aiextract(schema1, "Extract number 1"; return_type = fields,
        model = "gpt4",
        api_kwargs = (; temperature = 0, n = 2))
    @test msg.content == Dict("x" => 1)

    ## Test multiple samples -- mock_choice is less probable
    mock_choice2 = Dict(
        :message => Dict(:content => "Hello!",
            :tool_calls => [
                Dict(:function => Dict(
                :arguments => JSON3.write(Dict(:x => 1)),
                :name => "RandomType1235"))
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

    ### JSON mode testing
    # Prepare mock response for JSON mode
    json_response = Dict(
        :choices => [
            Dict(
            :message => Dict(
                :content => JSON3.write(Dict(:age => 30, :height => 180, :weight => 80.0))
            ),
            :finish_reason => "stop"
        )
        ],
        :usage => Dict(:total_tokens => 20, :prompt_tokens => 15, :completion_tokens => 5)
    )
    schema_json = TestEchoOpenAISchema(; response = json_response, status = 200)

    # Define test struct
    struct TestMeasurement
        age::Int
        height::Union{Int, Nothing}
        weight::Union{Float64, Nothing}
    end

    # Test with JSON mode enabled
    msg_json = aiextract(schema_json, "James is 30, weighs 80kg. He's 180cm tall.";
        return_type = TestMeasurement,
        json_mode = true,
        model = "gpt4",
        api_kwargs = (; temperature = 0))

    @test msg_json.content isa TestMeasurement
    @test msg_json.content.age == 30
    @test msg_json.content.height == 180
    @test msg_json.content.weight == 80.0
    @test msg_json.tokens == (15, 5)

    # Test with field descriptions
    fields_with_desc = [
        :age => Int,
        :age__description => "Person's age in years",
        :height => Union{Int, Nothing},
        :height__description => "Person's height in centimeters",
        :weight => Union{Float64, Nothing},
        :weight__description => "Person's weight in kilograms"
    ]

    msg_json_fields = aiextract(schema_json, "James is 30, weighs 80kg. He's 180cm tall.";
        return_type = fields_with_desc,
        json_mode = true,
        model = "gpt4",
        api_kwargs = (; temperature = 0))

    @test isextracted(msg_json_fields.content)
    @test msg_json_fields.content.age == 30
    @test msg_json_fields.content.height == 180
    @test msg_json_fields.content.weight == 80.0

    # Test with partial information
    partial_response = Dict(
        :choices => [
            Dict(
            :message => Dict(
                :content => JSON3.write(Dict(
                :age => 25, :height => nothing, :weight => nothing))
            ),
            :finish_reason => "stop"
        )
        ],
        :usage => Dict(:total_tokens => 18, :prompt_tokens => 15, :completion_tokens => 3)
    )
    schema_partial = TestEchoOpenAISchema(; response = partial_response, status = 200)

    msg_partial = aiextract(schema_partial, "Sarah is 25 years old.";
        return_type = TestMeasurement,
        json_mode = true,
        model = "gpt4",
        api_kwargs = (; temperature = 0))

    @test msg_partial.content isa TestMeasurement
    @test msg_partial.content.age == 25
    @test msg_partial.content.height === nothing
    @test msg_partial.content.weight === nothing
    @test msg_partial.tokens == (15, 3)
end

@testset "aitools-OpenAI" begin
    # Define a test tool
    struct WeatherTool
        location::String
        date::String
    end

    # Mock response for a single tool call
    single_tool_response = Dict(
        :id => "123",
        :choices => [
            Dict(
            :message => Dict(:content => "",
                :reasoning_content => "Reasoning content",
                :tool_calls => [
                    Dict(:id => "123",
                    :function => Dict(
                        :name => "get_weather",
                        :arguments => JSON3.write(Dict(
                            :location => "New York", :date => "2023-05-01"))
                    ))
                ]),
            :finish_reason => "tool_calls")
        ],
        :usage => Dict(:total_tokens => 20, :prompt_tokens => 15, :completion_tokens => 5)
    )

    schema_single = TestEchoOpenAISchema(; response = single_tool_response, status = 200)

    msg_single = aitools(schema_single, "What's the weather in New York on May 1st, 2023?";
        tools = [Tool(; name = "get_weather", callable = WeatherTool)],
        model = "gpt4",
        api_kwargs = (; temperature = 0))

    @test isaitoolrequest(msg_single)
    @test msg_single.tool_calls[1].tool_call_id == "123"
    @test msg_single.tool_calls[1].name == "get_weather"
    @test msg_single.tool_calls[1].args[:location] == "New York"
    @test msg_single.tool_calls[1].args[:date] == "2023-05-01"
    @test msg_single.tokens == (15, 5)
    @test msg_single.extras[:reasoning_content] == "Reasoning content"

    # Mock response for multiple tool calls
    multi_tool_response = Dict(
        :choices => [
            Dict(
            :message => Dict(:content => "",
                :tool_calls => [
                    Dict(:id => "123",
                        :function => Dict(
                            :name => "get_weatherUS",
                            :arguments => JSON3.write(Dict(
                                :location => "New York", :date => "2023-05-01"))
                        )),
                    Dict(:id => "456",
                        :function => Dict(
                            :name => "get_weatherUK",
                            :arguments => JSON3.write(Dict(
                                :location => "London", :date => "2023-05-02"))
                        ))
                ]),
            :finish_reason => "tool_calls")
        ],
        :usage => Dict(:total_tokens => 30, :prompt_tokens => 20, :completion_tokens => 10)
    )

    schema_multi = TestEchoOpenAISchema(; response = multi_tool_response, status = 200)

    msg_multi = aitools(
        schema_multi, "Compare the weather in New York on May 1st and London on May 2nd, 2023.";
        tools = [Tool(; name = "get_weatherUS", callable = WeatherTool),
            Tool(; name = "get_weatherUK", callable = WeatherTool)],
        model = "gpt4",
        api_kwargs = (; temperature = 0))

    @test isaitoolrequest(msg_multi)
    @test length(msg_multi.tool_calls) == 2
    @test msg_multi.tool_calls[1].tool_call_id == "123"
    @test msg_multi.tool_calls[1].name == "get_weatherUS"
    @test msg_multi.tool_calls[1].args[:location] == "New York"
    @test msg_multi.tool_calls[1].args[:date] == "2023-05-01"
    @test msg_multi.tool_calls[2].tool_call_id == "456"
    @test msg_multi.tool_calls[2].name == "get_weatherUK"
    @test msg_multi.tool_calls[2].args[:location] == "London"
    @test msg_multi.tool_calls[2].args[:date] == "2023-05-02"
    @test msg_multi.tokens == (20, 10)

    # Test with JSON mode
    json_mode_response = Dict(
        :choices => [
            Dict(
            :id => "123",
            :message => Dict(
                :content => Dict(:location => "Tokyo", :date => "2023-05-03")
            ),
            :finish_reason => "stop")
        ],
        :usage => Dict(:total_tokens => 25, :prompt_tokens => 18, :completion_tokens => 7)
    )

    schema_json = TestEchoOpenAISchema(; response = json_mode_response, status = 200)

    msg_json = aitools(schema_json, "What's the weather in Tokyo on May 3rd, 2023?";
        tools = [Tool(; name = "get_weather", callable = WeatherTool)],
        model = "gpt4",
        json_mode = true,
        api_kwargs = (; temperature = 0))

    @test msg_json.tool_calls[1].tool_call_id == "call_$(msg_json.run_id)"
    @test msg_json.tool_calls[1].name == "get_weather"
    @test msg_json.tool_calls[1].args[:location] == "Tokyo"
    @test msg_json.tool_calls[1].args[:date] == "2023-05-03"
    @test msg_json.tokens == (18, 7)

    # Test with dry_run
    msg_dry_run = aitools(schema_single, "What's the weather in Paris tomorrow?";
        tools = [Tool(; name = "get_weather", callable = WeatherTool)],
        model = "gpt4",
        dry_run = true)

    @test msg_dry_run === nothing

    # Test with return_all
    msg_return_all = aitools(
        schema_single, "What's the weather in New York on May 1st, 2023?";
        tools = [Tool(; name = "get_weather", callable = WeatherTool)],
        model = "gpt4",
        return_all = true,
        api_kwargs = (; temperature = 0))

    @test msg_return_all isa Vector
    @test length(msg_return_all) == 3
    @test msg_return_all[1] isa SystemMessage
    @test msg_return_all[2] isa UserMessage
    @test isaitoolrequest(msg_return_all[3])
    @test msg_return_all[end].tool_calls[1].name == "get_weather"
    @test msg_return_all[end].tool_calls[1].args[:location] == "New York"
    @test msg_return_all[end].tool_calls[1].args[:date] == "2023-05-01"
end

@testset "aiscan-OpenAI" begin
    ## Test with single sample and log_probs samples
    response = Dict(
        :choices => [
            Dict(
            :message => Dict(:content => "Hello1!",
                ## Only for DeepSeek API
                :reasoning_content => "Reasoning content"),
            :finish_reason => "stop",
            :logprobs => Dict(:content => [
                Dict(:logprob => -0.1),
                Dict(:logprob => -0.2)
            ])
        )
        ],
        :usage => Dict(:total_tokens => 3, :prompt_tokens => 2, :completion_tokens => 1))
    schema1 = TestEchoOpenAISchema(; response, status = 200)
    msg = aiscan(schema1, "Describe the image";
        image_url = "https://example.com/image.png",
        model = "gpt4", http_kwargs = (; verbose = 3),
        api_kwargs = (; temperature = 0))
    @test msg.content == "Hello1!"
    @test msg.log_prob ≈ -0.3
    @test msg.extras[:reasoning_content] == "Reasoning content"
    ## Test multiple samples
    response = Dict(
        :choices => [
            Dict(:message => Dict(:content => "Hello1!"),
                :finish_reason => "stop"),
            Dict(:message => Dict(:content => "Hello2!"),
                :finish_reason => "stop")
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

@testset "aiimage-OpenAI" begin
    # corresponds to OpenAI API v1 for create_images
    payload = Dict(:url => "xyz/url", :revised_prompt => "New prompt")
    response1 = Dict(:data => [payload])
    schema1 = TestEchoOpenAISchema(; response = response1, status = 200)

    msg = aiimage(schema1, "Hello World")
    expected_output = DataMessage(;
        content = payload,
        status = 200,
        tokens = (0, 0),
        cost = msg.cost,
        elapsed = msg.elapsed)
    @test msg == expected_output
    @test schema1.inputs == "Hello World"
    @test schema1.model_id == MODEL_IMAGE_GENERATION

    # Test different inputs
    msg = aiimage(schema1, :AssistantAsk; model = "banana")
    expected_output = DataMessage(;
        content = payload,
        status = 200,
        tokens = (0, 0),
        cost = msg.cost,
        elapsed = msg.elapsed)
    @test msg == expected_output
    @test schema1.inputs == "# Question\n\n{{ask}}" # Grabs only the content of last message
    @test schema1.model_id == "banana"

    conv = aiimage(OpenAISchema(), :AssistantAsk; dry_run = true, return_all = true)
    template = PT.render(OpenAISchema(), AITemplate(:AssistantAsk)) |>
               x -> PT.render(OpenAISchema(), x)
    @test conv == template

    # Invalid inputs
    @test_throws AssertionError aiimage(OpenAISchema(), "my input"; image_size = "wrong")
    @test_throws AssertionError aiimage(OpenAISchema(), "my input"; image_n = 2)
    @test_throws AssertionError aiimage(
        OpenAISchema(), "my input"; conversation = [PT.UserMessage("hi")])
end
