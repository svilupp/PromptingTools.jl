using Test
using PromptingTools: GoogleOpenAISchema, AIMessage
using PromptingTools: aigenerate, aiembed
using HTTP, JSON3

@testset "GoogleOpenAISchema" begin
    # Test with empty GOOGLE_API_KEY
    withenv("GOOGLE_API_KEY" => "") do
        PORT = rand(10000:20000)
        echo_server = HTTP.serve!(PORT, verbose = -1) do req
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
    end

    # Test with non-empty GOOGLE_API_KEY
    withenv("GOOGLE_API_KEY" => "env_key") do
        PORT = rand(10000:20000)
        echo_server = HTTP.serve!(PORT, verbose = -1) do req
            @test HTTP.header(req, "Authorization") == "Bearer env_key"
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
            api_key = "test_key",  # This should be ignored since GOOGLE_API_KEY is set
            model = "gemini-1.5-pro-latest",
            api_kwargs = (; url = "http://localhost:$(PORT)"))

        @test msg.content == "Test response"
        @test msg.finish_reason == "stop"
        close(echo_server)
    end

    # Test embeddings with empty GOOGLE_API_KEY
    withenv("GOOGLE_API_KEY" => "") do
        PORT = rand(10000:20000)
        echo_server = HTTP.serve!(PORT, verbose = -1) do req
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
    end

    # Test embeddings with non-empty GOOGLE_API_KEY
    withenv("GOOGLE_API_KEY" => "env_key") do
        PORT = rand(10000:20000)
        echo_server = HTTP.serve!(PORT, verbose = -1) do req
            @test HTTP.header(req, "Authorization") == "Bearer env_key"
            content = JSON3.read(req.body)
            response = Dict(:data => [Dict(:embedding => ones(128))],
                :usage => Dict(:total_tokens => 5,
                    :prompt_tokens => 5,
                    :completion_tokens => 0))
            return HTTP.Response(200, JSON3.write(response))
        end

        msg = aiembed(GoogleOpenAISchema(),
            "Test prompt";
            api_key = "test_key",  # This should be ignored since GOOGLE_API_KEY is set
            model = "gemini-1.5-pro-latest",
            api_kwargs = (; url = "http://localhost:$(PORT)"))

        @test msg.content == ones(128)
        @test msg.tokens == (5, 0)
        close(echo_server)
    end
end
