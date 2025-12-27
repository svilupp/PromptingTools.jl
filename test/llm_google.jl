## using GoogleGenAI # not needed 
using PromptingTools: TestEchoGoogleSchema, render, GoogleSchema, ggi_generate_content
using PromptingTools: AIMessage, SystemMessage, AbstractMessage
using PromptingTools: UserMessage, DataMessage
const PT = PromptingTools

@testset "render-Google" begin
    schema = GoogleSchema()
    # Given a schema and a vector of messages with handlebar variables, it should replace the variables with the correct values in the conversation dictionary.
    messages = [
        SystemMessage("Act as a helpful AI assistant"),
        UserMessage("Hello, my name is {{name}}")
    ]
    expected_conversation = [
        Dict(:role => "user",
        :parts => [
            Dict("text" => "Hello, my name is John")
        ])
    ]
    expected_system = "Act as a helpful AI assistant"
    result = render(schema, messages; name = "John")
    @test result.conversation == expected_conversation
    @test result.system_instruction == expected_system
    # Test with dry_run=true on ai* functions
    test_schema = TestEchoGoogleSchema(; text = "a", response_status = 0)
    @test aigenerate(test_schema,
        messages;
        name = "John",
        dry_run = true) ==
          nothing
    @test aigenerate(test_schema,
        messages;
        name = "John",
        dry_run = true,
        return_all = true) ==
          expected_conversation

    # AI message does NOT replace variables
    messages = [
        SystemMessage("Act as a helpful AI assistant"),
        AIMessage("Hello, my name is {{name}}")
    ]
    expected_conversation = [
        Dict(:role => "model", :parts => [Dict("text" => "Hello, my name is {{name}}")])
    ]
    expected_system = "Act as a helpful AI assistant"
    result = render(schema, messages; name = "John")
    # Broken: AIMessage does not replace handlebar variables
    @test result.conversation == expected_conversation
    @test result.system_instruction == expected_system

    # Given a schema and a vector of messages with no system messages, it should add a default system prompt to the conversation dictionary.
    messages = [
        UserMessage("User message")
    ]
    result = render(schema, messages)
    expected_conversation = [
        Dict(:role => "user",
        :parts => [Dict("text" => "User message")])
    ]
    @test result.conversation == expected_conversation
    @test result.system_instruction == "Act as a helpful AI assistant"

    # Given a schema and a vector of messages, it should return a conversation dictionary with the correct roles and contents for each message.
    messages = [
        UserMessage("Hello"),
        AIMessage("Hi there"),
        UserMessage("How are you?"),
        AIMessage("I'm doing well, thank you!")
    ]
    expected_conversation = [
        Dict(:role => "user",
            :parts => [Dict("text" => "Hello")]),
        Dict(:role => "model", :parts => [Dict("text" => "Hi there")]),
        Dict(:role => "user", :parts => [Dict("text" => "How are you?")]),
        Dict(:role => "model", :parts => [Dict("text" => "I'm doing well, thank you!")])
    ]
    result = render(schema, messages)
    @test result.conversation == expected_conversation
    @test result.system_instruction == "Act as a helpful AI assistant"

    # Given a schema and a vector of messages with a system message in the middle, it should extract the system message and keep conversation intact.
    messages = [
        UserMessage("Hello"),
        AIMessage("Hi there"),
        SystemMessage("This is a system message")
    ]
    expected_conversation = [
        Dict(:role => "user",
            :parts => [Dict("text" => "Hello")]),
        Dict(:role => "model", :parts => [Dict("text" => "Hi there")])
    ]
    result = render(schema, messages)
    @test result.conversation == expected_conversation
    @test result.system_instruction == "This is a system message"

    # Given an empty vector of messages, it should return an empty conversation dictionary just with the system prompt
    messages = AbstractMessage[]
    expected_conversation = Dict{Symbol, Any}[]
    result = render(schema, messages)
    @test result.conversation == expected_conversation
    @test result.system_instruction == "Act as a helpful AI assistant"

    # Given a schema and a vector of messages with a system message containing handlebar variables not present in kwargs, it keeps the placeholder 
    messages = [
        SystemMessage("Hello, {{name}}!"),
        UserMessage("How are you?")
    ]
    expected_conversation = [
        Dict(:role => "user",
        :parts => [Dict("text" => "How are you?")])
    ]
    expected_system = "Hello, {{name}}!"
    result = render(schema, messages)
    # Broken because we do not remove any unused handlebar variables
    @test result.conversation == expected_conversation
    @test result.system_instruction == expected_system

    # Given a schema and a vector of messages with an unknown message type, it should skip the message and continue building the conversation dictionary.
    messages = [
        UserMessage("Hello"),
        DataMessage(; content = ones(3, 3)),
        AIMessage("Hi there")
    ]
    expected_conversation = [
        Dict(:role => "user",
            :parts => [Dict("text" => "Hello")]),
        Dict(:role => "model", :parts => [Dict("text" => "Hi there")])
    ]
    result = render(schema, messages)
    @test result.conversation == expected_conversation
    @test result.system_instruction == "Act as a helpful AI assistant"

    ## Test that if either of System or User message is empty, we don't add double newlines
    messages = [
        SystemMessage("Hello, {{name}}!"),
        UserMessage("")
    ]
    expected_conversation = [
        Dict(:role => "user", :parts => [Dict("text" => "")])
    ]
    expected_system = "Hello, John!"
    result = render(schema, messages; name = "John")
    # Broken because we do not remove any unused handlebar variables
    @test result.conversation == expected_conversation
    @test result.system_instruction == expected_system

    # Test that system message as first message is extracted
    messages = [
        SystemMessage("You are a helpful assistant"),
        UserMessage("Help me with Julia"),
        AIMessage("I'd be happy to help!")
    ]
    expected_conversation = [
        Dict(:role => "user", :parts => [Dict("text" => "Help me with Julia")]),
        Dict(:role => "model", :parts => [Dict("text" => "I'd be happy to help!")])
    ]
    expected_system = "You are a helpful assistant"
    result = render(schema, messages)
    @test result.conversation == expected_conversation
    @test result.system_instruction == expected_system

    # Test that system message in middle position still works and merges user messages
    messages = [
        UserMessage("Hi"),
        SystemMessage("You are a helpful assistant"),
        UserMessage("Help me with Julia")
    ]
    expected_conversation = [
        Dict(:role => "user", :parts => [Dict("text" => "Hi\n\nHelp me with Julia")])
    ]
    result = render(schema, messages)
    @test result.conversation == expected_conversation
    @test result.system_instruction == "You are a helpful assistant"

    # Test no_system_message=true prevents extraction
    messages = [
        SystemMessage("You are a helpful assistant"),
        UserMessage("Help me")
    ]
    expected_conversation = [
        Dict(:role => "user",
        :parts => [Dict("text" => "You are a helpful assistant\n\nHelp me")])
    ]
    result = render(schema, messages; no_system_message = true)
    @test result.conversation == expected_conversation
    @test isnothing(result.system_instruction)
