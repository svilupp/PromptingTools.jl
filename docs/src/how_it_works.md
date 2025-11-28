```@meta
CurrentModule = PromptingTools
```

# How It Works

This is an advanced section that explains how PromptingTools.jl works under the hood. It is not necessary to understand this to use the package, but it can be helpful for debugging and understanding the limitations of the package.

We'll start with the key concepts and then walk through an example of `aigenerate` to see how it all fits together.

## Key Concepts

5 Key Concepts (/Objects):

- **API/Model Providers** -> The method that gives you access to Large Language Models (LLM), it can be an API (eg, OpenAI) or a locally-hosted application (eg, Llama.cpp or Ollama)
- **Schemas** -> object of type `AbstractPromptSchema` that determines which methods are called and, hence, what providers/APIs are used
- **Prompts** -> the information you want to convey to the AI model
- **Messages** -> the basic unit of communication between the user and the AI model (eg, `UserMessage` vs `AIMessage`)
- **Prompt Templates** -> re-usable "prompts" with placeholders that you can replace with your inputs at the time of making the request

When you call `aigenerate`, roughly the following happens: `render` -> `UserMessage`(s) -> `render` -> `OpenAI.create_chat` -> ... -> `AIMessage`.

### API/Model Providers

You can think of "API/Model Providers" as the method that gives you access to Large Language Models (LLM). It can be an API (eg, OpenAI) or a locally-hosted application (eg, Llama.cpp or Ollama).

You interact with them via the `schema` object, which is a subtype of `AbstractPromptSchema`,
eg, there is an `OpenAISchema` for the provider "OpenAI" and its supertype `AbstractOpenAISchema` is for all other providers that mimic the OpenAI API.

### Schemas

For your "message" to reach an AI model, it needs to be formatted and sent to the right place (-> provider!).

We leverage the multiple dispatch around the "schemas" to pick the right logic.
All schemas are subtypes of `AbstractPromptSchema` and there are many subtypes, eg, `OpenAISchema <: AbstractOpenAISchema <:AbstractPromptSchema`.

For example, if you provide `schema = OpenAISchema()`, the system knows that:
- it will have to format any user inputs to OpenAI's "message specification" (a vector of dictionaries, see their API documentation). Function `render(OpenAISchema(),...)` will take care of the rendering.
- it will have to send the message to OpenAI's API. We will use the amazing `OpenAI.jl` package to handle the communication.

### Prompts

Prompt is loosely the information you want to convey to the AI model. It can be a question, a statement, or a command. It can have instructions or some context, eg, previous conversation.

You need to remember that Large Language Models (LLMs) are **stateless**. They don't remember the previous conversation/request, so you need to provide the whole history/context every time (similar to how REST APIs work).

Prompts that we send to the LLMs are effectively a sequence of messages (`<:AbstractMessage`).

### Messages

Messages are the basic unit of communication between the user and the AI model. 

There are 5 main types of messages (`<:AbstractMessage`):

