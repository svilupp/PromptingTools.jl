## OpenAI Responses API
#
# This file defines support for the OpenAI Responses API
# https://platform.openai.com/docs/api-reference/responses/create
#

using HTTP
using JSON3
using OpenAI

# Import message types
import ..AbstractChatMessage, ..AbstractMessage, ..ALLOWED_PROMPT_TYPE
import .._calculate_cost, ..finalize_outputs, ..OPENAI_API_KEY, ..MODEL_CHAT, ..MODEL_ALIASES

# Type definitions
"""
    AbstractMessagePart

Base type for different parts of a message response from OpenAI Responses API.
"""
abstract type AbstractMessagePart end

"""
    TextMessagePart <: AbstractMessagePart

A text message part returned by the OpenAI Responses API.

# Fields
- `text::String`: The text content of the message part.
- `annotations::Vector{Dict{String, Any}}`: Annotations for the text, such as citations or references.
"""
Base.@kwdef struct TextMessagePart <: AbstractMessagePart
    text::String
    annotations::Vector{Dict{String, Any}} = Dict{String, Any}[]
end

"""
    ImageMessagePart <: AbstractMessagePart

An image message part returned by the OpenAI Responses API.

# Fields
- `url::String`: The URL of the image.
- `detail::String`: The detail level of the image.
"""
Base.@kwdef struct ImageMessagePart <: AbstractMessagePart
    url::String
    detail::String = "auto"
end

"""
    ReasoningParams

Reasoning parameters from the OpenAI Responses API.

# Fields
- `effort::Union{Nothing, String}`: The effort level for reasoning (e.g., "high").
- `summary::Union{Nothing, String}`: A summary of the reasoning.
"""
Base.@kwdef struct ReasoningParams
    effort::Union{Nothing, String} = nothing
    summary::Union{Nothing, String} = nothing
end

"""
    UsageMetrics

Usage metrics from the OpenAI Responses API.

# Fields
- `input_tokens::Int`: The number of input tokens used.
- `output_tokens::Int`: The number of output tokens used.
- `total_tokens::Int`: The total number of tokens used.
- `input_tokens_details::Dict{String, Any}`: Detailed information about input tokens.
- `output_tokens_details::Dict{String, Any}`: Detailed information about output tokens.
"""
Base.@kwdef struct UsageMetrics
    input_tokens::Int = -1
    output_tokens::Int = -1
    total_tokens::Int = -1
    input_tokens_details::Dict{String, Any} = Dict{String, Any}()
    output_tokens_details::Dict{String, Any} = Dict{String, Any}()
end

"""
    AIMessageParts

A message type for AI-generated responses from the OpenAI Responses API.
Returned by the `airespond` function.
    
# Fields
- `parts::Vector{AbstractMessagePart}`: The parts of the message (text, image, etc.).
- `reasoning::ReasoningParams`: Reasoning parameters from the API.
- `usage::UsageMetrics`: Usage metrics from the API.
- `response_id::String`: The ID of the response from the API.
- `status::Union{Int, Nothing}`: The status of the message from the API.
- `tokens::Tuple{Int, Int}`: The number of tokens used (prompt, completion).
- `elapsed::Float64`: The time taken to generate the response in seconds.
- `cost::Union{Nothing, Float64}`: The cost of the API call.
- `extras::Union{Nothing, Dict{Symbol, Any}}`: Additional metadata.
- `finish_reason::Union{Nothing, String}`: The reason the response was finished.
- `run_id::Union{Nothing, Int}`: The unique ID of the run.
- `_type::Symbol`: The type of the message.
"""
Base.@kwdef struct AIMessageParts <: AbstractChatMessage
    parts::Vector{AbstractMessagePart} = AbstractMessagePart[]
    reasoning::ReasoningParams = ReasoningParams()
    usage::UsageMetrics = UsageMetrics()
    response_id::String = ""
    status::Union{Int, Nothing} = nothing
    tokens::Tuple{Int, Int} = (-1, -1)
    elapsed::Float64 = -1.0
    cost::Union{Nothing, Float64} = nothing
    extras::Union{Nothing, Dict{Symbol, Any}} = nothing
    finish_reason::Union{Nothing, String} = nothing
    run_id::Union{Nothing, Int} = Int(rand(Int16))
    _type::Symbol = :aimessageparts
end

