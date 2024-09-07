# PromptingTools.jl Cheat Sheet

PromptingTools.jl is a Julia package for easy interaction with AI language models. It provides convenient macros and functions for text generation, data extraction, and more.

## Installation and Setup

```julia
# Install and set up PromptingTools.jl with your API key
using Pkg
Pkg.add("PromptingTools")
using PromptingTools
const PT = PromptingTools # Optional alias for convenience

# Set OpenAI API key (or use ENV["OPENAI_API_KEY"])
PT.set_preferences!("OPENAI_API_KEY" => "your-api-key")
```

## Basic Usage

### Simple query using string macro
```julia
# Quick, one-off queries to the AI model
ai"What is the capital of France?"
```

### With variable interpolation
```julia
# Dynamically include Julia variables in your prompts
country = "Spain"
ai"What is the capital of $(country)?"
```

### Using a specific model (e.g., GPT-4)
```julia
# Specify a different model for more complex queries
ai"Explain quantum computing"gpt4
```

### Asynchronous call (non-blocking)
```julia
# Use for longer running queries to avoid blocking execution
aai"Say hi but slowly!"gpt4
```

## Available Functions

### Text Generation
```julia
# Generate text using a prompt or a predefined template
aigenerate(prompt; model = "gpt-3.5-turbo", kwargs...)
aigenerate(template::Symbol; variables..., model = "gpt-3.5-turbo", kwargs...)
```

### String Macro for Quick Queries
```julia
# Shorthand for quick, simple queries
ai"Your prompt here"
ai"Your prompt here"gpt4  # Specify model
```

### Asynchronous Queries
```julia
# Non-blocking queries for longer running tasks
aai"Your prompt here"
aai"Your prompt here"gpt4
```

### Data Extraction
```julia
# Extract structured data from unstructured text
aiextract(prompt; return_type = YourStructType, model = "gpt-3.5-turbo", kwargs...)
```

### Classification
```julia
# Classify text into predefined categories
aiclassify(prompt; choices = ["true", "false", "unknown"], model = "gpt-3.5-turbo", kwargs...)
```

### Embeddings
```julia
# Generate vector representations of text for similarity comparisons
aiembed(text, [normalization_function]; model = "text-embedding-ada-002", kwargs...)
```

### Image Analysis
```julia
# Analyze and describe images using AI vision models
aiscan(prompt; image_path = path_to_image, model = "gpt-4-vision-preview", kwargs...)
```

### Template Discovery
```julia
# Find and explore available templates
aitemplates(search_term::String)
aitemplates(template_name::Symbol)
```

## Advanced Usage

### Template-based generation
```julia
# Use predefined templates for consistent query structures
msg = aigenerate(:JuliaExpertAsk; ask = "How do I add packages?")
```

### Data extraction
```julia
# Define custom structures for extracted data
struct CurrentWeather
    location::String
    unit::Union{Nothing, TemperatureUnits}
end
msg = aiextract("What's the weather in New York in F?"; return_type = CurrentWeather)

# Simple data extraction with assumed String types
msg = aiextract(
    "What's the weather in New York in F?"; 
    return_type = [:location, :unit, :temperature]
)

# Detailed data extraction with type specifications and descriptions
msg = aiextract("What's the weather in New York in F?";
    return_type = [
        :location => String,
        :location__description => "The city or location for the weather report",
        :temperature => Float64,
        :temperature__description => "The current temperature",
        :unit => String,
        :unit__description => "The temperature unit (e.g., Fahrenheit, Celsius)"
    ])
```

### Classification
```julia
# Perform simple classification tasks
aiclassify("Is two plus two four?")
```

### Embeddings
```julia
# Generate and use text embeddings for various NLP tasks
embedding = aiembed("The concept of AI").content
```

### Image analysis
```julia
# Analyze images and generate descriptions
msg = aiscan("Describe the image"; image_path = "julia.png", model = "gpt4v")
```

## Working with Conversations

