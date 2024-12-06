########################
# Extraction
########################
# These are utilities to support structured data extraction tasks through the OpenAI function calling interface (wrapped by `aiextract`)
#
# There are potential formats: 1) JSON-based for OpenAI compatible APIs, 2) XML-based for Anthropic compatible APIs (used also by Hermes-2-Pro model). 
#

#### Core Types
# Alias for backwards compatibility
function tool_call_signature end
const function_call_signature = tool_call_signature

"""
    AbstractTool

Abstract type for all tool types.

Required fields:
- `name::String`: The name of the tool.
- `parameters::Dict`: The parameters of the tool.
- `description::Union{String, Nothing}`: The description of the tool.
- `callable::Any`: The callable object of the tool, eg, a type or a function.
"""
abstract type AbstractTool end
isabstracttool(x) = x isa AbstractTool

"""
    Tool

A tool that can be sent to an LLM for execution ("function calling").

# Arguments
- `name::String`: The name of the tool.
- `parameters::Dict`: The parameters of the tool.
- `description::Union{String, Nothing}`: The description of the tool.
- `strict::Union{Bool, Nothing}`: Whether to enforce strict mode for the tool.
- `callable::Any`: The callable object of the tool, eg, a type or a function.

See also: [`AbstractTool`](@ref), [`tool_call_signature`](@ref)
"""
Base.@kwdef struct Tool <: AbstractTool
    name::String
    parameters::Dict = Dict()
    description::Union{String, Nothing} = nothing
    strict::Union{Bool, Nothing} = nothing
    callable::Any
end
Base.show(io::IO, t::AbstractTool) = dump(io, t; maxdepth = 1)

"""
    ToolRef(ref::Symbol, callable::Any)

Represents a reference to a tool with a symbolic name and a callable object (to call during tool execution).
It can be rendered with a `render` method and a prompt schema.

# Arguments
- `ref::Symbol`: The symbolic name of the tool.
- `callable::Any`: The callable object of the tool, eg, a type or a function.
- `extras::Dict{String, Any}`: Additional parameters to be included in the tool signature.

# Examples
```julia
# Define a tool with a symbolic name and a callable object
tool = ToolRef(;ref=:computer, callable=println)

# Show the rendered tool signature
PT.render(PT.AnthropicSchema(), tool)
```
"""
Base.@kwdef struct ToolRef <: AbstractTool
    ref::Symbol
    callable::Any = identity
    extras::Dict{String, Any} = Dict()
end
Base.show(io::IO, t::ToolRef) = print(io, "ToolRef($(t.ref))")

### Useful Error Types
"""
    AbstractToolError

Abstract type for all tool errors.

Available subtypes:
- [`ToolNotFoundError`](@ref)
- [`ToolExecutionError`](@ref)
- [`ToolGenericError`](@ref)
"""
abstract type AbstractToolError <: Exception end

"Error type for when a tool is not found. It should contain the tool name that was not found."
struct ToolNotFoundError <: AbstractToolError
    msg::String
end

"Error type for when a tool execution fails. It should contain the error message from the tool execution."
struct ToolExecutionError <: AbstractToolError
    msg::String
    err::Exception
end

"Error type for when a tool execution fails with a generic error. It should contain the detailed error message."
struct ToolGenericError <: AbstractToolError
    msg::String
    err::Exception
end

######################
# 1) OpenAI / JSON format
######################

"Check if a type is concrete."
function is_concrete_type(s::Type)
    isconcretetype(s) ||
        throw(ArgumentError("Cannot convert abstract type $s to JSON type. You must provide concrete types!"))
end

function is_not_union_type(s::Type)
    !isa(s, Union) ||
        throw(ArgumentError("Cannot convert $s to JSON type. The only supported union types are Union{..., Nothing}. Please pick a concrete type (`::String` is generic if you cannot pick)!"))
end

to_json_type(s::Type{<:AbstractString}) = (is_concrete_type(s); "string")
to_json_type(n::Type{<:Real}) = (is_concrete_type(n); "number")
to_json_type(n::Type{<:Integer}) = (is_concrete_type(n); "integer")
to_json_type(b::Type{Bool}) = "boolean"
to_json_type(t::Type{<:Union{Missing, Nothing}}) = "null"
to_json_type(t::Type{<:Any}) = (is_not_union_type(t); is_concrete_type(t); "string") # object?
to_json_type(t::Type{Any}) = "string" # Allow explicit Any as it can be deserialized by JSON3

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