# Define the content field for compatibility with existing functions
function Base.getproperty(msg::AIMessageParts, sym::Symbol)
    if sym === :content
        # Concatenate text from all TextMessagePart instances
        return join([part.text for part in getfield(msg, :parts) if part isa TextMessagePart], "\n")
    else
        return getfield(msg, sym)
    end
end

# API function to create responses
"""
    create_response(schema::AbstractOpenAISchema, 
                   api_key::AbstractString,
                   model::AbstractString,
                   input;
                   previous_response_id::Union{Nothing, AbstractString} = nothing,
                   http_kwargs::NamedTuple = NamedTuple(),
                   tools::Vector{<:Any} = [],
                   reasoning::Union{Nothing, Dict{String, Any}} = nothing,
                   kwargs...)

Creates a response using the OpenAI Responses API.

# Arguments
- `schema::AbstractOpenAISchema`: The schema for the prompt.
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
function create_response(schema::AbstractOpenAISchema,
                        api_key::AbstractString,
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
    !isnothing(previous_response_id) && (body["previous_response_id"] = previous_response_id)
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

# Convert response to AIMessageParts
"""
    response_to_message(schema::AbstractOpenAISchema, 
                       response;
                       time::Float64 = 0.0,
                       model_id::AbstractString = "",
                       run_id::Int = Int(rand(Int32)))

Converts a response from the OpenAI Responses API to an AIMessageParts object.

# Arguments
- `schema::AbstractOpenAISchema`: The schema for the prompt.
- `response`: The response from the OpenAI API.
- `time::Float64`: The time taken to generate the response in seconds.
- `model_id::AbstractString`: The ID of the model used to generate the response.
- `run_id::Int`: The unique ID of the run.

# Returns
- `msg::AIMessageParts`: The AIMessageParts object.
"""
function response_to_message(schema::AbstractOpenAISchema,
                            response;
                            time::Float64 = 0.0,
                            model_id::AbstractString = "",
                            run_id::Int = Int(rand(Int32)))
    # Extract the response ID
    response_id = response.response[:id]
    
    # Extract message parts
    parts = AbstractMessagePart[]
    
    # Extract output from the response
    output = response.response[:output]
    
    # Process each output item
    for item in output
        # Check item type (message, etc.)
        if item[:type] == "message"
            # Process message content
            for content in item[:content]
                if content[:type] == "output_text"
                    # Create a TextMessagePart
                    push!(parts, TextMessagePart(
                        text = content[:text],
                        annotations = get(content, :annotations, Dict{String, Any}[])
                    ))
                elseif content[:type] == "output_image"
                    # Create an ImageMessagePart
                    push!(parts, ImageMessagePart(
                        url = content[:image_url]
                    ))
                end
                # Add other part types as needed
            end
        end
        # Add other output types as needed
    end
    
    # Extract reasoning parameters
    reasoning_data = get(response.response, :reasoning, Dict())
    reasoning = ReasoningParams(
        effort = get(reasoning_data, :effort, nothing),
        summary = get(reasoning_data, :summary, nothing)
    )
    
    # Extract usage metrics
    usage_data = get(response.response, :usage, Dict())
    usage = UsageMetrics(
        input_tokens = get(usage_data, :input_tokens, -1),
        output_tokens = get(usage_data, :output_tokens, -1),
        total_tokens = get(usage_data, :total_tokens, -1),
        input_tokens_details = get(usage_data, :input_tokens_details, Dict()),
        output_tokens_details = get(usage_data, :output_tokens_details, Dict())
    )
    
    # Calculate cost based on token usage (similar to existing functions)
    cost = _calculate_cost(model_id, usage.input_tokens, usage.output_tokens)
    
    # Create and return the AIMessageParts object
    return AIMessageParts(
        parts = parts,
        reasoning = reasoning,
        usage = usage,
        response_id = response_id,
        status = response.status,
        tokens = (usage.input_tokens, usage.output_tokens),
        elapsed = time,
        cost = cost,
        extras = Dict{Symbol, Any}(:full_response => response.response),
        finish_reason = get(response.response, :status, nothing),
        run_id = run_id
    )
end

# Main function for generating responses
"""
    airespond(prompt_schema::AbstractOpenAISchema, prompt::ALLOWED_PROMPT_TYPE;
            verbose::Bool = true,
            api_key::String = OPENAI_API_KEY,
            model::String = MODEL_CHAT,
            previous_response_id::Union{Nothing, String} = nothing,
            return_all::Bool = false,
            dry_run::Bool = false,
            conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
            no_system_message::Bool = false,
            name_user::Union{Nothing, String} = nothing,
            http_kwargs::NamedTuple = (retry_non_idempotent = true, retries = 5, readtimeout = 120),
            api_kwargs::NamedTuple = NamedTuple(),
            reasoning::Union{Nothing, Dict{String, Any}} = nothing,
            tools::Vector{<:Any} = [],
            kwargs...)

