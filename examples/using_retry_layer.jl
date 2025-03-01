# # Using the Retry Layer
#
# The retry layer automatically handles temporary API failures by retrying requests that fail with specific 
# HTTP status codes (like rate limiting). This is especially useful when working with external AI services 
# that might have usage limits or temporary availability issues.

# ## The Simplest workflow
using PromptingTools

# Enable the retry layer with default settings (retries 429 status codes)
# This adds a middleware layer to HTTP requests that will automatically retry when rate limited
enable_retry!()

# Any rate limiting errors (status code 429) will be retried automatically
# The system will use exponential backoff to wait progressively longer between retries
aigenerate("What is the meaning of life?")

# Disable the retry layer when done
# This removes the middleware from the HTTP request pipeline
enable_retry!(false)

## Advanced usage: Configuring global defaults -- only before the first call to `custom_retry_layer`!
using PromptingTools
using HTTP

# Enable with custom global defaults
enable_retry!(;
    max_retries = 3,                   # Maximum 3 retry attempts (default is 5)
    base_delay = 1.0,                  # Start with 1 second delay (default is 2.0)
    status_codes = [429, 503, 504],    # Retry on rate limits and server errors
    show_headers = false               # Don't show headers in warning messages
)

# All subsequent requests will use these global defaults
aigenerate("What is the meaning of life?")

# ## Per-request customization
# Override specific settings for a single request
msg = aigenerate("Write a poem about AI",
    http_kwargs = (;
        custom_retry_max_retries = 10,         # Try harder for this request
        custom_retry_status_codes = [429, 404] # Also retry on 404 errors
    )
)

# Temporarily disable retries for a specific request
msg = aigenerate("What is 2+2?",
    http_kwargs = (; custom_retry_enabled = false)
)

# ## Low-level HTTP layer management
# Check which layers are currently installed
println("Current HTTP request layers: ", HTTP.REQUEST_LAYERS)

# Manually remove the retry layer
enable_retry!(false)

# Manually install the retry layer for stream requests instead of request handlers
# This affects streaming API calls rather than standard requests
enable_retry!(; request = false)

# Remove from stream layers
enable_retry!(false; request = false)

## Note on configuration hierarchy (from lowest to highest priority):
# 1. Default values in CustomRetryConfig
# 2. Values set with enable_retry!() function
# 3. Per-request values in http_kwargs
#
# This means that per-request settings always override global settings, which override defaults.

# ## How It Works
#
# The retry layer is implemented as a middleware component in Julia's HTTP.jl package.
# Here's how the implementation works under the hood:
#
# ### HTTP Layer Stack
# HTTP.jl uses a layered approach for request processing. Each layer can modify 
# requests/responses or implement specific behaviors like retrying or logging.
# 
# - The retry layer is inserted into this stack using `HTTP.pushlayer!()`
# - When disabled, it's removed with `HTTP.poplayer!()`
# - Layers are executed in order, with each having the opportunity to handle requests/responses
#
# ### Retry Logic Implementation
#
# When a request fails with a specified status code, the retry layer:
#
# 1. Examines response headers to determine wait time:
#    - Looks for headers like `Retry-After`, `RateLimit-Reset`, or `X-RateLimit-Reset`
#    - These headers often indicate how long to wait before trying again
#
# 2. If no specific wait time is found, uses exponential backoff:
#    - Starts with `base_delay` (default: 2 seconds)
#    - Each subsequent retry multiplies this by 2 (plus some jitter)
#    - This prevents overwhelming the API with immediate retry attempts
#
# ### Concurrency Control
#
# To handle multiple concurrent requests gracefully:
#
# - A global `ReentrantLock` is used to coordinate all retry attempts
# - This ensures that even highly concurrent applications respect rate limits
# - When one thread is delayed due to rate limiting, other threads will also be throttled
# - This prevents the "thundering herd" problem where multiple threads hit rate limits simultaneously
#
# ### Best Practices
#
# 1. Enable the retry layer early in your application startup
# 2. Configure global defaults appropriately for your API provider
# 3. Adjust per-request settings only when necessary for specific calls
# 4. Consider disabling the retry layer when making time-sensitive requests where retrying might be harmful
#
# The retry system is designed to be unobtrusive while providing robust handling of 
# temporary failures, especially for long-running processes or batch operations.
