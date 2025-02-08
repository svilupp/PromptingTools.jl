import { _ as _export_sfc, c as createElementBlock, o as openBlock, ai as createStaticVNode } from "./chunks/framework.BtwkMZaB.js";
const __pageData = JSON.parse('{"title":"","description":"","frontmatter":{},"headers":[],"relativePath":"prompts/general.md","filePath":"prompts/general.md","lastUpdated":null}');
const _sfc_main = { name: "prompts/general.md" };
function _sfc_render(_ctx, _cache, $props, $setup, $data, $options) {
  return openBlock(), createElementBlock("div", null, _cache[0] || (_cache[0] = [
    createStaticVNode('<p>The following file is auto-generated from the <code>templates</code> folder. For any changes, please modify the source files in the <code>templates</code> folder.</p><p>To use these templates in <code>aigenerate</code>, simply provide the template name as a symbol, eg, <code>aigenerate(:MyTemplate; placeholder1 = value1)</code></p><h2 id="General-Templates" tabindex="-1">General Templates <a class="header-anchor" href="#General-Templates" aria-label="Permalink to &quot;General Templates {#General-Templates}&quot;">​</a></h2><h3 id="Template:-BlankSystemUser" tabindex="-1">Template: BlankSystemUser <a class="header-anchor" href="#Template:-BlankSystemUser" aria-label="Permalink to &quot;Template: BlankSystemUser {#Template:-BlankSystemUser}&quot;">​</a></h3><ul><li><p>Description: Blank template for easy prompt entry without the <code>*Message</code> objects. Simply provide keyword arguments for <code>system</code> (=system prompt/persona) and <code>user</code> (=user/task/data prompt). Placeholders: <code>system</code>, <code>user</code></p></li><li><p>Placeholders: <code>system</code>, <code>user</code></p></li><li><p>Word count: 18</p></li><li><p>Source:</p></li><li><p>Version: 1.1</p></li></ul><p><strong>System Prompt:</strong></p><div class="language-plaintext vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">plaintext</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>{{system}}</span></span></code></pre></div><p><strong>User Prompt:</strong></p><div class="language-plaintext vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">plaintext</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>{{user}}</span></span></code></pre></div><h3 id="Template:-PromptEngineerForTask" tabindex="-1">Template: PromptEngineerForTask <a class="header-anchor" href="#Template:-PromptEngineerForTask" aria-label="Permalink to &quot;Template: PromptEngineerForTask {#Template:-PromptEngineerForTask}&quot;">​</a></h3><ul><li><p>Description: Prompt engineer that suggests what could be a good system prompt/user prompt for a given <code>task</code>. Placeholder: <code>task</code></p></li><li><p>Placeholders: <code>task</code></p></li><li><p>Word count: 402</p></li><li><p>Source:</p></li><li><p>Version: 1</p></li></ul><p><strong>System Prompt:</strong></p><div class="language-plaintext vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">plaintext</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>You are a world-class prompt engineering assistant. Generate a clear, effective prompt that accurately interprets and structures the user&#39;s task, ensuring it is comprehensive, actionable, and tailored to elicit the most relevant and precise output from an AI model. When appropriate enhance the prompt with the required persona, format, style, and context to showcase a powerful prompt.</span></span></code></pre></div><p><strong>User Prompt:</strong></p><div class="language-plaintext vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">plaintext</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span># Task</span></span>\n<span class="line"><span></span></span>\n<span class="line"><span>{{task}}</span></span></code></pre></div>', 15)
  ]));
}
const general = /* @__PURE__ */ _export_sfc(_sfc_main, [["render", _sfc_render]]);
export {
  __pageData,
  general as default
};
