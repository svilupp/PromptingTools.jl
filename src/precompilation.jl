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
                Dict(:function => Dict(
                :name => "X123", :arguments => JSON3.write(Dict(:x => 1))))
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

## Streaming configuration
cb = StreamCallback()
configure_callback!(cb, OpenAISchema())