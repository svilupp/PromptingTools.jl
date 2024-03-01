import { defineConfig } from 'vitepress'
import { tabsMarkdownPlugin } from 'vitepress-plugin-tabs'
import mathjax3 from "markdown-it-mathjax3";
import footnote from "markdown-it-footnote";

// https://vitepress.dev/reference/site-config
export default defineConfig({
  base: '/PromptingTools.jl/',// TODO: replace this in makedocs!
  title: 'PromptingTools.jl',
  description: "A VitePress Site",
  lastUpdated: true,
  cleanUrls: true,
  outDir: '../final_site', // This is required for MarkdownVitepress to work correctly...
  
  ignoreDeadLinks: true,

  markdown: {
    math: true,
    config(md) {
      md.use(tabsMarkdownPlugin),
      md.use(mathjax3),
      md.use(footnote)
    },
    theme: {
      light: "github-light",
      dark: "github-dark"}
  },
  themeConfig: {
    outline: 'deep',
    logo: { src: '/logo.png', width: 24, height: 24},
    search: {
      provider: 'local',
      options: {
        detailedView: true
      }
    },
    nav: [
{ text: 'Home', link: '/index' },
{ text: 'Getting Started', link: '/getting_started' },
{ text: 'How It Works', link: '/how_it_works' },
{ text: 'Examples', collapsed: false, items: [
{ text: 'Various examples', link: '/examples/readme_examples' },
{ text: 'Using AITemplates', link: '/examples/working_with_aitemplates' },
{ text: 'Local models with Ollama.ai', link: '/examples/working_with_ollama' },
{ text: 'Google AIStudio', link: '/examples/working_with_google_ai_studio' },
{ text: 'Custom APIs (Mistral, Llama.cpp)', link: '/examples/working_with_custom_apis' },
{ text: 'Building RAG Application', link: '/examples/building_RAG' }]
 },
{ text: 'F.A.Q.', link: '/frequently_asked_questions' },
{ text: 'Reference', collapsed: false, items: [
{ text: 'PromptingTools.jl', link: '/reference' },
{ text: 'Experimental Modules', link: '/reference_experimental' },
{ text: 'RAGTools', link: '/reference_ragtools' },
{ text: 'AgentTools', link: '/reference_agenttools' },
{ text: 'APITools', link: '/reference_apitools' }]
 }
]
,
    sidebar: [
{ text: 'Home', link: '/index' },
{ text: 'Getting Started', link: '/getting_started' },
{ text: 'How It Works', link: '/how_it_works' },
{ text: 'Examples', collapsed: false, items: [
{ text: 'Various examples', link: '/examples/readme_examples' },
{ text: 'Using AITemplates', link: '/examples/working_with_aitemplates' },
{ text: 'Local models with Ollama.ai', link: '/examples/working_with_ollama' },
{ text: 'Google AIStudio', link: '/examples/working_with_google_ai_studio' },
{ text: 'Custom APIs (Mistral, Llama.cpp)', link: '/examples/working_with_custom_apis' },
{ text: 'Building RAG Application', link: '/examples/building_RAG' }]
 },
{ text: 'F.A.Q.', link: '/frequently_asked_questions' },
{ text: 'Reference', collapsed: false, items: [
{ text: 'PromptingTools.jl', link: '/reference' },
{ text: 'Experimental Modules', link: '/reference_experimental' },
{ text: 'RAGTools', link: '/reference_ragtools' },
{ text: 'AgentTools', link: '/reference_agenttools' },
{ text: 'APITools', link: '/reference_apitools' }]
 }
]
,
    editLink: { pattern: "https://github.com/YourGithubUsername/YourPackage.jl/edit/main/docs/src/:path" },
    socialLinks: [
      { icon: 'github', link: 'https://github.com/YourGithubUsername/YourPackage.jl' }
    ],
    footer: {
      message: 'Made with <a href="https://documenter.juliadocs.org/stable/" target="_blank"><strong>Documenter.jl</strong></a> & <a href="https://vitepress.dev" target="_blank"><strong>VitePress</strong></a> & Icons by <a target="_blank" href="https://icons8.com">Icons8</a> <br>',
      copyright: `© Copyright ${new Date().getUTCFullYear()}.`
    }
  }
})
