using PromptingTools.CustomRetryLayer: enable_retry!, custom_retry_layer,
                                       extract_retry_after, parse_time_string,
                                       is_paused, pause_requests, RETRY_CONFIG,
                                       RATE_LIMIT_STATE

@testset "CustomRetryLayer" begin
    # Save original config to restore later
    original_max_retries = RETRY_CONFIG.max_retries
    original_base_delay = RETRY_CONFIG.base_delay
    original_status_codes = copy(RETRY_CONFIG.status_codes)
    original_show_headers = RETRY_CONFIG.show_headers

    # Test is_paused and pause_requests
    @test !is_paused()[1]  # Initially not paused

    pause_requests(0.2)  # Pause for a short time
    paused, wait_time = is_paused()
    @test paused  # Should be paused
    @test wait_time > 0  # Should have some wait time

    sleep(0.3)  # Wait for pause to expire
    @test !is_paused()[1]  # Should no longer be paused

    # Test enable_retry! configuration
    enable_retry!(; max_retries = 10, base_delay = 3.0, status_codes = [429, 503])
    @test RETRY_CONFIG.max_retries == 10
    @test RETRY_CONFIG.base_delay == 3.0
    @test RETRY_CONFIG.status_codes == [429, 503]

    # Test enable_retry! layer management
    enable_retry!(false)  # Disable first to ensure clean state
    @test !any(layer -> layer == custom_retry_layer, HTTP.REQUEST_LAYERS)

    enable_retry!()  # Enable with default settings
    @test any(layer -> layer == custom_retry_layer, HTTP.REQUEST_LAYERS)

    enable_retry!(false)  # Disable again
    @test !any(layer -> layer == custom_retry_layer, HTTP.REQUEST_LAYERS)

    # Test custom_retry_layer with mocked handler
    # We'll create a mock handler that simulates different responses
    retry_count = 0
    function mock_handler(req; kw...)
        if retry_count < 2
            retry_count += 1
            headers = [("retry-after", "0.1")]
            resp = HTTP.Response(429, headers)
            throw(HTTP.StatusError(429, req.method, req.target, resp))
        else
            return HTTP.Response(200)
        end
    end

    # Test the retry layer with our mock handler
    retry_layer = custom_retry_layer(
        mock_handler;
        custom_retry_max_retries = 3,
        custom_retry_base_delay = 0.1,
        custom_retry_status_codes = [429]
    )

    # Reset retry count
    retry_count = 0

    # The layer should retry and eventually succeed
    resp = retry_layer(HTTP.Request("GET", "/"))
    @test resp.status == 200
    @test retry_count == 2  # Should have retried twice

    # Test with retry disabled
    retry_count = 0
    retry_layer_disabled = custom_retry_layer(
        mock_handler;
        custom_retry_enabled = false
    )

    # Should throw immediately without retrying
    @test_throws HTTP.StatusError retry_layer_disabled(HTTP.Request("GET", "/"))
    @test retry_count == 1  # Should have only tried once

    # Restore original config
    RETRY_CONFIG.max_retries = original_max_retries
    RETRY_CONFIG.base_delay = original_base_delay
    RETRY_CONFIG.status_codes = original_status_codes
    RETRY_CONFIG.show_headers = original_show_headers

    # Make sure RATE_LIMIT_STATE is reset
    RATE_LIMIT_STATE.paused_until = nothing
end

