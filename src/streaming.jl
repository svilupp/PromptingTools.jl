# # Experimental support for streaming
# This code should be carved out into a separate package and upstreamed when stable

### Define the types
abstract type AbstractStreamCallback end
abstract type AbstractStreamFlavor end
struct OpenAIStream <: AbstractStreamFlavor end
struct AnthropicStream <: AbstractStreamFlavor end

"""
    StreamChunk

A chunk of streaming data. A message is composed of multiple chunks.

# Fields
- `event`: The event name.
- `data`: The data chunk.
- `json`: The JSON object or `nothing` if the chunk does not contain JSON.
"""
@kwdef struct StreamChunk{T1 <: AbstractString, T2 <: Union{JSON3.Object, Nothing}}
    event::Union{Symbol, Nothing} = nothing
    data::T1 = ""
    json::T2 = nothing
end
function Base.show(io::IO, chunk::StreamChunk)
    data_preview = if length(chunk.data) > 10
        "$(first(chunk.data, 10))..."
    else
        chunk.data
    end
    json_keys = if !isnothing(chunk.json)
        join(keys(chunk.json), ", ", " and ")
    else
        "-"
    end
    print(io,
        "StreamChunk(event=$(chunk.event), data=$(data_preview), json keys=$(json_keys))")
end

"""
    StreamCallback

Simplest callback for streaming message, which just prints the content to the output stream defined by `out`.

For more complex use cases, you can define your own `callback`. See the interface description below for more information.

# Fields
- `out`: The output stream, eg, `stdout` or a pipe.
- `flavor`: The stream flavor which might or might not differ between different providers, eg, `OpenAIStream` or `AnthropicStream`.
- `chunks`: The list of `StreamChunk` chunks.
- `kwargs`: The keyword arguments, eg, `verbose=true` to see more details.

# Interface
- `extract_chunks(flavor, blob)`: Extract the chunks from the received SSE blob. Returns a list of `StreamChunk` and the next spillover (if message was incomplete).
- `callback(cb, chunk)`: Process the chunk to be printed
    - `extract_content(flavor, chunk)`: Extract the content from the chunk.
    - `print_content(out, text)`: Print the content to the output stream.
- `is_done(flavor, chunk)`: Check if the stream is done.
- `build_response_body(flavor, cb)`: Build the response body from the chunks to mimic receiving a standard response from the API.

If you want to implement your own callback, you can create your own methods for the interface functions.
Eg, if you want to print the streamed chunks into a Channel, you could define a simple method just for `print_content`.

"""
@kwdef mutable struct StreamCallback{
    T1 <: Any, T2 <: Union{AbstractStreamFlavor, Nothing}} <:
                      AbstractStreamCallback
    out::T1 = stdout
    flavor::T2 = nothing
    chunks::Vector{StreamChunk} = StreamChunk[]
    kwargs::NamedTuple = NamedTuple()
end
function Base.show(io::IO, cb::StreamCallback)
    print(io,
        "StreamCallback(out=$(cb.out), flavor=$(cb.flavor), chunks=$(length(cb.chunks)) items)")
end

### Convenience utilities
"""
    configure_callback!(cb::AbstractStreamCallback, schema::AbstractPromptSchema;
        api_kwargs::NamedTuple = NamedTuple(), kwargs...)

Configures the callback `cb` for streaming with a given prompt schema.
If no `cb.flavor` is provided, adjusts the `flavor` and the provided `api_kwargs` as necessary.
"""
function configure_callback!(cb::T, schema::AbstractPromptSchema;
        api_kwargs...) where {T <: AbstractStreamCallback}
    ## Check if we are in passthrough mode or if we should configure the callback
    if isnothing(cb.flavor)
        if schema isa OpenAISchema
            api_kwargs = (;
                api_kwargs..., stream = true, stream_options = (; include_usage = true))
            flavor = OpenAIStream()
        elseif schema isa AnthropicSchema
            api_kwargs = (; api_kwargs..., stream = true)
            flavor = AnthropicStream()
        else
            error("Unsupported schema type: $(typeof(schema)). Currently supported: OpenAISchema and AnthropicSchema.")
        end
        cb = StreamCallback(; [f => getfield(cb, f) for f in fieldnames(T)]...,
            flavor)
    end
    return cb, api_kwargs
