# Custom APIs

PromptingTools allows you to use any OpenAI-compatible API (eg, MistralAI), including a locally hosted one like the server from `llama.cpp`.

````julia
using PromptingTools
const PT = PromptingTools
````

## Using MistralAI

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
msg = aigenerate(PT.MistralOpenAISchema(), "Say Hi!"; model="mistral-tiny", api_key=ENV["MISTRALAI_API_KEY"])
```
As you can see, we can load your API key either from the ENV or via the Preferences.jl mechanism (see `?PREFERENCES` for more information).

## Using other OpenAI-compatible APIs

MistralAI are not the only ones who mimic the OpenAI API!
There are many other exciting providers, eg, [Perplexity.ai](https://docs.perplexity.ai/), [Fireworks.ai](https://app.fireworks.ai/).

As long as they are compatible with the OpenAI API (eg, sending `messages` with `role` and `content` keys), you can use them with PromptingTools.jl by using `schema = CustomOpenAISchema()`:

```julia
# Set your API key and the necessary base URL for the API
api_key = "..."
provider_url = "..." # provider API URL
prompt = "Say hi!"
msg = aigenerate(PT.CustomOpenAISchema(), prompt; model="<some-model>", api_key, api_kwargs=(; url=provider_url))
```

> [!TIP]
> If you register the model names with `PT.register_model!`, you won't have to keep providing the `schema` manually.

Note: At the moment, we only support `aigenerate` and `aiembed` functions.

## Using llama.cpp server

In line with the above, you can also use the [`llama.cpp` server](https://github.com/ggerganov/llama.cpp/blob/master/examples/server/README.md). 

It is a bit more technically demanding because you need to "compile" `llama.cpp` first, but it will always have the latest models and it is quite fast (eg, faster than Ollama, which uses llama.cpp under the hood but has some extra overhead).

Start your server in a command line (`-m` refers to the model file, `-c` is the context length, `-ngl` is the number of layers to offload to GPU):

```bash
./server -m models/mixtral-8x7b-instruct-v0.1.Q4_K_M.gguf -c 2048 -ngl 99
```

Then simply access it via PromptingTools:

```julia
msg = aigenerate(PT.CustomOpenAISchema(), "Count to 5 and say hi!"; api_kwargs=(; url="http://localhost:8080/v1"))
```

> [!TIP]
> If you register the model names with `PT.register_model!`, you won't have to keep providing the `schema` manually. It can be any `model` name, because the model is actually selected when you start the server in the terminal.