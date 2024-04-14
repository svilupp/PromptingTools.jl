using PromptingTools: AIMessage, SystemMessage, MetadataMessage, AbstractMessage
using PromptingTools: UserMessage, UserMessageWithImages, DataMessage
using PromptingTools: _encode_local_image, attach_images_to_user_message, last_message,
                      last_output
using PromptingTools: isusermessage, issystemmessage, isdatamessage, isaimessage,
                      istracermessage
using PromptingTools: TracerMessageLike, TracerMessage, align_tracer!, unwrap,
                      AbstractTracerMessage, AbstractTracer, pprint

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

@testset "last_message,last_output" begin
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
    # unwrap the tracer
    @test unwrap(tr1) == msg1

    # Align random IDs
    conv = [tr1, tr2]
    align_tracer!(conv)
    @test conv[1].parent_id == conv[2].parent_id
    @test conv[1].thread_id == conv[2].thread_id

    ## TracerMessageLike
    str = "Test Message"
    tracer = TracerMessageLike(str)
    @test tracer.object == str
    @test unwrap(tracer) == str

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