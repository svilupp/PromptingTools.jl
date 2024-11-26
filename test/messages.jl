using PromptingTools: AIMessage, SystemMessage, MetadataMessage, AbstractMessage
using PromptingTools: UserMessage, UserMessageWithImages, DataMessage, AIToolRequest,
                      ToolMessage, AnnotationMessage
using PromptingTools: _encode_local_image, attach_images_to_user_message, last_message,
                      last_output, tool_calls
using PromptingTools: isusermessage, issystemmessage, isdatamessage, isaimessage,
                      istracermessage, isaitoolrequest, istoolmessage,
                      isabstractannotationmessage
using PromptingTools: TracerMessageLike, TracerMessage, align_tracer!, unwrap,
                      AbstractTracerMessage, AbstractTracer, pprint, annotate!
using PromptingTools: TracerSchema, SaverSchema

@testset "Message constructors" begin
    # Creates an instance of MSG with the given content string.
    content = "Hello, world!"
    for T in [AIMessage, SystemMessage, UserMessage, MetadataMessage]
        # args
        msg = T(content)
        @test typeof(msg) <: T
        @test msg.content == content
        # kwargs
        msg = T(; content)
        @test typeof(msg) <: T
        @test msg.content == content
    end
    # Check the Reserved keywords
    content = "{{model}}"
    @test_throws AssertionError UserMessage(content)
    @test_throws AssertionError UserMessage(; content)
    @test_throws AssertionError SystemMessage(content)
    @test_throws AssertionError SystemMessage(; content)
    @test_throws AssertionError UserMessageWithImages(; content, image_url = ["a"])

    # Check methods
    content = "Hello, world!"
    @test UserMessage(content) |> isusermessage
    @test SystemMessage(content) |> issystemmessage
    @test DataMessage(; content) |> isdatamessage
    @test AIMessage(; content) |> isaimessage
    @test UserMessage(content) |> AIMessage |> isaimessage
    @test UserMessage(content) != AIMessage(content)
    @test AIToolRequest() |> isaitoolrequest
    @test ToolMessage(; tool_call_id = "x", raw = "") |> istoolmessage
    ## check handling other types
    @test isusermessage(1) == false
    @test issystemmessage(nothing) == false
    @test isdatamessage(1) == false
    @test isaimessage(missing) == false
    @test istracermessage(1) == false
end

@testset "AnnotationMessage" begin
    # Test creation and basic properties
    annotation = AnnotationMessage(
        content = "Test annotation",
        extras = Dict{Symbol, Any}(:key => "value"),
        tags = [:debug, :test],
        comment = "Test comment"
    )
    @test annotation.content == "Test annotation"
    @test annotation.extras[:key] == "value"
    @test :debug in annotation.tags
    @test annotation.comment == "Test comment"
    @test isabstractannotationmessage(annotation)
    @test !isabstractannotationmessage(UserMessage("test"))

    # Test that annotations are filtered out during rendering
    messages = [
        SystemMessage("System prompt"),
        UserMessage("User message"),
        AnnotationMessage(content = "Debug info", comment = "Debug note"),
        AIMessage("AI response")
    ]

    # Test annotate! utility
    msgs = [UserMessage("Hello"), AIMessage("Hi")]
    msgs = annotate!(msgs, "Debug info", tags = [:debug])
    @test length(msgs) == 3
    @test isabstractannotationmessage(msgs[1])
    @test msgs[1].tags == [:debug]

    # Test pretty printing
    io = IOBuffer()
    pprint(io, annotation)
    output = String(take!(io))
    @test occursin("Test annotation", output)
    @test occursin("debug", output)
    @test occursin("Test comment", output)

    # Test show method
    io = IOBuffer()
    show(io, MIME("text/plain"), annotation)
    output = String(take!(io))
    @test occursin("AnnotationMessage", output)
    @test occursin("Test annotation", output)
    @test !occursin("extras", output) # Should only show type and content
    @test !occursin("tags", output)
    @test !occursin("comment", output)
end

@testset "UserMessageWithImages" begin
    content = "Hello, world!"
    image_path = joinpath(@__DIR__, "data", "julia.png")
    image_url = "https://www.google.com/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png"

    # Cannot init with string only // without images
    @test_throws AssertionError UserMessageWithImages(content)
    # non-existing image path
    @test_throws AssertionError UserMessageWithImages(content;
        image_path = "data/does_not_exist_123456.png")

    # Test with URL
    msg = UserMessageWithImages(content; image_url)
    @test typeof(msg) <: UserMessageWithImages
    @test msg.content == content
    @test msg.image_url == [image_url]

    # Creates an instance of UserMessageWithImages with the given content string and image_path.
    msg = UserMessageWithImages(content, image_path = image_path)
    @test typeof(msg) <: UserMessageWithImages
    @test msg.content == content
    @test msg.image_url == [_encode_local_image(image_path)]

    # Creates an instance of UserMessageWithImages with the given content string and image_path.
    msg = UserMessageWithImages(content; image_path, image_url)
    @test typeof(msg) <: UserMessageWithImages
    @test msg.content == content
    @test msg.image_url == [image_url, _encode_local_image(image_path)]
