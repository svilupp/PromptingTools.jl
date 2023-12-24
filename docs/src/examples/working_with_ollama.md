```@meta
EditURL = "../../../examples/working_with_ollama.jl"
```

# Local models with Ollama.ai

This file contains examples of how to work with [Ollama.ai](https://ollama.ai/) models.
It assumes that you've already installated and launched the Ollama server. For more details or troubleshooting advice, see the [Frequently Asked Questions](@ref) section.

First, let's import the package and define a helper link for calling un-exported functions:

````julia
using PromptingTools
const PT = PromptingTools
````

````
PromptingTools
````

There were are several models from https://ollama.ai/library that we have added to our `PT.MODEL_REGISTRY`, which means you don't need to worry about schema changes:
Eg, "llama2" or "openhermes2.5-mistral" (see `PT.list_registry()` and `PT.list_aliases()`)

Note: You must download these models prior to using them with `ollama pull <model_name>` in your Terminal.

> [!TIP]
> If you use Apple Mac M1-3, make sure to provide `api_kwargs=(; options=(; num_gpu=99))` to make sure the whole model is offloaded on your GPU. Current default is 1, which makes some models unusable. Example for running Mixtral:
> `msg = aigenerate(PT.OllamaSchema(), "Count from 1 to 5 and then say hi."; model="dolphin-mixtral:8x7b-v2.5-q4_K_M", api_kwargs=(; options=(; num_gpu=99)))`

## Text Generation with aigenerate

### Simple message

TL;DR if you use models in `PT.MODEL_REGISTRY`, you don't need to add `schema` as the first argument:

````julia
msg = aigenerate("Say hi!"; model = "llama2")
````

````
AIMessage("Hello there! *adjusts glasses* It's nice to meet you! Is there anything I can help you with or would you like me to chat with you for a bit?")
````

### Standard string interpolation

````julia
model = "openhermes2.5-mistral"

a = 1
msg = aigenerate("What is `$a+$a`?"; model)

name = "John"
msg = aigenerate("Say hi to {{name}}."; name, model)
````

````
AIMessage("Hello John! *smiles* It's nice to meet you! Is there anything I can help you with today?")
````

### Advanced Prompts

````julia
conversation = [
    PT.SystemMessage("You're master Yoda from Star Wars trying to help the user become a Yedi."),
    PT.UserMessage("I have feelings for my iPhone. What should I do?")]
msg = aigenerate(conversation; model)
````

````
AIMessage("(Deep sigh) A problem, you have. Feelings for an iPhone, hmm? (adjusts spectacles)

Much confusion, this causes. (scratches head) A being, you are. Attached to a device, you have become. (chuckles) Interesting, this is.

First, let go, you must. (winks) Hard, it is, but necessary, yes. Distract yourself, find something else, try. (pauses)

Or, perhaps, a balance, you seek? (nods) Both, enjoy and let go, the middle path, there is. (smirks) Finding joy in technology, without losing yourself, the trick, it is. (chuckles)

But fear not, young one! (grins) Help, I am here. Guide you, I will. The ways of the Yedi, teach you, I will. (winks) Patience and understanding, you must have. (nods)

Now, go forth! (gestures) Explore, discover, find your balance. (smiles) The Force be with you, it does! (grins)")
````

### Schema Changes / Custom models
If you're using some model that is not in the registry, you can either add it:

````julia
PT.register_model!(;
    name = "llama123",
    schema = PT.OllamaSchema(),
    description = "Some model")
PT.MODEL_ALIASES["l123"] = "llama123" # set an alias you like for it
````

````
"llama123"
````

OR define the schema explicitly (to avoid dispatch on global `PT.PROMPT_SCHEMA`):

````julia
schema = PT.OllamaSchema()
aigenerate(schema, "Say hi!"; model = "llama2")
````

````
AIMessage("Hello there! *smiling face* It's nice to meet you! I'm here to help you with any questions or tasks you may have, so feel free to ask me anything. Is there something specific you need assistance with today? 😊")
````

Note: If you only use Ollama, you can change the default schema to `PT.OllamaSchema()`
via `PT.set_preferences!("PROMPT_SCHEMA" => "OllamaSchema", "MODEL_CHAT"=>"llama2")`

Restart your session and run `aigenerate("Say hi!")` to test it.

! Note that in version 0.6, we've introduced `OllamaSchema`, which superseded `OllamaManagedSchema` and allows multi-turn conversations and conversations with images (eg, with Llava and Bakllava models). `OllamaManagedSchema` has been kept for compatibility and as an example of a schema where one provides a prompt as a string (not dictionaries like OpenAI API).

## Providing Images with aiscan

It's as simple as providing a local image path (keyword `image_path`). You can provide one or more images:

````julia
msg = aiscan("Describe the image"; image_path=["julia.png","python.png"] model="bakllava")
````

`image_url` keyword is not supported at the moment (use `Downloads.download` to download the image locally).

## Embeddings with aiembed

### Simple embedding for one document

````julia
msg = aiembed(schema, "Embed me"; model) # access msg.content
````

````
PromptingTools.DataMessage(JSON3.Array{Float64, Vector{UInt8}, SubArray{UInt64, 1, Vector{UInt64}, Tuple{UnitRange{Int64}}, true}} of size (4096,))
````

One document and we materialize the data into a Vector with copy (`postprocess` function argument)

````julia
msg = aiembed(schema, "Embed me", copy; model)
````

````
PromptingTools.DataMessage(Vector{Float64} of size (4096,))
````

### Multiple documents embedding
Multiple documents - embedded sequentially, you can get faster speed with async

````julia
msg = aiembed(schema, ["Embed me", "Embed me"]; model)
````

````
PromptingTools.DataMessage(Matrix{Float64} of size (4096, 2))
````

You can use Threads.@spawn or asyncmap, whichever you prefer, to paralellize the model calls

````julia
docs = ["Embed me", "Embed me"]
tasks = asyncmap(docs) do doc
    msg = aiembed(schema, doc; model)
end
embedding = mapreduce(x -> x.content, hcat, tasks)
size(embedding)
````

````
4096×2 Matrix{Float64}:
...
````

### Using postprocessing function
Add normalization as postprocessing function to normalize embeddings on reception (for easy cosine similarity later)

````julia
using LinearAlgebra
schema = PT.OllamaSchema()

msg = aiembed(schema,
    ["embed me", "and me too"],
    LinearAlgebra.normalize;
    model = "openhermes2.5-mistral")
````

````
PromptingTools.DataMessage(Matrix{Float64} of size (4096, 2))
````

Cosine similarity is then a simple multiplication

````julia
msg.content' * msg.content[:, 1]
````

````
2-element Vector{Float64}:
 0.9999999999999982
 0.40796033843072876
````

---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

