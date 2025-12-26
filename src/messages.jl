# This file contains key building blocks of conversation history (messages) and utilities to work with them (eg, render)

## Messages
abstract type AbstractMessage end
abstract type AbstractChatMessage <: AbstractMessage end # with text-based content
abstract type AbstractDataMessage <: AbstractMessage end # with data-based content, eg, embeddings
"""
    AbstractAnnotationMessage

Messages that provide extra information without being sent to LLMs.

Required fields: `content`, `tags`, `comment`, `run_id`.

Note: `comment` is intended for human readers only and should never be used.
`run_id` should be a unique identifier for the annotation, typically a random number.
"""
abstract type AbstractAnnotationMessage <: AbstractMessage end # messages that provide extra information without being sent to LLMs
abstract type AbstractTracerMessage{T <: AbstractMessage} <: AbstractMessage end # message with annotation that exposes the underlying message
# Complementary type for tracing, follows the same API as TracerMessage
abstract type AbstractTracer{T <: Any} end

## Allowed inputs for ai* functions, AITemplate is resolved one level higher
const ALLOWED_PROMPT_TYPE = Union{
    AbstractString,
    AbstractMessage,
    Vector{<:AbstractMessage}
}

## Token Usage Tracking
"""
    TokenUsage

Standardized token usage tracking across all LLM providers.

Provides unified field names for cross-provider compatibility while preserving
provider-specific details in the `extras` field.

# Core Fields (always populated when available)
- `input_tokens::Int`: Standard input/prompt tokens (default: 0)
- `output_tokens::Int`: Standard output/completion tokens (default: 0)

# Cache Fields (for providers with caching)
- `cache_read_tokens::Int`: Tokens read from cache (discounted) (default: 0)
- `cache_write_tokens::Int`: Tokens written to cache (premium for Anthropic) (default: 0)

# Extended Fields (provider-specific)
- `reasoning_tokens::Int`: Reasoning/thinking tokens (OpenAI o1/DeepSeek) (default: 0)
- `audio_input_tokens::Int`: Audio input tokens (OpenAI) (default: 0)
- `audio_output_tokens::Int`: Audio output tokens (OpenAI) (default: 0)

# Metadata
- `model_id::String`: Model identifier used for this usage (default: "")
- `cost::Float64`: Calculated cost including cache discounts (default: 0.0)
- `elapsed::Float64`: Time taken for the API call in seconds (default: 0.0)
- `extras::Dict{Symbol,Any}`: Provider-specific raw usage data (default: empty)

# Example
```julia
usage = TokenUsage(
    input_tokens = 100,
    output_tokens = 50,
    cache_read_tokens = 80,
    model_id = "claude-sonnet-4-20250514"
)
```
"""
@kwdef struct TokenUsage
    # Core tokens
    input_tokens::Int = 0
    output_tokens::Int = 0

    # Cache tokens
    cache_read_tokens::Int = 0
    cache_write_tokens::Int = 0

    # Extended tokens (provider-specific)
    reasoning_tokens::Int = 0
    audio_input_tokens::Int = 0
    audio_output_tokens::Int = 0

    # Metadata
    model_id::String = ""
    cost::Float64 = 0.0
    elapsed::Float64 = 0.0

    # Raw provider data
    extras::Dict{Symbol, Any} = Dict{Symbol, Any}()
end

# Arithmetic operations for aggregation
function Base.:+(a::TokenUsage, b::TokenUsage)
    TokenUsage(
        input_tokens = a.input_tokens + b.input_tokens,
        output_tokens = a.output_tokens + b.output_tokens,
        cache_read_tokens = a.cache_read_tokens + b.cache_read_tokens,
        cache_write_tokens = a.cache_write_tokens + b.cache_write_tokens,
        reasoning_tokens = a.reasoning_tokens + b.reasoning_tokens,
        audio_input_tokens = a.audio_input_tokens + b.audio_input_tokens,
        audio_output_tokens = a.audio_output_tokens + b.audio_output_tokens,
        model_id = isempty(a.model_id) ? b.model_id : a.model_id,
        cost = a.cost + b.cost,
        elapsed = a.elapsed + b.elapsed,
        extras = merge(a.extras, b.extras)
    )
end

"Total tokens including all token types"
function total_tokens(u::TokenUsage)
    u.input_tokens + u.output_tokens +
    u.cache_read_tokens + u.cache_write_tokens + u.reasoning_tokens
