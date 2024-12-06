using PromptingTools: MaybeExtract, extract_docstring, ItemsExtract, ToolMessage
using PromptingTools: has_null_type, is_required_field, remove_null_types, to_json_schema
using PromptingTools: tool_call_signature, set_properties_strict!, is_concrete_type,
                      to_json_type, is_not_union_type,
                      update_field_descriptions!, generate_struct
using PromptingTools: Tool, isabstracttool, execute_tool, parse_tool, get_arg_names,
                      get_arg_types, get_method, get_function, remove_field!,
                      tool_call_signature, ToolRef
using PromptingTools: AbstractToolError, ToolNotFoundError, ToolExecutionError,
                      ToolGenericError, is_hidden_field

# TODO: check more edge cases like empty structs

"This is a test function."
function my_test_function(x::Int, y::String)
    return "Test function: $x, $y"
end
function context_test_function(x::Int, y::String, ctx_z::Float64)
    return "Context test: $x, $y, $(ctx_z)"
end
function context_test_function2(x::Int, y::String, context::Dict)
    return "Context test: $x, $y, $(context)"
end

# Test function that accepts kwargs
function kwarg_test_function(x::Int; y::Int = 0, z::Int = 0, kwargs...)
    return x + y + z
end
# Test with function that has no kwargs
function no_kwarg_function(x::Int)
    return x
end

@testset "ToolErrors" begin
    e = ToolNotFoundError("Tool `xyz` not found")
    @test e isa AbstractToolError
    @test e.msg == "Tool `xyz` not found"

    e = ToolExecutionError(
        "Tool `xyz` execution failed", MethodError(my_test_function, (1,)))
    @test e isa AbstractToolError
    @test e.msg == "Tool `xyz` execution failed"

    e = ToolGenericError(
        "Tool `xyz` failed with a generic error", MethodError(my_test_function, (1,)))
    @test e isa AbstractToolError
    @test e.msg == "Tool `xyz` failed with a generic error"
end

@testset "Tool-constructor" begin
    tool = Tool(my_test_function)

    @test tool isa Tool
    @test tool.name == "my_test_function"
    @test haskey(tool.parameters, "properties")
    @test haskey(tool.parameters["properties"], "x")
    @test haskey(tool.parameters["properties"], "y")
    @test tool.callable == my_test_function

    # Test Tool constructor with a struct
    struct MyTestStruct
        field1::Int
        field2::String
    end

    tool_struct = Tool(MyTestStruct)

    @test tool_struct isa Tool
    @test tool_struct.name == "MyTestStruct"
    @test haskey(tool_struct.parameters, "properties")
    @test haskey(tool_struct.parameters["properties"], "field1")
    @test haskey(tool_struct.parameters["properties"], "field2")
    @test tool_struct.callable == MyTestStruct

    # Test show method
    io = IOBuffer()
    show(io, tool)
    output = String(take!(io))

    @test occursin("Tool", output)
    @test occursin("name", output)
    @test occursin("parameters", output)
    @test occursin("description", output)
    @test occursin("strict", output)
    @test occursin("callable", output)

    @test isabstracttool(tool) == true
    @test isabstracttool(tool_struct) == true
    @test isabstracttool(my_test_function) == false

    ## ToolRef
    tool = ToolRef(; ref = :computer, callable = println)
    @test tool isa ToolRef
    @test tool.ref == :computer
    @test tool.callable == println
    io = IOBuffer()
    show(io, tool)
    output = String(take!(io))
    @test occursin("ToolRef", output)
    @test occursin("computer", output)
end

@testset "is_concrete_type" begin
    @test is_concrete_type(Int) == true
    @test_throws ArgumentError is_concrete_type(AbstractString)
end

@testset "is_not_union_type" begin
    @test_throws ArgumentError is_not_union_type(Union{Int, String})
    @test is_not_union_type(Int) == true
end

