# Load templates
load_templates!();

# API Calls
mock_response = Dict(:choices => [Dict(:message => Dict(:content => "Hello!"))],
    :usage => Dict(:total_tokens => 3, :prompt_tokens => 2, :completion_tokens => 1))
schema = TestEchoOpenAISchema(; response = mock_response, status = 200)
# API calls
msg = aigenerate(schema, "I want to ask {{it}}"; it = "Is this correct?")
msg = aiclassify(schema, "I want to ask {{it}}"; it = "Is this correct?")

# Use of Templates
template_name = :JudgeIsItTrue
msg = aigenerate(schema, template_name; it = "Is this correct?")
msg = aiclassify(schema, template_name; it = "Is this correct?");