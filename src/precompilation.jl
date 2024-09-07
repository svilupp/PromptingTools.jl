# Load templates
load_template(joinpath(@__DIR__, "..", "templates", "general", "BlankSystemUser.json"))
load_templates!();

# Preferences
@load_preference("MODEL_CHAT", default="x")

# API Calls prep
mock_response = Dict(
    :choices => [
        Dict(
        :message => Dict(:content => "Hello!",
            :tool_calls => [
                Dict(:function => Dict(:arguments => JSON3.write(Dict(:x => 1))))
            ]),
        :finish_reason => "stop")
    ],
    :usage => Dict(:total_tokens => 3, :prompt_tokens => 2, :completion_tokens => 1))
schema = TestEchoOpenAISchema(; response = mock_response, status = 200)

# API calls
msg = aigenerate(schema, "I want to ask {{it}}"; it = "Is this correct?")
msg = aiclassify(schema, "I want to ask {{it}}"; it = "Is this correct?")
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
msg = aiclassify(schema, template_name; it = "Is this correct?");
msg = aiextract(schema,
    template_name;
    it = "This doesn't make sense but do run it...",
    return_type = X123);
msg = aiscan(schema,
    template_name;
    it = "Is the image a Julia logo?",
    image_url = "some_link_to_julia_logo");

## Streaming
# OpenAIStream functionality
openai_flavor = OpenAIStream()
chunk = StreamChunk(
    json = JSON3.read("""
    {
        "choices": [
            {
                "delta": {
                    "content": "Hello, world!"
                }
            }
        ]
    }
    """)
)
content = extract_content(openai_flavor, chunk)
chunk = StreamChunk(; data = "[DONE]")
is_done(openai_flavor, chunk)

# AnthropicStream functionality
anthropic_flavor = AnthropicStream()
chunk = StreamChunk(
    json = JSON3.read("""
    {
        "content_block": {
            "text": "Hello from Anthropic!"
        }
    }
    """)
)
content = extract_content(anthropic_flavor, chunk)
is_done(anthropic_flavor, StreamChunk(event = :message_stop))

# extract_chunks functionality
blob = "event: start\ndata: {\"key\": \"value\"}\n\n"
chunks, spillover = extract_chunks(OpenAIStream(), blob)

# build_response_body functionality
cb = StreamCallback(flavor = OpenAIStream())
push!(cb.chunks,
    StreamChunk(
        nothing,
        """{"id":"chatcmpl-123","object":"chat.completion.chunk","created":1234567890,"model":"gpt-4","choices":[{"index":0,"delta":{"role":"assistant","content":"Hello"},"finish_reason":null}]}""",
        JSON3.read("""{"id":"chatcmpl-123","object":"chat.completion.chunk","created":1234567890,"model":"gpt-4","choices":[{"index":0,"delta":{"role":"assistant","content":"Hello"},"finish_reason":null}]}""")
    ))
response = build_response_body(OpenAIStream(), cb)

# AnthropicStream build_response_body functionality
anthropic_cb = StreamCallback(flavor = AnthropicStream())
push!(anthropic_cb.chunks,
    StreamChunk(
        :message_start,
        """{"message":{"content":[],"model":"claude-2","stop_reason":null,"stop_sequence":null}}""",
        JSON3.read("""{"message":{"content":[],"model":"claude-2","stop_reason":null,"stop_sequence":null}}""")
    ))
push!(anthropic_cb.chunks,
    StreamChunk(
        :content_block_start,
        """{"content_block":{"type":"text","text":"Hello from Anthropic!"}}""",
        JSON3.read("""{"content_block":{"type":"text","text":"Hello from Anthropic!"}}""")
    ))
push!(anthropic_cb.chunks,
    StreamChunk(
        :message_delta,
        """{"delta":{"stop_reason":"end_turn","stop_sequence":null}}""",
        JSON3.read("""{"delta":{"stop_reason":"end_turn","stop_sequence":null}}""")
    ))
anthropic_response = build_response_body(AnthropicStream(), anthropic_cb)
