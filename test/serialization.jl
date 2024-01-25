using PromptingTools: AIMessage,
    SystemMessage, UserMessage, UserMessageWithImages, AbstractMessage, DataMessage
using PromptingTools: save_conversation, load_conversation
using PromptingTools: save_template, load_template

@testset "Serialization - Messages" begin
    # Test save_conversation
    messages = AbstractMessage[SystemMessage("System message 1"),
        UserMessage("User message"),
        AIMessage("AI message"),
        UserMessageWithImages(; content = "a", image_url = String["b", "c"]),
        DataMessage(;
            content = "Data message")]
    tmp, _ = mktemp()
    save_conversation(tmp, messages)
    # Test load_conversation
    loaded_messages = load_conversation(tmp)
    @test loaded_messages == messages
end

@testset "Serialization - Templates" begin
    description = "Some description"
    version = "1.1"
    msgs = [
        SystemMessage("You are an impartial AI judge evaluting whether the provided statement is \"true\" or \"false\". Answer \"unknown\" if you cannot decide."),
        UserMessage("# Statement\n\n{{it}}"),
    ]
    tmp, _ = mktemp()
    save_template(tmp,
        msgs;
        description, version)
    template, metadata = load_template(tmp)
    @test template == msgs
    @test metadata[1].description == description
    @test metadata[1].version == version
    @test metadata[1].content == "Template Metadata"
    @test metadata[1].source == ""
end
