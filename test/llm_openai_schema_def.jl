using Test
using PromptingTools: GoogleOpenAISchema, AIMessage
using PromptingTools: aigenerate, aiembed
using HTTP, JSON3
using PromptingTools
using Logging  # Add logging support

@testset "GoogleOpenAISchema" begin
    # Set up test-specific logger
    test_logger = ConsoleLogger(stdout, Logging.Debug)
    global_logger(test_logger)

    @info "Starting GoogleOpenAISchema tests"

    # Save original API key
    original_api_key = PromptingTools.GOOGLE_API_KEY
    @info "Saved original API key" original_api_key

    # Test with empty GOOGLE_API_KEY
    PromptingTools.GOOGLE_API_KEY = ""
    @info "Set empty GOOGLE_API_KEY" current_key=PromptingTools.GOOGLE_API_KEY
    PORT = rand(10000:20000)
    echo_server = HTTP.serve!(PORT, verbose = -1) do req
        @info "Mock Server (empty GOOGLE_API_KEY): Analyzing request" port=PORT method=req.method target=req.target
        @info "Request headers" headers=Dict(k => v for (k,v) in req.headers)
        auth_header = HTTP.header(req, "Authorization")
        @info "Authorization analysis" received=auth_header expected="Bearer test_key" matches=(auth_header == "Bearer test_key")
        @test HTTP.header(req, "Authorization") == "Bearer test_key"

        content = JSON3.read(req.body)
        @debug "Request body content" content

        response = Dict(
            :choices => [
                Dict(:message => Dict(:content => "Test response"),
                    :finish_reason => "stop")
            ],
            :usage => Dict(:total_tokens => 5,
                :prompt_tokens => 5,
                :completion_tokens => 0))
        @debug "Sending response" response
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

    # Test with non-empty GOOGLE_API_KEY
    PromptingTools.GOOGLE_API_KEY = "env_key"
    PORT = rand(10000:20000)
    echo_server = HTTP.serve!(PORT, verbose = -1) do req
        @info "Mock Server (non-empty GOOGLE_API_KEY): Analyzing request" port=PORT method=req.method target=req.target
        @info "Request headers" headers=Dict(k => v for (k,v) in req.headers)
        auth_header = HTTP.header(req, "Authorization")
        @info "Authorization analysis" received=auth_header expected="Bearer env_key" matches=(auth_header == "Bearer env_key")
        @test HTTP.header(req, "Authorization") == "Bearer env_key"

        content = JSON3.read(req.body)
        @debug "Request body content" content

        response = Dict(
            :choices => [
                Dict(:message => Dict(:content => "Test response"),
                    :finish_reason => "stop")
            ],
            :usage => Dict(:total_tokens => 5,
                :prompt_tokens => 5,
                :completion_tokens => 0))
        @debug "Sending response" response
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

    # Test embeddings with empty GOOGLE_API_KEY
    PromptingTools.GOOGLE_API_KEY = ""
    PORT = rand(10000:20000)
    echo_server = HTTP.serve!(PORT, verbose = -1) do req
        @info "Mock Server (empty GOOGLE_API_KEY, embeddings): Analyzing request" port=PORT method=req.method target=req.target
        @info "Request headers" headers=Dict(k => v for (k,v) in req.headers)
        auth_header = HTTP.header(req, "Authorization")
        @info "Authorization analysis" received=auth_header expected="Bearer test_key" matches=(auth_header == "Bearer test_key")
        @test HTTP.header(req, "Authorization") == "Bearer test_key"

        content = JSON3.read(req.body)
        @debug "Request body content" content

        response = Dict(:data => [Dict(:embedding => ones(128))],
            :usage => Dict(:total_tokens => 5,
                :prompt_tokens => 5,
                :completion_tokens => 0))
        @debug "Sending response" response
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

    # Test embeddings with non-empty GOOGLE_API_KEY
    PromptingTools.GOOGLE_API_KEY = "env_key"
    PORT = rand(10000:20000)
    echo_server = HTTP.serve!(PORT, verbose = -1) do req
        @info "Mock Server (non-empty GOOGLE_API_KEY, embeddings): Analyzing request" port=PORT method=req.method target=req.target
        @info "Request headers" headers=Dict(k => v for (k,v) in req.headers)
        auth_header = HTTP.header(req, "Authorization")
        @info "Authorization analysis" received=auth_header expected="Bearer env_key" matches=(auth_header == "Bearer env_key")
        @test HTTP.header(req, "Authorization") == "Bearer env_key"

        content = JSON3.read(req.body)
        @debug "Request body content" content

        response = Dict(:data => [Dict(:embedding => ones(128))],
            :usage => Dict(:total_tokens => 5,
                :prompt_tokens => 5,
                :completion_tokens => 0))
        @debug "Sending response" response
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

    # Restore original API key
    PromptingTools.GOOGLE_API_KEY = original_api_key
end
