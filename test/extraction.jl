using PromptingTools: MaybeExtract, extract_docstring, ItemsExtract
using PromptingTools: has_null_type, is_required_field, remove_null_types, to_json_schema
using PromptingTools: function_call_signature, set_properties_strict!

# TODO: check more edge cases like empty structs

@testset "has_null_type" begin
    @test has_null_type(Number) == false
    @test has_null_type(Nothing) == true
    @test has_null_type(Union{Number, Nothing}) == true
    @test has_null_type(Union{Number, Missing}) == true
    @test has_null_type(Union{Number, String}) == false
    @test is_required_field(Union{Nothing, Missing}) == false
end
@testset "is_required_field" begin
    @test is_required_field(Number) == true
    @test is_required_field(Nothing) == false
    @test is_required_field(Union{Number, Nothing}) == false
    @test is_required_field(Union{Number, Missing}) == true
    @test is_required_field(Union{Number, String}) == true
    @test is_required_field(Union{Nothing, Missing}) == false
end
@testset "remove_null_type" begin
    @test remove_null_types(Number) == Number
    @test remove_null_types(Nothing) == Any
    @test remove_null_types(Union{Number, Nothing}) == Number
    @test remove_null_types(Union{Number, Missing}) == Number
    @test remove_null_types(Union{Number, String}) == Union{Number, String}
    @test remove_null_types(Union{Nothing, Missing}) == Any
end
@testset "extract_docstring" begin
    struct MyStructNoDocs
        field1::Int
    end
    docstring = extract_docstring(MyStructNoDocs)
    @test docstring == ""

    "I am a docstring."
    struct MyStructHasDocs
        field1::Int
    end
    docstring = extract_docstring(MyStructHasDocs)
    @test docstring == "I am a docstring.\n"

    docstring = extract_docstring(MyStructHasDocs; max_description_length = 4)
    @test docstring == "I am"

    # Ignore docs for generic types
    docstring = extract_docstring(Dict)
    @test docstring == ""

    ## intentionally broken -- cannot parse docstrings for Structs that have supertype different from Any
    abstract type MyBaseType2 end
    "Docstring is here!"
    struct MyStructWithSuper2 <: MyBaseType2
        field1::Int
    end
    docstring = extract_docstring(MyStructWithSuper2)
    @test_broken haskey(schema, "description")
end

@testset "to_json_schema" begin
    struct MyStruct
        field1::Int
        field2::String
        field3::Union{Nothing, Float64}
        field4::Union{Missing, Bool}
    end
    schema = to_json_schema(MyStruct)
    # detect struct type
    @test schema["type"] == "object"
    # field extraction
    @test haskey(schema, "properties")
    @test haskey(schema["properties"], "field1")
    @test haskey(schema["properties"], "field2")
    @test schema["properties"]["field1"]["type"] == "integer"
    @test schema["properties"]["field2"]["type"] == "string"
    @test schema["properties"]["field3"]["type"] == "number"
    @test schema["properties"]["field4"]["type"] == "boolean"
    @test schema["required"] == ["field1", "field2", "field4"]
    # no docs
    @test !haskey(schema, "description")

    ## Check with docs
    "Here is a docstring."
    struct MyStructWithDocs
        a::Int
    end
    schema = to_json_schema(MyStructWithDocs)
    @test schema["type"] == "object"
    @test haskey(schema, "description")
    @test schema["description"] == "Here is a docstring.\n"

    ## Singleton types (ie, not collections)
    schema = to_json_schema(Int)
    @test schema["type"] == "integer"
    schema = to_json_schema(Float32)
    @test schema["type"] == "number"
    schema = to_json_schema(Bool)
    @test schema["type"] == "boolean"

    ## Check with nested types
    schema = to_json_schema(Vector{Float32})
    @test schema["type"] == "array"
    @test schema["items"]["type"] == "number"

    ## Special types
    @enum TemperatureUnits celsius fahrenheit
    schema = to_json_schema(TemperatureUnits)
    @test schema["type"] == "string"
    @test schema["enum"] == ["celsius", "fahrenheit"]

    ## Nested struct parsing
    schema = to_json_schema(Vector{MyStruct})
    @test schema["type"] == "array"
    schema_items = schema["items"]
    @test schema_items["type"] == "object"
    @test haskey(schema_items, "properties")
    @test haskey(schema_items["properties"], "field1")
    @test haskey(schema_items["properties"], "field2")
    @test schema_items["properties"]["field1"]["type"] == "integer"
    @test schema_items["properties"]["field2"]["type"] == "string"
    @test schema_items["properties"]["field3"]["type"] == "number"
    @test schema_items["properties"]["field4"]["type"] == "boolean"
    @test schema_items["required"] == ["field1", "field2", "field4"]

    ## Struct in a Struct
    struct MyStructWrapper
        field1::MyStruct
        field2::Int
    end
    schema = to_json_schema(MyStructWrapper)
    @test schema["type"] == "object"
    @test schema["properties"]["field2"]["type"] == "integer"
    @test schema["required"] == ["field1", "field2"]
    schema_mystruct = schema["properties"]["field1"]
    @test schema_mystruct["properties"]["field1"]["type"] == "integer"
    @test schema_mystruct["properties"]["field2"]["type"] == "string"
    @test schema_mystruct["properties"]["field3"]["type"] == "number"
    @test schema_mystruct["properties"]["field4"]["type"] == "boolean"

    ## Fallback to string (for tough unions)
    @test to_json_schema(Any) == Dict("type" => "string")
    @test to_json_schema(Union{Int, String, Real}) == Dict("type" => "string")

    ## Disallowed types
    @test_throws ArgumentError to_json_schema(Dict{String, Int})

    ## No required fields
    struct MyStructNoRequired
        field1::Union{Nothing, Int}
        field2::Union{String, Nothing}
    end
    schema = to_json_schema(MyStructNoRequired)
    @test !haskey(schema, "required")

    ## intentionally broken -- cannot parse docstrings for Structs that have supertype different from Any
    abstract type MyBaseType end
    "Docstring is here!"
    struct MyStructFancy <: MyBaseType
        field1::Int
        field2::String
    end
    schema = to_json_schema(MyStructFancy)
    @test schema["type"] == "object"
    @test schema["properties"]["field1"]["type"] == "integer"
    @test schema["properties"]["field2"]["type"] == "string"
    @test schema["required"] == ["field1", "field2"]
    @test_broken haskey(schema, "description")
