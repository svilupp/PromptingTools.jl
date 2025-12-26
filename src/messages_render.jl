function role4render(schema::AbstractPromptSchema, msg::AbstractTracerMessage)
    role4render(schema, msg.object)
end
function render(schema::AbstractPromptSchema, msg::AbstractMessage; kwargs...)
    render(schema, [msg]; kwargs...)
end
function render(schema::AbstractPromptSchema, msg::AbstractString;
        name_user::Union{Nothing, String} = nothing, kwargs...)
    render(schema, [UserMessage(; content = msg, name = name_user)]; kwargs...)
end

## Serialization via JSON3
StructTypes.StructType(::Type{AbstractMessage}) = StructTypes.AbstractType()
StructTypes.subtypekey(::Type{AbstractMessage}) = :_type
function StructTypes.subtypes(::Type{AbstractMessage})
    (usermessage = UserMessage,
        usermessagewithimages = UserMessageWithImages,
        aimessage = AIMessage,
        toolmessage = ToolMessage,
        aitoolrequest = AIToolRequest,
        systemmessage = SystemMessage,
        metadatamessage = MetadataMessage,
        datamessage = DataMessage,
        tracermessage = TracerMessage,
        annotationmessage = AnnotationMessage)
end

StructTypes.StructType(::Type{AbstractChatMessage}) = StructTypes.AbstractType()
StructTypes.subtypekey(::Type{AbstractChatMessage}) = :_type
function StructTypes.subtypes(::Type{AbstractChatMessage})
    (usermessage = UserMessage,
        usermessagewithimages = UserMessageWithImages,
        aimessage = AIMessage,
        systemmessage = SystemMessage,
        metadatamessage = MetadataMessage,
        annotationmessage = AnnotationMessage)
end

StructTypes.StructType(::Type{AbstractAnnotationMessage}) = StructTypes.AbstractType()
StructTypes.subtypekey(::Type{AbstractAnnotationMessage}) = :_type
function StructTypes.subtypes(::Type{AbstractAnnotationMessage})
    (annotationmessage = AnnotationMessage,)
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

StructTypes.StructType(::Type{TokenUsage}) = StructTypes.Struct()
StructTypes.StructType(::Type{MetadataMessage}) = StructTypes.Struct()
StructTypes.StructType(::Type{SystemMessage}) = StructTypes.Struct()
StructTypes.StructType(::Type{UserMessage}) = StructTypes.Struct()
StructTypes.StructType(::Type{UserMessageWithImages}) = StructTypes.Struct()
StructTypes.StructType(::Type{ToolMessage}) = StructTypes.Struct()
StructTypes.StructType(::Type{AIToolRequest}) = StructTypes.Struct()
StructTypes.StructType(::Type{AIMessage}) = StructTypes.Struct()
StructTypes.StructType(::Type{DataMessage}) = StructTypes.Struct()
StructTypes.StructType(::Type{AnnotationMessage}) = StructTypes.Struct()
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
    elseif msg isa AIToolRequest
        "AI Tool Request"
    elseif msg isa ToolMessage
        "Tool Message"
    elseif msg isa AnnotationMessage
        "Annotation Message"
    else
        "Unknown Message"
    end
    content = if msg isa DataMessage
        length_ = msg.content isa AbstractArray ? " (Size: $(size(msg.content)))" : ""
        "Data: $(typeof(msg.content))$(length_)"
    elseif isaitoolrequest(msg)
        if isnothing(msg.content)
            join(
                ["Tool Request: $(tool.name), args: $(tool.args)"
                 for (tool) in msg.tool_calls],
                "\n")
        else
            wrap_string(msg.content, text_width)
        end
    elseif istoolmessage(msg)
        isnothing(msg.content) ? string("Name: ", msg.name, ", Args: ", msg.raw) :
        string(msg.content)
    elseif isabstractannotationmessage(msg)
        tags_str = isempty(msg.tags) ? "" : "\n [$(join(msg.tags, ", "))]"
        comment_str = isempty(msg.comment) ? "" : "\n ($(msg.comment))"
        "$(msg.content)$tags_str$comment_str"
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