end
# method to build a callback for a given output stream
function configure_callback!(output_stream::IO, schema::AbstractPromptSchema)
    cb = StreamCallback(out = output_stream)
    return configure_callback!(cb, schema)
end

### Define the interface functions
function is_done end
function extract_chunks end
function extract_content end
function print_content end
function callback end
function build_response_body end
function streamed_request end

### Define the necessary methods -- start with OpenAIStream

# Define the interface functions
"""
    is_done(flavor, chunk)

Check if the streaming is done. Shared by all streaming flavors currently.
"""
@inline function is_done(flavor::OpenAIStream, chunk::StreamChunk; kwargs...)
    chunk.data == "[DONE]"
end

@inline function is_done(flavor::AnthropicStream, chunk::StreamChunk; kwargs...)
    chunk.event == :error || chunk.event == :message_stop
end

"""
    extract_chunks(flavor, blob)

Extract the chunks from the received SSE blob. Shared by all streaming flavors currently.

Returns a list of `StreamChunk` and the next spillover (if message was incomplete).
"""
@inline function extract_chunks(flavor::Any, blob::AbstractString;
        spillover::AbstractString = "", verbose::Bool = false, kwargs...)
    chunks = StreamChunk[]
    next_spillover = ""
    ## SSE come separated by double-newlines
    blob_split = split(blob, "\n\n")
    for (bi, chunk) in enumerate(blob_split)
        isempty(chunk) && continue
        event_split = split(chunk, "event: ")
        has_event = length(event_split) > 1
        # if length>1, we know it was there!
        for event_blob in event_split
            isempty(event_blob) && continue
            event_name = nothing
            data_buf = IOBuffer()
            data_splits = split(event_blob, "data: ")
            for i in eachindex(data_splits)
                isempty(data_splits[i]) && continue
                if i == 1 & has_event && !isempty(data_splits[i])
                    ## we have an event name
                    event_name = strip(data_splits[i]) |> Symbol
                elseif bi == 1 && i == 1 && !isempty(data_splits[i])
                    ## in the first part of the first blob, it must be a spillover
                    spillover = string(spillover, rstrip(data_splits[i], '\n'))
                    verbose && @info "Buffer spillover detected: $(spillover)"
                elseif i > 1
                    ## any subsequent data blobs are accummulated into the data buffer
                    ## there can be multiline data that must be concatenated
                    data_chunk = rstrip(data_splits[i], '\n')
                    write(data_buf, data_chunk)
                end
            end
            ## On the last iteration of the blob, check if we spilled over
            if bi == length(blob_split) && length(data_splits) > 1 &&
               !isempty(strip(data_splits[end]))
                verbose && @info "Incomplete message detected: $(data_splits[end])"
                next_spillover = data_splits[end]
            end
            ## Parse the spillover
            if bi == 1 && !isempty(spillover)
                data = spillover
                json = if startswith(data, '{') && endswith(data, '}')
                    try
                        JSON3.read(data)
                    catch e
                        verbose && @warn "Cannot parse JSON: $raw_chunk"
                        nothing
                    end
                else
                    nothing
                end
                ## ignore event name
                push!(chunks, StreamChunk(; data = spillover, json = json))
                # reset the spillover
                spillover = ""
            end
            ## Try to parse the data as JSON
            data = String(take!(data_buf))
            ## try to build a JSON object if it's a well-formed JSON string
            json = if startswith(data, '{') && endswith(data, '}')
                try
                    JSON3.read(data)
                catch e
                    verbose && @warn "Cannot parse JSON: $raw_chunk"
                    nothing
                end
            else
                nothing
            end
            ## Create a new chunk
            push!(chunks, StreamChunk(event_name, data, json))
        end
    end
    return chunks, next_spillover
end

"""
    extract_content(flavor::OpenAIStream, chunk)

Extract the content from the chunk.
"""
@inline function extract_content(flavor::OpenAIStream, chunk::StreamChunk; kwargs...)
    if !isnothing(chunk.json)
        ## Can contain more than one choice for multi-sampling, but ignore for callback
        ## Get only the first choice
        choices = get(chunk.json, :choices, [])
        first_choice = get(choices, 1, Dict())
        delta = get(first_choice, :delta, Dict())
        out = get(delta, :content, nothing)
    else
        nothing
    end
end

