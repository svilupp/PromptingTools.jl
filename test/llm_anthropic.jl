using PromptingTools: TestEchoAnthropicSchema, render, AnthropicSchema
using PromptingTools: AIMessage, SystemMessage, AbstractMessage
using PromptingTools: UserMessage, UserMessageWithImages, DataMessage
using PromptingTools: call_cost, anthropic_api, function_call_signature,
                      anthropic_extra_headers

@testset "render-Anthropic" begin
    schema = AnthropicSchema()
    # Given a schema and a vector of messages with handlebar variables, it should replace the variables with the correct values in the conversation dictionary.
    messages = [
        SystemMessage("Act as a helpful AI assistant"),
        UserMessage("Hello, my name is {{name}}")
    ]
    expected_output = (; system = "Act as a helpful AI assistant",
        conversation = [Dict("role" => "user",
            "content" => [Dict("type" => "text", "text" => "Hello, my name is John")])])
    conversation = render(schema, messages; name = "John")
    @test conversation == expected_output
    # Test with dry_run=true on ai* functions
    @test aigenerate(schema, messages; name = "John", dry_run = true) == nothing
    @test aigenerate(schema, messages; name = "John", dry_run = true, return_all = true) ==
          expected_output

    # AI message does NOT replace variables
    messages = [
        SystemMessage("Act as a helpful AI assistant"),
        AIMessage("Hello, my name is {{name}}")
    ]
    expected_output = (; system = "Act as a helpful AI assistant",
        conversation = [Dict(
            "role" => "assistant",
            "content" => [Dict("type" => "text", "text" => "Hello, my name is {{name}}")])])
    conversation = render(schema, messages; name = "John")
    # AIMessage does not replace handlebar variables
    @test conversation == expected_output

    # Given a schema and a vector of messages with no system messages, it should add a default system prompt to the conversation dictionary.
    messages = [
        UserMessage("User message")
    ]
    conversation = render(schema, messages)
    expected_output = (; system = "Act as a helpful AI assistant",
        conversation = [Dict("role" => "user",
            "content" => [Dict("type" => "text", "text" => "User message")])])
    @test conversation == expected_output

    # Given a schema and a vector of messages, it should return a conversation dictionary with the correct roles and contents for each message.
    messages = [
        UserMessage("Hello"),
        AIMessage("Hi there"),
        UserMessage("How are you?"),
        AIMessage("I'm doing well, thank you!")
    ]
    expected_output = (; system = "Act as a helpful AI assistant",
        conversation = [
            Dict(
                "role" => "user", "content" => [Dict("type" => "text", "text" => "Hello")]),
            Dict("role" => "assistant",
                "content" => [Dict("type" => "text", "text" => "Hi there")]),
            Dict("role" => "user",
                "content" => [Dict("type" => "text", "text" => "How are you?")]),
            Dict("role" => "assistant",
                "content" => [Dict(
                    "type" => "text", "text" => "I'm doing well, thank you!")])
        ])
    conversation = render(schema, messages)
    @test conversation == expected_output

    # Given a schema and a vector of messages with a system message, it should move the system to the separate slot
    messages = [
        UserMessage("Hello"),
        AIMessage("Hi there"),
        SystemMessage("This is a system message")
    ]
    expected_output = (; system = "This is a system message",
        conversation = [
            Dict(
                "role" => "user", "content" => [Dict("type" => "text", "text" => "Hello")]),
            Dict("role" => "assistant",
                "content" => [Dict("type" => "text", "text" => "Hi there")])
        ])
    conversation = render(schema, messages)
    @test conversation == expected_output

    # Given an empty vector of messages, it throws an error.
    messages = AbstractMessage[]
    @test_throws AssertionError render(schema, messages)

    # Given a schema and a vector of messages with an unknown message type, it should skip the message and continue building the conversation dictionary.
    messages = [
        UserMessage("Hello"),
        DataMessage(; content = ones(3, 3)),
        AIMessage("Hi there")
    ]
    expected_output = (; system = "Act as a helpful AI assistant",
        conversation = [
            Dict(
                "role" => "user", "content" => [Dict("type" => "text", "text" => "Hello")]),
            Dict("role" => "assistant",
                "content" => [Dict("type" => "text", "text" => "Hi there")])
        ])
    conversation = render(schema, messages)
    @test conversation == expected_output

    # Test UserMessageWithImages -- errors for now
    messages = [
        SystemMessage("System message 1"),
        UserMessageWithImages("User message"; image_url = "https://example.com/image.png")
    ]
    @test_throws Exception render(schema, messages)

    ## Tool calling
    "abc"
    struct FruitCountX
        fruit::String
        count::Int
    end
    tools = [Dict("name" => "function_xyz", "description" => "ABC",
        "input_schema" => "")]
    messages = [
        SystemMessage("Act as a helpful AI assistant"),
        UserMessage("Hello, my name is {{name}}")
    ]
    conversation = render(schema, messages; tools, name = "John")
    @test occursin("Use the function_xyz tool in your response.", conversation.system)

    tools = [Dict("name" => "function_xyz", "description" => "ABC",
            "input_schema" => ""),
        Dict("name" => "function_abc", "description" => "ABC",
            "input_schema" => "")]
    @test_logs (:warn, r"Multiple tools provided") match_mode=:any render(
        schema, messages; tools)

    ## Cache variables
    messages = [
        SystemMessage("Act as a helpful AI assistant"),
        UserMessage("Hello, my name is {{name}}")
    ]
    conversation = render(schema, messages; name = "John", cache = :system)
    expected_output = (;
        system = Dict{String, Any}[Dict("cache_control" => Dict("type" => "ephemeral"),
            "text" => "Act as a helpful AI assistant", "type" => "text")],
        conversation = [Dict("role" => "user",
            "content" => [Dict("type" => "text", "text" => "Hello, my name is John")])])
    @test conversation == expected_output

    conversation = render(schema, messages; name = "John", cache = :last)
    expected_output = (;
        system = "Act as a helpful AI assistant",
        conversation = [Dict("role" => "user",
            "content" => [Dict("type" => "text", "text" => "Hello, my name is John",
                "cache_control" => Dict("type" => "ephemeral"))])])
    @test conversation == expected_output

    conversation = render(schema, messages; name = "John", cache = :all)
    expected_output = (;
        system = Dict{String, Any}[Dict("cache_control" => Dict("type" => "ephemeral"),
            "text" => "Act as a helpful AI assistant", "type" => "text")],
        conversation = [Dict("role" => "user",
            "content" => [Dict("type" => "text", "text" => "Hello, my name is John",
                "cache_control" => Dict("type" => "ephemeral"))])])
    @test conversation == expected_output
