# # Local models with Ollama.ai

# This file contains examples of how to work with [Ollama.ai](https://ollama.ai/) models.
# It assumes that you've already installated and launched the Ollama server. For more details or troubleshooting advice, see the [Frequently Asked Questions](@ref) section.
#
# First, let's import the package and define a helper link for calling un-exported functions:
using PromptingTools
const PT = PromptingTools

# Notice the schema change! If you want this to be the new default, you need to change `PT.PROMPT_SCHEMA`
schema = PT.OllamaManagedSchema()
# You can choose models from https://ollama.ai/library - I prefer `openhermes2.5-mistral`
model = "openhermes2.5-mistral"

# ## Text Generation with aigenerate

# ### Simple message
msg = aigenerate(schema, "Say hi!"; model)

# ### Standard string interpolation
a = 1
msg = aigenerate(schema, "What is `$a+$a`?"; model)

name = "John"
msg = aigenerate(schema, "Say hi to {{name}}."; name, model)

# ### Advanced Prompts
conversation = [
    PT.SystemMessage("You're master Yoda from Star Wars trying to help the user become a Yedi."),
    PT.UserMessage("I have feelings for my iPhone. What should I do?")]
msg = aigenerate(schema, conversation; model)

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

# ### Using postprocessing function
# Add normalization as postprocessing function to normalize embeddings on reception (for easy cosine similarity later)
using LinearAlgebra
schema = PT.OllamaManagedSchema()

msg = aiembed(schema,
    ["embed me", "and me too"],
    LinearAlgebra.normalize;
    model = "openhermes2.5-mistral")

# Cosine similarity is then a simple multiplication
msg.content' * msg.content[:, 1]