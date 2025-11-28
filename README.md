# PromptingTools.jl: "Your Daily Dose of AI Efficiency."

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://svilupp.github.io/PromptingTools.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://svilupp.github.io/PromptingTools.jl/dev/)
[![Slack](https://img.shields.io/badge/slack-%23generative--ai-brightgreen.svg?logo=slack)](https://julialang.slack.com/archives/C06G90C697X)
[![Build Status](https://github.com/svilupp/PromptingTools.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/svilupp/PromptingTools.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/svilupp/PromptingTools.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/svilupp/PromptingTools.jl)
[![Aqua](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
[![SciML Code Style](https://img.shields.io/static/v1?label=code%20style&message=SciML&color=9558b2&labelColor=389826)](https://github.com/SciML/SciMLStyle)
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/svilupp/PromptingTools.jl)

Streamline your life using PromptingTools.jl, the Julia package that simplifies interacting with large language models.

PromptingTools.jl is not meant for building large-scale systems. It's meant to be the go-to tool in your global environment that will save you 20 minutes every day!

> [!IMPORTANT]  
> **RAGTools Migration Notice**  
> RAG (Retrieval-Augmented Generation) functionality has moved to the dedicated [RAGTools.jl](https://github.com/JuliaGenAI/RAGTools.jl) package. If you're using `PromptingTools.Experimental.RAGTools`, please migrate to `RAGTools.jl`. The API remains the same - just change your imports from `using PromptingTools.Experimental.RAGTools` to `using RAGTools`.

> [!TIP]
> Jump to the **[docs](https://svilupp.github.io/PromptingTools.jl/dev/)**

## Quick Start with `@ai_str` and Easy Templating

Getting started with PromptingTools.jl is as easy as importing the package and using the `@ai_str` macro for your questions.

Note: You will need to set your OpenAI API key as an environment variable before using PromptingTools.jl (see the [Creating OpenAI API Key](#creating-openai-api-key) section below).

Following the introduction of [Prepaid Billing](https://help.openai.com/en/articles/8264644-what-is-prepaid-billing), you'll need to buy some credits to get started ($5 minimum).
For a quick start, simply set it via `ENV["OPENAI_API_KEY"] = "your-api-key"`

Install PromptingTools:
```julia
using Pkg
Pkg.add("PromptingTools")
```

And we're ready to go!
```julia
using PromptingTools

ai"What is the capital of France?"
# [ Info: Tokens: 31 @ Cost: $0.0 in 1.5 seconds --> Be in control of your spending! 
# AIMessage("The capital of France is Paris.")
```

The returned object is a light wrapper with a generated message in the field `:content` (eg, `ans.content`) for additional downstream processing.

> [!TIP]
> If you want to reply to the previous message, or simply continue the conversation, use `@ai!_str` (notice the bang `!`):
> ```julia
> ai!"And what is the population of it?"
> ```

You can easily inject any variables with string interpolation:
```julia
country = "Spain"
ai"What is the capital of \$(country)?"
# [ Info: Tokens: 32 @ Cost: $0.0001 in 0.5 seconds
# AIMessage("The capital of Spain is Madrid.")
```

> [!TIP]
> Use after-string-flags to select the model to be called, eg, `ai"What is the capital of France?"gpt4` (use `gpt4t` for the new GPT-4 Turbo model). Great for those extra hard questions!


For more complex prompt templates, you can use handlebars-style templating and provide variables as keyword arguments:

```julia
msg = aigenerate("What is the capital of {{country}}? Is the population larger than {{population}}?", country="Spain", population="1M")
# [ Info: Tokens: 74 @ Cost: $0.0001 in 1.3 seconds
# AIMessage("The capital of Spain is Madrid. And yes, the population of Madrid is larger than 1 million. As of 2020, the estimated population of Madrid is around 3.3 million people.")
```

> [!TIP]
> Use `asyncmap` to run multiple AI-powered tasks concurrently.

> [!TIP]
> If you use slow models (like GPT-4), you can use async version of `@ai_str` -> `@aai_str` to avoid blocking the REPL, eg, `aai"Say hi but slowly!"gpt4` (similarly `@ai!_str` -> `@aai!_str` for multi-turn conversations).

For more practical examples, see the `examples/` folder and the [Advanced Examples](#advanced-examples) section below.

## Table of Contents

- [PromptingTools.jl: "Your Daily Dose of AI Efficiency."](#promptingtoolsjl-your-daily-dose-of-ai-efficiency)
  - [Quick Start with `@ai_str` and Easy Templating](#quick-start-with-ai_str-and-easy-templating)
  - [Table of Contents](#table-of-contents)
  - [Why PromptingTools.jl](#why-promptingtoolsjl)
  - [Advanced Examples](#advanced-examples)
    - [`ai*` Functions Overview](#ai-functions-overview)
    - [Seamless Integration Into Your Workflow](#seamless-integration-into-your-workflow)
    - [Advanced Prompts / Conversations](#advanced-prompts--conversations)
    - [Templated Prompts](#templated-prompts)
    - [Asynchronous Execution](#asynchronous-execution)
    - [Model Aliases](#model-aliases)
    - [Embeddings](#embeddings)
    - [Classification](#classification)
    - [Routing to Defined Categories](#routing-to-defined-categories)
    - [Data Extraction](#data-extraction)
    - [OCR and Image Comprehension](#ocr-and-image-comprehension)
  - [Experimental Agent Workflows / Output Validation with `airetry!`](#experimental-agent-workflows--output-validation-with-airetry)
    - [Using Ollama models](#using-ollama-models)
    - [Using MistralAI API and other OpenAI-compatible APIs](#using-mistralai-api-and-other-openai-compatible-apis)
    - [Using OpenAI Responses API](#using-openai-responses-api)
    - [Using Anthropic Models](#using-anthropic-models)
    - [More Examples](#more-examples)
  - [Package Interface](#package-interface)
  - [Frequently Asked Questions](#frequently-asked-questions)
    - [Why OpenAI](#why-openai)
    - [What if I cannot access OpenAI?](#what-if-i-cannot-access-openai)
    - [Data Privacy and OpenAI](#data-privacy-and-openai)
    - [Creating OpenAI API Key](#creating-openai-api-key)
    - [Setting OpenAI Spending Limits](#setting-openai-spending-limits)
    - [How much does it cost? Is it worth paying for?](#how-much-does-it-cost-is-it-worth-paying-for)
    - [Configuring the Environment Variable for API Key](#configuring-the-environment-variable-for-api-key)
    - [Understanding the API Keyword Arguments in `aigenerate` (`api_kwargs`)](#understanding-the-api-keyword-arguments-in-aigenerate-api_kwargs)
    - [Instant Access from Anywhere](#instant-access-from-anywhere)
    - [Open Source Alternatives](#open-source-alternatives)
    - [Setup Guide for Ollama](#setup-guide-for-ollama)
    - [How would I fine-tune a model?](#how-would-i-fine-tune-a-model)
  - [Roadmap](#roadmap)

## Why PromptingTools.jl

Prompt engineering is neither fast nor easy. Moreover, different models and their fine-tunes might require different prompt formats and tricks, or perhaps the information you work with requires special models to be used. PromptingTools.jl is meant to unify the prompts for different backends and make the common tasks (like templated prompts) as simple as possible. 

Some features:
- **`aigenerate` Function**: Simplify prompt templates with handlebars (eg, `{{variable}}`) and keyword arguments
- **`@ai_str` String Macro**: Save keystrokes with a string macro for simple prompts
- **Easy to Remember**: All exported functions start with `ai...` for better discoverability
- **Light Wrapper Types**: Benefit from Julia's multiple dispatch by having AI outputs wrapped in specific types
- **Minimal Dependencies**: Enjoy an easy addition to your global environment with very light dependencies
- **No Context Switching**: Access cutting-edge LLMs with no context switching and minimum extra keystrokes directly in your REPL

## Advanced Examples

### `ai*` Functions Overview

Noteworthy functions: `aigenerate`, `aiembed`, `aiclassify`, `aiextract`, `aiscan`, `aiimage`, `aitemplates`

All `ai*` functions have the same basic structure: 

`ai*(<optional schema>,<prompt or conversation>; <optional keyword arguments>)`, 

but they differ in purpose:

- `aigenerate` is the general-purpose function to generate any text response with LLMs, ie, it returns `AIMessage` with field `:content` containing the generated text (eg, `ans.content isa AbstractString`)
- `aiembed` is designed to extract embeddings from the AI model's response, ie, it returns `DataMessage` with field `:content` containing the embeddings (eg, `ans.content isa AbstractArray`)
- `aiextract` is designed to extract structured data from the AI model's response and return them as a Julia struct (eg, if we provide `return_type=Food`, we get `ans.content isa Food`). You need to define the return type first and then provide it as a keyword argument.
- `aitools` is designed for agentic workflows with a mix of tool calls and user inputs. It can work with simple functions and execute them.
- `aiclassify` is designed to classify the input text into (or simply respond within) a set of discrete `choices` provided by the user. It can be very useful as an LLM Judge or a router for RAG systems, as it uses the "logit bias trick" and generates exactly 1 token. It returns `AIMessage` with field `:content`, but the `:content` can be only one of the provided `choices` (eg, `ans.content in choices`)
- `aiscan` is for working with images and vision-enabled models (as an input), but it returns `AIMessage` with field `:content` containing the generated text (eg, `ans.content isa AbstractString`) similar to `aigenerate`.
- `aiimage` is for generating images (eg, with OpenAI DALL-E 3). It returns a `DataMessage`, where the field `:content` might contain either the URL to download the image from or the Base64-encoded image depending on the user-provided kwarg `api_kwargs.response_format`.
- `aitemplates` is a helper function to discover available templates and see their details (eg, `aitemplates("some keyword")` or `aitemplates(:AssistantAsk)`)

If you're using a known `model`, you do NOT need to provide a `schema` (the first argument).

Optional keyword arguments in `ai*` tend to be:

- `model::String` - Which model you want to use
- `verbose::Bool` - Whether you went to see INFO logs around AI costs
- `return_all::Bool` - Whether you want the WHOLE conversation or just the AI answer (ie, whether you want to include your inputs/prompt in the output)
- `api_kwargs::NamedTuple` - Specific parameters for the model, eg, `temperature=0.0` to be NOT creative (and have more similar output in each run)
- `http_kwargs::NamedTuple` - Parameters for the HTTP.jl package, eg, `readtimeout = 120` to time out in 120 seconds if no response was received.

**Experimental: AgentTools**

In addition to the above list of `ai*` functions, you can also use the **"lazy" counterparts** of these functions from the experimental AgentTools module.
```julia
using PromptingTools.Experimental.AgentTools
```

For example, `AIGenerate()` will create a lazy instance of `aigenerate`. It is an instance of `AICall` with `aigenerate` as its ai function.
It uses exactly the same arguments and keyword arguments as `aigenerate` (see `?aigenerate` for details).

"lazy" refers to the fact that it does NOT generate any output when instantiated (only when `run!` is called). 

Or said differently, the `AICall` struct and all its flavors (`AIGenerate`, ...) are designed to facilitate a deferred execution model (lazy evaluation) for AI functions that interact with a Language Learning Model (LLM). It stores the necessary information for an AI call and executes the underlying AI function only when supplied with a `UserMessage` or when the `run!` method is applied. This allows us to remember user inputs and trigger the LLM call repeatedly if needed, which enables automatic fixing (see `?airetry!`).

If you would like a powerful auto-fixing workflow, you can use `airetry!`, which leverages Monte-Carlo tree search to pick the optimal trajectory of conversation based on your requirements.

**RAGTools**

Retrieval-Augmented Generation tools have moved to the dedicated
[RAGTools.jl](https://github.com/JuliaGenAI/RAGTools.jl) package. Please update
your workflow to depend on that package for RAG functionality.

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

If you are on VSCode, you can leverage a nice tabular display with `vscodedisplay`:
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

> [!TIP]
> You can limit the number of concurrent tasks with the keyword `asyncmap(...; ntasks=10)`.

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

### Routing to Defined Categories

`aiclassify` can be also used for classification into a set of defined categories (maximum 20), so we can use it for routing.

In addition, if you provide the choices as tuples (`(label, description)`), the model will use the descriptions to decide, but it will return the labels.

Example:
```julia
choices = [("A", "any animal or creature"), ("P", "for any plant or tree"), ("O", "for everything else")]

input = "spider" 
aiclassify(:InputClassifier; choices, input) # -> returns "A" for any animal or creature

# Try also with:
input = "daphodil" # -> returns "P" for any plant or tree
input = "castle" # -> returns "O" for everything else
```

Under the hood, we use the "logit bias" trick to force only 1 generated token - that means it's very cheap and very fast!

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

### OCR and Image Comprehension

With the `aiscan` function, you can interact with images as if they were text.

You can simply describe a provided image:
```julia
msg = aiscan("Describe the image"; image_path="julia.png", model="gpt4v")
# [ Info: Tokens: 1141 @ Cost: \$0.0117 in 2.2 seconds
# AIMessage("The image shows a logo consisting of the word "julia" written in lowercase")
```

Or you can do an OCR of a screenshot. 
Let's transcribe some SQL code from a screenshot (no more re-typing!), we use a template `:OCRTask`:

```julia
# Screenshot of some SQL code
image_url = "https://www.sqlservercentral.com/wp-content/uploads/legacy/8755f69180b7ac7ee76a69ae68ec36872a116ad4/24622.png"
msg = aiscan(:OCRTask; image_url, model="gpt4v", task="Transcribe the SQL code in the image.", api_kwargs=(; max_tokens=2500))

# [ Info: Tokens: 362 @ Cost: \$0.0045 in 2.5 seconds
# AIMessage("```sql
# update Orders <continue>
```

You can add syntax highlighting of the outputs via Markdown
```julia
using Markdown
msg.content |> Markdown.parse
```

## Experimental Agent Workflows / Output Validation with `airetry!`

This is an experimental feature, so you have to import it explicitly:
```julia
using PromptingTools.Experimental.AgentTools
```

This module offers "lazy" counterparts to the `ai...` functions, so you can use them in a more controlled way, eg, `aigenerate` -> `AIGenerate` (notice the CamelCase), which has exactly the same arguments except it generates only when `run!` is called.

For example:
```julia
out = AIGenerate("Say hi!"; model="gpt4t")
run!(out)
```

How is it useful? We can use the same "inputs" for repeated calls, eg, when we want to validate 
or regenerate some outputs. We have a function `airetry` to help us with that.

The signature of `airetry!` is `airetry!(condition_function, aicall::AICall, feedback_function)`.
It evaluates the condition `condition_function` on the `aicall` object (eg, we evaluate `f_cond(aicall) -> Bool`). If it fails, we call `feedback_function` on the `aicall` object to provide feedback for the AI model (eg, `f_feedback(aicall) -> String`) and repeat the process until it passes or until `max_retries` value is exceeded.

We can catch API failures (no feedback needed, so none is provided)
```julia
# API failure because of a non-existent model
# RetryConfig allows us to change the "retry" behaviour of any lazy call
out = AIGenerate("say hi!"; config = RetryConfig(; catch_errors = true),
    model = "NOTEXIST")
run!(out) # fails

# we ask to wait 2s between retries and retry 2 times (can be set in `config` in aicall as well)
airetry!(isvalid, out; retry_delay = 2, max_retries = 2)
```

Or we can validate some outputs (eg, its format, its content, etc.)

We'll play a color guessing game (I'm thinking "yellow"):

```julia
# Notice that we ask for two samples (`n_samples=2`) at each attempt (to improve our chances). 
# Both guesses are scored at each time step, and the best one is chosen for the next step.
# And with OpenAI, we can set `api_kwargs = (;n=2)` to get both samples simultaneously (cheaper and faster)!
out = AIGenerate(
    "Guess what color I'm thinking. It could be: blue, red, black, white, yellow. Answer with 1 word only";
    verbose = false,
    config = RetryConfig(; n_samples = 2), api_kwargs = (; n = 2))
run!(out)

## Check that the output is 1 word only, third argument is the feedback that will be provided if the condition fails
## Notice: functions operate on `aicall` as the only argument. We can use utilities like `last_output` and `last_message` to access the last message and output in the conversation.
airetry!(x -> length(split(last_output(x), r" |\\.")) == 1, out,
    "You must answer with 1 word only.")

# Note: you could also use the do-syntax, eg, 
airetry!(out, "You must answer with 1 word only.") do aicall
    length(split(last_output(aicall), r" |\\.")) == 1
end
```

You can place multiple `airetry!` calls in a sequence. They will keep retrying until they run out of maximum AI calls allowed (`max_calls`) or maximum retries (`max_retries`).

See the docs for more complex examples and usage tips (`?airetry`).
We leverage Monte Carlo Tree Search (MCTS) to optimize the sequence of retries, so it's a very powerful tool for building robust AI workflows (inspired by [Language Agent Tree Search paper](https://arxiv.org/abs/2310.04406) and by [DSPy Assertions paper](https://arxiv.org/abs/2312.13382)).

### Using Ollama models

[Ollama.ai](https://ollama.ai/) is an amazingly simple tool that allows you to run several Large Language Models (LLM) on your computer. It's especially suitable when you're working with some sensitive data that should not be sent anywhere.

Let's assume you have installed Ollama, downloaded a model, and it's running in the background.

We can use it with the `aigenerate` function:

```julia
const PT = PromptingTools
schema = PT.OllamaSchema() # notice the different schema!

msg = aigenerate(schema, "Say hi!"; model="openhermes2.5-mistral")
# [ Info: Tokens: 69 in 0.9 seconds
# AIMessage("Hello! How can I assist you today?")
```

For common models that have been registered (see `?PT.MODEL_REGISTRY`), you do not need to provide the schema explicitly:

```julia
msg = aigenerate("Say hi!"; model="openhermes2.5-mistral")
```

And we can also use the `aiembed` function:

```julia
msg = aiembed(schema, "Embed me", copy; model="openhermes2.5-mistral")
msg.content # 4096-element JSON3.Array{Float64...

msg = aiembed(schema, ["Embed me", "Embed me"]; model="openhermes2.5-mistral")
msg.content # 4096×2 Matrix{Float64}:
```

You can now also use `aiscan` to provide images to Ollama models! See the docs for more information.

If you're getting errors, check that Ollama is running - see the [Setup Guide for Ollama](#setup-guide-for-ollama) section below.

### Using MistralAI API and other OpenAI-compatible APIs

Mistral models have long been dominating the open-source space. They are now available via their API, so you can use them with PromptingTools.jl!

```julia
msg = aigenerate("Say hi!"; model="mistral-tiny")
```

It all just works, because we have registered the models in the `PromptingTools.MODEL_REGISTRY`! There are currently 4 models available: `mistral-tiny`, `mistral-small`, `mistral-medium`, `mistral-embed`.

Under the hood, we use a dedicated schema `MistralOpenAISchema` that leverages most of the OpenAI-specific code base, so you can always provide that explicitly as the first argument:

```julia
const PT = PromptingTools
msg = aigenerate(PT.MistralOpenAISchema(), "Say Hi!"; model="mistral-tiny", api_key=ENV["MISTRAL_API_KEY"])
```
As you can see, we can load your API key either from the ENV or via the Preferences.jl mechanism (see `?PREFERENCES` for more information).

But MistralAI are not the only ones! There are many other exciting providers, eg, [Perplexity.ai](https://docs.perplexity.ai/), [Fireworks.ai](https://app.fireworks.ai/).
As long as they are compatible with the OpenAI API (eg, sending `messages` with `role` and `content` keys), you can use them with PromptingTools.jl by using `schema = CustomOpenAISchema()`:

```julia
# Set your API key and the necessary base URL for the API
api_key = "..."
prompt = "Say hi!"
msg = aigenerate(PT.CustomOpenAISchema(), prompt; model="my_model", api_key, api_kwargs=(; url="http://localhost:8081"))
```

As you can see, it also works for any local models that you might have running on your computer!

Note: At the moment, we only support `aigenerate` and `aiembed` functions for MistralAI and other OpenAI-compatible APIs. We plan to extend the support in the future.

### Using OpenAI Responses API

PromptingTools.jl supports OpenAI's **Responses API** (`/responses` endpoint) in addition to the traditional Chat Completions API. The Responses API offers several advantages for agentic workflows and reasoning models:

**Key Benefits:**
- **Server-side state management**: No need to send full conversation history with each request
- **Better cache utilization**: 40-80% improved cache hits, reducing latency and costs
- **Built-in tools**: Native web search, file search, and code interpreter without round-trips
- **Reasoning model support**: Better preservation of reasoning traces for models like o1, o3, and GPT-5
- **Multimodal-first design**: Text, images, and tools as first-class citizens

```julia
# Use the Responses API with any compatible model
schema = OpenAIResponseSchema()
msg = aigenerate(schema, "What is Julia?"; model="gpt-5-mini")

# Enable web search (built-in tool)
msg = aigenerate(schema, "What are the latest Julia releases?";
    model="gpt-5-mini", enable_websearch=true)

# With reasoning enabled (for reasoning models)
msg = aigenerate(schema, "Solve: What is 15% of 80?";
    model="o3-mini",
    api_kwargs = (reasoning = Dict("effort" => "medium", "summary" => "auto"),))

# Access reasoning summary
println(msg.extras[:reasoning_content])

# Continue conversations using previous_response_id
msg2 = aigenerate(schema, "Tell me more";
    model="gpt-5-mini", previous_response_id=msg.extras[:response_id])

# Streaming responses
msg = aigenerate(schema, "Count from 1 to 10, one number per line.";
    model = "gpt-5-mini",
    streamcallback = stdout,
    verbose = false)
```

**When to use which API:**
- **Chat Completions API** (default): Straightforward conversations, established integrations, maximum compatibility
- **Responses API**: Complex agent workflows, tool use, reasoning models, state-heavy applications

See the [FAQ](https://svilupp.github.io/PromptingTools.jl/dev/frequently_asked_questions/#Why-use-the-Responses-API-instead-of-Chat-Completions?) for more details.

### Using Anthropic Models

Make sure the `ANTHROPIC_API_KEY` environment variable is set to your API key.

```julia
# cladeuh is alias for Claude 3 Haiku
ai"Say hi!"claudeh
```

Preset model aliases are `claudeo`, `claudes`, and `claudeh`, for Claude 3 Opus, Sonnet, and Haiku, respectively.

The corresponding schema is `AnthropicSchema`.

There are several prompt templates with `XML` in the name, suggesting that they use Anthropic-friendly XML formatting for separating sections.
Find them with `aitemplates("XML")`.

```julia
# cladeo is alias for Claude 3 Opus
msg = aigenerate(
    :JuliaExpertAskXML, ask = "How to write a function to convert Date to Millisecond?",
    model = "cladeo")
```


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

There will be situations not or cannot use it (eg, privacy, cost, etc.). In that case, you can use local models (eg, Ollama) or other APIs (eg, Anthropic).

Note: To get started with [Ollama.ai](https://ollama.ai/), see the [Setup Guide for Ollama](#setup-guide-for-ollama) section below.

### What if I cannot access OpenAI?

There are many alternatives:

- **Other APIs**: MistralAI, Anthropic, Google, Together, Fireworks, Voyager (the latter ones tend to give free credits upon joining!)
- **Locally-hosted models**: Llama.cpp/Llama.jl, Ollama, vLLM (see the examples and the corresponding docs)

### Data Privacy and OpenAI

At the time of writing, OpenAI does NOT use the API calls for training their models.

> **API**
> 
> OpenAI does not use data submitted to and generated by our API to train OpenAI models or improve OpenAI’s service offering. In order to support the continuous improvement of our models, you can fill out this form to opt-in to share your data with us. -- [How your data is used to improve our models](https://help.openai.com/en/articles/5722486-how-your-data-is-used-to-improve-model-performance)

You can always double-check the latest information on the [OpenAI's How we use your data](https://platform.openai.com/docs/models/how-we-use-your-data) page.

Resources:
- [OpenAI's How we use your data](https://platform.openai.com/docs/models/how-we-use-your-data)
- [Data usage for consumer services FAQ](https://help.openai.com/en/articles/7039943-data-usage-for-consumer-services-faq)
- [How your data is used to improve our models](https://help.openai.com/en/articles/5722486-how-your-data-is-used-to-improve-model-performance)


### Creating OpenAI API Key

You can get your API key from OpenAI by signing up for an account and accessing the API section of the OpenAI website.

1. Create an account with [OpenAI](https://platform.openai.com/signup)
2. Go to [API Key page](https://platform.openai.com/account/api-keys)
3. Click on “Create new secret key”

!!! danger
  Do not share it with anyone and do NOT save it to any files that get synced online.

Resources:
- [OpenAI Documentation](https://platform.openai.com/docs/quickstart?context=python)
- [Visual tutorial](https://www.maisieai.com/help/how-to-get-an-openai-api-key-for-chatgpt)

> [!TIP]
> Always set the spending limits!

### Setting OpenAI Spending Limits

OpenAI allows you to set spending limits directly on your account dashboard to prevent unexpected costs.

1. Go to [OpenAI Billing](https://platform.openai.com/account/billing)
2. Set Soft Limit (you’ll receive a notification) and Hard Limit (API will stop working not to spend more money)
 
A good start might be a soft limit of c.$5 and a hard limit of c.$10 - you can always increase it later in the month.

Resources:
- [OpenAI Forum](https://community.openai.com/t/how-to-set-a-price-limit/13086)

### How much does it cost? Is it worth paying for?

If you use a local model (eg, with Ollama), it's free. If you use any commercial APIs (eg, OpenAI), you will likely pay per "token" (a sub-word unit).

For example, a simple request with a simple question and 1 sentence response in return (”Is statement XYZ a positive comment”) will cost you ~$0.0001 (ie, one-hundredth of a cent)

**Is it worth paying for?**

GenAI is a way to buy time! You can pay cents to save tens of minutes every day.

Continuing the example above, imagine you have a table with 200 comments. Now, you can parse each one of them with an LLM for the features/checks you need. 
Assuming the price per call was $0.0001, you'd pay 2 cents for the job and save 30-60 minutes of your time!


Resources:
- [OpenAI Pricing per 1000 tokens](https://openai.com/pricing)

### Configuring the Environment Variable for API Key

This is a guide for OpenAI's API key, but it works for any other API key you might need (eg, `MISTRAL_API_KEY` for MistralAI API).

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

We also support Preferences.jl, so you can simply run: `PromptingTools.set_preferences!("OPENAI_API_KEY"=>"your-api-key")` and it will be persisted across sessions. 
To see the current preferences, run `PromptingTools.get_preferences("OPENAI_API_KEY")`.

Be careful NOT TO COMMIT `LocalPreferences.toml` to GitHub, as it would show your API Key to the world!

Resources: 
- [OpenAI Guide](https://platform.openai.com/docs/quickstart?context=python)


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

### Open Source Alternatives

The ethos of PromptingTools.jl is to allow you to use whatever model you want, which includes Open Source LLMs. The most popular and easiest to setup is [Ollama.ai](https://ollama.ai/) - see below for more information.

### Setup Guide for Ollama

Ollama runs a background service hosting LLMs that you can access via a simple API. It's especially useful when you're working with some sensitive data that should not be sent anywhere.

Installation is very easy, just download the latest version [here](https://ollama.ai/download).

Once you've installed it, just launch the app and you're ready to go!

To check if it's running, go to your browser and open `127.0.0.1:11434`. You should see the message "Ollama is running". 
Alternatively, you can run `ollama serve` in your terminal and you'll get a message that it's already running.

There are many models available in [Ollama Library](https://ollama.ai/library), including Llama2, CodeLlama, SQLCoder, or my personal favorite `openhermes2.5-mistral`.

Download new models with `ollama pull <model_name>` (eg, `ollama pull openhermes2.5-mistral`). 

Show currently available models with `ollama list`.

See [Ollama.ai](https://ollama.ai/) for more information.

### How would I fine-tune a model?

Fine-tuning is a powerful technique to adapt a model to your specific use case (mostly the format/syntax/task). It requires a dataset of examples, which you can now easily generate with PromptingTools.jl!

1. You can save any conversation (vector of messages) to a file with `PT.save_conversation("filename.json", conversation)`.

2. Once the finetuning time comes, create a bundle of ShareGPT-formatted conversations (common finetuning format) in a single `.jsonl` file. Use `PT.save_conversations("dataset.jsonl", [conversation1, conversation2, ...])` (notice that plural "conversationS" in the function name).

For an example of an end-to-end finetuning process, check out our sister project [JuliaLLMLeaderboard Finetuning experiment](https://github.com/svilupp/Julia-LLM-Leaderboard/blob/main/experiments/cheater-7b-finetune/README.md). It shows the process of finetuning for half a dollar with [Jarvislabs.ai](https://jarvislabs.ai/templates/axolotl) and [Axolotl](https://github.com/OpenAccess-AI-Collective/axolotl).

## Roadmap

This is a list of features that I'd like to see in the future (in no particular order):
- Document more mini-tasks, add tutorials
- Integration of new OpenAI capabilities (eg, audio, assistants -> Imagine a function you send a Plot to and it will add code to add titles, labels, etc. and generate insights for your report!)
- Add Preferences.jl mechanism to set defaults and persist them across sessions
- More templates for common tasks (eg, fact-checking, sentiment analysis, extraction of entities/metadata, etc.)
- Ability to easily add new templates, save them, and share them with others
- Ability to easily trace and serialize the prompts & AI results for finetuning or evaluation in the future
- Add multi-turn conversations if you need to "reply" to the AI assistant


For more information, contributions, or questions, please visit the [PromptingTools.jl GitHub repository](https://github.com/svilupp/PromptingTools.jl).

Please note that while PromptingTools.jl aims to provide a smooth experience, it relies on external APIs which may change. Stay tuned to the repository for updates and new features.

---

Thank you for choosing PromptingTools.jl to empower your applications with AI!