end

@testset "attach_images_to_user_message" begin
    content = "Hello, world!"
    image_url = "https://www.google.com/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png"
    msg = attach_images_to_user_message(content; image_url)
    @test typeof(msg) <: UserMessageWithImages
    @test msg.content == content
    @test msg.image_url == [image_url]

    # Test with UserMessage
    msg = UserMessage(content)
    msg = attach_images_to_user_message(msg; image_url)
    @test typeof(msg) <: UserMessageWithImages
    @test msg.content == content
    @test msg.image_url == [image_url]

    # Test with multiple UserMessages
    msgs = [UserMessage("Hello, world!"), UserMessage("Hello, world!")]
    # default attach_to_latest = true
    output = attach_images_to_user_message(msgs; image_url)
    @test typeof(output[1]) <: UserMessage
    @test typeof(output[2]) <: UserMessageWithImages
    @test output[1].content == "Hello, world!"
    @test output[2].content == "Hello, world!"
    @test output[2].image_url == [image_url]
    # attach_to_latest = false
    @test_throws AssertionError attach_images_to_user_message(msgs;
        image_url,
        attach_to_latest = false)
    # no UserMessages
    msg = UserMessageWithImages(content; image_url) # unclear where to add the new images!
    @test_throws AssertionError attach_images_to_user_message(msg; image_url)
end

@testset "last_message,last_output,tool_calls" begin
    # on a conversation
    msgs = [UserMessage("Hello, world 1!"), UserMessage("Hello, world 2!")]
    @test last_message(msgs) == msgs[end]
    @test last_output(msgs) == "Hello, world 2!"

    # on an empty conversation
    msgs = AbstractMessage[]
    @test last_message(msgs) == nothing
    @test last_output(msgs) == nothing

    # On a message
    msg = UserMessage("Hello, world 2!")
    @test last_message(msg) == msg
    @test last_output(msg) == "Hello, world 2!"
    @test tool_calls(msg) == ToolMessage[]

    tool_msg = ToolMessage(
        tool_call_id = "1", name = "tool1", raw = "", content = "content1")
    @test tool_calls(tool_msg) == [tool_msg]
    @test last_output(tool_msg) == "content1"
    msg = AIToolRequest(content = "Tool request",
        tool_calls = [tool_msg])
    @test tool_calls(msg) == [tool_msg]
    @test last_output(msg) == "Tool request"
end

@testset "show,pprint" begin
    io = IOBuffer()

    # AIMessage
    m = AIMessage("Hello, AI!")
    show(io, MIME("text/plain"), m)
    @test occursin("AIMessage(\"Hello, AI!\")", String(take!(io)))
    pprint(io, m)
    output = String(take!(io))
    @test occursin("AI Message", output)
    @test occursin("Hello, AI!", output)

    # SystemMessage
    take!(io)
    m = SystemMessage("System instruction")
    show(io, MIME("text/plain"), m)
    @test occursin("SystemMessage(\"System instruction\")", String(take!(io)))
    pprint(io, m)
    output = String(take!(io))
    @test occursin("System Message", output)
    @test occursin("System instruction", output)

    # UserMessage
    take!(io)
    m = UserMessage("User input")
    show(io, MIME("text/plain"), m)
    @test occursin("UserMessage(\"User input\")", String(take!(io)))
    pprint(io, m)
    output = String(take!(io))
    @test occursin("User Message", output)
    @test occursin("User input", output)

    # UserMessageWithImages
    take!(io)
    m = UserMessageWithImages(
        "User input with image", image_url = ["http://example.com/image.jpg"])
    show(io, MIME("text/plain"), m)
    @test occursin("UserMessageWithImages(\"User input with image\")", String(take!(io)))
    pprint(io, m)
    output = String(take!(io))
    @test occursin("User Message", output)
    @test occursin("User input with image", output)

    # MetadataMessage
    take!(io)
    m = MetadataMessage("Metadata info")
    show(io, MIME("text/plain"), m)
    @test occursin("MetadataMessage(\"Metadata info\")", String(take!(io)))
    pprint(io, m)
    output = String(take!(io))
    @test occursin("Unknown Message", output)
    @test occursin("Metadata info", output)

    # DataMessage with Array
    take!(io)
    m = DataMessage(content = rand(3, 3))
    show(io, MIME("text/plain"), m)
    output = String(take!(io))
    @test occursin("DataMessage", output)
    @test occursin("Matrix{Float64}", output)
    @test occursin("size (3, 3))", output)
    pprint(io, m)
    output = String(take!(io))
    @test occursin("Data Message", output)
    @test occursin("Data: Matrix{Float64}", output)

    # DataMessage with Dict
    take!(io)
    m = DataMessage(content = Dict(:key1 => "value1", :key2 => "value2"))
    show(io, MIME("text/plain"), m)
    output = String(take!(io))
    @test occursin("DataMessage", output)
    @test occursin("Dict", output)
    @test occursin("key1", output)
    @test occursin("key2", output)
    pprint(io, m)
    output = String(take!(io))
    @test occursin("Data Message", output)
    @test occursin("Data: Dict{Symbol, String}", output)

    # AIToolRequest
    take!(io)
    m = AIToolRequest(content = "Tool request",
        tool_calls = [ToolMessage(
            tool_call_id = "1", name = "tool1", raw = "", content = "content1")])
    show(io, MIME("text/plain"), m)
    output = String(take!(io))
    @test occursin("AIToolRequest", output)
    @test occursin("Tool request", output)
    @test occursin("Tool Requests: 1", output)
    pprint(io, m)
    output = String(take!(io))
    @test occursin("AI Tool Request", output)
    @test occursin("Tool request", output)

    # ToolMessage
    take!(io)
    m = ToolMessage(tool_call_id = "1", name = "tool1", raw = "", content = "Tool output")
    show(io, MIME("text/plain"), m)
    output = String(take!(io))
    @test occursin("ToolMessage", output)
    @test occursin("Tool output", output)
    pprint(io, m)
    output = String(take!(io))
    @test occursin("Tool Message", output)
    @test occursin("Tool output", output)

    m = ToolMessage(
        tool_call_id = "1", name = "tool1", raw = "{args: 1}", content = nothing)
    pprint(io, m)
    output = String(take!(io))
    @test occursin("Tool Message", output)
    @test occursin("Name: tool1", output)
    @test occursin("Args: {args: 1}", output)

    # Other DataMessage types
    take!(io)
    m = DataMessage(content = 42)
    show(io, MIME("text/plain"), m)
    output = String(take!(io))
    @test occursin("DataMessage", output)
    @test occursin("Int64", output)
