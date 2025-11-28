# OpenAI Responses API implementation
#
# This file implements support for OpenAI's `/responses` endpoint, which is used by
# models like gpt-5.1-codex that don't support the standard chat completions API.

# Test implementation for create_response - echoes back configured response
function create_response(schema::TestEchoOpenAIResponseSchema, api_key::AbstractString,
        model::AbstractString,
        input;
        instructions::Union{Nothing, AbstractString} = nothing,
        kwargs...)
    schema.model_id = model
    schema.inputs = (; input, instructions, kwargs...)
    return OpenAI.OpenAIResponse(Int16(schema.status), schema.response)
end

"""
    create_response(schema::AbstractOpenAIResponseSchema, api_key::AbstractString,
                   model::AbstractString,
                   input;
                   instructions::Union{Nothing, AbstractString} = nothing,
                   previous_response_id::Union{Nothing, AbstractString} = nothing,
                   http_kwargs::NamedTuple = NamedTuple(),
                   streamcallback::Any = nothing,
                   tools::Vector{<:Any} = [],
                   api_kwargs::NamedTuple = NamedTuple(),
                   kwargs...)

Creates a response using the OpenAI Responses API with streaming support.

# Arguments
- `schema::AbstractOpenAIResponseSchema`: The response schema to use
- `api_key::AbstractString`: The API key to use for the OpenAI API
- `model::AbstractString`: The model to use for generating the response
- `input`: The input for the model, can be a string or structured input
- `instructions::Union{Nothing, AbstractString}`: System instructions for the model
- `previous_response_id::Union{Nothing, AbstractString}`: The ID of a previous response to continue the conversation
- `http_kwargs::NamedTuple`: Additional keyword arguments for the HTTP request
- `streamcallback::Any`: Callback function for streaming responses
- `tools::Vector{<:Any}`: Tools for the model to use
- `api_kwargs::NamedTuple`: Additional API-specific keyword arguments:
  - `reasoning`: Dict controlling reasoning (e.g., `Dict("effort" => "low")` or `Dict("summary" => "detailed")`)
  - `text`: Dict controlling text output (e.g., `Dict("format" => Dict("type" => "json_schema", ...))`)
- `kwargs...`: Additional keyword arguments for the API call

# Returns
- `response`: The response from the OpenAI API
"""
function create_response(schema::AbstractOpenAIResponseSchema, api_key::AbstractString,
        model::AbstractString,
        input;
        instructions::Union{Nothing, AbstractString} = nothing,
        previous_response_id::Union{Nothing, AbstractString} = nothing,
        http_kwargs::NamedTuple = NamedTuple(),
        streamcallback::Any = nothing,
        tools::Vector{<:Any} = [],
        api_kwargs::NamedTuple = NamedTuple(),
        kwargs...)
    # Build the request body
    body = Dict{String, Any}(
        "model" => model,
        "input" => input
    )

    # Add optional parameters
    !isnothing(instructions) && (body["instructions"] = instructions)
    !isnothing(previous_response_id) &&
        (body["previous_response_id"] = previous_response_id)
    !isempty(tools) && (body["tools"] = tools)

    # Add streaming if callback provided
    if !isnothing(streamcallback)
        body["stream"] = true
    end

    # Add all parameters from api_kwargs (except url which is used for testing)
    # Supports: reasoning, text, temperature, max_output_tokens, etc.
    for (key, value) in pairs(api_kwargs)
        key == :url && continue  # url is used for testing, not sent to API
        body[string(key)] = value
    end

    # Make the API request (url can be overridden via api_kwargs for testing)
    url = get(api_kwargs, :url, OpenAI.build_url(OpenAI.DEFAULT_PROVIDER, "responses"))
    headers = OpenAI.auth_header(OpenAI.DEFAULT_PROVIDER, api_key)

    if !isnothing(streamcallback)
        # Configure streaming callback
        streamcallback, stream_kwargs = configure_callback!(streamcallback, schema)

        # Convert body dict to IOBuffer for streaming (streamed_request! expects IOBuffer)
        input = IOBuffer()
        JSON3.write(input, body)
        seekstart(input)

        # Use streaming request
        resp = streamed_request!(streamcallback, url, headers, input; http_kwargs...)

        # Build response body from chunks using StreamCallbacks
        response_body = build_response_body(streamcallback.flavor, streamcallback)
        return OpenAI.OpenAIResponse(resp.status, response_body)
    else
        # Convert the body to JSON for non-streaming
        json_body = JSON3.write(body)

        # Make the request
        r = HTTP.request("POST", url, headers, json_body; http_kwargs...)
        return OpenAI.OpenAIResponse(r.status, JSON3.read(r.body))
    end
end

