import { _ as _export_sfc, c as createElementBlock, o as openBlock, a7 as createStaticVNode } from "./chunks/framework.C1DzC6vG.js";
const __pageData = JSON.parse('{"title":"","description":"","frontmatter":{},"headers":[],"relativePath":"prompts/visual.md","filePath":"prompts/visual.md","lastUpdated":null}');
const _sfc_main = { name: "prompts/visual.md" };
const _hoisted_1 = /* @__PURE__ */ createStaticVNode('<p>The following file is auto-generated from the <code>templates</code> folder. For any changes, please modify the source files in the <code>templates</code> folder.</p><p>To use these templates in <code>aigenerate</code>, simply provide the template name as a symbol, eg, <code>aigenerate(:MyTemplate; placeholder1 = value1)</code></p><h2 id="Visual-Templates" tabindex="-1">Visual Templates <a class="header-anchor" href="#Visual-Templates" aria-label="Permalink to &quot;Visual Templates {#Visual-Templates}&quot;">​</a></h2><h3 id="Template:-OCRTask" tabindex="-1">Template: OCRTask <a class="header-anchor" href="#Template:-OCRTask" aria-label="Permalink to &quot;Template: OCRTask {#Template:-OCRTask}&quot;">​</a></h3><ul><li><p>Description: Transcribe screenshot, scanned pages, photos, etc. Placeholders: <code>task</code></p></li><li><p>Placeholders: <code>task</code></p></li><li><p>Word count: 239</p></li><li><p>Source:</p></li><li><p>Version: 1</p></li></ul><p><strong>System Prompt:</strong></p><div class="language-plaintext vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">plaintext</span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span>You are a world-class OCR engine. Accurately transcribe all visible text from the provided image, ensuring precision in capturing every character and maintaining the original formatting and structure as closely as possible.</span></span></code></pre></div><p><strong>User Prompt:</strong></p><div class="language-plaintext vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">plaintext</span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span># Task</span></span>\n<span class="line"><span></span></span>\n<span class="line"><span>{{task}}</span></span></code></pre></div>', 9);
const _hoisted_10 = [
  _hoisted_1
];
function _sfc_render(_ctx, _cache, $props, $setup, $data, $options) {
  return openBlock(), createElementBlock("div", null, _hoisted_10);
}
const visual = /* @__PURE__ */ _export_sfc(_sfc_main, [["render", _sfc_render]]);
export {
  __pageData,
  visual as default
};
