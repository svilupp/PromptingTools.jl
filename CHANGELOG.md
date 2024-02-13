# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

### Fixed

## [0.11.0]

### Added
- Support for [Databricks Foundation Models API](https://docs.databricks.com/en/machine-learning/foundation-models/index.html). Requires two environment variables to be set: `DATABRICKS_API_KEY` and `DATABRICKS_HOST` (the part of the URL before `/serving-endpoints/`)

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