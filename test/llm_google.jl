## using GoogleGenAI # not needed 
using PromptingTools: TestEchoGoogleSchema, render, GoogleSchema, ggi_generate_content
using PromptingTools: AIMessage, SystemMessage, AbstractMessage
using PromptingTools: UserMessage, DataMessage

@testset "render-Google" begin
    schema = GoogleSchema()
    # Given a schema and a vector of messages with handlebar variables, it should replace the variables with the correct values in the conversation dictionary.
    messages = [
        SystemMessage("Act as a helpful AI assistant"),
        UserMessage("Hello, my name is {{name}}"),
    ]
    expected_output = [
        Dict("role" => "user",
            "parts" => [
                Dict("text" => "Act as a helpful AI assistant\n\nHello, my name is John"),
            ]),
    ]
    conversation = render(schema, messages; name = "John")
    @test conversation == expected_output
    # Test with dry_run=true on ai* functions
    test_schema = TestEchoGoogleSchema(; text = "a", status = 0)
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
          expected_output

    # AI message does NOT replace variables
    messages = [
        SystemMessage("Act as a helpful AI assistant"),
        AIMessage("Hello, my name is {{name}}"),
    ]
    expected_output = [
        Dict("role" => "user",
            "parts" => [Dict("text" => "Act as a helpful AI assistant")]),
        Dict("role" => "model", "parts" => [Dict("text" => "Hello, my name is {{name}}")]),
    ]
    conversation = render(schema, messages; name = "John")
    # Broken: AIMessage does not replace handlebar variables
    @test conversation == expected_output

    # Given a schema and a vector of messages with no system messages, it should add a default system prompt to the conversation dictionary.
    messages = [
        UserMessage("User message"),
    ]
    conversation = render(schema, messages)
    expected_output = [
        Dict("role" => "user",
            "parts" => [Dict("text" => "Act as a helpful AI assistant\n\nUser message")]),
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
        Dict("role" => "user",
            "parts" => [Dict("text" => "Act as a helpful AI assistant\n\nHello")]),
        Dict("role" => "model", "parts" => [Dict("text" => "Hi there")]),
        Dict("role" => "user", "parts" => [Dict("text" => "How are you?")]),
        Dict("role" => "model", "parts" => [Dict("text" => "I'm doing well, thank you!")]),
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
        Dict("role" => "user",
            "parts" => [Dict("text" => "This is a system message\n\nHello")]),
        Dict("role" => "model", "parts" => [Dict("text" => "Hi there")]),
    ]
    conversation = render(schema, messages)
    @test conversation == expected_output

    # Given an empty vector of messages, it should return an empty conversation dictionary just with the system prompt
    messages = AbstractMessage[]
    expected_output = [
        Dict("role" => "user",
            "parts" => [Dict("text" => "Act as a helpful AI assistant")]),
    ]
    conversation = render(schema, messages)
    @test conversation == expected_output

    # Given a schema and a vector of messages with a system message containing handlebar variables not present in kwargs, it keeps the placeholder 
    messages = [
        SystemMessage("Hello, {{name}}!"),
        UserMessage("How are you?"),
    ]
    expected_output = [
        Dict("role" => "user",
            "parts" => [Dict("text" => "Hello, {{name}}!\n\nHow are you?")]),
    ]
    conversation = render(schema, messages)
    # Broken because we do not remove any unused handlebar variables
    @test conversation == expected_output

    # Given a schema and a vector of messages with an unknown message type, it should skip the message and continue building the conversation dictionary.
    messages = [
        UserMessage("Hello"),
        DataMessage(; content = ones(3, 3)),
        AIMessage("Hi there"),
    ]
    expected_output = [
        Dict("role" => "user",
            "parts" => [Dict("text" => "Act as a helpful AI assistant\n\nHello")]),
        Dict("role" => "model", "parts" => [Dict("text" => "Hi there")]),
    ]
    conversation = render(schema, messages)
    @test conversation == expected_output

    ## Test that if either of System or User message is empty, we don't add double newlines
    messages = [
        SystemMessage("Hello, {{name}}!"),
        UserMessage(""),
    ]
    expected_output = [
        Dict("role" => "user", "parts" => [Dict("text" => "Hello, John!")]),
    ]
    conversation = render(schema, messages; name = "John")
    # Broken because we do not remove any unused handlebar variables
    @test conversation == expected_output
end

@testset "aigenerate-Google" begin
    # break without the extension
    @test_throws ArgumentError aigenerate(PT.GoogleSchema(), "Hello World")

    # corresponds to GoogleGenAI v0.1.0
    # Test the monkey patch
    schema = TestEchoGoogleSchema(; text = "Hello!", status = 200)
    msg = ggi_generate_content(schema, "", "", "Hello")
    @test msg isa TestEchoGoogleSchema

    # Real generation API
    schema1 = TestEchoGoogleSchema(; text = "Hello!", status = 200)
    msg = aigenerate(schema1, "Hello World")
    expected_output = AIMessage(;
        content = "Hello!" |> strip,
        status = 200,
        tokens = (83, 6),
        elapsed = msg.elapsed)
    @test msg == expected_output
    @test schema1.inputs == Dict{String, Any}[Dict("role" => "user",
        "parts" => [Dict("text" => "Act as a helpful AI assistant\n\nHello World")])]
    @test schema1.model_id == "gemini-pro" # default model

    # Test different input combinations and different prompts
    schema2 = TestEchoGoogleSchema(; text = "World!", status = 200)
    msg = aigenerate(schema2, UserMessage("Hello {{name}}"),
        model = "geminixx", http_kwargs = (; verbose = 3), api_kwargs = (; temperature = 0),
        name = "World")
    expected_output = AIMessage(;
        content = "World!" |> strip,
        status = 200,
        tokens = (83, 6),
        elapsed = msg.elapsed)
    @test msg == expected_output
    @test schema1.inputs == Dict{String, Any}[Dict("role" => "user",
        "parts" => [Dict("text" => "Act as a helpful AI assistant\n\nHello World")])]
    @test schema2.model_id == "geminixx"
end
