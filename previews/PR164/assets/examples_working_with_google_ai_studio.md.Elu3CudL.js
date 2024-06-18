import { _ as _export_sfc, c as createElementBlock, o as openBlock, a7 as createStaticVNode } from "./chunks/framework.D7bC8ejX.js";
const __pageData = JSON.parse('{"title":"Working with Google AI Studio","description":"","frontmatter":{},"headers":[],"relativePath":"examples/working_with_google_ai_studio.md","filePath":"examples/working_with_google_ai_studio.md","lastUpdated":null}');
const _sfc_main = { name: "examples/working_with_google_ai_studio.md" };
const _hoisted_1 = /* @__PURE__ */ createStaticVNode('<h1 id="Working-with-Google-AI-Studio" tabindex="-1">Working with Google AI Studio <a class="header-anchor" href="#Working-with-Google-AI-Studio" aria-label="Permalink to &quot;Working with Google AI Studio {#Working-with-Google-AI-Studio}&quot;">​</a></h1><p>This file contains examples of how to work with <a href="https://ai.google.dev/" target="_blank" rel="noreferrer">Google AI Studio</a>. It is known for its Gemini models.</p><p>Get an API key from <a href="https://ai.google.dev/" target="_blank" rel="noreferrer">here</a>. If you see a documentation page (&quot;Available languages and regions for Google AI Studio and Gemini API&quot;), it means that it&#39;s not yet available in your region.</p><p>Save the API key in your environment as <code>GOOGLE_API_KEY</code>.</p><p>We&#39;ll need <code>GoogleGenAI</code> package:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> Pkg; Pkg</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">add</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;GoogleGenAI&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><p>You can now use the Gemini-1.0-Pro model like any other model in PromptingTools. We <strong>only support <code>aigenerate</code></strong> at the moment.</p><p>Let&#39;s import PromptingTools:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> PromptingTools</span></span>\n<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">const</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> PT </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> PromptingTools</span></span></code></pre></div><h2 id="Text-Generation-with-aigenerate" tabindex="-1">Text Generation with aigenerate <a class="header-anchor" href="#Text-Generation-with-aigenerate" aria-label="Permalink to &quot;Text Generation with aigenerate {#Text-Generation-with-aigenerate}&quot;">​</a></h2><p>You can use the alias &quot;gemini&quot; for the Gemini-1.0-Pro model.</p><h3 id="Simple-message" tabindex="-1">Simple message <a class="header-anchor" href="#Simple-message" aria-label="Permalink to &quot;Simple message {#Simple-message}&quot;">​</a></h3><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">msg </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> aigenerate</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;Say hi!&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">; model </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;gemini&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span>AIMessage(&quot;Hi there! As a helpful AI assistant, I&#39;m here to help you with any questions or tasks you may have. Feel free to ask me anything, and I&#39;ll do my best to assist you.&quot;)</span></span></code></pre></div><p>You could achieve the same with a string macro (notice the &quot;gemini&quot; at the end to specify which model to use):</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">ai</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;Say hi!&quot;</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">gemini</span></span></code></pre></div><h3 id="Advanced-Prompts" tabindex="-1">Advanced Prompts <a class="header-anchor" href="#Advanced-Prompts" aria-label="Permalink to &quot;Advanced Prompts {#Advanced-Prompts}&quot;">​</a></h3><p>You can provide multi-turn conversations like with any other model:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">conversation </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> [</span></span>\n<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    PT</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">SystemMessage</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;You&#39;re master Yoda from Star Wars trying to help the user become a Yedi.&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">),</span></span>\n<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    PT</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">UserMessage</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;I have feelings for my iPhone. What should I do?&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)]</span></span>\n<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">msg </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> aigenerate</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(conversation; model</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;gemini&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span>AIMessage(&quot;Young Padawan, you have stumbled into a dangerous path. Attachment leads to suffering, and love can turn to darkness. </span></span>\n<span class="line"><span></span></span>\n<span class="line"><span>Release your feelings for this inanimate object. </span></span>\n<span class="line"><span></span></span>\n<span class="line"><span>The Force flows through all living things, not machines. Seek balance in the Force, and your heart will find true connection. </span></span>\n<span class="line"><span></span></span>\n<span class="line"><span>Remember, the path of the Jedi is to serve others, not to be attached to possessions.&quot;)</span></span></code></pre></div><h3 id="Gotchas" tabindex="-1">Gotchas <a class="header-anchor" href="#Gotchas" aria-label="Permalink to &quot;Gotchas {#Gotchas}&quot;">​</a></h3><ul><li><p>Gemini models actually do NOT have a system prompt (for instructions), so we simply concatenate the system and user messages together for consistency with other APIs.</p></li><li><p>The reported <code>tokens</code> in the <code>AIMessage</code> are actually <em>characters</em> (that&#39;s how Google AI Studio intends to charge for them) and are a conservative estimate that we produce. It does not matter, because at the time of writing (Feb-24), the usage is free-of-charge.</p></li></ul>', 22);
const _hoisted_23 = [
  _hoisted_1
];
function _sfc_render(_ctx, _cache, $props, $setup, $data, $options) {
  return openBlock(), createElementBlock("div", null, _hoisted_23);
}
const working_with_google_ai_studio = /* @__PURE__ */ _export_sfc(_sfc_main, [["render", _sfc_render]]);
export {
  __pageData,
  working_with_google_ai_studio as default
};