"""
    print_content(out::IO, text::AbstractString; kwargs...)

Print the content to the IO output stream `out`.
"""
@inline function print_content(out::IO, text::AbstractString; kwargs...)
    print(out, text)
    # flush(stdout)
end
"""
    print_content(out::Channel, text::AbstractString; kwargs...)

Print the content to the provided Channel `out`.
"""
@inline function print_content(out::Channel, text::AbstractString; kwargs...)
    put!(out, text)
end

"""
    print_content(out::Nothing, text::Any)

Do nothing if the output stream is `nothing`.
"""
@inline function print_content(out::Nothing, text::Any; kwargs...)
    return nothing
end

"""
    callback(cb::StreamCallback, chunk::StreamChunk; kwargs...)

Process the chunk to be printed and print it. It's a wrapper for two operations:
- extract the content from the chunk using `extract_content`
- print the content to the output stream using `print_content`
"""
@inline function callback(cb::AbstractStreamCallback, chunk::StreamChunk; kwargs...)
    processed_text = extract_content(cb.flavor, chunk; kwargs...)
    isnothing(processed_text) && return nothing
    print_content(cb.out, processed_text; kwargs...)
    return nothing
end
@inline function handle_error_message(chunk::StreamChunk; kwargs...)
    if chunk.event == :error ||
       (isnothing(chunk.event) && !isnothing(chunk.json) &&
        haskey(chunk.json, :error))
        has_error_dict = !isnothing(chunk.json) &&
                         get(chunk.json, :error, nothing) isa AbstractDict
        ## Build the error message
        error_str = if has_error_dict
            join(
                ["$(titlecase(string(k))): $(v)"
                 for (k, v) in pairs(chunk.json.error)],
                ", ")
        else
            string(chunk.data)
        end
        @warn "Error detected in the streaming response: $(error_str)"
    end
    return nothing
end

"""
    build_response_body(flavor::OpenAIStream, cb::StreamCallback; kwargs...)

Build the response body from the chunks to mimic receiving a standard response from the API.

Note: Limited functionality for now. Does NOT support tool use, refusals, logprobs. Use standard responses for these.
"""
function build_response_body(
        flavor::OpenAIStream, cb::StreamCallback; verbose::Bool = false, kwargs...)
    isempty(cb.chunks) && return nothing
    response = nothing
    usage = nothing
    choices_output = Dict{Int, Dict{Symbol, Any}}()
    for i in eachindex(cb.chunks)
        chunk = cb.chunks[i]
        ## validate that we can access choices
        isnothing(chunk.json) && continue
        !haskey(chunk.json, :choices) && continue
        if isnothing(response)
            ## do it only once the first time when we have the json
            response = chunk.json |> copy
        end
        if isnothing(usage)
            usage_values = get(chunk.json, :usage, nothing)
            if !isnothing(usage_values)
                usage = usage_values |> copy
            end
        end
        for choice in chunk.json.choices
            index = get(choice, :index, nothing)
            isnothing(index) && continue
            if !haskey(choices_output, index)
                choices_output[index] = Dict{Symbol, Any}(:index => index)
            end
            index_dict = choices_output[index]
            finish_reason = get(choice, :finish_reason, nothing)
            if !isnothing(finish_reason)
                index_dict[:finish_reason] = finish_reason
            end
            ## skip for now
            # logprobs = get(choice, :logprobs, nothing)
            # if !isnothing(logprobs)
            #     choices_dict[index][:logprobs] = logprobs
            # end
            choice_delta = get(choice, :delta, Dict{Symbol, Any}())
            message_dict = get(index_dict, :message, Dict{Symbol, Any}(:content => ""))
            role = get(choice_delta, :role, nothing)
            if !isnothing(role)
                message_dict[:role] = role
            end
            content = get(choice_delta, :content, nothing)
            if !isnothing(content)
                message_dict[:content] *= content
            end
            ## skip for now
            # refusal = get(choice_delta, :refusal, nothing)
            # if !isnothing(refusal)
            #     message_dict[:refusal] = refusal
            # end
            index_dict[:message] = message_dict
        end
    end
    ## We know we have at least one chunk, let's use it for final response
    if !isnothing(response)
        # flatten the choices_dict into an array
        choices = [choices_output[index] for index in sort(collect(keys(choices_output)))]
        # overwrite the old choices
        response[:choices] = choices
        response[:object] = "chat.completion"
        response[:usage] = usage
    end
    return response
