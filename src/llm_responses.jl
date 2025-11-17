
"""
    create_response(schema::AbstractResponseSchema, api_key::AbstractString,
                   model::AbstractString,
                   input;
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
    for (key, value) in api_kwargs
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
    render_responses(prompt; kwargs...) -> (input, instructions)

Process different prompt types for the OpenAI Responses API and replace any placeholders
with values from kwargs. The function has specialized methods for each supported prompt type.

# Arguments
- `prompt`: The prompt to process (String, Vector{<:AbstractMessage}, AITemplate, or Symbol)
- `kwargs...`: Key-value pairs to replace placeholders in the prompt, e.g., {{key}} -> value

# Returns
- `input`: The input string for the API, with replacements
- `instructions`: Optional instructions for the API, or nothing, with replacements
"""
function render_responses end

"""
    render_responses(prompt::AbstractString; kwargs...) -> (input, instructions)

Process a string prompt for the OpenAI Responses API.
"""
function render_responses(prompt::AbstractString; kwargs...)
    input = replace_placeholders(prompt, kwargs)
    return input, nothing
end

"""
    render_responses(prompt::Vector{<:AbstractMessage}; kwargs...) -> (input, instructions)

Process a vector of messages for the OpenAI Responses API.
"""
function render_responses(prompt::Vector{<:AbstractMessage}; kwargs...)
    @assert length(prompt)<=2 "Can only process at most 2 messages (SystemMessage and UserMessage)"

    user_msg = nothing
    system_msg = nothing

    for msg in prompt
        if msg isa UserMessage
            user_msg = msg
        elseif msg isa SystemMessage
            system_msg = msg
        end
    end

    @assert !isnothing(user_msg) "A UserMessage is required in the message vector"

    input = replace_placeholders(user_msg.content, kwargs)
    instructions = isnothing(system_msg) ? nothing :
                   replace_placeholders(system_msg.content, kwargs)

    return input, instructions
end

function render_responses(msg::AbstractMessage; kwargs...)
    render_responses([msg]; kwargs...)
end

"""
    render_responses(template::AITemplate; kwargs...) -> (input, instructions)

Render an AITemplate into input and instructions for the OpenAI Responses API.
"""
function render_responses(template::AITemplate; kwargs...)
    messages = render(template; kwargs...)
    return render_responses(messages)
end

"""
    render_responses(template_name::Symbol; kwargs...) -> (input, instructions)

Render a template by its symbol name into input and instructions for the OpenAI Responses API.
"""
function render_responses(template_name::Symbol; kwargs...)
    return render_responses(AITemplate(template_name); kwargs...)
end

"""
    replace_placeholders(text::AbstractString, kwargs) -> String

Replace placeholders of form {{key}} in the input text with values from kwargs.

# Arguments
- `text`: The input text containing placeholders
- `kwargs`: Key-value pairs to replace placeholders in the text

# Returns
- String with placeholders replaced with values
"""
function replace_placeholders(text::AbstractString, kwargs)
    replaced_text = text
    for (key, value) in kwargs
        placeholder = "{{" * string(key) * "}}"
        replaced_text = replace(replaced_text, placeholder => string(value))
    end
    return replaced_text
end

"""
    airespond(schema::AbstractResponseSchema, prompt; kwargs...)

Generate a response using the OpenAI Responses API with streaming support.
Returns an AIMessage with the response content and additional information in the extras field.

# Arguments
- `prompt`: The prompt to send to the API, can be a string or a vector of AbstractMessages
  - If a string, it will be sent as the input
  - If a vector of AbstractMessages, must contain at most 2 messages:
    - SystemMessage will be passed via the instructions field
    - UserMessage will be sent as input (required)
- `previous_response_id=nothing`: ID of a previous response to continue the conversation
- `enable_websearch=false`: Whether to enable web search capabilities
- `model="gpt-5.1-codex"`: The model to use
- `verbose=true`: Whether to print verbose information
- `streamcallback=nothing`: Callback function for streaming responses
- `api_key`: The API key for OpenAI (defaults to ENV["OPENAI_API_KEY"])

# Returns
- `AIMessage`: The response from the API with extras containing response_id and other metadata

# Example
```julia
schema = OpenAIResponseSchema()

# Basic usage
response = airespond(schema, "What is Julia?"; model="gpt-5.1-codex")

# With streaming
response = airespond(schema, "Count to 10"; model="gpt-5.1-codex", streamcallback=stdout)

# With web search
response = airespond(schema, "Latest news about AI"; model="gpt-5.1-codex", enable_websearch=true)

# Reasoning traces are automatically included when available
response = airespond(schema, "Solve this math problem: 2+2*3"; model="gpt-5.1-codex")
```
"""
function airespond(schema::AbstractResponseSchema, prompt::ALLOWED_PROMPT_TYPE;
        previous_response_id::Union{Nothing, AbstractString} = nothing,
        enable_websearch::Bool = false,
        model::AbstractString = MODEL_CHAT,
        verbose::Bool = true,
        api_key::AbstractString = get(ENV, "OPENAI_API_KEY", ""),
        streamcallback::Any = nothing,
        kwargs...)

    start_time = time()

    # Process the prompt to get input and instructions
    input, instructions = render_responses(prompt; kwargs...)

    # Prepare tools if web search is enabled
    tools = []
    if enable_websearch
        push!(tools, Dict("type" => "web_search_preview"))
    end

    # Call the OpenAI Responses API
    api_kwargs = get(kwargs, :api_kwargs, NamedTuple())
    response = create_response(
        schema,
        api_key,
        model,
        input;
        previous_response_id = previous_response_id,
        tools = tools,
        streamcallback = streamcallback,
        http_kwargs = (retry_non_idempotent = true, retries = 3, readtimeout = 120),
        instructions = instructions,
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

# Support for template rendering with AbstractResponseSchema
function airespond(schema::AbstractResponseSchema, template::AITemplate; kwargs...)
    airespond(schema, render(template); kwargs...)
end

function airespond(schema::AbstractResponseSchema, template::Symbol; kwargs...)
    airespond(schema, AITemplate(template); kwargs...)
end

"""
    aigenerate(schema::AbstractResponseSchema, prompt::ALLOWED_PROMPT_TYPE; kwargs...)

Generate an AI response using the OpenAI Responses API. This is a wrapper around `airespond` 
to provide compatibility with the standard `aigenerate` interface.

See `?airespond` for detailed documentation of arguments and usage.
"""
function aigenerate(schema::AbstractResponseSchema, prompt::ALLOWED_PROMPT_TYPE; kwargs...)
    return airespond(schema, prompt; kwargs...)
end