using PromptingTools: OPENAI_TOKEN_IDS_GPT4O
# Basic Message Types precompilation - moved to top
sys_msg = SystemMessage("You are a helpful assistant")
user_msg = UserMessage("Hello!")
ai_msg = AIMessage(content = "Test response")

# Annotation Message precompilation - after basic types
annotation_msg = AnnotationMessage("Test metadata";
    extras = Dict{Symbol, Any}(:key => "value"),
    tags = Symbol[:test],
    comment = "Test comment")
_ = isabstractannotationmessage(annotation_msg)

# ConversationMemory precompilation
memory = ConversationMemory()
push!(memory, sys_msg)
push!(memory, user_msg)
_ = get_last(memory, 2)
_ = length(memory)
_ = last_message(memory)

# Test message rendering with all types - moved before API calls
messages = [
    sys_msg,
    annotation_msg,
    user_msg,
    ai_msg
]
_ = render(OpenAISchema(), messages)

## Utilities
pprint(devnull, messages)
last_output(messages)
last_message(messages)

# Load templates
load_template(joinpath(@__DIR__, "..", "templates", "general", "BlankSystemUser.json"))
load_templates!()

# Preferences
@load_preference("MODEL_CHAT", default="x")

# API Calls prep
mock_response = Dict(
    :choices => [
        Dict(
        :message => Dict(:content => "Hello!",
            :tool_calls => [
                Dict(:function => Dict(
                :name => "X123", :arguments => JSON3.write(Dict(:x => 1))))
            ]),
        :finish_reason => "stop")
    ],
    :usage => Dict(:total_tokens => 3, :prompt_tokens => 2, :completion_tokens => 1))
schema = TestEchoOpenAISchema(; response = mock_response, status = 200)

# API calls
msg = aigenerate(schema, "I want to ask {{it}}"; it = "Is this correct?")
msg = aiclassify(schema, "I want to ask {{it}}"; it = "Is this correct?",
    token_ids_map = OPENAI_TOKEN_IDS_GPT4O)
"With docstring"
struct X123
    x::Int
end
msg = aiextract(schema, "I want to ask {{it}}"; it = "Is this correct?", return_type = X123)
image_url = "some_mock_url"
msg = aiscan(schema, "Describe the image"; image_url)

# macro calls
ai"Hello"echo
ai!"Hello again"echo
empty!(CONV_HISTORY)

# Use of Templates
template_name = :JudgeIsItTrue
msg = aigenerate(schema, template_name; it = "Is this correct?")
msg = aiclassify(
    schema, template_name; it = "Is this correct?", token_ids_map = OPENAI_TOKEN_IDS_GPT4O);
msg = aiextract(schema,
    template_name;
    it = "This doesn't make sense but do run it...",
    return_type = X123);
msg = aiscan(schema,
    template_name;
    it = "Is the image a Julia logo?",
    image_url = "some_link_to_julia_logo");

## Streaming configuration
cb = StreamCallback()
configure_callback!(cb, OpenAISchema())
