# ## Create Retry Layer
## Define the new retry mechanism as a layer for HTTP
## See documentation [here](https://juliaweb.github.io/HTTP.jl/stable/client/#Quick-Examples)
"""
    CustomRetryLayer

Custom retry layer for HTTP.jl. Once installed, it will catch all errors with status codes 429, 404, 503 and retry with exponential backoff (can be customized).

# Examples
```julia
using HTTP
using PromptingTools

# Let's push the layer globally in all HTTP.jl requests
HTTP.pushlayer!(PromptingTools.CustomRetryLayer.custom_retry_layer, request=true) # for stream handling, we would set request=false

# Let's call the API - it fails with 404 Not Found (bad model name)
msg = aigenerate("What is the meaning of life?", model = "bad-name")

# Let's catch the 404 error in retry loop to demonstrate the retry logic
msg = aigenerate("What is the meaning of life?", model = "bad-name", http_kwargs = (; custom_retry_status_codes = [404]))

# We can temporarily disable the custom retry logic by setting custom_retry_enabled = false
msg = aigenerate("What is the meaning of life?", model = "bad-name", http_kwargs = (; custom_retry_enabled = false))
```

We can also remove the layer completely
```julia
HTTP.poplayer!() # you should see it pop off the stack
```

The layer is generally in either `HTTP.REQUEST_LAYERS` or `HTTP.STREAM_LAYERS`, depending on whether you set `request=true` or `request=false` in the `pushlayer!` call.

There is much more to customize, eg, `custom_retry_max_retries`, `custom_retry_base_delay`, `custom_retry_status_codes`).
```julia
msg = aigenerate("What is the meaning of life?", model = "bad-name", http_kwargs = (; custom_retry_status_codes = [429]))
```
"""
module CustomRetryLayer

using HTTP, JSON3
using Dates

# Global state to track rate limiting
mutable struct RateLimitState
    paused_until::Union{DateTime, Nothing}
    mutex::ReentrantLock
end

# Initialize the global state
const RATE_LIMIT_STATE = RateLimitState(nothing, ReentrantLock())

"""
    is_paused()

Check if requests should be paused due to rate limiting.
Returns a tuple (is_paused, seconds_remaining) where:
- is_paused: Boolean indicating if requests should be paused
- seconds_remaining: How many seconds to wait if paused
"""
function is_paused()::Tuple{Bool, Float64}
    lock(RATE_LIMIT_STATE.mutex) do
        if isnothing(RATE_LIMIT_STATE.paused_until)
            return false, 0.0
        end

        now_time = now()
        if now_time < RATE_LIMIT_STATE.paused_until
            seconds_remaining = float(Dates.value(RATE_LIMIT_STATE.paused_until -
                                                  now_time)) / 1000.0
            return true, seconds_remaining
        else
            # Reset the pause state since we're past the pause time
            RATE_LIMIT_STATE.paused_until = nothing
            return false, 0.0
        end
    end
end

"""
    pause_requests(seconds::Float64)

Pause all requests for the specified number of seconds.
"""
function pause_requests(seconds::Float64)
    lock(RATE_LIMIT_STATE.mutex) do
        pause_until = now() + Dates.Millisecond(round(Int, seconds * 1000))

        # Only update if the new pause time is later than any existing pause
        if isnothing(RATE_LIMIT_STATE.paused_until) ||
           pause_until > RATE_LIMIT_STATE.paused_until
            RATE_LIMIT_STATE.paused_until = pause_until
            @info "All requests paused until $(RATE_LIMIT_STATE.paused_until) ($(round(seconds, digits=2))s)"
        end
    end
end

