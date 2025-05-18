using Documenter, DocumenterVitepress
using PromptingTools
const PT = PromptingTools
using SparseArrays, LinearAlgebra, Markdown, Unicode
using PromptingTools.Experimental.AgentTools
using JSON3, Serialization, DataFramesMeta
using Statistics: mean

## Generate the prompt documentation
include("generate_prompt_library.jl")

# Enable debugging for vitepress
ENV["DEBUG"] = "vitepress:*"

DocMeta.setdocmeta!(PromptingTools,
    :DocTestSetup,
    :(using PromptingTools);
    recursive = true)

makedocs(;
    modules = [
        PromptingTools,
        PromptingTools.Experimental.AgentTools,
        PromptingTools.CustomRetryLayer
    ],
    authors = "J S <49557684+svilupp@users.noreply.github.com> and contributors",
    repo = "https://github.com/svilupp/PromptingTools.jl/blob/{commit}{path}#{line}",
    sitename = "PromptingTools.jl",
    format = DocumenterVitepress.MarkdownVitepress(
        repo = "https://github.com/svilupp/PromptingTools.jl",
        devbranch = "main",
        devurl = "dev",
        deploy_url = "svilupp.github.io/PromptingTools.jl"
    ),
    draft = false,
    source = "src",
    build = "build"
)

deploydocs(;
    repo = "github.com/svilupp/PromptingTools.jl",
    target = "build",
    push_preview = true,
    branch = "gh-pages",
    devbranch = "main")
