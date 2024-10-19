import { _ as _export_sfc, c as createElementBlock, a5 as createStaticVNode, o as openBlock } from "./chunks/framework.D66RCLwU.js";
const __pageData = JSON.parse('{"title":"","description":"","frontmatter":{"layout":"home","hero":{"name":"PromptingTools.jl","tagline":"Streamline Your Interactions with GenAI Models","description":"Discover the power of GenerativeAI and build mini workflows to save you 20 minutes every day.","image":{"src":"https://img.icons8.com/dusk/64/swiss-army-knife--v1.png","alt":"Swiss Army Knife"},"actions":[{"theme":"brand","text":"Get Started","link":"/getting_started"},{"theme":"alt","text":"How It Works","link":"/how_it_works"},{"theme":"alt","text":"F.A.Q.","link":"/frequently_asked_questions"},{"theme":"alt","text":"View on GitHub","link":"https://github.com/svilupp/PromptingTools.jl"}]},"features":[{"icon":"<img width=\\"64\\" height=\\"64\\" src=\\"https://img.icons8.com/clouds/100/000000/brain.png\\" alt=\\"Simplify\\"/>","title":"Simplify Prompt Engineering","details":"Leverage prompt templates with placeholders to make complex prompts easy."},{"icon":"<img width=\\"60\\" height=\\"60\\" src=\\"https://img.icons8.com/papercut/60/connected.png\\" alt=\\"Integration\\"/>","title":"Effortless Integration","details":"Fire quick questions with @ai_str macro and light wrapper types. Minimal dependencies for seamless integration."},{"icon":"<img width=\\"64\\" height=\\"64\\" src=\\"https://img.icons8.com/dusk/64/search--v1.png\\" alt=\\"Discoverability\\"/>","title":"Designed for Discoverability","details":"Efficient access to cutting-edge models with intuitive ai* functions. Stay in the flow with minimal context switching."}]},"headers":[],"relativePath":"index.md","filePath":"index.md","lastUpdated":null}');
const _sfc_main = { name: "index.md" };
function _sfc_render(_ctx, _cache, $props, $setup, $data, $options) {
  return openBlock(), createElementBlock("div", null, _cache[0] || (_cache[0] = [
    createStaticVNode('<p style="margin-bottom:2cm;"></p><div class="vp-doc" style="width:80%;margin:auto;"><h1> Why PromptingTools.jl? </h1><p>Prompt engineering is neither fast nor easy. Moreover, different models and their fine-tunes might require different prompt formats and tricks, or perhaps the information you work with requires special models to be used. PromptingTools.jl is meant to unify the prompts for different backends and make the common tasks (like templated prompts) as simple as possible.</p><h2> Getting Started </h2><p>Add PromptingTools, set OpenAI API key and generate your first answer:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> Pkg</span></span>\n<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">Pkg</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">add</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;PromptingTools&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>\n<span class="line"><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;"># Requires OPENAI_API_KEY environment variable!</span></span>\n<span class="line"></span>\n<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">ai</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;What is the meaning of life?&quot;</span></span></code></pre></div><p>For more information, see the <a href="/PromptingTools.jl/previews/PR219/getting_started#Getting-Started">Getting Started</a> section.</p><p><br> Ready to simplify your GenerativeAI tasks? Dive into PromptingTools.jl now and unlock your productivity.</p><h2> Building a More Advanced Workflow? </h2><p>PromptingTools offers many advanced features:</p><ul><li><p>Easy prompt templating and automatic serialization and tracing of your AI conversations for great observability</p></li><li><p>Ability to export into a ShareGPT-compatible format for easy fine-tuning</p></li><li><p>Code evaluation and automatic error localization for better LLM debugging</p></li><li><p>RAGTools module: from simple to advanced RAG implementations (hybrid index, rephrasing, reranking, etc.)</p></li><li><p>AgentTools module: lazy ai* calls with states, automatic code feedback, Monte-Carlo tree search-based auto-fixing of your workflows (ie, not just retrying in a loop)</p></li></ul><p>and more!</p></div>', 2)
  ]));
}
const index = /* @__PURE__ */ _export_sfc(_sfc_main, [["render", _sfc_render]]);
export {
  __pageData,
  index as default
};
