using PromptingTools: AbstractChatMessage, SystemMessage, UserMessage, MetadataMessage
using PromptingTools: render
using PromptingTools: save_template, load_template, load_templates!, aitemplates
using PromptingTools: TestEchoOpenAISchema

@testset "Templates - save/load" begin
    description = "Some description"
    version = "1.1"
    msgs = [
        SystemMessage("You are an impartial AI judge evaluting whether the provided statement is \"true\" or \"false\". Answer \"unknown\" if you cannot decide."),
        UserMessage("# Statement\n\n{{it}}"),
    ]
    tmp, _ = mktemp()
    save_template(tmp,
        msgs;
        description, version)
    template, metadata = load_template(tmp)
    @test template == msgs
    @test metadata[1].description == description
    @test metadata[1].version == version
    @test metadata[1].content == "Template Metadata"
    @test metadata[1].source == ""
end

@testset "Template rendering" begin
    template = AITemplate(:JudgeIsItTrue)
    expected_output = AbstractChatMessage[SystemMessage("You are an impartial AI judge evaluting whether the provided statement is \"true\" or \"false\". Answer \"unknown\" if you cannot decide."),
        UserMessage("# Statement\n\n{{it}}")]
    @test expected_output == render(PT.PROMPT_SCHEMA, template)
    @test expected_output == render(template)
end

@testset "Templates - search" begin
    # search all
    tmps = aitemplates("")
    @test tmps == PT.TEMPLATE_METADATA
    # Exact search for JudgeIsItTrue
    tmps = aitemplates(:JudgeIsItTrue)
    @test length(tmps) == 1
    @test tmps[1].name == :JudgeIsItTrue
    # Search for multiple with :Task in name
    tmps1 = aitemplates(:Task)
    @test length(tmps1) >= 1
    tmps2 = aitemplates("Task") # broader search
    @test length(tmps2) >= length(tmps1)
    # Search via regex
    tmps = aitemplates(r"IMPARTIAL AI JUDGE"i)
    @test length(tmps) >= 1
end

@testset "Templates - Echo aigenerate call" begin
    # E2E test for aigenerate with rendering template and filling the placeholders
    template_name = :JudgeIsItTrue
    expected_template_rendered = render(AITemplate(template_name)) |>
                                 x -> render(PT.PROMPT_SCHEMA, x; it = "Is this correct?")
    # corresponds to OpenAI API v1
    response = Dict(:choices => [Dict(:message => Dict(:content => "Hello!"))],
        :usage => Dict(:total_tokens => 3, :prompt_tokens => 2, :completion_tokens => 1))

    # AIGeneration API - use AITemplate(:)
    schema1 = TestEchoOpenAISchema(; response, status = 200)
    msg = aigenerate(schema1, AITemplate(template_name); it = "Is this correct?")
    @test schema1.inputs == expected_template_rendered

    # AIGeneration API - use template name as symbol
    schema2 = TestEchoOpenAISchema(; response, status = 200)
    msg = aigenerate(schema2, template_name; it = "Is this correct?")
    @test schema2.inputs == expected_template_rendered

    # AIClassify API - use symbol dispatch
    schema3 = TestEchoOpenAISchema(; response, status = 200)
    msg = aiclassify(schema3, template_name; it = "Is this correct?")
    @test schema3.inputs == expected_template_rendered
end