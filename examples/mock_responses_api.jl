using PromptingTools
const PT = PromptingTools
using PromptingTools: OpenAISchema, MODEL_REGISTRY, MODEL_CHAT, PROMPT_SCHEMA,
                      AbstractMessage, SystemMessage, UserMessage, ALLOWED_PROMPT_TYPE,
                      AITemplate, AbstractPromptSchema, render
using HTTP
using JSON3
using OpenAI

# This example demonstrates the use of the OpenAI Responses API
# with a simplified implementation that returns standard AIMessage objects

"""
    create_response(schema::OpenAISchema, api_key::AbstractString,
                   model::AbstractString,
                   input;
                   previous_response_id::Union{Nothing, AbstractString} = nothing,
                   http_kwargs::NamedTuple = NamedTuple(),
                   tools::Vector{<:Any} = [],
                   reasoning::Union{Nothing, Dict{String, Any}} = nothing,
                   kwargs...)

Creates a response using the OpenAI Responses API.

# Arguments
- `api_key::AbstractString`: The API key to use for the OpenAI API.
- `model::AbstractString`: The model to use for generating the response.
- `input`: The input for the model, can be a string or a structured input.
- `previous_response_id::Union{Nothing, AbstractString}`: The ID of a previous response to continue the conversation.
- `http_kwargs::NamedTuple`: Additional keyword arguments for the HTTP request.
- `tools::Vector{<:Any}`: Tools for the model to use.
- `reasoning::Union{Nothing, Dict{String, Any}}`: Reasoning parameters for the model.
- `kwargs...`: Additional keyword arguments for the API call.

# Returns
- `response`: The response from the OpenAI API.
"""
function create_response(schema::OpenAISchema, api_key::AbstractString,
        model::AbstractString,
        input;
        previous_response_id::Union{Nothing, AbstractString} = nothing,
        http_kwargs::NamedTuple = NamedTuple(),
        tools::Vector{<:Any} = [],
        reasoning::Union{Nothing, Dict{String, Any}} = nothing,
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
    !isnothing(reasoning) && (body["reasoning"] = reasoning)

    # Add any other parameters from kwargs
    for (key, value) in kwargs
        body[string(key)] = value
    end

    # Make the API request
    url = OpenAI.build_url(OpenAI.DEFAULT_PROVIDER, "responses")
    headers = OpenAI.auth_header(OpenAI.DEFAULT_PROVIDER, api_key)

    # Convert the body to JSON
    json_body = JSON3.write(body)

    # Make the request
    r = HTTP.request("POST", url, headers, json_body; http_kwargs...)

    # Parse and return the response
    return OpenAI.OpenAIResponse(r.status, JSON3.read(r.body))
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

# Returns
- `input`: The input string with replacements
- `instructions`: Nothing (no system message in a string prompt)
"""
function render_responses(prompt::AbstractString; kwargs...)
    input = replace_placeholders(prompt, kwargs)
    return input, nothing
end

"""
    render_responses(prompt::Vector{<:AbstractMessage}; kwargs...) -> (input, instructions)

Process a vector of messages for the OpenAI Responses API.

# Returns
- `input`: The UserMessage content with replacements
- `instructions`: The SystemMessage content with replacements, or nothing
"""
function render_responses(prompt::Vector{<:AbstractMessage}; kwargs...)
    @assert length(prompt)<=2 "Can only process at most 2 messages (SystemMessage and UserMessage)"

    # Find UserMessage and SystemMessage in the vector
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

    # Replace placeholders in messages
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

# Returns
- `input`: The input string from the rendered template
- `instructions`: The instructions from the rendered template, or nothing
"""
function render_responses(template::AITemplate; kwargs...)
    # Render the template into messages using the default schema
    messages = render(template; kwargs...)

    # Process the messages to extract input and instructions
    # No need to pass kwargs again as replacements are already done in render
    return render_responses(messages)
end

"""
    render_responses(template_name::Symbol; kwargs...) -> (input, instructions)

Render a template by its symbol name into input and instructions for the OpenAI Responses API.

# Returns
- `input`: The input string from the rendered template
- `instructions`: The instructions from the rendered template, or nothing
"""
function render_responses(template_name::Symbol; kwargs...)
    return render_responses(AITemplate(template_name); kwargs...)
end

function airespond(schema::AbstractPromptSchema, template::AITemplate; kwargs...)
    airespond(schema, render(template); kwargs...)
end
## function airespond(schema::OpenAISchema, template::AITemplate; kwargs...)
##     airespond(schema, render(template); kwargs...)
## end
function airespond(schema::AbstractPromptSchema, template::Symbol; kwargs...)
    airespond(schema, AITemplate(template); kwargs...)
end
## function airespond(schema::OpenAISchema, template::Symbol; kwargs...)
##     airespond(schema, AITemplate(template); kwargs...)
## end

function airespond(prompt; model = MODEL_CHAT, kwargs...)
    global MODEL_REGISTRY
    # first look up the model schema in the model registry; otherwise, use the default schema PROMPT_SCHEMA
    schema = get(MODEL_REGISTRY, model, (; schema = PROMPT_SCHEMA)).schema
    airespond(schema, prompt; model, kwargs...)
end

"""
    airespond(schema::OpenAISchema, prompt; kwargs...)

Generate a response using the OpenAI Responses API.
Returns an AIMessage with the response content and additional information in the extras field.

# Arguments
- `prompt`: The prompt to send to the API, can be a string or a vector of AbstractMessages
  - If a string, it will be sent as the input
  - If a vector of AbstractMessages, must contain at most 2 messages:
    - SystemMessage will be passed via the instructions field
    - UserMessage will be sent as input (required)
- `previous_response_id=nothing`: ID of a previous response to continue the conversation
- `enable_websearch=false`: Whether to enable web search capabilities
- `model="gpt-4.1-mini"`: The model to use
- `verbose=true`: Whether to print verbose information

# Returns
- `AIMessage`: The response from the API with extras containing response_id and other metadata
"""
function airespond(schema::OpenAISchema, prompt::ALLOWED_PROMPT_TYPE;
        previous_response_id::Union{Nothing, AbstractString} = nothing,
        enable_websearch::Bool = false,
        model::AbstractString = MODEL_CHAT,
        verbose::Bool = true,
        api_key::AbstractString = get(ENV, "OPENAI_API_KEY", ""),
        kwargs...)

    # Start timing
    start_time = time()

    # Process the prompt to get input and instructions
    input, instructions = render_responses(prompt; kwargs...)

    # Prepare tools if web search is enabled
    tools = []
    if enable_websearch
        push!(tools, Dict(
            "type" => "web_search_preview"
        ))
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
        http_kwargs = (retry_non_idempotent = true, retries = 3, readtimeout = 120),
        instructions = instructions,
        api_kwargs...
    )

    # Calculate elapsed time
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

    # Create extras dictionary with all the additional information
    extras = Dict{Symbol, Any}(
        :response_id => get(response.response, :id, ""),
        :reasoning => get(response.response, :reasoning, Dict()),
        :usage => usage_data,
        :full_response => response.response
    )

    # Extract status from response if available
    finish_reason = get(response.response, :status, nothing)

    # Calculate cost based on tokens and model ID
    cost = PT.call_cost(input_tokens, output_tokens, model)

    # Create and return an AIMessage
    result = PT.AIMessage(;
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

    # Print stats if verbose
    if verbose
        @info "Response generated in $(round(elapsed, digits=2))s using $(input_tokens + output_tokens) tokens"
    end

    return result
end

# Run this example to test the OpenAI Responses API implementation
# Make sure your OpenAI API key is set in the environment variable OPENAI_API_KEY

body = create_response(
    OpenAISchema(),
    PromptingTools.OPENAI_API_KEY,
    "gpt-4.1-mini",
    "What is the capital of France?"
)

## Ask normal question
response = airespond(
    "What is the 3rd largest city in the Czech Republic?", model = "gpt-4.1-mini")

## Trigger web search
response = airespond(
    "What is the 3rd largest city in the Czech Republic?", enable_websearch = true, model = "gpt-4.1-mini")
## You can access the extra fields like reasoning, response_id, or full_response
response.extras[:reasoning]
response.extras[:response_id]
response.extras[:full_response][:output]
## See the tools used
response.extras[:full_response][:tools]

## Do a follow up question
new_response = airespond(
    "What's the population?", enable_websearch = true,
    model = "gpt-4.1-mini",
    previous_response_id = response.extras[:response_id])

## See the annotations (sources)
JSON3.pretty(new_response.extras[:full_response][:output])

## Use a template
response = airespond(
    :AssistantAsk;
    ask = "What is the 3rd largest city in the Czech Republic?",
    model = "gpt-4.1-mini",
    enable_websearch = true,
    previous_response_id = response.extras[:response_id])