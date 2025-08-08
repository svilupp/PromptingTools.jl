# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

### Updated

## [0.80.0]

### Breaking Changes
- Changed the default chat model to GPT-5 mini (`MODEL_CHAT` global variable).

### Added
- Added GPT-5 family models (gpt-5, gpt-5-mini, gpt-5-nano) with aliases (`gpt5`, `gpt5m`, `gpt5n`).
- Integrated Groq and Cerebras hosted GPT-OSS 120B and 20B models with aliases (`ggptoss120` for Groq, `cgptoss120` for Cerebras).
- Example demonstrating GPT-5-specific verbosity and reasoning effort controls (see `examples/gpt5_api_kwargs.jl`).
- Added Gemini 2.5 Flash Lite and Gemini 2.5 Flash models with aliases (`gem25fl` and `gem25f`, respectively).

## [0.79.0]

### Added
- Updated `ModelRegistry` docstrings to show all supported models and aliases (see `??ModelRegistry`). Thanks to @Kunzaatko for the PR!

## [0.78.0]

### Added
- Added support for Moonshot's Kimi K2 model (alias `k2` and `gk2` for the version hosted by Groq, save api key to `MOONSHOT_API_KEY`).
- Added support for xAI's Grok 4 model (alias `grok4`, save api key to `XAI_API_KEY`).

## [0.77.0]

### Updated
- Increased GoogleGenAI compat to v0.5, fixing support for system prompts 

## Fixed
- Increased compat for StreamCallbacks.jl to fix a bug

## [0.76.0]

### Added
- Added support for Anthropic's new web search tool and code execution tool (alias `:web_search` and `:code_execution`, respectively). See `?aitools` for more information.

### Updated
- Updated `claude` alias to point to the latest Claude 4.0 Sonnet model (same as `claudes`).

## [0.75.0]

