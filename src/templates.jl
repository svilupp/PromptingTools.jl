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
    [(show(io, m, v[i]); println(io)) for i in eachindex(v)]
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
        remove_templates!()

Removes all templates from `TEMPLATE_STORE` and `TEMPLATE_METADATA`.
"""
remove_templates!(; store = TEMPLATE_STORE, metadata_store = TEMPLATE_METADATA) = (empty!(store); empty!(metadata_store); nothing)

"""
    load_templates!(; remove_templates::Bool=true)

Loads templates from folder `templates/` in the package root and stores them in `TEMPLATE_STORE` and `TEMPLATE_METADATA`.

Note: Automatically removes any existing templates and metadata from `TEMPLATE_STORE` and `TEMPLATE_METADATA` if `remove_templates=true`.
"""
function load_templates!(dir_templates::String = joinpath(@__DIR__, "..", "templates");
        remove_templates::Bool = true,
        store::Dict{Symbol, <:Any} = TEMPLATE_STORE,
        metadata_store::Vector{<:AITemplateMetadata} = TEMPLATE_METADATA,)
    # first remove any old templates and their metadata
    remove_templates && remove_templates!(; store, metadata_store)
    # recursively load all templates from the `templates` folder
    for (root, dirs, files) in walkdir(dir_templates)
        for file in files
            if endswith(file, ".json")
                template_name = Symbol(split(basename(file), ".")[begin])
                template, metadata_msgs = load_template(joinpath(root, file))
                # add to store
                if haskey(store, template_name)
                    @warn("Template $(template_name) already exists, overwriting! Metadata will be duplicated.")
                end
                store[template_name] = template

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
                    if msg isa SystemMessage && length(system_preview) < 100
                        system_preview *= first(msg.content, 100)
                    elseif msg isa UserMessage && length(user_preview) < 100
                        user_preview *= first(msg.content, 100)
                    end
                end
                if !isempty(metadata_msgs)
                    # use the first metadata message found if available
                    meta = first(metadata_msgs)
                    metadata = AITemplateMetadata(; name = template_name,
                        meta.description, meta.version, meta.source,
                        wordcount,
                        system_preview = first(system_preview, 100),
                        user_preview = first(user_preview, 100),
                        variables = unique(variables))
                else
                    metadata = AITemplateMetadata(; name = template_name,
                        wordcount,
                        system_preview = first(system_preview, 100),
                        user_preview = first(user_preview, 100),
                        variables = unique(variables))
                end
                # add metadata to store
                push!(metadata_store, metadata)
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

"Find the top-`limit` templates whose `name::Symbol` partially matches the `query_name::Symbol` in `TEMPLATE_METADATA`."
function aitemplates(query_name::Symbol;
        limit::Int = 10,
        metadata_store::Vector{AITemplateMetadata} = TEMPLATE_METADATA)
    query_str = lowercase(string(query_name))
    found_templates = filter(x -> occursin(query_str,
            lowercase(string(x.name))), metadata_store)
    return first(found_templates, limit)
end
"Find the top-`limit` templates whose `name` or `description` fields partially match the `query_key::String` in `TEMPLATE_METADATA`."
function aitemplates(query_key::AbstractString;
        limit::Int = 10,
        metadata_store::Vector{AITemplateMetadata} = TEMPLATE_METADATA)
    query_str = lowercase(query_key)
    found_templates = filter(x -> occursin(query_str, lowercase(string(x.name))) ||
            occursin(query_str, lowercase(string(x.description))),
        metadata_store)
    return first(found_templates, limit)
end
"Find the top-`limit` templates where provided `query_key::Regex` matches either of `name`, `description` or previews or User or System messages in `TEMPLATE_METADATA`."
function aitemplates(query_key::Regex;
        limit::Int = 10,
        metadata_store::Vector{AITemplateMetadata} = TEMPLATE_METADATA)
    found_templates = filter(x -> occursin(query_key,
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
function aiscan(schema::AbstractPromptSchema, template::AITemplate; kwargs...)
    aiscan(schema, render(schema, template); kwargs...)
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
function aiscan(schema::AbstractPromptSchema, template::Symbol; kwargs...)
    aiscan(schema, AITemplate(template); kwargs...)
end