- `SystemMessage` - this contains information about the "system", eg, how it should behave, format its output, etc. (eg, `You're a world-class Julia programmer. You write brief and concise code.)
- `UserMessage` - the information "from the user", ie, your question/statement/task
- `UserMessageWithImages` - the same as `UserMessage`, but with images (URLs or Base64-encoded images)
- `AIMessage` - the response from the AI model, when the "output" is text
- `DataMessage` - the response from the AI model, when the "output" is data, eg, embeddings with `aiembed` or user-defined structs with `aiextract`

### Prompt Templates

We want to have re-usable "prompts", so we provide you with a system to retrieve pre-defined prompts with placeholders (eg, `{{name}}`) that you can replace with your inputs at the time of making the request.

"AI Templates" as we call them (`AITemplate`) are usually a vector of `SystemMessage` and a `UserMessage` with specific purpose/task.

For example, the template `:AssistantAsk` is defined loosely as:

```julia
 template = [SystemMessage("You are a world-class AI assistant. Your communication is brief and concise. You're precise and answer only when you're confident in the high quality of your answer."),
             UserMessage("# Question\n\n{{ask}}")]
```

Notice that we have a placeholder `ask` (`{{ask}}`) that you can replace with your question without having to re-write the generic system instructions.

When you provide a Symbol (eg, `:AssistantAsk`) to ai* functions, thanks to the multiple dispatch, it recognizes that it's an `AITemplate(:AssistantAsk)` and looks it up.

You can discover all available templates with `aitemplates("some keyword")` or just see the details of some template `aitemplates(:AssistantAsk)`.

Note: There is a new way to create and register templates in one go with `create_template(;user=<user prompt>, system=<system prompt>, load_as=<template name>)` (it skips the serialization step where a template previously must have been saved somewhere on the disk). See FAQ for more details or directly `?create_template`.

### ai* Functions Overview

The above steps are implemented in the `ai*` functions, eg, `aigenerate`, `aiembed`, `aiextract`, etc. They all have the same basic structure: 

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

In addition to the above list of `ai*` functions, you can also use the **"lazy" counterparts** of these functions from the experimental AgentTools module.
```julia
using PromptingTools.Experimental.AgentTools
```

For example, `AIGenerate()` will create a lazy instance of `aigenerate`. It is an instance of `AICall` with `aigenerate` as its ai function.
It uses exactly the same arguments and keyword arguments as `aigenerate` (see `?aigenerate` for details).

"lazy" refers to the fact that it does NOT generate any output when instantiated (only when `run!` is called). 

Or said differently, the `AICall` struct and all its flavors (`AIGenerate`, ...) are designed to facilitate a deferred execution model (lazy evaluation) for AI functions that interact with a Language Learning Model (LLM). It stores the necessary information for an AI call and executes the underlying AI function only when supplied with a `UserMessage` or when the `run!` method is applied. 

This approach allows us to remember user inputs and trigger the LLM call repeatedly if needed, which enables automatic fixing (see `?airetry!`).

Example:
```julia
result = AIGenerate(:JuliaExpertAsk; ask="xyz", model="abc", api_kwargs=(; temperature=0.1))
result |> run!

# Is equivalent to
result = aigenerate(:JuliaExpertAsk; ask="xyz", model="abc", api_kwargs=(; temperature=0.1), return_all=true)
# The only difference is that we default to `return_all=true` with lazy types because we have a dedicated `conversation` field, which makes it much easier
```

Lazy AI calls and self-healing mechanisms unlock much more robust and useful LLM workflows!

## Walkthrough Example for `aigenerate`

```julia
using PromptingTools
const PT = PromptingTools

# Let's say this is our ask
msg = aigenerate(:AssistantAsk; ask="What is the capital of France?")

# it is effectively the same as:
msg = aigenerate(PT.OpenAISchema(), PT.AITemplate(:AssistantAsk); ask="What is the capital of France?", model="gpt3t")
```

There is no `model` provided, so we use the default `PT.MODEL_CHAT` (effectively GPT-4o-mini). Then we look it up in `PT.MDOEL_REGISTRY` and use the associated schema for it (`OpenAISchema` in this case).

The next step is to render the template, replace the placeholders and render it for the OpenAI model.

```julia
# Let's remember out schema
schema = PT.OpenAISchema()
ask = "What is the capital of France?"
```

First, we obtain the template (no placeholder replacement yet) and "expand it"
```julia
template_rendered = PT.render(schema, AITemplate(:AssistantAsk); ask)
```

```plaintext
2-element Vector{PromptingTools.AbstractChatMessage}:
  PromptingTools.SystemMessage("You are a world-class AI assistant. Your communication is brief and concise. You're precise and answer only when you're confident in the high quality of your answer.")
  PromptingTools.UserMessage{String}("# Question\n\n{{ask}}", [:ask], :usermessage)
```

Second, we replace the placeholders
```julia
rendered_for_api = PT.render(schema, template_rendered;  ask)
```
  
```plaintext
2-element Vector{Dict{String, Any}}:
  Dict("role" => "system", "content" => "You are a world-class AI assistant. Your communication is brief and concise. You're precise and answer only when you're confident in the high quality of your answer.")
  Dict("role" => "user", "content" => "# Question\n\nWhat is the capital of France?")
```

Notice that the placeholders are only replaced in the second step. The final output here is a vector of messages with "role" and "content" keys, which is the format required by the OpenAI API.

As a side note, under the hood, the second step is done in two sub-steps:

- replace the placeholders `messages_rendered = PT.render(PT.NoSchema(), template_rendered; ask)` -> returns a vector of Messages!
- then, we convert the messages to the format required by the provider/schema `PT.render(schema, messages_rendered)` -> returns the OpenAI formatted messages

Next, we send the above `rendered_for_api` to the OpenAI API and get the response back.

```julia
using OpenAI
OpenAI.create_chat(api_key, model, rendered_for_api)
```

The last step is to take the JSON response from the API and convert it to the `AIMessage` object.

```julia
# simplification for educational purposes
msg = AIMessage(; content = r.response[:choices][1][:message][:content])
```

In practice, there are more fields we extract, so we define a utility for it: `PT.response_to_message`. Especially, since with parameter `n`, you can request multiple AI responses at once, so we want to re-use our response processing logic.

That's it! I hope you've learned something new about how PromptingTools.jl works under the hood.

## Walkthrough Example for `aiextract`

Whereas `aigenerate` is a general-purpose function to generate any text response with LLMs, `aiextract` is designed to extract structured data from the AI model's response and return them as a Julia struct.

It's a bit more complicated than `aigenerate` because it needs to handle the JSON schema of the return type (= our struct).

Let's define a toy example of a struct and see how `aiextract` works under the hood.
```julia
using PromptingTools
const PT = PromptingTools

"""
Extract the name of the food from the sentence. Extract any provided adjectives for the food as well.

Example: "I am eating a crunchy bread." -> Food("bread", ["crunchy"])
"""
struct Food
    name::String # required field!
    adjectives::Union{Nothing,Vector{String}} # not required because `Nothing` is allowed
end

msg = aiextract("I just ate a delicious and juicy apple."; return_type=Food)
msg.content
# Food("apple", ["delicious", "juicy"])
```

You can see that we sent a prompt to the AI model and it returned a `Food` object. 
We provided some light guidance as a docstring of the return type, but the AI model did the heavy lifting.

`aiextract` leverages native "function calling" (supported by OpenAI, Fireworks, Together, and many others). 

We encode the user-provided `return_type` into the corresponding JSON schema and create the payload as per the specifications of the provider.

Let's how that's done:
```julia
sig = PT.function_call_signature(Food)
## Dict{String, Any} with 3 entries:
##   "name"        => "Food_extractor"
##   "parameters"  => Dict{String, Any}("properties"=>Dict{String, Any}("name"=>Dict("type"=>"string"), "adjectives"=>Dict{String, …
##   "description" => "Extract the food from the sentence. Extract any provided adjectives for the food as well.\n\nExample: "
```
You can see that we capture the field names and types in `parameters` and the description in `description` key.

Furthermore, if we zoom in on the "parameter" field, you can see that we encode not only the names and types but also whether the fields are required (ie, do they allow `Nothing`)
You can see below that the field `adjectives` accepts `Nothing`, so it's not required. Only the `name` field is required.
```julia
sig["parameters"]
## Dict{String, Any} with 3 entries:
##   "properties" => Dict{String, Any}("name"=>Dict("type"=>"string"), "adjectives"=>Dict{String, Any}("items"=>Dict("type"=>"strin…
##   "required"   => ["name"]
##   "type"       => "object"
```

For `aiextract`, the signature is provided to the API provider via `tools` parameter, eg, 

`api_kwargs = (; tools = [Dict(:type => "function", :function => sig)])`

Optionally, we can provide also `tool_choice` parameter to specify which tool to use if we provided multiple (differs across providers).

When the message is returned, we extract the JSON object in the response and decode it into Julia object via `JSON3.read(obj, Food)`. For example,
```julia
model_response = Dict(:tool_calls => [Dict(:function => Dict(:arguments => JSON3.write(Dict("name" => "apple", "adjectives" => ["delicious", "juicy"]))))])
food = JSON3.read(model_response[:tool_calls][1][:function][:arguments], Food)
# Output: Food("apple", ["delicious", "juicy"])
```

This is why you can sometimes have errors when you use abstract types in your `return_type` -> to enable that, you would need to set the right `StructTypes` behavior for your abstract type (see the JSON3.jl documentation for more details on how to do that).
 
It works quite well for concrete types and "vanilla" structs, though.

Unfortunately, function calling is generally NOT supported by locally-hosted / open-source models, 
so let's try to build a workaround with `aigenerate`

You need to pick a bigger / more powerful model, as it's NOT an easy task to output a correct JSON specification.
My laptop isn't too powerful and I don't like waiting, so I'm going to use Mixtral model hosted on Together.ai (you get \$25 credit when you join)!

```julia
model = "tmixtral" # tmixtral is an alias for "mistralai/Mixtral-8x7B-Instruct-v0.1" on Together.ai and it automatically sets `schema = TogetherOpenAISchema()`
```

We'll add the signature to the prompt and we'll request the JSON output in two places - in the prompt and in the `api_kwargs` (to ensure that the model outputs the JSON via "grammar")
NOTE: You can write much better and more specific prompt if you have a specific task / return type in mind + you should make sure that the prompt + struct description make sense together!

Let's define a prompt and `return_type`. Notice that we add several placeholders (eg, `{{description}}`) to fill with user inputs later.
```julia
prompt = """
You're a world-class data extraction engine. 

Your task is to extract information formatted as per the user provided schema.
You MUST response in JSON format.

**Example:**
---------
Description: "Extract the Car from the sentence. Extract the corresponding brand and model as well."
Input: "I drive a black Porsche 911 Turbo."
Schema: "{\"properties\":{\"model\":{\"type\":\"string\"},\"brand\":{\"type\":\"string\"}},\"required\":[\"brand\",\"model\"],\"type\":\"object\"}"
Output: "{\"model\":\"911 Turbo\",\"brand\":\"Porsche\"}"
---------

**User Request:**
Description: {{description}}
Input: {{input}}
Schema: {{signature}}
Output:

You MUST OUTPUT in JSON format.
"""
```

We need to extract the "signature of our `return_type` and put it in the right placeholders.
Let's generate now!
```julia
sig = PT.function_call_signature(Food)
result = aigenerate(prompt; input="I just ate a delicious and juicy apple.",
    schema=JSON3.write(sig["parameters"]), description=sig["description"],
    ## We provide the JSON output requirement as per API docs: https://docs.together.ai/docs/json-mode
    model, api_kwargs=(; response_format=Dict("type" => "json_object"), temperature=0.2), return_all=true)
result[end].content
## "{\n  \"adjectives\": [\"delicious\", \"juicy\"],\n  \"food\": \"apple\"\n}"
```

We're using a smaller model, so the output is not perfect.
Let's try to load into our object:
```julia
obj = JSON3.read(result[end].content, Food)
# Output: ERROR: MethodError: Cannot `convert` an object of type Nothing to an object of type String
```

Unfortunately, we get an error because the model mixed up the key "name" for "food", so it cannot be parsed.

Fortunately, we can do better and use automatic fixing! 
All we need to do is to change from `aigenerate` -> `AIGenerate` (and use `airetry!`)

The signature of `AIGenerate` is identical to `aigenerate` with the exception of `config` field, where we can influence the future `retry` behaviour.
```julia
result = AIGenerate(prompt; input="I just ate a delicious and juicy apple.",
    schema=JSON3.write(sig["parameters"]), description=sig["description"],
    ## We provide the JSON output requirement as per API docs: https://docs.together.ai/docs/json-mode
    model, api_kwargs=(; response_format=Dict("type" => "json_object"), temperature=0.2),
    ## limit the number of retries, default is 10 rounds
    config=RetryConfig(; max_retries=3))
run!(result) # run! triggers the generation step (to have some AI output to check)
```

Let's set up a retry mechanism with some practical feedback. We'll leverage `airetry!` to automatically retry the request and provide feedback to the model.
Think of `airetry!` as `@assert` on steroids:

`@assert CONDITION MESSAGE` → `airetry! CONDITION <state> MESSAGE`

The main benefits of `airetry!` are:
- It can retry automatically, not just throw an error
- It manages the "conversation’ (list of messages) for you, including adding user-provided feedback to help generate better output

```julia
feedback = "The output is not in the correct format. The keys should be $(join([string("\"$f\"") for f in fieldnames(Food)],", "))."
# We use do-syntax with provide the `CONDITION` (it must return Bool)
airetry!(result, feedback) do conv
    ## try to convert
    obj = try
        JSON3.read(last_output(conv), Food)
    catch e
        ## you could save the error and provide as feedback (eg, into a slot in the `:memory` field of the AICall object)
        e
    end
    ## Check if the conversion was successful; if it's `false`, it will retry
    obj isa Food # -> Bool
