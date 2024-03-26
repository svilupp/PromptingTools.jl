using PromptingTools: render, ShareGPTSchema
using PromptingTools: AIMessage, SystemMessage, AbstractMessage
using PromptingTools: UserMessage, UserMessageWithImages, DataMessage

## @testset "render-ShareGPT" begin
schema = ShareGPTSchema()
# Given a schema and a vector of messages with handlebar variables, it should replace the variables with the correct values in the conversation dictionary.
messages = [
    SystemMessage("Act as a helpful AI assistant"),
    UserMessage("Hello, my name is {{name}}")
]
expected_output = (; system = "Act as a helpful AI assistant",
    conversation = [Dict("role" => "user", "content" => "Hello, my name is John")])
conversation = render(schema, messages; name = "John")
@test conversation == expected_output

# AI message does NOT replace variables
messages = [
    SystemMessage("Act as a helpful AI assistant"),
    AIMessage("Hello, my name is {{name}}")
]
expected_output = (; system = "Act as a helpful AI assistant",
    conversation = [Dict(
        "role" => "assistant", "content" => "Hello, my name is {{name}}")])
conversation = render(schema, messages; name = "John")
# AIMessage does not replace handlebar variables
@test conversation == expected_output

# Given a schema and a vector of messages with no system messages, it should add a default system prompt to the conversation dictionary.
messages = [
    UserMessage("User message")
]
conversation = render(schema, messages)
expected_output = (; system = "Act as a helpful AI assistant",
    conversation = [Dict("role" => "user", "content" => "User message")])
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
        Dict("role" => "user", "content" => "Hello"),
        Dict("role" => "assistant", "content" => "Hi there"),
        Dict("role" => "user", "content" => "How are you?"),
        Dict("role" => "assistant", "content" => "I'm doing well, thank you!")
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
        Dict("role" => "user", "content" => "Hello"),
        Dict("role" => "assistant", "content" => "Hi there")
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
        Dict("role" => "user", "content" => "Hello"),
        Dict("role" => "assistant", "content" => "Hi there")
    ])
conversation = render(schema, messages)
@test conversation == expected_output

# Test UserMessageWithImages -- errors for now
messages = [
    SystemMessage("System message 1"),
    UserMessageWithImages("User message"; image_url = "https://example.com/image.png")
]
@test_throws Exception render(schema, messages)
## end

@testset "not implemented ai* functions" begin
    @test_throws ErrorException aigenerate(ShareGPTSchema(), "prompt")
    @test_throws ErrorException aiembed(ShareGPTSchema(), "prompt")
    @test_throws ErrorException aiextract(ShareGPTSchema(), "prompt")
    @test_throws ErrorException aiclassify(ShareGPTSchema(), "prompt")
    @test_throws ErrorException aiscan(ShareGPTSchema(), "prompt")
    @test_throws ErrorException aiimage(ShareGPTSchema(), "prompt")
end
