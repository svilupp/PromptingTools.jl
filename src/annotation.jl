"""
    annotate!(messages::AbstractVector{<:AbstractMessage}, content; kwargs...)
    annotate!(message::AbstractMessage, content; kwargs...)

Add an annotation message to a vector of messages or wrap a single message in a vector with an annotation.
The annotation is always inserted after any existing annotation messages.

# Arguments
- `messages`: Vector of messages or single message to annotate
- `content`: Content of the annotation
- `kwargs...`: Additional fields for the AnnotationMessage (extras, tags, comment)

# Returns
Vector{AbstractMessage} with the annotation message inserted

# Example
```julia
messages = [SystemMessage("Assistant"), UserMessage("Hello")]
annotate!(messages, "This is important"; tags=[:important], comment="For review")
```
"""
function annotate!(messages::AbstractVector{T}, content::AbstractString;
        kwargs...) where {T <: AbstractMessage}
    # Convert to Vector{AbstractMessage} if needed
    messages_abstract = T == AbstractMessage ? messages :
                        convert(Vector{AbstractMessage}, messages)

    # Find last annotation message index
    last_anno_idx = findlast(isabstractannotationmessage, messages_abstract)
    insert_idx = isnothing(last_anno_idx) ? 1 : last_anno_idx + 1

    # Create and insert annotation message
    anno = AnnotationMessage(; content = content, kwargs...)
    insert!(messages_abstract, insert_idx, anno)
    return messages_abstract
end

function annotate!(message::AbstractMessage, content::AbstractString; kwargs...)
    return annotate!(AbstractMessage[message], content; kwargs...)
end
