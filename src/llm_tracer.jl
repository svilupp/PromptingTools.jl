# Tracing infrastructure for logging and other callbacks
# - Define your own schema that is subtype of AbstractTracerSchema and wraps the underlying LLM provider schema
# - Customize initialize_tracer and finalize_tracer with your custom callback
# - Call your ai* function with the tracer schema as usual

# Simple passthrough, do nothing
function role4render(schema::AbstractTracerSchema, msg::SystemMessage)
    role4render(schema.schema, msg)
end
function role4render(schema::AbstractTracerSchema, msg::UserMessage)
    role4render(schema.schema, msg)
end
function role4render(schema::AbstractTracerSchema, msg::UserMessageWithImages)
    role4render(schema.schema, msg)
end
function role4render(schema::AbstractTracerSchema, msg::AIMessage)
    role4render(schema.schema, msg)
end
function role4render(schema::AbstractTracerSchema, msg::AbstractAnnotationMessage)
    role4render(schema.schema, msg)
end
"""
    render(tracer_schema::AbstractTracerSchema,
        conv::AbstractVector{<:AbstractMessage}; kwargs...)

Passthrough. No changes.
"""
function render(tracer_schema::AbstractTracerSchema,
        conv::AbstractVector{<:AbstractMessage}; kwargs...)
    return conv
end

"""
    initialize_tracer(
        tracer_schema::AbstractTracerSchema; model = "", tracer_kwargs = NamedTuple(),
        prompt::ALLOWED_PROMPT_TYPE = "", kwargs...)

Initializes `tracer`/callback (if necessary). Can provide any keyword arguments in `tracer_kwargs` (eg, `parent_id`, `thread_id`, `run_id`).
Is executed prior to the `ai*` calls.

By default it captures:
- `time_sent`: the time the request was sent
- `model`: the model to use
- `meta`: a dictionary of additional metadata that is not part of the tracer itself
    - `template_name`: the template to use if any
    - `template_version`: the template version to use if any
    - expanded `api_kwargs`, ie, the keyword arguments to pass to the API call

In the default implementation, we just collect the necessary data to build the tracer object in `finalize_tracer`.

See also: `meta`, `unwrap`, `TracerSchema`, `SaverSchema`, `finalize_tracer`
"""
function initialize_tracer(
        tracer_schema::AbstractTracerSchema; model = "", tracer_kwargs = NamedTuple(),
        prompt::ALLOWED_PROMPT_TYPE = "", api_kwargs::NamedTuple = NamedTuple(),
        kwargs...)
    meta = Dict{Symbol, Any}(k => v for (k, v) in pairs(api_kwargs))
    if haskey(tracer_kwargs, :meta)
        ## merge with the provided metadata
        meta = merge(meta, tracer_kwargs.meta)
    end
    if haskey(kwargs, :_tracer_template)
        tpl = get(kwargs, :_tracer_template, nothing)
        meta[:template_name] = tpl.name
        metadata = aitemplates(tpl.name)
        if !isempty(metadata)
            meta[:template_version] = metadata[1].version
        end
    end
    ## provide meta as last to make sure it's not overwriten by kwargs
    return (; time_sent = now(), model,
        tracer_kwargs..., meta)
end

function finalize_tracer(
        tracer_schema::AbstractTracerSchema, tracer, msg_or_conv;
        tracer_kwargs = NamedTuple(), model = "", kwargs...)
    # default is a passthrough
    return msg_or_conv