end

@testset "aigenerate-Google" begin
    # break without the extension
    @test_throws ArgumentError aigenerate(PT.GoogleSchema(), "Hello World")

    # corresponds to GoogleGenAI v0.1.0
    # Test the monkey patch
    schema = TestEchoGoogleSchema(; text = "Hello!", response_status = 200)
    msg = ggi_generate_content(schema, "", "", "Hello"; system_instruction = nothing)
    @test msg isa TestEchoGoogleSchema

    # Real generation API
    schema1 = TestEchoGoogleSchema(; text = "Hello!", response_status = 200)
    msg = aigenerate(schema1, "Hello World")
    # Test fields individually instead of full message equality
    @test msg.content == "Hello!"
    @test msg.status == 200
    @test msg.tokens == (50, 6)
    @test !isnothing(msg.usage)
    @test msg.usage.input_tokens == 50
    @test msg.usage.output_tokens == 6
    @test schema1.inputs == Dict{Symbol, Any}[Dict(:role => "user",
        :parts => [Dict("text" => "Hello World")])]
    @test schema1.model_id == "gemini-pro" # default model

    # Test different input combinations and different prompts
    schema2 = TestEchoGoogleSchema(; text = "World!", response_status = 200)
    msg = aigenerate(schema2, UserMessage("Hello {{name}}"),
        model = "geminixx", http_kwargs = (; verbose = 3), api_kwargs = (; temperature = 0),
        name = "World")
    # Test fields individually instead of full message equality
    @test msg.content == "World!"
    @test msg.status == 200
    @test msg.tokens == (50, 6)
    @test !isnothing(msg.usage)
    @test msg.usage.input_tokens == 50
    @test msg.usage.output_tokens == 6
    @test schema2.inputs == Dict{Symbol, Any}[Dict(:role => "user",
        :parts => [Dict("text" => "Hello World")])]
    @test schema2.model_id == "geminixx"
end