@testset "to_json_type" begin
    # Test string types
    @test to_json_type(String) == "string"
    @test to_json_type(SubString{String}) == "string"

    # Test number types
    @test to_json_type(Float64) == "number"
    @test to_json_type(Float32) == "number"
    @test to_json_type(Int64) == "integer"
    @test to_json_type(Int32) == "integer"
    @test to_json_type(UInt8) == "integer"

    # Test boolean type
    @test to_json_type(Bool) == "boolean"

    # Test null types
    @test to_json_type(Nothing) == "null"
    @test to_json_type(Missing) == "null"

    # Test concrete Any types
    struct CustomType end
    @test to_json_type(CustomType) == "string"

    # Test error cases for abstract types
    @test_throws ArgumentError to_json_type(AbstractString)
    @test_throws ArgumentError to_json_type(Real)
    @test_throws ArgumentError to_json_type(Integer)
    @test_throws ArgumentError to_json_type(AbstractArray)
end

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

    # Test extraction of docstring from a method
    method = methods(my_test_function) |> first
    docstring = extract_docstring(method)
    @test docstring == "This is a test function.\n"
end

@testset "get_arg_names,get_arg_types" begin
    # Test a function with no arguments
    f1() = nothing
    @test get_arg_names(first(methods(f1))) == Symbol[]
    @test get_arg_types(first(methods(f1))) == []

    # Test a function with one argument
    f2(x) = x
    @test get_arg_names(first(methods(f2))) == [:x]
    @test get_arg_types(first(methods(f2))) == [Any]

    # Test a function with multiple arguments
    f3(x, y, z) = x + y + z
    @test get_arg_names(first(methods(f3))) == [:x, :y, :z]
    @test get_arg_types(first(methods(f3))) == [Any, Any, Any]

    # Test a function with keyword arguments
    f4(x; y = 1, z = 2) = x + y + z
    @test get_arg_names(first(methods(f4))) == [:x]
    @test get_arg_types(first(methods(f4))) == [Any]

    # Test a function with varargs
    f5(x, y, z...) = x + y + sum(z)
    @test get_arg_names(first(methods(f5))) == [:x, :y, :z]
    @test get_arg_types(first(methods(f5))) == [Any, Any, Vararg{Any}]

    # Test a function with type annotations
    f6(x::Int, y::String) = "$x$y"
    @test get_arg_names(first(methods(f6))) == [:x, :y]
    @test get_arg_types(first(methods(f6))) == [Int, String]
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

    schema = to_json_schema(Tuple{Int64, String})
    @test schema["type"] == "array"
    @test schema["items"]["type"] == "string"

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
    ## We force user to be explicit about the type, so it fails with a clear error
    @test_throws ArgumentError to_json_schema(Union{Int, String, Float64})

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

    ## Method
    method = methods(my_test_function) |> first
    schema = to_json_schema(method)
    @test schema["type"] == "object"
    @test schema["properties"]["x"]["type"] == "integer"
    @test schema["properties"]["y"]["type"] == "string"
    @test schema["required"] == ["x", "y"]
    @test haskey(schema, "description")
    @test schema["description"] == "This is a test function.\n"

    ## Round trip on complicated types
    struct MockTypeTest4
        # Test concrete types
        int_field::Int64
        float_field::Float64
        string_field::String
        bool_field::Bool

        # Test unions with Nothing/Missing
        nullable_int::Union{Int64, Nothing}
        missing_float::Union{Float64, Missing}

        # No type
        no_type_field::Any

        # Test nested types
        array_field::Vector{Float64}
        tuple_field::Tuple{Int64, String}

        ## Not supported
        # dict_field::Dict{String, Int64}
        # union_field::Union{Int64, String}
    end

    # Test basic schema structure for MockTypeTest4
    schema = to_json_schema(MockTypeTest4)
    @test schema isa Dict{String, Any}
    @test schema["type"] == "object"
    @test haskey(schema, "properties")
    @test haskey(schema, "required")

    # Test concrete type fields
    props = schema["properties"]
    @test props["int_field"]["type"] == "integer"
    @test props["float_field"]["type"] == "number"
    @test props["string_field"]["type"] == "string"
    @test props["bool_field"]["type"] == "boolean"

    # Test nullable/missing fields
    @test props["nullable_int"]["type"] == "integer"

    @test props["missing_float"]["type"] == "number"

    # Test Any field
    @test props["no_type_field"]["type"] == "string"

    # Test array field
    @test props["array_field"]["type"] == "array"
    @test props["array_field"]["items"]["type"] == "number"

    # Test tuple field
    @test props["tuple_field"]["type"] == "array"
    @test props["tuple_field"]["items"]["type"] == "string"

    # Test required fields
    @test "int_field" in schema["required"]
    @test "float_field" in schema["required"]
    @test "string_field" in schema["required"]
    @test "bool_field" in schema["required"]
    @test "nullable_int" ∉ schema["required"]

    ## Round-trip test with JSON3
    str = JSON3.write(MockTypeTest4(
        1, 2.0, "3", true, nothing, missing, "any", [4.0], (5, "6")))
    @test_nowarn instance = JSON3.read(str, MockTypeTest4)
    @test instance.int_field == 1
    @test instance.float_field == 2.0
    @test instance.string_field == "3"
    @test instance.bool_field == true
    @test instance.nullable_int == nothing
    @test instance.missing_float === missing
    @test instance.no_type_field == "any"
    @test instance.array_field == [4.0]
    @test instance.tuple_field == (5, "6")

    struct TestTuple1
        x::Tuple{Int64, String}
    end
    str = JSON3.write(TestTuple1((1, "2")))
    instance = JSON3.read(str, TestTuple1)
    @test instance.x == (1, "2")
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