### Experimental Support for methods/functions
function get_method(f::Function)
    @assert length(methods(f))==1 "Function must have only one method for automatic signature generation"
    return only(methods(f))
end
function get_function(m::Method)
    return getfield(parentmodule(m), m.name)
end
"Get the argument names from a method, ignores keyword arguments!!"
function get_arg_names(method::Method)
    names_ = Base.method_argnames(method)
    if length(names_) == 1
        return Symbol[]
    else
        return names_[2:end]
    end
end
"Get the argument types from a method, ignores keyword arguments!!"
function get_arg_types(method::Method)
    return [t for t in method.sig.parameters[2:end]]   # Skip first type (typeof(f))
end
"Get the argument names from a function, ignores keyword arguments!!"
get_arg_names(f::Function) = get_arg_names(get_method(f))
"Get the argument types from a function, ignores keyword arguments!!"
get_arg_types(f::Function) = get_arg_types(get_method(f))

"Extract the docstring from a type or function."
function extract_docstring(
        type::Union{Type, Function}; max_description_length::Int = 100)
    ## plain struct has supertype Any
    ## we ignore the ones that are subtypes for now (to prevent picking up Dicts, etc.)
    if (type isa Type && (supertype(type) == Any)) || (type isa Function)
        docs = Docs.doc(type) |> string
        ## Covers two known cases: "No documentation found.\n\n" and "No documentation found for private symbol."
        if !startswith(docs, "No documentation found")
            return first(docs, max_description_length)
        end
    end
    return ""
end
function extract_docstring(m::Method; max_description_length::Int = 100)
    ## Recover the method's originalfunction
    return extract_docstring(get_function(m); max_description_length)
end

@inline function is_hidden_field(field_name::AbstractString,
        hidden_fields::AbstractVector{<:Union{AbstractString, Regex}})
    any(x -> occursin(x, field_name), hidden_fields)
end
@inline function is_hidden_field(field_name::Symbol,
        hidden_fields::AbstractVector{<:Union{AbstractString, Regex}})
    is_hidden_field(string(field_name), hidden_fields)
end

function to_json_schema(orig_type; max_description_length::Int = 100,
        hidden_fields::AbstractVector{<:Union{AbstractString, Regex}} = String[])
    schema = Dict{String, Any}()
    type = remove_null_types(orig_type)
    if isstructtype(type)
        schema["type"] = "object"
        schema["properties"] = Dict{String, Any}()
        ## extract the field names and types
        required_types = String[]
        for (field_name, field_type) in zip(fieldnames(type), fieldtypes(type))
            if is_hidden_field(field_name, hidden_fields)
                continue
            end
            schema["properties"][string(field_name)] = to_json_schema(
                remove_null_types(field_type);
                max_description_length, hidden_fields)
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
function to_json_schema(type::Type{<:AbstractString}; max_description_length::Int = 100,
        hidden_fields::AbstractVector{<:Union{AbstractString, Regex}} = String[])
    Dict{String, Any}("type" => to_json_type(type))
end
function to_json_schema(type::Type{T};
        max_description_length::Int = 100,
        hidden_fields::AbstractVector{<:Union{AbstractString, Regex}} = String[]) where {T <:
                                                                                         Union{
        AbstractSet, Tuple, AbstractArray}}
    element_type = eltype(type)
    return Dict{String, Any}("type" => "array",
        "items" => to_json_schema(remove_null_types(element_type);
            max_description_length, hidden_fields))
end
function to_json_schema(type::Type{<:Enum}; max_description_length::Int = 100,
        hidden_fields::AbstractVector{<:Union{AbstractString, Regex}} = String[])
    enum_options = Base.Enums.namemap(type) |> values .|> string
    return Dict{String, Any}("type" => "string",
        "enum" => enum_options)
