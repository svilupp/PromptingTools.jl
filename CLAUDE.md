# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Development Commands

### Testing
- `julia --project=. -e "using Pkg; Pkg.test()"` - Run all tests
- `julia --project=. test/runtests.jl` - Run tests directly

### Code Quality
- `julia --project=. -e "using JuliaFormatter; format(\".\")"` - Format code using SciML style (configured in .JuliaFormatter.toml)
- Code quality is enforced via Aqua.jl tests in the test suite

### Package Management
- `julia --project=. -e "using Pkg; Pkg.instantiate()"` - Install dependencies
- `julia --project=. -e "using Pkg; Pkg.precompile()"` - Precompile package

### Building Documentation
- Documentation is located in `docs/` with its own Project.toml
- `cd docs && julia --project=. make.jl` - Build documentation

## Project Architecture

PromptingTools.jl is a Julia package for streamlined interaction with Large Language Models (LLMs). The architecture is designed around three core concepts:

### Core Components

1. **Prompt Schemas** (`src/llm_*.jl`): Define how prompts are structured and formatted for different APIs
   - `llm_openai.jl` - OpenAI API implementation
   - `llm_anthropic.jl` - Anthropic Claude API implementation  
   - `llm_ollama.jl` - Ollama local models integration
   - `llm_google.jl` - Google Gemini API implementation
   - `llm_shared.jl` - Common utilities across schemas

2. **Messages** (`src/messages.jl`): Core message types for conversations
   - `SystemMessage` - System-level instructions
   - `UserMessage` - User inputs
   - `AIMessage` - AI responses
   - `DataMessage` - Structured data responses

3. **AI Functions** (`src/llm_interface.jl`): User-facing task functions
   - `aigenerate` - General text generation
   - `aiembed` - Text embeddings
   - `aiextract` - Structured data extraction
   - `aiclassify` - Classification tasks
   - `aiscan` - Vision/image processing
   - `aiimage` - Image generation
   - `aitools` - Agentic workflows with tools

### Key Modules

- **Templates** (`src/templates.jl`): Pre-built prompt templates with metadata system
- **Extraction** (`src/extraction.jl`): Structured data extraction from AI responses
- **Code Generation** (`src/code_*.jl`): Julia code parsing, evaluation, and execution
- **Streaming** (`src/streaming.jl`): Real-time response streaming support
- **Memory** (`src/memory.jl`): Conversation history management
- **User Preferences** (`src/user_preferences.jl`): Model registry, environment variables to load API keys and configuration management
- **Experimental** (`src/Experimental/`): Advanced features like AgentTools and APITools

### Model Registry System

The package maintains a global `MODEL_REGISTRY` that maps model aliases to their full names and configurations. This allows users to reference models by simple aliases (e.g., "gpt4" instead of "gpt-4-1106-preview"). Models are registered with the `register_model!` function.

### Multiple Dispatch Architecture

The package heavily uses Julia's multiple dispatch system with `AbstractPromptSchema` as the core abstraction. Each AI service has its own schema type that determines how prompts are rendered and API calls are made.

### Experimental Features

- **AgentTools** (`src/Experimental/AgentTools/`): Lazy evaluation, retry mechanisms with MCTS optimization, and advanced agent workflows
- **APITools** (`src/Experimental/APITools/`): External API integrations (e.g., Tavily search)

## Development Guidelines

- Follow SciML code style (enforced by JuliaFormatter)
- Each new AI service interface should be in a separate `llm_<interface>.jl` file
- All user-facing functions start with `ai*` for discoverability
- Use multiple dispatch on `AbstractPromptSchema` for extensibility
- Add comprehensive tests for new functionality
- Template files are stored in `templates/` directory and loaded at module initialization

## Model Support

The package supports multiple AI providers:
- OpenAI (GPT models, DALL-E, embeddings)
- Anthropic (Claude models) 
- Google (Gemini models)
- Local models via Ollama
- Custom OpenAI-compatible APIs (MistralAI, Perplexity, etc.)

## Testing Strategy

Tests are organized by module with comprehensive coverage including:
- Core functionality tests
- Individual LLM interface tests  
- Template system tests
- Code generation and evaluation tests
- Experimental module tests
- Code quality checks via Aqua.jl

## How-To Guides

### Creating Pull Requests

Before submitting a PR, ensure you complete the following requirements:

1. **Code Quality**: Run the formatter and ensure all tests pass
   - `julia --project=. -e "using JuliaFormatter; format(\".\")"` 
   - `julia --project=. -e "using Pkg; Pkg.test()"`

2. **Test Coverage**: Maintain ~90% test coverage and add tests for new functionality
   - New features must include comprehensive test coverage
   - Verify coverage doesn't decrease from current levels

3. **Documentation**: Add a brief description to CHANGELOG.md
   - Add entries under the "Unreleased" section unless increasing the version
   - Follow the existing changelog format and style

4. **Versioning**: Increase minor version for any additions or updates (beyond bug fixes)
   - Update version in `Project.toml`
   - Move changelog entries from "Unreleased" to new version section

### Adding Support for New Models

To add a new model to the package, follow these steps:

1. **Model Registration**: Edit `src/user_preferences.jl` to add the model
   - Add exact model name as key with `ModelSpec` configuration:
   ```julia
   "model-exact-name" => ModelSpec("model-exact-name", <schema>, <input-cost-per-million>, <output-cost-per-million>, <description>)
   ```

2. **Create Alias**: Add a user-friendly alias in the `aliases` dictionary
   - Follow established naming patterns for consistency
   - Link the alias to the exact model name

3. **Version and Documentation**: 
   - Increase minor version in `Project.toml`
   - Add description in `CHANGELOG.md` under new version header
   - Always mention both the model name and its alias
   - Follow format from previous model additions

4. **Testing**: Test both the exact model name and alias
   - Test the exact model name: `aigenerate("say hi", model="model-exact-name")`
   - Test the alias: `aigenerate("say hi", model="alias")`
   - Verify both work correctly and produce expected responses
   - Add unit tests if the model uses a new schema or has unique behavior
