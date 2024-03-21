# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

### Fixed

## [0.16.0]

### Added
- Added pretty-printing via `PT.pprint` that does NOT depend on Markdown and splits text to adjust to the width of the output terminal.
  It is useful in notebooks to add new lines.
- Added support annotations for RAGTools (see `?RAGTools.Experimental.annotate_support` for more information) to highlight which parts of the generated answer come from the provided context versus the model's knowledge base. It's useful for transparency and debugging, especially in the context of AI-generated content. You can experience it if you run the output of `airag` through pretty printing (`PT.pprint`).
- Added utility `distance_longest_common_subsequence` to find the normalized distance between two strings (or a vector of strings). Always returns a number between 0-1, where 0 means the strings are identical and 1 means they are completely different. It's useful for comparing the similarity between the context provided to the model and the generated answer.
- Added a new documentation section "Extra Tools" to highlight key functionality in various modules, eg, the available text utilities, which were previously hard to discover.
- Extended documentation FAQ with tips on tackling rate limits and other common issues with OpenAI API.
- Extended documentation with all available prompt templates. See section "Prompt Templates" in the documentation.
- Added new RAG interface underneath `airag` in `PromptingTools.RAGTools.Experimental`. Each step now has a dedicated function and a type that can be customized to achieve arbitrary logic (via defining methods for your own types). `airag` is split into two main steps: `retrieve` and `generate!`. You can use them separately or together. See `?airag` for more information.

### Updated
- Renamed `split_by_length` text splitter to `recursive_splitter` to make it easier to discover and understand its purpose. `split_by_length` is still available as a deprecated alias.

### Fixed
- Fixed a bug where `LOCAL_SERVER` default value was not getting picked up. Now, it defaults to `http://localhost:10897/v1` if not set in the preferences, which is the address of the OpenAI-compatible server started by Llama.jl.
- Fixed a bug in multi-line code annotation, which was assigning too optimistic scores to the generated code. Now the score of the chunk is the length-weighted score of the "top" source chunk divided by the full length of score tokens (much more robust and demanding).

## [0.15.0]

### Added
- Added experimental support for image generation with OpenAI DALL-E models, eg, `msg = aiimage("A white cat on a car")`. See `?aiimage` for more details.

## [0.14.0]

### Added
- Added a new documentation section "How it works" to explain the inner workings of the package. It's a work in progress, but it should give you a good idea of what's happening under the hood.
- Improved template loading, so if you load your custom templates once with `load_templates!("my/template/folder)`, it will remember your folder for all future re-loads.
- Added convenience function `create_template` to create templates on the fly without having to deal with `PT.UserMessage` etc. If you specify the keyword argument `load_as = "MyName"`, the template will be immediately loaded to the template registry. See `?create_template` for more information and examples.

### Fixed

## [0.13.0]