end
## Dispatch for method of a function -- grabs only arguments!! Not kwargs!!
function to_json_schema(m::Method; max_description_length::Int = 100,
        hidden_fields::AbstractVector{<:Union{AbstractString, Regex}} = String[])
    ## Warning: We cannot extract keyword arguments from the method signature
    kwargs = Base.kwarg_decl(m)
    !isempty(kwargs) &&
        @warn "Detected keyword arguments in $(m.name): $("\"".*join(kwargs, ", ").*"\""). They are not supported in tool encoding and will be ignored."

    schema = Dict{String, Any}()
    schema["type"] = "object"
    schema["properties"] = Dict{String, Any}()
    ## extract the field names and types
    required_types = String[]
    for (field_name, field_type) in zip(get_arg_names(m), get_arg_types(m))
        if is_hidden_field(field_name, hidden_fields)
            continue
        end
        schema["properties"][string(field_name)] = to_json_schema(
            remove_null_types(field_type);
            max_description_length, hidden_fields)
        ## Hack: no null type (Nothing, Missing) implies it it is a required field
        is_required_field(field_type) && push!(required_types, string(field_name))
    end
    !isempty(required_types) && (schema["required"] = required_types)
    ## docstrings
    docs = extract_docstring(m; max_description_length)
    !isempty(docs) && (schema["description"] = docs)
    return schema
end
function to_json_schema(type::Type{<:AbstractDict}; max_description_length::Int = 100,
        hidden_fields::AbstractVector{<:Union{AbstractString, Regex}} = String[])
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
    update_field_descriptions!(
        parameters::Dict{String, <:Any}, descriptions::Dict{Symbol, <:AbstractString};
        max_description_length::Int = 200)

Update the given JSON schema with descriptions from the `descriptions` dictionary.
This function modifies the schema in-place, adding a "description" field to each property
that has a corresponding entry in the `descriptions` dictionary.

Note: It modifies the schema in place. Only the top-level "properties" are updated!

Returns: The modified schema dictionary.

# Arguments
- `parameters`: A dictionary representing the JSON schema to be updated.
- `descriptions`: A dictionary mapping field names (as symbols) to their descriptions.
- `max_description_length::Int`: Maximum length for descriptions. Defaults to 200.

# Examples
```julia
    parameters = Dict{String, Any}(
        "properties" => Dict{String, Any}(
            "location" => Dict{String, Any}("type" => "string"),
            "condition" => Dict{String, Any}("type" => "string"),
            "temperature" => Dict{String, Any}("type" => "number")
        ),
        "required" => ["location", "temperature", "condition"],
        "type" => "object"
    )
    descriptions = Dict{Symbol, String}(
        :temperature => "Temperature in degrees Fahrenheit",
        :condition => "Current weather condition (e.g., sunny, rainy, cloudy)"
    )
    update_field_descriptions!(parameters, descriptions)
```
"""
function update_field_descriptions!(
        parameters::Dict{String, <:Any}, descriptions::Dict{Symbol, <:AbstractString};
        max_description_length::Int = 200)
    properties = get(parameters, "properties", Dict())

    for (field, field_schema) in properties
        field_sym = Symbol(field)
        if haskey(descriptions, field_sym)
            field_schema["description"] = first(
                descriptions[field_sym], max_description_length)
        end
    end

    return parameters
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
    remove_field!(parameters::AbstractDict, field::AbstractString)

Utility to remove a specific top-level field from the parameters (and the `required` list if present) of the JSON schema.
"""
function remove_field!(parameters::AbstractDict, field::AbstractString)
    if haskey(parameters, "properties") && haskey(parameters["properties"], field)
        delete!(parameters["properties"], field)
    end
    if haskey(parameters, "required") && field in parameters["required"]
        filter!(x -> x != field, parameters["required"])
    end
    return parameters
end

function remove_field!(parameters::AbstractDict, pattern::Regex)
    if haskey(parameters, "properties")
        for (key, value) in parameters["properties"]
            if occursin(pattern, key)
                delete!(parameters["properties"], key)
            end
        end
    end
    if haskey(parameters, "required")
        filter!(x -> !occursin(pattern, x), parameters["required"])
    end
    return parameters
end

