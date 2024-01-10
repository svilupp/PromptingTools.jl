```@meta
CurrentModule = PromptingTools
```

# PromptingTools

Documentation for [PromptingTools](https://github.com/svilupp/PromptingTools.jl).

Streamline your life using PromptingTools.jl, the Julia package that simplifies interacting with large language models.

PromptingTools.jl is not meant for building large-scale systems. It's meant to be the go-to tool in your global environment that will save you 20 minutes every day!

## Why PromptingTools.jl?

Prompt engineering is neither fast nor easy. Moreover, different models and their fine-tunes might require different prompt formats and tricks, or perhaps the information you work with requires special models to be used. PromptingTools.jl is meant to unify the prompts for different backends and make the common tasks (like templated prompts) as simple as possible. 

Some features:
- **`aigenerate` Function**: Simplify prompt templates with handlebars (eg, `{{variable}}`) and keyword arguments
- **`@ai_str` String Macro**: Save keystrokes with a string macro for simple prompts
- **Easy to Remember**: All exported functions start with `ai...` for better discoverability
- **Light Wrapper Types**: Benefit from Julia's multiple dispatch by having AI outputs wrapped in specific types
- **Minimal Dependencies**: Enjoy an easy addition to your global environment with very light dependencies
- **No Context Switching**: Access cutting-edge LLMs with no context switching and minimum extra keystrokes directly in your REPL

## First Steps

To get started, see the [Getting Started](@ref) section.