end

@testset "to_json_schema-MaybeExtract" begin
    "Represents person's age, height, and weight"
    struct MyMeasurement1
        age::Int
        height::Union{Int, Nothing}
        weight::Union{Nothing, Float64}
    end
    schema = to_json_schema(MaybeExtract{MyMeasurement1})
    @test schema["type"] == "object"
    @test schema["properties"]["error"]["type"] == "boolean"
    @test schema["properties"]["message"]["type"] == "string"
    @test schema["required"] == ["error"]
    @test haskey(schema, "description")
    ## Check that the nested struct is extracted correctly
    schema_measurement = schema["properties"]["result"]
    @test schema_measurement["type"] == "object"
    @test schema_measurement["properties"]["age"]["type"] == "integer"
    @test schema_measurement["properties"]["height"]["type"] == "integer"
    @test schema_measurement["properties"]["weight"]["type"] == "number"
    @test schema_measurement["required"] == ["age"]
    ## Check that the nested docstring is extracted correctly
    @test schema_measurement["description"] ==
          "Represents person's age, height, and weight\n"
end
@testset "to_json_schema-ItemsExtract" begin
    "Represents person's age, height, and weight"
    struct MyMeasurement11
        age::Int
        height::Union{Int, Nothing}
        weight::Union{Nothing, Float64}
    end
    schema = to_json_schema(ItemsExtract{MyMeasurement11})
    @test schema["type"] == "object"
    @test schema["properties"]["items"]["type"] == "array"
    @test schema["required"] == ["items"]
    @test haskey(schema, "description")
    ## Check that the nested struct is extracted correctly
    schema_measurement = schema["properties"]["items"]["items"]
    @test schema_measurement["type"] == "object"
    @test schema_measurement["properties"]["age"]["type"] == "integer"
    @test schema_measurement["properties"]["height"]["type"] == "integer"
    @test schema_measurement["properties"]["weight"]["type"] == "number"
    @test schema_measurement["required"] == ["age"]
    ## Check that the nested docstring is extracted correctly
    @test schema_measurement["description"] ==
          "Represents person's age, height, and weight\n"
