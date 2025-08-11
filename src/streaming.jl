# # Interface for streaming

abstract type AbstractStreamCallback end

function configure_callback!(cb::AbstractStreamCallback, schema::AbstractPromptSchema;
        api_kwargs...)
    error("Unimplemented configure_callback! for $(typeof(cb)) and $(typeof(schema)).")
end

function streamed_request!(cb::AbstractStreamCallback, url, headers, input; kwargs...)
    error("Unimplemented streamed_request! for $(typeof(cb)).")
end

# this is from StreamCallbacks.jl
Base.empty!(cb::AbstractStreamCallback) = empty!(cb.chunks)
Base.push!(cb::AbstractStreamCallback, chunk::StreamChunk) = push!(cb.chunks, chunk)
Base.isempty(cb::AbstractStreamCallback) = isempty(cb.chunks)
Base.length(cb::AbstractStreamCallback) = length(cb.chunks)