end
food = JSON3.read(last_output(result), Food)
## [ Info: Condition not met. Retrying...
## Output: Food("apple", ["delicious", "juicy"])
```

It took 1 retry (see `result.config.retries`) and we have the correct output from an open-source model!

If you're interested in the `result` object, it's a struct (`AICall`) with a field `conversation`, which holds the conversation up to this point.
AIGenerate is an alias for AICall using `aigenerate` function. See `?AICall` (the underlying struct type) for more details on the fields and methods available.

## Walkthrough Example for the Responses API

The Responses API is OpenAI's newer API endpoint designed for agentic workflows and reasoning models. Unlike the Chat Completions API which requires you to manage conversation state client-side, the Responses API can manage state server-side.

### When to Use the Responses API

Use the Responses API when you need:
- **Server-side state management**: Avoid sending full conversation history with each request
- **Built-in tools**: Web search, file search, code interpreter without implementing them yourself
- **Reasoning models**: Better support for o1, o3, o4-mini, and GPT-5 models
- **Better caching**: 40-80% improved cache utilization for cost and latency benefits

### Basic Usage

```julia
using PromptingTools
const PT = PromptingTools

# Explicitly use the Responses API with OpenAIResponseSchema
schema = PT.OpenAIResponseSchema()

msg = aigenerate(schema, "What is the capital of France?"; model="gpt-5-mini")
```

### How It Works Under the Hood

Let's trace through what happens when you make a Responses API call:

```julia
# Step 1: Render the prompt for the Responses API
prompt = "What is Julia programming language?"
rendered = PT.render(schema, prompt)
```

The `render` function for `OpenAIResponseSchema` produces a different output than `OpenAISchema`:

```plaintext
(input = "What is Julia programming language?", instructions = nothing)
```

Notice that instead of a vector of messages with "role" and "content" keys, we get a named tuple with `input` and `instructions` fields. This matches the Responses API specification.

If we use a template with a system message:

```julia
conversation = [
    PT.SystemMessage("You are a helpful Julia programming assistant."),
    PT.UserMessage("What is Julia?")
]
rendered = PT.render(schema, conversation)
```

```plaintext
(input = "What is Julia?", instructions = "You are a helpful Julia programming assistant.")
```

### Server-Side State Management

One of the key advantages of the Responses API is server-side state management:

```julia
# First message
msg1 = aigenerate(schema, "My name is Alice."; model="gpt-5-mini")

