########################
# Extraction
########################
# These are utilities to support structured data extraction tasks through the OpenAI function calling interface (wrapped by `aiextract`)
#
# There are potential formats: 1) JSON-based for OpenAI compatible APIs, 2) XML-based for Anthropic compatible APIs (used also by Hermes-2-Pro model). 
#

######################
# 1) OpenAI / JSON format
######################

to_json_type(s::Type{<:AbstractString}) = "string"
to_json_type(n::Type{<:Real}) = "number"
to_json_type(n::Type{<:Integer}) = "integer"
to_json_type(b::Type{Bool}) = "boolean"
to_json_type(t::Type{<:Union{Missing, Nothing}}) = "null"
to_json_type(t::Type{<:Any}) = "string" # object?

has_null_type(T::Type{Missing}) = true
has_null_type(T::Type{Nothing}) = true
has_null_type(T::Type) = T isa Union && any(has_null_type, Base.uniontypes(T))
## For required fields, only Nothing is considered a null type (and be easily parsed by JSON3)
is_required_field(T::Type{Nothing}) = false
function is_required_field(T::Type)
    if T isa Union
        all(is_required_field, Base.uniontypes(T))
    else
        true
    end
end

# Remove null types from Union etc.
remove_null_types(T::Type{Missing}) = Any
remove_null_types(T::Type{Nothing}) = Any
remove_null_types(T::Type{Union{Nothing, Missing}}) = Any
function remove_null_types(T::Type)
    T isa Union ? Union{filter(!has_null_type, Base.uniontypes(T))...} : T
end

function extract_docstring(type::Type; max_description_length::Int = 100)
    ## plain struct has supertype Any
    ## we ignore the ones that are subtypes for now (to prevent picking up Dicts, etc.)
    if supertype(type) == Any
        docs = Docs.doc(type) |> string
        if !occursin("No documentation found.\n\n", docs)
            return first(docs, max_description_length)
        end
    end
    return ""
end

function to_json_schema(orig_type; max_description_length::Int = 100)
    schema = Dict{String, Any}()
    type = remove_null_types(orig_type)
    if isstructtype(type)
        schema["type"] = "object"
        schema["properties"] = Dict{String, Any}()
        ## extract the field names and types
        required_types = String[]
        for (field_name, field_type) in zip(fieldnames(type), fieldtypes(type))
            schema["properties"][string(field_name)] = to_json_schema(
                remove_null_types(field_type);
                max_description_length)
            ## Hack: no null type (Nothing, Missing) implies it it is a required field
            is_required_field(field_type) && push!(required_types, string(field_name))
        end
        !isempty(required_types) && (schema["required"] = required_types)
        ## docstrings
        docs = extract_docstring(type; max_description_length)
        !isempty(docs) && (schema["description"] = docs)
    else
        schema["type"] = to_json_type(type)
    end
    return schema
end
function to_json_schema(type::Type{<:AbstractString}; max_description_length::Int = 100)
    Dict{String, Any}("type" => to_json_type(type))
end
function to_json_schema(type::Type{T};
        max_description_length::Int = 100) where {T <:
                                                  Union{AbstractSet, Tuple, AbstractArray}}
    element_type = eltype(type)
    return Dict{String, Any}("type" => "array",
        "items" => to_json_schema(remove_null_types(element_type)))
end
function to_json_schema(type::Type{<:Enum}; max_description_length::Int = 100)
    enum_options = Base.Enums.namemap(type) |> values .|> string
    return Dict{String, Any}("type" => "string",
        "enum" => enum_options)
end
function to_json_schema(type::Type{<:AbstractDict}; max_description_length::Int = 100)
    throw(ArgumentError("Dicts are not supported yet as we cannot analyze their keys/values on a type-level. Use a nested Struct instead!"))
end