end

@testset "anthropic_extra_headers" begin
    @test anthropic_extra_headers() == ["anthropic-version" => "2023-06-01"]

    @test anthropic_extra_headers(has_tools = true) == [
        "anthropic-version" => "2023-06-01",
        "anthropic-beta" => "tools-2024-04-04"
    ]

    @test anthropic_extra_headers(has_cache = true) == [
        "anthropic-version" => "2023-06-01",
        "anthropic-beta" => "prompt-caching-2024-07-31"
    ]

    @test anthropic_extra_headers(has_tools = true, has_cache = true) == [
        "anthropic-version" => "2023-06-01",
        "anthropic-beta" => "tools-2024-04-04",
        "anthropic-beta" => "prompt-caching-2024-07-31"
    ]
end

@testset "anthropic_api" begin
    # Invalid endpoint
    @test_throws AssertionError anthropic_api(
        AnthropicSchema(); api_key = "abc", endpoint = "embedding")

    # Invalid API key
    e = try
        anthropic_api(AnthropicSchema(); api_key = "abc")
    catch e
        e
    end
    @test e.status == 401
    s = String(e.response.body)
    @test occursin("authentication_error", s)
    @test occursin("invalid x-api-key", s)
end

@testset "aigenerate-Anthropic" begin
    # corresponds to Anthropic version 2023 June, v1
    response = Dict(
        :content => [
            Dict(:text => "Hello!")],
        :stop_reason => "stop",
        :usage => Dict(:input_tokens => 2, :output_tokens => 1))

    # Real generation API
    schema1 = TestEchoAnthropicSchema(; response, status = 200)
    msg = aigenerate(schema1, "Hello World"; model = "claudeo")
    expected_output = AIMessage(;
        content = "Hello!" |> strip,
        status = 200,
        tokens = (2, 1),
        finish_reason = "stop",
        cost = msg.cost,
        extras = Dict{Symbol, Any}(),
        elapsed = msg.elapsed)
    @test msg == expected_output
    @test schema1.inputs.system == "Act as a helpful AI assistant"
    @test schema1.inputs.messages == [Dict(
        "role" => "user", "content" => [Dict("type" => "text", "text" => "Hello World")])]
    @test schema1.model_id == "claude-3-opus-20240229"

    # Test different input combinations and different prompts
    schema2 = TestEchoAnthropicSchema(; response, status = 200)
    msg = aigenerate(schema2, UserMessage("Hello {{name}}"),
        model = "claudes", http_kwargs = (; verbose = 3), api_kwargs = (; temperature = 0),
        name = "World")
    expected_output = AIMessage(;
        content = "Hello!" |> strip,
        status = 200,
        tokens = (2, 1),
        finish_reason = "stop",
        cost = msg.cost,
        extras = Dict{Symbol, Any}(),
        elapsed = msg.elapsed)
    @test msg == expected_output
    @test schema2.inputs.system == "Act as a helpful AI assistant"
    @test schema2.inputs.messages == [Dict(
        "role" => "user", "content" => [Dict("type" => "text", "text" => "Hello World")])]
    @test schema2.model_id == "claude-3-5-sonnet-20240620"

    # With caching
    response3 = Dict(
        :content => [
            Dict(:text => "Hello!")],
        :stop_reason => "stop",
        :usage => Dict(:input_tokens => 2, :output_tokens => 1,
            :cache_creation_input_tokens => 1, :cache_read_input_tokens => 0))

    schema3 = TestEchoAnthropicSchema(; response = response3, status = 200)
    msg = aigenerate(schema3, UserMessage("Hello {{name}}"),
        model = "claudes", http_kwargs = (; verbose = 3), api_kwargs = (; temperature = 0),
        cache = :all,
        name = "World")
    expected_output = AIMessage(;
        content = "Hello!" |> strip,
        status = 200,
        tokens = (2, 1),
        finish_reason = "stop",
        cost = msg.cost,
        extras = Dict{Symbol, Any}(
            :cache_read_input_tokens => 0, :cache_creation_input_tokens => 1),
        elapsed = msg.elapsed)
    @test msg == expected_output
    @test schema3.inputs.system == [Dict("cache_control" => Dict("type" => "ephemeral"),
        "text" => "Act as a helpful AI assistant", "type" => "text")]
    @test schema3.inputs.messages == [Dict("role" => "user",
        "content" => Dict{String, Any}[Dict("cache_control" => Dict("type" => "ephemeral"),
            "text" => "Hello World", "type" => "text")])]
    @test schema3.model_id == "claude-3-5-sonnet-20240620"

    ## Bad cache
    @test_throws AssertionError aigenerate(
        schema3, UserMessage("Hello {{name}}"); model = "claudeo", cache = :bad)