"""
    render(schema::AbstractOpenAIResponseSchema, messages::Vector{<:AbstractMessage};
           conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
           no_system_message::Bool = false,
           kwargs...)

Render messages for the OpenAI Responses API. Returns a NamedTuple with `input` and `instructions`
fields suitable for the `/responses` endpoint.

The Responses API expects:
- `input`: The user's input/question (from UserMessage)
- `instructions`: System-level instructions (from SystemMessage, optional)

# Arguments
- `schema::AbstractOpenAIResponseSchema`: The response schema
- `messages::Vector{<:AbstractMessage}`: Messages to render
- `conversation`: Previous conversation history (currently limited support)
- `no_system_message`: If true, don't add default system message
- `kwargs...`: Placeholder replacements for templates

# Returns
- `NamedTuple{(:input, :instructions), Tuple{String, Union{Nothing, String}}}`: Rendered input and instructions
"""
function render(schema::AbstractOpenAIResponseSchema,
        messages::Vector{<:AbstractMessage};
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        no_system_message::Bool = false,
        kwargs...)
    # First, use NoSchema to process placeholders and organize messages
    processed = render(NoSchema(), messages; conversation, no_system_message, kwargs...)

    # Extract system message (instructions) and user message (input)
    system_msg = nothing
    user_msg = nothing

    for msg in processed
        if issystemmessage(msg)
            system_msg = msg
        elseif isusermessage(msg)
            user_msg = msg
        end
    end

    # Responses API requires at least user input
    if isnothing(user_msg)
        throw(ArgumentError("A UserMessage is required for the Responses API"))
    end

    input = user_msg.content
    instructions = isnothing(system_msg) ? nothing : system_msg.content

    return (; input, instructions)
end

# Render for string prompts - wrap in UserMessage and process
function render(schema::AbstractOpenAIResponseSchema, prompt::AbstractString;
        no_system_message::Bool = true, kwargs...)
    render(schema, [UserMessage(prompt)]; no_system_message, kwargs...)
end

# Render for single message
function render(schema::AbstractOpenAIResponseSchema, msg::AbstractMessage; kwargs...)
    render(schema, [msg]; kwargs...)
end

# Render for AITemplate
function render(schema::AbstractOpenAIResponseSchema, template::AITemplate; kwargs...)
    render(schema, render(template); kwargs...)
end

# Render for Symbol (template name)
function render(schema::AbstractOpenAIResponseSchema, template::Symbol; kwargs...)
    render(schema, AITemplate(template); kwargs...)
end

"""
    extract_response_content(response) -> (content, reasoning_content)

Extract text content and reasoning content from an OpenAI Responses API response.

Returns a tuple of (main_content::String, reasoning_content::Vector{String})
"""
function extract_response_content(response)
    content = ""
    reasoning_content = String[]

    if haskey(response, :output)
        for item in response[:output]
            item_type = get(item, :type, "")

            if item_type == "message"
                # Extract main message content
                for msg_content in get(item, :content, [])
                    if get(msg_content, :type, "") == "output_text"
                        content *= get(msg_content, :text, "") * "\n"
                    end
                end
            elseif item_type == "reasoning"
                # Extract reasoning summary from the summary array
                # OpenAI format: {"type": "reasoning", "summary": [{"type": "summary_text", "text": "..."}]}
                for summary_item in get(item, :summary, [])
                    text = get(summary_item, :text, "")
                    if !isempty(text)
                        push!(reasoning_content, text)
                    end
                end
            end
        end
        content = rstrip(content)
    end

    return content, reasoning_content
end