end
"""
    finalize_tracer(
        tracer_schema::AbstractTracerSchema, tracer, msg_or_conv::Union{
            AbstractMessage, AbstractVector{<:AbstractMessage}};
        tracer_kwargs = NamedTuple(), model = "", kwargs...)

Finalizes the calltracer of whatever is nedeed after the `ai*` calls. Use `tracer_kwargs` to provide any information necessary (eg, `parent_id`, `thread_id`, `run_id`).

In the default implementation, we convert all non-tracer messages into `TracerMessage`.

See also: `meta`, `unwrap`, `SaverSchema`, `initialize_tracer`
"""
function finalize_tracer(
        tracer_schema::AbstractTracerSchema, tracer, msg_or_conv::Union{
            AbstractMessage, AbstractVector{<:AbstractMessage}};
        tracer_kwargs = NamedTuple(), model = "", kwargs...)
    # We already captured all kwargs, they are already in `tracer`, we can ignore them in this implementation
    time_received = now()
    # work with arrays for unified processing
    is_vector = msg_or_conv isa AbstractVector
    conv = msg_or_conv isa AbstractVector{<:AbstractMessage} ?
           convert(Vector{AbstractMessage}, msg_or_conv) :
           AbstractMessage[msg_or_conv]
    # extract the relevant properties from the tracer
    tracer_subset = [f => get(tracer, f, nothing)
                     for f in fieldnames(TracerMessage) if haskey(tracer, f)]
    # all msg non-traced, set times
    for i in eachindex(conv)
        msg = conv[i]
        # change into TracerMessage if not already, use the current kwargs
        if !istracermessage(msg)
            # we saved our data for `tracer`
            conv[i] = TracerMessage(; object = msg, tracer_subset..., time_received)
        end
    end
    return is_vector ? conv : first(conv)
end

## Specialized finalizer to save the response to the disk
"""
    finalize_tracer(
        tracer_schema::SaverSchema, tracer, msg_or_conv::Union{
            AbstractMessage, AbstractVector{<:AbstractMessage}};
        tracer_kwargs = NamedTuple(), model = "", kwargs...)

Finalizes the calltracer by saving the provided conversation `msg_or_conv` to the disk.

Default path is `LOG_DIR/conversation__<first_msg_hash>__<time_received_str>.json`, 
 where `LOG_DIR` is set by user preferences or ENV variable (defaults to `log/` in current working directory).

If you want to change the logging directory or the exact file name to log with, you can provide the following arguments to `tracer_kwargs`:
- `log_dir` - used as the directory to save the log into when provided. Defaults to `LOG_DIR` if not provided.
- `log_file_path` - used as the file name to save the log into when provided. This value overrules the `log_dir` and `LOG_DIR` if provided.

It can be composed with `TracerSchema` to also attach necessary metadata (see below).

# Example
```julia
wrap_schema = PT.SaverSchema(PT.TracerSchema(PT.OpenAISchema()))
conv = aigenerate(wrap_schema,:BlankSystemUser; system="You're a French-speaking assistant!",
    user="Say hi!"; model="gpt-4", api_kwargs=(;temperature=0.1), return_all=true)

# conv is a vector of messages that will be saved to a JSON together with metadata about the template and api_kwargs
```

See also: `meta`, `unwrap`, `TracerSchema`, `initialize_tracer`
"""
function finalize_tracer(
        tracer_schema::SaverSchema, tracer, msg_or_conv::Union{
            AbstractMessage, AbstractVector{<:AbstractMessage}};
        tracer_kwargs = NamedTuple(), model = "", kwargs...)
    # We already captured all kwargs, they are already in `tracer`, we can ignore them in this implementation
    time_received = now()
    # work with arrays for unified processing
    is_vector = msg_or_conv isa AbstractVector
    conv = msg_or_conv isa AbstractVector{<:AbstractMessage} ?
           convert(Vector{AbstractMessage}, msg_or_conv) :
           AbstractMessage[msg_or_conv]

    # Log the conversation to disk, 
    log_dir = get(tracer, :log_dir, LOG_DIR)
    path = if haskey(tracer, :log_file_path)
        ## take the provided log file path
        tracer.log_file_path
    else
        ## save by hash of the first convo message + timestamp
        first_msg_hash = hash(first(conv).content)
        time_received_str = Dates.format(
            time_received, dateformat"YYYYmmdd_HHMMSS")
        path = joinpath(
            log_dir,
            "conversation__$(first_msg_hash)__$(time_received_str).json")
    end
    mkpath(dirname(path))
    save_conversation(path, conv)
    return is_vector ? conv : first(conv)
end

