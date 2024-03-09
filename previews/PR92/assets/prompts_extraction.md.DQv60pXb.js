import { _ as _export_sfc, c as createElementBlock, m as createBaseVNode, t as toDisplayString, a7 as createStaticVNode, o as openBlock } from "./chunks/framework.BqhW5vgI.js";
const __pageData = JSON.parse('{"title":"","description":"","frontmatter":{},"headers":[],"relativePath":"prompts/extraction.md","filePath":"prompts/extraction.md","lastUpdated":null}');
const _sfc_main = { name: "prompts/extraction.md" };
const _hoisted_1 = /* @__PURE__ */ createStaticVNode('<p>The following file is auto-generated from the <code>templates</code> folder. For any changes, please modify the source files in the <code>templates</code> folder.</p><p>To use these templates in <code>aigenerate</code>, simply provide the template name as a symbol, eg, <code>aigenerate(:MyTemplate; placeholder1 = value1)</code></p><h2 id="extraction-templates-extraction-templates" tabindex="-1">Extraction Templates {#Extraction-Templates} <a class="header-anchor" href="#extraction-templates-extraction-templates" aria-label="Permalink to &quot;Extraction Templates {#Extraction-Templates}&quot;">​</a></h2><h3 id="template-extractdata-template-extractdata" tabindex="-1">Template: ExtractData {#Template:-ExtractData} <a class="header-anchor" href="#template-extractdata-template-extractdata" aria-label="Permalink to &quot;Template: ExtractData {#Template:-ExtractData}&quot;">​</a></h3><ul><li><p>Description: Template suitable for data extraction via <code>aiextract</code> calls. Placeholder: <code>data</code>.</p></li><li><p>Placeholders: <code>data</code></p></li><li><p>Word count: 500</p></li><li><p>Source:</p></li><li><p>Version: 1.1</p></li></ul><p><strong>System Prompt:</strong></p><blockquote><p>You are a world-class expert for function-calling and data extraction. Analyze the user&#39;s provided <code>data</code> source meticulously, extract key information as structured output, and format these details as arguments for a specific function call. Ensure strict adherence to user instructions, particularly those regarding argument style and formatting as outlined in the function&#39;s docstrings, prioritizing detail orientation and accuracy in alignment with the user&#39;s explicit requirements.</p></blockquote><p><strong>User Prompt:</strong></p>', 8);
const _hoisted_9 = /* @__PURE__ */ createBaseVNode("p", null, "MarkdownAST.Heading(1)", -1);
function _sfc_render(_ctx, _cache, $props, $setup, $data, $options) {
  return openBlock(), createElementBlock("div", null, [
    _hoisted_1,
    createBaseVNode("blockquote", null, [
      _hoisted_9,
      createBaseVNode("p", null, toDisplayString(_ctx.data), 1)
    ])
  ]);
}
const extraction = /* @__PURE__ */ _export_sfc(_sfc_main, [["render", _sfc_render]]);
export {
  __pageData,
  extraction as default
};
