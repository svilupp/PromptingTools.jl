using PromptingTools: role4render, render, ShareGPTSchema
using PromptingTools: AIMessage, SystemMessage, AbstractMessage
using PromptingTools: UserMessage, UserMessageWithImages, DataMessage

@testset "render-ShareGPT" begin
    schema = ShareGPTSchema()

    role4render(schema, SystemMessage("System message 1")) == "system"
    role4render(schema, UserMessage("User message 1")) == "human"
    role4render(schema, AIMessage("AI message 1")) == "gpt"

    # Ignores any handlebar replacement, takes conversations as is
    messages = [
        SystemMessage("Act as a helpful AI assistant"),
        UserMessage("Hello, my name is {{name}}"),
        AIMessage("Hello, my name is {{name}}")
    ]
    expected_output = Dict("conversations" => [
        Dict("value" => "Act as a helpful AI assistant", "from" => "system"),
        Dict("value" => "Hello, my name is {{name}}", "from" => "human"),
        Dict("value" => "Hello, my name is {{name}}", "from" => "gpt")])
    conversation = render(schema, messages)
    @test conversation == expected_output

    # IT DOES NOT support any advanced message types (UserMessageWithImages, DataMessage)
    messages = [
        UserMessage("Hello"),
        DataMessage(; content = ones(3, 3))
    ]

    @test_throws ArgumentError render(schema, messages)

    messages = [
        SystemMessage("System message 1"),
        UserMessageWithImages("User message"; image_url = "https://example.com/image.png")
    ]
    @test_throws ArgumentError render(schema, messages)
end

@testset "not implemented ai* functions" begin
    @test_throws ErrorException aigenerate(ShareGPTSchema(), "prompt")
    @test_throws ErrorException aiembed(ShareGPTSchema(), "prompt")
    @test_throws ErrorException aiextract(ShareGPTSchema(), "prompt")
    @test_throws ErrorException aitools(ShareGPTSchema(), "prompt")
    @test_throws ErrorException aiclassify(ShareGPTSchema(), "prompt")
    @test_throws ErrorException aiscan(ShareGPTSchema(), "prompt")
    @test_throws ErrorException aiimage(ShareGPTSchema(), "prompt")
end