@testset "is_hidden_field" begin
    # Test basic string matching
    @test is_hidden_field("context", ["context"]) == true
    @test is_hidden_field("data", ["context"]) == false

    # Test regex matching
    @test is_hidden_field("my_context", [r"context$"]) == true
    @test is_hidden_field("context_var", [r"^context"]) == true
    @test is_hidden_field("mydata", [r"context"]) == false

    # Test multiple patterns
    @test is_hidden_field("context", ["data", "context", "temp"]) == true
    @test is_hidden_field("context", [r"^data", r"temp$", r"context"]) == true

    # Test mixed string and regex patterns
    @test is_hidden_field(
        "my_context", Union{AbstractString, Regex}["data", r"context$"]) == true
    @test is_hidden_field(
        "context_var", Union{AbstractString, Regex}[r"^context", "temp"]) == true

    # Test empty patterns list
    @test is_hidden_field("context", String[]) == false
    @test is_hidden_field("context", Regex[]) == false

    # Test with Symbol input
    @test is_hidden_field(:context, ["context"]) == true
    @test is_hidden_field(:my_context, [r"context$"]) == true
    @test is_hidden_field(:data, ["context"]) == false
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

@testset "generate_struct" begin
    # Test with only field names
    fields = [:field1, :field2, :field3]
    struct_type, descriptions = generate_struct(fields)
    @test fieldnames(struct_type) == (:field1, :field2, :field3)
    @test descriptions == Dict{Symbol, String}()

    # Test with field names and types
    fields = [:field1 => Int, :field2 => String, :field3 => Float64]
    struct_type, descriptions = generate_struct(fields)
    @test fieldnames(struct_type) == (:field1, :field2, :field3)
    @test fieldtypes(struct_type) == (Int, String, Float64)
    @test descriptions == Dict{Symbol, String}()

    # Test with field names, types, and descriptions
    fields = [:field1 => Int, :field2 => String, :field3 => Float64,
        :field1__description => "Field 1 description",
        :field2__description => "Field 2 description"]
    struct_type, descriptions = generate_struct(fields)
    @test fieldnames(struct_type) == (:field1, :field2, :field3)
    @test fieldtypes(struct_type) == (Int, String, Float64)
    @test descriptions ==
          Dict(:field1 => "Field 1 description", :field2 => "Field 2 description")

    # Test with invalid field specification
    fields = [:field1 => Int, :field2 => :InvalidType]
    @test_throws ErrorException generate_struct(fields)
end