Generates responses using the OpenAI Responses API.

# Arguments
- `prompt_schema::AbstractOpenAISchema`: The schema for the prompt.
- `prompt::ALLOWED_PROMPT_TYPE`: The prompt to generate a response for.
- `verbose::Bool`: Whether to print verbose information.
- `api_key::String`: The API key to use for the OpenAI API.
- `model::String`: The model to use for generating the response.
- `previous_response_id::Union{Nothing, String}`: The ID of a previous response to continue the conversation.
- `return_all::Bool`: Whether to return all outputs or just the message.
- `dry_run::Bool`: Whether to make a dry run (no API call).
- `conversation::AbstractVector{<:AbstractMessage}`: Past conversation to include.
- `no_system_message::Bool`: Whether to exclude system messages.
- `name_user::Union{Nothing, String}`: The name of the user in the conversation.
- `http_kwargs::NamedTuple`: Additional keyword arguments for the HTTP request.
- `api_kwargs::NamedTuple`: Additional keyword arguments for the API call.
- `reasoning::Union{Nothing, Dict{String, Any}}`: Reasoning parameters for the model.
- `tools::Vector{<:Any}`: Tools for the model to use.
- `kwargs...`: Additional keyword arguments.

# Returns
- `output`: The response from the model.
"""
function airespond(prompt_schema::AbstractOpenAISchema, prompt::ALLOWED_PROMPT_TYPE;
                 verbose::Bool = true,
                 api_key::String = OPENAI_API_KEY,
                 model::String = MODEL_CHAT,
                 previous_response_id::Union{Nothing, String} = nothing,
                 return_all::Bool = false,
                 dry_run::Bool = false,
                 conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
                 no_system_message::Bool = false,
                 name_user::Union{Nothing, String} = nothing,
                 http_kwargs::NamedTuple = (retry_non_idempotent = true, retries = 5, readtimeout = 120),
                 api_kwargs::NamedTuple = NamedTuple(),
                 reasoning::Union{Nothing, Dict{String, Any}} = nothing,
                 tools::Vector{<:Any} = [],
                 kwargs...)
    # Assert that streaming is not allowed
    @assert !haskey(api_kwargs, :stream) "Streaming is not supported for the Responses API"
    @assert isnothing(get(kwargs, :streamcallback, nothing)) "Streaming is not supported for the Responses API"
    
    # Find the unique ID for the model alias provided
    global MODEL_ALIASES
    model_id = get(MODEL_ALIASES, model, model)
    
    # Render the conversation
    input_data = render_for_responses(
        prompt_schema, prompt;
        conversation, no_system_message, name_user, kwargs...)
    
    if !dry_run
        # Make the API call
        time = @elapsed r = create_response(prompt_schema, api_key,
            model_id,
            input_data;
            previous_response_id,
            http_kwargs,
            tools,
            reasoning,
            api_kwargs...)
        
        # Process the response
        msg = response_to_message(prompt_schema, r;
            time, model_id, run_id = Int(rand(Int32)))
        
        # Reporting
        verbose && @info _report_stats(msg, model_id)
    else
        msg = nothing
    end
    
    # Select what to return
    output = finalize_outputs(prompt,
        input_data,
        msg;
        conversation,
        return_all,
        dry_run,
        no_system_message,
        kwargs...)
    
    return output
end

"""
    render_for_responses(schema::AbstractOpenAISchema, prompt::ALLOWED_PROMPT_TYPE;
                      conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
                      no_system_message::Bool = false,
                      name_user::Union{Nothing, String} = nothing,
                      kwargs...)

Renders a prompt for the OpenAI Responses API.

