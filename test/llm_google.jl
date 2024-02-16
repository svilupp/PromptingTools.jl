using GoogleGenAI
using PromptingTools: TestEchoGoogleSchema, render, GoogleSchema, MockEchoGoogleSchema
using PromptingTools: AIMessage, SystemMessage, AbstractMessage
using PromptingTools: UserMessage, UserMessageWithImages, DataMessage

@testset "render-google" begin
    schema = GoogleSchema()
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
end

@testset "aigenerate-OpenAI" begin
    # corresponds to OpenAI API v1
    response = Dict(:choices => [Dict(:message => Dict(:content => "Hello!"))],
        :usage => Dict(:total_tokens => 3, :prompt_tokens => 2, :completion_tokens => 1))

    # Test the monkey patch
    schema = TestEchoGoogleSchema(; response, status = 200)
    msg = ggi_generate_content(schema, "", "", "Hello")
    @test msg isa TestEchoOpenAISchema

    # Real generation API
    schema1 = TestEchoGoogleSchema(; response, status = 200)
    msg = aigenerate(schema1, "Hello World")
    expected_output = AIMessage(;
        content = "Hello!" |> strip,
        status = 200,
        tokens = (0, 0),
        elapsed = msg.elapsed)
    @test msg == expected_output
    @test schema1.inputs ==
          [Dict("role" => "system", "content" => "Act as a helpful AI assistant")
        Dict("role" => "user", "content" => "Hello World")]
    @test schema1.model_id == "gemini" # default model

    # Test different input combinations and different prompts
    schema2 = TestEchoGoogleSchema(; response, status = 200)
    msg = aigenerate(schema2, UserMessage("Hello {{name}}"),
        model = "geminixx", http_kwargs = (; verbose = 3), api_kwargs = (; temperature = 0),
        name = "World")
    expected_output = AIMessage(;
        content = "Hello!" |> strip,
        status = 200,
        tokens = (0, 0),
        elapsed = msg.elapsed)
    @test msg == expected_output
    @test schema1.inputs ==
          [Dict("role" => "system", "content" => "Act as a helpful AI assistant")
        Dict("role" => "user", "content" => "Hello World")]
    @test schema2.model_id == "geminixx"
end