```@meta
CurrentModule = PromptingTools.Experimental.APITools
```

# APITools Introduction

`APITools` is an experimental module wrapping helpful APIs for working with and enhancing GenerativeAI models.

Import the module as follows:

```julia
using PromptingTools.Experimental.APITools
```

## Highlights

Currently, there is only one function in this module `create_websearch` that leverages [Tavily.com](https://tavily.com/) search and answer engine to provide additional context.

You need to sign up for an API key at [Tavily.com](https://tavily.com/) and set it as an environment variable `TAVILY_API_KEY` to use this function.

## References

```@docs; canonical=false
create_websearch
```
