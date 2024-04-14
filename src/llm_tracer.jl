# Tracing infrastructure for logging and other callbacks

# Simple passthrough
function render(tracer_schema::AbstractTracerSchema, conv; kwargs...)
    return conv
end
function initialize_tracer(tracer_schema::AbstractTracerSchema; kwargs...)
    return tracer_schema
end
function finalize_tracer(tracer_schema::AbstractTracerSchema, tracer, conv; kwargs...)
    return conv
end
function aigenerate(tracer_schema::AbstractTracerSchema, args...; kwargs...)
    tracer = initialize_tracer(tracer_schema; kwargs...)
    conv = aigenerate(tracer_schema.schema, args...; kwargs...)
    return finalize_tracer(tracer_schema, tracer, conv; kwargs...)
end
