using PromptingTools: render, NoSchema, AbstractPromptSchema, OpenAISchema
using PromptingTools: AIMessage, SystemMessage, AbstractMessage, AbstractChatMessage
using PromptingTools: UserMessage, UserMessageWithImages, DataMessage, AIToolRequest,
                      ToolMessage, ToolRef
using PromptingTools: finalize_outputs, role4render

@testset "render-NoSchema" begin
    schema = NoSchema()

    @test role4render(schema, SystemMessage("System message 1")) == "system"
    @test role4render(schema, UserMessage("User message 1")) == "user"
    @test role4render(schema, UserMessageWithImages("User message 1"; image_url = "")) ==
          "user"
    @test role4render(schema, AIMessage("AI message 1")) == "assistant"
    @test role4render(schema, AIToolRequest()) == "assistant"
    @test role4render(schema, ToolMessage(; tool_call_id = "x", raw = "")) == "tool"
    @test_throws ArgumentError role4render(schema, DataMessage(; content = ones(3, 3)))

    # Given a schema and a vector of messages with handlebar variables, it should replace the variables with the correct values in the conversation dictionary.
    messages = [
        SystemMessage("Act as a helpful AI assistant"),
        UserMessage("Hello, my name is {{name}}")
    ]
    expected_output = [
        SystemMessage("Act as a helpful AI assistant"),
        UserMessage(;
            content = "Hello, my name is John",
            variables = [:name],
            _type = :usermessage)
    ]
    conversation = render(schema,
        messages;
        conversation = AbstractChatMessage[],
        name = "John")
    @test conversation == expected_output

    # AI message does NOT replace variables
    messages = [
        SystemMessage("Act as a helpful AI assistant"),
        AIMessage("Hello, my name is {{name}}")
    ]
    expected_output = [
        SystemMessage("Act as a helpful AI assistant"),
        AIMessage("Hello, my name is {{name}}")
    ]
    conversation = render(schema, messages; name = "John")
    # AIMessage does not replace handlebar variables
    @test conversation == expected_output

    # Given a schema and a vector of messages with no system messages, it should add a default system prompt to the conversation dictionary.
    messages = [
        UserMessage("User message")
    ]
    conversation = render(schema, messages)
    expected_output = [
        SystemMessage("Act as a helpful AI assistant"),
        UserMessage("User message")
    ]
    @test conversation == expected_output

    # Given a schema and a vector of messages and a conversation history, it should append the messages to the conversation
    conversation = [
        SystemMessage("System message 1"),
        UserMessage("Hello"),
        AIMessage("Hi there")
    ]
    messages = [
        UserMessage("How are you?"),
        AIMessage("I'm doing well, thank you!")
    ]
    expected_output = [
        SystemMessage("System message 1"),
        UserMessage("Hello"),
        AIMessage("Hi there"),
        UserMessage("How are you?"),
        AIMessage("I'm doing well, thank you!")
    ]
    conversation = render(schema, messages; conversation)
    @test conversation == expected_output

    # Replacement placeholders should be replaced only in the messages, not in the conversation history
    conversation = [
        SystemMessage("System message 1"),
        UserMessage("Hello {{name}}"),
        AIMessage("Hi there")
    ]
    messages = [
        UserMessage("How are you, {{name}}?"),
        AIMessage("I'm doing well, thank you!")
    ]
    expected_output = [
        SystemMessage("System message 1"),
        UserMessage("Hello {{name}}"),
        AIMessage("Hi there"),
        UserMessage("How are you, John?", [:name], nothing, :usermessage),
        AIMessage("I'm doing well, thank you!")
    ]
    conversation = render(schema, messages; conversation, name = "John")
    @test conversation == expected_output

    # Given a schema and a vector of messages with a system message, it should move the system message to the front of the conversation dictionary.
    messages = [
        UserMessage("Hello"),
        AIMessage("Hi there"),
        SystemMessage("This is a system message")
    ]
    expected_output = [
        SystemMessage("This is a system message"),
        UserMessage("Hello"),
        AIMessage("Hi there")
    ]
    conversation = render(schema, messages)
    @test conversation == expected_output

    # Given an empty vector of messages, it should return an empty conversation dictionary just with the system prompt
    messages = AbstractMessage[]
    expected_output = [
        SystemMessage("Act as a helpful AI assistant")
    ]
    conversation = render(schema, messages)
    @test conversation == expected_output

    # Given a schema and a vector of messages with a system message containing handlebar variables not present in kwargs, it should replace the variables with empty strings in the conversation dictionary.
    messages = [
        SystemMessage("Hello, {{name}}!"),
        UserMessage("How are you?")
    ]
    expected_output = [
        SystemMessage("Hello, !", [:name], :systemmessage),
        UserMessage("How are you?")
    ]
    conversation = render(schema, messages)
    # Broken because we do not remove any unused handlebar variables
    @test_broken conversation == expected_output

    # Given a schema and a vector of messages with an unknown message type, it should skip the message and continue building the conversation dictionary.
    messages = [
        SystemMessage("Act as a helpful AI assistant"),
        UserMessage("Hello"),
        DataMessage(; content = ones(3, 3)),
        AIMessage("Hi there")
    ]
    expected_output = [
        SystemMessage("Act as a helpful AI assistant"),
        UserMessage("Hello"),
        AIMessage("Hi there")
    ]
    conversation = render(schema, messages)
    @test conversation == expected_output

    # Given more than 1 system message, it should throw an error.
    messages = [
        SystemMessage("System message 1"),
        SystemMessage("System message 2"),
        UserMessage("User message")
    ]
    @test_throws ArgumentError render(schema, messages)

    # Given a schema and a vector of messages with multiple system messages, it should concatenate them together in the conversation dictionary.
    messages = [
        SystemMessage("System message 1"),
        SystemMessage("System message 2"),
        UserMessage("User message")
    ]
    # conversation = render(schema, messages)
    # expected_output = [
    #     SystemMessage("System message 1\nSystem message 2"),
    #     UserMessage("User message"),
    # ]
    # Broken: Does not concatenate system messages yet
    # @test_broken conversation == expected_output
    @test_throws ArgumentError render(schema, messages)

    # Test UserMessageWithImages
    messages = [
        SystemMessage("System message 1"),
        UserMessageWithImages("User message"; image_url = "https://example.com/image.png")
    ]
    expected_output = [
        SystemMessage("System message 1"),
        UserMessageWithImages("User message"; image_url = "https://example.com/image.png")
    ]
    conversation = render(schema, messages)
    @test conversation == expected_output

    # Test no_system_message
    messages = [
        SystemMessage("System message 1"),
        UserMessage("User message")
    ]
    expected_output = [
        UserMessage("System message 1"),
        UserMessage("User message")
    ]
    conversation = render(schema, messages; no_system_message = true)
    @test conversation[1] isa UserMessage
    @test conversation[2] isa UserMessage
    @test conversation[1].content == "System message 1"
    @test conversation[2].content == "User message"

    ## No default message 
    messages = [
        UserMessage("User message")
    ]
    expected_output = [
        UserMessage("User message")
    ]
    conversation = render(schema, messages; no_system_message = true)
    @test conversation[1] isa UserMessage
    @test conversation[1].content == "User message"

    struct WeirdSchema <: AbstractPromptSchema end
    @test_throws ArgumentError render(WeirdSchema(),
        [Tool(; name = "f", description = "f", callable = () -> nothing)])

    ## different ways to enter tools for rendering
    opt1 = render(OpenAISchema(),
        [Tool(; name = "f", description = "f", callable = () -> nothing)])
    opt2 = render(OpenAISchema(),
        Dict("f" => Tool(; name = "f", description = "f", callable = () -> nothing)))
    @test opt1 == opt2

    ## ToolRef
    schema = NoSchema()
    tool = ToolRef(; ref = :computer)
    @test_throws ArgumentError render(schema, tool)