end

function Base.show(io::IO, u::TokenUsage)
    print(io, "TokenUsage(in=$(u.input_tokens), out=$(u.output_tokens)")
    u.cache_read_tokens > 0 && print(io, ", cache_read=$(u.cache_read_tokens)")
    u.cache_write_tokens > 0 && print(io, ", cache_write=$(u.cache_write_tokens)")
    u.reasoning_tokens > 0 && print(io, ", reasoning=$(u.reasoning_tokens)")
    u.cost > 0 && print(io, ", cost=\$$(round(u.cost; digits=6))")
    print(io, ")")
end

# Custom equality for TokenUsage (needed because extras Dict compares by identity, not value)
function Base.:(==)(a::TokenUsage, b::TokenUsage)
    a.input_tokens == b.input_tokens &&
        a.output_tokens == b.output_tokens &&
        a.cache_read_tokens == b.cache_read_tokens &&
        a.cache_write_tokens == b.cache_write_tokens &&
        a.reasoning_tokens == b.reasoning_tokens &&
        a.audio_input_tokens == b.audio_input_tokens &&
        a.audio_output_tokens == b.audio_output_tokens &&
        a.model_id == b.model_id &&
        a.cost == b.cost &&
        a.elapsed == b.elapsed &&
        a.extras == b.extras
end

# Workaround to be able to add metadata to serialized conversations, templates, etc.
# Ignored by `render` directives
Base.@kwdef struct MetadataMessage{T <: AbstractString} <: AbstractChatMessage
    content::T
    description::String = ""
    version::String = "1"
    source::String = ""
    run_id::Union{Nothing, Int} = Int(rand(Int16))
    _type::Symbol = :metadatamessage
end
Base.@kwdef struct SystemMessage{T <: AbstractString} <: AbstractChatMessage
    content::T
    variables::Vector{Symbol} = _extract_handlebar_variables(content)
    _type::Symbol = :systemmessage
    SystemMessage{T}(c, v, t) where {T <: AbstractString} = new(c, v, t)
end
function SystemMessage(content::T,
        variables::Vector{Symbol},
        type::Symbol) where {T <: AbstractString}
    not_allowed_kwargs = intersect(variables, RESERVED_KWARGS)
    @assert length(not_allowed_kwargs)==0 "Error: Some placeholders are invalid, as they are reserved for `ai*` functions. Change: $(join(not_allowed_kwargs,","))"
    return SystemMessage{T}(content, variables, type)
end

"""
    UserMessage

A message type for user-generated text-based responses. 
Consumed by `ai*` functions to generate responses.
    
# Fields
- `content::T`: The content of the message.
- `variables::Vector{Symbol}`: The variables in the message.
- `name::Union{Nothing, String}`: The name of the `role` in the conversation.
"""
Base.@kwdef struct UserMessage{T <: AbstractString} <: AbstractChatMessage
    content::T
    variables::Vector{Symbol} = _extract_handlebar_variables(content)
    name::Union{Nothing, String} = nothing
    _type::Symbol = :usermessage
    UserMessage{T}(c, v, n, t) where {T <: AbstractString} = new(c, v, n, t)
end
function UserMessage(content::T,
        variables::Vector{Symbol},
        name::Union{Nothing, String},
        type::Symbol) where {T <: AbstractString}
    not_allowed_kwargs = intersect(variables, RESERVED_KWARGS)
    @assert length(not_allowed_kwargs)==0 "Error: Some placeholders are invalid, as they are reserved for `ai*` functions. Change: $(join(not_allowed_kwargs,","))"
    return UserMessage{T}(content, variables, name, type)
end

"""
    UserMessageWithImages

A message type for user-generated text-based responses with images. 
Consumed by `ai*` functions to generate responses.
    
# Fields
- `content::T`: The content of the message.
- `image_url::Vector{String}`: The URLs of the images.
- `variables::Vector{Symbol}`: The variables in the message.
- `name::Union{Nothing, String}`: The name of the `role` in the conversation.
"""
Base.@kwdef struct UserMessageWithImages{T <: AbstractString} <: AbstractChatMessage
    content::T
    image_url::Vector{String} # no default! fail when not provided
    variables::Vector{Symbol} = _extract_handlebar_variables(content)
    name::Union{Nothing, String} = nothing
    _type::Symbol = :usermessagewithimages
    UserMessageWithImages{T}(c, i, v, n, t) where {T <: AbstractString} = new(c, i, v, n, t)