@testset "extract_retry_after" begin
    # Test case 1: retry-after-ms
    headers1 = Dict("retry-after-ms" => "2000")
    @test extract_retry_after(headers1) == 2.0

    # Test case 2: retry-after
    headers2 = Dict("retry-after" => "5")
    @test extract_retry_after(headers2) == 5.0

    # Test case 3: X-Ratelimit-Reset
    headers3 = Dict("X-Ratelimit-Reset" => "10")
    @test extract_retry_after(headers3) == 10.0

    # Test case 4: x-ratelimit-reset-requests (seconds)
    headers4 = Dict("x-ratelimit-reset-requests" => "2s")
    @test extract_retry_after(headers4) == 2.0

    # Test case 5: x-ratelimit-reset-tokens (minutes and seconds)
    headers5 = Dict("x-ratelimit-reset-tokens" => "1m30s")
    @test extract_retry_after(headers5) == 90.0
    headers5 = Dict("x-ratelimit-reset-tokens" => "10")
    @test extract_retry_after(headers5) == 10.0

    # Test case 6: x-ratelimit-reset-requests and x-ratelimit-reset-tokens (minimum)
    headers6 = Dict(
        "x-ratelimit-reset-requests" => "5s", "x-ratelimit-reset-tokens" => "2m")
    @test extract_retry_after(headers6) == 5.0

    # Test case 7: No headers
    headers7 = Dict{String, String}()
    @test isnothing(extract_retry_after(headers7))

    # Test case 8: Invalid time string
    headers8 = Dict("x-ratelimit-reset-requests" => "invalid")
    @test isnothing(extract_retry_after(headers8))

    # Test case 9: Only minutes
    headers9 = Dict("x-ratelimit-reset-tokens" => "2m")
    @test extract_retry_after(headers9) == 120.0

    # Test case 10: Only seconds with decimal
    headers10 = Dict("x-ratelimit-reset-requests" => "2.5s")
    @test extract_retry_after(headers10) == 2.5

    # Test case 11: Minutes and seconds with decimal
    headers11 = Dict("x-ratelimit-reset-tokens" => "1m30.5s")
    @test extract_retry_after(headers11) == 90.5

    # Test case 12: Multiple ratelimit headers, one invalid
    headers12 = Dict(
        "x-ratelimit-reset-requests" => "5s", "x-ratelimit-reset-tokens" => "invalid")
    @test extract_retry_after(headers12) == 5.0

    # Test case 13: Milliseconds
    headers13 = Dict("retry-after-ms" => "500")
    @test extract_retry_after(headers13) == 0.5
end

@testset "parse_time_string" begin
    # Test case 1: Seconds only
    @test parse_time_string("5s") == 5.0

    # Test case 2: Minutes only
    @test parse_time_string("3m") == 180.0

    # Test case 3: Minutes and seconds
    @test parse_time_string("2m30s") == 150.0

    # Test case 4: Decimal seconds
    @test parse_time_string("1.5s") == 1.5

    # Test case 5: Minutes and decimal seconds
    @test parse_time_string("1m2.5s") == 62.5

    # Test case 6: Invalid string
    @test isnothing(parse_time_string("invalid"))

    # Test case 7: Empty string
    @test isnothing(parse_time_string(""))

    # Test case 8: No time units
    @test isnothing(parse_time_string("123"))

    # Test case 9: Milliseconds only
    @test parse_time_string("500ms") == 0.5

    # Test case 10: Seconds and milliseconds
    @test parse_time_string("2s500ms") == 2.5

    # Test case 11: Minutes, seconds, and milliseconds
    @test parse_time_string("1m30s500ms") == 90.5

    # Test case 12: Decimal milliseconds
    @test parse_time_string("1.5ms") == 0.0015

    # Test case 13: Minutes and milliseconds (no seconds)
    @test parse_time_string("2m500ms") == 120.5

    # Test basic time formats
    @test parse_time_string("1s") == 1.0
    @test parse_time_string("1.5s") == 1.5
    @test parse_time_string("1m") == 60.0
    @test parse_time_string("500ms") == 0.5

    # Test combined formats
    @test parse_time_string("1m30s") == 90.0
    @test parse_time_string("1m30s500ms") == 90.5
    @test parse_time_string("30s500ms") == 30.5

    # Test edge cases
    @test parse_time_string("0s") == 0.0
    @test parse_time_string("0m0s0ms") == 0.0
    @test isnothing(parse_time_string("invalid"))

    # Test potential ambiguous cases
    @test parse_time_string("5m") == 300.0  # 5 minutes
    @test parse_time_string("5ms") == 0.005  # 5 milliseconds

    # Test with spaces (which the current implementation might not handle)
    @test parse_time_string("1m 30s") == 90.0

    # Test with unusual order
    @test parse_time_string("500ms1m") == 60.5  # Should handle any order
end
