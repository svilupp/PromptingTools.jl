module MarkdownPromptingToolsExt

using PromptingTools
using Markdown
const PT = PromptingTools

"""
    preview(msg::PT.AbstractMessage)

Render a single `AbstractMessage` as a markdown-formatted string, highlighting the role of the message sender and the content of the message.

This function identifies the type of the message (User, Data, System, AI, or Unknown) and formats it with a header indicating the sender's role, followed by the content of the message. The output is suitable for nicer rendering, especially in REPL or markdown environments.

# Arguments
- `msg::PT.AbstractMessage`: The message to be rendered.

# Returns
- `String`: A markdown-formatted string representing the message.

# Example
```julia
msg = PT.UserMessage("Hello, world!")
println(PT.preview(msg))
```

This will output:
```
# User Message
Hello, world!
```
"""
function PT.preview(msg::PT.AbstractMessage)
    role = if msg isa Union{PT.UserMessage, PT.UserMessageWithImages}
        "User Message"
    elseif msg isa PT.DataMessage
        "Data Message"
    elseif msg isa PT.SystemMessage
        "System Message"
    elseif msg isa PT.AIMessage
        "AI Message"
    else
        "Unknown Message"
    end
    content = if msg isa PT.DataMessage
        length_ = msg.content isa AbstractArray ? " (Size: $(size(msg.content)))" : ""
        "Data: $(typeof(msg.content))$(length_)"
    else
        msg.content
    end
    return """# $role\n$(content)\n\n"""
end

"""
    preview(conversation::AbstractVector{<:PT.AbstractMessage})

Render a conversation, which is a vector of `AbstractMessage` objects, as a single markdown-formatted string. Each message is rendered individually and concatenated with separators for clear readability.

This function is particularly useful for displaying the flow of a conversation in a structured and readable format. It leverages the `PT.preview` method for individual messages to create a cohesive view of the entire conversation.

# Arguments
- `conversation::AbstractVector{<:PT.AbstractMessage}`: A vector of messages representing the conversation.

# Returns
- `String`: A markdown-formatted string representing the entire conversation.

# Example
```julia
conversation = [
    PT.SystemMessage("Welcome"),
    PT.UserMessage("Hello"),
    PT.AIMessage("Hi, how can I help you?")
]
println(PT.preview(conversation))
```

This will output:
```
# System Message
Welcome
---
# User Message
Hello
---
# AI Message
Hi, how can I help you?
---
```
"""
function PT.preview(conversation::AbstractVector{<:PT.AbstractMessage})
    io = IOBuffer()
    print(io, join(PT.preview.(conversation), "---\n"))
    String(take!(io)) |> Markdown.parse
end

end # end of module