end
function UserMessageWithImages(content::T, image_url::Vector{<:AbstractString},
        variables::Vector{Symbol},
        name::Union{Nothing, String},
        type::Symbol) where {T <: AbstractString}
    not_allowed_kwargs = intersect(variables, RESERVED_KWARGS)
    @assert length(not_allowed_kwargs)==0 "Error: Some placeholders are invalid, as they are reserved for `ai*` functions. Change: $(join(not_allowed_kwargs,","))"
    return UserMessageWithImages{T}(content, string.(image_url), variables, name, type)
end

"""
    AIMessage

A message type for AI-generated text-based responses.
Returned by `aigenerate`, `aiclassify`, and `aiscan` functions.

# Fields
- `content::Union{AbstractString, Nothing}`: The content of the message.
- `status::Union{Int, Nothing}`: The status of the message from the API.
- `name::Union{Nothing, String}`: The name of the `role` in the conversation.
- `tokens::Tuple{Int, Int}`: The number of tokens used (prompt,completion). Legacy field, prefer `usage`.
- `elapsed::Float64`: The time taken to generate the response in seconds. Legacy field, prefer `usage.elapsed`.
- `cost::Union{Nothing, Float64}`: The cost of the API call. Legacy field, prefer `usage.cost`.
- `usage::Union{Nothing, TokenUsage}`: Detailed token usage including cache tokens, cost, and timing.
- `log_prob::Union{Nothing, Float64}`: The log probability of the response.
- `extras::Union{Nothing, Dict{Symbol, Any}}`: A dictionary for additional metadata that is not part of the key message fields. Try to limit to a small number of items and singletons to be serializable.
- `finish_reason::Union{Nothing, String}`: The reason the response was finished.
- `run_id::Union{Nothing, Int}`: The unique ID of the run.
- `sample_id::Union{Nothing, Int}`: The unique ID of the sample (if multiple samples are generated, they will all have the same `run_id`).
"""
Base.@kwdef struct AIMessage{T <: Union{AbstractString, Nothing}} <: AbstractChatMessage
    content::T = nothing
    status::Union{Int, Nothing} = nothing
    name::Union{Nothing, String} = nothing
    tokens::Tuple{Int, Int} = (-1, -1)
    elapsed::Float64 = -1.0
    cost::Union{Nothing, Float64} = nothing
    usage::Union{Nothing, TokenUsage} = nothing
    log_prob::Union{Nothing, Float64} = nothing
    extras::Union{Nothing, Dict{Symbol, Any}} = nothing
    finish_reason::Union{Nothing, String} = nothing
    run_id::Union{Nothing, Int} = Int(rand(Int16))
    sample_id::Union{Nothing, Int} = nothing
    _type::Symbol = :aimessage
end

"""
    DataMessage

A message type for AI-generated data-based responses, ie, different `content` than text.
Returned by `aiextract` function.

# Fields
- `content::Union{AbstractString, Nothing}`: The content of the message.
- `status::Union{Int, Nothing}`: The status of the message from the API.
- `tokens::Tuple{Int, Int}`: The number of tokens used (prompt,completion). Legacy field, prefer `usage`.
- `elapsed::Float64`: The time taken to generate the response in seconds. Legacy field, prefer `usage.elapsed`.
- `cost::Union{Nothing, Float64}`: The cost of the API call. Legacy field, prefer `usage.cost`.
- `usage::Union{Nothing, TokenUsage}`: Detailed token usage including cache tokens, cost, and timing.
- `log_prob::Union{Nothing, Float64}`: The log probability of the response.
- `extras::Union{Nothing, Dict{Symbol, Any}}`: A dictionary for additional metadata that is not part of the key message fields. Try to limit to a small number of items and singletons to be serializable.
- `finish_reason::Union{Nothing, String}`: The reason the response was finished.
- `run_id::Union{Nothing, Int}`: The unique ID of the run.
- `sample_id::Union{Nothing, Int}`: The unique ID of the sample (if multiple samples are generated, they will all have the same `run_id`).
"""
Base.@kwdef struct DataMessage{T <: Any} <: AbstractDataMessage
    content::T
    status::Union{Int, Nothing} = nothing
    tokens::Tuple{Int, Int} = (-1, -1)
    elapsed::Float64 = -1.0
    cost::Union{Nothing, Float64} = nothing
    usage::Union{Nothing, TokenUsage} = nothing
    log_prob::Union{Nothing, Float64} = nothing
    extras::Union{Nothing, Dict{Symbol, Any}} = nothing
    finish_reason::Union{Nothing, String} = nothing
    run_id::Union{Nothing, Int} = Int(rand(Int16))
    sample_id::Union{Nothing, Int} = nothing
    _type::Symbol = :datamessage
