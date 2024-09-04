# # PromptingTools.jl Cheat Sheet
# PromptingTools.jl: A Julia package for easy interaction with AI language models.
# Provides convenient macros and functions for text generation, data extraction, and more.

# Installation and Setup
using Pkg
Pkg.add("PromptingTools")
using PromptingTools
const PT = PromptingTools # Optional alias for convenience

# Set OpenAI API key (or use ENV["OPENAI_API_KEY"])
PT.set_preferences!("OPENAI_API_KEY" => "your-api-key")

# Basic Usage

# Simple query using string macro
ai"What is the capital of France?"

# With variable interpolation
country = "Spain"
ai"What is the capital of $(country)?"

# Using a specific model (e.g., GPT-4)
ai"Explain quantum computing"gpt4

# Asynchronous call (non-blocking)
aai"Say hi but slowly!"gpt4

# Available Functions

# Text Generation
aigenerate(prompt; model = "gpt-3.5-turbo", kwargs...)
aigenerate(template::Symbol; variables..., model = "gpt-3.5-turbo", kwargs...)

# String Macro for Quick Queries
ai"Your prompt here"
ai"Your prompt here"gpt4  # Specify model

# Asynchronous Queries
aai"Your prompt here"
aai"Your prompt here"gpt4

# Data Extraction
aiextract(prompt; return_type = YourStructType, model = "gpt-3.5-turbo", kwargs...)

# Classification
aiclassify(
    prompt; choices = ["true", "false", "unknown"], model = "gpt-3.5-turbo", kwargs...)

# Embeddings
aiembed(text, [normalization_function]; model = "text-embedding-ada-002", kwargs...)

# Image Analysis
aiscan(prompt; image_path = path_to_image, model = "gpt-4-vision-preview", kwargs...)

# Template Discovery
aitemplates(search_term::String)
aitemplates(template_name::Symbol)

# Advanced Usage

# Template-based generation
msg = aigenerate(:JuliaExpertAsk; ask = "How do I add packages?")

# Data extraction
struct CurrentWeather
    location::String
    unit::Union{Nothing, TemperatureUnits}
end
msg = aiextract("What's the weather in New York in F?"; return_type = CurrentWeather)

# Simplest data extraction - all fields assumed to be of type String
msg = aiextract(
    "What's the weather in New York in F?"; return_type = [:location, :unit, :temperature])

# Data extraction with pair syntax to specify the exact type or add a field-level description, notice the fieldname__description format
msg = aiextract("What's the weather in New York in F?";
    return_type = [
        :location => String,
        :location__description => "The city or location for the weather report",
        :temperature => Float64,
        :temperature__description => "The current temperature",
        :unit => String,
        :unit__description => "The temperature unit (e.g., Fahrenheit, Celsius)"
    ])

# Classification
aiclassify("Is two plus two four?")

# Embeddings
embedding = aiembed("The concept of AI").content

# Image analysis
msg = aiscan("Describe the image"; image_path = "julia.png", model = "gpt4v")

# Working with Conversations

# Create a conversation
conversation = [
    SystemMessage("You're master Yoda from Star Wars."),
    UserMessage("I have feelings for my {{object}}. What should I do?")]

# Generate response
msg = aigenerate(conversation; object = "old iPhone")

# Continue the conversation
new_conversation = vcat(conversation..., msg, UserMessage("Thank you, master Yoda!"))
aigenerate(new_conversation)

# Create a New Template
# Basic usage
create_template("You are a helpful assistant", "Translate '{{text}}' to {{language}}")

# With default system message
create_template(user = "Summarize {{article}}")

# Load template into memory
create_template("You are a poet", "Write a poem about {{topic}}"; load_as = :PoetryWriter)

# Use placeholders
create_template("You are a chef", "Create a recipe for {{dish}} with {{ingredients}}")

# Save template to file
save_template("templates/ChefRecipe.json", chef_template)

# Load saved templates
load_templates!("path/to/templates")

# Use created templates
aigenerate(template; variable1 = "value1", variable2 = "value2")
aigenerate(:TemplateName; variable1 = "value1", variable2 = "value2")

# Using Templates

# List available templates
tmps = aitemplates("Julia")

# Use a template
msg = aigenerate(:JuliaExpertAsk; ask = "How do I add packages?")

# Inspect a template
AITemplate(:JudgeIsItTrue) |> PromptingTools.render

# Providing Variables for Placeholders

# Simple variable substitution
aigenerate("Say hello to {{name}}!", name = "World")

# Using a template with multiple variables
aigenerate(:TemplateNameHere;
    variable1 = "value1",
    variable2 = "value2"
)

# Example with a complex template
conversation = [
    SystemMessage("You're master {{character}} from {{universe}}."),
    UserMessage("I have feelings for my {{object}}. What should I do?")]
msg = aigenerate(conversation;
    character = "Yoda",
    universe = "Star Wars",
    object = "old iPhone"
)

# Working with Different Model Providers

# OpenAI (default)
ai"Hello, world!"

# Ollama (local models)
schema = PT.OllamaSchema()
msg = aigenerate(schema, "Say hi!"; model = "openhermes2.5-mistral")
# Or use registered models directly:
msg = aigenerate("Say hi!"; model = "openhermes2.5-mistral")

# MistralAI
msg = aigenerate("Say hi!"; model = "mistral-tiny")

# Anthropic (Claude models)
ai"Say hi!"claudeh  # Claude 3 Haiku
ai"Say hi!"claudes  # Claude 3 Sonnet
ai"Say hi!"claudeo  # Claude 3 Opus

# Custom OpenAI-compatible APIs
schema = PT.CustomOpenAISchema()
msg = aigenerate(schema, prompt;
    model = "my_model",
    api_key = "your_key",
    api_kwargs = (; url = "http://your_api_url")
)

# Experimental Features

using PromptingTools.Experimental.AgentTools

# Lazy evaluation
out = AIGenerate("Say hi!"; model = "gpt4t")
run!(out)

# Retry with conditions
airetry!(condition_function, aicall::AICall, feedback_function)

# Example:
airetry!(x -> length(split(last_output(x))) == 1, out,
    "You must answer with 1 word only.")

# Retry with do-syntax
airetry!(out, "You must answer with 1 word only.") do aicall
    length(split(last_output(aicall))) == 1
end

# Utility Functions

# Save conversations for fine-tuning
PT.save_conversation("filename.json", conversation)
PT.save_conversations("dataset.jsonl", [conversation1, conversation2])

# Set API key preferences
PT.set_preferences!("OPENAI_API_KEY" => "your-api-key")

# Get current preferences
PT.get_preferences("OPENAI_API_KEY")