"""
    aigenerate(tracer_schema::AbstractTracerSchema, prompt::ALLOWED_PROMPT_TYPE;
        tracer_kwargs = NamedTuple(), model = "", return_all::Bool = false, kwargs...)

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
        tracer_kwargs = NamedTuple(), model = "", return_all::Bool = false, kwargs...)
    tracer = initialize_tracer(tracer_schema; model, tracer_kwargs, prompt, kwargs...)
    # Force to return all convo and then subset as necessary
    merged_kwargs = isempty(model) ? kwargs : (; model, kwargs...) # to not override default model for each schema if not provided
    msg_or_conv = aigenerate(
        tracer_schema.schema, prompt; tracer_kwargs, return_all = true, merged_kwargs...)
    output = finalize_tracer(
        tracer_schema, tracer, msg_or_conv; model, tracer_kwargs, kwargs...)
    return return_all ? output : last(output)
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
    tracer = initialize_tracer(tracer_schema; model, prompt, tracer_kwargs..., kwargs...)
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
        tracer_kwargs = NamedTuple(), model = "", return_all::Bool = false, kwargs...)
    tracer = initialize_tracer(tracer_schema; model, prompt, tracer_kwargs..., kwargs...)
    # Force to return all convo and then subset as necessary
    merged_kwargs = isempty(model) ? kwargs : (; model, kwargs...) # to not override default model for each schema if not provided
    extract_or_conv = aiextract(
        tracer_schema.schema, prompt; return_all = true, merged_kwargs...)
    output = finalize_tracer(
        tracer_schema, tracer, extract_or_conv; model, tracer_kwargs..., kwargs...)
    return return_all ? output : last(output)
end

"""
    aitools(tracer_schema::AbstractTracerSchema, prompt::ALLOWED_PROMPT_TYPE;
        tracer_kwargs = NamedTuple(), model = "", kwargs...)

Wraps the normal `aitools` call in a tracing/callback system. Use `tracer_kwargs` to provide any information necessary to the tracer/callback system only (eg, `parent_id`, `thread_id`, `run_id`).

Logic:
- calls `initialize_tracer`
- calls `aiextract` (with the `tracer_schema.schema`)
- calls `finalize_tracer`
"""
function aitools(tracer_schema::AbstractTracerSchema, prompt::ALLOWED_PROMPT_TYPE;
        tracer_kwargs = NamedTuple(), model = "", return_all::Bool = false, kwargs...)
    tracer = initialize_tracer(tracer_schema; model, prompt, tracer_kwargs..., kwargs...)
    # Force to return all convo and then subset as necessary
    merged_kwargs = isempty(model) ? kwargs : (; model, kwargs...) # to not override default model for each schema if not provided
    extract_or_conv = aitools(
        tracer_schema.schema, prompt; return_all = true, merged_kwargs...)
    output = finalize_tracer(
        tracer_schema, tracer, extract_or_conv; model, tracer_kwargs..., kwargs...)
    return return_all ? output : last(output)
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
        tracer_kwargs = NamedTuple(), model = "", return_all::Bool = false, kwargs...)
    tracer = initialize_tracer(tracer_schema; model, prompt, tracer_kwargs..., kwargs...)
    # Force to return all convo and then subset as necessary
    merged_kwargs = isempty(model) ? kwargs : (; model, kwargs...) # to not override default model for each schema if not provided
    scan_or_conv = aiscan(
        tracer_schema.schema, prompt; return_all = true, merged_kwargs...)
    output = finalize_tracer(
        tracer_schema, tracer, scan_or_conv; model, tracer_kwargs..., kwargs...)
    return return_all ? output : last(output)
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
        tracer_kwargs = NamedTuple(), model = "", return_all::Bool = false, kwargs...)
    tracer = initialize_tracer(tracer_schema; model, prompt, tracer_kwargs..., kwargs...)
    # Force to return all convo and then subset as necessary
    merged_kwargs = isempty(model) ? kwargs : (; model, kwargs...) # to not override default model for each schema if not provided
    image_or_conv = aiimage(
        tracer_schema.schema, prompt; return_all = true, merged_kwargs...)
    output = finalize_tracer(
        tracer_schema, tracer, image_or_conv; model, tracer_kwargs..., kwargs...)
    return return_all ? output : last(output)
end