end

"""
    ToolMessage

A message type for tool calls. 
    
It represents both the request (fields `args`, `name`) and the response (field `content`).

# Fields
- `content::Any`: The content of the message.
- `req_id::Union{Nothing, Int}`: The unique ID of the request.
- `tool_call_id::String`: The unique ID of the tool call.
- `raw::AbstractString`: The raw JSON string of the tool call request.
- `args::Union{Nothing, Dict{Symbol, Any}}`: The arguments of the tool call request.
- `name::Union{Nothing, String}`: The name of the tool call request.
"""
Base.@kwdef mutable struct ToolMessage <: AbstractDataMessage
    content::Any = nothing
    req_id::Union{Nothing, Int} = nothing
    tool_call_id::String
    raw::AbstractString
    args::Union{Nothing, Dict{Symbol, Any}} = nothing
    name::Union{Nothing, String} = nothing
    _type::Symbol = :toolmessage
end

"""
    AIToolRequest

A message type for AI-generated tool requests.
Returned by `aitools` functions.

# Fields
- `content::Union{AbstractString, Nothing}`: The content of the message.
- `tool_calls::Vector{ToolMessage}`: The vector of tool call requests.
- `name::Union{Nothing, String}`: The name of the `role` in the conversation.
- `status::Union{Int, Nothing}`: The status of the message from the API.
- `tokens::Tuple{Int, Int}`: The number of tokens used (prompt,completion). Legacy field, prefer `usage`.
- `elapsed::Float64`: The time taken to generate the response in seconds. Legacy field, prefer `usage.elapsed`.
- `cost::Union{Nothing, Float64}`: The cost of the API call. Legacy field, prefer `usage.cost`.
- `usage::Union{Nothing, TokenUsage}`: Detailed token usage including cache tokens, cost, and timing.
- `log_prob::Union{Nothing, Float64}`: The log probability of the response.
- `extras::Union{Nothing, Dict{Symbol, Any}}`: A dictionary for additional metadata that is not part of the key message fields. Try to limit to a small number of items and singletons to be serializable.
- `finish_reason::Union{Nothing, String}`: The reason the response was finished.
- `run_id::Union{Nothing, Int}`: The unique ID of the run.
- `sample_id::Union{Nothing, Int}`: The unique ID of the sample (if multiple samples are generated, they will all have the same `run_id`).

See `ToolMessage` for the fields of the tool call requests.

See also: [`tool_calls`](@ref), [`execute_tool`](@ref), [`parse_tool`](@ref)
"""
Base.@kwdef struct AIToolRequest{T <: Union{AbstractString, Nothing}} <: AbstractDataMessage
    content::T = nothing
    tool_calls::Vector{ToolMessage} = ToolMessage[]
    name::Union{Nothing, String} = nothing
    status::Union{Int, Nothing} = nothing
    tokens::Tuple{Int, Int} = (-1, -1)
    elapsed::Float64 = -1.0
    cost::Union{Nothing, Float64} = nothing
    usage::Union{Nothing, TokenUsage} = nothing
    log_prob::Union{Nothing, Float64} = nothing
    extras::Union{Nothing, Dict{Symbol, Any}} = nothing
    finish_reason::Union{Nothing, String} = nothing
    run_id::Union{Nothing, Int} = Int(rand(Int16))
    sample_id::Union{Nothing, Int} = nothing
    _type::Symbol = :aitoolrequest
end
"Get the vector of tool call requests from an AIToolRequest/message."
tool_calls(msg::AIToolRequest) = msg.tool_calls
tool_calls(msg::AbstractMessage) = ToolMessage[]
tool_calls(msg::ToolMessage) = [msg]
tool_calls(msg::AbstractTracerMessage) = tool_calls(msg.object)

