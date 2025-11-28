using PromptingTools: StreamCallback, StreamChunk, OpenAIStream, OpenAIResponsesStream,
                      AnthropicStream, configure_callback!, OllamaStream
using PromptingTools: OpenAISchema, AnthropicSchema, GoogleSchema, OllamaSchema,
                      OpenAIResponseSchema

@testset "configure_callback!" begin
    # Test configure_callback! method
    cb, api_kwargs = configure_callback!(StreamCallback(), OpenAISchema())
    @test cb.flavor isa OpenAIStream
    @test api_kwargs[:stream] == true
    @test api_kwargs[:stream_options] == (include_usage = true,)

    cb, api_kwargs = configure_callback!(StreamCallback(), AnthropicSchema())
    @test cb.flavor isa AnthropicStream
    @test api_kwargs[:stream] == true

    cb, api_kwargs = configure_callback!(StreamCallback(), OllamaSchema())
    @test cb.flavor isa OllamaStream
    @test api_kwargs[:stream] == true

    # Test ResponseSchema streaming with OpenAIResponsesStream
    cb, api_kwargs = configure_callback!(StreamCallback(), OpenAIResponseSchema())
    @test cb.flavor isa OpenAIResponsesStream
    @test api_kwargs[:stream] == true

    # Test error for unsupported schema
    @test_throws ErrorException configure_callback!(StreamCallback(), GoogleSchema())
    @test_throws ErrorException configure_callback!(StreamCallback(), OllamaManagedSchema())

    # Test configure_callback! with output stream
    cb, _ = configure_callback!(IOBuffer(), OpenAISchema())
    @test cb isa StreamCallback
    @test cb.out isa IOBuffer
    @test cb.flavor isa OpenAIStream
end