# Arguments
- `schema::AbstractOpenAISchema`: The schema for the prompt.
- `prompt::ALLOWED_PROMPT_TYPE`: The prompt to render.
- `conversation::AbstractVector{<:AbstractMessage}`: Past conversation to include.
- `no_system_message::Bool`: Whether to exclude system messages.
- `name_user::Union{Nothing, String}`: The name of the user in the conversation.
- `kwargs...`: Additional keyword arguments.

# Returns
- `input_data`: The rendered input data for the API.
"""
function render_for_responses(schema::AbstractOpenAISchema, prompt::ALLOWED_PROMPT_TYPE;
                           conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
                           no_system_message::Bool = false,
                           name_user::Union{Nothing, String} = nothing,
                           kwargs...)
    # Check if prompt is a string, message, or vector of messages
    if prompt isa AbstractString
        # Simple text input
        return prompt
    else
        # For messages, render them into the format expected by the Responses API
        conv_rendered = render(
            schema, prompt;
            conversation, no_system_message, name_user, kwargs...)
        
        # Convert to Responses API format
        if isempty(conv_rendered) || (length(conv_rendered) == 1 && conv_rendered[1][:role] == "user")
            # Simple user message
            user_message = conv_rendered[1]
            
            # Check if it's a simple text message or a message with images
            if haskey(user_message, :content) && user_message[:content] isa String
                # Simple text message
                return user_message[:content]
            else
                # Message with structured content (e.g., text and images)
                input_items = []
                
                # For each message in the conversation
                for msg in conv_rendered
                    item = Dict{String, Any}("role" => msg[:role])
                    
                    # Convert content to the format expected by the Responses API
                    if msg[:content] isa String
                        item["content"] = [Dict{String, Any}("type" => "input_text", "text" => msg[:content])]
                    elseif msg[:content] isa Vector
                        item["content"] = msg[:content]
                    end
                    
                    push!(input_items, item)
                end
                
                return input_items
            end
        else
            # Multiple messages - format as an array of messages
            input_items = []
            
            # For each message in the conversation
            for msg in conv_rendered
                item = Dict{String, Any}("role" => msg[:role])
                
                # Convert content to the format expected by the Responses API
                if msg[:content] isa String
                    item["content"] = [Dict{String, Any}("type" => "input_text", "text" => msg[:content])]
                elseif msg[:content] isa Vector
                    item["content"] = msg[:content]
                end
                
                push!(input_items, item)
            end
            
            return input_items
        end
    end
end

"""
    render(schema::AbstractOpenAISchema, tool::ToolRef; kwargs...)

Renders a tool reference into the OpenAI Responses API format.

# Arguments
- `schema::AbstractOpenAISchema`: The schema for the prompt.
- `tool::ToolRef`: The tool reference to render.
- `kwargs...`: Additional keyword arguments.

# Returns
- The rendered tool reference.
"""
function render(schema::AbstractOpenAISchema, tool::ToolRef; kwargs...)
    # Map tool references to OpenAI tools
    (; extras) = tool
    rendered = if tool.ref == :websearch
        Dict(
            "type" => "web_search",
            "name" => get(extras, "name", "web_search")
        )
    elseif tool.ref == :file_search
        Dict(
            "type" => "file_search",
            "name" => get(extras, "name", "file_search"),
            "vector_store_ids" => get(extras, "vector_store_ids", String[]),
            "max_num_results" => get(extras, "max_num_results", 10)
        )
    elseif tool.ref == :function
        Dict(
            "type" => "function",
            "name" => get(extras, "name", "function"),
            "description" => get(extras, "description", ""),
            "parameters" => get(extras, "parameters", Dict())
        )
    else
        throw(ArgumentError("Unknown tool reference: $(tool.ref)"))
    end
    
    # Add any other parameters from extras
    if !isempty(extras)
        for (key, value) in extras
            key = string(key)
            if !haskey(rendered, key)
                rendered[key] = value
            end
        end
    end
    
    return rendered
end

# Default method for airespond
"""
    airespond(prompt::ALLOWED_PROMPT_TYPE; kwargs...)

Generates responses using the OpenAI Responses API with default schema.

# Arguments
- `prompt::ALLOWED_PROMPT_TYPE`: The prompt to generate a response for.
- `kwargs...`: Additional keyword arguments.

# Returns
- `output`: The response from the model.
"""
function airespond(prompt::ALLOWED_PROMPT_TYPE; kwargs...)
    airespond(OpenAISchema(), prompt; kwargs...)
end