end

"""
    streamed_request!(cb::AbstractStreamCallback, url, headers, input; kwargs...)

End-to-end wrapper for streaming requests. 
In-place modification of the callback object (`cb.chunks`) with the results of the request being returned.
We build the `body` of the response object in the end and write it into the `resp.body`.

Returns the response object.
"""
function streamed_request!(cb::AbstractStreamCallback, url, headers, input; kwargs...)
    verbose = get(kwargs, :verbose, false) || get(cb.kwargs, :verbose, false)
    resp = HTTP.open("POST", url, headers; kwargs...) do stream
        write(stream, String(take!(input)))
        HTTP.closewrite(stream)
        r = HTTP.startread(stream)
        isdone = false
        ## messages might be incomplete, so we need to keep track of the spillover
        spillover = ""
        while !eof(stream) || !isdone
            masterchunk = String(readavailable(stream))
            chunks, spillover = extract_chunks(
                cb.flavor, masterchunk; spillover, cb.kwargs...)

            for chunk in chunks
                verbose && @info "Chunk Data: $(chunk.data)"
                ## look for errors
                handle_error_message(chunk; cb.kwargs...)
                ## look for termination signal, but process all remaining chunks first
                is_done(cb.flavor, chunk; cb.kwargs...) && (isdone = true)
                ## trigger callback
                callback(cb, chunk; cb.kwargs...)
                ## Write into our CB chunks (for later processing)
                push!(cb.chunks, chunk)
            end
        end
        HTTP.closeread(stream)
    end

    body = build_response_body(cb.flavor, cb; cb.kwargs...)
    resp.body = JSON3.write(body)

    return resp
end

### Additional methods required for AnthropicStream
"""
    build_response_body(flavor::AnthropicStream, cb::StreamCallback; kwargs...)

Build the response body from the chunks to mimic receiving a standard response from the API.
"""
function build_response_body(
        flavor::AnthropicStream, cb::StreamCallback; verbose::Bool = false, kwargs...)
    isempty(cb.chunks) && return nothing
    response = nothing
    usage = nothing
    content_buf = IOBuffer()
    for i in eachindex(cb.chunks)
        ## Note we ignore the index ID, because Anthropic does not support multiple
        ## parallel generations
        chunk = cb.chunks[i]
        ## validate that we can access choices
        isnothing(chunk.json) && continue
        ## Core of the message body
        if isnothing(response) && chunk.event == :message_start &&
           haskey(chunk.json, :message)
            ## do it only once the first time when we have the json
            response = chunk.json[:message] |> copy
            usage = get(response, :usage, Dict())
        end
        ## Update stop reason and usage
        if chunk.event == :message_delta && haskey(chunk.json, :content_block)
            response = merge(response, get(chunk.json, :delta, Dict()))
            usage = merge(usage, get(chunk.json, :usage, Dict()))
        end

        ## Load text chunks
        if chunk.event == :content_block_start ||
           chunk.event == :content_block_delta || chunk.event == :content_block_stop
            ## Find the text delta
            delta_block = get(chunk.json, :content_block, nothing)
            if isnothing(delta_block)
                ## look for the delta segment
                delta_block = get(chunk.json, :delta, Dict())
            end
            text = get(delta_block, :text, nothing)
            !isnothing(text) && write(content_buf, text)
        end
    end
    ## We know we have at least one chunk, let's use it for final response
    if !isnothing(response)
        response[:content] = [Dict(:type => "text", :text => String(take!(content_buf)))]
        isnothing(usage) && (response[:usage] = usage)
    end
    @info "Response: $(response)"
    return response
end
"""
    extract_content(flavor::AnthropicStream, chunk)

Extract the content from the chunk.
"""
function extract_content(flavor::AnthropicStream, chunk::StreamChunk; kwargs...)
    if !isnothing(chunk.json)
        ## Can contain more than one choice for multi-sampling, but ignore for callback
        ## Get only the first choice, index=0
        index = get(chunk.json, :index, nothing)
        isnothing(index) || !iszero(index) && return nothing

        delta_block = get(chunk.json, :content_block, nothing)
        if isnothing(delta_block)
            ## look for the delta segment
            delta_block = get(chunk.json, :delta, Dict())
        end
        out = get(delta_block, :text, nothing)
    else
        nothing
    end
end