end

@testset "TracerMessage,TracerMessageLike" begin
    # Tracer functionality
    msg1 = UserMessage("Hi")
    msg2 = AIMessage("Hi there!")

    # Create wrapper
    tr1 = TracerMessage(msg1; from = :me, to = :you)
    @test istracermessage(tr1)
    @test tr1.object == msg1
    @test tr1.from == :me
    @test tr1.to == :you
    @test tool_calls(tr1) == ToolMessage[]

    # Message methods
    tr2 = TracerMessage(msg2; from = :you, to = :me)
    @test tr1.content == msg1.content
    @test tr2.run_id == msg2.run_id
    @test tr1 != tr2
    @test tr1 == tr1
    @test UserMessage(tr2).content == msg2.content
    @test copy(tr1) == tr1
    @test copy(tr2) !== tr2

    # Specific methods
    # type trait passthrough to the underlying message
    content = "say hi"
    @test TracerMessage(UserMessage(content)) |> isusermessage
    @test TracerMessage(SystemMessage(content)) |> issystemmessage
    @test TracerMessage(DataMessage(; content)) |> isdatamessage
    @test TracerMessage(AIMessage(; content)) |> isaimessage
    @test TracerMessage(UserMessage(content)) |> AIMessage |> isaimessage

    # unwrap the tracer
    @test unwrap(tr1) == msg1

    # Align random IDs
    conv = [tr1, tr2]
    align_tracer!(conv)
    @test conv[1].parent_id == conv[2].parent_id
    @test conv[1].thread_id == conv[2].thread_id

    empty_ = AbstractTracer[]
    @test empty_ == align_tracer!(empty_)

    ## TracerMessageLike
    str = "Test Message"
    tracer = TracerMessageLike(str)
    @test tracer.object == str
    @test unwrap(tracer) == str

    # methods
    tracer2 = TracerMessageLike(str)
    @test tracer == tracer2

    struct TracerRandom1 <: AbstractTracer{Int} end
    tracer3 = TracerRandom1()
    @test tracer != tracer3

    # show and pprint for TracerMessage
    # Test show method
    io_show = IOBuffer()
    show(io_show, MIME("text/plain"), tr1)
    show_output = String(take!(io_show))
    @test occursin("TracerMessage", show_output)
    @test occursin("UserMessage", show_output)
    @test occursin("you", show_output)

    # Test pprint method
    io_pprint = IOBuffer()
    pprint(io_pprint, tr1)
    pprint_output = String(take!(io_pprint))
    @test occursin("TracerMessage with:", pprint_output)
    @test occursin("User Message", pprint_output)
    @test occursin("Hi", pprint_output)

    # show and pprint for TracerMessageLike
    # Test show method
    io_show = IOBuffer()
    show(io_show, MIME("text/plain"), tracer)
    show_output = String(take!(io_show))
    @test occursin("TracerMessageLike{String}", show_output)
    @test occursin("Test Message", show_output)

    # Test pprint method
    io_pprint = IOBuffer()
    pprint(io_pprint, tracer)
    pprint_output = String(take!(io_pprint))
    @test occursin("TracerMessageLike with:", pprint_output)
    @test occursin("Test Message", pprint_output)
end
