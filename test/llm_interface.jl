using PromptingTools: TestEchoOpenAISchema, render, OpenAISchema
using PromptingTools: AIMessage, SystemMessage, AbstractMessage
using PromptingTools: UserMessage, UserMessageWithImages, DataMessage
using PromptingTools: response_to_message, AbstractPromptSchema

@testset "ai* default schema" begin
    OLD_PROMPT_SCHEMA = PromptingTools.PROMPT_SCHEMA
    ### AIGenerate
    # corresponds to OpenAI API v1
    response = Dict(
        :choices => [
            Dict(:message => Dict(:content => "Hello!"), :finish_reason => "stop")
        ],
        :usage => Dict(:total_tokens => 3, :prompt_tokens => 2, :completion_tokens => 1))

    schema = TestEchoOpenAISchema(; response, status = 200)
    PromptingTools.PROMPT_SCHEMA = schema
    msg = aigenerate("Hello World"; model = "xyz")
    expected_output = AIMessage(;
        content = "Hello!" |> strip,
        status = 200,
        tokens = (2, 1),
        run_id = msg.run_id,
        finish_reason = "stop",
        cost = 0.0,
        elapsed = msg.elapsed)
    @test msg == expected_output

    ### AIClassify
    msg = aiclassify(
        "Hello World"; choices = ["true", "false", "unknown"], model = "gpt-4o-made-up-model")
    expected_output = AIMessage(;
        content = nothing,
        status = 200,
        tokens = (2, 1),
        run_id = msg.run_id,
        cost = 0.0,
        finish_reason = "stop",
        elapsed = msg.elapsed)
    @test msg == expected_output

    ### AIExtract
    response1 = Dict(
        :choices => [
            Dict(
            :message => Dict(:tool_calls => [
                Dict(:function => Dict(:arguments => "{\"content\": \"x\"}"))
            ]),
            :finish_reason => "stop")],
        :usage => Dict(:total_tokens => 3, :prompt_tokens => 2, :completion_tokens => 1))

    schema = TestEchoOpenAISchema(; response = response1, status = 200)
    PromptingTools.PROMPT_SCHEMA = schema
    struct MyType
        content::String
    end
    msg = aiextract("Hello World"; model = "xyz", return_type = MyType)
    expected_output = DataMessage(;
        content = MyType("x"),
        status = 200,
        tokens = (2, 1),
        run_id = msg.run_id,
        cost = 0.0,
        finish_reason = "stop",
        elapsed = msg.elapsed)
    @test msg == expected_output

    # corresponds to OpenAI API v1
    response2 = Dict(:data => [Dict(:embedding => ones(128))],
        :usage => Dict(:total_tokens => 2, :prompt_tokens => 2, :completion_tokens => 0))

    # Real generation API
    schema2 = TestEchoOpenAISchema(; response = response2, status = 200)
    PromptingTools.PROMPT_SCHEMA = schema2
    msg = aiembed("Hello World"; model = "xyz")
    expected_output = DataMessage(;
        content = ones(128),
        status = 200,
        tokens = (2, 0),
        run_id = msg.run_id,
        cost = 0.0,
        elapsed = msg.elapsed)
    @test msg == expected_output

    ## Return things to previous
    PromptingTools.PROMPT_SCHEMA = OLD_PROMPT_SCHEMA

    ## Check response_to_message throws by default
    struct Random123Schema <: AbstractPromptSchema end
    @test_throws ArgumentError response_to_message(Random123Schema(),
        AIMessage,
        nothing,
        nothing)
end
