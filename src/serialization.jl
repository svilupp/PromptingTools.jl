## Loading / Saving
"""
    save_template(io_or_file::Union{IO, AbstractString},
        messages::AbstractVector{<:AbstractChatMessage};
        content::AbstractString = "Template Metadata",
        description::AbstractString = "",
        version::AbstractString = "1",
        source::AbstractString = "")

Saves provided messaging template (`messages`) to `io_or_file`. Automatically adds metadata based on provided keyword arguments.
"""
function save_template(io_or_file::Union{IO, AbstractString},
        messages::AbstractVector{<:AbstractChatMessage};
        content::AbstractString = "Template Metadata",
        description::AbstractString = "",
        version::AbstractString = "1",
        source::AbstractString = "")

    # create metadata
    metadata_msg = MetadataMessage(; content, description, version, source)

    # save template to IO or file
    JSON3.write(io_or_file, [metadata_msg, messages...])
end
"""
    load_template(io_or_file::Union{IO, AbstractString})

Loads messaging template from `io_or_file` and returns tuple of template messages and metadata.
"""
function load_template(io_or_file::Union{IO, AbstractString})
    messages = JSON3.read(io_or_file, Vector{AbstractChatMessage})
    template, metadata = AbstractChatMessage[], MetadataMessage[]
    for i in eachindex(messages)
        msg = messages[i]
        if msg isa MetadataMessage
            push!(metadata, msg)
        else
            push!(template, msg)
        end
    end
    return template, metadata
end

## Variants without metadata:
"""
    save_conversation(io_or_file::Union{IO, AbstractString},
        messages::AbstractVector{<:AbstractMessage})

Saves provided conversation (`messages`) to `io_or_file`. If you need to add some metadata, see `save_template`.
"""
function save_conversation(io_or_file::Union{IO, AbstractString},
        messages::AbstractVector{<:AbstractMessage})
    JSON3.write(io_or_file, messages)
end
"""
    load_conversation(io_or_file::Union{IO, AbstractString})

Loads a conversation (`messages`) from `io_or_file`
"""
function load_conversation(io_or_file::Union{IO, AbstractString})
    messages = JSON3.read(io_or_file, Vector{AbstractMessage})
end

"""
    save_conversations(schema::AbstractPromptSchema, filename::AbstractString,
        conversations::Vector{<:AbstractVector{<:PT.AbstractMessage}})

Saves provided conversations (vector of vectors of `messages`) to `filename` rendered in the particular `schema`. 

Commonly used for finetuning models with `schema = ShareGPTSchema()`

The format is JSON Lines, where each line is a JSON object representing one provided conversation.

See also: `save_conversation`

# Examples

You must always provide a VECTOR of conversations
```julia
messages = AbstractMessage[SystemMessage("System message 1"),
    UserMessage("User message"),
    AIMessage("AI message")]
conversation = [messages] # vector of vectors

dir = tempdir()
fn = joinpath(dir, "conversations.jsonl")
save_conversations(fn, conversation)

# Content of the file (one line for each conversation)
# {"conversations":[{"value":"System message 1","from":"system"},{"value":"User message","from":"human"},{"value":"AI message","from":"gpt"}]}
```
"""
function save_conversations(schema::AbstractPromptSchema, filename::AbstractString,
        conversations::Vector{<:AbstractVector{<:AbstractMessage}})
    @assert endswith(filename, ".jsonl") "Filename must end with `.jsonl` (JSON Lines format)."
    io = IOBuffer()
    for i in eachindex(conversations)
        conv = conversations[i]
        rendered_conv = render(schema, conv)
        JSON3.write(io, rendered_conv)
        # separate each conversation by newline
        i < length(conversations) && print(io, "\n")
    end
    write(filename, String(take!(io)))
    return nothing
end

# shortcut for ShareGPTSchema
function save_conversations(filename::AbstractString,
        conversations::Vector{<:AbstractVector{<:AbstractMessage}})
    save_conversations(ShareGPTSchema(), filename, conversations)
end