"""
    AnnotationMessage

A message type for providing extra information in the conversation history without being sent to LLMs.
These messages are filtered out during rendering to ensure they don't affect the LLM's context.

Used to bundle key information and documentation for colleagues and future reference together with the data.

# Fields
- `content::T`: The content of the annotation (can be used for inputs to airag etc.)
- `extras::Dict{Symbol,Any}`: Additional metadata with symbol keys and any values
- `tags::Vector{Symbol}`: Vector of tags for categorization (default: empty)
- `comment::String`: Human-readable comment, never used for automatic operations (default: empty)
- `run_id::Union{Nothing,Int}`: The unique ID of the annotation

Note: The comment field is intended for human readers only and should never be used
for automatic operations.
"""
Base.@kwdef struct AnnotationMessage{T <: AbstractString} <: AbstractAnnotationMessage
    content::T
    extras::Union{Nothing, Dict{Symbol, Any}} = nothing
    tags::Vector{Symbol} = Symbol[]
    comment::String = ""
    run_id::Union{Nothing, Int} = Int(rand(Int32))
    _type::Symbol = :annotationmessage
end

### Other Message methods
# content-only constructor
function (MSG::Type{<:AbstractChatMessage})(prompt::AbstractString; kwargs...)
    MSG(; content = prompt, kwargs...)
end
function (MSG::Type{<:AbstractAnnotationMessage})(content::AbstractString; kwargs...)
    ## Re-type extras to be generic Dict{Symbol, Any}
    new_kwargs = if haskey(kwargs, :extras)
        [f == :extras ? f => convert(Dict{Symbol, Any}, kwargs[f]) : f => kwargs[f]
         for f in keys(kwargs)]
    else
        kwargs
    end
    MSG(; content, new_kwargs...)
end
function (MSG::Type{<:AbstractChatMessage})(msg::AbstractChatMessage)
    MSG(; msg.content)
end
function (MSG::Type{<:AbstractChatMessage})(msg::AbstractTracerMessage{<:AbstractChatMessage})
    MSG(; msg.content)
end

## It checks types so it should be defined for all inputs
isusermessage(m::Any) = m isa UserMessage
isusermessagewithimages(m::Any) = m isa UserMessageWithImages
issystemmessage(m::Any) = m isa SystemMessage
isdatamessage(m::Any) = m isa DataMessage
isaimessage(m::Any) = m isa AIMessage
istoolmessage(m::Any) = m isa ToolMessage
isaitoolrequest(m::Any) = m isa AIToolRequest
isabstractannotationmessage(msg::Any) = msg isa AbstractAnnotationMessage
istracermessage(m::Any) = m isa AbstractTracerMessage
isusermessage(m::AbstractTracerMessage) = isusermessage(m.object)
isusermessagewithimages(m::AbstractTracerMessage) = isusermessagewithimages(m.object)
issystemmessage(m::AbstractTracerMessage) = issystemmessage(m.object)
isdatamessage(m::AbstractTracerMessage) = isdatamessage(m.object)
isaimessage(m::AbstractTracerMessage) = isaimessage(m.object)
istoolmessage(m::AbstractTracerMessage) = istoolmessage(m.object)
isaitoolrequest(m::AbstractTracerMessage) = isaitoolrequest(m.object)
function isabstractannotationmessage(m::AbstractTracerMessage)
    isabstractannotationmessage(m.object)
end

# equality check for testing, only equal if all fields are equal and type is the same
Base.var"=="(m1::AbstractMessage, m2::AbstractMessage) = false
function Base.var"=="(m1::T, m2::T) where {T <: AbstractMessage}
    ## except for run_id, that's random and not important for content comparison
    all([getproperty(m1, f) == getproperty(m2, f) for f in fieldnames(T) if f != :run_id])
end

## Vision Models -- Constructor and Conversion
"Construct `UserMessageWithImages` with 1 or more images. Images can be either URLs or local paths."
function UserMessageWithImages(prompt::AbstractString;
        image_url::Union{Nothing, AbstractString, Vector{<:AbstractString}} = nothing,
        image_path::Union{Nothing, AbstractString, Vector{<:AbstractString}} = nothing,
        base64_only::Bool = false)
    @assert !(isnothing(image_url) && isnothing(image_path)) "At least one of `image_url` and `image_path` must be provided."
    url1 = !isnothing(image_url) ? _string_to_vector(image_url) : String[]
    # Process local image
    url2 = !isnothing(image_path) ?
           _string_to_vector(_encode_local_image(image_path; base64_only)) :
           String[]
    return UserMessageWithImages(;
        content = prompt,
        image_url = vcat(url1, url2),
        variables = _extract_handlebar_variables(prompt),
        _type = :usermessagewithimage)
