# Tracing infrastructure for logging and other callbacks

# Simple passthrough, do nothing
"""
    render(tracer_schema::AbstractTracerSchema, conv::ALLOWED_PROMPT_TYPE; kwargs...)

Passthrough. No changes.
"""
function render(tracer_schema::AbstractTracerSchema, conv::ALLOWED_PROMPT_TYPE; kwargs...)
    return conv
end

"""
    initialize_tracer(
        tracer_schema::AbstractTracerSchema; model = "", tracer_kwargs = NamedTuple(), kwargs...)

Initializes `tracer`/callback (if necessary). Can provide any keyword arguments in `tracer_kwargs` (eg, `parent_id`, `thread_id`, `run_id`).
Is executed prior to the `ai*` calls.

In the default implementation, we just collect the necessary data to build the tracer object in `finalize_tracer`.
"""
function initialize_tracer(
        tracer_schema::AbstractTracerSchema; model = "", tracer_kwargs = NamedTuple(), kwargs...)
    return (; time_sent = now(), model, tracer_kwargs...)
end

"""
    finalize_tracer(
        tracer_schema::AbstractTracerSchema, tracer, msg_or_conv; tracer_kwargs = NamedTuple(), model = "", kwargs...)

Finalizes the calltracer of whatever is nedeed after the `ai*` calls. Use `tracer_kwargs` to provide any information necessary (eg, `parent_id`, `thread_id`, `run_id`).

In the default implementation, we convert all non-tracer messages into `TracerMessage`.
"""
function finalize_tracer(
        tracer_schema::AbstractTracerSchema, tracer, msg_or_conv; tracer_kwargs = NamedTuple(), model = "", kwargs...)
    # We already captured all kwargs, they are already in `tracer`, we can ignore them in this implementation
    time_received = now()
    @info tracer
    # work with arrays for unified processing
    is_vector = msg_or_conv isa AbstractVector
    conv = msg_or_conv isa AbstractVector{<:AbstractMessage} ?
           convert(Vector{AbstractMessage}, msg_or_conv) :
           AbstractMessage[msg_or_conv]
    # all msg non-traced, set times
    for i in eachindex(conv)
        msg = conv[i]
        # change into TracerMessage if not already, use the current kwargs
        if !istracermessage(msg)
            # we saved our data for `tracer`
            conv[i] = TracerMessage(; object = msg, tracer..., time_received)
        end
    end
    return is_vector ? conv : first(conv)
end

"""
    aigenerate(tracer_schema::AbstractTracerSchema, prompt::ALLOWED_PROMPT_TYPE;
        tracer_kwargs = NamedTuple(), model = "", kwargs...)

Wraps the normal `aigenerate` call in a tracing/callback system. Use `tracer_kwargs` to provide any information necessary to the tracer/callback system only (eg, `parent_id`, `thread_id`, `run_id`).

Logic:
- calls `initialize_tracer`
- calls `aigenerate` (with the `tracer_schema.schema`)
- calls `finalize_tracer`

# Example
```julia
wrap_schema = PT.TracerSchema(PT.OpenAISchema())
msg = aigenerate(wrap_schema, "Say hi!"; model = "gpt4t")
msg isa TracerMessage # true
msg.content # access content like if it was the message
PT.pprint(msg) # pretty-print the message
```

It works on a vector of messages and converts only the non-tracer ones, eg,
```julia
wrap_schema = PT.TracerSchema(PT.OpenAISchema())
conv = aigenerate(wrap_schema, "Say hi!"; model = "gpt4t", return_all = true)
all(PT.istracermessage, conv) #true
```
"""
function aigenerate(tracer_schema::AbstractTracerSchema, prompt::ALLOWED_PROMPT_TYPE;
        tracer_kwargs = NamedTuple(), model = "", kwargs...)
    tracer = initialize_tracer(tracer_schema; model, tracer_kwargs, kwargs...)
    merged_kwargs = isempty(model) ? kwargs : (; model, kwargs...) # to not override default model for each schema if not provided
    msg_or_conv = aigenerate(tracer_schema.schema, prompt; merged_kwargs...)
    return finalize_tracer(
        tracer_schema, tracer, msg_or_conv; model, tracer_kwargs, kwargs...)
end

"""
    aiembed(tracer_schema::AbstractTracerSchema,
        doc_or_docs::Union{AbstractString, AbstractVector{<:AbstractString}}, postprocess::Function = identity;
        tracer_kwargs = NamedTuple(), model = "", kwargs...)

Wraps the normal `aiembed` call in a tracing/callback system. Use `tracer_kwargs` to provide any information necessary to the tracer/callback system only (eg, `parent_id`, `thread_id`, `run_id`).

Logic:
- calls `initialize_tracer`
- calls `aiembed` (with the `tracer_schema.schema`)
- calls `finalize_tracer`
"""
function aiembed(tracer_schema::AbstractTracerSchema,
        doc_or_docs::Union{AbstractString, AbstractVector{<:AbstractString}}, postprocess::Function = identity;
        tracer_kwargs = NamedTuple(), model = "", kwargs...)
    tracer = initialize_tracer(tracer_schema; model, tracer_kwargs..., kwargs...)
    merged_kwargs = isempty(model) ? kwargs : (; model, kwargs...) # to not override default model for each schema if not provided
    embed_or_conv = aiembed(
        tracer_schema.schema, doc_or_docs, postprocess; merged_kwargs...)
    return finalize_tracer(
        tracer_schema, tracer, embed_or_conv; model, tracer_kwargs..., kwargs...)
