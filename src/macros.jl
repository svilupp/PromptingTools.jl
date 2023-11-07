"""
    ai"user_prompt"[model_alias] -> AIMessage

The `ai""` string macro generates an AI response to a given prompt by using `aigenerate` under the hood.

## Arguments
- `user_prompt` (String): The input prompt for the AI model.
- `model_alias` (optional, any): Provide model alias of the AI model (see `MODEL_ALIASES`).

## Returns
`AIMessage` corresponding to the input prompt.

## Example
```julia
result = ai"Hello, how are you?"
# AIMessage("Hello! I'm an AI assistant, so I don't have feelings, but I'm here to help you. How can I assist you today?")
```

If you want to interpolate some variables or additional context, simply use string interpolation:
```julia
a=1
result = ai"What is `\$a+\$a`?"
# AIMessage("The sum of `1+1` is `2`.")
```

If you want to use a different model, eg, GPT-4, you can provide its alias as a flag:
```julia
result = ai"What is `1.23 * 100 + 1`?"gpt4
# AIMessage("The answer is 124.")
```
"""
macro ai_str(user_prompt, flags...)
    model = isempty(flags) ? MODEL_CHAT : only(flags)
    prompt = Meta.parse("\"$(escape_string(user_prompt))\"")
    quote
        aigenerate($(esc(prompt)); model = $(esc(model)))
    end
end

"""
    aai"user_prompt"[model_alias] -> AIMessage

Asynchronous version of `@ai_str` macro, which will log the result once it's ready.

# Example

Send asynchronous request to GPT-4, so we don't have to wait for the response:
Very practical with slow models, so you can keep working in the meantime.

```julia
m = aai"Say Hi!"gpt4; 
# ...with some delay...
# [ Info: Tokens: 29 @ Cost: \$0.0011 in 2.7 seconds
# [ Info: AIMessage> Hello! How can I assist you today?
"""
macro aai_str(user_prompt, flags...)
    model = isempty(flags) ? MODEL_CHAT : only(flags)
    prompt = Meta.parse("\"$(escape_string(user_prompt))\"")
    quote
        Threads.@spawn begin
            m = aigenerate($(esc(prompt)); model = $(esc(model)))
            @info "AIMessage> $(m.content)" # display the result once it's ready
            m
        end
    end
end