# Continue the conversation using previous_response_id
# No need to send the full conversation history!
msg2 = aigenerate(schema, "What is my name?";
    model="gpt-5-mini",
    previous_response_id=msg1.extras[:response_id])

# The model remembers: "Your name is Alice."
```

With Chat Completions, you would need to send all previous messages with each request. The Responses API handles this server-side.

### Built-in Web Search

The Responses API provides hosted tools that execute server-side:

```julia
msg = aigenerate(schema, "What are the latest Julia 1.11 features?";
    model="gpt-5-mini",
    enable_websearch=true)
```

This uses OpenAI's built-in web search tool without any additional setup.

### Reasoning Models

For reasoning models like o1, o3, and o4-mini, you can control the reasoning effort:

```julia
msg = aigenerate(schema, "Solve: If a train travels 120 km in 2 hours, and then 180 km in 3 hours, what is its average speed for the entire journey?";
    model="o3-mini",
    api_kwargs = (reasoning = Dict("effort" => "high", "summary" => "detailed"),))

# Access the reasoning summary
println(msg.extras[:reasoning_content])
```

Reasoning options:
- `effort`: "low", "medium", or "high" - controls how much reasoning effort the model applies
- `summary`: "auto", "concise", or "detailed" - controls verbosity of reasoning summary

### Structured Data Extraction

The Responses API supports structured output via JSON schema:

```julia
struct WeatherInfo
    location::String
    temperature::Float64
    conditions::String