end

"""
    aiclassify(tracer_schema::AbstractTracerSchema, prompt::ALLOWED_PROMPT_TYPE;
        tracer_kwargs = NamedTuple(), model = "", kwargs...)

Wraps the normal `aiclassify` call in a tracing/callback system. Use `tracer_kwargs` to provide any information necessary to the tracer/callback system only (eg, `parent_id`, `thread_id`, `run_id`).

Logic:
- calls `initialize_tracer`
- calls `aiclassify` (with the `tracer_schema.schema`)
- calls `finalize_tracer`
"""
function aiclassify(tracer_schema::AbstractTracerSchema, prompt::ALLOWED_PROMPT_TYPE;
        tracer_kwargs = NamedTuple(), model = "", kwargs...)
    tracer = initialize_tracer(tracer_schema; model, tracer_kwargs..., kwargs...)
    merged_kwargs = isempty(model) ? kwargs : (; model, kwargs...) # to not override default model for each schema if not provided
    classify_or_conv = aiclassify(tracer_schema.schema, prompt; merged_kwargs...)
    return finalize_tracer(
        tracer_schema, tracer, classify_or_conv; model, tracer_kwargs..., kwargs...)
end

"""
    aiextract(tracer_schema::AbstractTracerSchema, prompt::ALLOWED_PROMPT_TYPE;
        tracer_kwargs = NamedTuple(), model = "", kwargs...)

Wraps the normal `aiextract` call in a tracing/callback system. Use `tracer_kwargs` to provide any information necessary to the tracer/callback system only (eg, `parent_id`, `thread_id`, `run_id`).

Logic:
- calls `initialize_tracer`
- calls `aiextract` (with the `tracer_schema.schema`)
- calls `finalize_tracer`
"""
function aiextract(tracer_schema::AbstractTracerSchema, prompt::ALLOWED_PROMPT_TYPE;
        tracer_kwargs = NamedTuple(), model = "", kwargs...)
    tracer = initialize_tracer(tracer_schema; model, tracer_kwargs..., kwargs...)
    merged_kwargs = isempty(model) ? kwargs : (; model, kwargs...) # to not override default model for each schema if not provided
    extract_or_conv = aiextract(tracer_schema.schema, prompt; merged_kwargs...)
    return finalize_tracer(
        tracer_schema, tracer, extract_or_conv; model, tracer_kwargs..., kwargs...)
end

"""
    aiscan(tracer_schema::AbstractTracerSchema, prompt::ALLOWED_PROMPT_TYPE;
        tracer_kwargs = NamedTuple(), model = "", kwargs...)

Wraps the normal `aiscan` call in a tracing/callback system. Use `tracer_kwargs` to provide any information necessary to the tracer/callback system only (eg, `parent_id`, `thread_id`, `run_id`).

Logic:
- calls `initialize_tracer`
- calls `aiscan` (with the `tracer_schema.schema`)
- calls `finalize_tracer`
"""
function aiscan(tracer_schema::AbstractTracerSchema, prompt::ALLOWED_PROMPT_TYPE;
        tracer_kwargs = NamedTuple(), model = "", kwargs...)
    tracer = initialize_tracer(tracer_schema; model, tracer_kwargs..., kwargs...)
    merged_kwargs = isempty(model) ? kwargs : (; model, kwargs...) # to not override default model for each schema if not provided
    scan_or_conv = aiscan(tracer_schema.schema, prompt; merged_kwargs...)
    return finalize_tracer(
        tracer_schema, tracer, scan_or_conv; model, tracer_kwargs..., kwargs...)
end

"""
    aiimage(tracer_schema::AbstractTracerSchema, prompt::ALLOWED_PROMPT_TYPE;
        tracer_kwargs = NamedTuple(), model = "", kwargs...)

Wraps the normal `aiimage` call in a tracing/callback system. Use `tracer_kwargs` to provide any information necessary to the tracer/callback system only (eg, `parent_id`, `thread_id`, `run_id`).

Logic:
- calls `initialize_tracer`
- calls `aiimage` (with the `tracer_schema.schema`)
- calls `finalize_tracer`
"""
function aiimage(tracer_schema::AbstractTracerSchema, prompt::ALLOWED_PROMPT_TYPE;
        tracer_kwargs = NamedTuple(), model = "", kwargs...)
    tracer = initialize_tracer(tracer_schema; model, tracer_kwargs..., kwargs...)
    merged_kwargs = isempty(model) ? kwargs : (; model, kwargs...) # to not override default model for each schema if not provided
    image_or_conv = aiimage(tracer_schema.schema, prompt; merged_kwargs...)
    return finalize_tracer(
        tracer_schema, tracer, image_or_conv; model, tracer_kwargs..., kwargs...)
end
