# Prompt Management with TextPrompts.jl - PromptingTools Integration
#
# This example shows how to manage prompts as text files with metadata
# and integrate them with PromptingTools.jl for clean, versioned workflows.
#
# TextPrompts.jl is part of a cross-language ecosystem - the same prompt files
# work with Python (textprompts) and TypeScript (@anthropic/textprompts) too!
# This enables teams to share prompts across different codebases.
#
# INSTALLATION
# ============
# using Pkg
# Pkg.add("TextPrompts")
#
# BENEFITS
# ========
# - Version control prompts in git (easy collaboration & history)
# - Catch placeholder typos before LLM calls execute
# - Track metadata: version, author, description
# - Separate prompt engineering from code
# - Cross-language: same prompts work in Python, TypeScript, and Julia
#
# Run: julia --project=. examples/working_with_textprompts.jl

using TextPrompts
using PromptingTools
using PromptingTools: SystemMessage, UserMessage

# Get the examples directory path
examples_dir = @__DIR__
prompts_dir = joinpath(examples_dir, "prompts")

# =============================================================================
# Example 1: Basic Integration - Load and format prompts
# =============================================================================
println("=" ^ 60)
println("Example 1: Basic Integration")
println("=" ^ 60)

# Load prompt templates from files
system_template = load_prompt(joinpath(prompts_dir, "expert_system.txt"))
user_template = load_prompt(joinpath(prompts_dir, "task_request.txt"))

println("\nLoaded templates:")
println("  System: ", system_template.meta.title)
println("  User: ", user_template.meta.title)
println("  System placeholders: ", system_template.placeholders)
println("  User placeholders: ", user_template.placeholders)

# Format templates and pipe to PromptingTools message types
system_msg = system_template(; role = "Julia expert", style = "concise") |> SystemMessage
user_msg = user_template(; task = "explain how macros work in Julia") |> UserMessage

println("\nCreated messages:")
println("  SystemMessage: ", system_msg.content)
println("  UserMessage: ", user_msg.content)

# =============================================================================
# Example 2: One-liner with Piping
# =============================================================================
println("\n" * "=" ^ 60)
println("Example 2: One-liner with Piping")
println("=" ^ 60)

# Elegant one-liner pattern for creating message arrays
messages = [
    load_prompt(joinpath(prompts_dir, "expert_system.txt"))(;
        role = "Python-to-Julia translator", style = "detailed") |> SystemMessage,
    load_prompt(joinpath(prompts_dir, "task_request.txt"))(;
        task = "convert this Python code to Julia: print('hello')") |> UserMessage
]

println("\nMessages created with pipe operator:")
for msg in messages
    println("  $(typeof(msg).name.name): $(first(msg.content, 60))...")
end

# =============================================================================
# Example 3: Dynamic Prompt Selection
# =============================================================================
println("\n" * "=" ^ 60)
println("Example 3: Dynamic Prompt Selection")
println("=" ^ 60)

# Load all templates from directory and index by title
all_templates = load_prompts(prompts_dir)
templates_by_title = Dict(p.meta.title => p for p in all_templates)

println("\nAvailable templates:")
for title in keys(templates_by_title)
    println("  - ", title)
end

# Select template dynamically based on use case
if haskey(templates_by_title, "Task Request")
    task_template = templates_by_title["Task Request"]
    msg = task_template(; task = "write a hello world function") |> UserMessage
    println("\nDynamically selected 'Task Request' template:")
    println("  ", msg.content)
end

# =============================================================================
# Example 4: Working with Prompt Strings Directly
# =============================================================================
println("\n" * "=" ^ 60)
println("Example 4: Working with Prompt Strings Directly")
println("=" ^ 60)

# Create a prompt from a string (no file needed) - useful for quick prototyping
inline_prompt = from_string("""
---
title = "Inline Example"
version = "1.0"
---
Calculate {operation} of {a} and {b}.
""")

println("\nInline prompt placeholders: ", inline_prompt.placeholders)
formatted = inline_prompt(; operation = "the sum", a = 5, b = 3)
println("Formatted: ", formatted)

# =============================================================================
# Example 5: Metadata Modes
# =============================================================================
println("\n" * "=" ^ 60)
println("Example 5: Metadata Modes")
println("=" ^ 60)

# IGNORE mode - treat file as plain text, use filename as title
ignored = load_prompt(joinpath(prompts_dir, "expert_system.txt"); meta = :ignore)
println("\nWith meta=:ignore:")
println("  Title: ", ignored.meta.title, " (from filename)")
println("  Content includes TOML header: ", startswith(ignored.content, "---"))

# =============================================================================
# Example 6: Calling the LLM (uncomment to run with API key)
# =============================================================================
println("\n" * "=" ^ 60)
println("Example 6: Calling the LLM")
println("=" ^ 60)

println("\nTo call the LLM, uncomment the code below.")
println("Make sure you have OPENAI_API_KEY set in your environment.")

# Uncomment to actually call the LLM:
# response = aigenerate(messages; model = "gpt4om")
# println("Response: ", response.content)

# =============================================================================
# Cross-Language Compatibility
# =============================================================================
println("\n" * "=" ^ 60)
println("Cross-Language Compatibility")
println("=" ^ 60)

println("""
The same prompt files work across languages:

  Python:     pip install textprompts
              from textprompts import load_prompt
              prompt = load_prompt("prompts/expert_system.txt")

  TypeScript: npm install @anthropic/textprompts
              import { loadPrompt } from '@anthropic/textprompts'
              const prompt = loadPrompt("prompts/expert_system.txt")

  Julia:      using TextPrompts
              prompt = load_prompt("prompts/expert_system.txt")

This enables teams to share prompts across different codebases!
""")

println("=" ^ 60)
println("Done! See the prompts/ folder for example prompt files.")
println("=" ^ 60)