end

@testset "aiextract-Anthropic" begin
    # corresponds to Anthropic version 2023 June, v1 // tool beta!
    struct Fruit
        name::String
    end
    response = Dict(
        :content => [
            Dict(:type => "tool_use", :input => Dict("name" => "banana"))],
        :stop_reason => "tool_use",
        :usage => Dict(:input_tokens => 2, :output_tokens => 1))

    # Real generation API
    schema1 = TestEchoAnthropicSchema(; response, status = 200)
    msg = aiextract(schema1, "Hello World! Banana"; model = "claudeo", return_type = Fruit)
    expected_output = DataMessage(;
        content = Fruit("banana"),
        status = 200,
        tokens = (2, 1),
        finish_reason = "tool_use",
        cost = msg.cost,
        extras = Dict{Symbol, Any}(),
        elapsed = msg.elapsed)
    @test msg == expected_output
    @test schema1.inputs.system ==
          "Act as a helpful AI assistant\n\nUse the Fruit_extractor tool in your response."
    @test schema1.inputs.messages ==
          [Dict("role" => "user",
        "content" => Dict{String, Any}[Dict(
            "text" => "Hello World! Banana", "type" => "text")])]
    @test schema1.model_id == "claude-3-opus-20240229"

    # Test badly formatted response
    response = Dict(
        :content => [
            Dict(:type => "tool_use", :input => Dict("namexxx" => "banana"))],
        :stop_reason => "tool_use",
        :usage => Dict(:input_tokens => 2, :output_tokens => 1))
    schema2 = TestEchoAnthropicSchema(; response, status = 200)
    msg = aiextract(schema2, "Hello World! Banana"; model = "claudeo", return_type = Fruit)
    @test msg.content isa AbstractDict
    @test msg.content[:namexxx] == "banana"

    # Bad finish reason
    response = Dict(
        :content => [
            Dict(:type => "text", :text => "No tools for you!")],
        :stop_reason => "stop",
        :usage => Dict(:input_tokens => 2, :output_tokens => 1))
    schema3 = TestEchoAnthropicSchema(; response, status = 200)
    msg = aiextract(schema3, "Hello World! Banana"; model = "claudeo", return_type = Fruit)
    @test msg.content == "No tools for you!"

    # With Cache
    response4 = Dict(
        :content => [
            Dict(:type => "tool_use", :input => Dict("name" => "banana"))],
        :stop_reason => "tool_use",
        :usage => Dict(:input_tokens => 2, :output_tokens => 1,
            :cache_creation_input_tokens => 1, :cache_read_input_tokens => 0))
    schema4 = TestEchoAnthropicSchema(; response = response4, status = 200)
    msg = aiextract(
        schema4, "Hello World! Banana"; model = "claudeo", return_type = Fruit, cache = :all)
    expected_output = DataMessage(;
        content = Fruit("banana"),
        status = 200,
        tokens = (2, 1),
        finish_reason = "tool_use",
        cost = msg.cost,
        extras = Dict{Symbol, Any}(
            :cache_read_input_tokens => 0, :cache_creation_input_tokens => 1),
        elapsed = msg.elapsed)
    @test msg == expected_output

    # Bad cache
    @test_throws AssertionError aiextract(
        schema4, "Hello World! Banana"; model = "claudeo",
        return_type = Fruit, cache = :bad)
end

@testset "not implemented ai* functions" begin
    @test_throws ErrorException aiembed(AnthropicSchema(), "prompt")
    @test_throws ErrorException aiclassify(AnthropicSchema(), "prompt")
    @test_throws ErrorException aiscan(AnthropicSchema(), "prompt")
    @test_throws ErrorException aiimage(AnthropicSchema(), "prompt")
end