"""
    parse_time_string(time_str::AbstractString)

Parses a time string like "1s", "6m0s", "1m30s", "500ms", or "1m30s500ms" into seconds.
Returns the time in seconds as a Float64, or `nothing` if parsing fails.
"""
function parse_time_string(time_str::AbstractString)::Union{Float64, Nothing}
    total_seconds = 0.0
    remaining = time_str

    # Match milliseconds first (to avoid confusion with minutes)
    ms_match = match(r"(\d+(\.\d+)?)ms", remaining)
    if !isnothing(ms_match)
        milliseconds = parse(Float64, ms_match.captures[1])
        total_seconds += milliseconds / 1000.0
        remaining = replace(remaining, ms_match.match => "")
    end

    # Match minutes (now safe since we've already handled milliseconds)
    m_match = match(r"(\d+)m(?!s)", remaining)
    if !isnothing(m_match)
        minutes = parse(Float64, m_match.captures[1])
        total_seconds += minutes * 60
        remaining = replace(remaining, m_match.match => "")
    end

    # Match seconds
    s_match = match(r"(\d+(\.\d+)?)s(?!ms)", remaining)
    if !isnothing(s_match)
        seconds = parse(Float64, s_match.captures[1])
        total_seconds += seconds
        remaining = replace(remaining, s_match.match => "")
    end

    # Check if we found any time components
    if ms_match === nothing && m_match === nothing && s_match === nothing
        return nothing  # No valid time components found, return nothing
    else
        return total_seconds  # Return the total seconds, even if it's 0.0
    end
end

"""
    extract_retry_after(headers::Dict{String, String})

Extracts the retry-after time in seconds from the headers.

It checks for the following headers in order of priority:
1. `retry-after-ms` (milliseconds)
2.  `retry-after` (seconds)
3.  `X-Ratelimit-Reset` (seconds)
4.  `x-ratelimit-reset-requests` (seconds/minutes/both)
5.  `x-ratelimit-reset-tokens` (seconds/minutes/both)

Returns the retry-after time in seconds as a Float64, or `nothing` if no such header is found.
"""
function extract_retry_after(headers::Dict{String, String})::Union{Float64, Nothing}
    if haskey(headers, "retry-after-ms")
        return parse(Float64, headers["retry-after-ms"]) / 1000.0
    elseif haskey(headers, "retry-after")
        return parse(Float64, headers["retry-after"])
    elseif haskey(headers, "X-Ratelimit-Reset")
        return parse(Float64, headers["X-Ratelimit-Reset"])
    else
        # Check for the rate limit headers and parse them
        reset_times = Float64[]
        for header in ["x-ratelimit-reset-requests", "x-ratelimit-reset-tokens"]
            if haskey(headers, header)
                value = headers[header]
                if occursin(r"[sm]", value)
                    time = parse_time_string(value)
                    if !isnothing(time)
                        push!(reset_times, time)
                    end
                elseif all(isdigit, value)
                    time = tryparse(Float64, value)
                    if !isnothing(time)
                        push!(reset_times, time)
                    end
                end
            end
        end

        # Return the minimum reset time if any
        if !isempty(reset_times)
            return minimum(reset_times)
        else
            return nothing
        end
    end
end

