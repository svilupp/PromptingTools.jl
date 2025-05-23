# Migrating from PromptingTools.Experimental.RAGTools to RAGTools.jl

## Overview

RAG (Retrieval-Augmented Generation) functionality has been moved from `PromptingTools.Experimental.RAGTools` to a dedicated package [RAGTools.jl](https://github.com/JuliaGenAI/RAGTools.jl). This migration provides better maintainability, faster development cycles, and a more focused feature set for RAG workflows.

## Why the Migration?

- **Focused Development**: RAGTools.jl can evolve independently with RAG-specific features
- **Reduced Dependencies**: PromptingTools.jl becomes lighter and you won't have to import 4 packages to trigger the package extensions!
- **Better Testing**: Dedicated testing and CI/CD for RAG functionality
- **Community**: Centralized location for RAG-related contributions and discussions

## Migration Guide

### Step 1: Install RAGTools.jl

```julia
using Pkg
Pkg.add("RAGTools")
```

### Step 2: Update Your Imports

The migration is straightforward - you only need to change your import statements:

```julia
# Old way (deprecated):
using PromptingTools.Experimental.RAGTools
const RT = PromptingTools.Experimental.RAGTools

# New way:
using RAGTools
const RT = RAGTools
```

### Step 3: Verify Everything Works

All function names, APIs, and workflows remain exactly the same. Your existing code should work without any other changes.

## Complete Example

Here's a simple example showing the migration:

### Before (Old Code)
```julia
using LinearAlgebra, SparseArrays, Unicode
using PromptingTools
using PromptingTools.Experimental.RAGTools
const PT = PromptingTools
const RT = PromptingTools.Experimental.RAGTools

# Sample documents
documents = ["Julia is a high-level programming language.", "The sky is blue on a clear day."]

# Build index and ask question
index = build_index(documents)
answer = airag(index; question = "What is Julia?")
```

### After (Migrated Code)
```julia
using PromptingTools
using RAGTools  # Only this line changed!
const PT = PromptingTools
const RT = RAGTools  # And this line changed!

# Sample documents
documents = ["Julia is a high-level programming language.", "The sky is blue on a clear day."]

# Build index and ask question - everything else is identical
index = build_index(documents)
answer = airag(index; question = "What is Julia?")
```

## Full RAG Workflow Example

Here's a complete example using the new RAGTools.jl package:

```julia
using RAGTools
using PromptingTools

# Create sample documents
documents = [
    "Julia is a high-level programming language designed for high-performance numerical analysis and computational science.",
    "RAGTools.jl provides tools for building Retrieval-Augmented Generation workflows in Julia.",
    "The build_index function creates embeddings and prepares documents for semantic search."
]

# Build the RAG index
index = build_index(documents; chunker_kwargs = (; sources = ["doc1", "doc2", "doc3"]))

# Ask a question
question = "What is Julia used for?"
result = airag(index; question, return_all = true)

# Display results
println("Question: ", result.question)
println("Answer: ", result.final_answer)
println("Retrieved chunks: ", length(result.context))
```

## API Compatibility

✅ **Complete API compatibility** - All functions work exactly the same:

- `build_index()` 
- `airag()`
- `build_qa_evals()`
- `run_qa_evals()`
- All RAG configuration options
- All chunking strategies
- All retrieval methods
- All evaluation metrics

## Troubleshooting

### Getting a Deprecation Warning?

If you see a warning like:
```
┌ Warning: RAGTools functionality has moved to a dedicated package!
```

Simply update your imports as shown above.

### Import Errors?

Make sure you've installed RAGTools.jl:
```julia
using Pkg
Pkg.add("RAGTools")
```

### Need Help?

- 📖 [RAGTools.jl Documentation](https://github.com/JuliaGenAI/RAGTools.jl)
- 💬 [Julia Slack #generative-ai channel](https://julialang.slack.com/archives/C06G90C697X)
- 🐛 [Report Issues](https://github.com/JuliaGenAI/RAGTools.jl/issues)

## Timeline

- **Now**: The experimental module has been completely removed from PromptingTools. All RAG functionality is now exclusively available in RAGTools.jl

Migrate at your convenience, but sooner is better to avoid any future breaking changes!