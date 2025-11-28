# # Experimental support for streaming

# All code besides the API configuration is in StreamCallbacks package now

"""
    configure_callback!(cb::StreamCallback, schema::AbstractPromptSchema;
        api_kwargs...)

Configures the callback `cb` for streaming with a given prompt schema.

If no `cb.flavor` is provided, adjusts the `flavor` and the provided `api_kwargs` as necessary.
Eg, for most schemas, we add kwargs like `stream = true` to the `api_kwargs`.

If `cb.flavor` is provided, both `callback` and `api_kwargs` are left unchanged! You need to configure them yourself!
"""
function configure_callback!(cb::T, schema::AbstractPromptSchema;
        api_kwargs...) where {T <: AbstractStreamCallback}
    ## Check if we are in passthrough mode or if we should configure the callback
    if isnothing(cb.flavor)
        if schema isa AbstractOpenAISchema
            ## Enable streaming for all OpenAI-compatible APIs
            api_kwargs = (;
                api_kwargs..., stream = true, stream_options = (; include_usage = true))
            flavor = OpenAIStream()
        elseif schema isa AbstractOpenAIResponseSchema
            ## Enable streaming for Response API
            api_kwargs = (; api_kwargs..., stream = true)
            flavor = OpenAIResponsesStream()
        elseif schema isa Union{AbstractAnthropicSchema, AbstractOllamaSchema}
            api_kwargs = (; api_kwargs..., stream = true)
            flavor = schema isa AbstractOllamaSchema ? OllamaStream() : AnthropicStream()
        elseif schema isa AbstractOllamaManagedSchema
            throw(ErrorException("OllamaManagedSchema is not supported for streaming. Use OllamaSchema instead."))
        else
            error("Unsupported schema type: $(typeof(schema)). Currently supported: OpenAISchema, AbstractOpenAIResponseSchema, and AnthropicSchema.")
        end
        cb.flavor = flavor
    end
    return cb, api_kwargs
end
# method to build a callback for a given output stream
function configure_callback!(
        output_stream::Union{IO, Channel}, schema::AbstractPromptSchema)
    cb = StreamCallback(out = output_stream)
    return configure_callback!(cb, schema)
end
