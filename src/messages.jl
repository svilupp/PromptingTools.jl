# This file contains key building blocks of conversation history (messages) and utilities to work with them (eg, render)

## Messages
abstract type AbstractMessage end
abstract type AbstractChatMessage <: AbstractMessage end # with text-based content
abstract type AbstractDataMessage <: AbstractMessage end # with data-based content, eg, embeddings

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
end
Base.@kwdef struct UserMessage{T <: AbstractString} <: AbstractChatMessage
    content::T
    variables::Vector{Symbol} = _extract_handlebar_variables(content)
    _type::Symbol = :usermessage
end
Base.@kwdef struct AIMessage{T <: Union{AbstractString, Nothing}} <: AbstractChatMessage
    content::T = nothing
    status::Union{Int, Nothing} = nothing
    tokens::Tuple{Int, Int} = (-1, -1)
    elapsed::Float64 = -1.0
    _type::Symbol = :aimessage
end
Base.@kwdef struct DataMessage{T <: Any} <: AbstractDataMessage
    content::T
    status::Union{Int, Nothing} = nothing
    tokens::Tuple{Int, Int} = (-1, -1)
    elapsed::Float64 = -1.0
    _type::Symbol = :datamessage
end

# content-only constructor
function (MSG::Type{<:AbstractChatMessage})(s::AbstractString)
    MSG(; content = s)
end

# equality check for testing, only equal if all fields are equal and type is the same
Base.var"=="(m1::AbstractMessage, m2::AbstractMessage) = false
function Base.var"=="(m1::T, m2::T) where {T <: AbstractMessage}
    all([getproperty(m1, f) == getproperty(m2, f) for f in fieldnames(T)])
end

function Base.show(io::IO, ::MIME"text/plain", m::AbstractChatMessage)
    type_ = string(typeof(m)) |> x -> split(x, "{")[begin]
    if m isa AIMessage
        printstyled(io, type_; color = :magenta)
    elseif m isa SystemMessage
        printstyled(io, type_; color = :light_green)
    elseif m isa UserMessage
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
    size_str = (m.content) isa AbstractArray ? string(size(m.content)) : "-"
    print(io, "(", typeof(m.content), " of size ", size_str, ")")
end

## Dispatch for render
function render(schema::AbstractPromptSchema,
        messages::Vector{<:AbstractMessage};
        kwargs...)
    render(schema, messages; kwargs...)
end
function render(schema::AbstractPromptSchema, msg::AbstractMessage; kwargs...)
    render(schema, [msg]; kwargs...)
end
function render(schema::AbstractPromptSchema, msg::AbstractString; kwargs...)
    render(schema, [UserMessage(; content = msg)]; kwargs...)
end

## Serialization via JSON3
StructTypes.StructType(::Type{AbstractChatMessage}) = StructTypes.AbstractType()
StructTypes.StructType(::Type{MetadataMessage}) = StructTypes.Struct()
StructTypes.StructType(::Type{SystemMessage}) = StructTypes.Struct()
StructTypes.StructType(::Type{UserMessage}) = StructTypes.Struct()
StructTypes.StructType(::Type{AIMessage}) = StructTypes.Struct()
StructTypes.subtypekey(::Type{AbstractChatMessage}) = :_type
function StructTypes.subtypes(::Type{AbstractChatMessage})
    (usermessage = UserMessage,
        aimessage = AIMessage,
        systemmessage = SystemMessage,
        metadatamessage = MetadataMessage)
end