end

@testset "finalize_outputs" begin
    # Given a vector of messages and a single message, it should return the last message.
    messages = [
        SystemMessage("System message 1"),
        UserMessage("User message"),
        AIMessage("AI message")
    ]
    msg = AIMessage("AI message 2")
    expected_output = msg
    output = finalize_outputs(messages, [], msg)
    @test output == expected_output

    # Given a vector of messages and a single message, it should return the entire conversation history.
    messages = [
        SystemMessage("System message 1"),
        UserMessage("User message"),
        AIMessage("AI message")
    ]
    msg = AIMessage("AI message 2")
    expected_output = [
        SystemMessage("System message 1"),
        UserMessage("User message"),
        AIMessage("AI message"),
        msg
    ]
    output = finalize_outputs(messages, [], msg; return_all = true)
    @test output == expected_output

    # Given a vector of messages, conversation history and a single message, it should return the entire conversation history.
    conversation = [
        SystemMessage("System message 1"),
        UserMessage("User message"),
        AIMessage("AI message")
    ]
    messages = [
        AIMessage("AI message 2")
    ]
    msg = AIMessage("AI message 3")
    expected_output = [
        SystemMessage("System message 1"),
        UserMessage("User message"),
        AIMessage("AI message"),
        AIMessage("AI message 2"),
        msg
    ]
    output = finalize_outputs(messages, [], msg; conversation, return_all = true)
    @test output == expected_output

    # Test dry run 
    conversation = [
        SystemMessage("System message 1"),
        UserMessage("User message"),
        AIMessage("AI message")
    ]
    messages = [
        AIMessage("AI message 2")
    ]
    msg = AIMessage("AI message 3")

    output = finalize_outputs(messages,
        [],
        msg;
        conversation,
        return_all = true,
        dry_run = true)
    @test output == []

    # Test that replacements are replicated properly in the messages but not in the conversation
    conversation = [
        SystemMessage("System message 1"),
        UserMessage("User message {{name}}"),
        AIMessage("AI message")
    ]
    messages = [
        UserMessage("User message {{name}}"),
        AIMessage("AI message 2")
    ]
    msg = AIMessage("AI message 3")
    expected_output = [
        SystemMessage("System message 1"),
        UserMessage("User message {{name}}"),
        AIMessage("AI message"),
        UserMessage("User message John", [:name], nothing, :usermessage),
        AIMessage("AI message 2"),
        msg
    ]
    output = finalize_outputs(messages,
        [],
        msg;
        name = "John",
        conversation,
        return_all = true)
    @test output == expected_output

    ## With multiple samples
    conversation = [
        SystemMessage("System message 1"),
        UserMessage("User message {{name}}"),
        AIMessage("AI message")
    ]
    messages = [
        UserMessage("User message {{name}}"),
        AIMessage("AI message 2")
    ]
    msg = AIMessage("AI message 3")
    expected_output = [
        SystemMessage("System message 1"),
        UserMessage("User message {{name}}"),
        AIMessage("AI message"),
        UserMessage("User message John", [:name], nothing, :usermessage),
        AIMessage("AI message 2"),
        msg,
        msg
    ]
    output = finalize_outputs(messages,
        [],
        [msg, msg];
        name = "John",
        conversation,
        return_all = true)
    @test output == expected_output
end
