using Test
using PromptingTools: GoogleOpenAISchema, AIMessage, aigenerate, aiembed

@testset "GoogleOpenAISchema" begin
    # Save original API key
    original_api_key = PromptingTools.GOOGLE_API_KEY

    # Test with empty GOOGLE_API_KEY
    PromptingTools.GOOGLE_API_KEY = ""
    PORT = rand(10000:20000)
    echo_server = HTTP.serve!(PORT, verbose = -1) do req
        auth_header = HTTP.header(req, "Authorization")
        @test HTTP.header(req, "Authorization") == "Bearer test_key"

        content = JSON3.read(req.body)

        response = Dict(
            :choices => [
                Dict(:message => Dict(:content => "Test response"),
                :finish_reason => "stop")
            ],
            :usage => Dict(:total_tokens => 5,
                :prompt_tokens => 5,
                :completion_tokens => 0))
        return HTTP.Response(200, JSON3.write(response))
    end

    msg = aigenerate(GoogleOpenAISchema(),
        "Test prompt";
        api_key = "test_key",
        model = "gemini-1.5-pro-latest",
        api_kwargs = (; url = "http://localhost:$(PORT)"))

    @test msg.content == "Test response"
    @test msg.finish_reason == "stop"
    close(echo_server)

    # Test with non-empty GOOGLE_API_KEY - explicit api_key should take precedence
    PromptingTools.GOOGLE_API_KEY = "env_key"
    PORT = rand(10000:20000)
    echo_server = HTTP.serve!(PORT, verbose = -1) do req
        auth_header = HTTP.header(req, "Authorization")
        @test HTTP.header(req, "Authorization") == "Bearer test_key"

        content = JSON3.read(req.body)

        response = Dict(
            :choices => [
                Dict(:message => Dict(:content => "Test response"),
                :finish_reason => "stop")
            ],
            :usage => Dict(:total_tokens => 5,
                :prompt_tokens => 5,
                :completion_tokens => 0))
        return HTTP.Response(200, JSON3.write(response))
    end

    msg = aigenerate(GoogleOpenAISchema(),
        "Test prompt";
        api_key = "test_key",
        model = "gemini-1.5-pro-latest",
        api_kwargs = (; url = "http://localhost:$(PORT)"))

    @test msg.content == "Test response"
    @test msg.finish_reason == "stop"
    close(echo_server)

    # Test embeddings with empty GOOGLE_API_KEY
    PromptingTools.GOOGLE_API_KEY = ""
    PORT = rand(10000:20000)
    echo_server = HTTP.serve!(PORT, verbose = -1) do req
        auth_header = HTTP.header(req, "Authorization")
        @test HTTP.header(req, "Authorization") == "Bearer test_key"

        content = JSON3.read(req.body)

        response = Dict(:data => [Dict(:embedding => ones(128))],
            :usage => Dict(:total_tokens => 5,
                :prompt_tokens => 5,
                :completion_tokens => 0))
        return HTTP.Response(200, JSON3.write(response))
    end

    msg = aiembed(GoogleOpenAISchema(),
        "Test prompt";
        api_key = "test_key",
        model = "gemini-1.5-pro-latest",
        api_kwargs = (; url = "http://localhost:$(PORT)"))

    @test msg.content == ones(128)
    @test msg.tokens == (5, 0)
    close(echo_server)

    # Test embeddings with non-empty GOOGLE_API_KEY - explicit api_key should take precedence
    PromptingTools.GOOGLE_API_KEY = "env_key"
    PORT = rand(10000:20000)
    echo_server = HTTP.serve!(PORT, verbose = -1) do req
        auth_header = HTTP.header(req, "Authorization")
        @test HTTP.header(req, "Authorization") == "Bearer test_key"

        content = JSON3.read(req.body)

        response = Dict(:data => [Dict(:embedding => ones(128))],
            :usage => Dict(:total_tokens => 5,
                :prompt_tokens => 5,
                :completion_tokens => 0))
        return HTTP.Response(200, JSON3.write(response))
    end

    msg = aiembed(GoogleOpenAISchema(),
        "Test prompt";
        api_key = "test_key",
        model = "gemini-1.5-pro-latest",
        api_kwargs = (; url = "http://localhost:$(PORT)"))

    @test msg.content == ones(128)
    @test msg.tokens == (5, 0)
    close(echo_server)

    # Restore original API key
    PromptingTools.GOOGLE_API_KEY = original_api_key
end