@testset "update_field_descriptions!" begin
    # Test with empty descriptions
    parameters = Dict("properties" => Dict("field1" => Dict("type" => "string")))
    descriptions = Dict{Symbol, String}()
    updated_schema = update_field_descriptions!(parameters, descriptions)
    @test !haskey(updated_schema["properties"]["field1"], "description")

    # Test with descriptions provided
    parameters = Dict("properties" => Dict("field1" => Dict("type" => "string")))
    descriptions = Dict(:field1 => "Field 1 description")
    updated_schema = update_field_descriptions!(parameters, descriptions)
    @test updated_schema["properties"]["field1"]["description"] ==
          "Field 1 description"

    # Test with max_description_length
    parameters = Dict("properties" => Dict("field1" => Dict("type" => "string")))
    descriptions = Dict(:field1 => "Field 1 description is very long and should be truncated")
    updated_schema = update_field_descriptions!(
        parameters, descriptions; max_description_length = 10)
    @test updated_schema["properties"]["field1"]["description"] ==
          "Field 1 de"

    # Test with multiple fields
    parameters = Dict("properties" => Dict(
        "field1" => Dict("type" => "string"), "field2" => Dict("type" => "integer")))
    descriptions = Dict(:field1 => "Field 1 description", :field2 => "Field 2 description")
    updated_schema = update_field_descriptions!(parameters, descriptions)
    @test updated_schema["properties"]["field1"]["description"] ==
          "Field 1 description"
    @test updated_schema["properties"]["field2"]["description"] ==
          "Field 2 description"

    # Test with missing field in descriptions
    parameters = Dict("properties" => Dict(
        "field1" => Dict("type" => "string"), "field2" => Dict("type" => "integer")))
    descriptions = Dict(:field1 => "Field 1 description")
    updated_schema = update_field_descriptions!(parameters, descriptions)
    @test updated_schema["properties"]["field1"]["description"] ==
          "Field 1 description"
    @test !haskey(updated_schema["properties"]["field2"], "description")
end

@testset "remove_field!" begin
    # Test removing a field by string
    parameters = Dict(
        "properties" => Dict(
            "field1" => Dict("type" => "string"),
            "field2" => Dict("type" => "integer")
        ),
        "required" => ["field1", "field2"]
    )
    remove_field!(parameters, "field1")
    @test !haskey(parameters["properties"], "field1")
    @test parameters["required"] == ["field2"]

    # Test removing a non-existent field
    remove_field!(parameters, "field3")
    @test parameters["properties"] == Dict("field2" => Dict("type" => "integer"))
    @test parameters["required"] == ["field2"]

    # Test removing a field by regex
    parameters = Dict(
        "properties" => Dict(
            "user_id" => Dict("type" => "string"),
            "user_name" => Dict("type" => "string"),
            "age" => Dict("type" => "integer")
        ),
        "required" => ["user_id", "user_name", "age"]
    )
    remove_field!(parameters, r"^user_")
    @test !haskey(parameters["properties"], "user_id")
    @test !haskey(parameters["properties"], "user_name")
    @test haskey(parameters["properties"], "age")
    @test parameters["required"] == ["age"]

    # Test removing with regex that doesn't match any fields
    remove_field!(parameters, r"^non_existent_")
    @test parameters["properties"] == Dict("age" => Dict("type" => "integer"))
    @test parameters["required"] == ["age"]

    # Test with empty properties and required fields
    parameters = Dict("properties" => Dict(), "required" => String[])
    remove_field!(parameters, "field")
    remove_field!(parameters, r"field")
    @test parameters == Dict("properties" => Dict(), "required" => String[])
end