### Type conversion / Schema generation
"""
    generate_struct(fields::Vector)

Generate a struct with the given name and fields. Fields can be specified simply as symbols (with default type `String`) or pairs of symbol and type.
Field descriptions can be provided by adding a pair with the field name suffixed with "__description" (eg, `:myfield__description => "My field description"`).

Returns: A tuple of (struct type, descriptions)

# Examples
```julia
Weather, descriptions = generate_struct(
    [:location,
     :temperature=>Float64,
     :temperature__description=>"Temperature in degrees Fahrenheit",
     :condition=>String,
     :condition__description=>"Current weather condition (e.g., sunny, rainy, cloudy)"
    ])
```
"""
function generate_struct(fields::Vector)
    name = gensym("ExtractedData")
    struct_fields = []
    descriptions = Dict{Symbol, String}()

    for field in fields
        if field isa Symbol
            push!(struct_fields, :($field::String))
        elseif field isa Pair
            field_name, field_value = field
            if endswith(string(field_name), "__description")
                base_field = Symbol(replace(string(field_name), "__description" => ""))
                descriptions[base_field] = field_value
            elseif field_name isa Symbol &&
                   (field_value isa Type || field_value isa AbstractString)
                push!(struct_fields, :($field_name::$field_value))
            else
                error("Invalid field specification: $(field). It must be a Symbol or a Pair{Symbol, Type} or Pair{Symbol, Pair{Type, String}}.")
            end
        else
            error("Invalid field specification: $(field). It must be a Symbol or a Pair{Symbol, Type} or Pair{Symbol, Pair{Type, String}}.")
        end
    end

    struct_def = quote
        @kwdef struct $name <: AbstractExtractedData
            $(struct_fields...)
        end
    end

    # Evaluate the struct definition
    eval(struct_def)

    return eval(name), descriptions
end

"""
    update_schema_descriptions!(
        schema::Dict{String, <:Any}, descriptions::Dict{Symbol, <:AbstractString};
        max_description_length::Int = 200)

Update the given JSON schema with descriptions from the `descriptions` dictionary.
This function modifies the schema in-place, adding a "description" field to each property
that has a corresponding entry in the `descriptions` dictionary.

Note: It modifies the schema in place. Only the top-level "properties" are updated!

Returns: The modified schema dictionary.

# Arguments
- `schema`: A dictionary representing the JSON schema to be updated.
- `descriptions`: A dictionary mapping field names (as symbols) to their descriptions.
- `max_description_length::Int`: Maximum length for descriptions. Defaults to 200.

# Examples
```julia
    schema = Dict{String, Any}(
        "name" => "varExtractedData235_extractor",
        "parameters" => Dict{String, Any}(
            "properties" => Dict{String, Any}(
                "location" => Dict{String, Any}("type" => "string"),
                "condition" => Dict{String, Any}("type" => "string"),
                "temperature" => Dict{String, Any}("type" => "number")
            ),
            "required" => ["location", "temperature", "condition"],
            "type" => "object"
        )
    )
    descriptions = Dict{Symbol, String}(
        :temperature => "Temperature in degrees Fahrenheit",
        :condition => "Current weather condition (e.g., sunny, rainy, cloudy)"
    )
    update_schema_descriptions!(schema, descriptions)
```
"""
function update_schema_descriptions!(
        schema::Dict{String, <:Any}, descriptions::Dict{Symbol, <:AbstractString};
        max_description_length::Int = 200)
    properties = get(get(schema, "parameters", Dict()), "properties", Dict())

    for (field, field_schema) in properties
        field_sym = Symbol(field)
        if haskey(descriptions, field_sym)
            field_schema["description"] = first(
                descriptions[field_sym], max_description_length)
        end
    end

    return schema
end

"""
    set_properties_strict!(properties::AbstractDict)

Sets strict mode for the properties of a JSON schema.

Changes:
- Sets `additionalProperties` to `false`.
- All keys must be included in `required`.
- All optional keys will have `null` added to their type.

Reference: https://platform.openai.com/docs/guides/structured-outputs/supported-schemas
"""
function set_properties_strict!(parameters::AbstractDict)
    parameters["additionalProperties"] = false
    required_fields = get(parameters, "required", String[])
    optional_fields = String[]

    for (key, value) in parameters["properties"]
        if key ∉ required_fields
            push!(optional_fields, key)
            if haskey(value, "type")
                value["type"] = [value["type"], "null"]
            end
        end

        # Recursively apply to nested properties
        if haskey(value, "properties")
            set_properties_strict!(value)
        elseif haskey(value, "items") && haskey(value["items"], "properties")
            ## if it's an array, we need to skip inside "items"
            set_properties_strict!(value["items"])
        end
    end

    parameters["required"] = vcat(required_fields, optional_fields)
    return parameters
