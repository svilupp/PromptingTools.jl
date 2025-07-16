# This file contains the templating system which translates a symbol (=template name) into a set of messages under the specified schema.
# Templates are stored as JSON files in the `templates` folder.
# Once loaded, they are stored in global variable `TEMPLATE_STORE`
#
# Flow: template -> messages |+ kwargs variables -> "conversation" to pass to the model

## Types
"""
    AITemplate

AITemplate is a template for a conversation prompt. 
 This type is merely a container for the template name, which is resolved into a set of messages (=prompt) by `render`.

# Naming Convention
- Template names should be in CamelCase
- Follow the format `<Persona>...<Variable>...` where possible, eg, `JudgeIsItTrue`, ``
    - Starting with the Persona (=System prompt), eg, `Judge` = persona is meant to `judge` some provided information
    - Variable to be filled in with context, eg, `It` = placeholder `it`
    - Ending with the variable name is helpful, eg, `JuliaExpertTask` for a persona to be an expert in Julia language and `task` is the placeholder name
- Ideally, the template name should be self-explanatory, eg, `JudgeIsItTrue` = persona is meant to `judge` some provided information where it is true or false

# Examples

Save time by re-using pre-made templates, just fill in the placeholders with the keyword arguments:
```julia
msg = aigenerate(:JuliaExpertAsk; ask = "How do I add packages?")
```

The above is equivalent to a more verbose version that explicitly uses the dispatch on `AITemplate`:
```julia
msg = aigenerate(AITemplate(:JuliaExpertAsk); ask = "How do I add packages?")
```

Find available templates with `aitemplates`:
```julia
tmps = aitemplates("JuliaExpertAsk")
# Will surface one specific template
# 1-element Vector{AITemplateMetadata}:
# PromptingTools.AITemplateMetadata
#   name: Symbol JuliaExpertAsk
#   description: String "For asking questions about Julia language. Placeholders: `ask`"
#   version: String "1"
#   wordcount: Int64 237
#   variables: Array{Symbol}((1,))
#   system_preview: String "You are a world-class Julia language programmer with the knowledge of the latest syntax. Your commun"
#   user_preview: String "# Question\n\n{{ask}}"
#   source: String ""
```
The above gives you a good idea of what the template is about, what placeholders are available, and how much it would cost to use it (=wordcount).

Search for all Julia-related templates:
```julia
tmps = aitemplates("Julia")
# 2-element Vector{AITemplateMetadata}... -> more to come later!
```

If you are on VSCode, you can leverage nice tabular display with `vscodedisplay`:
```julia
using DataFrames
tmps = aitemplates("Julia") |> DataFrame |> vscodedisplay
```

I have my selected template, how do I use it? Just use the "name" in `aigenerate` or `aiclassify` 
 like you see in the first example!

You can inspect any template by "rendering" it (this is what the LLM will see):
```julia
julia> AITemplate(:JudgeIsItTrue) |> PromptingTools.render
```

See also: `save_template`, `load_template`, `load_templates!` for more advanced use cases (and the corresponding script in `examples/` folder)
"""
struct AITemplate
    name::Symbol
end

"Helper for easy searching and reviewing of templates. Defined on loading of each template."
Base.@kwdef struct AITemplateMetadata
    name::Symbol
    description::String = ""
    version::String = "-"
    wordcount::Int
    variables::Vector{Symbol} = Symbol[]
    system_preview::String = ""
    user_preview::String = ""
    source::String = ""
end
function Base.show(io::IO, ::MIME"text/plain", t::AITemplateMetadata)
    # just dumping seems to give ok output
    dump(IOContext(io, :limit => true), t, maxdepth = 1)
end
# overload also the vector printing for nicer search results with `aitemplates`
function Base.show(io::IO, m::MIME"text/plain", v::Vector{<:AITemplateMetadata})
    printstyled(io, "$(length(v))-element Vector{AITemplateMetadata}:"; color = :light_blue)
    println(io)
    [(show(io, m, v[i]); println(io))
     for i in eachindex(v)]
    nothing
end

## Rendering messages from templates
function render(schema::AbstractPromptSchema, template::AITemplate; kwargs...)
    global TEMPLATE_STORE
    haskey(TEMPLATE_STORE, template.name) ||
        error("Template $(template.name) not found in TEMPLATE_STORE")
    # get template
    return TEMPLATE_STORE[template.name] |> copy
