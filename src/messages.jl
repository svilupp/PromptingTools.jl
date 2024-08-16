# This file contains key building blocks of conversation history (messages) and utilities to work with them (eg, render)

## Messages
abstract type AbstractMessage end
abstract type AbstractChatMessage <: AbstractMessage end # with text-based content
abstract type AbstractDataMessage <: AbstractMessage end # with data-based content, eg, embeddings
abstract type AbstractTracerMessage{T <: AbstractMessage} <: AbstractMessage end # message with annotation that exposes the underlying message
# Complementary type for tracing, follows the same API as TracerMessage
abstract type AbstractTracer{T <: Any} end

## Allowed inputs for ai* functions, AITemplate is resolved one level higher
const ALLOWED_PROMPT_TYPE = Union{
    AbstractString,
    AbstractMessage,
    Vector{<:AbstractMessage}
}

# Workaround to be able to add metadata to serialized conversations, templates, etc.
# Ignored by `render` directives
Base.@kwdef struct MetadataMessage{T <: AbstractString} <: AbstractChatMessage
    content::T
    description::String = ""
    version::String = "1"
    source::String = ""
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
Base.@kwdef struct UserMessage{T <: AbstractString} <: AbstractChatMessage
    content::T
    variables::Vector{Symbol} = _extract_handlebar_variables(content)
    _type::Symbol = :usermessage
    UserMessage{T}(c, v, t) where {T <: AbstractString} = new(c, v, t)
end
function UserMessage(content::T,
        variables::Vector{Symbol},
        type::Symbol) where {T <: AbstractString}
    not_allowed_kwargs = intersect(variables, RESERVED_KWARGS)
    @assert length(not_allowed_kwargs)==0 "Error: Some placeholders are invalid, as they are reserved for `ai*` functions. Change: $(join(not_allowed_kwargs,","))"
    return UserMessage{T}(content, variables, type)
end
Base.@kwdef struct UserMessageWithImages{T <: AbstractString} <: AbstractChatMessage
    content::T
    image_url::Vector{String} # no default! fail when not provided
    variables::Vector{Symbol} = _extract_handlebar_variables(content)
    _type::Symbol = :usermessagewithimages
    UserMessageWithImages{T}(c, i, v, t) where {T <: AbstractString} = new(c, i, v, t)
end
function UserMessageWithImages(content::T, image_url::Vector{<:AbstractString},
        variables::Vector{Symbol},
        type::Symbol) where {T <: AbstractString}
    not_allowed_kwargs = intersect(variables, RESERVED_KWARGS)
    @assert length(not_allowed_kwargs)==0 "Error: Some placeholders are invalid, as they are reserved for `ai*` functions. Change: $(join(not_allowed_kwargs,","))"
    return UserMessageWithImages{T}(content, string.(image_url), variables, type)
end

"""
    AIMessage

A message type for AI-generated text-based responses. 
Returned by `aigenerate`, `aiclassify`, and `aiscan` functions.
    
# Fields
- `content::Union{AbstractString, Nothing}`: The content of the message.
- `status::Union{Int, Nothing}`: The status of the message from the API.
- `tokens::Tuple{Int, Int}`: The number of tokens used (prompt,completion).
- `elapsed::Float64`: The time taken to generate the response in seconds.
- `cost::Union{Nothing, Float64}`: The cost of the API call (calculated with information from `MODEL_REGISTRY`).
- `log_prob::Union{Nothing, Float64}`: The log probability of the response.
- `extras::Union{Nothing, Dict{Symbol, Any}}`: A dictionary for additional metadata that is not part of the key message fields. Try to limit to a small number of items and singletons to be serializable.
- `finish_reason::Union{Nothing, String}`: The reason the response was finished.
- `run_id::Union{Nothing, Int}`: The unique ID of the run.
- `sample_id::Union{Nothing, Int}`: The unique ID of the sample (if multiple samples are generated, they will all have the same `run_id`).
"""
Base.@kwdef struct AIMessage{T <: Union{AbstractString, Nothing}} <: AbstractChatMessage
    content::T = nothing
    status::Union{Int, Nothing} = nothing
    tokens::Tuple{Int, Int} = (-1, -1)
    elapsed::Float64 = -1.0
    cost::Union{Nothing, Float64} = nothing
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
Returned by `aiextract`, and `aiextract` functions.
    
# Fields
- `content::Union{AbstractString, Nothing}`: The content of the message.
- `status::Union{Int, Nothing}`: The status of the message from the API.
- `tokens::Tuple{Int, Int}`: The number of tokens used (prompt,completion).
- `elapsed::Float64`: The time taken to generate the response in seconds.
- `cost::Union{Nothing, Float64}`: The cost of the API call (calculated with information from `MODEL_REGISTRY`).
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
    log_prob::Union{Nothing, Float64} = nothing
    extras::Union{Nothing, Dict{Symbol, Any}} = nothing
    finish_reason::Union{Nothing, String} = nothing
    run_id::Union{Nothing, Int} = Int(rand(Int16))
    sample_id::Union{Nothing, Int} = nothing
    _type::Symbol = :datamessage
end

### Other Message methods
# content-only constructor
function (MSG::Type{<:AbstractChatMessage})(prompt::AbstractString)
    MSG(; content = prompt)
end
function (MSG::Type{<:AbstractChatMessage})(msg::AbstractChatMessage)
    MSG(; msg.content)
end
function (MSG::Type{<:AbstractChatMessage})(msg::AbstractTracerMessage{<:AbstractChatMessage})
    MSG(; msg.content)