"""
    tool_call_signature(
        type_or_method::Union{Type, Method}; strict::Union{Nothing, Bool} = nothing,
        max_description_length::Int = 200, name::Union{Nothing, String} = nothing,
        docs::Union{Nothing, String} = nothing, hidden_fields::AbstractVector{<:Union{
            AbstractString, Regex}} = String[])

Extract the argument names, types and docstrings from a struct to create the function call signature in JSON schema.

You must provide a Struct type (not an instance of it) with some fields.
The types must be CONCRETE, it helps with correct conversion to JSON schema and then conversion back to the struct.

Note: Fairly experimental, but works for combination of structs, arrays, strings and singletons.

# Arguments
- `type_or_method::Union{Type, Method}`: The struct type or method to extract the signature from.
- `strict::Union{Nothing, Bool}`: Whether to enforce strict mode for the schema. Defaults to `nothing`.
- `max_description_length::Int`: Maximum length for descriptions. Defaults to 200.
- `name::Union{Nothing, String}`: The name of the tool. Defaults to the name of the struct.
- `docs::Union{Nothing, String}`: The description of the tool. Defaults to the docstring of the struct/overall function.
- `hidden_fields::AbstractVector{<:Union{AbstractString, Regex}}`: A list of fields to hide from the LLM (eg, `["ctx_user_id"]` or `r"ctx"`).

# Returns
- `Dict{String, AbstractTool}`: A dictionary representing the function call signature schema.

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
tool_map = tool_call_signature(MyMeasurement)
#
# Dict{String, PromptingTools.AbstractTool}("MyMeasurement" => PromptingTools.Tool
#   name: String "MyMeasurement"
#   parameters: Dict{String, Any}
#   description: Nothing nothing
#   strict: Nothing nothing
#   callable: MyMeasurement <: Any
"
```

You can see that only the field `age` does not allow null values, hence, it's "required".
While `height` and `weight` are optional.
```
tool_map["MyMeasurement"].parameters["required"]
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

You can also hide certain fields in your function call signature with Strings or Regex patterns (eg, `r"ctx"`).

```
tool_map = tool_call_signature(MyMeasurement; hidden_fields = ["ctx_user_id"])
```
"""
function tool_call_signature(
        type_or_method::Union{Type, Method}; strict::Union{Nothing, Bool} = nothing,
        max_description_length::Int = 200, name::Union{Nothing, String} = nothing,
        docs::Union{Nothing, String} = nothing, hidden_fields::AbstractVector{<:Union{
            AbstractString, Regex}} = String[])
    ## Asserts
    if type_or_method isa Type && !isstructtype(type_or_method)
        error("Only Structs are supported (provided type: $type_or_method)")
    end
    ## Standardize the name
    name = if isnothing(name) && type_or_method isa Type
        replace(string(nameof(type_or_method)), "PromptingTools." => "") |>
        x -> replace(x, r"[^0-9A-Za-z_-]" => "") |> x -> first(x, 64)
    elseif isnothing(name) && type_or_method isa Method
        string(type_or_method.name)
    else
        name
    end
    schema = Dict{String, Any}("name" => name,
        "parameters" => to_json_schema(type_or_method; max_description_length,
            hidden_fields))
    ## docstrings
    docs = isnothing(docs) ? extract_docstring(type_or_method; max_description_length) :
           docs
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
    call_type = type_or_method isa Type ? type_or_method : get_function(type_or_method)
    ## Remove hidden fields
    if !isempty(hidden_fields)
        for field in hidden_fields
            remove_field!(schema["parameters"], field)
        end
    end
    tool = Tool(; name = schema["name"], parameters = schema["parameters"],
        description = haskey(schema, "description") ? schema["description"] : nothing,
        strict = haskey(schema, "strict") ? schema["strict"] : nothing,
        callable = call_type)
    return Dict{String, AbstractTool}(schema["name"] => tool)
end

## Only thing you can change is the "strict" setting
function tool_call_signature(
        tool::AbstractTool; strict::Union{Nothing, Bool} = nothing, kwargs...)
    if tool.strict != strict
        tool = Tool(;
            [k => getfield(tool, k) for k in fieldnames(Tool) if k != :strict]...,
            strict = strict)
        if strict == true
            if haskey(tool.parameters, "properties")
                set_properties_strict!(tool.parameters)
            end
        end
    end
    return Dict(tool.name => tool)
end
function tool_call_signature(
        tool::ToolRef; kwargs...)
    return Dict{String, AbstractTool}(string(tool.ref) => tool)
end

## Add support for function signatures
function tool_call_signature(f::Function; kwargs...)
    return tool_call_signature(get_method(f); kwargs...)
