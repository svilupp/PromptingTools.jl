# Various Examples

## `ai*` Functions Overview

Noteworthy functions: `aigenerate`, `aiembed`, `aiclassify`, `aiextract`, `aiscan`, `aiimage`, `aitemplates`

All `ai*` functions have the same basic structure: 

`ai*(<optional schema>,<prompt or conversation>; <optional keyword arguments>)`, 

but they differ in purpose:

- `aigenerate` is the general-purpose function to generate any text response with LLMs, ie, it returns `AIMessage` with field `:content` containing the generated text (eg, `ans.content isa AbstractString`)
- `aiembed` is designed to extract embeddings from the AI model's response, ie, it returns `DataMessage` with field `:content` containing the embeddings (eg, `ans.content isa AbstractArray`)
- `aiextract` is designed to extract structured data from the AI model's response and return them as a Julia struct (eg, if we provide `return_type=Food`, we get `ans.content isa Food`). You need to define the return type first and then provide it as a keyword argument.
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

**RAGTools**

Tools for building Retrieval-Augmented Generation workflows now live in the
dedicated [RAGTools.jl](https://github.com/JuliaGenAI/RAGTools.jl) package.
Please migrate your code there for continued support and updates.


## Seamless Integration Into Your Workflow
Google search is great, but it's a context switch. You often have to open a few pages and read through the discussion to find the answer you need. Same with the ChatGPT website.

Imagine you are in VSCode, editing your `.gitignore` file. How do I ignore a file in all subfolders again?

All you need to do is to type:
`aai"What to write in .gitignore to ignore file XYZ in any folder or subfolder?"`

With `aai""` (as opposed to `ai""`), we make a non-blocking call to the LLM to not prevent you from continuing your work. When the answer is ready, we log it from the background:

```plaintext
[ Info: Tokens: 102 @ Cost: $0.0002 in 2.7 seconds
┌ Info: AIMessage> To ignore a file called "XYZ" in any folder or subfolder, you can add the following line to your .gitignore file:
│ 
│ ```
│ **/XYZ
│ ```
│ 
└ This pattern uses the double asterisk (`**`) to match any folder or subfolder, and then specifies the name of the file you want to ignore.
```

You probably saved 3-5 minutes on this task and probably another 5-10 minutes, because of the context switch/distraction you avoided. It's a small win, but it adds up quickly.

## Advanced Prompts / Conversations

You can use the `aigenerate` function to replace handlebar variables (eg, `{{name}}`) via keyword arguments.

```julia
msg = aigenerate("Say hello to {{name}}!", name="World")
```

The more complex prompts are effectively a conversation (a set of messages), where you can have messages from three entities: System, User, AI Assistant. We provide the corresponding types for each of them: `SystemMessage`, `UserMessage`, `AIMessage`. 

```julia
using PromptingTools: SystemMessage, UserMessage

conversation = [
    SystemMessage("You're master Yoda from Star Wars trying to help the user become a Jedi."),
    UserMessage("I have feelings for my {{object}}. What should I do?")]
msg = aigenerate(conversation; object = "old iPhone")
```

```plaintext
AIMessage("Ah, a dilemma, you have. Emotional attachment can cloud your path to becoming a Jedi. To be attached to material possessions, you must not. The iPhone is but a tool, nothing more. Let go, you must.

Seek detachment, young padawan. Reflect upon the impermanence of all things. Appreciate the memories it gave you, and gratefully part ways. In its absence, find new experiences to grow and become one with the Force. Only then, a true Jedi, you shall become.")
```

You can also use it to build conversations, eg, 
```julia
new_conversation = vcat(conversation...,msg, UserMessage("Thank you, master Yoda! Do you have {{object}} to know what it feels like?"))
aigenerate(new_conversation; object = "old iPhone")
```
    
```plaintext
> AIMessage("Hmm, possess an old iPhone, I do not. But experience with attachments, I have. Detachment, I learned. True power and freedom, it brings...")
```

## Templated Prompts

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

See more examples in the [Examples](https://github.com/svilupp/PromptingTools.jl/tree/main/examples) folder.

## Asynchronous Execution

You can leverage `asyncmap` to run multiple AI-powered tasks concurrently, improving performance for batch operations. 

```julia
prompts = [aigenerate("Translate 'Hello, World!' to {{language}}"; language) for language in ["Spanish", "French", "Mandarin"]]
responses = asyncmap(aigenerate, prompts)
```

Pro tip: You can limit the number of concurrent tasks with the keyword `asyncmap(...; ntasks=10)`.

## Model Aliases

Certain tasks require more powerful models. All user-facing functions have a keyword argument `model` that can be used to specify the model to be used. For example, you can use `model = "gpt-4-1106-preview"` to use the latest GPT-4 Turbo model. However, no one wants to type that!

We offer a set of model aliases (eg, "gpt3", "gpt4", "gpt4t" -> the above GPT-4 Turbo, etc.) that can be used instead. 

Each `ai...` call first looks up the provided model name in the dictionary `PromptingTools.MODEL_ALIASES`, so you can easily extend with your own aliases! 

```julia
const PT = PromptingTools
PT.MODEL_ALIASES["gpt4t"] = "gpt-4-1106-preview"
```

These aliases also can be used as flags in the `@ai_str` macro, eg, `ai"What is the capital of France?"gpt4t` (GPT-4 Turbo has a knowledge cut-off in April 2023, so it's useful for more contemporary questions).

## Embeddings

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

## Classification

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

## Data Extraction

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

## OCR and Image Comprehension

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

The signature of `airetry` is `airetry(condition_function, aicall::AICall, feedback_function)`.
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

## Using Ollama models

[Ollama.ai](https://ollama.ai/) is an amazingly simple tool that allows you to run several Large Language Models (LLM) on your computer. It's especially suitable when you're working with some sensitive data that should not be sent anywhere.

Let's assume you have installed Ollama, downloaded a model, and it's running in the background.

We can use it with the `aigenerate` function:

```julia
const PT = PromptingTools
schema = PT.OllamaManagedSchema() # notice the different schema!

msg = aigenerate(schema, "Say hi!"; model="openhermes2.5-mistral")
# [ Info: Tokens: 69 in 0.9 seconds
# AIMessage("Hello! How can I assist you today?")
```

And we can also use the `aiembed` function:

```julia
msg = aiembed(schema, "Embed me", copy; model="openhermes2.5-mistral")
msg.content # 4096-element JSON3.Array{Float64...

msg = aiembed(schema, ["Embed me", "Embed me"]; model="openhermes2.5-mistral")
msg.content # 4096×2 Matrix{Float64}:
```

If you're getting errors, check that Ollama is running - see the [Setup Guide for Ollama](#setup-guide-for-ollama) section below.

## Using MistralAI API and other OpenAI-compatible APIs

Mistral models have long been dominating the open-source space. They are now available via their API, so you can use them with PromptingTools.jl!

```julia
msg = aigenerate("Say hi!"; model="mistral-tiny")
# [ Info: Tokens: 114 @ Cost: $0.0 in 0.9 seconds
# AIMessage("Hello there! I'm here to help answer any questions you might have, or assist you with tasks to the best of my abilities. How can I be of service to you today? If you have a specific question, feel free to ask and I'll do my best to provide accurate and helpful information. If you're looking for general assistance, I can help you find resources or information on a variety of topics. Let me know how I can help.")
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