end

## It checks types so it should be defined for all inputs
isusermessage(m::Any) = m isa UserMessage
issystemmessage(m::Any) = m isa SystemMessage
isdatamessage(m::Any) = m isa DataMessage
isaimessage(m::Any) = m isa AIMessage
istracermessage(m::Any) = m isa AbstractTracerMessage
isusermessage(m::AbstractTracerMessage) = isusermessage(m.object)
issystemmessage(m::AbstractTracerMessage) = issystemmessage(m.object)
isdatamessage(m::AbstractTracerMessage) = isdatamessage(m.object)
isaimessage(m::AbstractTracerMessage) = isaimessage(m.object)

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
    return isnothing(msg) ? nothing : msg.content
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
    else
        print(io, "(", typeof(m.content), ")")
    end
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
function role4render(schema::AbstractPromptSchema, msg::AbstractTracerMessage)
    role4render(schema, msg.object)
end
function render(schema::AbstractPromptSchema, msg::AbstractMessage; kwargs...)
    render(schema, [msg]; kwargs...)
end
function render(schema::AbstractPromptSchema, msg::AbstractString; kwargs...)
    render(schema, [UserMessage(; content = msg)]; kwargs...)
end

## Serialization via JSON3
StructTypes.StructType(::Type{AbstractMessage}) = StructTypes.AbstractType()
StructTypes.subtypekey(::Type{AbstractMessage}) = :_type
function StructTypes.subtypes(::Type{AbstractMessage})
    (usermessage = UserMessage,
        usermessagewithimages = UserMessageWithImages,
        aimessage = AIMessage,
        systemmessage = SystemMessage,
        metadatamessage = MetadataMessage,
        datamessage = DataMessage,
        tracermessage = TracerMessage)
end

StructTypes.StructType(::Type{AbstractChatMessage}) = StructTypes.AbstractType()
StructTypes.subtypekey(::Type{AbstractChatMessage}) = :_type
function StructTypes.subtypes(::Type{AbstractChatMessage})
    (usermessage = UserMessage,
        usermessagewithimages = UserMessageWithImages,
        aimessage = AIMessage,
        systemmessage = SystemMessage,
        metadatamessage = MetadataMessage)
end

StructTypes.StructType(::Type{AbstractTracerMessage}) = StructTypes.AbstractType()
StructTypes.subtypekey(::Type{AbstractTracerMessage}) = :_type
function StructTypes.subtypes(::Type{AbstractTracerMessage})
    (tracermessage = TracerMessage,)
end

StructTypes.StructType(::Type{AbstractTracer}) = StructTypes.AbstractType()
StructTypes.subtypekey(::Type{AbstractTracer}) = :_type
function StructTypes.subtypes(::Type{AbstractTracer})
    (tracermessagelike = TracerMessageLike,)
end

StructTypes.StructType(::Type{MetadataMessage}) = StructTypes.Struct()
StructTypes.StructType(::Type{SystemMessage}) = StructTypes.Struct()
StructTypes.StructType(::Type{UserMessage}) = StructTypes.Struct()
StructTypes.StructType(::Type{UserMessageWithImages}) = StructTypes.Struct()
StructTypes.StructType(::Type{AIMessage}) = StructTypes.Struct()
StructTypes.StructType(::Type{DataMessage}) = StructTypes.Struct()
StructTypes.StructType(::Type{TracerMessage}) = StructTypes.Struct() # Ignore mutability once we serialize
StructTypes.StructType(::Type{TracerMessageLike}) = StructTypes.Struct() # Ignore mutability once we serialize

### Utilities for Pretty Printing
"""
    pprint(io::IO, msg::AbstractMessage; text_width::Int = displaysize(io)[2])

Pretty print a single `AbstractMessage` to the given IO stream.

`text_width` is the width of the text to be displayed. If not provided, it defaults to the width of the given IO stream and add `newline` separators as needed.
"""
function pprint(io::IO, msg::AbstractMessage; text_width::Int = displaysize(io)[2])
    ## never use extension, because we don't have good method for single message
    role = if msg isa Union{UserMessage, UserMessageWithImages}
        "User Message"
    elseif msg isa DataMessage
        "Data Message"
    elseif msg isa SystemMessage
        "System Message"
    elseif msg isa AIMessage
        "AI Message"
    else
        "Unknown Message"
    end
    content = if msg isa DataMessage
        length_ = msg.content isa AbstractArray ? " (Size: $(size(msg.content)))" : ""
        "Data: $(typeof(msg.content))$(length_)"
    else
        wrap_string(msg.content, text_width)
    end
    print(io, "-"^20, "\n")
    printstyled(io, role, color = :blue, bold = true)
    print(io, "\n", "-"^20, "\n")
    print(io, content, "\n\n")
end

function pprint(io::IO, t::Union{AbstractTracerMessage, AbstractTracer};
        text_width::Int = displaysize(io)[2])
    role = "$(nameof(typeof(t))) with:"
    print(io, "-"^20, "\n")
    print(io, role, "\n")
    pprint(io, unwrap(t); text_width)
end
"""
    pprint(io::IO, conversation::AbstractVector{<:AbstractMessage})

Pretty print a vector of `AbstractMessage` to the given IO stream.
"""
function pprint(
        io::IO, conversation::AbstractVector{<:AbstractMessage};
        text_width::Int = displaysize(io)[2])
    for msg in conversation
        pprint(io, msg; text_width)
    end
end