"""
    aigenerate(schema::AbstractOpenAIResponseSchema, prompt::ALLOWED_PROMPT_TYPE;
               previous_response_id::Union{Nothing, AbstractString} = nothing,
               enable_websearch::Bool = false,
               model::AbstractString = MODEL_CHAT,
               verbose::Bool = true,
               api_key::AbstractString = "",
               streamcallback::Any = nothing,
               kwargs...)

Generate an AI response using the OpenAI Responses API with streaming support.
Returns an AIMessage with the response content and additional information in the extras field.

# Arguments
- `schema::AbstractOpenAIResponseSchema`: The schema to use (e.g., `OpenAIResponseSchema()`)
- `prompt`: The prompt to send to the API, can be:
  - A string (sent as user input)
  - A vector of AbstractMessages (SystemMessage becomes instructions, UserMessage becomes input)
  - An AITemplate or Symbol for template-based prompts
- `previous_response_id=nothing`: ID of a previous response to continue the conversation
- `enable_websearch=false`: Whether to enable web search capabilities
- `model`: The model to use (defaults to MODEL_CHAT)
- `verbose=true`: Whether to print verbose information
- `api_key`: The API key for OpenAI (defaults to `""`, falls back to ENV["OPENAI_API_KEY"])
- `streamcallback=nothing`: Callback function for streaming responses
- `api_kwargs`: Additional API-specific keyword arguments:
  - `reasoning`: Control reasoning effort/verbosity, e.g., `Dict("effort" => "low")` or `Dict("summary" => "auto")`
    - `effort`: "low", "medium", or "high" - controls how much reasoning effort the model applies
    - `summary`: "auto", "concise", or "detailed" - controls verbosity of reasoning summary in response
  - `text`: Control text output format

# Returns
- `AIMessage`: The response from the API with extras containing:
  - `response_id`: The response ID for continuing conversations
  - `reasoning`: Full reasoning object from API
  - `reasoning_content`: Extracted reasoning summary text (Vector{String})
  - `usage`: Token usage information
  - `full_response`: The complete API response

# Notes
- Reasoning content is only available for models that support reasoning (e.g., o1, o3, o4-mini, gpt-5)
- By default, reasoning traces are encrypted and hidden from the client for safety
- The `reasoning_content` field contains the summary text, not the full reasoning trace
- Use `reasoning = Dict("summary" => "auto")` or `"detailed"` to get more verbose summaries

# Example
```julia
schema = OpenAIResponseSchema()

# Basic usage (no reasoning by default)
response = aigenerate(schema, "What is Julia?"; model="gpt-4o-mini")

# With reasoning enabled (for reasoning models like o1, o3)
response = aigenerate(schema, "Solve 2+2*3";
    model="o3-mini",
    api_kwargs = (reasoning = Dict("effort" => "medium", "summary" => "auto"),))

# Access reasoning summary
println(response.extras[:reasoning_content])
```
"""
function aigenerate(schema::AbstractOpenAIResponseSchema, prompt::ALLOWED_PROMPT_TYPE;
        previous_response_id::Union{Nothing, AbstractString} = nothing,
        enable_websearch::Bool = false,
        model::AbstractString = MODEL_CHAT,
        verbose::Bool = true,
        api_key::AbstractString = "",
        streamcallback::Any = nothing,
        no_system_message::Bool = false,
        kwargs...)
    # Resolve API key - use provided key or fall back to environment variable
    api_key = isempty(api_key) ? get(ENV, "OPENAI_API_KEY", "") : api_key

    start_time = time()

    # Process the prompt to get input and instructions using unified render
    rendered = render(schema, prompt; no_system_message, kwargs...)

    # Prepare tools if web search is enabled
    tools = Any[]
    if enable_websearch
        push!(tools, Dict("type" => "web_search_preview"))
    end

    # Call the OpenAI Responses API
    api_kwargs = get(kwargs, :api_kwargs, NamedTuple())
    response = create_response(
        schema,
        api_key,
        model,
        rendered.input;
        instructions = rendered.instructions,
        previous_response_id = previous_response_id,
        tools = tools,
        streamcallback = streamcallback,
        http_kwargs = (retry_non_idempotent = true, retries = 3, readtimeout = 120),
        api_kwargs = api_kwargs
    )

    elapsed = time() - start_time

    # Extract content and reasoning
    content, reasoning_content = extract_response_content(response.response)
    if isempty(content)
        content = "No output content found in response"
    end

    # Extract usage information
    usage_data = get(response.response, :usage, Dict())
    input_tokens = get(usage_data, :input_tokens, -1)
    output_tokens = get(usage_data, :output_tokens, -1)

    # Create extras dictionary with reasoning content
    extras = Dict{Symbol, Any}(
        :response_id => get(response.response, :id, ""),
        :reasoning => get(response.response, :reasoning, Dict()),
        :reasoning_content => reasoning_content,
        :usage => usage_data,
        :full_response => response.response
    )

    finish_reason = get(response.response, :status, nothing)
    cost = call_cost(input_tokens, output_tokens, model)

    result = AIMessage(;
        content = content,
        status = Int(response.status),
        tokens = (input_tokens, output_tokens),
        elapsed = elapsed,
        extras = extras,
        name = nothing,
        cost = cost,
        log_prob = nothing,
        finish_reason = finish_reason,
        run_id = Int(rand(Int32)),
        sample_id = nothing
    )

    verbose && @info _report_stats(result, model)
    return result
end

