using Test
using PromptingTools
using PromptingTools: isabstractannotationmessage

@testset "AnnotationMessage" begin
    # Test creation and basic properties
    annotation = AnnotationMessage(
        content="Test annotation",
        extras=Dict{Symbol,Any}(:key => "value"),
        tags=[:debug, :test],
        comment="Test comment"
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
        AnnotationMessage(content="Debug info", comment="Debug note"),
        AIMessage("AI response")
    ]

    # Create a basic schema for testing
    schema = NoSchema()
    rendered = render(schema, messages)

    # Verify annotation message is not in rendered output
    @test length(rendered) == 3  # Only system, user, and AI messages
    @test all(!isabstractannotationmessage, rendered)

    # Test annotate! utility
    msgs = [UserMessage("Hello"), AIMessage("Hi")]
    annotate!(msgs, "Debug info", tags=[:debug])
    @test length(msgs) == 3
    @test isabstractannotationmessage(msgs[1])
    @test msgs[1].tags == [:debug]

    # Test single message annotation
    msg = UserMessage("Test")
    result = annotate!(msg, "Annotation", comment="Note")
    @test length(result) == 2
    @test isabstractannotationmessage(result[1])
    @test result[1].comment == "Note"

    # Test tracer message handling
    tracer_msg = TracerMessage(annotation)
    @test isabstractannotationmessage(tracer_msg)

    # Test pretty printing
    io = IOBuffer()
    pprint(io, annotation)
    output = String(take!(io))
    @test contains(output, "Test annotation")
    @test contains(output, "debug")
    @test contains(output, "Test comment")
end