@testset "tool_call_signature" begin
    "Some docstring"
    struct MyMeasurement2
        age::Int
        height::Union{Int, Nothing}
        weight::Union{Nothing, Float64}
    end
    tool_map = tool_call_signature(MyMeasurement2)#|> JSON3.pretty
    name, tool = only(tool_map)
    parameters = Dict{String, Any}(
        "properties" => Dict{String, Any}(
            "height" => Dict{
                String,
                Any
            }("type" => "integer"),
            "weight" => Dict{String, Any}("type" => "number"),
            "age" => Dict{String, Any}("type" => "integer")),
        "required" => ["age"],
        "type" => "object")
    @test tool.parameters == parameters
    @test tool.name == "MyMeasurement2"
    @test tool.description == "Some docstring\n"
    @test tool.strict == nothing
    @test tool.callable == MyMeasurement2
    @test isabstracttool(tool)

    ## MaybeWraper name cleanup
    tool_map = tool_call_signature(MaybeExtract{MyMeasurement2})
    name, tool = only(tool_map)
    @test name == "MaybeExtract"
    @test tool.parameters["properties"]["result"]["properties"] == parameters["properties"]
    @test tool.name == "MaybeExtract"
    @test tool.strict == nothing
    @test tool.description isa String
    @test tool.callable == MaybeExtract{MyMeasurement2}

    ## Test with strict = true

    "Person's age, height, and weight."
    struct MyMeasurement3
        age::Int
        height::Union{Int, Nothing}
        weight::Union{Nothing, Float64}
    end

    # Test with strict = nothing  (default behavior)
    tool_map = tool_call_signature(MyMeasurement3)
    name, tool = only(tool_map)
    @test tool.strict == nothing
    @test name == "MyMeasurement3"
    @test tool.parameters["properties"]["height"]["type"] == "integer"
    @test tool.parameters["properties"]["weight"]["type"] == "number"
    @test tool.parameters["properties"]["age"]["type"] == "integer"
    @test Set(tool.parameters["required"]) == Set(["age"])
    @test !haskey(tool.parameters, "additionalProperties")

    # Test with strict =false
    tool_map = tool_call_signature(MyMeasurement3; strict = false)
    name, tool = only(tool_map)
    @test tool.strict == false
    @test name == "MyMeasurement3"
    @test tool.parameters["properties"]["height"]["type"] == "integer"
    @test tool.parameters["properties"]["weight"]["type"] == "number"
    @test tool.parameters["properties"]["age"]["type"] == "integer"
    @test Set(tool.parameters["required"]) == Set(["age"])
    @test !haskey(tool.parameters, "additionalProperties")

    # Test with strict = true
    tool_map = tool_call_signature(MyMeasurement3; strict = true)
    name, tool = only(tool_map)
    @test tool.strict == true
    @test name == "MyMeasurement3"
    @test tool.parameters["properties"]["height"]["type"] == ["integer", "null"]
    @test tool.parameters["properties"]["weight"]["type"] == ["number", "null"]
    @test tool.parameters["properties"]["age"]["type"] == "integer"
    @test Set(tool.parameters["required"]) == Set(["age", "height", "weight"])
    @test haskey(tool.parameters, "additionalProperties")

    # Test with MaybeExtract wrapper
    tool_map = tool_call_signature(MaybeExtract{MyMeasurement3}; strict = true)
    name, tool_maybe = only(tool_map)
    @test name == "MaybeExtract"
    @test tool_maybe.parameters["properties"]["result"]["properties"] ==
          tool.parameters["properties"]
    @test tool_maybe.name == "MaybeExtract"
    @test tool_maybe.strict == true
    @test tool_maybe.description isa String
    @test tool_maybe.callable == MaybeExtract{MyMeasurement3}

    #### Test with generated structs and with descriptions
    # Test with simple fields
    fields = [:field1 => Int, :field2 => String]
    tool_map = tool_call_signature(fields)
    name, tool = only(tool_map)
    @test haskey(tool.parameters, "properties")
    @test haskey(tool.parameters["properties"], "field1")
    @test haskey(tool.parameters["properties"], "field2")
    @test tool.parameters["properties"]["field1"]["type"] == "integer"
    @test tool.parameters["properties"]["field2"]["type"] == "string"

    # Test with strict mode
    fields = [:field1 => Int, :field2 => String]
    tool_map = tool_call_signature(fields; strict = true)
    name, tool = only(tool_map)
    @test tool.strict == true

    # Test with descriptions and max_description_length
    fields = [
        :field1 => Int, :field2 => String, :field1__description => "Field 1 description",
        :field2__description => "Field 2 description"]
    tool_map = tool_call_signature(fields; max_description_length = 7)
    name, tool = only(tool_map)
    @test haskey(tool.parameters, "properties")
    @test haskey(tool.parameters["properties"], "field1")
    @test haskey(tool.parameters["properties"], "field2")
    @test tool.parameters["properties"]["field1"]["type"] == "integer"
    @test tool.parameters["properties"]["field2"]["type"] == "string"
    @test tool.parameters["properties"]["field1"]["description"] == "Field 1"
    @test tool.parameters["properties"]["field2"]["description"] == "Field 2"

    # Test with empty fields
    fields = []
    tool_map = tool_call_signature(fields)
    name, tool = only(tool_map)
    @test haskey(tool.parameters, "properties")
    @test isempty(tool.parameters["properties"])

    # Test with invalid field specification
    fields = [:field1 => Int, :field2 => :InvalidType]
    @test_throws ErrorException tool_call_signature(fields)
    fields = ["field1" => Int]
    @test_throws ErrorException tool_call_signature(fields)
    fields = ["field1", "field2"] # caught earlier as an error so assertion error
    @test_throws AssertionError tool_call_signature(fields)

    ## TODO: add Tool passthrough, functions, methods
    # Test with a function
    tool_map = tool_call_signature(my_test_function)
    name, tool = only(tool_map)
    @test name == "my_test_function"
    @test tool.name == "my_test_function"
    @test tool.description == "This is a test function.\n"
    @test tool.callable == my_test_function
    @test tool.strict == nothing
    @test tool.parameters["properties"]["x"]["type"] == "integer"
    @test tool.parameters["properties"]["y"]["type"] == "string"
    @test Set(tool.parameters["required"]) == Set(["x", "y"])

    # Test with a method
    method = first(methods(my_test_function))
    tool_map = tool_call_signature(method)
    name, tool = only(tool_map)
    @test name == "my_test_function"
    @test tool.name == "my_test_function"
    @test tool.description == "This is a test function.\n"
    @test tool.callable == my_test_function
    @test tool.strict == nothing
    @test tool.parameters["properties"]["x"]["type"] == "integer"

    # Test with a tool
    tool_map = tool_call_signature(method)
    name, tool = only(tool_map)
    tool_map2 = tool_call_signature(tool)
    name2, tool2 = only(tool_map2)
    @test name == name2
    @test tool.name == tool2.name
    @test tool.description == tool2.description
    @test tool.callable == tool2.callable
    @test tool.strict == tool2.strict
    @test tool.parameters == tool2.parameters

    # Test with a vector of tools
    tools = Union{Function, Type}[my_test_function, MyMeasurement3]
    tool_map = tool_call_signature(tools)
    @test length(tool_map) == 2
    for (name, tool) in tool_map
        @test name isa String
        @test tool isa Tool
    end
    tool1 = tool_map["my_test_function"]
    @test tool1.name == "my_test_function"
    @test tool1.description == "This is a test function.\n"
    @test tool1.callable == my_test_function
    @test tool1.strict == nothing
    @test tool1.parameters["properties"]["x"]["type"] == "integer"
    @test tool1.parameters["properties"]["y"]["type"] == "string"
    @test Set(tool1.parameters["required"]) == Set(["x", "y"])

    tool2 = tool_map["MyMeasurement3"]
    @test tool2.name == "MyMeasurement3"
    @test tool2.description == "Person's age, height, and weight.\n"
    @test tool2.callable == MyMeasurement3
    @test tool2.strict == nothing
    @test tool2.parameters["properties"]["age"]["type"] == "integer"
    @test tool2.parameters["properties"]["height"]["type"] == "integer"
    @test tool2.parameters["properties"]["weight"]["type"] == "number"

    ## ToolRef
    tool = ToolRef(; ref = :computer, callable = println)
    tool_map = tool_call_signature(tool)
    @test tool_map == Dict("computer" => tool)

    ## accepting dictionary when it's hidden // it would fail otherwise
    tool_map = tool_call_signature(context_test_function2; hidden_fields = ["context"])
    @test tool_map isa Dict

    @test_throws ArgumentError tool_call_signature(context_test_function2)

    # for struct
    mutable struct MyStruct1234
        context::Dict{String, Any}
    end
    @test_throws ArgumentError tool_call_signature(MyStruct1234)
    tool_map = tool_call_signature(MyStruct1234; hidden_fields = ["context"])
    @test tool_map isa Dict
