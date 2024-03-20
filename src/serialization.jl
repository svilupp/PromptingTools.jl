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