@testset "process_google_config" begin
    # Basic functionality - preserve original tests
    config_kwargs = PT.process_google_config(
        (temperature = 0.5, max_output_tokens = 100),
        "test system",
        (timeout = 30,)
    )
    @test config_kwargs[:temperature] == 0.5
    @test config_kwargs[:max_output_tokens] == 100
    @test config_kwargs[:system_instruction] == "test system"
    @test config_kwargs[:http_options] == (timeout = 30,)

    config_kwargs = PT.process_google_config(NamedTuple(), nothing, NamedTuple())
    @test !haskey(config_kwargs, :system_instruction)
    @test config_kwargs[:http_options] == NamedTuple()

    schema = TestEchoGoogleSchema(; text = "Hello!", response_status = 200)
    msg = ggi_generate_content(schema, "", "", "Hello";
        system_instruction = "test",
        api_kwargs = (temperature = 0.7,),
        http_kwargs = (timeout = 60,))
    @test haskey(schema.config_kwargs, :temperature)
    @test schema.config_kwargs[:temperature] == 0.7
    @test schema.config_kwargs[:system_instruction] == "test"
    @test schema.config_kwargs[:http_options] == (timeout = 60,)

    # System instruction edge cases
    config1 = PT.process_google_config(NamedTuple(), "", NamedTuple())
    config2 = PT.process_google_config(NamedTuple(), nothing, NamedTuple())
    @test haskey(config1, :system_instruction)
    @test config1[:system_instruction] == ""
    @test !haskey(config2, :system_instruction)

    # Input type variations - Dict vs NamedTuple
    config_kwargs = PT.process_google_config(
        Dict(:temperature => 0.5, :max_output_tokens => 100),
        "test",
        Dict(:timeout => 30)
    )
    @test config_kwargs[:temperature] == 0.5
    @test config_kwargs[:max_output_tokens] == 100
    @test config_kwargs[:system_instruction] == "test"
    @test config_kwargs[:http_options][:timeout] == 30

    # Extension behavior - test both loaded and not loaded scenarios
    ext = Base.get_extension(PromptingTools, :GoogleGenAIPromptingToolsExt)

    if !isnothing(ext)
        # Test unsupported kwargs warning when extension is loaded
        @test_logs (:warn, r"The following api_kwargs are not supported.*unsupported_field") begin
            config_kwargs = PT.process_google_config(
                (temperature = 0.5, unsupported_field = 123),
                nothing,
                NamedTuple()
            )
            @test config_kwargs[:temperature] == 0.5
            @test !haskey(config_kwargs, :unsupported_field)
        end

        # Test valid fields pass through correctly
        GoogleGenAI = ext.GoogleGenAI
        valid_fields = (temperature = 0.7, max_output_tokens = 1000)
        config_kwargs = PT.process_google_config(valid_fields, nothing, NamedTuple())
        @test config_kwargs[:temperature] == 0.7
        @test config_kwargs[:max_output_tokens] == 1000
        @test_nowarn GoogleGenAI.GenerateContentConfig(; config_kwargs...)
    else
        # Test passthrough behavior when extension is not loaded
        config_kwargs = PT.process_google_config(
            (unsupported_field = 123, temperature = 0.5),
            "test system",
            (timeout = 30,)
        )
        @test config_kwargs[:unsupported_field] == 123
        @test config_kwargs[:temperature] == 0.5
        @test config_kwargs[:system_instruction] == "test system"
        @test config_kwargs[:http_options] == (timeout = 30,)
    end

    # Edge cases - boundary values
    config_kwargs = PT.process_google_config(
        (temperature = 0.0, max_output_tokens = 1),
        "",
        NamedTuple()
    )
    @test config_kwargs[:temperature] == 0.0
    @test config_kwargs[:max_output_tokens] == 1
    @test config_kwargs[:system_instruction] == ""
end

@testset "GoogleSchema - usage field" begin
    @testset "extract_usage" begin
        # Test with full metadata
        resp = (
            text = "Test response",
            response_status = 200,
            usage_metadata = (
                promptTokenCount = 100,
                candidatesTokenCount = 50,
                totalTokenCount = 150,
                cachedContentTokenCount = 30
            )
        )
        usage = PT.extract_usage(PT.GoogleSchema(), resp; model_id = "gemini-pro", elapsed = 1.5)
        @test usage.input_tokens == 100
        @test usage.output_tokens == 50
        @test usage.cache_read_tokens == 30
        @test usage.model_id == "gemini-pro"
        @test usage.elapsed == 1.5

        # Test with missing usage_metadata (should default to 0)
        resp_no_usage = (text = "response", response_status = 200)
        usage = PT.extract_usage(PT.GoogleSchema(), resp_no_usage; model_id = "gemini-pro")
        @test usage.input_tokens == 0
        @test usage.output_tokens == 0
        @test usage.cache_read_tokens == 0
    end

    @testset "aigenerate with usage" begin
        schema = PT.TestEchoGoogleSchema(;
            text = "Hello!",
            response_status = 200,
            usage_metadata = Dict{Symbol, Any}(
                :promptTokenCount => 50,
                :candidatesTokenCount => 6
            )
        )
        msg = PT.aigenerate(schema, "Test")

        @test !isnothing(msg.usage)
        @test msg.usage isa PT.TokenUsage
        @test msg.usage.input_tokens == 50
        @test msg.usage.output_tokens == 6
        @test msg.tokens == (50, 6)  # Legacy field
        @test msg.elapsed == msg.usage.elapsed
    end
end

@testset "not implemented ai* functions" begin
    @test_throws ErrorException aiembed(GoogleSchema(), "prompt")
    @test_throws ErrorException aiextract(GoogleSchema(), "prompt")
    @test_throws ErrorException aitools(GoogleSchema(), "prompt")
    @test_throws ErrorException aiclassify(GoogleSchema(), "prompt")
    @test_throws ErrorException aiscan(GoogleSchema(), "prompt")
    @test_throws ErrorException aiimage(GoogleSchema(), "prompt")
end
