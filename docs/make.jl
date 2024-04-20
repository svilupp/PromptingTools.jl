using Documenter, DocumenterVitepress
using PromptingTools
const PT = PromptingTools
using SparseArrays, LinearAlgebra, Markdown
using PromptingTools.Experimental.RAGTools
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
        PromptingTools.Experimental.RAGTools,
        PromptingTools.Experimental.AgentTools
    ],
    authors = "J S <49557684+svilupp@users.noreply.github.com> and contributors",
    repo = "https://github.com/svilupp/PromptingTools.jl/blob/{commit}{path}#{line}",
    sitename = "PromptingTools.jl",
    ## format = Documenter.HTML(;
    ##     prettyurls = get(ENV, "CI", "false") == "true",
    ##     repolink = "https://github.com/svilupp/PromptingTools.jl",
    ##     canonical = "https://svilupp.github.io/PromptingTools.jl",
    ##     edit_link = "main",
    ##     size_threshold = nothing,
    ##     assets = String[]),
    format = DocumenterVitepress.MarkdownVitepress(
        repo = "https://github.com/svilupp/PromptingTools.jl",
        devbranch = "main",
        devurl = "dev",
        deploy_url = "svilupp.github.io/PromptingTools.jl"
    ),
    draft = false,
    source = "src",
    build = "build",
    pages = [
        "Home" => "index.md",
        "Getting Started" => "getting_started.md",
        "How It Works" => "how_it_works.md",
        "Coverage of Model Providers" => "coverage_of_model_providers.md",
        "Examples" => [
            "Various examples" => "examples/readme_examples.md",
            "Using AITemplates" => "examples/working_with_aitemplates.md",
            "Local models with Ollama.ai" => "examples/working_with_ollama.md",
            "Google AIStudio" => "examples/working_with_google_ai_studio.md",
            "Custom APIs (Mistral, Llama.cpp)" => "examples/working_with_custom_apis.md",
            "Building RAG Application" => "examples/building_RAG.md"
        ],
        "Extra Tools" => [
            "Text Utilities" => "extra_tools/text_utilities_intro.md",
            "AgentTools" => "extra_tools/agent_tools_intro.md",
            "RAGTools" => "extra_tools/rag_tools_intro.md",
            "APITools" => "extra_tools/api_tools_intro.md"
        ],
        "F.A.Q." => "frequently_asked_questions.md",
        "Prompt Templates" => [
            "General" => "prompts/general.md",
            "Persona-Task" => "prompts/persona-task.md",
            "Visual" => "prompts/visual.md",
            "Classification" => "prompts/classification.md",
            "Extraction" => "prompts/extraction.md",
            "Agents" => "prompts/agents.md",
            "RAG" => "prompts/RAG.md"
        ],
        "Reference" => [
            "PromptingTools.jl" => "reference.md",
            "Experimental Modules" => "reference_experimental.md",
            "RAGTools" => "reference_ragtools.md",
            "AgentTools" => "reference_agenttools.md",
            "APITools" => "reference_apitools.md"
        ]
    ])

deploydocs(;
    repo = "github.com/svilupp/PromptingTools.jl",
    target = "build",
    push_preview = true,
    branch = "gh-pages",
    devbranch = "main")