end

function tool_call_signature(
        tools::Vector{<:T}; kwargs...) where {T <:
                                              Union{Type, Function, Method, AbstractTool}}
    tool_map = Dict{String, AbstractTool}()
    for tool in tools
        temp_map = tool_call_signature(tool; kwargs...)
        for (name, tool) in temp_map
            @assert !haskey(tool_map, name) "Duplicate tool name: $name. Please provide unique names for each tool."
            tool_map[name] = tool
        end
    end
    return tool_map
end

"""
    tool_call_signature(fields::Vector;
        strict::Union{Nothing, Bool} = nothing, max_description_length::Int = 200, name::Union{
            Nothing, String} = nothing,
        docs::Union{Nothing, String} = nothing)

Generate a function call signature schema for a dynamically generated struct based on the provided fields.

# Arguments
- `fields::Vector{Union{Symbol, Pair{Symbol, Type}, Pair{Symbol, String}}}`: A vector of field names or pairs of field name and type or string description, eg, `[:field1, :field2, :field3]` or `[:field1 => String, :field2 => Int, :field3 => Float64]` or `[:field1 => String, :field1__description => "Field 1 has the name"]`.
- `strict::Union{Nothing, Bool}`: Whether to enforce strict mode for the schema. Defaults to `nothing`.
- `max_description_length::Int`: Maximum length for descriptions. Defaults to 200.
- `name::Union{Nothing, String}`: The name of the tool. Defaults to the name of the struct.
- `docs::Union{Nothing, String}`: The description of the tool. Defaults to the docstring of the struct/overall function.

# Returns a `tool_map` with the tool name as the key and the tool object as the value.

See also `generate_struct`, `aiextract`, `update_field_descriptions!`.

# Examples
```julia
tool_map = tool_call_signature([:field1, :field2, :field3])
```

With the field types:
```julia
tool_map = tool_call_signature([:field1 => String, :field2 => Int, :field3 => Float64])
```

And with the field descriptions:
```julia
tool_map = tool_call_signature([:field1 => String, :field1__description => "Field 1 has the name"])
```
"""
function tool_call_signature(fields::Vector;
        strict::Union{Nothing, Bool} = nothing, max_description_length::Int = 200, name::Union{
            Nothing, String} = nothing,
        docs::Union{Nothing, String} = nothing)
    @assert all(x -> x isa Symbol || x isa Pair, fields) "Invalid return types provided. All fields must be either Symbols or Pairs of Symbol and Type or String"
    # Generate the struct and descriptions
    datastructtype, descriptions = generate_struct(fields)

    # Create the schema
    tool_map = tool_call_signature(
        datastructtype; strict, max_description_length, name, docs)
    name, tool = only(tool_map)
    # Update the schema with descriptions
    update_field_descriptions!(tool.parameters, descriptions; max_description_length)
    tool_map[name] = Tool(;
        [k => getfield(tool, k) for k in fieldnames(Tool) if k != :callable]...,
        callable = datastructtype)
    return tool_map
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

### Processing utilities

"""
    parse_tool(datatype::Type, blob::AbstractString; kwargs...)

Parse the JSON blob into the specified datatype in try-catch mode.

If parsing fails, it tries to return the untyped JSON blob in a dictionary.
"""
function parse_tool(datatype::Type, blob::AbstractString; kwargs...)
    try
        return if blob == "{}"
            ## If empty, return empty datatype
            ## a shortcut for function calls without defining the JSON3 StructType
            datatype()
        else
            Base.invokelatest(JSON3.read, blob, datatype)::datatype
        end
    catch e
        @warn "There was an error parsing the response: $e. Using the raw response instead."
        return JSON3.read(blob) |> copy
    end
end

## Utility for Anthropic - it returns a parsed dict and we need text for deserialization into an object
function parse_tool(datatype::Type, blob::AbstractDict; kwargs...)
    isempty(blob) ? datatype() : parse_tool(datatype, JSON3.write(blob); kwargs...)
end
function parse_tool(
        tool::AbstractTool, input::Union{AbstractString, AbstractDict}; kwargs...)
    return parse_tool(tool.callable, input; kwargs...)
end