"""
    custom_retry_layer(
        handler;
        custom_retry_enabled::Bool = true,
        custom_retry_max_retries::Int = 5,
        custom_retry_base_delay::Float64 = 2.0,
        custom_retry_status_codes = [429],
        custom_retry_show_headers::Bool = true
)

HTTP-layer that retries requests with exponential backoff or with a delay specified in the headers.
It pauses all requests globally (to not overwhelm the server when using `asyncmap`) when a rate limit is hit.

By default, we only retry on 429 (rate limit hit) errors - most common issue with LLM providers.

# Examples
```julia
using HTTP
using PromptingTools    

# Let's push the layer globally in all HTTP.jl requests
HTTP.pushlayer!(PromptingTools.CustomRetryLayer.custom_retry_layer, request=true) # for stream handling, we would set request=false

# All calls should have retry set for 429 errors
msg = aigenerate("What is the meaning of life?")
```
"""
function custom_retry_layer(
        handler;
        custom_retry_enabled::Bool = true,
        custom_retry_max_retries::Int = 5,
        custom_retry_base_delay::Float64 = 2.0,
        custom_retry_status_codes = [429],
        custom_retry_show_headers::Bool = true
)
    return function (req; kw...)
        # If retries are disabled, just pass through to the handler
        if !custom_retry_enabled
            return handler(req; kw...)
        end

        # Check if requests are currently paused
        paused, wait_time = is_paused()
        if paused
            @info "Request paused due to rate limiting. Waiting $(round(wait_time, digits=2)) seconds."
            sleep(wait_time)
        end

        # Retry logic
        num_retries = 0
        while true
            try
                resp = handler(req; kw...)
                return resp  # Success! Return the response
            catch e
                if e isa HTTP.Exceptions.StatusError
                    status_code = e.status
                    if status_code in custom_retry_status_codes
                        num_retries += 1
                        if num_retries > custom_retry_max_retries
                            @error "Max retries reached. Failing the request."
                            rethrow(e)  # Re-throw the exception
                        end

                        ## Custom behavior
                        if status_code == 429
                            # Try to extract the delay from the headers
                            retry_after = extract_retry_after(Dict(string(k) => string(v)
                            for (k, v) in e.response.headers))
                            if !isnothing(retry_after) && retry_after > 0
                                delay = retry_after
                                @warn """
                                    Rate limit hit (429). Pausing all requests for $(round(delay, digits=2)) seconds (attempt $num_retries/$custom_retry_max_retries) from headers.
                                    $(custom_retry_show_headers ? """
                                    Headers:
                                    $(join(["$k: $v" for (k,v) in e.response.headers], "\n    "))
                                    """ : "")
                                    """
                                # Pause all requests
                                pause_requests(delay)
                            else
                                # Exponential backoff for rate limiting
                                delay = custom_retry_base_delay * (2^(num_retries - 1)) +
                                        rand()
                                @warn """Rate limit hit (429). Pausing all requests for $(round(delay, digits=2)) seconds (attempt $num_retries/$custom_retry_max_retries) with exponential backoff.
                                $(custom_retry_show_headers ? """
                                Headers:
                                $(join(["$k: $v" for (k,v) in e.response.headers], "\n    "))
                                """ : "")
                                """
                                # Pause all requests
                                pause_requests(delay)
                            end
                            sleep(delay)
                        else
                            delay = custom_retry_base_delay * (2^(num_retries - 1)) + rand()
                            @warn """Status code $(status_code). Retrying in $(round(delay, digits=2)) seconds (attempt $num_retries/$custom_retry_max_retries).
                            $(custom_retry_show_headers ? """
                            Headers:
                            $(join(["$k: $v" for (k,v) in e.response.headers], "\n    "))
                            """ : "")
                            """
                            sleep(delay)
                        end
                    else
                        # Not a 429 or 404, re-throw the exception
                        rethrow(e)
                    end
                else
                    # Not an HTTP error, re-throw the exception
                    rethrow(e)
                end
            end
        end
        # pass the request along to the next layer by calling `cache_layer` arg `handler`
        # also pass along the trailing keyword args `kw...`
        return handler(req; kw...)
    end
end

"""
    custom_retry_layer!(enable::Bool = true; request::Bool = true)

Enable or disable the custom retry layer. 
A convenience function that only installs the layer in the HTTP.jl stack if it's not already installed.

# Examples
```julia
using HTTP
using PromptingTools

# Enable the custom retry layer
custom_retry_layer!(true)

# Disable the custom retry layer
custom_retry_layer!(false)
```
"""
function custom_retry_layer!(enable::Bool = true; request::Bool = true)
    # Get the appropriate layer stack based on request parameter
    layer_stack = request ? HTTP.REQUEST_LAYERS : HTTP.STREAM_LAYERS
    layer_pos = findfirst(layer -> layer == custom_retry_layer, layer_stack)

    if enable && isnothing(layer_pos)
        HTTP.pushlayer!(custom_retry_layer, request = request)
    elseif enable
        @warn "Custom retry layer is already in position $layer_pos of the $(request ? "request" : "stream") layer stack"
    elseif !enable && !isnothing(layer_pos)
        deleteat!(layer_stack, layer_pos)
    else
        @warn "Custom retry layer not found in the $(request ? "request" : "stream") layer stack"
    end
end

# Create a new client with the retry layer added
HTTP.@client [custom_retry_layer]

end # module