using PromptingTools: AIMessage, SystemMessage, MetadataMessage
using PromptingTools: UserMessage, UserMessageWithImages, DataMessage
using PromptingTools: _encode_local_image, attach_images_to_user_message

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