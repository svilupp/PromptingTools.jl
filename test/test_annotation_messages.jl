using Test
using PromptingTools
using PromptingTools: TestEchoOpenAISchema, render, SystemMessage, UserMessage, AnnotationMessage

@testset "AnnotationMessage" begin
    # Test creation and basic properties
    @testset "Basic Construction" begin
        msg = AnnotationMessage(content="Test content")
        @test msg.content == "Test content"
        @test isempty(msg.extras)
        @test !isnothing(msg.run_id)
    end

    # Test with all fields
    @testset "Full Construction" begin
        msg = AnnotationMessage(
            content="Full test",
            extras=Dict{Symbol,Any}(:key => "value"),
            tags=[:test, :example],
            comment="Test comment"
        )
        @test msg.content == "Full test"
        @test msg.extras[:key] == "value"
        @test msg.tags == [:test, :example]
        @test msg.comment == "Test comment"
    end

    # Test annotate! utility
    @testset "annotate! utility" begin
        # Test with vector of messages
        messages = [SystemMessage("System"), UserMessage("User")]
        annotated = annotate!(messages, "Annotation")
        @test length(annotated) == 3
        @test annotated[1] isa AnnotationMessage
        @test annotated[1].content == "Annotation"

        # Test with single message
        message = UserMessage("Single")
        annotated = annotate!(message, "Single annotation")
        @test length(annotated) == 2
        @test annotated[1] isa AnnotationMessage
        @test annotated[1].content == "Single annotation"

        # Test annotation placement with existing annotations
        messages = [
            AnnotationMessage("First"),
            SystemMessage("System"),
            UserMessage("User")
        ]
        annotated = annotate!(messages, "Second")
        @test length(annotated) == 4
        @test annotated[2] isa AnnotationMessage
        @test annotated[2].content == "Second"
    end

    # Test serialization
    @testset "Serialization" begin
        original = AnnotationMessage(
            content="Test",
            extras=Dict{Symbol,Any}(:key => "value"),
            tags=[:test],
            comment="Comment"
        )

        # Convert to Dict and back
        dict = Dict(original)
        reconstructed = convert(AnnotationMessage, dict)

        @test reconstructed.content == original.content
        @test reconstructed.extras == original.extras
        @test reconstructed.tags == original.tags
        @test reconstructed.comment == original.comment
    end

    # Test rendering skipping
    @testset "Render Skipping" begin
        schema = TestEchoOpenAISchema(response=Dict(:choices => [Dict(:message => Dict(:content => "Echo"))]))
        msg = AnnotationMessage("Should be skipped")
        @test render(schema, msg) === nothing

        # Test in message sequence
        messages = [
            SystemMessage("System"),
            AnnotationMessage("Skip me"),
            UserMessage("User")
        ]
        rendered = render(schema, messages)
        @test !contains(rendered, "Skip me")
    end
end
