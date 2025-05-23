"""
    ai"user_prompt"[model_alias] -> AIMessage

The `ai""` string macro generates an AI response to a given prompt by using `aigenerate` under the hood.

See also `ai!""` if you want to reply to the provided message / continue the conversation.

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
result = ai"What is `1.23 * 100 + 1`?"gpt4t
# AIMessage("The answer is 124.")
```
"""
macro ai_str(user_prompt, flags...)
    global CONV_HISTORY, MAX_HISTORY_LENGTH
    model = isempty(flags) ? :MODEL_CHAT : esc(only(flags))
    prompt = Meta.parse("\"$(escape_string(user_prompt))\"")
    quote
        conv = aigenerate($(esc(prompt)); model = $model, return_all = true)
        push_conversation!($(esc(CONV_HISTORY)), conv, $(esc(MAX_HISTORY_LENGTH)))
        last(conv)
    end
end

"""
    ai!"user_prompt"[model_alias] -> AIMessage

The `ai!""` string macro is used to continue a previous conversation with the AI model. 

It appends the new user prompt to the last conversation in the tracked history (in `PromptingTools.CONV_HISTORY`) and generates a response based on the entire conversation context.
If you want to see the previous conversation, you can access it via `PromptingTools.CONV_HISTORY`, which keeps at most last `PromptingTools.MAX_HISTORY_LENGTH` conversations.

## Arguments
- `user_prompt` (String): The new input prompt to be added to the existing conversation.
- `model_alias` (optional, any): Specify the model alias of the AI model to be used (see `MODEL_ALIASES`). If not provided, the default model is used.

## Returns
`AIMessage` corresponding to the new user prompt, considering the entire conversation history.

## Example
To continue a conversation:
```julia
# start conversation as normal
ai"Say hi." 

# ... wait for reply and then react to it:

# continue the conversation (notice that you can change the model, eg, to more powerful one for better answer)
ai!"What do you think about that?"gpt4t
# AIMessage("Considering our previous discussion, I think that...")
```

## Usage Notes
- This macro should be used when you want to maintain the context of an ongoing conversation (ie, the last `ai""` message).
- It automatically accesses and updates the global conversation history.
- If no conversation history is found, it raises an assertion error, suggesting to initiate a new conversation using `ai""` instead.

## Important
Ensure that the conversation history is not too long to maintain relevancy and coherence in the AI's responses. The history length is managed by `MAX_HISTORY_LENGTH`.
"""
macro ai!_str(user_prompt, flags...)
    global CONV_HISTORY
    model = isempty(flags) ? :MODEL_CHAT : esc(only(flags))
    prompt = Meta.parse("\"$(escape_string(user_prompt))\"")
    quote
        @assert !isempty($(esc(CONV_HISTORY))) "No conversation history found. Please use `ai\"\"` instead."
        # grab the last conversation
        old_conv = $(esc(CONV_HISTORY))[end]
        conv = aigenerate(vcat(old_conv, [UserMessage($(esc(prompt)))]);
            model = $model,
            return_all = true)
        # replace the last conversation with the new one
        $(esc(CONV_HISTORY))[end] = conv
        # 
        last(conv)
    end
end

"""
    aai"user_prompt"[model_alias] -> AIMessage

Asynchronous version of `@ai_str` macro, which will log the result once it's ready.

See also `aai!""` if you want an asynchronous reply to the provided message / continue the conversation.    

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
    global CONV_HISTORY, MAX_HISTORY_LENGTH, CONV_HISTORY_LOCK
    model = isempty(flags) ? :MODEL_CHAT : esc(only(flags))
    prompt = Meta.parse("\"$(escape_string(user_prompt))\"")
    quote
        Threads.@spawn begin
            conv = aigenerate($(esc(prompt)); model = $model, return_all = true)
            lock($(esc(CONV_HISTORY_LOCK))) do
                push_conversation!($(esc(CONV_HISTORY)), conv, $(esc(MAX_HISTORY_LENGTH)))
            end
            @info "AIMessage> $(last(conv).content)" # display the result once it's ready
            last(conv)
        end
    end
end

macro aai!_str(user_prompt, flags...)
    global CONV_HISTORY, CONV_HISTORY_LOCK
    model = isempty(flags) ? :MODEL_CHAT : esc(only(flags))
    prompt = Meta.parse("\"$(escape_string(user_prompt))\"")
    quote
        @assert !isempty($(esc(CONV_HISTORY))) "No conversation history found. Please use `aai\"\"` instead."
        Threads.@spawn begin
            # grab the last conversation
            old_conv = $(esc(CONV_HISTORY))[end]

            # send to AI
            conv = aigenerate(vcat(old_conv, [UserMessage($(esc(prompt)))]);
                model = $model,
                return_all = true)

            # replace the last conversation with the new one
            lock($(esc(CONV_HISTORY_LOCK))) do
                $(esc(CONV_HISTORY))[end] = conv
            end
            @info "AIMessage> $(last(conv).content)" # display the result once it's ready
            last(conv)
        end
    end
end
