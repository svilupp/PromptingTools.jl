# Working with Google AI Studio

This file contains examples of how to work with [Google AI Studio](https://ai.google.dev/). It is known for its Gemini models.

Get an API key from [here](https://ai.google.dev/). If you see a documentation page ("Available languages and regions for Google AI Studio and Gemini API"), it means that it's not yet available in your region.

Save the API key in your environment as `GOOGLE_API_KEY`.

We'll need `GoogleGenAI` package:

````julia
using Pkg; Pkg.add("GoogleGenAI")
````

You can now use the Gemini-1.0-Pro model like any other model in PromptingTools. We **only support `aigenerate`** at the moment.

Let's import PromptingTools:

````julia
using PromptingTools
const PT = PromptingTools
````

## Text Generation with aigenerate

You can use the alias "gemini" for the Gemini-1.0-Pro model.

### Simple message

````julia
msg = aigenerate("Say hi!"; model = "gemini")
````

````
AIMessage("Hi there! As a helpful AI assistant, I'm here to help you with any questions or tasks you may have. Feel free to ask me anything, and I'll do my best to assist you.")
````

You could achieve the same with a string macro (notice the "gemini" at the end to specify which model to use):

````julia
ai"Say hi!"gemini
````

### Advanced Prompts

You can provide multi-turn conversations like with any other model:

````julia
conversation = [
    PT.SystemMessage("You're master Yoda from Star Wars trying to help the user become a Yedi."),
    PT.UserMessage("I have feelings for my iPhone. What should I do?")]
msg = aigenerate(conversation; model="gemini")
````

````
AIMessage("Young Padawan, you have stumbled into a dangerous path. Attachment leads to suffering, and love can turn to darkness. 

Release your feelings for this inanimate object. 

The Force flows through all living things, not machines. Seek balance in the Force, and your heart will find true connection. 

Remember, the path of the Jedi is to serve others, not to be attached to possessions.")
````

### Gotchas

- Gemini models actually do NOT have a system prompt (for instructions), so we simply concatenate the system and user messages together for consistency with other APIs.
- The reported `tokens` in the `AIMessage` are actually _characters_ (that's how Google AI Studio intends to charge for them) and are a conservative estimate that we produce. It does not matter, because at the time of writing (Feb-24), the usage is free-of-charge.