end

# Attach image to user message
function attach_images_to_user_message(prompt::AbstractString;
        image_url::Union{Nothing, AbstractString, Vector{<:AbstractString}} = nothing,
        image_path::Union{Nothing, AbstractString, Vector{<:AbstractString}} = nothing,
        base64_only::Bool = false,
        kwargs...)
    UserMessageWithImages(prompt; image_url, image_path, base64_only)
end
function attach_images_to_user_message(msg::UserMessageWithImages; kwargs...)
    throw(AssertionError("Cannot attach additional images to UserMessageWithImages."))
end
function attach_images_to_user_message(msg::UserMessage;
        image_url::Union{Nothing, AbstractString, Vector{<:AbstractString}} = nothing,
        image_path::Union{Nothing, AbstractString, Vector{<:AbstractString}} = nothing,
        base64_only::Bool = false,
        kwargs...)
    UserMessageWithImages(msg.content; image_url, image_path, base64_only)
end
# automatically attach images to the latest user message, if not allowed, throw an error if more than 2 user messages provided
function attach_images_to_user_message(msgs::Vector{T};
        image_url::Union{Nothing, AbstractString, Vector{<:AbstractString}} = nothing,
        image_path::Union{Nothing, AbstractString, Vector{<:AbstractString}} = nothing,
        base64_only::Bool = false,
        attach_to_latest::Bool = true) where {T <: AbstractChatMessage}
    # Check how to add images to UserMessage
    count_user_msgs = count(isusermessage, msgs)
    @assert attach_to_latest||(count_user_msgs <= 1) "At most one user message must be provided. Otherwise we would not know where to attach the images!"
    @assert count_user_msgs>0 "At least one user message must be provided."
    ##
    idx = findlast(isusermessage, msgs)
    # re-type to accept UserMessageWithImages type
    msgs = convert(Vector{typejoin(UserMessageWithImages, T)}, msgs)
    msgs[idx] = attach_images_to_user_message(msgs[idx]; image_url, image_path, base64_only)
    return msgs
end

##############################
### TracerMessages
# - They are mutable (to update iteratively)
# - they contain a message and additional metadata
# - they expose as much of the underlying message as possible to allow the same operations
"""
    TracerMessage{T <: Union{AbstractChatMessage, AbstractDataMessage}} <: AbstractTracerMessage

A mutable wrapper message designed for tracing the flow of messages through the system, allowing for iterative updates and providing additional metadata for observability.

# Fields
- `object::T`: The original message being traced, which can be either a chat or data message.
- `from::Union{Nothing, Symbol}`: The identifier of the sender of the message.
- `to::Union{Nothing, Symbol}`: The identifier of the intended recipient of the message.
- `viewers::Vector{Symbol}`: A list of identifiers for entities that have access to view the message, in addition to the sender and recipient.
- `time_received::DateTime`: The timestamp when the message was received by the tracing system.
- `time_sent::Union{Nothing, DateTime}`: The timestamp when the message was originally sent, if available.
- `model::String`: The name of the model that generated the message. Defaults to empty.
- `parent_id::Symbol`: An identifier for the job or process that the message is associated with. Higher-level tracing ID.
- `thread_id::Symbol`: An identifier for the thread (series of messages for one model/agent) or execution context within the job where the message originated. It should be the same for messages in the same thread.
- `meta::Union{Nothing, Dict{Symbol, Any}}`: A dictionary for additional metadata that is not part of the message itself. Try to limit to a small number of items and singletons to be serializable.
- `_type::Symbol`: A fixed symbol identifying the type of the message as `:eventmessage`, used for type discrimination.

This structure is particularly useful for debugging, monitoring, and auditing the flow of messages in systems that involve complex interactions or asynchronous processing.

All fields are optional besides the `object`.

Useful methods: `pprint` (pretty prints the underlying message), `unwrap` (to get the `object` out of tracer), `align_tracer!` (to set all shared IDs in a vector of tracers to the same), `istracermessage` to check if given message is an AbstractTracerMessage

# Example
```julia
wrap_schema = PT.TracerSchema(PT.OpenAISchema())
msg = aigenerate(wrap_schema, "Say hi!"; model = "gpt4t")
msg # isa TracerMessage
msg.content # access content like if it was the message
```
"""
Base.@kwdef mutable struct TracerMessage{T <:
                                         Union{AbstractChatMessage, AbstractDataMessage}} <:
                           AbstractTracerMessage{T}
    object::T
    from::Union{Nothing, Symbol} = nothing # who sent it
    to::Union{Nothing, Symbol} = nothing # who received it
    viewers::Vector{Symbol} = Symbol[] # who has access to it (besides from, to)
    time_received::DateTime = now()
    time_sent::Union{Nothing, DateTime} = nothing
    model::String = ""
    parent_id::Symbol = gensym("parent")
    thread_id::Symbol = gensym("thread")
    run_id::Union{Nothing, Int} = Int(rand(Int32))
    meta::Union{Nothing, Dict{Symbol, Any}} = Dict{Symbol, Any}()
    _type::Symbol = :tracermessage
