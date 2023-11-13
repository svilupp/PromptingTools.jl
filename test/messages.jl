using PromptingTools: AIMessage, SystemMessage, MetadataMessage, UserMessage, DataMessage

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
