using PromptingTools: AbstractChatMessage, SystemMessage, UserMessage, MetadataMessage
using PromptingTools: render
using PromptingTools: load_templates!, aitemplates, create_template, AITemplateMetadata,
                      save_conversation
using PromptingTools: TestEchoOpenAISchema

@testset "Template rendering" begin
    template = AITemplate(:JudgeIsItTrue)
    expected_output = AbstractChatMessage[
    SystemMessage("You are an impartial AI judge evaluating whether the provided statement is \"true\" or \"false\". Answer \"unknown\" if you cannot decide."),
    UserMessage("# Statement\n\n{{it}}")]
    @test expected_output == render(PT.PROMPT_SCHEMA, template)
    @test expected_output == render(template)
    @test expected_output == render(nothing, template)
end

@testset "Templates - search" begin
    # search all
    tmps = aitemplates(""; limit = typemax(Int))
    @test tmps == PT.TEMPLATE_METADATA
    @info length(tmps)
    @info length(PT.TEMPLATE_METADATA)
    # Exact search for JudgeIsItTrue
    tmps = aitemplates(:JudgeIsItTrue)
    @test length(tmps) == 1
    @test tmps[1].name == :JudgeIsItTrue
    # Search for an exact match :Task in name
    tmps1 = aitemplates(:Task)
    @test length(tmps1) == 0 # does not exist
    tmps2 = aitemplates("Task") # broader search
    @test length(tmps2) >= length(tmps1)
    # Search via regex
    tmps = aitemplates(r"IMPARTIAL AI JUDGE"i)
    @test length(tmps) >= 1
end

@testset "load_templates!" begin
    load_templates!()
    PT.TEMPLATE_PATH = PT.TEMPLATE_PATH[[1]] # reset
    dir_name = joinpath(tempdir(), "templates")
    mkpath(dir_name)
    load_templates!(dir_name)
    @test length(PT.TEMPLATE_PATH) == 2
    @test PT.TEMPLATE_PATH[2] == dir_name
    # no more changes
    load_templates!(dir_name)
    load_templates!(dir_name)
    @test length(PT.TEMPLATE_PATH) == 2
    @test PT.TEMPLATE_PATH[2] == dir_name
    # reset to normal
    PT.TEMPLATE_PATH = PT.TEMPLATE_PATH[[1]] # reset
end

@testset "create_template" begin
    tpl = create_template("You must speak like a pirate", "Say hi to {{name}}")
    @test tpl[1].content == "You must speak like a pirate"
    @test tpl[1] isa SystemMessage
    @test tpl[2].content == "Say hi to {{name}}"
    @test tpl[2].variables == [:name]
    @test tpl[2] isa UserMessage

    # kwarg constructor
    tpl = create_template(; user = "Say hi to {{chef}}")
    @test tpl[1].content == "Act as a helpful AI assistant."
    @test tpl[1] isa SystemMessage
    @test tpl[2].content == "Say hi to {{chef}}"
    @test tpl[2].variables == [:chef]
    @test tpl[2] isa UserMessage

    # use save_as
    tpl = create_template(
        "You must speak like a pirate", "Say hi to {{name}}"; load_as = :PirateGreetingX)
    @test haskey(PT.TEMPLATE_STORE, :PirateGreetingX)
    @test length(filter(x -> x.name == :PirateGreetingX, PT.TEMPLATE_METADATA)) == 1
    ## clean up
    delete!(PT.TEMPLATE_STORE, :PirateGreetingX)
    filter!(x -> x.name != :PirateGreetingX, PT.TEMPLATE_METADATA)
end

@testset "load_templates!-filtering" begin
    tpl = create_template(; system = "a", user = "b")
    mktempdir() do dir
        ## File to be visible
        fn = joinpath(dir, "x1.json")
        save_conversation(fn, tpl)

        ## File to be invisible
        fn = joinpath(dir, "._x2.json")
        save_conversation(fn, tpl)

        store = Dict{Symbol, Any}()
        PT.load_templates!(dir;
            remember_path = false, store,
            metadata_store = Vector{AITemplateMetadata}())
        @test length(store) == 1
        @test haskey(store, :x1)
    end
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
