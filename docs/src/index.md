```@raw html
---
layout: home

hero:
  name: PromptingTools.jl
  tagline: Streamline Your Interactions with GenAI Models
  description: Discover the power of GenerativeAI and build mini workflows to save you 20 minutes every day.
  image:
    src: https://img.icons8.com/dusk/64/swiss-army-knife--v1.png
    alt: Swiss Army Knife
  actions:
    - theme: brand
      text: Get Started
      link: /getting_started
    - theme: alt
      text: How It Works
      link: /how_it_works
    - theme: alt
      text: F.A.Q.
      link: /frequently_asked_questions
    - theme: alt
      text: View on GitHub
      link: https://github.com/svilupp/PromptingTools.jl

features:
  - icon: <img width="64" height="64" src="https://img.icons8.com/clouds/100/000000/brain.png" alt="Simplify"/>
    title: Simplify Prompt Engineering
    details: 'Leverage prompt templates with placeholders to make complex prompts easy.'
  - icon: <img width="60" height="60" src="https://img.icons8.com/papercut/60/connected.png" alt="Integration"/>
    title: Effortless Integration
    details: 'Fire quick questions with @ai_str macro and light wrapper types. Minimal dependencies for seamless integration.'
  - icon: <img width="64" height="64" src="https://img.icons8.com/dusk/64/search--v1.png" alt="Discoverability"/>
    title: Designed for Discoverability
    details: 'Efficient access to cutting-edge models with intuitive ai* functions. Stay in the flow with minimal context switching.'

---
```



<p style="margin-bottom:2cm"></p>

<div class="vp-doc" style="width:80%; margin:auto">

<h1> Why PromptingTools.jl? </h1>

Prompt engineering is neither fast nor easy. Moreover, different models and their fine-tunes might require different prompt formats and tricks, or perhaps the information you work with requires special models to be used. PromptingTools.jl is meant to unify the prompts for different backends and make the common tasks (like templated prompts) as simple as possible. 

<h2> Getting Started </h2>

Add PromptingTools, set OpenAI API key and generate your first answer:

```julia
using Pkg
Pkg.add("PromptingTools")
# Requires OPENAI_API_KEY environment variable!

ai"What is the meaning of life?"
```

For more information, see the [Getting Started](@ref) section.

<br>
Ready to simplify your GenerativeAI tasks? Dive into PromptingTools.jl now and unlock your productivity.

<h2> Building a More Advanced Workflow? </h2>

PromptingTools offers many advanced features:
- Easy prompt templating and automatic serialization and tracing of your AI conversations for great observability
- Ability to export into a ShareGPT-compatible format for easy fine-tuning
- Code evaluation and automatic error localization for better LLM debugging
- RAG workflows are now supported via the separate [RAGTools.jl](https://github.com/JuliaGenAI/RAGTools.jl) package
- AgentTools module: lazy ai* calls with states, automatic code feedback, Monte-Carlo tree search-based auto-fixing of your workflows (ie, not just retrying in a loop)

and more!

</div>
