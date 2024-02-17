using PromptingTools
using Documenter
using SparseArrays, LinearAlgebra, Markdown
using PromptingTools.Experimental.RAGTools
using PromptingTools.Experimental.AgentTools
using JSON3, Serialization, DataFramesMeta
using Statistics: mean

DocMeta.setdocmeta!(PromptingTools,
    :DocTestSetup,
    :(using PromptingTools);
    recursive = true)

makedocs(;
    modules = [
        PromptingTools,
        PromptingTools.Experimental.RAGTools,
        PromptingTools.Experimental.AgentTools,
    ],
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
        "Getting Started" => "getting_started.md",
        "Examples" => [
            "Various examples" => "examples/readme_examples.md",
            "Using AITemplates" => "examples/working_with_aitemplates.md",
            "Local models with Ollama.ai" => "examples/working_with_ollama.md",
            "Google AIStudio" => "examples/working_with_google_ai_studio.md",
            "Custom APIs (Mistral, Llama.cpp)" => "examples/working_with_custom_apis.md",
            "Building RAG Application" => "examples/building_RAG.md",
        ],
        "F.A.Q." => "frequently_asked_questions.md",
        "Reference" => [
            "PromptingTools.jl" => "reference.md",
            "Experimental Modules" => "reference_experimental.md",
            "RAGTools" => "reference_ragtools.md",
            "AgentTools" => "reference_agenttools.md",
            "APITools" => "reference_apitools.md",
        ],
    ])

deploydocs(;
    repo = "github.com/svilupp/PromptingTools.jl",
    devbranch = "main")