end

# dispatch on default schema
"Renders provided messaging template (`template`) under the default schema (`PROMPT_SCHEMA`)."
function render(template::AITemplate; kwargs...)
    global PROMPT_SCHEMA
    render(PROMPT_SCHEMA, template; kwargs...)
end
# Since we don't distinguish between schema, support schema=nothing as well
function render(schema::Nothing, template::AITemplate; kwargs...)
    global PROMPT_SCHEMA
    render(PROMPT_SCHEMA, template; kwargs...)
end

## Loading/saving -- see src/serialization.jl
"""
    build_template_metadata(
        template::AbstractVector{<:AbstractMessage}, template_name::Symbol,
        metadata_msgs::AbstractVector{<:MetadataMessage} = MetadataMessage[]; max_length::Int = 100)

Builds `AITemplateMetadata` for a given template based on the messages in `template` and other information.

`AITemplateMetadata` is a helper struct for easy searching and reviewing of templates via `aitemplates()`.

Note: Assumes that there is only ever one UserMessage and SystemMessage (concatenates them together)
"""
function build_template_metadata(
        template::AbstractVector{<:AbstractMessage}, template_name::Symbol,
        metadata_msgs::AbstractVector{<:MetadataMessage} = MetadataMessage[]; max_length::Int = 100)

    # prepare the metadata
    wordcount = 0
    system_preview = ""
    user_preview = ""
    variables = Symbol[]
    for i in eachindex(template)
        msg = template[i]
        wordcount += length(msg.content)
        if hasproperty(msg, :variables)
            append!(variables, msg.variables)
        end
        # truncate previews to 100 characters
        if msg isa SystemMessage && length(system_preview) < max_length
            system_preview *= first(msg.content, max_length)
        elseif msg isa UserMessage && length(user_preview) < max_length
            user_preview *= first(msg.content, max_length)
        end
    end
    if !isempty(metadata_msgs)
        # use the first metadata message found if available
        meta = first(metadata_msgs)
        metadata = AITemplateMetadata(; name = template_name,
            meta.description, meta.version, meta.source,
            wordcount,
            system_preview = first(system_preview, max_length),
            user_preview = first(user_preview, max_length),
            variables = unique(variables))
    else
        metadata = AITemplateMetadata(; name = template_name,
            wordcount,
            system_preview = first(system_preview, max_length),
            user_preview = first(user_preview, max_length),
            variables = unique(variables))
    end

    return metadata
end
"""
        remove_templates!()

Removes all templates from `TEMPLATE_STORE` and `TEMPLATE_METADATA`.
"""
function remove_templates!(; store = TEMPLATE_STORE, metadata_store = TEMPLATE_METADATA)
    (empty!(store); empty!(metadata_store); nothing)
end

