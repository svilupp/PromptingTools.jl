using PromptingTools
const PT = PromptingTools
using HTTP
using JSON3
using OpenAI

# This example demonstrates the use of the OpenAI Responses API
# with a simplified implementation that returns standard AIMessage objects

"""
    create_response(api_key::AbstractString,
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
function create_response(api_key::AbstractString,
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

"""
    airespond(prompt; kwargs...)

Generate a response using the OpenAI Responses API.
Returns an AIMessage with the response content and additional information in the extras field.

# Arguments
- `prompt`: The prompt to send to the API
- `previous_response_id=nothing`: ID of a previous response to continue the conversation
- `enable_websearch=false`: Whether to enable web search capabilities
- `model="gpt-4o"`: The model to use
- `verbose=true`: Whether to print verbose information

# Returns
- `AIMessage`: The response from the API with extras containing response_id and other metadata
"""
function airespond(prompt; 
                  previous_response_id=nothing, 
                  enable_websearch=false,
                  model="gpt-4o",
                  verbose=true,
                  api_key=ENV["OPENAI_API_KEY"],
                  kwargs...)
    
    # Start timing
    start_time = time()
    
    # Prepare tools if web search is enabled
    tools = []
    if enable_websearch
        push!(tools, Dict(
            "type" => "web_search",
            "name" => "web_search"
        ))
    end
    
    # Call the OpenAI Responses API
    response = create_response(
        api_key,
        model,
        prompt;
        previous_response_id=previous_response_id,
        tools=tools,
        http_kwargs=(retry_non_idempotent=true, retries=3, readtimeout=120)
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
    
    # Create and return an AIMessage
    result = PT.AIMessage(
        content = content,
        status = response.status,
        tokens = (input_tokens, output_tokens),
        elapsed = elapsed,
        extras = extras
    )
    
    # Print stats if verbose
    if verbose
        @info "Response generated in $(round(elapsed, digits=2))s using $(input_tokens + output_tokens) tokens"
    end
    
    return result
end

# Run this example to test the OpenAI Responses API implementation
# Make sure your OpenAI API key is set in the environment variable OPENAI_API_KEY

println("Testing OpenAI Responses API with airespond function...")

try
    # Example 1: Basic usage
    println("\nExample 1: Basic usage")
    response = airespond("What is the capital of France?")
    println("Response: ", response.content)
    println("Response ID: ", response.extras[:response_id])
    
    # Example 2: Continue a conversation
    println("\nExample 2: Continue a conversation")
    follow_up = airespond("Tell me more about its history"; 
                         previous_response_id=response.extras[:response_id])
    println("Follow-up: ", follow_up.content)
    
    # Example 3: Using web search
    println("\nExample 3: Using web search")
    web_response = airespond("What are the latest developments in quantum computing?"; 
                            enable_websearch=true)
    println("Web search response: ", web_response.content)
    if haskey(web_response.extras[:reasoning], "effort")
        println("Reasoning effort: ", web_response.extras[:reasoning]["effort"])
    end
    
    # Example 4: Using a different model
    println("\nExample 4: Using a different model")
    custom_model = airespond("Generate a haiku about programming"; 
                            model="gpt-4-turbo")
    println("Custom model response: ", custom_model.content)
    
    println("\nAll examples completed successfully!")
catch e
    println("\nError running examples: ", e)
    # Print the backtrace for debugging
    for (exc, bt) in Base.catch_stack()
        showerror(stdout, exc, bt)
        println()
    end
end