end

@testset "parse_tool" begin
    # Test parsing a valid JSON string into a struct
    struct MyStruct1233
        x::Int
        y::String
    end
    result = parse_tool(MyStruct1233, "{\"x\": 1, \"y\": \"test\"}")
    @test result.x == 1
    @test result.y == "test"

    # Test parsing an empty JSON string
    struct EmptyStruct end
    @test parse_tool(EmptyStruct, "{}") isa EmptyStruct

    # Test parsing a valid JSON string with missing fields
    @kwdef struct PartialStruct
        x::Int
        y::Union{String, Nothing} = nothing
    end
    result = parse_tool(PartialStruct, "{\"x\": 1}")
    @test result.x == 1
    @test result.y === nothing

    # Test parsing an invalid JSON string
    @test_logs (:warn, r"There was an error parsing the response:.*") parse_tool(
        Tuple, "{\"a\": 1}")

    # Test parsing a valid JSON string into a Dict
    result = parse_tool(Dict, "{\"x\": 1, \"y\": \"test\"}")
    @test result isa Dict
    @test result["x"] == 1
    @test result["y"] == "test"

    # Test parsing an empty dict
    @test parse_tool(Dict, "{}") isa Dict

    # Test parsing a non-empty dict
    result = parse_tool(
        NamedTuple{(:x, :y), Tuple{Int, String}}, "{\"x\": 1, \"y\": \"test\"}")
    @test result.x == 1
    @test result.y == "test"
