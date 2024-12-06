import { _ as _export_sfc, c as createElementBlock, a5 as createStaticVNode, o as openBlock } from "./chunks/framework.D8VEsFEo.js";
const __pageData = JSON.parse('{"title":"APITools Introduction","description":"","frontmatter":{},"headers":[],"relativePath":"extra_tools/api_tools_intro.md","filePath":"extra_tools/api_tools_intro.md","lastUpdated":null}');
const _sfc_main = { name: "extra_tools/api_tools_intro.md" };
function _sfc_render(_ctx, _cache, $props, $setup, $data, $options) {
  return openBlock(), createElementBlock("div", null, _cache[0] || (_cache[0] = [
    createStaticVNode('<h1 id="APITools-Introduction" tabindex="-1">APITools Introduction <a class="header-anchor" href="#APITools-Introduction" aria-label="Permalink to &quot;APITools Introduction {#APITools-Introduction}&quot;">​</a></h1><p><code>APITools</code> is an experimental module wrapping helpful APIs for working with and enhancing GenerativeAI models.</p><p>Import the module as follows:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> PromptingTools</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">Experimental</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">APITools</span></span></code></pre></div><h2 id="Highlights" tabindex="-1">Highlights <a class="header-anchor" href="#Highlights" aria-label="Permalink to &quot;Highlights {#Highlights}&quot;">​</a></h2><p>Currently, there is only one function in this module <code>create_websearch</code> that leverages <a href="https://tavily.com/" target="_blank" rel="noreferrer">Tavily.com</a> search and answer engine to provide additional context.</p><p>You need to sign up for an API key at <a href="https://tavily.com/" target="_blank" rel="noreferrer">Tavily.com</a> and set it as an environment variable <code>TAVILY_API_KEY</code> to use this function.</p><h2 id="References" tabindex="-1">References <a class="header-anchor" href="#References" aria-label="Permalink to &quot;References {#References}&quot;">​</a></h2><div style="border-width:1px;border-style:solid;border-color:black;padding:1em;border-radius:25px;"><a id="PromptingTools.Experimental.APITools.create_websearch-extra_tools-api_tools_intro" href="#PromptingTools.Experimental.APITools.create_websearch-extra_tools-api_tools_intro">#</a> <b><u>PromptingTools.Experimental.APITools.create_websearch</u></b> — <i>Function</i>. <div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">create_websearch</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(query</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">::</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">AbstractString</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">;</span></span>\n<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    api_key</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">::</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">AbstractString</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>\n<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    search_depth</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">::</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">AbstractString</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> =</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;basic&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><p><strong>Arguments</strong></p><ul><li><p><code>query::AbstractString</code>: The query to search for.</p></li><li><p><code>api_key::AbstractString</code>: The API key to use for the search. Get an API key from <a href="https://tavily.com" target="_blank" rel="noreferrer">Tavily</a>.</p></li><li><p><code>search_depth::AbstractString</code>: The depth of the search. Can be either &quot;basic&quot; or &quot;advanced&quot;. Default is &quot;basic&quot;. Advanced search calls equal to 2 requests.</p></li><li><p><code>include_answer::Bool</code>: Whether to include the answer in the search results. Default is <code>false</code>.</p></li><li><p><code>include_raw_content::Bool</code>: Whether to include the raw content in the search results. Default is <code>false</code>.</p></li><li><p><code>max_results::Integer</code>: The maximum number of results to return. Default is 5.</p></li><li><p><code>include_images::Bool</code>: Whether to include images in the search results. Default is <code>false</code>.</p></li><li><p><code>include_domains::AbstractVector{&lt;:AbstractString}</code>: A list of domains to include in the search results. Default is an empty list.</p></li><li><p><code>exclude_domains::AbstractVector{&lt;:AbstractString}</code>: A list of domains to exclude from the search results. Default is an empty list.</p></li></ul><p><strong>Example</strong></p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">r </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> create_websearch</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;Who is King Charles?&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><p>Even better, you can get not just the results but also the answer:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">r </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> create_websearch</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;Who is King Charles?&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">; include_answer </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> true</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><p>See <a href="https://docs.tavily.com/docs/tavily-api/rest_api" target="_blank" rel="noreferrer">Rest API documentation</a> for more information.</p><p><a href="https://github.com/svilupp/PromptingTools.jl/blob/a716149db0e1382faa4e7eeea5f0cff3e2c70361/src/Experimental/APITools/tavily_api.jl#L31-L59" target="_blank" rel="noreferrer">source</a></p></div><br>', 10)
  ]));
}
const api_tools_intro = /* @__PURE__ */ _export_sfc(_sfc_main, [["render", _sfc_render]]);
export {
  __pageData,
  api_tools_intro as default
};
