using PromptingTools
using Documenter

DocMeta.setdocmeta!(PromptingTools,
    :DocTestSetup,
    :(using PromptingTools);
    recursive = true)

makedocs(;
    modules = [PromptingTools],
    authors = "J S <49557684+svilupp@users.noreply.github.com> and contributors",
    repo = "https://github.com/svilupp/PromptingTools.jl/blob/{commit}{path}#{line}",
    sitename = "PromptingTools.jl",
    format = Documenter.HTML(;
        prettyurls = get(ENV, "CI", "false") == "true",
        repolink = "https://github.com/svilupp/PromptingTools.jl",
        canonical = "https://svilupp.github.io/PromptingTools.jl",
        edit_link = "main",
        assets = String[]),
    pages = [
        "Home" => "index.md",
    ])

deploydocs(;
    repo = "github.com/svilupp/PromptingTools.jl",
    devbranch = "main")
