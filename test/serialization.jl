using PromptingTools: AIMessage,
                      SystemMessage, UserMessage, UserMessageWithImages, AbstractMessage,
                      DataMessage, ShareGPTSchema, Tool, ToolMessage, AIToolRequest,
                      AnnotationMessage, AbstractAnnotationMessage
using PromptingTools: save_conversation, load_conversation, save_conversations
using PromptingTools: save_template, load_template

@testset "Serialization - Messages" begin
    # Test save_conversation
    messages = AbstractMessage[AnnotationMessage(;
        content = "Annotation message"),
    AnnotationMessage(;
        content = "Annotation message 2", extras = Dict{Symbol, Any}(:a => 1, :b => 2)),
    SystemMessage("System message 1"),
    UserMessage("User message"),
    AIMessage("AI message"),
    UserMessageWithImages(;
        content = "a", image_url = String["b", "c"]),
    DataMessage(;
        content = "Data message"),
    AIToolRequest(;
        tool_calls = [ToolMessage(;
        tool_call_id = "1", name = "MyType", raw = "", args = Dict(:content => "x"))]),
    ToolMessage(;
        tool_call_id = "1", name = "MyType", content = "x", raw = "", args = Dict(:content => 1))]
    tmp, _ = mktemp()
    save_conversation(tmp, messages)
    # Test load_conversation
    loaded_messages = load_conversation(tmp)
    @test loaded_messages == messages

    # save and load AbstractAnnotationMessage
    msg = AnnotationMessage("Annotation message"; extras = Dict(:a => 1))
    JSON3.write(tmp, msg)
    loaded_msg = JSON3.read(tmp, AbstractAnnotationMessage)
    @test loaded_msg == msg
end

@testset "Serialization - Templates" begin
    description = "Some description"
    version = "1.1"
    msgs = [
        SystemMessage("You are an impartial AI judge evaluting whether the provided statement is \"true\" or \"false\". Answer \"unknown\" if you cannot decide."),
        UserMessage("# Statement\n\n{{it}}")
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

@testset "Serialization - Messages" begin
    # Test save_conversations
    messages = AbstractMessage[SystemMessage("System message 1"),
    UserMessage("User message"),
    AIMessage("AI message"),
    AIToolRequest(;
        tool_calls = [ToolMessage(;
        tool_call_id = "1", name = "MyType", raw = "", args = Dict(:content => "x"))]),
    ToolMessage(;
        tool_call_id = "1", name = "MyType", content = "x", raw = "", args = Dict(:content => 1))]
    dir = tempdir()
    fn = joinpath(dir, "conversations.jsonl")
    save_conversations(fn, [messages])
    s = read(fn, String)
    @test s ==
          "{\"conversations\":[{\"value\":\"System message 1\",\"from\":\"system\"},{\"value\":\"User message\",\"from\":\"human\"},{\"value\":\"AI message\",\"from\":\"gpt\"},{\"value\":null,\"from\":\"assistant\"},{\"value\":\"x\",\"from\":\"tool\"}]}"
end

@testset "Serialization - TracerMessage" begin
    conv = AbstractMessage[SystemMessage("System message 1"),
    UserMessage("User message"),
    AIMessage("AI message")]
    traced_conv = TracerMessage.(conv)
    align_tracer!(traced_conv)
    tmp, _ = mktemp()
    save_conversation(tmp, traced_conv)
    loaded_tracer = load_conversation(tmp)
    @test loaded_tracer == traced_conv

    # We cannot recover all type information !!!
    obj = Dict{String, Any}("a" => 1, "b" => 2)
    tr = TracerMessageLike(obj; from = :user, to = :ai, model = "TestModel")
    tmp, _ = mktemp()
    JSON3.write(tmp, tr)
    tr2 = JSON3.read(tmp, TracerMessageLike)
    @test tr2.from == tr.from
    @test tr2.to == tr.to
    @test unwrap(tr) == unwrap(tr2) == obj
end
