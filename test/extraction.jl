using PromptingTools: MaybeExtract, extract_docstring, ItemsExtract
using PromptingTools: has_null_type, is_required_field, remove_null_types, to_json_schema
using PromptingTools: function_call_signature

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
end
@testset "to_json_schema-primitive_types" begin
    @test to_json_schema(Int) == Dict("type" => "integer")
    @test to_json_schema(Float64) == Dict("type" => "number")
    @test to_json_schema(Bool) == Dict("type" => "boolean")
    @test to_json_schema(String) == Dict("type" => "string")
    @test_throws ArgumentError to_json_schema(Any) # Type Any is not supported
end
@testset "to_json_schema-structs" begin
    # Function to check the equivalence of two JSON strings, since Dict is
    # unordered, we need to sort keys before comparison.
    function check_json_equivalence(json1::AbstractString, json2::AbstractString)
        println("\ncheck_json_equivalence\n===json1===")
        println(json1)
        println("===json2===")
        println(json2)
        println()
        # JSON dictionary
        d1 = JSON3.read(json1)
        d2 = JSON3.read(json2)

        # Get all the keys
        k1 = sort(collect(keys(d1)))
        k2 = sort(collect(keys(d2)))

        # Test that all the keys are present
        @test setdiff(k1, k2) == []
        @test setdiff(k2, k1) == []

        # Test that all the values are equivalent
        for (k, v) in d1
            @test d2[k] == v
        end

        # @test JSON3.write(JSON3.read(json1)) == JSON3.write(JSON3.read(json2))
    end
    function check_json_equivalence(d::Dict, s::AbstractString)
        return check_json_equivalence(JSON3.write(d), s)
    end

    # Simple flat structure where each field is a primitive type
    struct SimpleSingleton
        singleton_value::Int
    end

    check_json_equivalence(
        JSON3.write(typed_json_schema(SimpleSingleton)),
        "{\"singleton_value\":\"integer\"}"
    )

    # Test a struct that contains another struct.
    struct Nested
        inside_element::SimpleSingleton
    end

    check_json_equivalence(
        JSON3.write(typed_json_schema(Nested)),
        "{\"inside_element\":{\"singleton_value\":\"integer\"}}"
    )

    # Test a struct with two primitive types
    struct IntFloatFlat
        int_value::Int
        float_value::Float64
    end
    check_json_equivalence(
        typed_json_schema(IntFloatFlat),
        "{\"int_value\":\"integer\",\"float_value\":\"number\"}"
    )

    # Test a struct that contains all primitive types
    struct AllJSONPrimitives
        int::Integer
        float::Real
        string::AbstractString
        bool::Bool
        nothing::Nothing
        missing::Missing

        # Array types
        array_of_strings::Vector{String}
        array_of_ints::Vector{Int}
        array_of_floats::Vector{Float64}
        array_of_bools::Vector{Bool}
        array_of_nothings::Vector{Nothing}
        array_of_missings::Vector{Missing}
    end

    check_json_equivalence(
        typed_json_schema(AllJSONPrimitives),
        "{\"int\":\"integer\",\"float\":\"number\",\"string\":\"string\",\"bool\":\"boolean\",\"nothing\":\"null\",\"missing\":\"null\",\"array_of_strings\":\"string[]\",\"array_of_ints\":\"integer[]\",\"array_of_floats\":\"number[]\",\"array_of_bools\":\"boolean[]\",\"array_of_nothings\":\"null[]\",\"array_of_missings\":\"null[]\"}"
    )

    # Test a struct with a vector of primitives
    struct ABunchOfVectors
        strings::Vector{String}
        ints::Vector{Int}
        floats::Vector{Float64}
        nested_vector::Vector{Nested}
    end

    check_json_equivalence(
        typed_json_schema(ABunchOfVectors),
        "{\"strings\":\"string[]\",\"ints\":\"integer[]\",\"nested_vector\":{\"list[Object]\":\"{\\\"inside_element\\\":{\\\"singleton_value\\\":\\\"integer\\\"}}\"},\"floats\":\"number[]\"}"
    )

    # Weird struct with a bunch of different types
    struct Monster
        name::String
        age::Int
        height::Float64
        friends::Vector{String}
        nested::Nested
        flat::IntFloatFlat
    end

    check_json_equivalence(
        typed_json_schema(Monster),
        "{\"flat\":{\"float_value\":\"number\",\"int_value\":\"integer\"},\"nested\":{\"inside_element\":{\"singleton_value\":\"integer\"}},\"age\":\"integer\",\"name\":\"string\",\"height\":\"number\",\"friends\":\"string[]\"}"
    )
end;