end

"""
    function_call_signature(
        datastructtype::Type; strict::Union{Nothing, Bool} = nothing,
        max_description_length::Int = 200)

Extract the argument names, types and docstrings from a struct to create the function call signature in JSON schema.

You must provide a Struct type (not an instance of it) with some fields.

Note: Fairly experimental, but works for combination of structs, arrays, strings and singletons.

# Tips
- You can improve the quality of the extraction by writing a helpful docstring for your struct (or any nested struct). It will be provided as a description. 
 You can even include comments/descriptions about the individual fields.
- All fields are assumed to be required, unless you allow null values (eg, `::Union{Nothing, Int}`). Fields with `Nothing` will be treated as optional.
- Missing values are ignored (eg, `::Union{Missing, Int}` will be treated as Int). It's for broader compatibility and we cannot deserialize it as easily as `Nothing`.

# Example

Do you want to extract some specific measurements from a text like age, weight and height?
You need to define the information you need as a struct (`return_type`):
```
struct MyMeasurement
    age::Int
    height::Union{Int,Nothing}
    weight::Union{Nothing,Float64}
end
signature, t = function_call_signature(MyMeasurement)
#
# Dict{String, Any} with 3 entries:
#   "name"        => "MyMeasurement_extractor"
#   "parameters"  => Dict{String, Any}("properties"=>Dict{String, Any}("height"=>Dict{String, Any}("type"=>"integer"), "weight"=>Dic…
#   "description" => "Represents person's age, height, and weight
"
```

You can see that only the field `age` does not allow null values, hence, it's "required".
While `height` and `weight` are optional.
```
signature["parameters"]["required"]
# ["age"]
```

If there are multiple items you want to extract, define a wrapper struct to get a Vector of `MyMeasurement`:
```
struct MyMeasurementWrapper
    measurements::Vector{MyMeasurement}
end

Or if you want your extraction to fail gracefully when data isn't found, use `MaybeExtract{T}` wrapper (inspired by Instructor package!):
```
using PromptingTools: MaybeExtract

type = MaybeExtract{MyMeasurement}
# Effectively the same as:
# struct MaybeExtract{T}
#     result::Union{T, Nothing}
#     error::Bool // true if a result is found, false otherwise
#     message::Union{Nothing, String} // Only present if no result is found, should be short and concise
# end

# If LLM extraction fails, it will return a Dict with `error` and `message` fields instead of the result!
msg = aiextract("Extract measurements from the text: I am giraffe", type)

#
# Dict{Symbol, Any} with 2 entries:
# :message => "Sorry, this feature is only available for humans."
# :error   => true
```
That way, you can handle the error gracefully and get a reason why extraction failed.
"""
function function_call_signature(
        datastructtype::Type; strict::Union{Nothing, Bool} = nothing,
        max_description_length::Int = 200)
    !isstructtype(datastructtype) &&
        error("Only Structs are supported (provided type: $datastructtype")
    ## Standardize the name
    name = string(datastructtype, "_extractor") |>
           x -> replace(x, r"[^0-9A-Za-z_-]" => "") |> x -> first(x, 64)
    schema = Dict{String, Any}("name" => name,
        "parameters" => to_json_schema(datastructtype; max_description_length))
    ## docstrings
    docs = extract_docstring(datastructtype; max_description_length)
    !isempty(docs) && (schema["description"] = docs)
    ## remove duplicated Struct docstring in schema
    if haskey(schema["parameters"], "description") &&
       schema["parameters"]["description"] == docs
        delete!(schema["parameters"], "description")
    end
    ## strict mode // see https://platform.openai.com/docs/guides/structured-outputs/supported-schemas
    if strict == false
        schema["strict"] = false
    elseif strict == true
        schema["strict"] = true
        if haskey(schema["parameters"], "properties")
            set_properties_strict!(schema["parameters"])
        end
    end
    return schema, datastructtype