end

result = aiextract(schema, "The weather in Paris is 22°C and sunny.";
    return_type=WeatherInfo,
    model="gpt-5-mini")

result.content
# WeatherInfo("Paris", 22.0, "sunny")
```

### Response Extras

The `AIMessage` returned by the Responses API includes additional information in the `extras` field:

```julia
msg = aigenerate(schema, "Hello!"; model="gpt-5-mini")

msg.extras[:response_id]        # ID for continuing conversations
msg.extras[:reasoning_content]  # Vector of reasoning summaries (for reasoning models)
msg.extras[:usage]              # Token usage details
msg.extras[:full_response]      # Complete API response
```

### Chat Completions vs Responses API Comparison

| Aspect | Chat Completions | Responses API |
|--------|------------------|---------------|
| State Management | Client-side (send all messages) | Server-side (`previous_response_id`) |
| Built-in Tools | None | Web search, file search, code interpreter |
| Reasoning Models | Limited | Full support with effort/summary controls |
| Cache Efficiency | Standard | 40-80% better cache hits |
| Endpoint | `/v1/chat/completions` | `/v1/responses` |
| Schema | `OpenAISchema()` | `OpenAIResponseSchema()` |

For more details on when to use each API, see the [FAQ section on Responses API](frequently_asked_questions.md#Why-use-the-Responses-API-instead-of-Chat-Completions).