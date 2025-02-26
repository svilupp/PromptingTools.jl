## The Simplest workflow
using PromptingTools
# Enable the custom retry layer
custom_retry_layer!(true)
# Any rate limiting / rate limit errors will be retried automatically
aigenerate("What is the meaning of life?")
# Uninstall with / remove it with
custom_retry_layer!(false)

## More Advanced use
using HTTP
using PromptingTools

# Let's push the layer globally in all HTTP.jl requests
HTTP.pushlayer!(PromptingTools.CustomRetryLayer.custom_retry_layer, request = true) # for stream handling, we would set request=false

# Let's call the API - it fails with 404 Not Found (bad model name)
msg = aigenerate("What is the meaning of life?", model = "bad-name")

# Let's catch the 404 error in retry loop to demonstrate the retry logic
msg = aigenerate("What is the meaning of life?", model = "bad-name",
    http_kwargs = (; custom_retry_status_codes = [404]))

# We can temporarily disable the custom retry logic by setting custom_retry_enabled = false
msg = aigenerate("What is the meaning of life?", model = "bad-name",
    http_kwargs = (; custom_retry_enabled = false))

# We can also remove the layer completely
HTTP.poplayer!() # you should see it pop off the stack

# The layer is generally in either `HTTP.REQUEST_LAYERS` or `HTTP.STREAM_LAYERS`, depending on whether you set `request=true` or `request=false` in the `pushlayer!` call.

# There is much more to customize, eg, `custom_retry_max_retries`, `custom_retry_base_delay`, `custom_retry_status_codes`).
msg = aigenerate("What is the meaning of life?", model = "bad-name",
    http_kwargs = (; custom_retry_status_codes = [429]))

# You can also use the convenience function `custom_retry_layer!` to enable/disable the custom retry layer.
custom_retry_layer!(true)

# Disable the custom retry layer
custom_retry_layer!(false)