end

"""
    function_call_signature(fields::Vector; strict::Union{Nothing, Bool} = nothing, max_description_length::Int = 200)

Generate a function call signature schema for a dynamically generated struct based on the provided fields.

# Arguments
- `fields::Vector{Union{Symbol, Pair{Symbol, Type}, Pair{Symbol, String}}}`: A vector of field names or pairs of field name and type or string description, eg, `[:field1, :field2, :field3]` or `[:field1 => String, :field2 => Int, :field3 => Float64]` or `[:field1 => String, :field1__description => "Field 1 has the name"]`.
- `strict::Union{Nothing, Bool}`: Whether to enforce strict mode for the schema. Defaults to `nothing`.
- `max_description_length::Int`: Maximum length for descriptions. Defaults to 200.

# Returns a tuple of (schema, struct type)
- `Dict{String, Any}`: A dictionary representing the function call signature schema.
- `Type`: The struct type to create instance of the result.

See also `generate_struct`, `aiextract`, `update_schema_descriptions!`.

# Examples
```julia
schema, return_type = function_call_signature([:field1, :field2, :field3])
```

With the field types:
```julia
schema, return_type = function_call_signature([:field1 => String, :field2 => Int, :field3 => Float64])
```

And with the field descriptions:
```julia
schema, return_type = function_call_signature([:field1 => String, :field1__description => "Field 1 has the name"])
```
"""
function function_call_signature(fields::Vector;
        strict::Union{Nothing, Bool} = nothing, max_description_length::Int = 200)
    @assert all(x -> x isa Symbol || x isa Pair, fields) "Invalid return types provided. All fields must be either Symbols or Pairs of Symbol and Type or String"
    # Generate the struct and descriptions
    datastructtype, descriptions = generate_struct(fields)

    # Create the schema
    schema, _ = function_call_signature(
        datastructtype; strict, max_description_length)

    # Update the schema with descriptions
    update_schema_descriptions!(schema, descriptions; max_description_length)

    return schema, datastructtype
end

######################
# 2) Anthropic / XML format
######################

"""
Simple template to add to the System Message when doing data extraction with Anthropic models.

It has 2 placeholders: `tool_name`, `tool_description` and `tool_parameters` that are filled with the tool's name, description and parameters.
Source: https://docs.anthropic.com/claude/docs/functions-external-tools
"""
ANTHROPIC_TOOL_PROMPT = """
  In this environment you have access to a specific tool you MUST use to answer the user's question.

  You should call it like this:
  <function_calls>
  <invoke>
  <tool_name>\$TOOL_NAME</tool_name>
  <parameters>
  <\$PARAMETER_NAME>\$PARAMETER_VALUE</\$PARAMETER_NAME>
  ...
  </parameters>
  </invoke>
  </function_calls>

  Here are the tools available:
  <tools>
  {{tool_description}}
  </tools>
  """
ANTHROPIC_TOOL_PROMPT_LIST_EXTRA = """
  For any List[] types, include multiple <\$PARAMETER_NAME>\$PARAMETER_VALUE</\$PARAMETER_NAME> tags for each item in the list. XML tags should only contain the name of the parameter.
  """
######################
# Useful Structs
######################

# This is kindly borrowed from the awesome Instructor package](https://github.com/jxnl/instructor/blob/main/instructor/dsl/maybe.py).
"""
Extract a result from the provided data, if any, otherwise set the error and message fields.

# Arguments
- `error::Bool`: `true` if a result is found, `false` otherwise.
- `message::String`: Only present if no result is found, should be short and concise.
"""
struct MaybeExtract{T <: Any}
    result::Union{Nothing, T}
    error::Bool
    message::Union{Nothing, String}
end

"""
Extract zero, one or more specified items from the provided data.
"""
struct ItemsExtract{T <: Any}
    items::Vector{T}
end
