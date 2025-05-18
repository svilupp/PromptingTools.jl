```@meta
CurrentModule = PromptingTools
```

# Text Utilities

Working with Generative AI (and in particular with the text modality), requires a lot of text manipulation. PromptingTools.jl provides a set of utilities to make this process easier and more efficient.


## Highlights

The main functions to be aware of are
- `recursive_splitter` to split the text into sentences and words (of a desired length `max_length`)
- `replace_words` to mask some sensitive words in your text before sending it to AI
- `wrap_string` for wrapping the text into a desired length by adding newlines (eg, to fit some large text into your terminal width)
- `length_longest_common_subsequence` to find the length of the longest common subsequence between two strings (eg, to compare the similarity between the context provided and generated text)
- `distance_longest_common_subsequence` a companion utility for `length_longest_common_subsequence` to find the normalized distance between two strings. Always returns a number between 0-1, where 0 means the strings are identical and 1 means they are completely different.

You can import them simply via:
```julia
using PromptingTools: recursive_splitter, replace_words, wrap_string, length_longest_common_subsequence, distance_longest_common_subsequence
```

There are many more (especially in the AgentTools module).

Text utilities that used to live in `Experimental.RAGTools` have moved to
the [RAGTools.jl](https://github.com/JuliaGenAI/RAGTools.jl) package.
- `STOPWORDS` a set of common stopwords (very brief)

Feel free to open an issue or ask in the `#generative-ai` channel in the JuliaLang Slack if you have a specific need.

## References

```@docs; canonical=false
recursive_splitter
replace_words
wrap_string
length_longest_common_subsequence
distance_longest_common_subsequence
```
