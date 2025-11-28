import { defineConfig } from 'vitepress'
import { tabsMarkdownPlugin } from 'vitepress-plugin-tabs'
import mathjax3 from "markdown-it-mathjax3";
import footnote from "markdown-it-footnote";

// https://vitepress.dev/reference/site-config
export default defineConfig({
  base: 'REPLACE_ME_DOCUMENTER_VITEPRESS',// TODO: replace this in makedocs!
  title: 'REPLACE_ME_DOCUMENTER_VITEPRESS',
  description: "Streamline Your Interactions with GenAI Models. Discover the power of GenerativeAI and build mini workflows to save you 20 minutes every day.",
  lastUpdated: true,
  cleanUrls: true,
  outDir: 'REPLACE_ME_DOCUMENTER_VITEPRESS', // This is required for MarkdownVitepress to work correctly...
  head: [['link', { rel: 'icon', href: 'REPLACE_ME_DOCUMENTER_VITEPRESS_FAVICON' }]],
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
    logo: 'REPLACE_ME_DOCUMENTER_VITEPRESS',
    search: {
      provider: 'local',
      options: {
        detailedView: true
      }
    },
    nav: [
      { text: 'Home', link: '/index' },
      { text: 'Manual',
          items:[
          { text: 'Getting Started', link: '/getting_started' },
          { text: 'How It Works', link: '/how_it_works' },
          { text: 'Coverage of Model Providers', link: '/coverage_of_model_providers' },
          { text: 'Examples', items: [
            { text: 'Various examples', link: '/examples/readme_examples' },
            { text: 'Using AITemplates', link: '/examples/working_with_aitemplates' },
            { text: 'Local models with Ollama.ai', link: '/examples/working_with_ollama' },
            { text: 'Google AIStudio', link: '/examples/working_with_google_ai_studio' },
            { text: 'Custom APIs (Mistral, Llama.cpp)', link: '/examples/working_with_custom_apis' }]
          },
          { text: 'Extra Tools', items: [
            { text: 'Text Utilities', link: '/extra_tools/text_utilities_intro' },
            { text: 'AgentTools', link: '/extra_tools/agent_tools_intro' },
            { text: 'RAGTools', link: '/extra_tools/rag_tools_intro' },
            { text: 'RAGTools Migration', link: '/ragtools_migration' },
            { text: 'APITools', link: '/extra_tools/api_tools_intro' },
            { text: 'Observability (Logfire)', link: '/extra_tools/observability_logfire' },
          ]
          },
        ],
      },
      { text: 'F.A.Q.', link: '/frequently_asked_questions' },
      { text: 'Prompt Templates', items: [
      { text: 'General', link: '/prompts/general' },
      { text: 'Persona-Task', link: '/prompts/persona-task' },
      { text: 'Visual', link: '/prompts/visual' },
      { text: 'Classification', link: '/prompts/classification' },
      { text: 'Extraction', link: '/prompts/extraction' },
      { text: 'Agents', link: '/prompts/agents' },
      { text: 'RAG', link: '/prompts/RAG' }]
      },
      { text: 'Reference', items: [
      { text: 'PromptingTools.jl', link: '/reference' },
      { text: 'Experimental Modules', link: '/reference_experimental' },
      { text: 'AgentTools', link: '/reference_agenttools' },
      { text: 'APITools', link: '/reference_apitools' }]
      }
      ],
    sidebar: [
      { text: 'Home', link: '/index' },
      { text: 'Manual',
          items:[
          { text: 'Getting Started', link: '/getting_started' },
          { text: 'How It Works', link: '/how_it_works' },
          { text: 'Coverage of Model Providers', link: '/coverage_of_model_providers' },
          { text: 'Examples', collapsed: true, items: [
            { text: 'Various examples', link: '/examples/readme_examples' },
            { text: 'Using AITemplates', link: '/examples/working_with_aitemplates' },
            { text: 'Local models with Ollama.ai', link: '/examples/working_with_ollama' },
            { text: 'Google AIStudio', link: '/examples/working_with_google_ai_studio' },
            { text: 'Custom APIs (Mistral, Llama.cpp)', link: '/examples/working_with_custom_apis' }]
          },
          { text: 'Extra Tools', collapsed: true, items: [
            { text: 'Text Utilities', link: '/extra_tools/text_utilities_intro' },
            { text: 'AgentTools', link: '/extra_tools/agent_tools_intro' },
            { text: 'APITools', link: '/extra_tools/api_tools_intro' },
            { text: 'Observability (Logfire)', link: '/extra_tools/observability_logfire' }]
          },
        ],
      },
      { text: 'F.A.Q.', link: '/frequently_asked_questions' },
      { text: 'Prompt Templates', collapsed: true, items: [
      { text: 'General', link: '/prompts/general' },
      { text: 'Persona-Task', link: '/prompts/persona-task' },
      { text: 'Visual', link: '/prompts/visual' },
      { text: 'Classification', link: '/prompts/classification' },
      { text: 'Extraction', link: '/prompts/extraction' },
      { text: 'Agents', link: '/prompts/agents' },
      { text: 'RAG', link: '/prompts/RAG' }]
        },
      { text: 'Reference', collapsed: true, items: [
      { text: 'PromptingTools.jl', link: '/reference' },
      { text: 'Experimental Modules', link: '/reference_experimental' },
      { text: 'AgentTools', link: '/reference_agenttools' },
      { text: 'APITools', link: '/reference_apitools' }]
        }
    ],
    editLink: 'REPLACE_ME_DOCUMENTER_VITEPRESS',
    socialLinks: [
      { icon: 'github', link: 'REPLACE_ME_DOCUMENTER_VITEPRESS' }
    ],
    footer: {
      message: 'Made with <a href="https://documenter.juliadocs.org/stable/" target="_blank"><strong>Documenter.jl</strong></a> & <a href="https://vitepress.dev" target="_blank"><strong>VitePress</strong></a> & Icons by <a target="_blank" href="https://icons8.com">Icons8</a> <br>',
      copyright: `© Copyright ${new Date().getUTCFullYear()}.`
    }
  }
})