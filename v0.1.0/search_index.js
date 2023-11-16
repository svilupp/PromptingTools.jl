var documenterSearchIndex = {"docs":
[{"location":"","page":"Home","title":"Home","text":"CurrentModule = PromptingTools","category":"page"},{"location":"#PromptingTools","page":"Home","title":"PromptingTools","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Documentation for PromptingTools.","category":"page"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"Modules = [PromptingTools]","category":"page"},{"location":"#PromptingTools.AbstractPromptSchema","page":"Home","title":"PromptingTools.AbstractPromptSchema","text":"Defines different prompting styles based on the model training and fine-tuning.\n\n\n\n\n\n","category":"type"},{"location":"#PromptingTools.ChatMLSchema","page":"Home","title":"PromptingTools.ChatMLSchema","text":"ChatMLSchema is used by many open-source chatbots, by OpenAI models under the hood and by several models and inferfaces (eg, Ollama, vLLM)\n\nIt uses the following conversation structure:\n\n<im_start>system\n...<im_end>\n<|im_start|>user\n...<|im_end|>\n<|im_start|>assistant\n...<|im_end|>\n\n\n\n\n\n","category":"type"},{"location":"#PromptingTools.OpenAISchema","page":"Home","title":"PromptingTools.OpenAISchema","text":"OpenAISchema is the default schema for OpenAI models.\n\nIt uses the following conversation template:\n\n[Dict(role=\"system\",content=\"...\"),Dict(role=\"user\",content=\"...\"),Dict(role=\"assistant\",content=\"...\")]\n\nIt's recommended to separate sections in your prompt with markdown headers (e.g. `##Answer\n\n`).\n\n\n\n\n\n","category":"type"},{"location":"#PromptingTools.TestEchoOpenAISchema","page":"Home","title":"PromptingTools.TestEchoOpenAISchema","text":"Echoes the user's input back to them. Used for testing the implementation\n\n\n\n\n\n","category":"type"},{"location":"#PromptingTools.aiclassify-Tuple{PromptingTools.AbstractOpenAISchema, Any}","page":"Home","title":"PromptingTools.aiclassify","text":"aiclassify(prompt_schema::AbstractOpenAISchema, prompt;\napi_kwargs::NamedTuple = (logit_bias = Dict(837 => 100, 905 => 100, 9987 => 100),\n    max_tokens = 1, temperature = 0),\nkwargs...)\n\nClassifies the given prompt/statement as true/false/unknown.\n\nNote: this is a very simple classifier, it is not meant to be used in production. Credit goes to: https://twitter.com/AAAzzam/status/1669753721574633473\n\nIt uses Logit bias trick to force the model to output only true/false/unknown.\n\nOutput tokens used (via api_kwargs):\n\n837: ' true'\n905: ' false'\n9987: ' unknown'\n\nArguments\n\nprompt_schema::AbstractOpenAISchema: The schema for the prompt.\nprompt: The prompt/statement to classify if it's a String. If it's a Symbol, it is expanded as a template via render(schema,template).\n\nExample\n\naiclassify(\"Is two plus two four?\") # true\naiclassify(\"Is two plus three a vegetable on Mars?\") # false\n\naiclassify returns only true/false/unknown. It's easy to get the proper Bool output type out with tryparse, eg,\n\ntryparse(Bool, aiclassify(\"Is two plus two four?\")) isa Bool # true\n\nOutput of type Nothing marks that the model couldn't classify the statement as true/false.\n\nIdeally, we would like to re-use some helpful system prompt to get more accurate responses. For this reason we have templates, eg, :IsStatementTrue. By specifying the template, we can provide our statement as the expected variable (statement in this case) See that the model now correctly classifies the statement as \"unknown\".\n\naiclassify(:IsStatementTrue; statement = \"Is two plus three a vegetable on Mars?\") # unknown\n\nFor better results, use higher quality models like gpt4, eg, \n\naiclassify(:IsStatementTrue;\n    statement = \"If I had two apples and I got three more, I have five apples now.\",\n    model = \"gpt4\") # true\n\n\n\n\n\n","category":"method"},{"location":"#PromptingTools.aiembed-Union{Tuple{F}, Tuple{PromptingTools.AbstractOpenAISchema, Union{AbstractString, Vector{<:AbstractString}}}, Tuple{PromptingTools.AbstractOpenAISchema, Union{AbstractString, Vector{<:AbstractString}}, F}} where F<:Function","page":"Home","title":"PromptingTools.aiembed","text":"aiembed(prompt_schema::AbstractOpenAISchema,\n        doc_or_docs::Union{AbstractString, Vector{<:AbstractString}},\n        postprocess::F = identity;\n        verbose::Bool = true,\n        api_key::String = API_KEY,\n        model::String = MODEL_EMBEDDING,\n        http_kwargs::NamedTuple = (retry_non_idempotent = true,\n                                   retries = 5,\n                                   readtimeout = 120),\n        api_kwargs::NamedTuple = NamedTuple(),\n        kwargs...) where {F <: Function}\n\nThe aiembed function generates embeddings for the given input using a specified model and returns a message object containing the embeddings, status, token count, and elapsed time.\n\nArguments\n\nprompt_schema::AbstractOpenAISchema: The schema for the prompt.\ndoc_or_docs::Union{AbstractString, Vector{<:AbstractString}}: The document or list of documents to generate embeddings for.\npostprocess::F: The post-processing function to apply to each embedding. Defaults to the identity function.\nverbose::Bool: A flag indicating whether to print verbose information. Defaults to true.\napi_key::String: The API key to use for the OpenAI API. Defaults to API_KEY.\nmodel::String: The model to use for generating embeddings. Defaults to MODEL_EMBEDDING.\nhttp_kwargs::NamedTuple: Additional keyword arguments for the HTTP request. Defaults to (retry_non_idempotent = true, retries = 5, readtimeout = 120).\napi_kwargs::NamedTuple: Additional keyword arguments for the OpenAI API. Defaults to an empty NamedTuple.\nkwargs...: Additional keyword arguments.\n\nReturns\n\nmsg: A DataMessage object containing the embeddings, status, token count, and elapsed time.\n\nExample\n\nmsg = aiembed(\"Hello World\")\nmsg.content # 1536-element JSON3.Array{Float64...\n\nWe can embed multiple strings at once and they will be hcat into a matrix   (ie, each column corresponds to one string)\n\nmsg = aiembed([\"Hello World\", \"How are you?\"])\nmsg.content # 1536×2 Matrix{Float64}:\n\nIf you plan to calculate the cosine distance between embeddings, you can normalize them first:\n\nusing LinearAlgebra\nmsg = aiembed([\"embed me\", \"and me too\"], LinearAlgebra.normalize)\n\n# calculate cosine distance between the two normalized embeddings as a simple dot product\nmsg.content' * msg.content[:, 1] # [1.0, 0.787]\n\n\n\n\n\n","category":"method"},{"location":"#PromptingTools.aigenerate-Tuple{PromptingTools.AbstractOpenAISchema, Any}","page":"Home","title":"PromptingTools.aigenerate","text":"aigenerate([prompt_schema::AbstractOpenAISchema,] prompt; verbose::Bool = true,\n    model::String = MODEL_CHAT,\n    http_kwargs::NamedTuple = (;\n        retry_non_idempotent = true,\n        retries = 5,\n        readtimeout = 120), api_kwargs::NamedTuple = NamedTuple(),\n    kwargs...)\n\nGenerate an AI response based on a given prompt using the OpenAI API.\n\nArguments\n\nprompt_schema: An optional object to specify which prompt template should be applied (Default to PROMPT_SCHEMA = OpenAISchema)\nprompt: Can be a string representing the prompt for the AI conversation, a UserMessage, a vector of AbstractMessage or an AITemplate\nverbose: A boolean indicating whether to print additional information.\nprompt_schema: An abstract schema for the prompt.\napi_key: A string representing the API key for accessing the OpenAI API.\nmodel: A string representing the model to use for generating the response. Can be an alias corresponding to a model ID defined in MODEL_ALIASES.\nhttp_kwargs: A named tuple of HTTP keyword arguments.\napi_kwargs: A named tuple of API keyword arguments.\nkwargs: Prompt variables to be used to fill the prompt/template\n\nReturns\n\nmsg: An AIMessage object representing the generated AI message, including the content, status, tokens, and elapsed time.\n\nSee also: ai_str\n\nExample\n\nSimple hello world to test the API:\n\nresult = aigenerate(\"Say Hi!\")\n# [ Info: Tokens: 29 @ Cost: $0.0 in 1.0 seconds\n# AIMessage(\"Hello! How can I assist you today?\")\n\nresult is an AIMessage object. Access the generated string via content property:\n\ntypeof(result) # AIMessage{SubString{String}}\npropertynames(result) # (:content, :status, :tokens, :elapsed\nresult.content # \"Hello! How can I assist you today?\"\n\n___ You can use string interpolation:\n\na = 1\nmsg=aigenerate(\"What is `$a+$a`?\")\nmsg.content # \"The sum of `1+1` is `2`.\"\n\n___ You can provide the whole conversation or more intricate prompts as a Vector{AbstractMessage}:\n\nconversation = [\n    SystemMessage(\"You're master Yoda from Star Wars trying to help the user become a Yedi.\"),\n    UserMessage(\"I have feelings for my iPhone. What should I do?\")]\nmsg=aigenerate(conversation)\n# AIMessage(\"Ah, strong feelings you have for your iPhone. A Jedi's path, this is not... <continues>\")\n\n\n\n\n\n","category":"method"},{"location":"#PromptingTools.render-Tuple{PromptingTools.AbstractOpenAISchema, Vector{<:PromptingTools.AbstractMessage}}","page":"Home","title":"PromptingTools.render","text":"Builds a history of the conversation to provide the prompt to the API. All kwargs are passed as replacements such that {{key}}=>value in the template.}}\n\n\n\n\n\n","category":"method"},{"location":"#PromptingTools.@aai_str-Tuple{Any, Vararg{Any}}","page":"Home","title":"PromptingTools.@aai_str","text":"aai\"user_prompt\"[model_alias] -> AIMessage\n\nAsynchronous version of @ai_str macro, which will log the result once it's ready.\n\nExample\n\nSend asynchronous request to GPT-4, so we don't have to wait for the response: Very practical with slow models, so you can keep working in the meantime.\n\n```julia m = aai\"Say Hi!\"gpt4; \n\n...with some delay...\n\n[ Info: Tokens: 29 @ Cost: 0.0011 in 2.7 seconds\n\n[ Info: AIMessage> Hello! How can I assist you today?\n\n\n\n\n\n","category":"macro"},{"location":"#PromptingTools.@ai_str-Tuple{Any, Vararg{Any}}","page":"Home","title":"PromptingTools.@ai_str","text":"ai\"user_prompt\"[model_alias] -> AIMessage\n\nThe ai\"\" string macro generates an AI response to a given prompt by using aigenerate under the hood.\n\nArguments\n\nuser_prompt (String): The input prompt for the AI model.\nmodel_alias (optional, any): Provide model alias of the AI model (see MODEL_ALIASES).\n\nReturns\n\nAIMessage corresponding to the input prompt.\n\nExample\n\nresult = ai\"Hello, how are you?\"\n# AIMessage(\"Hello! I'm an AI assistant, so I don't have feelings, but I'm here to help you. How can I assist you today?\")\n\nIf you want to interpolate some variables or additional context, simply use string interpolation:\n\na=1\nresult = ai\"What is `$a+$a`?\"\n# AIMessage(\"The sum of `1+1` is `2`.\")\n\nIf you want to use a different model, eg, GPT-4, you can provide its alias as a flag:\n\nresult = ai\"What is `1.23 * 100 + 1`?\"gpt4\n# AIMessage(\"The answer is 124.\")\n\n\n\n\n\n","category":"macro"}]
}