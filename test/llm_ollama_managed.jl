using PromptingTools: TestEchoOllamaManagedSchema, render, OllamaManagedSchema, ollama_api
using PromptingTools: AIMessage, SystemMessage, AbstractMessage
using PromptingTools: UserMessage, UserMessageWithImages, DataMessage

# Write unit tests for the render function
@testset "render-ollama" begin
    schema = OllamaManagedSchema()
    @testset "render with system and prompt" begin
        system = "System message"
        prompt = "Prompt message"
        conversation = render(schema,
            AbstractMessage[SystemMessage(system), UserMessage(prompt)])
        @test conversation.system == system
        @test conversation.prompt == prompt
    end
    @testset "render with only prompt" begin
        prompt = "Prompt message"
        conversation = render(schema, UserMessage(prompt))
        @test conversation.system == "Act as a helpful AI assistant"
        @test conversation.prompt == prompt
        ## alt with string format
        conversation = render(schema, prompt)
        @test conversation.system == "Act as a helpful AI assistant"
        @test conversation.prompt == prompt
    end
    @testset "render without prompt" begin
        @test_throws AssertionError render(schema, SystemMessage("System message"))
        @test_throws AssertionError render(schema, AbstractMessage[])
    end
    # error with UserMessageWithImages or AIMessage
    @test_throws ErrorException render(schema,
        UserMessageWithImages("abc"; image_url = "https://example.com"))
    @test_throws ErrorException render(schema,
        [AIMessage("abc")])
    # error if more than 2 user messages, or no user messages
    @test_throws AssertionError aigenerate(schema,
        [UserMessage("abc"), UserMessage("abc"), UserMessage("abc")])
    @test_throws AssertionError aigenerate(schema,
        [UserMessage("abc"), SystemMessage("abc"), UserMessage("abc")])
    @test_throws AssertionError aigenerate(schema,
        [SystemMessage("abc"), SystemMessage("abc")])
    @test_throws AssertionError aigenerate(schema,
        [SystemMessage("abc")])
    @test_throws AssertionError aigenerate(schema,
        [UserMessage("abc"), UserMessage("abc")])

    # error if conversation is provided
    @test_throws AssertionError aigenerate(schema,
        UserMessage("abc");
        conversation = [SystemMessage("abc")])

    # Double check templating
    messages = [
        SystemMessage("Act as a helpful AI assistant"),
        UserMessage("Hello, my name is {{name}}"),
    ]
    expected_output = (; system = "Act as a helpful AI assistant",
        prompt = "Hello, my name is John")
    conversation = render(schema, messages; name = "John")
    @test conversation == expected_output
end

# Sense check for the Echo Setup
@testset "ollama_api-echo" begin
    # corresponds to standard Ollama response format
    response = Dict(:response => "Hello!",
        :prompt_eval_count => 2,
        :eval_count => 1)
    schema = TestEchoOllamaManagedSchema(; response, status = 200)
    prompt = "Prompt message"
    system = "System message"
    msg = ollama_api(schema, prompt; system)
    schema
    msg
    @test msg.response == response
    @test msg.status == 200
    @test schema.inputs == (; system, prompt)
    ## Assert
    @test_throws Exception ollama_api(OllamaManagedSchema(), nothing)
    @test_throws ollama_api(OllamaManagedSchema(), "x"; endpoint = "wrong-endpoint")
end

@testset "aigenerate-ollama" begin
    @testset "with system and prompt" begin
        response = Dict(:response => "Prompt message",
            :prompt_eval_count => 2,
            :eval_count => 1)
        schema = TestEchoOllamaManagedSchema(; response, status = 200)
        prompt = "Prompt message"
        system = "System message"
        msg = aigenerate(schema,
            [SystemMessage(system), UserMessage(prompt)];
            model = "llama2")
        @test msg.content == prompt
        @test msg.status == 200
        @test msg.tokens == (2, 1)
        @test isapprox(msg.elapsed, 0, atol = 3e-1)
        @test schema.inputs == (; system, prompt)
        @test schema.model_id == "llama2"
    end
    @testset "prompt with placeholders" begin
        response = Dict(:response => "Hello John",
            :prompt_eval_count => 2,
            :eval_count => 1)
        schema = TestEchoOllamaManagedSchema(; response, status = 200)
        prompt = "Hello {{name}}"
        msg = aigenerate(schema, prompt; model = "llama2aaaa", name = "John")
        @test msg.content == "Hello John"
        @test msg.status == 200
        @test msg.tokens == (2, 1)
        @test isapprox(msg.elapsed, 0, atol = 3e-1)
        @test schema.inputs ==
              (; system = "Act as a helpful AI assistant", prompt = "Hello John")
        @test schema.model_id == "llama2aaaa"
    end
    @testset "error modes" begin
        response = Dict(:response => "Hello John",
            :prompt_eval_count => 2,
            :eval_count => 1)
        schema = TestEchoOllamaManagedSchema(; response, status = 200)
        @test_throws AssertionError aigenerate(schema, AbstractMessage[])
        @test_throws AssertionError aigenerate(schema, SystemMessage("abc"))
        @test_throws AssertionError aigenerate(schema,
            [UserMessage("abc"), UserMessage("abc")])
        ## disabled types
        @test_throws ErrorException aigenerate(schema,
            UserMessageWithImages("abc"; image_url = "https://example.com"))
    end
end
@testset "aiembed-ollama" begin
    @testset "single doc" begin
        response = Dict(:embedding => ones(16))
        schema = TestEchoOllamaManagedSchema(; response, status = 200)
        doc = "embed me"
        msg = aiembed(schema, doc; model = "llama2")
        @test msg.content == ones(16)
        @test msg.status == 200
        @test msg.tokens == (0, 0)
        @test isapprox(msg.elapsed, 0, atol = 3e-1)
        @test schema.inputs == (; system = nothing, prompt = doc)
        @test schema.model_id == "llama2"
    end
    @testset "multi doc + postprocess" begin
        response = Dict(:embedding => ones(16))
        schema = TestEchoOllamaManagedSchema(; response, status = 200)
        docs = ["embed me", "and me"]
        msg = aiembed(schema, docs, x -> 2 * x; model = "llama2")
        @info typeof(msg.content) size(msg.content)
        @test msg.content == 2 * ones(16, 2)
        @test msg.status == 200
        @test msg.tokens == (0, 0)
        @test isapprox(msg.elapsed, 0, atol = 3e-1)
        @test schema.inputs == (; system = nothing, prompt = docs[2]) # only the last doc is caught (serial execution)
        @test schema.model_id == "llama2"
    end
end

@testset "not implemented ai* functions" begin
    @test_throws ErrorException aiextract(OllamaManagedSchema(), "prompt")
    @test_throws ErrorException aiclassify(OllamaManagedSchema(), "prompt")
    @test_throws ErrorException aiscan(OllamaManagedSchema(), "prompt")
end