end

@testset "execute_tool" begin
    # Test executing a function with ordered arguments
    args = Dict(:x => 5, :y => "hello")
    @test execute_tool(my_test_function, args) == "Test function: 5, hello"

    # Test executing a function with unordered arguments
    args_unordered = Dict(:y => "world", :x => 10)
    @test execute_tool(my_test_function, args_unordered) == "Test function: 10, world"

    tool = Tool(my_test_function)
    @test execute_tool(tool, args) == "Test function: 5, hello"

    # Test executing a function with context
    args = Dict(:x => 5, :y => "hello")
    context = Dict(:ctx_z => 3.14)
    @test execute_tool(context_test_function, args, context) ==
          "Context test: 5, hello, 3.14"

    # Test context overriding args
    args_override = Dict(:x => 5, :y => "hello", :ctx_z => 2.71)
    context_override = Dict(:y => "world", :ctx_z => 3.14)
    @test execute_tool(context_test_function, args_override, context_override) ==
          "Context test: 5, world, 3.14"

    # with full context
    args = Dict(:x => 5, :y => "hello")
    context_override = Dict(:new_arg => "new_value")
    @test execute_tool(context_test_function2, args, context_override) ==
          "Context test: 5, hello, Dict(:new_arg => \"new_value\")"

    # Test with missing argument in both args and context
    args_missing = Dict(:x => 5)
    context_missing = Dict(:y => "hello")
    @test_throws ToolExecutionError execute_tool(
        context_test_function, args_missing, context_missing)
    err = execute_tool(
        context_test_function, args_missing, context_missing; throw_on_error = false)
    @test err isa ToolExecutionError
    @test err.err isa MethodError

    # Test with Tool
    context_tool = Tool(context_test_function)
    @test execute_tool(context_tool, args, context) == "Context test: 5, hello, 3.14"

    # Test with tool_map
    args = Dict(:x => 10, :y => "hello")
    tool_map = tool_call_signature(my_test_function; hidden_fields = [r"ctx"])
    msg = ToolMessage(;
        tool_call_id = "1", name = "my_test_function", raw = "", args = args)
    output = execute_tool(tool_map, msg)
    @test output == "Test function: 10, hello"
    ## Call wrong tool name
    @test_throws ToolNotFoundError execute_tool(tool_map,
        ToolMessage(;
            tool_call_id = "1", name = "wrong_tool_name", raw = "", args = args))

    # Test passing kwargs directly
    args = Dict(:x => 1)
    @test execute_tool(kwarg_test_function, args; y = 2, z = 3) == 6 # 1 + 2 + 3

    # Test unused args passed as kwargs when unused_as_kwargs=true
    args = Dict(:x => 1, :y => 2, :z => 3, :extra => 4)
    @test execute_tool(kwarg_test_function, args; unused_as_kwargs = true) == 6 # 1 + 2 + 3

    # Test that extra args are ignored when unused_as_kwargs=false
    args = Dict(:x => 1, :y => 2, :z => 3, :extra => 4)
    @test execute_tool(kwarg_test_function, args; unused_as_kwargs = false) == 1

    # Test that args override kwargs when unused_as_kwargs=true
    args = Dict(:x => 1, :y => 2, :z => 3)
    @test execute_tool(kwarg_test_function, args; unused_as_kwargs = true, y = 5) == 6 # args

    args = Dict(:x => 1, :extra => 2)
    @test execute_tool(no_kwarg_function, args; unused_as_kwargs = false) == 1
end
