# # Local models with Ollama.ai

# This file contains examples of how to work with [Ollama.ai](https://ollama.ai/) models.
# It assumes that you've already installated and launched the Ollama server. For more details or troubleshooting advice, see the [Frequently Asked Questions](@ref) section.
#
# First, let's import the package and define a helper link for calling un-exported functions:
using PromptingTools
const PT = PromptingTools

# There were are several models from https://ollama.ai/library that we have added to our `PT.MODEL_REGISTRY`, which means you don't need to worry about schema changes:
# Eg, "llama2" or "openhermes2.5-mistral" (see `PT.list_registry()` and `PT.list_aliases()`)
#
# Note: You must download these models prior to using them with `ollama pull <model_name>` in your Terminal.

# ## Text Generation with aigenerate

# ### Simple message
#
# TL;DR if you use models in `PT.MODEL_REGISTRY`, you don't need to add `schema` as the first argument:
#
msg = aigenerate("Say hi!"; model = "llama2")

# ### Standard string interpolation
model = "openhermes2.5-mistral"

a = 1
msg = aigenerate("What is `$a+$a`?"; model)

name = "John"
msg = aigenerate("Say hi to {{name}}."; name, model)

# ### Advanced Prompts
conversation = [
    PT.SystemMessage("You're master Yoda from Star Wars trying to help the user become a Yedi."),
    PT.UserMessage("I have feelings for my iPhone. What should I do?")]
msg = aigenerate(conversation; model)

# ### Schema Changes / Custom models
# If you're using some model that is not in the registry, you can either add it:
PT.register_model!(;
    name = "llama123",
    schema = PT.OllamaSchema(),
    description = "Some model")
PT.MODEL_ALIASES["l123"] = "llama123" # set an alias you like for it

# OR define the schema explicitly (to avoid dispatch on global `PT.PROMPT_SCHEMA`):
schema = PT.OllamaSchema()
aigenerate(schema, "Say hi!"; model = "llama2")

# Note: If you only use Ollama, you can change the default schema to `PT.OllamaSchema()` 
# via `PT.set_preferences!("PROMPT_SCHEMA" => "OllamaSchema", "MODEL_CHAT"=>"llama2")`
#
# Restart your session and run `aigenerate("Say hi!")` to test it.

# ! Note that in version 0.6, we've introduced `OllamaSchema`, which superseded `OllamaManagedSchema` and allows multi-turn conversations and conversations with images (eg, with Llava and Bakllava models). `OllamaManagedSchema` has been kept for compatibility and as an example of a schema where one provides a prompt as a string (not dictionaries like OpenAI API).

# ## Providing Images with aiscan

# It's as simple as providing an image URL (keyword `image_url`) or a local path (keyword `image_path`). You can provide one or more images:

msg = aiscan(
    "Describe the image"; image_path =  ["/test/data/julia.png"]model = "bakllava" )

# ## Embeddings with aiembed

# ### Simple embedding for one document
msg = aiembed(schema, "Embed me"; model) # access msg.content

# One document and we materialize the data into a Vector with copy (`postprocess` function argument)
msg = aiembed(schema, "Embed me", copy; model)

# ### Multiple documents embedding
# Multiple documents - embedded sequentially, you can get faster speed with async
msg = aiembed(schema, ["Embed me", "Embed me"]; model)

# You can use Threads.@spawn or asyncmap, whichever you prefer, to paralellize the model calls
docs = ["Embed me", "Embed me"]
tasks = asyncmap(docs) do doc
    msg = aiembed(schema, doc; model)
end
embedding = mapreduce(x -> x.content, hcat, tasks)
size(embedding)

# ### Using postprocessing function
# Add normalization as postprocessing function to normalize embeddings on reception (for easy cosine similarity later)
using LinearAlgebra
schema = PT.OllamaSchema()

msg = aiembed(schema,
    ["embed me", "and me too"],
    LinearAlgebra.normalize;
    model = "openhermes2.5-mistral")

# Cosine similarity is then a simple multiplication
msg.content' * msg.content[:, 1]