### Added
- Added initial support for Google Gemini models for `aigenerate` (requires environment variable `GOOGLE_API_KEY` and package [GoogleGenAI.jl](https://github.com/tylerjthomas9/GoogleGenAI.jl) to be loaded). It must be added explicitly as it is not yet registered.
- Added a utility to compare any two string sequences (and other iterators)`length_longest_common_subsequence`. It can be used to fuzzy match strings (eg, detecting context/sources in an AI-generated response or fuzzy matching AI response to some preset categories). See the docstring for more information `?length_longest_common_subsequence`.
- Rewrite of `aiclassify` to classify into an arbitrary list of categories (including with descriptions). It's a quick and easy option for "routing" and similar use cases, as it exploits the logit bias trick and outputs only 1 token. Currently, only `OpenAISchema` is supported. See `?aiclassify` for more information.
- Initial support for multiple completions in one request for OpenAI-compatible API servers. Set via API kwarg `n=5` and it will request 5 completions in one request, saving the network communication time and paying the prompt tokens only once. It's useful for majority voting, diversity, or challenging agentic workflows.
- Added new fields to `AIMessage` and `DataMessage` types to simplify tracking in complex applications. Added fields: 
  - `cost` - the cost of the query (summary per call, so count only once if you requested multiple completions in one call)
  - `log_prob` - summary log probability of the generated sequence, set API kwarg `logprobs=true` to receive it
  - `run_id`  - ID of the AI API call
  - `sample_id` - ID of the sample in the batch if you requested multiple completions, otherwise `sample_id==nothing` (they will have the same `run_id`)
  - `finish_reason` - the reason why the AI stopped generating the sequence (eg, "stop", "length") to provide more visibility for the user
- Support for Fireworks.ai and Together.ai providers for fast and easy access to open-source models. Requires environment variables `FIREWORKS_API_KEY` and `TOGETHER_API_KEY` to be set, respectively. See the `?FireworksOpenAISchema` and `?TogetherOpenAISchema` for more information.
- Added an `extra` field to `ChunkIndex` object for RAG workloads to allow additional flexibility with metadata for each document chunk (assumed to be a vector of the same length as the document chunks).
- Added `airetry` function to `PromptingTools.Experimental.AgentTools` to allow "guided" automatic retries of the AI calls (eg, `AIGenerate` which is the "lazy" counterpart of `aigenerate`) if a given condition fails. It's useful for robustness and reliability in agentic workflows. You can provide conditions as functions and the same holds for feedback to the model as well. See a guessing game example in `?airetry`.

## Updated
- Updated names of endpoints and prices of Mistral.ai models as per the [latest announcement](https://mistral.ai/technology/#models) and [pricing](https://docs.mistral.ai/platform/pricing/). Eg, `mistral-small` -> `mistral-small-latest`. In addition, the latest Mistral model has been added `mistral-large-latest` (aliased as `mistral-large` and `mistrall`, same for the others). `mistral-small-latest` and `mistral-large-latest` now support function calling, which means they will work with `aiextract` (You need to explicitly provide `tool_choice`, see the docs `?aiextract`).

## Removed 
- Removed package extension for GoogleGenAI.jl, as it's not yet registered. Users must load the code manually for now.

## [0.12.0]

### Added
- Added more specific kwargs in `Experimental.RAGTools.airag` to give more control over each type of AI call (ie, `aiembed_kwargs`, `aigenerate_kwargs`, `aiextract_kwargs`)
- Move up compat bounds for OpenAI.jl to 0.9

### Fixed
- Fixed a bug where obtaining an API_KEY from ENV would get precompiled as well, causing an error if the ENV was not set at the time of precompilation. Now, we save the `get(ENV...)` into a separate variable to avoid being compiled away.

## [0.11.0]

### Added
- Support for [Databricks Foundation Models API](https://docs.databricks.com/en/machine-learning/foundation-models/index.html). Requires two environment variables to be set: `DATABRICKS_API_KEY` and `DATABRICKS_HOST` (the part of the URL before `/serving-endpoints/`)
- Experimental support for API tools to enhance your LLM workflows: `Experimental.APITools.create_websearch` function which can execute and summarize a web search (incl. filtering on specific domains). It requires `TAVILY_API_KEY` to be set in the environment. Get your own key from [Tavily](https://tavily.com/) - the free tier enables c. 1000 searches/month, which should be more than enough to get started.

### Fixed
- Added an option to reduce the "batch size" for the embedding step in building the RAG index (`build_index`, `get_embeddings`). Set `embedding_kwargs = (; target_batch_size_length=10_000, ntasks=1)` if you're having some limit issues with your provider.
- Better error message if RAGTools are only partially imported (requires `LinearAlgebra` and `SparseArrays` to load the extension).

## [0.10.0]

### Added
- [BREAKING CHANGE] The default embedding model (`MODEL_EMBEDDING`) changes to "text-embedding-3-small" effectively immediately (lower cost, higher performance). The default chat model (`MODEL_CHAT`) will be changed by OpenAI to 0125 (from 0613) by mid-February. If you have older embeddings or rely on the exact chat model version, please set the model explicitly in your code or in your preferences. 
- New OpenAI models added to the model registry (see the [release notes](https://openai.com/blog/new-embedding-models-and-api-updates)).
  - "gpt4t" refers to whichever is the latest GPT-4 Turbo model ("gpt-4-0125-preview" at the time of writing)
  - "gpt3t" refers to the latest GPT-3.5 Turbo model version 0125, which is 25-50% cheaper and has updated knowledge (available from February 2024, you will get an error in the interim)
  - "gpt3" still refers to the general endpoint "gpt-3.5-turbo", which OpenAI will move to version 0125 by mid-February (ie, "gpt3t" will be the same as "gpt3" then. We have reflected the approximate cost in the model registry but note that it will be incorrect in the transition period)
  - "emb3small" refers to the small version of the new embedding model (dim=1536), which is 5x cheaper than Ada and promises higher quality
  - "emb3large" refers to the large version of the new embedding model (dim=3072), which is only 30% more expensive than Ada
- Improved AgentTools: added more information and specific methods to `aicode_feedback` and `error_feedback` to pass more targeted feedback/tips to the AIAgent
- Improved detection of which lines were the source of error during `AICode` evaluation + forcing the error details to be printed in `AICode(...).stdout` for downstream analysis.
- Improved detection of Base/Main method overrides in `AICode` evaluation (only warns about the fact), but you can use `detect_base_main_overrides(code)` for custom handling

### Fixed
- Fixed typos in the documentation
- Fixed a bug when API keys set in ENV would not be picked up by the package (caused by inlining of the `get(ENV,...)` during precompilation)
- Fixed string interpolation to be correctly escaped when evaluating `AICode`

## [0.9.0]

### Added
- Split `Experimental.RAGTools.build_index` into smaller functions to easier sharing with other packages (`get_chunks`, `get_embeddings`, `get_metadata`)
- Added support for Cohere-based RAG re-ranking strategy (and introduced associated `COHERE_API_KEY` global variable and ENV variable)

### Fixed

## [0.8.1]

### Fixed
- Fixed `split_by_length` to not mutate `separators` argument (appeared in RAG use cases where we repeatedly apply splits to different documents)

## [0.8.0]

### Added
- Initial support for [Llama.jl](https://github.com/marcom/Llama.jl) and other local servers. Once your server is started, simply use `model="local"` to route your queries to the local server, eg, `ai"Say hi!"local`. Option to permanently set the `LOCAL_SERVER` (URL) added to preference management. See `?LocalServerOpenAISchema` for more information.
- Added a new template `StorytellerExplainSHAP` (see the metadata)

### Fixed
- Repeated calls to Ollama models were failing due to missing `prompt_eval_count` key in subsequent calls.

## [0.7.0]

### Added
- Added new Experimental sub-module AgentTools introducing `AICall` (incl. `AIGenerate`), and `AICodeFixer` structs. The AICall struct provides a "lazy" wrapper for ai* functions, enabling efficient and flexible AI interactions and building Agentic workflows.
- Added the first AI Agent: `AICodeFixer` which iteratively analyzes and improves any code provided by a LLM by evaluating it in a sandbox. It allows a lot of customization (templated responses, feedback function, etc.) See `?AICodeFixer` for more information on usage and `?aicodefixer_feedback` for the example implementation of the feedback function.
- Added `@timeout` macro to allow for limiting the execution time of a block of code in `AICode` via `execution_timeout` kwarg (prevents infinite loops, etc.). See `?AICode` for more information.
- Added `preview(conversation)` utility that allows you to quickly preview the conversation in a Markdown format in your REPL. Requires `Markdown` package for the extension to be loaded.
- Added `ItemsExtract` convenience wrapper for `aiextract` when you want to extract one or more of a specific `return_type` (eg, `return_type = ItemsExtract{MyMeasurement}`)

### Fixed
- Fixed `aiembed` to accept any AbstractVector of documents (eg, a view of a vector of documents)

## [0.6.0]

### Added
- `@ai_str` macros now support multi-turn conversations. The `ai"something"` call will automatically remember the last conversation, so you can simply reply with `ai!"my-reply"`. If you send another message with `ai""`, you'll start a new conversation. Same for the asynchronous versions `aai""` and `aai!""`.
- Created a new default schema for Ollama models `OllamaSchema` (replacing `OllamaManagedSchema`), which allows multi-turn conversations and conversations with images (eg, with Llava and Bakllava models). `OllamaManagedSchema` has been kept for compatibility and as an example of a schema where one provides the prompt as a string (not dictionaries like OpenAI API).

### Fixed
- Removed template `RAG/CreateQAFromContext` because it's a duplicate of `RAG/RAGCreateQAFromContext`

## [0.5.0]

### Added
- Experimental sub-module RAGTools providing basic Retrieval-Augmented Generation functionality. See `?RAGTools` for more information. It's all nested inside of `PromptingTools.Experimental.RAGTools` to signify that it might change in the future. Key functions are `build_index` and `airag`, but it also provides a suite to make evaluation easier (see `?build_qa_evals` and `?run_qa_evals` or just see the example `examples/building_RAG.jl`)

### Fixed
- Stricter code parsing in `AICode` to avoid false positives (code blocks must end with "```\n" to catch comments inside text)
- Introduced an option `skip_invalid=true` for `AICode`, which allows you to include only code blocks that parse successfully (useful when the code definition is good, but the subsequent examples are not), and an option `capture_stdout=false` to avoid capturing stdout if you want to evaluate `AICode` in parallel (`Pipe()` that we use is NOT thread-safe)
- `OllamaManagedSchema` was passing an incorrect model name to the Ollama server, often serving the default llama2 model instead of the requested model. This is now fixed.
- Fixed a bug in kwarg `model` handling when leveraging PT.MODEL_REGISTRY

## [0.4.0]

### Added
- Improved AICode parsing and error handling (eg, capture more REPL prompts, detect parsing errors earlier, parse more code fence types), including the option to remove unsafe code (eg, `Pkg.add("SomePkg")`) with `AICode(msg; skip_unsafe=true, vebose=true)`
- Added new prompt templates: `JuliaRecapTask`, `JuliaRecapCoTTask`, `JuliaExpertTestCode` and updated `JuliaExpertCoTTask` to be more robust against early stopping for smaller OSS models
- Added support for MistralAI API via the MistralOpenAISchema(). All their standard models have been registered, so you should be able to just use `model="mistral-tiny` in your `aigenerate` calls without any further changes. Remember to either provide `api_kwargs.api_key` or ensure you have ENV variable `MISTRALAI_API_KEY` set.
- Added support for any OpenAI-compatible API via `schema=CustomOpenAISchema()`. All you have to do is to provide your `api_key` and `url` (base URL of the API) in the `api_kwargs` keyword argument. This option is useful if you use [Perplexity.ai](https://docs.perplexity.ai/), [Fireworks.ai](https://app.fireworks.ai/), or any other similar services.

## [0.3.0]

### Added
- Introduced a set of utilities for working with generate Julia code (Eg, extract code-fenced Julia code with `PromptingTools.extract_code_blocks` ) or simply apply `AICode` to the AI messages. `AICode` tries to extract, parse and eval Julia code, if it fails both stdout and errors are captured. It is useful for generating Julia code and, in the future, creating self-healing code agents 
- Introduced ability to have multi-turn conversations. Set keyword argument `return_all=true` and `ai*` functions will return the whole conversation, not just the last message. To continue a previous conversation, you need to provide it to a keyword argument `conversation`
- Introduced schema `NoSchema` that does not change message format, it merely replaces the placeholders with user-provided variables. It serves as the first pass of the schema pipeline and allow more code reuse across schemas
- Support for project-based and global user preferences with Preferences.jl. See `?PREFERENCES` docstring for more information. It allows you to persist your configuration and model aliases across sessions and projects (eg, if you would like to default to Ollama models instead of OpenAI's)
- Refactored `MODEL_REGISTRY` around `ModelSpec` struct, so you can record the name, schema(!) and token cost of new models in a single place. The biggest benefit is that your `ai*` calls will now automatically lookup the right model schema, eg, no need to define schema explicitly for your Ollama models! See `?ModelSpec` for more information and `?register_model!`for an example of how to register a new model

### Fixed
- Changed type of global `PROMPT_SCHEMA::AbstractPromptSchema` for an easier switch to local models as a default option

### Breaking Changes
- `API_KEY` global variable has been renamed to `OPENAI_API_KEY` to align with the name of the environment variable and preferences

## [0.2.0]

### Added

- Add support for prompt templates with `AITemplate` struct. Search for suitable templates with `aitemplates("query string")` and then simply use them with `aigenerate(AITemplate(:TemplateABC); variableX = "some value") -> AIMessage` or use a dispatch on the template name as a `Symbol`, eg, `aigenerate(:TemplateABC; variableX = "some value") -> AIMessage`. Templates are saved as JSON files in the folder `templates/`. If you add new templates, you can reload them with `load_templates!()` (notice the exclamation mark to override the existing `TEMPLATE_STORE`).
- Add `aiextract` function to extract structured information from text quickly and easily. See `?aiextract` for more information.
- Add `aiscan` for image scanning (ie, image comprehension tasks). You can transcribe screenshots or reason over images as if they were text. Images can be provided either as a local file (`image_path`) or as an url (`image_url`). See `?aiscan` for more information.
- Add support for [Ollama.ai](https://ollama.ai/)'s local models. Only `aigenerate` and `aiembed` functions are supported at the moment.
- Add a few non-coding templates, eg, verbatim analysis (see `aitemplates("survey")`) and meeting summarization (see `aitemplates("meeting")`), and supporting utilities (non-exported): `split_by_length` and `replace_words` to make it easy to work with smaller open source models.
