```@meta
CurrentModule = PromptingTools
```

# Getting Started

## Prerequisites

**OpenAI API key saved in the environment variable `OPENAI_API_KEY`**

You will need to register with OpenAI and generate an API key:

1. Create an account with [OpenAI](https://platform.openai.com/signup)
2. Go to [Account Billing](https://platform.openai.com/account/billing) and buy some credits (prepayment, minimum $5). Your account must have credits for the API access to work.
3. Go to [API Key page](https://platform.openai.com/account/api-keys)
4. Click on “Create new secret key”
  !!! Do not share it with anyone and do NOT save it to any files that get synced online.

Resources:
- [OpenAI Documentation](https://platform.openai.com/docs/quickstart?context=python)
- [Visual tutorial](https://www.maisieai.com/help/how-to-get-an-openai-api-key-for-chatgpt)

You will need to set this key as an environment variable before using PromptingTools.jl:

For a quick start, simply set it via `ENV["OPENAI_API_KEY"] = "your-api-key"`
Alternatively, you can:
- set it in the terminal before launching Julia: `export OPENAI_API_KEY = <your key>`
- set it in your `setup.jl` (make sure not to commit it to GitHub!)

Make sure to start Julia from the same terminal window where you set the variable.
Easy check in Julia, run `ENV["OPENAI_API_KEY"]` and you should see your key!

For other options or more robust solutions, see the FAQ section.

Resources: 
- [OpenAI Guide](https://platform.openai.com/docs/quickstart?context=python)

## Installation

PromptingTools can be installed using the following commands:

```julia
using Pkg
Pkg.add("PromptingTools.jl")
```

Throughout the rest of this tutorial, we will assume that you have installed the
PromptingTools package and have already typed `using PromptingTools` to bring all of the
relevant variables into your current namespace.

## Quick Start with `@ai_str`

The easiest start is the `@ai_str` macro. Simply type `ai"your prompt"` and you will get a response from the default model (GPT-3.5 Turbo).

```julia
ai"What is the capital of France?"
```

```plaintext
[ Info: Tokens: 31 @ Cost: $0.0 in 1.5 seconds --> Be in control of your spending! 
AIMessage("The capital of France is Paris.")
```

Returned object is a light wrapper with generated message in field `:content` (eg, `ans.content`) for additional downstream processing.

If you want to reply to the previous message, or simply continue the conversation, use `@ai!_str` (notice the bang `!`):
```julia
ai!"And what is the population of it?"
```

You can easily inject any variables with string interpolation:
```julia
country = "Spain"
ai"What is the capital of \$(country)?"
```

```plaintext
[ Info: Tokens: 32 @ Cost: $0.0001 in 0.5 seconds
AIMessage("The capital of Spain is Madrid.")
```

Pro tip: Use after-string-flags to select the model to be called, eg, `ai"What is the capital of France?"gpt4` (use `gpt4t` for the new GPT-4 Turbo model). Great for those extra hard questions!

## Using `aigenerate` with placeholders

For more complex prompt templates, you can use handlebars-style templating and provide variables as keyword arguments:

```julia
msg = aigenerate("What is the capital of {{country}}? Is the population larger than {{population}}?", country="Spain", population="1M")
```

```plaintext
[ Info: Tokens: 74 @ Cost: $0.0001 in 1.3 seconds
AIMessage("The capital of Spain is Madrid. And yes, the population of Madrid is larger than 1 million. As of 2020, the estimated population of Madrid is around 3.3 million people.")
```

Pro tip: Use `asyncmap` to run multiple AI-powered tasks concurrently.

Pro tip: If you use slow models (like GPT-4), you can use the asynchronous version of `@ai_str` -> `@aai_str` to avoid blocking the REPL, eg, `aai"Say hi but slowly!"gpt4` (similarly `@ai!_str` -> `@aai!_str` for multi-turn conversations).

For more practical examples, see the [Various Examples](@ref) section.
