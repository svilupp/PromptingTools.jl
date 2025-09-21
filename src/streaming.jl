# # Interface for streaming

abstract type AbstractStreamCallback end

function configure_callback!(cb::AbstractStreamCallback, schema::AbstractPromptSchema;
        api_kwargs...)
    error("Unimplemented configure_callback! for $(typeof(cb)) and $(typeof(schema)).")
end

function streamed_request!(cb::AbstractStreamCallback, url, headers, input; kwargs...)
    error("Unimplemented streamed_request! for $(typeof(cb)).")
end