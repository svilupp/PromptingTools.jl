# This file contains key building blocks of conversation history (messages) and utilities to work with them (eg, render)

## Messages
abstract type AbstractMessage end
abstract type AbstractChatMessage <: AbstractMessage end # with text-based content
abstract type AbstractDataMessage <: AbstractMessage end # with data-based content, eg, embeddings

Base.@kwdef mutable struct SystemMessage{T <: AbstractString} <: AbstractChatMessage
    content::T
    variables::Vector{Symbol} = _extract_handlebar_variables(content)
end
Base.@kwdef mutable struct UserMessage{T <: AbstractString} <: AbstractChatMessage
    content::T
    variables::Vector{Symbol} = _extract_handlebar_variables(content)
end
Base.@kwdef struct AIMessage{T <: Union{AbstractString, Nothing}} <: AbstractChatMessage
    content::T = nothing
    status::Union{Int, Nothing} = nothing
    tokens::Tuple{Int, Int} = (-1, -1)
    elapsed::Float64 = -1.0
end
Base.@kwdef mutable struct DataMessage{T <: Any} <: AbstractDataMessage
    content::T
    status::Union{Int, Nothing} = nothing
    tokens::Tuple{Int, Int} = (-1, -1)
    elapsed::Float64 = -1.0
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

## Prompt Templates
# ie, a way to re-use similar prompting patterns (eg, aiclassifier)
# flow: template -> messages |+ kwargs variables -> chat history
# Defined through Val() to allow for dispatch
function render(prompt_schema::AbstractOpenAISchema, template::Val{:IsStatementTrue})
    [
        SystemMessage("You are an impartial AI judge evaluting whether the provided statement is \"true\" or \"false\". Answer \"unknown\" if you cannot decide."),
        UserMessage("##Statement\n\n{{statement}}"),
    ]
end