end
function TracerMessage(msg::Union{AbstractChatMessage, AbstractDataMessage}; kwargs...)
    TracerMessage(; object = msg, kwargs...)
end

"""
    TracerMessageLike{T <: Any} <: AbstractTracer

A mutable structure designed for general-purpose tracing within the system, capable of handling any type of object that is part of the AI Conversation.
It provides a flexible way to track and annotate objects as they move through different parts of the system, facilitating debugging, monitoring, and auditing.

# Fields
- `object::T`: The original object being traced.
- `from::Union{Nothing, Symbol}`: The identifier of the sender or origin of the object.
- `to::Union{Nothing, Symbol}`: The identifier of the intended recipient or destination of the object.
- `viewers::Vector{Symbol}`: A list of identifiers for entities that have access to view the object, in addition to the sender and recipient.
- `time_received::DateTime`: The timestamp when the object was received by the tracing system.
- `time_sent::Union{Nothing, DateTime}`: The timestamp when the object was originally sent, if available.
- `model::String`: The name of the model or process that generated or is associated with the object. Defaults to empty.
- `parent_id::Symbol`: An identifier for the job or process that the object is associated with. Higher-level tracing ID.
- `thread_id::Symbol`: An identifier for the thread or execution context (sub-task, sub-process) within the job where the object originated. It should be the same for objects in the same thread.
- `run_id::Union{Nothing, Int}`: A unique identifier for the run or instance of the process (ie, a single call to the LLM) that generated the object. Defaults to a random integer.
- `meta::Union{Nothing, Dict{Symbol, Any}}`: A dictionary for additional metadata that is not part of the object itself. Try to limit to a small number of items and singletons to be serializable.
- `_type::Symbol`: A fixed symbol identifying the type of the tracer as `:tracermessage`, used for type discrimination.

This structure is particularly useful for systems that involve complex interactions or asynchronous processing, where tracking the flow and transformation of objects is crucial.

All fields are optional besides the `object`.
"""
@kwdef mutable struct TracerMessageLike{T <: Any} <: AbstractTracer{T}
    object::T
    from::Union{Nothing, Symbol} = nothing # who sent it
    to::Union{Nothing, Symbol} = nothing # who received it
    viewers::Vector{Symbol} = Symbol[] # who has access to it (besides from, to)
    time_received::DateTime = now()
    time_sent::Union{Nothing, DateTime} = nothing
    model::String = ""
    parent_id::Symbol = gensym("parent")
    thread_id::Symbol = gensym("thread")
    run_id::Union{Nothing, Int} = Int(rand(Int32))
    meta::Union{Nothing, Dict{Symbol, Any}} = Dict{Symbol, Any}()
    _type::Symbol = :tracermessagelike
    ## TracerMessageLike() = new()
end
function TracerMessageLike(
        object; kwargs...)
    TracerMessageLike(; object, kwargs...)
end
Base.var"=="(t1::AbstractTracer, t2::AbstractTracer) = false
function Base.var"=="(t1::AbstractTracer{T}, t2::AbstractTracer{T}) where {T <: Any}
    ## except for run_id, that's random and not important for content comparison
    all([getproperty(t1, f) == getproperty(t2, f) for f in fieldnames(T) if f != :run_id])
end

# Shared methods
# getproperty for tracer messages forwards to the message when relevant
function Base.getproperty(t::Union{AbstractTracerMessage, AbstractTracer}, f::Symbol)
    obj = getfield(t, :object)
    if hasproperty(obj, f)
        getproperty(obj, f)
    else
        getfield(t, f)
    end