"""
    load_templates!(dir_templates::Union{String, Nothing} = nothing;
        remember_path::Bool = true,
        remove_templates::Bool = isnothing(dir_templates),
        store::Dict{Symbol, <:Any} = TEMPLATE_STORE,
        metadata_store::Vector{<:AITemplateMetadata} = TEMPLATE_METADATA)

Loads templates from folder `templates/` in the package root and stores them in `TEMPLATE_STORE` and `TEMPLATE_METADATA`.

Note: Automatically removes any existing templates and metadata from `TEMPLATE_STORE` and `TEMPLATE_METADATA` if `remove_templates=true`.

# Arguments
- `dir_templates::Union{String, Nothing}`: The directory path to load templates from. If `nothing`, uses the default list of paths. It usually used only once "to register" a new template storage.
- `remember_path::Bool=true`: If true, remembers the path for future refresh (in `TEMPLATE_PATH`).
- `remove_templates::Bool=isnothing(dir_templates)`: If true, removes any existing templates and metadata from `store` and `metadata_store`.
- `store::Dict{Symbol, <:Any}=TEMPLATE_STORE`: The store to load the templates into.
- `metadata_store::Vector{<:AITemplateMetadata}=TEMPLATE_METADATA`: The metadata store to load the metadata into.

# Example

Load the default templates:
```julia
PT.load_templates!() # no path needed
```

Load templates from a new custom path:
```julia
PT.load_templates!("path/to/templates") # we will remember this path for future refresh
```

If you want to now refresh the default templates and the new path, just call `load_templates!()` without any arguments.
"""
function load_templates!(dir_templates::Union{String, Nothing} = nothing;
        remember_path::Bool = true,
        remove_templates::Bool = isnothing(dir_templates),
        store::Dict{Symbol, <:Any} = TEMPLATE_STORE,
        metadata_store::Vector{<:AITemplateMetadata} = TEMPLATE_METADATA)
    ## Init
    global TEMPLATE_PATH
    @assert isnothing(dir_templates)||isdir(dir_templates) "Invalid directory path provided! ($dir_templates)"

    # If no path is provided, use the default list
    load_paths = isnothing(dir_templates) ? TEMPLATE_PATH : [dir_templates]
    # first remove any old templates and their metadata
    remove_templates && remove_templates!(; store, metadata_store)
    # remember the path for future refresh
    if remember_path && !isnothing(dir_templates)
        if !(dir_templates in TEMPLATE_PATH)
            push!(TEMPLATE_PATH, dir_templates)
        end
    end

    # recursively load all templates from the `load_paths`
    for template_path in load_paths
        for (root, dirs, files) in walkdir(template_path)
            for file in files
                if endswith(file, ".json") && !startswith(file, ".")
                    template_name = Symbol(split(basename(file), ".")[begin])
                    template, metadata_msgs = load_template(joinpath(root, file))
                    # add to store
                    if haskey(store, template_name)
                        @warn("Template $(template_name) already exists, overwriting! Metadata will be duplicated.")
                    end
                    store[template_name] = template

                    # add metadata to store
                    metadata = build_template_metadata(
                        template, template_name, metadata_msgs)
                    push!(metadata_store, metadata)
                end
            end
        end
    end
    return nothing
end

## Searching for templates
"""
    aitemplates

Find easily the most suitable templates for your use case.

You can search by:
- `query::Symbol` which looks look only for partial matches in the template `name`
- `query::AbstractString` which looks for partial matches in the template `name` or `description`
- `query::Regex` which looks for matches in the template `name`, `description` or any of the message previews

# Keyword Arguments
- `limit::Int` limits the number of returned templates (Defaults to 10)

# Examples

Find available templates with `aitemplates`:
```julia
tmps = aitemplates("JuliaExpertAsk")
# Will surface one specific template
# 1-element Vector{AITemplateMetadata}:
# PromptingTools.AITemplateMetadata
#   name: Symbol JuliaExpertAsk
#   description: String "For asking questions about Julia language. Placeholders: `ask`"
#   version: String "1"
#   wordcount: Int64 237
#   variables: Array{Symbol}((1,))
#   system_preview: String "You are a world-class Julia language programmer with the knowledge of the latest syntax. Your commun"
#   user_preview: String "# Question\n\n{{ask}}"
#   source: String ""
```
The above gives you a good idea of what the template is about, what placeholders are available, and how much it would cost to use it (=wordcount).

Search for all Julia-related templates:
```julia
tmps = aitemplates("Julia")
# 2-element Vector{AITemplateMetadata}... -> more to come later!
```

If you are on VSCode, you can leverage nice tabular display with `vscodedisplay`:
```julia
using DataFrames
tmps = aitemplates("Julia") |> DataFrame |> vscodedisplay
```

I have my selected template, how do I use it? Just use the "name" in `aigenerate` or `aiclassify` 
 like you see in the first example!
"""
function aitemplates end

"Find the top-`limit` templates whose `name::Symbol` exactly matches the `query_name::Symbol` in `TEMPLATE_METADATA`."
function aitemplates(query_name::Symbol;
        limit::Int = 10,
        metadata_store::Vector{AITemplateMetadata} = TEMPLATE_METADATA)
    found_templates = filter(x -> query_name == x.name, metadata_store)
    return first(found_templates, limit)
end
"Find the top-`limit` templates whose `name` or `description` fields partially match the `query_key::String` in `TEMPLATE_METADATA`."
function aitemplates(query_key::AbstractString;
        limit::Int = 10,
        metadata_store::Vector{AITemplateMetadata} = TEMPLATE_METADATA)
    query_str = lowercase(query_key)
    found_templates = filter(
        x -> occursin(query_str, lowercase(string(x.name))) ||
             occursin(query_str, lowercase(string(x.description))),
        metadata_store)
    return first(found_templates, limit)
