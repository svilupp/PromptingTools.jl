import { _ as _export_sfc, c as createElementBlock, m as createBaseVNode, t as toDisplayString, a7 as createStaticVNode, o as openBlock } from "./chunks/framework.BmjGwZNh.js";
const __pageData = JSON.parse('{"title":"Using AITemplates","description":"","frontmatter":{},"headers":[],"relativePath":"examples/working_with_aitemplates.md","filePath":"examples/working_with_aitemplates.md","lastUpdated":null}');
const _sfc_main = { name: "examples/working_with_aitemplates.md" };
const _hoisted_1 = /* @__PURE__ */ createStaticVNode('<h1 id="Using-AITemplates" tabindex="-1">Using AITemplates <a class="header-anchor" href="#Using-AITemplates" aria-label="Permalink to &quot;Using AITemplates {#Using-AITemplates}&quot;">​</a></h1><p>This file contains examples of how to work with AITemplate(s).</p><p>First, let&#39;s import the package and define a helper link for calling un-exported functions:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> PromptingTools</span></span>\n<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">const</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> PT </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> PromptingTools</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span>PromptingTools</span></span></code></pre></div><p>LLM responses are only as good as the prompts you give them. However, great prompts take long time to write – AITemplate are a way to re-use great prompts!</p>', 6);
const _hoisted_7 = /* @__PURE__ */ createStaticVNode('<p>They are saved as JSON files in the <code>templates</code> directory. They are automatically loaded on package import, but you can always force a re-load with <code>PT.load_templates!()</code></p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">PT</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">load_templates!</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">();</span></span></code></pre></div><p>You can (create them) and use them for any ai* function instead of a prompt: Let&#39;s use a template called <code>:JuliaExpertAsk</code> alternatively, you can use <code>AITemplate(:JuliaExpertAsk)</code> for cleaner dispatch</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">msg </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> aigenerate</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:JuliaExpertAsk</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">; ask </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;How do I add packages?&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span>AIMessage(&quot;To add packages in Julia, you can use the `Pkg` module. Here are the steps:</span></span>\n<span class="line"><span></span></span>\n<span class="line"><span>1. Start Julia by running the Julia REPL (Read-Eval-Print Loop).</span></span>\n<span class="line"><span>2. Press the `]` key to enter the Pkg mode.</span></span>\n<span class="line"><span>3. To add a package, use the `add` command followed by the package name.</span></span>\n<span class="line"><span>4. Press the backspace key to exit Pkg mode and return to the Julia REPL.</span></span>\n<span class="line"><span></span></span>\n<span class="line"><span>For example, to add the `Example` package, you would enter:</span></span>\n<span class="line"><span></span></span>\n<span class="line"><span>```julia</span></span>\n<span class="line"><span>]add Example</span></span>\n<span class="line"><span>```</span></span>\n<span class="line"><span></span></span>\n<span class="line"><span>After the package is added, you can start using it in your Julia code by using the `using` keyword. For the `Example` package, you would add the following line to your code:</span></span>\n<span class="line"><span></span></span>\n<span class="line"><span>```julia</span></span>\n<span class="line"><span>using Example</span></span>\n<span class="line"><span>```</span></span>\n<span class="line"><span></span></span>\n<span class="line"><span>Note: The first time you add a package, Julia may take some time to download and compile the package and its dependencies.&quot;)</span></span></code></pre></div><p>You can see that it had a placeholder for the actual question (<code>ask</code>) that we provided as a keyword argument. We did not have to write any system prompt for personas, tone, etc. – it was all provided by the template!</p><p>How to know which templates are available? You can search for them with <code>aitemplates()</code>: You can search by Symbol (only for partial name match), String (partial match on name or description), or Regex (more fields)</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">tmps </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> aitemplates</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;JuliaExpertAsk&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span>1-element Vector{AITemplateMetadata}:</span></span>\n<span class="line"><span>PromptingTools.AITemplateMetadata</span></span>\n<span class="line"><span>  name: Symbol JuliaExpertAsk</span></span>\n<span class="line"><span>  description: String &quot;For asking questions about Julia language. Placeholders: `ask`&quot;</span></span>\n<span class="line"><span>  version: String &quot;1&quot;</span></span>\n<span class="line"><span>  wordcount: Int64 237</span></span>\n<span class="line"><span>  variables: Array{Symbol}((1,))</span></span>\n<span class="line"><span>  system_preview: String &quot;You are a world-class Julia language programmer with the knowledge of the latest syntax. Your commun&quot;</span></span>\n<span class="line"><span>  user_preview: String &quot;# Question\\n\\n{{ask}}&quot;</span></span>\n<span class="line"><span>  source: String &quot;&quot;</span></span></code></pre></div><p>You can see that it outputs a list of available templates that match the search - there is just one in this case.</p><p>Moreover, it shows not just the description, but also a preview of the actual prompts, placeholders available, and the length (to gauge how much it would cost).</p><p>If you use VSCode, you can display them in a nice scrollable table with <code>vscodedisplay</code>:</p><div class="language-plaintext vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">plaintext</span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span>using DataFrames</span></span>\n<span class="line"><span>DataFrame(tmp) |&gt; vscodedisplay</span></span></code></pre></div><p>You can also just <code>render</code> the template to see the underlying mesages:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">msgs </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> PT</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">render</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">AITemplate</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:JuliaExpertAsk</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">))</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span>2-element Vector{PromptingTools.AbstractChatMessage}:</span></span>\n<span class="line"><span> PromptingTools.SystemMessage(&quot;You are a world-class Julia language programmer with the knowledge of the latest syntax. Your communication is brief and concise. You&#39;re precise and answer only when you&#39;re confident in the high quality of your answer.&quot;)</span></span>\n<span class="line"><span> PromptingTools.UserMessage{String}(&quot;# Question\\n\\n{{ask}}&quot;, [:ask], :usermessage)</span></span></code></pre></div><p>Now, you know exactly what&#39;s in the template!</p><p>If you want to modify it, simply change it and save it as a new file with <code>save_template</code> (see the docs <code>?save_template</code> for more details).</p><p>Let&#39;s adjust the previous template to be more specific to a data analysis question:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">tpl </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> [PT</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">SystemMessage</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;You are a world-class Julia language programmer with the knowledge of the latest syntax. You&#39;re also a senior Data Scientist and proficient in data analysis in Julia. Your communication is brief and concise. You&#39;re precise and answer only when you&#39;re confident in the high quality of your answer.&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>\n<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    PT</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">UserMessage</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;# Question</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">\\n\\n</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">{{ask}}&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)]</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span>2-element Vector{PromptingTools.AbstractChatMessage}:</span></span>\n<span class="line"><span> PromptingTools.SystemMessage(&quot;You are a world-class Julia language programmer with the knowledge of the latest syntax. You&#39;re also a senior Data Scientist and proficient in data analysis in Julia. Your communication is brief and concise. You&#39;re precise and answer only when you&#39;re confident in the high quality of your answer.&quot;)</span></span>\n<span class="line"><span> PromptingTools.UserMessage{String}(&quot;# Question\\n\\n{{ask}}&quot;, [:ask], :usermessage)</span></span></code></pre></div><p>Templates are saved in the <code>templates</code> directory of the package. Name of the file will become the template name (eg, call <code>:JuliaDataExpertAsk</code>)</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">filename </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> joinpath</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">pkgdir</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(PromptingTools),</span></span>\n<span class="line"><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">    &quot;templates&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>\n<span class="line"><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">    &quot;persona-task&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>\n<span class="line"><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">    &quot;JuliaDataExpertAsk_123.json&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>\n<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">PT</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">save_template</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(filename,</span></span>\n<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    tpl;</span></span>\n<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    description </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;For asking data analysis questions in Julia language. Placeholders: `ask`&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>\n<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">rm</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(filename) </span><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;"># cleanup if we don&#39;t like it</span></span></code></pre></div><p>When you create a new template, remember to re-load the templates with <code>load_templates!()</code> so that it&#39;s available for use.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">PT</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">load_templates!</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">();</span></span></code></pre></div><p>!!! If you have some good templates (or suggestions for the existing ones), please consider sharing them with the community by opening a PR to the <code>templates</code> directory!</p><hr><p><em>This page was generated using <a href="https://github.com/fredrikekre/Literate.jl" target="_blank" rel="noreferrer">Literate.jl</a>.</em></p>', 28);
function _sfc_render(_ctx, _cache, $props, $setup, $data, $options) {
  return openBlock(), createElementBlock("div", null, [
    _hoisted_1,
    createBaseVNode("p", null, 'AITemplates are just a collection of templated prompts (ie, set of "messages" that have placeholders like ' + toDisplayString(_ctx.question) + ")", 1),
    _hoisted_7
  ]);
}
const working_with_aitemplates = /* @__PURE__ */ _export_sfc(_sfc_main, [["render", _sfc_render]]);
export {
  __pageData,
  working_with_aitemplates as default
};
