```@meta
CurrentModule = PromptingTools
```

# Coverage of Model Providers

PromptingTools.jl routes AI calls through the use of subtypes of AbstractPromptSchema, which determine how data is formatted and where it is sent. (For example, OpenAI models have the corresponding subtype AbstractOpenAISchema, having the corresponding schemas - OpenAISchema, CustomOpenAISchema, etc.) This ensures that the data is correctly formatted for the specific AI model provider. 

Below is an overview of the model providers supported by PromptingTools.jl, along with the corresponding schema information.

| Abstract Schema         | Schema                    | Model Provider                         | aigenerate | aiembed | aiextract | aiscan | aiimage | aiclassify |
|-------------------------|---------------------------|----------------------------------------|------------|---------|-----------|--------|---------|------------|
| AbstractOpenAISchema    | OpenAISchema              | OpenAI                                 | ✅         | ✅     | ✅       | ✅     | ✅     | ✅         |
| AbstractOpenAISchema    | CustomOpenAISchema*       | Any OpenAI-compatible API (eg, vLLM)*  | ✅         | ✅     | ✅       | ✅     | ✅     | ❌         |
| AbstractOpenAISchema    | LocalServerOpenAISchema** | Any OpenAI-compatible Local server**   | ✅         | ✅     | ✅       | ✅     | ✅     | ❌         |
| AbstractOpenAISchema    | MistralOpenAISchema       | Mistral AI                             | ✅         | ✅     | ✅       | ✅     | ✅     | ❌         |
| AbstractOpenAISchema    | DatabricksOpenAISchema    | Databricks                             | ✅         | ✅     | ✅       | ✅     | ✅     | ❌         |
| AbstractOpenAISchema    | FireworksOpenAISchema     | Fireworks AI                           | ✅         | ✅     | ✅       | ✅     | ✅     | ❌         |
| AbstractOpenAISchema    | TogetherOpenAISchema      | Together AI                            | ✅         | ✅     | ✅       | ✅     | ✅     | ❌         |
| AbstractOpenAISchema    | GroqOpenAISchema          | Groq                                   | ✅         | ❌     | ✅       | ❌     | ❌     | ❌         |
| AbstractOllamaSchema    | OllamaSchema              | Ollama (endpoint `api/chat`)           | ✅         | ✅     | ❌       | ✅     | ❌     | ❌         |
| AbstractManagedSchema   | AbstractOllamaManagedSchema | Ollama (endpoint `api/generate`)     | ✅         | ✅     | ❌       | ❌     | ❌     | ❌         |
| AbstractAnthropicSchema | AnthropicSchema           | Anthropic                              | ✅         | ❌     | ✅       | ❌     | ❌     | ❌         |
| AbstractGoogleSchema    | GoogleSchema              | Google Gemini                          | ✅         | ❌     | ❌       | ❌     | ❌     | ❌         |


\* Catch-all implementation - Requires providing a `url` with `api_kwargs` and corresponding API key.

\*\* This schema is a flavor of CustomOpenAISchema with a `url` key preset by global preference key `LOCAL_SERVER`. It is specifically designed for seamless integration with Llama.jl and utilizes an ENV variable for the URL, making integration easier in certain workflows, such as when nested calls are involved and passing `api_kwargs` is more challenging.

**Note:** The aiscan and aiimage functions rely on specific endpoints being implemented by the provider. Ensure that the provider you choose supports these functionalities.

For more detailed explanations of the functions and schema information, refer to [How It Works](https://siml.earth/PromptingTools.jl/dev/how_it_works#ai*-Functions-Overview).