end
"Find the top-`limit` templates where provided `query_key::Regex` matches either of `name`, `description` or previews or User or System messages in `TEMPLATE_METADATA`."
function aitemplates(query_key::Regex;
        limit::Int = 10,
        metadata_store::Vector{AITemplateMetadata} = TEMPLATE_METADATA)
    found_templates = filter(
        x -> occursin(query_key,
                 string(x.name)) ||
             occursin(query_key,
                 x.description) ||
             occursin(query_key,
                 x.system_preview) ||
             occursin(query_key, x.user_preview),
        metadata_store)
    return first(found_templates, limit)
end

## Dispatch for AI templates (unpacks the messages)
function aigenerate(schema::AbstractPromptSchema, template::AITemplate; kwargs...)
    aigenerate(schema, render(schema, template); kwargs...)
end
function aiclassify(schema::AbstractPromptSchema, template::AITemplate; kwargs...)
    aiclassify(schema, render(schema, template); kwargs...)
end
function aiextract(schema::AbstractPromptSchema, template::AITemplate; kwargs...)
    aiextract(schema, render(schema, template); kwargs...)
end
function aitools(schema::AbstractPromptSchema, template::AITemplate; kwargs...)
    aitools(schema, render(schema, template); kwargs...)
end
function aiscan(schema::AbstractPromptSchema, template::AITemplate; kwargs...)
    aiscan(schema, render(schema, template); kwargs...)
end
function aiimage(schema::AbstractPromptSchema, template::AITemplate; kwargs...)
    aiimage(schema, render(schema, template); kwargs...)
end

# Shortcut for symbols
function aigenerate(schema::AbstractPromptSchema, template::Symbol; kwargs...)
    aigenerate(schema, AITemplate(template); kwargs...)
end
function aiclassify(schema::AbstractPromptSchema, template::Symbol; kwargs...)
    aiclassify(schema, AITemplate(template); kwargs...)
end
function aiextract(schema::AbstractPromptSchema, template::Symbol; kwargs...)
    aiextract(schema, AITemplate(template); kwargs...)
end
function aitools(schema::AbstractPromptSchema, template::Symbol; kwargs...)
    aitools(schema, AITemplate(template); kwargs...)
end
function aiscan(schema::AbstractPromptSchema, template::Symbol; kwargs...)
    aiscan(schema, AITemplate(template); kwargs...)
end
function aiimage(schema::AbstractPromptSchema, template::Symbol; kwargs...)
    aiimage(schema, AITemplate(template); kwargs...)
end

## Dispatch for TracerSchema to avoid ambiguities
function render(schema::AbstractTracerSchema, template::AITemplate; kwargs...)
    render(schema.schema, template; kwargs...)
end
function aigenerate(schema::AbstractTracerSchema, template::Symbol; kwargs...)
    tpl = AITemplate(template)
    aigenerate(schema, render(schema, tpl);
        _tracer_template = tpl, kwargs...)
end
function aiclassify(schema::AbstractTracerSchema, template::Symbol; kwargs...)
    tpl = AITemplate(template)
    aiclassify(schema, render(schema, tpl);
        _tracer_template = tpl, kwargs...)
end
function aiextract(schema::AbstractTracerSchema, template::Symbol; kwargs...)
    tpl = AITemplate(template)
    aiextract(schema, render(schema, tpl);
        _tracer_template = tpl, kwargs...)
end
function aitools(schema::AbstractTracerSchema, template::Symbol; kwargs...)
    tpl = AITemplate(template)
    aitools(schema, render(schema, tpl);
        _tracer_template = tpl, kwargs...)
end
function aiscan(schema::AbstractTracerSchema, template::Symbol; kwargs...)
    tpl = AITemplate(template)
    aiscan(schema, render(schema, tpl);
        _tracer_template = tpl, kwargs...)
end
function aiimage(schema::AbstractTracerSchema, template::Symbol; kwargs...)
    tpl = AITemplate(template)
    aiimage(schema, render(schema, tpl);
        _tracer_template = tpl, kwargs...)
end