```julia
# Create multi-turn conversations with AI models
conversation = [
    SystemMessage("You're master Yoda from Star Wars."),
    UserMessage("I have feelings for my {{object}}. What should I do?")
]

# Generate a response within the conversation context
msg = aigenerate(conversation; object = "old iPhone")

# Continue and extend the conversation
new_conversation = vcat(conversation..., msg, UserMessage("Thank you, master Yoda!"))
aigenerate(new_conversation)
```

## Creating and Using Templates

### Create a New Template
```julia
# Define reusable templates for common query patterns
tpl = create_template("You are a helpful assistant", "Translate '{{text}}' to {{language}}")

# Create a template with a default system message
tpl = create_template(; user = "Summarize {{article}}")

# Create and immediately load a template into memory
tpl = create_template("You are a poet", "Write a poem about {{topic}}"; load_as = :PoetryWriter)

# Create a template with multiple placeholders
tpl = create_template(; system = "You are a chef", user = "Create a recipe for {{dish}} with {{ingredients}}")

# Save a template to a file for later use
save_template("templates/ChefRecipe.json", tpl)

# Load previously saved templates
tpl = load_templates!("path/to/templates")
```

### Using Templates
```julia
# Find templates matching a search term
tmps = aitemplates("Julia")

# Use a predefined template
msg = aigenerate(:JuliaExpertAsk; ask = "How do I add packages?")

# Inspect the content of a template
AITemplate(:JudgeIsItTrue) |> PromptingTools.render

# Use a template with a single variable
aigenerate("Say hello to {{name}}!", name = "World")

# Use a template with multiple variables
aigenerate(:TemplateNameHere;
    variable1 = "value1",
    variable2 = "value2"
)

# Use a complex template with multiple placeholders
conversation = [
    SystemMessage("You're master {{character}} from {{universe}}."),
    UserMessage("I have feelings for my {{object}}. What should I do?")
]
msg = aigenerate(conversation;
    character = "Yoda",
    universe = "Star Wars",
    object = "old iPhone"
)
```

## Working with Different Model Providers

```julia
# Use the default OpenAI model
ai"Hello, world!"

# Use local models with Ollama
schema = PT.OllamaSchema()
msg = aigenerate(schema, "Say hi!"; model = "openhermes2.5-mistral")
# Or use registered models directly:
msg = aigenerate("Say hi!"; model = "openhermes2.5-mistral")

# Use MistralAI models
msg = aigenerate("Say hi!"; model = "mistral-tiny")

# Use Anthropic's Claude models
ai"Say hi!"claudeh  # Claude 3 Haiku
ai"Say hi!"claudes  # Claude 3 Sonnet
ai"Say hi!"claudeo  # Claude 3 Opus

# Use custom OpenAI-compatible APIs
schema = PT.CustomOpenAISchema()
msg = aigenerate(schema, prompt;
    model = "my_model",
    api_key = "your_key",
    api_kwargs = (; url = "http://your_api_url")
)
```

## Experimental Features

```julia
# Import experimental features
using PromptingTools.Experimental.AgentTools

# Use lazy evaluation for deferred execution
out = AIGenerate("Say hi!"; model = "gpt4t")
run!(out)

# Retry AI calls with custom conditions
airetry!(condition_function, aicall::AICall, feedback_function)

# Example of retry with a specific condition
airetry!(x -> length(split(last_output(x))) == 1, out,
    "You must answer with 1 word only.")

# Use do-syntax for more readable retry conditions
airetry!(out, "You must answer with 1 word only.") do aicall
    length(split(last_output(aicall))) == 1
end
```

## Utility Functions

```julia
# Save individual conversations for later use or fine-tuning
PT.save_conversation("filename.json", conversation)

# Save multiple conversations at once
PT.save_conversations("dataset.jsonl", [conversation1, conversation2])

# Set API key preferences
PT.set_preferences!("OPENAI_API_KEY" => "your-api-key")

# Retrieve current preference settings
PT.get_preferences("OPENAI_API_KEY")
```