"""
    execute_tool(f::Function, args::AbstractDict{Symbol, <:Any},
        context::AbstractDict{Symbol, <:Any} = Dict{Symbol, Any}();
        throw_on_error::Bool = true, unused_as_kwargs::Bool = false,
        kwargs...)

Executes a function with the provided arguments. 

Picks the function arguments in the following order:
- `:context` refers to the context dictionary passed to the function.
- Then it looks for the arguments in the `context` dictionary.
- Then it looks for the arguments in the `args` dictionary.

Dictionary is un-ordered, so we need to sort the arguments first and then pass them to the function.

# Arguments
- `f::Function`: The function to execute.
- `args::AbstractDict{Symbol, <:Any}`: The arguments to pass to the function.
- `context::AbstractDict{Symbol, <:Any}`: Optional context to pass to the function, it will prioritized to get the argument values from.
- `throw_on_error::Bool`: Whether to throw an error if the tool execution fails. Defaults to `true`.
- `unused_as_kwargs::Bool`: Whether to pass unused arguments as keyword arguments. Defaults to `false`. Function must support keyword arguments!
- `kwargs...`: Additional keyword arguments to pass to the function.

# Example
```julia
my_function(x, y) = x + y
execute_tool(my_function, Dict(:x => 1, :y => 2))
```

```julia
get_weather(date, location) = "The weather in \$location on \$date is 70 degrees."
tool_map = PT.tool_call_signature(get_weather)

msg = aitools("What's the weather in Tokyo on May 3rd, 2023?";
    tools = collect(values(tool_map)))

PT.execute_tool(tool_map, PT.tool_calls(msg)[1])
# "The weather in Tokyo on 2023-05-03 is 70 degrees."
```
"""
function execute_tool(f::Function, args::AbstractDict{Symbol, <:Any},
        context::AbstractDict{Symbol, <:Any} = Dict{Symbol, Any}();
        throw_on_error::Bool = true, unused_as_kwargs::Bool = false,
        kwargs...)
    args_sorted = []
    arg_names = get_arg_names(f)
    for arg in arg_names
        if arg == :context
            push!(args_sorted, context)
        elseif haskey(context, arg)
            push!(args_sorted, context[arg])
        elseif haskey(args, arg)
            push!(args_sorted, args[arg])
        end
    end
    if unused_as_kwargs
        unused_args = setdiff(keys(args), arg_names)
        kwargs = merge(NamedTuple(kwargs), (; [arg => args[arg] for arg in unused_args]...))
    end

    result = try
        f(args_sorted...; kwargs...)
    catch e
        ToolExecutionError("Tool execution of `$(f)` failed", e)
    end
    throw_on_error && result isa AbstractToolError && throw(result)
    return result
end
function execute_tool(tool::AbstractTool, args::AbstractDict{Symbol, <:Any},
        context::AbstractDict{Symbol, <:Any} = Dict{Symbol, Any}(); kwargs...)
    return execute_tool(tool.callable, args, context; kwargs...)
end
function execute_tool(tool::AbstractTool, msg::ToolMessage,
        context::AbstractDict{Symbol, <:Any} = Dict{Symbol, Any}(); kwargs...)
    return execute_tool(tool.callable, msg.args, context; kwargs...)
end
function execute_tool(tool_map::AbstractDict{String, <:AbstractTool}, msg::ToolMessage,
        context::AbstractDict{Symbol, <:Any} = Dict{Symbol, Any}(); kwargs...)
    if !haskey(tool_map, msg.name)
        throw(ToolNotFoundError("Tool `$(msg.name)` not found"))
    end
    tool = tool_map[msg.name]
    return execute_tool(tool, msg, context; kwargs...)
end

"""
    Tool(callable::Union{Function, Type, Method}; kwargs...)

Create a `Tool` from a callable object (function, type, or method).

# Arguments
- `callable::Union{Function, Type, Method}`: The callable object to convert to a tool.

# Returns
- `Tool`: A tool object that can be used for function calling.

# Examples
```julia
# Create a tool from a function
tool = Tool(my_function)

# Create a tool from a type
tool = Tool(MyStruct)
```
"""
function Tool(callable::Union{Function, Type, Method}; kwargs...)
    tool_map = tool_call_signature(callable; kwargs...)
    name, tool = only(tool_map)
    return tool
end