end
@testset "set_properties_strict!" begin
    # Test 1: Basic functionality
    params = Dict(
        "properties" => Dict{String, Any}(
            "name" => Dict{String, Any}("type" => "string"),
            "age" => Dict{String, Any}("type" => "integer")
        ),
        "required" => ["name"]
    )
    set_properties_strict!(params)
    @test params["additionalProperties"] == false
    @test Set(params["required"]) == Set(["name", "age"])
    @test params["properties"]["age"]["type"] == ["integer", "null"]

    # Test 2: Nested properties
    params = Dict{String, Any}(
        "properties" => Dict{String, Any}(
        "person" => Dict{String, Any}(
        "type" => "object",
        "properties" => Dict{String, Any}(
            "name" => Dict{String, Any}("type" => "string"),
            "age" => Dict{String, Any}("type" => "integer")
        )
    )
    )
    )
    set_properties_strict!(params)
    @test params["properties"]["person"]["additionalProperties"] == false
    @test Set(params["properties"]["person"]["required"]) ==
          Set(["name", "age"])

    # Test 3: Array of objects
    params = Dict{String, Any}(
        "properties" => Dict{String, Any}(
        "people" => Dict{String, Any}(
        "type" => "array",
        "items" => Dict{String, Any}(
            "type" => "object",
            "properties" => Dict{String, Any}(
                "name" => Dict{String, Any}("type" => "string"),
                "age" => Dict{String, Any}("type" => "integer")
            )
        )
    )
    )
    )
    set_properties_strict!(params)
    @test params["properties"]["people"]["items"]["additionalProperties"] == false
    @test Set(params["properties"]["people"]["items"]["required"]) == Set(["name", "age"])

    # Test 4: Multiple levels of nesting
    params = Dict{String, Any}(
        "properties" => Dict{String, Any}(
        "company" => Dict{String, Any}(
        "type" => "object",
        "properties" => Dict{String, Any}(
            "name" => Dict{String, Any}("type" => "string"),
            "employees" => Dict{String, Any}(
                "type" => "array",
                "items" => Dict{String, Any}(
                    "type" => "object",
                    "properties" => Dict{String, Any}(
                        "name" => Dict{String, Any}("type" => "string"),
                        "position" => Dict{String, Any}("type" => "string")
                    )
                )
            )
        )
    )
    )
    )
    set_properties_strict!(params)
    @test params["properties"]["company"]["additionalProperties"] == false
    @test params["properties"]["company"]["properties"]["employees"]["items"]["additionalProperties"] ==
          false
    @test Set(params["properties"]["company"]["properties"]["employees"]["items"]["required"]) ==
          Set(["name", "position"])

    # Test 5: Handling of existing required fields
    params = Dict{String, Any}(
        "properties" => Dict{String, Any}(
            "name" => Dict{String, Any}("type" => "string"),
            "age" => Dict{String, Any}("type" => "integer"),
            "email" => Dict{String, Any}("type" => "string")
        ),
        "required" => ["name", "email"]
    )
    set_properties_strict!(params)
    @test Set(params["required"]) == Set(["name", "email", "age"])
    @test params["properties"]["age"]["type"] == ["integer", "null"]
    @test !haskey(params["properties"]["name"], "null")
    @test !haskey(params["properties"]["email"], "null")
end

@testset "function_call_signature" begin
    "Some docstring"
    struct MyMeasurement2
        age::Int
        height::Union{Int, Nothing}
        weight::Union{Nothing, Float64}
    end
    output = function_call_signature(MyMeasurement2)#|> JSON3.pretty
    expected_output = Dict{String, Any}("name" => "MyMeasurement2_extractor",
        "parameters" => Dict{String, Any}(
            "properties" => Dict{String, Any}(
                "height" => Dict{
                    String,
                    Any
                }("type" => "integer"),
                "weight" => Dict{String, Any}("type" => "number"),
                "age" => Dict{String, Any}("type" => "integer")),
            "required" => ["age"],
            "type" => "object"),
        "description" => "Some docstring\n")
    @test output == expected_output

    ## MaybeWraper name cleanup
    schema = function_call_signature(MaybeExtract{MyMeasurement2})
    @test schema["name"] == "MaybeExtractMyMeasurement2_extractor"

    ## Test with strict = true

    "Person's age, height, and weight."
    struct MyMeasurement3
        age::Int
        height::Union{Int, Nothing}
        weight::Union{Nothing, Float64}
    end

    # Test with strict = nothing (default behavior)
    output_default = function_call_signature(MyMeasurement3)
    @test !haskey(output_default, "strict")
    @test output_default["name"] == "MyMeasurement3_extractor"
    @test output_default["parameters"]["type"] == "object"
    @test output_default["parameters"]["required"] == ["age"]
    @test !haskey(output_default["parameters"], "additionalProperties")

    # Test with strict =false
    output_not_strict = function_call_signature(MyMeasurement3; strict = false)
    @test haskey(output_not_strict, "strict")
    @test output_not_strict["strict"] == false
    @test output_not_strict["name"] == "MyMeasurement3_extractor"
    @test output_not_strict["parameters"]["type"] == "object"
    @test output_not_strict["parameters"]["required"] == ["age"]
    @test !haskey(output_default["parameters"], "additionalProperties")

    # Test with strict = true
    output_strict = function_call_signature(MyMeasurement3; strict = true)
    @test output_strict["strict"] == true
    @test output_strict["name"] == "MyMeasurement3_extractor"
    @test output_strict["parameters"]["type"] == "object"
    @test Set(output_strict["parameters"]["required"]) == Set(["age", "height", "weight"])
    @test output_strict["parameters"]["additionalProperties"] == false
    @test output_strict["parameters"]["properties"]["height"]["type"] == ["integer", "null"]
    @test output_strict["parameters"]["properties"]["weight"]["type"] == ["number", "null"]
    @test output_strict["parameters"]["properties"]["age"]["type"] == "integer"

    # Test with MaybeExtract wrapper
    output_maybe = function_call_signature(MaybeExtract{MyMeasurement3}; strict = true)
    @test output_maybe["name"] == "MaybeExtractMyMeasurement3_extractor"
    @test output_maybe["parameters"]["properties"]["result"]["type"] == ["object", "null"]
    @test output_maybe["parameters"]["properties"]["error"]["type"] == "boolean"
    @test output_maybe["parameters"]["properties"]["message"]["type"] == ["string", "null"]
    @test Set(output_maybe["parameters"]["required"]) == Set(["result", "error", "message"])
end