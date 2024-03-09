import { _ as _export_sfc, c as createElementBlock, m as createBaseVNode, t as toDisplayString, a7 as createStaticVNode, o as openBlock } from "./chunks/framework.BqhW5vgI.js";
const __pageData = JSON.parse('{"title":"","description":"","frontmatter":{},"headers":[],"relativePath":"prompts/visual.md","filePath":"prompts/visual.md","lastUpdated":null}');
const _sfc_main = { name: "prompts/visual.md" };
const _hoisted_1 = /* @__PURE__ */ createStaticVNode('<p>The following file is auto-generated from the <code>templates</code> folder. For any changes, please modify the source files in the <code>templates</code> folder.</p><p>To use these templates in <code>aigenerate</code>, simply provide the template name as a symbol, eg, <code>aigenerate(:MyTemplate; placeholder1 = value1)</code></p><h2 id="visual-templates-visual-templates" tabindex="-1">Visual Templates {#Visual-Templates} <a class="header-anchor" href="#visual-templates-visual-templates" aria-label="Permalink to &quot;Visual Templates {#Visual-Templates}&quot;">​</a></h2><h3 id="template-ocrtask-template-ocrtask" tabindex="-1">Template: OCRTask {#Template:-OCRTask} <a class="header-anchor" href="#template-ocrtask-template-ocrtask" aria-label="Permalink to &quot;Template: OCRTask {#Template:-OCRTask}&quot;">​</a></h3><ul><li><p>Description: Transcribe screenshot, scanned pages, photos, etc. Placeholders: <code>task</code></p></li><li><p>Placeholders: <code>task</code></p></li><li><p>Word count: 239</p></li><li><p>Source:</p></li><li><p>Version: 1</p></li></ul><p><strong>System Prompt:</strong></p><blockquote><p>You are a world-class OCR engine. Accurately transcribe all visible text from the provided image, ensuring precision in capturing every character and maintaining the original formatting and structure as closely as possible.</p></blockquote><p><strong>User Prompt:</strong></p>', 8);
const _hoisted_9 = /* @__PURE__ */ createBaseVNode("p", null, "MarkdownAST.Heading(1)", -1);
function _sfc_render(_ctx, _cache, $props, $setup, $data, $options) {
  return openBlock(), createElementBlock("div", null, [
    _hoisted_1,
    createBaseVNode("blockquote", null, [
      _hoisted_9,
      createBaseVNode("p", null, toDisplayString(_ctx.task), 1)
    ])
  ]);
}
const visual = /* @__PURE__ */ _export_sfc(_sfc_main, [["render", _sfc_render]]);
export {
  __pageData,
  visual as default
};
