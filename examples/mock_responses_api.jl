using HTTP
using JSON3
using OpenAI
using PromptingTools
const PT = PromptingTools
using PromptingTools: OpenAIResponseSchema, AbstractResponseSchema, airespond
using StreamCallbacks: StreamCallback

# This example demonstrates the use of the OpenAI Responses API
# with proper schema support and streaming capabilities

# Make sure your OpenAI API key is set in the environment variable OPENAI_API_KEY

# Basic usage with the new schema
schema = OpenAIResponseSchema()
cb = StreamCallback(out = stdout)

response = airespond(schema,
    "What is the 6th largest city in the Czech Republic? you can think, but in the answer I only want to see the city.";
    model = "gpt-5.1-codex", streamcallback = cb)
@show response.tokens
@show response.extras[:usage]
;

#%%
cb = StreamCallback(out = stdout)
aigenerate(
    "What is the 6th largest city in the Czech Republic? you can think, but in the answer I only want to see the city.";
    model = "gpt-5.1-codex",
    streamcallback = cb)
#%%
# Ask normal question
response = airespond(schema, "What is the 3rd largest city in the Czech Republic?";
    model = "gpt-5.1-codex", streamcallback = cb)

## With streaming
response = airespond(schema, "Count from 1 to 10";
    model = "gpt-5.1-codex",
    streamcallback = stdout)

## Trigger web search
response = airespond(schema, "What is the 3rd largest city in the Czech Republic?";
    enable_websearch = true,
    model = "gpt-5.1-codex")

## Access extra fields
response.extras[:reasoning]
response.extras[:response_id]
response.extras[:full_response][:output]

## Do a follow up question
new_response = airespond(schema, "What's the population?";
    enable_websearch = true,
    model = "gpt-5.1-codex",
    previous_response_id = response.extras[:response_id])

## Use a template
response = airespond(schema, :AssistantAsk;
    ask = "What is the 3rd largest city in the Czech Republic?",
    model = "gpt-5.1-codex",
    enable_websearch = true)
#%%

# Run this example to test the OpenAI Responses API implementation
# Make sure your OpenAI API key is set in the environment variable OPENAI_API_KEY
# response = airespond(
#     OpenAISchema(), "What is the 3rd largest city in the Czech Republic?", model = "gpt-5.1-codex")

body = create_response(
    OpenAISchema(),
    PromptingTools.OPENAI_API_KEY,
    "gpt-5.1-codex",
    "Please think carefully, how would we reimplement zustand v5 useShallow, you can think, but in the answer I only want to see the useShallow function."
)

## Ask normal question
response = airespond(
    "What is the 3rd largest city in the Czech Republic?", model = "gpt-4.1-mini")

# ## Trigger web search
# response = airespond(
#     "What is the 3rd largest city in the Czech Republic?", enable_websearch = true, model = "gpt-4.1-mini")
## You can access the extra fields like reasoning, response_id, or full_response
response.extras[:reasoning]
response.extras[:response_id]
response.extras[:full_response][:output]
## See the tools used
response.extras[:full_response][:tools]

## Do a follow up question
new_response = airespond(
    "What's the population?", enable_websearch = true,
    model = "gpt-4.1-mini",
    previous_response_id = response.extras[:response_id])

## See the annotations (sources)
JSON3.pretty(new_response.extras[:full_response][:output])

## Use a template
response = airespond(
    :AssistantAsk;
    ask = "What is the 3rd largest city in the Czech Republic?",
    model = "gpt-4.1-mini",
    enable_websearch = true,
    previous_response_id = response.extras[:response_id])