## Utility for creating templates
"""
    create_template(; user::AbstractString, system::AbstractString="Act as a helpful AI assistant.", 
        load_as::Union{Nothing, Symbol, AbstractString} = nothing)

    create_template(system::AbstractString, user::AbstractString, 
        load_as::Union{Nothing, Symbol, AbstractString} = nothing)

Creates a simple template with a user and system message. Convenience function to prevent writing `[PT.UserMessage(...), ...]`

# Arguments
- `system::AbstractString`: The system message. Usually defines the personality, style, instructions, output format, etc.
- `user::AbstractString`: The user message. Usually defines the input, query, request, etc.
- `load_as::Union{Nothing, Symbol, AbstractString}`: If provided, loads the template into the `TEMPLATE_STORE` under the provided name `load_as`. If `nothing`, does not load the template.

Use double handlebar placeholders (eg, `{{name}}`) to define variables that can be replaced by the `kwargs` during the AI call (see example).

Returns a vector of `SystemMessage` and UserMessage objects.
If `load_as` is provided, it registers the template in the `TEMPLATE_STORE` and `TEMPLATE_METADATA` as well.

# Examples

Let's generate a quick template for a simple conversation (only one placeholder: name)

```julia
# first system message, then user message (or use kwargs)
tpl=PT.create_template("You must speak like a pirate", "Say hi to {{name}}")

## 2-element Vector{PromptingTools.AbstractChatMessage}:
## PromptingTools.SystemMessage("You must speak like a pirate")
##  PromptingTools.UserMessage("Say hi to {{name}}")
```

You can immediately use this template in `ai*` functions:
```julia
aigenerate(tpl; name="Jack Sparrow")
# Output: AIMessage("Arr, me hearty! Best be sending me regards to Captain Jack Sparrow on the salty seas! May his compass always point true to the nearest treasure trove. Yarrr!")
```

If you're interested in saving the template in the template registry, jump to the end of these examples!

If you want to save it in your project folder:
```julia
PT.save_template("templates/GreatingPirate.json", tpl; version="1.0") # optionally, add description
```
It will be saved and accessed under its basename, ie, `GreatingPirate`.

Now you can load it like all the other templates (provide the template directory):

```julia
PT.load_templates!("templates") # it will remember the folder after the first run
# Note: If you save it again, overwrite it, etc., you need to explicitly reload all templates again!
```

You can verify that your template is loaded with a quick search for "pirate":
```julia
aitemplates("pirate")

## 1-element Vector{AITemplateMetadata}:
## PromptingTools.AITemplateMetadata
##   name: Symbol GreatingPirate
##   description: String ""
##   version: String "1.0"
##   wordcount: Int64 46
##   variables: Array{Symbol}((1,))
##   system_preview: String "You must speak like a pirate"
##   user_preview: String "Say hi to {{name}}"
##   source: String ""
```

Now you can use it like any other template (notice it's a symbol, so `:GreatingPirate`):
```julia
aigenerate(:GreatingPirate; name="Jack Sparrow")
# Output: AIMessage("Arr, me hearty! Best be sending me regards to Captain Jack Sparrow on the salty seas! May his compass always point true to the nearest treasure trove. Yarrr!")
```

If you do not need to save this template as a file, but you want to make it accessible in the template store for all `ai*` functions, you can use the `load_as` (= template name) keyword argument:

```julia
# this will not only create the template, but also register it for immediate use
tpl=PT.create_template("You must speak like a pirate", "Say hi to {{name}}"; load_as="GreatingPirate")

# you can now use it like any other template
aiextract(:GreatingPirate; name="Jack Sparrow")
```
"""
function create_template(
        system::AbstractString,
        user::AbstractString; load_as::Union{Nothing, Symbol, AbstractString} = nothing)
    ##
    global TEMPLATE_STORE, TEMPLATE_METADATA
    ##
    template = [SystemMessage(system), UserMessage(user)]
    ## Should it be loaded as well?
    if !isnothing(load_as)
        template_name = Symbol(load_as)
        ## add to store
        if haskey(TEMPLATE_STORE, template_name)
            @warn("Template $(template_name) already exists, overwriting!")
            ## remove from metadata to avoid duplicates
            filter!(x -> x.name != template_name, TEMPLATE_METADATA)
        end
        TEMPLATE_STORE[template_name] = template
        ## prepare the metadata
        metadata = build_template_metadata(
            template, template_name)
        push!(TEMPLATE_METADATA, metadata)
    end

    return template
end
# Kwarg version
function create_template(;
        user::AbstractString, system::AbstractString = "Act as a helpful AI assistant.",
        load_as::Union{Nothing, Symbol, AbstractString} = nothing)
    create_template(system, user; load_as)
end
