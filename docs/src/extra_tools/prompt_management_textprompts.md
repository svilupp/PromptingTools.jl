# Prompt Management with TextPrompts.jl

[TextPrompts.jl](https://github.com/svilupp/textprompts/tree/main/packages/TextPrompts.jl) allows you to manage prompts as text files with optional TOML metadata. This enables version-controlled, collaborative prompt engineering that separates prompt content from code.

## Why TextPrompts.jl?

| Benefit | Description |
|---------|-------------|
| **Version Control** | Track prompt changes in git with full history and diffs |
| **Collaboration** | Team members can edit prompts without touching code |
| **Validation** | Catch placeholder typos before LLM calls execute |
| **Metadata** | Track version, author, description for each prompt |
| **Separation of Concerns** | Keep prompt engineering separate from application logic |
| **Cross-Language** | Same prompt files work in Python, TypeScript, and Julia |

## Cross-Language Ecosystem

TextPrompts is available across multiple languages, enabling teams to share prompts across different codebases:

| Language | Package | Installation |
|----------|---------|--------------|
| **Julia** | [TextPrompts.jl](https://github.com/svilupp/textprompts/tree/main/packages/TextPrompts.jl) | `Pkg.add("TextPrompts")` |
| **Python** | [textprompts](https://github.com/svilupp/textprompts/tree/main/packages/textprompts) | `pip install textprompts` |
| **TypeScript** | [@anthropic/textprompts](https://github.com/svilupp/textprompts/tree/main/packages/textprompts-ts) | `npm install @anthropic/textprompts` |

The same prompt files with TOML frontmatter work identically across all three languages!

## Installation

TextPrompts.jl is a separate package. Install it to enable prompt file management:

```julia
using Pkg
Pkg.add("TextPrompts")
```

## Quick Start

```julia
using TextPrompts
using PromptingTools

# Load a prompt template from file
prompt = load_prompt("prompts/system.txt")

# Format with placeholders and convert to PromptingTools message
system_msg = prompt(; role = "Julia expert", task = "explain macros") |> SystemMessage

# Use in aigenerate
response = aigenerate([system_msg, UserMessage("How do macros work?")]; model = "gpt4om")
```

## Prompt File Format

Prompts can include optional TOML frontmatter for metadata:

```
---
title = "Expert System Prompt"
version = "1.0"
author = "Team Name"
description = "A system prompt for expert assistance"
---
You are a {role}. Be {style} and helpful.
```

If no frontmatter is provided, the file is treated as plain text with the filename used as the title.

### Metadata Modes

TextPrompts supports three metadata handling modes:

| Mode | Behavior |
|------|----------|
| `:allow` (default) | Parse metadata if present, otherwise use filename as title |
| `:strict` | Require title, description, and version fields |
| `:ignore` | Treat entire file as content; use filename as title |

```julia
# Strict mode - requires all metadata fields
prompt = load_prompt("system.txt"; meta = :strict)

# Ignore mode - treat as plain text
prompt = load_prompt("system.txt"; meta = :ignore)
```

## Core API

### Loading Prompts

```julia
# Load a single prompt file
prompt = load_prompt("prompts/system.txt")

# Load all prompts from a directory
all_prompts = load_prompts("prompts/"; recursive = true)

# Create prompt from string (no file needed)
inline_prompt = from_string("""
---
title = "Inline Example"
---
Hello, {name}!
""")
```

### Accessing Prompt Data

```julia
prompt = load_prompt("greeting.txt")

# Access raw content
println(prompt.content)

# Access metadata
println(prompt.meta.title)
println(prompt.meta.version)
println(prompt.meta.description)

# See available placeholders
println(prompt.placeholders)  # e.g., [:name, :day]
```

### Formatting with Placeholders

```julia
prompt = load_prompt("greeting.txt")

# Format by calling as a function
formatted = prompt(; name = "World", day = "Monday")

# Partial formatting (skip validation for missing placeholders)
partial = prompt(; name = "World", skip_validation = true)

# Alternative: use TextPrompts.format explicitly
formatted2 = TextPrompts.format(prompt; name = "World", day = "Monday")
```

### Integration with PromptingTools

The pipe operator `|>` creates a seamless workflow:

```julia
using TextPrompts
using PromptingTools
using PromptingTools: SystemMessage, UserMessage

# One-liner pattern for creating message arrays
messages = [
    load_prompt("system.txt")(; role = "Expert") |> SystemMessage,
    load_prompt("task.txt")(; task = "explain closures") |> UserMessage
]

response = aigenerate(messages; model = "gpt4om")
```

### Dynamic Prompt Selection

```julia
# Load all templates and index by title
templates = load_prompts("prompts/")
by_title = Dict(p.meta.title => p for p in templates)

# Select based on runtime conditions
template_name = determine_template()  # your logic
prompt = by_title[template_name]
msg = prompt(; task = "some task") |> UserMessage
```

### Saving Prompts

```julia
# Save a prompt string to file
save_prompt("output.txt", "Hello, {name}!")

# Save a prompt object
prompt = from_string("Hello, {name}!")
save_prompt("output.txt", prompt)
```

## Combining with Logfire.jl

TextPrompts.jl works seamlessly with [Logfire.jl observability](observability_logfire.md):

```julia
using TextPrompts, PromptingTools, Logfire

Logfire.configure(service_name = "my-app")
Logfire.instrument_promptingtools!()

# Prompts from files are automatically traced
msg = load_prompt("task.txt")(; task = "analyze data") |> UserMessage
response = aigenerate(msg; model = "gpt4om")
# Traces include full conversation with formatted prompts
```

## Recommended Workflow

1. **Store prompts in a `prompts/` directory** in your project
2. **Use TOML frontmatter** for metadata (version, description, author)
3. **Version control with git** to track changes and collaborate
4. **Load dynamically** based on use case or user input
5. **Combine with Logfire.jl** for full observability of your LLM calls

This workflow enables continuous prompt improvement: version prompts in git, trace calls in Logfire, and iterate based on real-world performance.

## Example

See the full example at [`examples/working_with_textprompts.jl`](https://github.com/svilupp/PromptingTools.jl/blob/main/examples/working_with_textprompts.jl).

## Further Reading

- [TextPrompts.jl GitHub](https://github.com/svilupp/textprompts/tree/main/packages/TextPrompts.jl)
- [Discourse Announcement](https://discourse.julialang.org/t/announcing-logfire-jl-textprompts-jl-observability-and-prompt-management-for-julia-genai/134268)
- [Logfire.jl Observability](observability_logfire.md)
