using PromptingTools: ModelSpec,
                      register_model!, MODEL_REGISTRY, MODEL_ALIASES, ModelRegistry
using PromptingTools: list_registry, list_aliases
using PromptingTools: OpenAISchema, OllamaManagedSchema, set_preferences!, get_preferences

@testset "set_preferences!" begin
    # Remember old preferences
    OLD_MODEL_CHAT = get_preferences("MODEL_CHAT")
    OLD_MODEL_EMBEDDING = get_preferences("MODEL_EMBEDDING")
    OLD_OPENAI_API_KEY = get_preferences("OPENAI_API_KEY")

    # Test Setting Allowed Preferences
    @testset "Allowed Preferences" for pref in [
        "OPENAI_API_KEY",
        "MODEL_CHAT",
        "MODEL_EMBEDDING"
    ]
        set_preferences!(pref => "test_value")
        @test get_preferences(pref) == "test_value"  # Assuming a get_preferences function exists
        @test getproperty(PromptingTools, Symbol(pref)) == "test_value"  # Check if the module-level variable is updated
    end

    # Test Attempting to Set a Disallowed Preference
    @test_throws AssertionError set_preferences!("UNKNOWN_PREF" => "value")
    @test_throws AssertionError get_preferences("UNKNOWN_PREF")

    # Test Setting Multiple Preferences at Once
    set_preferences!("OPENAI_API_KEY" => "key1", "MODEL_CHAT" => "chat1")
    @test get_preferences("OPENAI_API_KEY") == "key1"
    @test get_preferences("MODEL_CHAT") == "chat1"

    # Return back to previous state
    set_preferences!("OPENAI_API_KEY" => OLD_OPENAI_API_KEY,
        "MODEL_CHAT" => OLD_MODEL_CHAT,
        "MODEL_EMBEDDING" => OLD_MODEL_EMBEDDING)
end

@testset "ModelSpec" begin
    # Test for Correct Initialization
    spec = ModelSpec("gpt-3.5-turbo", OpenAISchema(), 0.0015, 0.002, "Description")
    @test spec.name == "gpt-3.5-turbo"
    @test spec.schema == OpenAISchema()
    @test spec.cost_of_token_prompt ≈ 0.0015
    @test spec.cost_of_token_generation ≈ 0.002
    @test spec.description == "Description"

    # Test for Default Values
    spec = ModelSpec(; name = "gpt-3")
    @test spec.schema === nothing
    @test spec.cost_of_token_prompt ≈ 0.0
    @test spec.cost_of_token_generation ≈ 0.0
    @test spec.description == ""

    # Test for Type Assertions
    @test_throws MethodError ModelSpec(123, OpenAISchema(), 0.0015, 0.002, "Description")
    @test_throws MethodError ModelSpec("gpt-3", :OpenAISchema, 0.0015, 0.002, "Description")
    @test_throws MethodError ModelSpec("gpt-3",
        "InvalidSymbol",
        0.0015,
        0.002,
        "Description")
    # Test for Correct Output Format
    spec = ModelSpec("gpt-3.5-turbo", OpenAISchema(), 0.0015, 0.002, "Description")
    buffer = IOBuffer()
    show(buffer, spec)
    output = String(take!(buffer))
    expected_output = "ModelSpec\n  name: String \"gpt-3.5-turbo\"\n  schema: OpenAISchema OpenAISchema()\n  cost_of_token_prompt: Float64 0.0015\n  cost_of_token_generation: Float64 0.002\n  description: String \"Description\"\n"
    @test output == expected_output
end

@testset "ModelRegistry" begin
    # Assuming MODEL_REGISTRY is a Dict accessible for testing
    # Test for Normal Registration
    register_model!(; name = "gpt-5",
        schema = OllamaManagedSchema(),
        cost_of_token_prompt = 0.1,
        cost_of_token_generation = 0.1,
        description = "Test model")
    @test MODEL_REGISTRY["gpt-5"].schema == OllamaManagedSchema()
    @test MODEL_REGISTRY["gpt-5"].description == "Test model"

    # Manual registry
    new_spec = ModelSpec("gpt-new", OpenAISchema(), 0.001, 0.002, "New model description")
    MODEL_REGISTRY["gpt-new"] = new_spec
    @test MODEL_REGISTRY["gpt-new"].name == "gpt-new"

    # Test for Default Argument Usage
    register_model!(name = "gpt-5-mini")
    @test MODEL_REGISTRY["gpt-5-mini"].schema === nothing
    @test MODEL_REGISTRY["gpt-5-mini"].description == ""

    # Test for Model Overwriting Warning
    @test_logs (:warn, "Model `gpt-5` already registered! It will be overwritten.") register_model!(name = "gpt-5")

    # Test for Registry Update
    original_count = length(MODEL_REGISTRY.registry)
    delete!(MODEL_REGISTRY, "new-model")
    register_model!(name = "new-model")
    @test length(MODEL_REGISTRY.registry) == original_count + 1

    # Test for Correct Alias Access
    @test MODEL_ALIASES["gpt3"] == "gpt-3.5-turbo"

    # Test for Adding New Alias
    MODEL_ALIASES["new-alias"] = "gpt-3.5-turbo"
    @test MODEL_ALIASES["new-alias"] == "gpt-3.5-turbo"
    @test MODEL_REGISTRY["new-alias"].name == "gpt-3.5-turbo"

    # Test for Correct Model Access by Full Name
    @test MODEL_REGISTRY["gpt-3.5-turbo"].name == "gpt-3.5-turbo"

    # Test for Non-Existent Alias
    @test_throws KeyError MODEL_ALIASES["nonexistent"]
    @test_throws KeyError MODEL_REGISTRY["nonexistent"]
    @test get(MODEL_REGISTRY, "nonexistent", "xyz") == "xyz"

    # Show method
    buffer = IOBuffer()
    show(buffer, MODEL_REGISTRY)
    output = String(take!(buffer))

    expected_output = "ModelRegistry with $(length(MODEL_REGISTRY.registry)) models and $(length(MODEL_REGISTRY.aliases)) aliases. See `?MODEL_REGISTRY` for more information."
    @test output == expected_output

    # list functions
    @test list_registry() == sort(collect(keys(MODEL_REGISTRY.registry)))
    @test list_aliases() == MODEL_REGISTRY.aliases

    struct A <: PT.AbstractPromptSchema end
    struct B <: PT.AbstractPromptSchema end

    m = PT.ModelRegistry(
        Dict("aa" => ModelSpec(name = "aa", schema = A()),
            "aa2" => ModelSpec(name = "aa2", schema = A()),
            "bb" => ModelSpec(name = "bb", schema = B())),
        Dict("a" => "aa", "b" => "bb", "b2" => "bb")
    )

    @test keys(m) == Set(["aa2", "bb", "b", "b2", "aa", "a"])
    @test PT.model_docs(m) ==
          """
          ## A
          - `aa2`
          - `aa` - aliases: `a`

          ## B
          - `bb` - aliases: `b` and `b2`
          """ # sorted, multiple aliases, multiple schemas, multiple models for single schema
end