end

function Base.copy(t::T) where {T <: Union{AbstractTracerMessage, AbstractTracer}}
    T([deepcopy(getfield(t, f)) for f in fieldnames(T)]...)
end

"Unwraps the tracer message or tracer-like object, returning the original `object`."
function unwrap(t::Union{AbstractTracerMessage, AbstractTracer})
    getfield(t, :object)
end

"Extracts the metadata dictionary from the tracer message or tracer-like object."
function meta(t::Union{AbstractTracerMessage, AbstractTracer})
    getfield(t, :meta)
end

"Aligns the tracer message, updating the `parent_id`, `thread_id`. Often used to align multiple tracers in the vector to have the same IDs."
function align_tracer!(
        t::Union{AbstractTracerMessage, AbstractTracer}; parent_id::Symbol = t.parent_id,
        thread_id::Symbol = t.thread_id)
    t.parent_id = parent_id
    t.thread_id = thread_id
    return t
end
"Aligns multiple tracers in the vector to have the same Parent and Thread IDs as the first item."
function align_tracer!(
        vect::AbstractVector{<:Union{AbstractTracerMessage, AbstractTracer}})
    if !isempty(vect)
        t = first(vect)
        align_tracer!.(vect; t.parent_id, t.thread_id)
    else
        vect
    end
end

##############################
## Helpful accessors
"Helpful accessor for the last message in `conversation`. Returns the last message in the conversation."
function last_message(conversation::AbstractVector{<:AbstractMessage})
    length(conversation) == 0 ? nothing : conversation[end]
end

"Helpful accessor for the last generated output (`msg.content`) in `conversation`. Returns the last output in the conversation (eg, the string/data in the last message)."
function last_output(conversation::AbstractVector{<:AbstractMessage})
    msg = last_message(conversation)
    return isnothing(msg) ? nothing : last_output(msg)
end
last_message(msg::AbstractMessage) = msg
last_output(msg::AbstractMessage) = msg.content

## Display methods
function Base.show(io::IO, ::MIME"text/plain", m::AbstractChatMessage)
    type_ = string(typeof(m)) |> x -> split(x, "{")[begin]
    if m isa AIMessage
        printstyled(io, type_; color = :magenta)
    elseif m isa SystemMessage
        printstyled(io, type_; color = :light_green)
    elseif m isa UserMessage || m isa UserMessageWithImages
        printstyled(io, type_; color = :light_red)
    elseif m isa MetadataMessage
        printstyled(io, type_; color = :light_blue)
    else
        print(io, type_)
    end
    print(io, "(\"", m.content, "\")")
end
function Base.show(io::IO, ::MIME"text/plain", m::AbstractDataMessage)
    type_ = string(typeof(m)) |> x -> split(x, "{")[begin]
    printstyled(io, type_; color = :light_yellow)
    # for Embedding messages
    if m.content isa AbstractArray
        print(io, "(", typeof(m.content), " of size ", size(m.content), ")")
        # for any non-types extraction messages
    elseif m.content isa Dict{Symbol, <:Any}
        print(io, "(Dict with keys: ", join(keys(m.content), ", "), ")")
    elseif isaitoolrequest(m)
        content_str = m.content isa AbstractString ? m.content : "-"
        print(io, "(\"", content_str, "\"; Tool Requests: ", length(m.tool_calls), ")")
    elseif istoolmessage(m)
        content_str = m.content isa AbstractString ? m.content : "-"
        print(io, "(\"", content_str, "\")")
    else
        print(io, "(", typeof(m.content), ")")
    end
end
function Base.show(io::IO, ::MIME"text/plain", m::AbstractAnnotationMessage)
    type_ = string(typeof(m)) |> x -> split(x, "{")[begin]
    printstyled(io, type_; color = :light_blue)
    print(io, "(\"", m.content, "\")")
end
function Base.show(io::IO, ::MIME"text/plain", t::AbstractTracerMessage)
    dump(IOContext(io, :limit => true), t, maxdepth = 1)
end
function Base.show(io::IO, ::MIME"text/plain", t::AbstractTracer)
    dump(IOContext(io, :limit => true), t, maxdepth = 1)
end

## Dispatch for render
# function render(schema::AbstractPromptSchema,
#         messages::Vector{<:AbstractMessage};
#         kwargs...)
#     render(schema, messages; kwargs...)
# end