"""
    aiextract(schema::AbstractOpenAIResponseSchema, prompt::ALLOWED_PROMPT_TYPE;
              return_type::Union{Type, AbstractTool},
              model::AbstractString = MODEL_CHAT,
              api_key::AbstractString = "",
              verbose::Bool = true,
              strict::Union{Nothing, Bool} = true,
              kwargs...)

Extract structured data from text using the OpenAI Responses API with JSON schema output.

Uses the existing `tool_call_signature` and `parse_tool` utilities for schema generation and parsing.

Note: Unlike the Chat Completions API, the Responses API `text.format` only supports a single
JSON schema. For multi-type extraction (union of structs), use the Chat Completions API instead.

# Arguments
- `schema::AbstractOpenAIResponseSchema`: The schema to use
- `prompt`: The input prompt
- `return_type`: A Julia struct type or AbstractTool to extract (single type only)
- `model`: The model to use
- `api_key`: OpenAI API key
- `verbose`: Print stats
- `strict`: Whether to enforce strict JSON schema mode (default: true)
- `api_kwargs`: Additional API kwargs (e.g., `reasoning` for reasoning traces)

# Returns
- `DataMessage`: Contains the extracted data in the `content` field, with extras containing reasoning

# Example
```julia
using PromptingTools

# Define the structure to extract
struct CalendarEvent
    name::String
    date::String
    participants::Vector{String}
end

schema = OpenAIResponseSchema()
result = aiextract(schema, "Alice and Bob are going to a science fair on Friday.";
    return_type=CalendarEvent,
    model="gpt-4o")

# Access extracted data
event = result.content
println(event.name)          # "Science Fair"
println(event.participants)  # ["Alice", "Bob"]

# With reasoning enabled
result = aiextract(schema, "Solve: What is 15% of 80?";
    return_type=MathAnswer,
    model="gpt-4o",
    api_kwargs=(reasoning=Dict("effort"=>"high"),))
println(result.extras[:reasoning_content])
```
"""
function aiextract(schema::AbstractOpenAIResponseSchema, prompt::ALLOWED_PROMPT_TYPE;
        return_type::Union{Type, AbstractTool},
        model::AbstractString = MODEL_CHAT,
        api_key::AbstractString = "",
        verbose::Bool = true,
        strict::Union{Nothing, Bool} = true,
        no_system_message::Bool = false,
        kwargs...)
    # Resolve API key
    api_key = isempty(api_key) ? get(ENV, "OPENAI_API_KEY", "") : api_key

    start_time = time()

    # Process the prompt
    rendered = render(schema, prompt; no_system_message, kwargs...)

    # Use existing tool_call_signature utility to generate JSON schema
    # Note: Responses API text.format only supports a single schema, unlike Chat Completions tools
    tool_map = tool_call_signature(return_type; strict = strict)
    if length(tool_map) != 1
        throw(ArgumentError("Responses API aiextract only supports a single return_type. " *
                            "Got $(length(tool_map)) types. Use Chat Completions API for multi-type extraction."))
    end
    name, tool = only(tool_map)

    # Configure text output format for structured extraction
    # Responses API uses text.format instead of tools
    api_kwargs = get(kwargs, :api_kwargs, NamedTuple())

    # Build text format, preserving user's text settings (e.g., verbosity) but overriding format
    user_text = get(api_kwargs, :text, Dict())
    text_format = if user_text isa Dict
        # Merge user settings with our format (our format takes precedence)
        merge(user_text,
            Dict(
                "format" => Dict(
                "type" => "json_schema",
                "name" => tool.name,
                "schema" => tool.parameters,
                "strict" => something(tool.strict, true)
            )
            ))
    else
        Dict(
            "format" => Dict(
            "type" => "json_schema",
            "name" => tool.name,
            "schema" => tool.parameters,
            "strict" => something(tool.strict, true)
        )
        )
    end

    # Merge with existing api_kwargs, replacing text with our merged version
    merged_kwargs = (;
        [k => v for (k, v) in pairs(api_kwargs) if k != :text]..., text = text_format)

    # Call the API
    response = create_response(
        schema,
        api_key,
        model,
        rendered.input;
        instructions = rendered.instructions,
        http_kwargs = (retry_non_idempotent = true, retries = 3, readtimeout = 120),
        api_kwargs = merged_kwargs
    )

    elapsed = time() - start_time

    # Extract content and reasoning
    content_str, reasoning_content = extract_response_content(response.response)

    # Parse the JSON response using existing parse_tool utility
    parsed_content = parse_tool(tool, content_str)

    # Extract usage
    usage_data = get(response.response, :usage, Dict())
    input_tokens = get(usage_data, :input_tokens, -1)
    output_tokens = get(usage_data, :output_tokens, -1)

    # Create extras with reasoning content
    extras = Dict{Symbol, Any}(
        :response_id => get(response.response, :id, ""),
        :reasoning => get(response.response, :reasoning, Dict()),
        :reasoning_content => reasoning_content,
        :raw_content => content_str,
        :usage => usage_data,
        :full_response => response.response
    )

    cost = call_cost(input_tokens, output_tokens, model)

    result = DataMessage(;
        content = parsed_content,
        status = Int(response.status),
        tokens = (input_tokens, output_tokens),
        elapsed = elapsed,
        extras = extras,
        cost = cost,
        run_id = Int(rand(Int32)),
        sample_id = nothing
    )

    verbose && @info _report_stats(result, model)
    return result
end
