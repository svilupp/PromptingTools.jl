# Generates the "Prompt Library" sections of the docs
#
# 1 page for each folder in `templates/`, 1 section for each file in the folder

## ! Config
input_files = joinpath(@__DIR__, "..", "templates", "general") |>
              x -> readdir(x; join = true)
output_dir = joinpath(@__DIR__, "src", "prompts")
mkpath(output_dir);

## Utilities
"Returns the file name and the section name."
function extract_md_hierarchy(fn)
    ## find the depth of nested folders 
    p = splitpath(fn)
    idx = findfirst(==("templates"), p)
    if idx == nothing || idx >= length(p) - 1
        nothing, nothing
    elseif idx == length(p) - 2
        ## no dual subfolder, duplicate name
        p[idx + 1] * ".md", titlecase(p[idx + 1])
    else
        ## has dual subfolder
        p[idx + 1] * ".md", titlecase(p[idx + 2])
    end
end
function escape_prompt(s)
    ## escape HTML tags
    ## s = replace(
    ##     s, "\n" => "\n> ", "<" => "\\<", ">" => "\\>", "{{" => "\\{\\{", "}}" => "\\}\\}")
    ## return "> " * s
    """`````plaintext\n$(s)\n`````\n"""
end

## Load the templates
# key: top-level folder, sub-folder, file
loaded_templates = Dict{String, Dict}()
for (dir, _, files) in walkdir(joinpath(@__DIR__, "..", "templates"))
    for file in files
        fn = joinpath(dir, file)
        if endswith(fn, ".json")
            dest_file, section = extract_md_hierarchy(fn)
            if isnothing(dest_file)
                continue
            end
            dest_file_path = joinpath(output_dir, dest_file)
            template, metadata = PT.load_template(fn)
            template_name = splitext(basename(file))[1] |> Symbol
            # Assumes that there is only ever one UserMessage and SystemMessage (concats them together)
            meta = PT.build_template_metadata(
                template, template_name, metadata; max_length = 10^6)
            ## save to loaded_templates
            file_dict = get!(loaded_templates, dest_file_path, Dict())
            section_vect = get!(file_dict, section, [])
            push!(section_vect, meta)
        end
    end
end

## Write into files
for file_path in keys(loaded_templates)
    io = IOBuffer()
    println(io,
        "The following file is auto-generated from the `templates` folder. For any changes, please modify the source files in the `templates` folder.\n")
    println(io,
        "To use these templates in `aigenerate`, simply provide the template name as a symbol, eg, `aigenerate(:MyTemplate; placeholder1 = value1)`")
    println(io)
    for (section, templates) in loaded_templates[file_path]
        println(io, "## $(section) Templates\n")
        for meta in templates
            println(io, "### Template: $(meta.name)")
            println(io)
            println(io, "- Description: $(meta.description)")
            println(
                io, "- Placeholders: $(join("`" .* string.(meta.variables) .* "`",", "))")
            println(io, "- Word count: $(meta.wordcount)")
            println(io, "- Source: $(meta.source)")
            println(io, "- Version: $(meta.version)")
            println(io)
            println(io, "**System Prompt:**")
            println(io, escape_prompt(meta.system_preview))
            println(io)
            println(io, "**User Prompt:**")
            println(io, escape_prompt(meta.user_preview))
            println(io)
        end
    end
    ## write to file
    write(file_path, String(take!(io)))
end