###BREAKING CHANGES:
- Removed the `RAGTools` module. Please use the standalone [RAGTools.jl](https://github.com/JuliaGenAI/RAGTools.jl) package. See the migration guide in the docs & FAQ.
- Default chat model changed to GPT 4.1 mini (previously it was GPT 4o mini, variable `PromptingTools.MODEL_CHAT`).

### Added
- Added Claude 4 models (`claude-sonnet-4-20250514`, `claude-opus-4-20250514`) and set them as new defaults for aliases `claudeo` and`claudes` (Added specs for the new Claude 4 text editor as a ToolRef `:str_replace_based_edit_tool`).
- Added a Deepwiki.com badge for AI-powered repo documentation.
- Added Gemini 2.5 Flash Preview model from 20th May 2025 (alias `gem25f`).

### Updated
- Updated the OllamaManagedSchema to accept URLs with and without protocol to allow endpoints with `https://` (previously only `http://` was supported).
- Removed the `RAGTools` module.

### Fixed
- Fixed `@ai_str` macro to keep dynamic reference to your default model (`PromptingTools.MODEL_CHAT`). Prevents "baking in" the default model if PromptingTools is precompiled by another package.

## [0.74.3]

### Added
- Added support for Gemini 2.5 Pro and Flash preview models (aliases `gem25p` and `gem25f`, respectively).

## [0.74.2]

### Added
- Added support for OpenAI's O3 and O4-Mini reasoning models (aliases `o3` and `o4m`, respectively).

### Fixed
- Fixed a bug in the precompilation. If a user set `MODEL_CHAT` to be a non-OpenAI model, `aiclassify` would throw an error as it could not validate the tokenizer for correct functionality. Bypassed by forcing a specific tokenizer vocabulary (irrelevant for precompilation purposes).
- Fixed failing CI due to not publishing docs for `CustomRetryLayer`.

## [0.74.1]

### Added
- Added support for GPT-4.1 models (aliases `gpt41` for GPT 4.1, `gpt41m` for GPT 4.1 mini, `gpt41n` for GPT 4.1 nano; see details [here](https://openai.com/index/gpt-4-1/)).

## [0.74.0]

### Added
- Added support for extended output (up to 128K tokens) with Claude 3.7 models via the `:extended_output` beta header.

### Fixed
- Added validation to ensure that `thinking.budget_tokens` does not exceed `max_tokens` when using Anthropic API.

## [0.73.0]

### Added
- Added a new `enable_retry!` function to enable the retry layer for HTTP requests. Main use case is to prevent rate limiting errors from external AI services, but you can fully customize the retry behavior for any HTTP status codes, etc. See `?enable_retry!` for more information.

### Updated
- Updated the `StreamCallbacks` dependency to `0.6` to improve parsing of streaming responses with thinking from Anthropic.

## [0.72.3]

### Added
- Added a OpenAI's GPT 4.5 research preview (alias `gpt45`) to the model registry.

## [0.72.2]

### Added
- Added Claude 3.7 Sonnet model to the model registry (alias `claude37` and updated default `claude` alias to point to it).

## [0.72.1]

### Added
- Added Qwen models from OpenRouter API: Qwen Turbo, Plus and Max models with competitive pricing and 128K context window (aliases `orqwenturbo`, `orqwenplus` and `orqwenmax`, respectively).

## [0.72.0]

### Added
- Added new Gemini 2.0 Pro and Flash models to the model registry (aliases `gem20p` and `gem20f`, respectively). Added Gemini 2.0 Flash Lite Preview model (alias `gem20fl`) and Gemini 2.0 Flash Thinking Experimental model (alias `gem20ft`).
- Added BM25 normalization kwarg to `RAGTools.jl` to enable 0-1 query-specific normalization of BM25 scores for easier filtering and comparison. See `?RT.bm25` and `?RT.max_bm25_score` for more information.

## [0.71.0]

### Added
- Added the new OpenAI's O3 Mini reasoning model to the model registry (alias `o3m`).
- Added the new DeepSeek R1 Distill Llama 70b model hosted on GroqCloud, which beats GPT 4o in many benchmarks while being upto 10x cheaper (alias `glmr` - stands for Groq Llama Medium(70b) Reasoning).
- Added experimental support for "thinking tokens" that can be found with DeepSeek API and the reasoning model R1 (alias `dsr`). If the thought chain is provided, we save it in the `msg.extras[:reasoning_content]` field for advanced users.

## [0.70.0]

### Added
- Added new DeepSeek V3 model via Deepseek (alias `dschat` or simply `ds`, because they are in a category of their own), Fireworks.ai and Together.ai (`fds` and `tds` for hosted Deepseek V3, respectively). Added Qwen 2.5 Coder 32B (alias `fqwen25c` or `tqwen25c` for Fireworks.ai and Together.ai, respectively).
- Added the reasoning Qwen QwQ 32B hosted on Together.ai.
- Added the new OpenAI's O1 model to the model registry (alias `o1`).
- Added DeepSeek Reasoner model alias (`dsreason` or simply `dsr`) from DeepSeek
- Added MiniMax model support and alias (`minimax`) for MiniMax-Text-01 model

## [0.69.1]

### Fixed
- Added assertion in `response_to_message` for missing `:tool_calls` key in the response message. It's model failure but it wasn't obvious from the original error.
- Fixes error for usage information in CamelCase from OpenAI servers (Gemini proxy now sends it in CamelCase).

## [0.69.0]

### Added
- Added a new Gemini 2.0 Flash Experimental model (`gemini-2.0-flash-exp`) and updated the alias `gem20f` with it.

## [0.68.0]

### Added
- Added a new `cache=:all_but_last` cache strategy for Anthropic models to enable caching of the entire conversation except for the last user message (useful for longer conversations that you want to re-use, but not continue). See the docstrings for more information on which cache strategy to use.

## [0.67.0]

### Added
- Added a new Gemini Experimental model from December 2024 (`gemini-exp-1206`) and updated the `gemexp` alias to point to it.

## [0.66.0]

### Added
- Added support for Groq's new Llama3.3 models. Updated `gllama370`, `gl70`, `glm` aliases to `llama-3.3-70b-versatile` and added `gl70s`, `glms` aliases to `llama-3.3-70b-specdec` (faster with speculative decoding).

### Fixed
- Fixed a bug in `extract_docstring` where it would not correctly block "empty" docstrings on Julia 1.11.

## [0.65.1]

### Fixed
- Removed unnecessary printing to `stdout` during precompilation in `precompile.jl`.
- Fixed a "bug-waiting-to-happen" in tool use. `to_json_type` now enforces users to provide concrete types, because abstract types can lead to errors during JSON3 deserialization.
- Flowed through a bug fix in `StreamCallback` where the usage information was being included in the response even when `usage=nothing`. Lower bound of `StreamCallbacks` was bumped to `0.5.1`.

## [0.65.0]

### Breaking
- Changed the official ENV variable for MistralAI API from `MISTRALAI_API_KEY` to `MISTRAL_API_KEY` to be compatible with the Mistral docs.

### Added
- Added a new Gemini Experimental model from November 2024 (`gemini-exp-1121` with alias `gemexp`).
- Added a new `AnnotationMessage` type for keeping human-only information in the message changes. See `?annotate!` on how to use it.
- Added a new `ConversationMemory` type (exported) to enable long multi-turn conversations with a truncated memory of the conversation history. Truncation works in "batches" to not prevent caching. See `?ConversationMemory` and `get_last` for more information.


### Updated
- Changed the ENV variable for MistralAI API from `MISTRALAI_API_KEY` to `MISTRAL_API_KEY` to be compatible with the Mistral docs.

## [0.64.0]

### Added
- Added support for images in `aitools` to enable passing screenshots via `image_path` argument (extended to both OpenAI and Anthropic APIs, uses `?UserMessageWithImages` internally).
- Added the latest Gemini Experimental model via OpenAI compatibility mode (`gemini-exp-1114` with alias `gemexp`).

## [0.63.0]

### Added
- Added support for Google's Gemini API via OpenAI compatibility mode (`GoogleOpenAISchema`). Use model aliases `gem15p` (Gemini 1.5 Pro), `gem15f` (Gemini 1.5 Flash), and `gem15f8` (Gemini 1.5 Flash 8b). Set your ENV api key `GOOGLE_API_KEY` to use it.
- Thanks to @sixzero, added support for Google Flash via OpenRouter and Qwen 72b models.

## [0.62.1]

### Fixed
- Fixed a bug in `tool_call_signature` where hidden fields were not hidden early enough and would fail if a Dict argument was provided. It used to do the processing after, but Dicts cannot be processed, so we're now masking the fields upfront.

## [0.62.0]

### Added
- Added a new Claude 3.5 Haiku model (`claude-3-5-haiku-latest`) and updated the alias `claudeh` with it.
- Added support for XAI's Grok 2 beta model (`grok-beta`) and updated the alias `grok` with it. Set your ENV api key `XAI_API_KEY` to use it.

## [0.61.0]

### Added
- Added a new `extras` field to `ToolRef` to enable additional parameters in the tool signature (eg, `display_width_px`, `display_height_px` for the `:computer` tool).
- Added a new kwarg `unused_as_kwargs` to `execute_tool` to enable passing unused args as kwargs (see `?execute_tool` for more information). Helps with using kwarg-based functions.

### Updated
- Updated the compat bounds for `StreamCallbacks` to enable both v0.4 and v0.5 (Fixes Julia 1.9 compatibility).
- Updated the return type of `tool_call_signature` to `Dict{String, AbstractTool}` to enable better interoperability with different tool types.

## [0.60.0]

### Added
- Added new Claude 3.5 Sonnet model (`claude-3-5-sonnet-latest`) and updated the alias `claude` and `claudes` with it.
- Added support for Ollama streaming with schema `OllamaSchema` (see `?StreamCallback` for more information). Schema `OllamaManaged` is NOT supported (it's legacy and will be removed in the future).
- Moved the implementation of streaming callbacks to a new `StreamCallbacks` package.
- Added new error types for tool execution to enable better error handling and reporting (see `?AbstractToolError`).
- Added support for Anthropic's new pre-trained tools via `ToolRef` (see `?ToolRef`), to enable the feature, use the `:computer_use` beta header (eg, `aitools(..., betas = [:computer_use])`).

### Fixed
- Fixed a bug in `call_cost` where the cost was not calculated if any non-AIMessages were provided in the conversation.

## [0.59.1]

### Fixed
- Fixed a bug in multi-turn tool calls for OpenAI models where an empty tools array could have been, which causes an API error.

## [0.59.0]

### Breaking Changes
- New field `name` introduced in `AbstractChatMessage` and `AIToolRequest` messages to enable role-based workflows. It initializes to `nothing`, so it is backward compatible.

### Added
- Extends support for structured extraction with multiple "tools" definitions (see `?aiextract`).
- Added new primitives `Tool` (to re-use tool definitions) and a function `aitools` to support mixed structured and non-structured workflows, eg, agentic workflows (see `?aitools`).
- Added a field `name` to `AbstractChatMessage` and `AIToolRequest` messages to enable role-based workflows.
- Added a support for partial argument execution with `execute_tool` function (provide your own context to override the arg values).
- Added support for [SambaNova](https://sambanova.ai/) hosted models (set your ENV `SAMBANOVA_API_KEY`). 
- Added many new models from Mistral, Groq, Sambanova, OpenAI.

### Updated
- Renamed `function_call_signature` to `tool_call_signature` to better reflect that it's used for tools, but kept a link to the old name for back-compatibility.
- Improves structured extraction for Anthropic models (now you can use `tool_choice` keyword argument to specify which tool to use or re-use your parsed tools).
- When log probs are requested, we will now also log the raw information in `AIMessage.extras[:log_prob]` field (previously we logged only the full sum). This enables more nuanced log-probability calculations for individual tokens.

## [0.58.0]

### Added
- Added support for [Cerebras](https://cloud.cerebras.ai) hosted models (set your ENV `CEREBRAS_API_KEY`). Available model aliases: `cl3` (Llama3.1 8bn), `cl70` (Llama3.1 70bn).
- Added a kwarg to `aiclassify` to provide a custom token ID mapping (`token_ids_map`) to work with custom tokenizers.

### Updated
- Improved the implementation of `airetry!` to concatenate feedback from all ancestor nodes ONLY IF `feedback_inplace=true` (because otherwise LLM can see it in the message history).

### Fixed
- Fixed a potential bug in `airetry!` where the `aicall` object was not properly validated to ensure it has been `run!` first.

## [0.57.0]

### Added

- Support for [Azure OpenAI API](https://learn.microsoft.com/en-us/azure/ai-services/openai/reference). Requires two environment variables to be st: `AZURE_OPENAI_API_KEY` and `AZURE_OPENAI_HOST`(i.e. https://<resource-name>.openai.azure.com).

## [0.56.1]

### Fixed
- Removed accidental INFO log in Anthropic's `aigenerate`
- Changed internal logging in `streamcallback` to use `@debug` when printing raw data chunks.

## [0.56.0]

### Updated
- Enabled Streaming for OpenAI-compatible APIs (eg, DeepSeek Coder)
- If streaming to stdout, also print a newline at the end of streaming (to separate multiple outputs).

### Fixed
- Relaxed the type-assertions in `StreamCallback` to allow for more flexibility.

## [0.55.0]

### Added
- Added support for OpenAI's JSON mode for `aiextract` (just provide kwarg `json_mode=true`). Reference [Structured Outputs](https://platform.openai.com/docs/guides/structured-outputs).
- Added support for OpenRouter's API (you must set ENV `OPENROUTER_API_KEY`) to provide access to more models like Cohere Command R+ and OpenAI's o1 series. Reference [OpenRouter](https://openrouter.ai/).
- Added new OpenRouter hosted models to the model registry (prefixed with `or`): `oro1` (OpenAI's o1-preview), `oro1m` (OpenAI's o1-mini), `orcop` (Cohere's command-r-plus), `orco` (Cohere's command-r). The `or` prefix is to avoid conflicts with existing models and OpenAI's aliases, then the goal is to provide 2 letters for each model and 1 letter for additional qualifier (eg, "p" for plus, "m" for mini) -> `orcop` (OpenRouter cohere's COmmand-r-Plus).

### Updated
- Updated FAQ with instructions on how to access new OpenAI o1 models via OpenRouter.
- Updated FAQ with instructions on how to add custom APIs (with an example `examples/adding_custom_API.jl`).

### Fixed
- Fixed a bug in `aiclassify` for the OpenAI GPT4o models that have a different tokenizer. Unknown model IDs will throw an error.

## [0.54.0]

### Updated
- Improved the performance of BM25/Keywords-based indices for >10M documents. Introduced new kwargs of `min_term_freq` and `max_terms` in `RT.get_keywords` to reduce the size of the vocabulary. See `?RT.get_keywords` for more information.

## [0.53.0]

### Added
- Added beta headers to enable long outputs (up to 8K tokens) with Anthropic's Sonnet 3.5 (see `?anthropic_extra_headers`).
- Added a kwarg to prefill (`aiprefill`) AI responses with Anthropic's models to improve steerability (see `?aigenerate`).

### Updated
- Documentation of `aigenerate` to make it clear that if `streamcallback` is provide WITH `flavor` set, there is no automatic configuration and the user must provide the correct `api_kwargs`.
- Grouped Anthropic's beta headers as a comma-separated string as per the latest API specification.


## [0.52.0]

### Added
- Added a new EXPERIMENTAL `streamcallback` kwarg for `aigenerate` with the OpenAI and Anthropic prompt schema to enable custom streaming implementations. Simplest usage is simply with `streamcallback=stdout`, which will print each text chunk into the console. System is modular enabling custom callbacks and allowing you to inspect received chunks. See `?StreamCallback` for more information. It does not support tools yet.

## [0.51.0]

### Added
- Added more flexible structured extraction with `aiextract` -> now you can simply provide the field names and, optionally, their types without specifying the struct itself (in `aiextract`, provide the fields like `return_type = [:field_name => field_type]`). 
- Added a way to attach field-level descriptions to the generated JSON schemas to better structured extraction (see `?update_schema_descriptions!` to see the syntax), which was not possible with struct-only extraction.

## [0.50.0]

### Breaking Changes
- `AIMessage` and `DataMessage` now have a new field `extras` to hold any API-specific metadata in a simple dictionary. Change is backward-compatible (defaults to `nothing`).

### Added
- Added EXPERIMENTAL support for Anthropic's new prompt cache (see ?`aigenerate` and look for `cache` kwarg). Note that COST estimate will be wrong (ignores the caching discount for now).
- Added a new `extras` field to `AIMessage` and `DataMessage` to hold any API-specific metadata in a simple dictionary (eg, used for reporting on the cache hit/miss).

## [0.49.0]

### Added
- Added new OpenAI's model "chatgpt-4o-latest" to the model registry with alias "chatgpt". This model represents the latest version of ChatGPT-4o tuned specifically for ChatGPT.

## [0.48.0]

### Added
- Implements the new OpenAI structured output mode for `aiextract` (just provide kwarg `strict=true`). Reference [blog post](https://openai.com/index/introducing-structured-outputs-in-the-api/).

## [0.47.0]

### Added
- Added a new specialized method for `hcat(::DocumentTermMatrix, ::DocumentTermMatrix)` to allow for combining large DocumentTermMatrices (eg, 1M x 100K).

### Updated
- Increased the compat bound for HTTP.jl to 1.10.8 to fix a bug with Julia 1.11.

### Fixed
- Fixed a bug in `vcat_labeled_matrices` where extremely large DocumentTermMatrix could run out of memory.
- Fixed a bug in `score_to_unit_scale` where empty score vectors would error (now returns the empty array back).

## [0.46.0]

### Added
- Added a new model `gpt-4o-2024-08-06` to the model registry (alias `gpt4ol` with `l` for latest). It's the latest version of GPT4o, which is faster and cheaper than the previous version.

## [0.45.0]

### Breaking Change
- `getindex(::MultiIndex, ::MultiCandidateChunks)` now returns sorted chunks by default (`sorted=true`) to guarantee that potential `context` (=`chunks`) is sorted by descending similarity score across different sub-indices.

### Updated
- Updated a `hcat` implementation in `RAGTools.get_embeddings` to reduce memory allocations for large embedding batches (c. 3x fewer allocations, see `hcat_truncate`).
- Updated `length_longest_common_subsequence` signature to work only for pairs of `AbstractString` to not fail silently when wrong arguments are provided.

### Fixed
- Changed the default behavior of `getindex(::MultiIndex, ::MultiCandidateChunks)` to always return sorted chunks for consistency with other similar functions and correct `retrieve` behavior. This was accidentally changed in v0.40 and is now reverted to the original behavior.

## [0.44.0]

### Added
- Added Mistral Large 2 and Mistral-Nemo to the model registry (alias `mistral-nemo`).

### Fixed
- Fixed a bug where `wrap_string` would not correctly split very long Unicode words.

## [0.43.0]

### Added
- Added Llama 3.1 registry records for Fireworks.ai (alias `fllama3`, `fllama370`, `fllama3405` and `fls`, `flm`, `fll` for small/medium/large similar to the other providers).

## [0.42.0]

### Added
- Registered new Meta Llama 3.1 models hosted on GroqCloud and Together.ai (eg, Groq-hosted `gllama370` has been updated to point to the latest available model and 405b model now has alias `gllama3405`). Because that's quite clunky, I've added abbreviations based on sizes small/medium/large (that is 8b, 70b, 405b) under `gls/glm/gll` for Llama 3.1 hosted on GroqCloud (similarly, we now have `tls/tlm/tll` for Llama3.1 on Together.ai).
- Generic model aliases for Groq and Together.ai for Llama3 models have been updated to point to the latest available models (Llama 3.1).
- Added Gemma2 9b model hosted on GroqCloud to the model registry (alias `ggemma9`).

### Updated
- Minor optimizations to `SubDocumentTermMatrix` to reduce memory allocations and improve performance.

## [0.41.0]

### Added 
- Introduced a "view" of `DocumentTermMatrix` (=`SubDocumentTermMatrix`) to allow views of Keyword-based indices (`ChunkKeywordsIndex`). It's not a pure view (TF matrix is materialized to prevent performance degradation).

### Fixed
- Fixed a bug in `find_closest(finder::BM25Similarity, ...)` where the view of `DocumentTermMatrix` (ie, `view(DocumentTermMatrix(...), ...)`) was undefined.
- Fixed a bug where a view of a view of a `ChunkIndex` wouldn't intersect the positions (it was returning only the latest requested positions).

## [0.40.0]

### Added
- Introduces `RAGTools.SubChunkIndex` to allow projecting `views` of various indices. Useful for pre-filtering your data (faster and more precise retrieval). See `?RT.SubChunkIndex` for more information and how to use it.

### Updated
- `CandidateChunks` and `MultiCandidateChunks` intersection methods updated to be an order of magnitude faster (useful for large sets like tag filters).

### Fixed 
- Fixed a bug in `find_closest(finder::BM25Similarity, ...)` where `minimum_similarity` kwarg was not implemented.

## [0.39.0]

### Breaking Changes
- Changed the default model for `ai*` chat functions (`PT.MODEL_CHAT`) from `gpt3t` to `gpt4om` (GPT-4o-mini). See the LLM-Leaderboard results and the release [blog post](https://openai.com/index/gpt-4o-mini-advancing-cost-efficient-intelligence/).

### Added
- Added the new GPT-4o-mini to the model registry (alias `gpt4om`). It's the smallest and fastest model based on GPT4 that is cheaper than GPT3.5Turbo.

## [0.38.0]

### Added
- Added a new tagging filter `RT.AllTagFilter` to `RT.find_tags`, which requires all tags to be present in a chunk.
- Added an option in `RT.get_keywords` to set the minimum length of the keywords.
- Added a new method for `reciprocal_rank_fusion` and utility for standardizing candidate chunk scores (`score_to_unit_scale`).

## [0.37.1]

### Fixed
- Fixed a bug in CohereReranker when it wouldn't handle correctly CandidateChunks.

## [0.37.0]

### Updated
- Increase compat bound for FlashRank to 0.4

## [0.36.0]

### Added
- Added a prompt template for RAG query expansion for BM25 (`RAGQueryKeywordExpander`)

### Fixed
- Fixed a small bug in the truncation step of the RankGPT's `permutation_step!` (bad indexing of string characters).
- Fixed a bug where a certain combination of `rank_start` and `rank_end` would not result the last sliding window.
- Fixed a bug where partially filled `RAGResult` would fail pretty-printing with `pprint`

## [0.35.0]

### Added
- Added a utility function to RAGTools `reciprocal_rank_fusion`, as a principled way to merge multiple rankings. See `?RAGTools.Experimental.reciprocal_rank_fusion` for more information.

## [0.34.0]

### Added
- `RankGPT` implementation for RAGTools chunk re-ranking pipeline. See `?RAGTools.Experimental.rank_gpt` for more information and corresponding reranker type `?RankGPTReranker`.

## [0.33.2]

### Fixed
- Add back accidentally dropped DBKS keys

## [0.33.1]

### Fixed
- Fixed loading RAGResult when one of the candidate fields was `nothing`.
- Utility type checks like `isusermessage`, `issystemmessage`, `isdatamessage`, `isaimessage`, `istracermessage` do not throw errors when given any arbitrary input types (previously they only worked for `AbstractMessage` types). It's a `isa` check, so it should work for all input types.
- Changed preference loading to use typed `global` instead of `const`, to fix issues with API keys not being loaded properly on start. You can now also call `PromptingTools.load_api_keys!()` to re-load the API keys (and ENV variables) manually.

## [0.33.0]

### Added
- Added registry record for Anthropic Claude 3.5 Sonnet with ID `claude-3-5-sonnet-20240620` (read the [blog post](https://www.anthropic.com/news/claude-3-5-sonnet)). Aliases "claude" and "claudes" have been linked to this latest Sonnet model.

## [0.32.0]

### Updated
- Changed behavior of `RAGTools.rerank(::FlashRanker,...)` to always dedupe input chunks (to reduce compute requirements).

### Fixed
- Fixed a bug in verbose INFO log in `RAGTools.rerank(::FlashRanker,...)`.

## [0.31.1]

### Updated
- Improved the implementation of `RAGTools.unpack_bits` to be faster with fewer allocations.

## [0.31.0]

### Breaking Changes
- The return type of `RAGTools.find_tags(::NoTagger,...)` is now `::Nothing` instead of `CandidateChunks`/`MultiCandidateChunks` with all documents.
- `Base.getindex(::MultiIndex, ::MultiCandidateChunks)` now always returns sorted chunks for consistency with the behavior of other `getindex` methods on `*Chunks`. 

### Updated
- Cosine similarity search now uses `partialsortperm` for better performance on large datasets.
- Skip unnecessary work when the tagging functionality in the RAG pipeline is disabled (`find_tags` with `NoTagger` always returns `nothing` which improves the compiled code).
- Changed the default behavior of `getindex(::MultiIndex, ::MultiCandidateChunks)` to always return sorted chunks for consistency with other similar functions. Note that you should always use re-rankering anyway (see `FlashRank.jl`).

## [0.30.0]

### Fixed
- Fixed a bug on Julia 1.11 beta by adding REPL stdlib as a direct dependency.
- Fixed too restrictive argument types for `RAGTools.build_tags` method.

## [0.29.0]

### Added
- Added package extension for FlashRank.jl to support local ranking models. See `?RT.FlashRanker` for more information or `examples/RAG_with_FlashRank.jl` for a quick example.


## [0.28.0]

### Added
- Added Mistral coding-oriented [Codestral](https://mistral.ai/news/codestral/) to the model registry, aliased as `codestral` or `mistralc`. It's very fast, performant and much cheaper than similar models.

## [0.27.0]

### Added
- Added a keyword-based search similarity to RAGTools to serve both for baseline evaluation and for advanced performance (by having a hybrid index with both embeddings and BM25). See `?RT.KeywordsIndexer` and `?RT.BM25Similarity` for more information, to build use `build_index(KeywordsIndexer(), texts)` or convert an existing embeddings-based index `ChunkKeywordsIndex(index)`.

### Updated
- For naming consistency, `ChunkIndex` in RAGTools has been renamed to `ChunkEmbeddingsIndex` (with an alias `ChunkIndex` for backwards compatibility). There are now two main index types: `ChunkEmbeddingsIndex` and `ChunkKeywordsIndex` (=BM25), which can be combined into a `MultiIndex` to serve as a hybrid index.

## [0.26.2]

### Fixed
- Fixed a rare bug where prompt templates created on MacOS will come with metadata that breaks the prompt loader. From now on, it ignores any dotfiles (hidden files starting with ".").

## [0.26.1]

### Fixed
- Fixed a bug where utility `length_longest_common_subsequence` was not working with complex Unicode characters

## [0.26.0]

### BREAKING CHANGES
- Added new field `meta` to `TracerMessage` and `TracerMessageLike` to hold metadata in a simply dictionary. Change is backward-compatible.
- Changed behaviour of `aitemplates(name::Symbol)` to look for the exact match on the template name, not just a partial match. This is a breaking change for the `aitemplates` function only. Motivation is that having multiple matches could have introduced subtle bugs when looking up valid placeholders for a template.

### Added
- Improved support for `aiclassify` with OpenAI models (you can now encode upto 40 choices).
- Added a template for routing questions `:QuestionRouter` (to be used with `aiclassify`)
- Improved tracing by `TracerSchema` to automatically capture crucial metadata such as any LLM API kwargs (`api_kwargs`), use of prompt templates and its version. Information is captured in `meta(tracer)` dictionary. See `?TracerSchema` for more information.
- New tracing schema `SaverSchema` allows to automatically serialize all conversations. It can be composed with other tracing schemas, eg, `TracerSchema` to automatically capture necessary metadata and serialize. See `?SaverSchema` for more information.
- Updated options for Binary embeddings (refer to release v0.18 for motivation). Adds utility functions `pack_bits` and `unpack_bits` to move between binary and UInt64 representations of embeddings. RAGTools adds the corresponding `BitPackedBatchEmbedder` and `BitPackedCosineSimilarity` for fast retrieval on these Bool<->UInt64 embeddings (credit to [**domluna's tinyRAG**](https://github.com/domluna/tinyRAG)).

### Fixed
- Fixed a bug where `aiclassify` would not work when returning the full conversation for choices with extra descriptions

## [0.25.0]

### Added
- Added model registry record for the latest OpenAI GPT4 Omni model (`gpt4o`) - it's as good as GPT4, faster and cheaper.

## [0.24.0]

### Added
- Added support for [DeepSeek models](https://platform.deepseek.com/docs) via the `dschat` and `dscode` aliases. You can set the `DEEPSEEK_API_KEY` environment variable to your DeepSeek API key.


## [0.23.0]

### Added
- Added new prompt templates for "Expert" tasks like `LinuxBashExpertAsk`, `JavascriptExpertTask`, etc.
- Added new prompt templates for self-critiquing agents like `ChiefEditorTranscriptCritic`, `JuliaExpertTranscriptCritic`, etc.

### Updated
- Extended `aicodefixer_feedback` methods to work with `AICode` and `AIGenerate`.

## [0.22.0]

### Added
- Added support for [Groq](https://console.groq.com/), the fastest LLM provider out there. It's free for now, so you can try it out - you just need to set your `GROQ_API_KEY`. We've added Llama3 8b (alias "gllama3"), 70b (alias "gllama370") and Mixtral 8x7b (alias "gmixtral"). For the shortcut junkies, we also added a shorthand Llama3 8b = "gl3" (first two letters and the last digit), Llama3 70b = "gl70" (first two letters and the last two digits).

## [0.21.0]

### Added
- New models added to the model registry: Llama3 8b on Ollama (alias "llama3" for convenience) and on Together.ai (alias "tllama3", "t" stands for Together.ai), also adding the llama3 70b on Together.ai (alias "tllama370") and the powerful Mixtral-8x22b on Together.ai (alias "tmixtral22").

### Fixed
- Fixed a bug where pretty-printing `RAGResult` would forget a newline between the sources and context sections.

## [0.20.1]

### Fixed
- Fixed `truncate_dimension` to ignore when 0 is provided (previously it would throw an error).

## [0.20.0]

### Added
- Added a few new open-weights models hosted by Fireworks.ai to the registry (DBRX Instruct, Mixtral 8x22b Instruct, Qwen 72b). If you're curious about how well they work, try them!
- Added basic support for observability downstream. Created custom callback infrastructure with `initialize_tracer` and `finalize_tracer` and dedicated types are `TracerMessage` and `TracerMessageLike`. See `?TracerMessage` for more information and the corresponding `aigenerate` docstring.
- Added `MultiCandidateChunks` which can hold candidates for retrieval across many indices (it's a flat structure to be similar to `CandidateChunks` and easy to reason about).
- JSON serialization support extended for `RAGResult`, `CandidateChunks`, and `MultiCandidateChunks` to increase observability of RAG systems
- Added a new search refiner `TavilySearchRefiner` - it will search the web via Tavily API to try to improve on the RAG answer (see `?refine!`).
- Introduced a few small utilities for manipulation of nested kwargs (necessary for RAG pipelines), check out `getpropertynested`, `setpropertynested`, `merge_kwargs_nested`.

### Updated
- [BREAKING] change to `CandidateChunks` where it's no longer allowed to be nested (ie, `cc.positions` being a list of several `CandidateChunks`). This is a breaking change for the `RAGTools` module only. We have introduced a new `MultiCandidateChunks` types that can refer to `CandidateChunks` across many indices.
- Changed default model for `RAGTools.CohereReranker` to "cohere-rerank-english-v3.0".

### Fixed
- `wrap_string` utility now correctly splits only on spaces. Previously it would split on newlines, which would remove natural formatting of prompts/messages when displayed via `pprint`

## [0.19.0]

### Added
- [BREAKING CHANGE] The default GPT-4 Turbo model alias ("gpt4t") now points to the official GPT-4 Turbo endpoint ("gpt-4-turbo").
- Adds references to `mistral-tiny` (7bn parameter model from MistralAI) to the model registry for completeness.
- Adds the new GPT-4 Turbo model (`"gpt-4-turbo-2024-04-09"`), but you can simply use alias `"gpt4t"` to access it.

## [0.18.0]

### Added
- Adds support for binary embeddings in RAGTools (dispatch type for `find_closest` is `finder=BinaryCosineSimilarity()`), but you can also just convert the embeddings to binary yourself (always choose `Matrix{Bool}` for speed, not `BitMatrix`) and use without any changes (very little performance difference at the moment).
- Added Ollama embedding models to the model registry ("nomic-embed-text", "mxbai-embed-large") and versioned MistralAI models.
- Added template for data extraction with Chain-of-thought reasoning: `:ExtractDataCoTXML`.
- Added data extraction support for Anthropic models (Claude 3) with `aiextract`. Try it with Claude-3 Haiku (`model="claudeh"`) and Chain-of-though template (`:ExtractDataCoTXML`). See `?aiextract` for more information and check Anthropic's [recommended practices](https://docs.anthropic.com/claude/docs/tool-use).

## [0.17.1]

### Fixed
- Fixed a bug in `print_html` where the custom kwargs were not being passed to the `HTML` constructor.

## [0.17.0]

### Added
- Added support for `aigenerate` with Anthropic API. Preset model aliases are `claudeo`, `claudes`, and `claudeh`, for Claude 3 Opus, Sonnet, and Haiku, respectively.
- Enabled the GoogleGenAI extension since `GoogleGenAI.jl` is now officially registered. You can use `aigenerate` by setting the model to `gemini` and providing the `GOOGLE_API_KEY` environment variable.
- Added utilities to make preparation of finetuning datasets easier. You can now export your conversations in JSONL format with ShareGPT formatting (eg, for Axolotl). See `?PT.save_conversations` for more information.
- Added `print_html` utility for RAGTools module to print HTML-styled RAG answer annotations for web applications (eg, Genie.jl). See `?PromptingTools.Experimental.RAGTools.print_html` for more information and examples.

## [0.16.1]

### Fixed
- Fixed a bug where `set_node_style!` was not accepting any Stylers except for the vanilla `Styler`.

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
- Added support for MistralAI API via the MistralOpenAISchema(). All their standard models have been registered, so you should be able to just use `model="mistral-tiny` in your `aigenerate` calls without any further changes. Remember to either provide `api_kwargs.api_key` or ensure you have ENV variable `MISTRALAI_API_KEY` set. Note: This has been since changed to `MISTRAL_API_KEY` to be compatible with the Mistral docs, refer to the versions after v0.65.
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
