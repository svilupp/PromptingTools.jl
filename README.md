# PromptingTools.jl: "Your Daily Dose of AI Efficiency."

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://svilupp.github.io/PromptingTools.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://svilupp.github.io/PromptingTools.jl/dev/)
[![Build Status](https://github.com/svilupp/PromptingTools.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/svilupp/PromptingTools.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/svilupp/PromptingTools.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/svilupp/PromptingTools.jl)
[![Aqua](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
[![SciML Code Style](https://img.shields.io/static/v1?label=code%20style&message=SciML&color=9558b2&labelColor=389826)](https://github.com/SciML/SciMLStyle)

Streamline your life using PromptingTools.jl, the Julia package that simplifies interacting with large language models.

PromptingTools.jl is not meant for building large-scale systems. It's meant to be the go-to tool in your global environment that will save you 20 minutes every day!

## Quick Start with `@ai_str` and Easy Templating

Getting started with PromptingTools.jl is as easy as importing the package and using the `@ai_str` macro for your questions.

Note: You will need to set your OpenAI API key as an environment variable before using PromptingTools.jl (see the [Creating OpenAI API Key](#creating-openai-api-key) section below). 
For a quick start, simply set it via `ENV["OPENAI_API_KEY"] = "your-api-key"`

```julia
using PromptingTools

ai"What is the capital of France?"
# [ Info: Tokens: 31 @ Cost: $0.0 in 1.5 seconds --> Be in control of your spending! 
# AIMessage("The capital of France is Paris.")
```

Returned object is a light wrapper with generated message in field `:content` (eg, `ans.content`) for additional downstream processing.

You can easily inject any variables with string interpolation:
```julia
country = "Spain"
ai"What is the capital of \$(country)?"
# [ Info: Tokens: 32 @ Cost: $0.0001 in 0.5 seconds
# AIMessage("The capital of Spain is Madrid.")
```

Pro tip: Use after-string-flags to select the model to be called, eg, `ai"What is the capital of France?"gpt4` (use `gpt4t` for the new GPT-4 Turbo model). Great for those extra hard questions!

For more complex prompt templates, you can use handlebars-style templating and provide variables as keyword arguments:

```julia
msg = aigenerate("What is the capital of {{country}}? Is the population larger than {{population}}?", country="Spain", population="1M")
# [ Info: Tokens: 74 @ Cost: $0.0001 in 1.3 seconds
# AIMessage("The capital of Spain is Madrid. And yes, the population of Madrid is larger than 1 million. As of 2020, the estimated population of Madrid is around 3.3 million people.")
```

Pro tip: Use `asyncmap` to run multiple AI-powered tasks concurrently.

Pro tip: If you use slow models (like GPT-4), you can use async version of `@ai_str` -> `@aai_str` to avoid blocking the REPL, eg, `aai"Say hi but slowly!"gpt4`

For more practical examples, see the `examples/` folder and the [Advanced Examples](#advanced-examples) section below.

## Table of Contents

- [PromptingTools.jl: "Your Daily Dose of AI Efficiency."](#promptingtoolsjl-your-daily-dose-of-ai-efficiency)
  - [Quick Start with `@ai_str` and Easy Templating](#quick-start-with-ai_str-and-easy-templating)
  - [Table of Contents](#table-of-contents)
  - [Why PromptingTools.jl](#why-promptingtoolsjl)
  - [Advanced Examples](#advanced-examples)
    - [Seamless Integration Into Your Workflow](#seamless-integration-into-your-workflow)
    - [Advanced Prompts / Conversations](#advanced-prompts--conversations)
    - [Templated Prompts](#templated-prompts)
    - [Asynchronous Execution](#asynchronous-execution)
    - [Model Aliases](#model-aliases)
    - [Embeddings](#embeddings)
    - [Classification](#classification)
    - [Data Extraction](#data-extraction)
    - [More Examples](#more-examples)
  - [Package Interface](#package-interface)
  - [Frequently Asked Questions](#frequently-asked-questions)
    - [Why OpenAI](#why-openai)
    - [Data Privacy and OpenAI](#data-privacy-and-openai)
    - [Creating OpenAI API Key](#creating-openai-api-key)
    - [Setting OpenAI Spending Limits](#setting-openai-spending-limits)
    - [How much does it cost? Is it worth paying for?](#how-much-does-it-cost-is-it-worth-paying-for)
    - [Configuring the Environment Variable for API Key](#configuring-the-environment-variable-for-api-key)
    - [Understanding the API Keyword Arguments in `aigenerate` (`api_kwargs`)](#understanding-the-api-keyword-arguments-in-aigenerate-api_kwargs)
    - [Instant Access from Anywhere](#instant-access-from-anywhere)
  - [Roadmap](#roadmap)

## Why PromptingTools.jl

Prompt engineering is neither fast nor easy. Moreover, different models and their fine-tunes might require different prompt formats and tricks, or perhaps the information you work with requires special models to be used. PromptingTools.jl is meant to unify the prompts for different backends and make the common tasks (like templated prompts) as simple as possible. 

Some features:
- **`aigenerate` Function**: Simplify prompt templates with handlebars (eg, `{{variable}}`) and keyword arguments
- **`@ai_str` String Macro**: Save keystrokes with a string macro for simple prompts
- **Easy to Remember**: All exported functions start with `ai...` for better discoverability
- **Light Wraper Types**: Benefit from Julia's multiple dispatch by having AI outputs wrapped in specific types
- **Minimal Dependencies**: Enjoy an easy addition to your global environment with very light dependencies
- **No Context Switching**: Access cutting-edge LLMs with no context switching and minimum extra keystrokes directly in your REPL

## Advanced Examples

TODOs:

- [ ] Add more practical examples (with DataFrames!)
- [ ] Add an example of how to build a RAG app in 50 lines

Noteworthy functions: `aigenerate`, `aiembed`, `aiclassify`, `aiextract`, `aitemplates`

### Seamless Integration Into Your Workflow
Google search is great, but it's a context switch. You often have to open a few pages and read through the discussion to find the answer you need. Same with the ChatGPT website.

Imagine you are in VSCode, editing your `.gitignore` file. How do I ignore a file in all subfolders again?

All you need to do is to type:
`aai"What to write in .gitignore to ignore file XYZ in any folder or subfolder?"`

With `aai""` (as opposed to `ai""`), we make a non-blocking call to the LLM to not prevent you from continuing your work. When the answer is ready, we log it from the background:

> [ Info: Tokens: 102 @ Cost: $0.0002 in 2.7 seconds
> ┌ Info: AIMessage> To ignore a file called "XYZ" in any folder or subfolder, you can add the following line to your .gitignore file:
> │ 
> │ ```
> │ **/XYZ
> │ ```
> │ 
> └ This pattern uses the double asterisk (`**`) to match any folder or subfolder, and then specifies the name of the file you want to ignore.

You probably saved 3-5 minutes on this task and probably another 5-10 minutes, because of the context switch/distraction you avoided. It's a small win, but it adds up quickly.

### Advanced Prompts / Conversations

You can use the `aigenerate` function to replace handlebar variables (eg, `{{name}}`) via keyword arguments.

```julia
msg = aigenerate("Say hello to {{name}}!", name="World")
```

The more complex prompts are effectively a conversation (a set of messages), where you can have messages from three entities: System, User, AIAssistant. We provide the corresponding types for each of them: `SystemMessage`, `UserMessage`, `AIMessage`. 

```julia
using PromptingTools: SystemMessage, UserMessage

conversation = [
    SystemMessage("You're master Yoda from Star Wars trying to help the user become a Jedi."),
    UserMessage("I have feelings for my {{object}}. What should I do?")]
msg = aigenerate(conversation; object = "old iPhone")
```

> AIMessage("Ah, a dilemma, you have. Emotional attachment can cloud your path to becoming a Jedi. To be attached to material possessions, you must not. The iPhone is but a tool, nothing more. Let go, you must.

Seek detachment, young padawan. Reflect upon the impermanence of all things. Appreciate the memories it gave you, and gratefully part ways. In its absence, find new experiences to grow and become one with the Force. Only then, a true Jedi, you shall become.")

You can also use it to build conversations, eg, 
```julia
new_conversation = vcat(conversation...,msg, UserMessage("Thank you, master Yoda! Do you have {{object}} to know what it feels like?"))
aigenerate(new_conversation; object = "old iPhone")
```
> AIMessage("Hmm, possess an old iPhone, I do not. But experience with attachments, I have. Detachment, I learned. True power and freedom, it brings...")

### Templated Prompts

With LLMs, the quality / robustness of your results depends on the quality of your prompts. But writing prompts is hard! That's why we offer a templating system to save you time and effort.

To use a specific template (eg, `` to ask a Julia language):
```julia
msg = aigenerate(:JuliaExpertAsk; ask = "How do I add packages?")
```

The above is equivalent to a more verbose version that explicitly uses the dispatch on `AITemplate`:
```julia
msg = aigenerate(AITemplate(:JuliaExpertAsk); ask = "How do I add packages?")
```

Find available templates with `aitemplates`:
```julia
tmps = aitemplates("JuliaExpertAsk")
# Will surface one specific template
# 1-element Vector{AITemplateMetadata}:
# PromptingTools.AITemplateMetadata
#   name: Symbol JuliaExpertAsk
#   description: String "For asking questions about Julia language. Placeholders: `ask`"
#   version: String "1"
#   wordcount: Int64 237
#   variables: Array{Symbol}((1,))
#   system_preview: String "You are a world-class Julia language programmer with the knowledge of the latest syntax. Your commun"
#   user_preview: String "# Question\n\n{{ask}}"
#   source: String ""
```
The above gives you a good idea of what the template is about, what placeholders are available, and how much it would cost to use it (=wordcount).

Search for all Julia-related templates:
```julia
tmps = aitemplates("Julia")
# 2-element Vector{AITemplateMetadata}... -> more to come later!
```

If you are on VSCode, you can leverage nice tabular display with `vscodedisplay`:
```julia
using DataFrames
tmps = aitemplates("Julia") |> DataFrame |> vscodedisplay
```

I have my selected template, how do I use it? Just use the "name" in `aigenerate` or `aiclassify` 
 like you see in the first example!

You can inspect any template by "rendering" it (this is what the LLM will see):
```julia
julia> AITemplate(:JudgeIsItTrue) |> PromptingTools.render
```

See more examples in the [examples/](examples/) folder.

### Asynchronous Execution

You can leverage `asyncmap` to run multiple AI-powered tasks concurrently, improving performance for batch operations. 

```julia
prompts = [aigenerate("Translate 'Hello, World!' to {{language}}"; language) for language in ["Spanish", "French", "Mandarin"]]
responses = asyncmap(aigenerate, prompts)
```

Pro tip: You can limit the number of concurrent tasks with the keyword `asyncmap(...; ntasks=10)`.

### Model Aliases

Certain tasks require more powerful models. All user-facing functions have a keyword argument `model` that can be used to specify the model to be used. For example, you can use `model = "gpt-4-1106-preview"` to use the latest GPT-4 Turbo model. However, no one wants to type that!

We offer a set of model aliases (eg, "gpt3", "gpt4", "gpt4t" -> the above GPT-4 Turbo, etc.) that can be used instead. 

Each `ai...` call first looks up the provided model name in the dictionary `PromptingTools.MODEL_ALIASES`, so you can easily extend with your own aliases! 

```julia
const PT = PromptingTools
PT.MODEL_ALIASES["gpt4t"] = "gpt-4-1106-preview"
```

These aliases also can be used as flags in the `@ai_str` macro, eg, `ai"What is the capital of France?"gpt4t` (GPT-4 Turbo has a knowledge cut-off in April 2023, so it's useful for more contemporary questions).

### Embeddings

Use the `aiembed` function to create embeddings via the default OpenAI model that can be used for semantic search, clustering, and more complex AI workflows.

```julia
text_to_embed = "The concept of artificial intelligence."
msg = aiembed(text_to_embed)
embedding = msg.content # 1536-element Vector{Float64}
```

If you plan to calculate the cosine distance between embeddings, you can normalize them first:
```julia
using LinearAlgebra
msg = aiembed(["embed me", "and me too"], LinearAlgebra.normalize)

# calculate cosine distance between the two normalized embeddings as a simple dot product
msg.content' * msg.content[:, 1] # [1.0, 0.787]
```

### Classification

You can use the `aiclassify` function to classify any provided statement as true/false/unknown. This is useful for fact-checking, hallucination or NLI checks, moderation, filtering, sentiment analysis, feature engineering and more.

```julia
aiclassify("Is two plus two four?") 
# true
```

System prompts and higher-quality models can be used for more complex tasks, including knowing when to defer to a human:

```julia
aiclassify(:JudgeIsItTrue; it = "Is two plus three a vegetable on Mars?", model = "gpt4t") 
# unknown
```

In the above example, we used a prompt template `:JudgeIsItTrue`, which automatically expands into the following system prompt (and a separate user prompt): 

> "You are an impartial AI judge evaluating whether the provided statement is \"true\" or \"false\". Answer \"unknown\" if you cannot decide."

For more information on templates, see the [Templated Prompts](#templated-prompts) section.

### Data Extraction

Are you tired of extracting data with regex? You can use LLMs to extract structured data from text!

All you have to do is to define the structure of the data you want to extract and the LLM will do the rest.

Define a `return_type` with struct. Provide docstrings if needed (improves results and helps with documentation).

Let's start with a hard task - extracting the current weather in a given location:
```julia
@enum TemperatureUnits celsius fahrenheit
"""Extract the current weather in a given location

# Arguments
- `location`: The city and state, e.g. "San Francisco, CA"
- `unit`: The unit of temperature to return, either `celsius` or `fahrenheit`
"""
struct CurrentWeather
    location::String
    unit::Union{Nothing,TemperatureUnits}
end

# Note that we provide the TYPE itself, not an instance of it!
msg = aiextract("What's the weather in Salt Lake City in C?"; return_type=CurrentWeather)
msg.content
# CurrentWeather("Salt Lake City, UT", celsius)
```

But you can use it even for more complex tasks, like extracting many entities from a text:

```julia
"Person's age, height, and weight."
struct MyMeasurement
    age::Int
    height::Union{Int,Nothing}
    weight::Union{Nothing,Float64}
end
struct ManyMeasurements
    measurements::Vector{MyMeasurement}
end
msg = aiextract("James is 30, weighs 80kg. He's 180cm tall. Then Jack is 19 but really tall - over 190!"; return_type=ManyMeasurements)
msg.content.measurements
# 2-element Vector{MyMeasurement}:
#  MyMeasurement(30, 180, 80.0)
#  MyMeasurement(19, 190, nothing)
```

There is even a wrapper to help you catch errors together with helpful explanations on why parsing failed. See `?PromptingTools.MaybeExtract` for more information.

### More Examples

TBU...

Find more examples in the [examples/](examples/) folder.

## Package Interface

The package is built around three key elements:
- Prompt Schemas: Define the structure of the prompt, how to separate it, combine it, how to "render" it 
- Messages: Hold the user inputs (=prompts) and AI outputs (=responses). Prompts are effectively "conversations to be completed"
- Task-oriented functions: Provide the user-facing functionality (eg, `aigenerate`, `aiembed`, `aiclassify`)

Why this design? Different APIs require different prompt formats. For example, OpenAI's API requires an array of dictionaries with `role` and `content` fields, while Ollama's API for Zephyr-7B model requires a ChatML schema with one big string and separators like `<|im_start|>user\nABC...<|im_end|>user`. For separating sections in your prompt, OpenAI prefers markdown headers (`##Response`) vs Anthropic performs better with HTML tags (`<text>{{TEXT}}</text>`).

This package is heavily inspired by [Instructor](https://github.com/jxnl/instructor) and it's clever use of function calling API.

**Prompt Schemas**

The key type used for customization of logic of preparing inputs for LLMs and calling them (via multiple dispatch). 

All are subtypes of `AbstractPromptSchema` and each task function has a generic signature with schema in the first position `foo(schema::AbstractPromptSchema,...)`

The dispatch is defined both for "rendering" of prompts (`render`) and for calling the APIs (`aigenerate`).

Ideally, each new interface would be defined in a separate `llm_<interface>.jl` file (eg, `llm_openai.jl`).

**Messages**

Prompts are effectively a conversation to be completed.

Conversations tend to have three key actors: system (for overall instructions), user (for inputs/data), and AI assistant (for outputs). We provide `SystemMessage`, `UserMessage`, and `AIMessage` types for each of them.

Given a prompt schema and one or more message, you can `render` the resulting object to be fed into the model API. 
Eg, for OpenAI 

```julia
using PromptingTools: render, SystemMessage, UserMessage
PT = PromptingTools

schema = PT.OpenAISchema() # also accessible as the default schema `PT.PROMPT_SCHEMA`
conversation = conversation = [
    SystemMessage("Act as a helpful AI assistant. Provide only the information that is requested."),
    UserMessage("What is the capital of France?")]

messages = render(schema, conversation)
# 2-element Vector{Dict{String, String}}:
# Dict("role" => "system", "content" => "Act as a helpful AI assistant. Provide only the information that is requested.")
# Dict("role" => "user", "content" => "What is the capital of France?")
```
This object can be provided directly to the OpenAI API.

**Task-oriented functions**

The aspiration is to provide a set of easy-to-remember functions for common tasks, hence, all start with `ai...`. All functions should return a light wrapper with resulting responses. At the moment, it can be only `AIMessage` (for any text-based response) or a generic `DataMessage` (for structured data like embeddings).

Given the differences in model APIs and their parameters (eg, OpenAI API vs Ollama), task functions are dispatched on `schema::AbstractPromptSchema` as their first argument. 

See `src/llm_openai.jl` for an example implementation.
Each new interface would be defined in a separate `llm_<interface>.jl` file.

## Frequently Asked Questions

### Why OpenAI

OpenAI's models are at the forefront of AI research and provide robust, state-of-the-art capabilities for many tasks.

There will be reasons when you do not or cannot use it (eg, privacy, cost, etc.). In that case, you can use local models (eg, Ollama) or other APIs (eg, Anthropic).

Note: Tutorial for how to set up and use Ollama + PromptingTools.jl is coming!

### Data Privacy and OpenAI

At the time of writing, OpenAI does NOT use the API calls for training their models.

> **API**
> 
> OpenAI does not use data submitted to and generated by our API to train OpenAI models or improve OpenAI’s service offering. In order to support the continuous improvement of our models, you can fill out this form to opt-in to share your data with us. -- [How your data is used to improve our models](https://help.openai.com/en/articles/5722486-how-your-data-is-used-to-improve-model-performance)

Resources:
- [Data usage for consumer services FAQ](https://help.openai.com/en/articles/7039943-data-usage-for-consumer-services-faq)
- [How your data is used to improve our models](https://help.openai.com/en/articles/5722486-how-your-data-is-used-to-improve-model-performance)


### Creating OpenAI API Key

You can get your API key from OpenAI by signing up for an account and accessing the API section of the OpenAI website.

1. Create an account with [OpenAI](https://platform.openai.com/signup)
2. Go to [API Key page](https://platform.openai.com/account/api-keys)
3. Click on “Create new secret key”
  !!! Do not share it with anyone and do NOT save it to any files that get synced online.

Resources:
- [OpenAI Documentation](https://platform.openai.com/docs/quickstart?context=python)
- [Visual tutorial](https://www.maisieai.com/help/how-to-get-an-openai-api-key-for-chatgpt)

Pro tip: Always set the spending limits!

### Setting OpenAI Spending Limits

OpenAI allows you to set spending limits directly on your account dashboard to prevent unexpected costs.

1. Go to [OpenAI Billing](https://platform.openai.com/account/billing)
2. Set Soft Limit (you’ll receive a notification) and Hard Limit (API will stop working not to spend more money)
 
A good start might be a soft limit of c.$5 and a hard limit of c.$10 - you can always increase it later in the month.

Resources:
- [OpenAI Forum](https://community.openai.com/t/how-to-set-a-price-limit/13086)

### How much does it cost? Is it worth paying for?

If you use a local model (eg, with Ollama), it's free. If you use any commercial APIs (eg, OpenAI), you will likely pay per "token" (a sub-word unit).

For example, a simple request with a simple question and 1 sentence response in return (”Is statement XYZ a positive comment”) will cost you ~$0.0001 (ie, one hundredth of a cent)

**Is it worth paying for?**

GenAI is a way to buy time! You can pay cents to save tens of minutes every day.

Continuing the example above, imagine you have a table with 200 comments. Now, you can parse each one of them with an LLM for the features/checks you need. 
Assuming the price per call was $0.0001, you'd pay 2 cents for the job and save 30-60 minutes of your time!


Resources:
- [OpenAI Pricing per 1000 tokens](https://openai.com/pricing)

### Configuring the Environment Variable for API Key

To use the OpenAI API with PromptingTools.jl, set your API key as an environment variable:

```julia
ENV["OPENAI_API_KEY"] = "your-api-key"
```

As a one-off, you can: 
- set it in the terminal before launching Julia: `export OPENAI_API_KEY = <your key>`
- set it in your `setup.jl` (make sure not to commit it to GitHub!)

Make sure to start Julia from the same terminal window where you set the variable.
Easy check in Julia, run `ENV["OPENAI_API_KEY"]` and you should see your key!

A better way:
- On a Mac, add the configuration line to your terminal's configuration file (eg, `~/.zshrc`). It will get automatically loaded every time you launch the terminal
- On Windows, set it as a system variable in "Environment Variables" settings (see the Resources)

Resources: 
- [OpenAI Guide](https://platform.openai.com/docs/quickstart?context=python)

Note: In the future, we hope to add `Preferences.jl`-based workflow to set the API key and other preferences.

### Understanding the API Keyword Arguments in `aigenerate` (`api_kwargs`)
  
See [OpenAI API reference](https://platform.openai.com/docs/guides/text-generation/chat-completions-api) for more information.

### Instant Access from Anywhere

For easy access from anywhere, add PromptingTools into your `startup.jl` (can be found in `~/.julia/config/startup.jl`).

Add the following snippet:
```
using PromptingTools
const PT = PromptingTools # to access unexported functions and types
```

Now, you can just use `ai"Help me do X to achieve Y"` from any REPL session!

## Roadmap

This is a list of features that I'd like to see in the future (in no particular order):
- Document more mini-tasks, add tutorials
- Integration of new OpenAI capabilities (eg, vision, audio, assistants -> Imagine a function you send a Plot to and it will add code to add titles, labels, etc. and generate insights for your report!)
- Documented support for local models (eg, guide and prompt templates for Ollama)
- Add Preferences.jl mechanism to set defaults and persist them across sessions
- More templates for common tasks (eg, fact-checking, sentiment analysis, extraction of entities/metadata, etc.)
- Ability to easily add new templates, save them, and share them with others
- Ability to easily trace and serialize the prompts & AI results for finetuning or evaluation in the future

For more information, contributions, or questions, please visit the [PromptingTools.jl GitHub repository](https://github.com/svilupp/PromptingTools.jl).

Please note that while PromptingTools.jl aims to provide a smooth experience, it relies on external APIs which may change. Stay tuned to the repository for updates and new features.

---

Thank you for choosing PromptingTools.jl to empower your applications with AI!