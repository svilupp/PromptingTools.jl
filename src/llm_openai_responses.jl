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
    create_response(schema::AbstractResponseSchema, api_key::AbstractString,
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
- `schema::AbstractResponseSchema`: The response schema to use
- `api_key::AbstractString`: The API key to use for the OpenAI API
- `model::AbstractString`: The model to use for generating the response
- `input`: The input for the model, can be a string or structured input
- `instructions::Union{Nothing, AbstractString}`: System instructions for the model
- `previous_response_id::Union{Nothing, AbstractString}`: The ID of a previous response to continue the conversation
- `http_kwargs::NamedTuple`: Additional keyword arguments for the HTTP request
- `streamcallback::Any`: Callback function for streaming responses
- `tools::Vector{<:Any}`: Tools for the model to use
- `api_kwargs::NamedTuple`: Additional API-specific keyword arguments (e.g., reasoning)
- `kwargs...`: Additional keyword arguments for the API call

# Returns
- `response`: The response from the OpenAI API
"""
function create_response(schema::AbstractResponseSchema, api_key::AbstractString,
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

    # Add reasoning configuration from api_kwargs, default to detailed summary
    # Valid summary values: "detailed", "concise", "none"
    if haskey(api_kwargs, :reasoning)
        body["reasoning"] = api_kwargs.reasoning
    else
        body["reasoning"] = Dict("summary" => "detailed")
    end

    # Add any other parameters from api_kwargs only
    for (key, value) in pairs(api_kwargs)
        if key != :reasoning  # already handled above
            body[string(key)] = value
        end
    end

    # Make the API request
    url = OpenAI.build_url(OpenAI.DEFAULT_PROVIDER, "responses")
    headers = OpenAI.auth_header(OpenAI.DEFAULT_PROVIDER, api_key)

    if !isnothing(streamcallback)
        # Configure streaming callback - only pass schema, no extra kwargs
        streamcallback, stream_kwargs = configure_callback!(streamcallback, schema)

        # Use streaming request
        resp = streamed_request!(streamcallback, url, headers, body; http_kwargs...)
        return OpenAI.OpenAIResponse(resp.status, JSON3.read(resp.body))
    else
        # Convert the body to JSON for non-streaming
        json_body = JSON3.write(body)

        # Make the request
        r = HTTP.request("POST", url, headers, json_body; http_kwargs...)
        return OpenAI.OpenAIResponse(r.status, JSON3.read(r.body))
    end
end

"""
    render(schema::AbstractResponseSchema, messages::Vector{<:AbstractMessage};
           conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
           kwargs...)

Render messages for the OpenAI Responses API. Returns a NamedTuple with `input` and `instructions`
fields suitable for the `/responses` endpoint.

The Responses API expects:
- `input`: The user's input/question (from UserMessage)
- `instructions`: System-level instructions (from SystemMessage, optional)

# Arguments
- `schema::AbstractResponseSchema`: The response schema
- `messages::Vector{<:AbstractMessage}`: Messages to render
- `conversation`: Previous conversation history (currently limited support)
- `kwargs...`: Placeholder replacements for templates

# Returns
- `NamedTuple{(:input, :instructions), Tuple{String, Union{Nothing, String}}}`: Rendered input and instructions
"""
function render(schema::AbstractResponseSchema,
        messages::Vector{<:AbstractMessage};
        conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
        kwargs...)
    # First, use NoSchema to process placeholders and organize messages
    processed = render(NoSchema(), messages; conversation, kwargs...)

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
function render(schema::AbstractResponseSchema, prompt::AbstractString; kwargs...)
    render(schema, [UserMessage(prompt)]; kwargs...)
end

# Render for single message
function render(schema::AbstractResponseSchema, msg::AbstractMessage; kwargs...)
    render(schema, [msg]; kwargs...)
end

# Render for AITemplate
function render(schema::AbstractResponseSchema, template::AITemplate; kwargs...)
    render(schema, render(template); kwargs...)
end

# Render for Symbol (template name)
function render(schema::AbstractResponseSchema, template::Symbol; kwargs...)
    render(schema, AITemplate(template); kwargs...)
end

"""
    aigenerate(schema::AbstractResponseSchema, prompt::ALLOWED_PROMPT_TYPE;
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
- `schema::AbstractResponseSchema`: The schema to use (e.g., `OpenAIResponseSchema()`)
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
- `api_kwargs`: Additional API-specific keyword arguments (e.g., `reasoning = Dict("summary" => "concise")`)

# Returns
- `AIMessage`: The response from the API with extras containing:
  - `response_id`: The response ID for continuing conversations
  - `reasoning`: Reasoning traces (if available)
  - `usage`: Token usage information
  - `full_response`: The complete API response

# Example
```julia
schema = OpenAIResponseSchema()

# Basic usage
response = aigenerate(schema, "What is Julia?"; model="gpt-5.1-codex")

# With streaming
response = aigenerate(schema, "Count to 10"; model="gpt-5.1-codex", streamcallback=stdout)

# With web search
response = aigenerate(schema, "Latest news about AI"; model="gpt-5.1-codex", enable_websearch=true)

# Custom reasoning configuration
response = aigenerate(schema, "Solve 2+2*3";
    model="gpt-5.1-codex",
    api_kwargs = (reasoning = Dict("summary" => "concise"),))

# Using templates
response = aigenerate(schema, :BlankSystemUser;
    system="You are a helpful assistant",
    user="Hello!",
    model="gpt-5.1-codex")
```
"""
function aigenerate(schema::AbstractResponseSchema, prompt::ALLOWED_PROMPT_TYPE;
        previous_response_id::Union{Nothing, AbstractString} = nothing,
        enable_websearch::Bool = false,
        model::AbstractString = MODEL_CHAT,
        verbose::Bool = true,
        api_key::AbstractString = "",
        streamcallback::Any = nothing,
        kwargs...)
    # Resolve API key - use provided key or fall back to environment variable
    api_key = isempty(api_key) ? get(ENV, "OPENAI_API_KEY", "") : api_key

    start_time = time()

    # Process the prompt to get input and instructions using unified render
    rendered = render(schema, prompt; kwargs...)

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

    # Extract the text content from the response
    content = ""
    if haskey(response.response, :output)
        for item in response.response[:output]
            if item[:type] == "message"
                for msg_content in item[:content]
                    if msg_content[:type] == "output_text"
                        content *= msg_content[:text] * "\n"
                    end
                end
            end
        end
        content = rstrip(content)
    else
        content = "No output content found in response"
    end

    # Extract usage information
    usage_data = get(response.response, :usage, Dict())
    input_tokens = get(usage_data, :input_tokens, -1)
    output_tokens = get(usage_data, :output_tokens, -1)

    # Create extras dictionary
    extras = Dict{Symbol, Any}(
        :response_id => get(response.response, :id, ""),
        :reasoning => get(response.response, :reasoning, Dict()),
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
