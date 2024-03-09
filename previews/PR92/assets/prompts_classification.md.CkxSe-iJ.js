import { _ as _export_sfc, c as createElementBlock, m as createBaseVNode, t as toDisplayString, a7 as createStaticVNode, o as openBlock } from "./chunks/framework.BqhW5vgI.js";
const __pageData = JSON.parse('{"title":"","description":"","frontmatter":{},"headers":[],"relativePath":"prompts/classification.md","filePath":"prompts/classification.md","lastUpdated":null}');
const _sfc_main = { name: "prompts/classification.md" };
const _hoisted_1 = /* @__PURE__ */ createStaticVNode('<p>The following file is auto-generated from the <code>templates</code> folder. For any changes, please modify the source files in the <code>templates</code> folder.</p><p>To use these templates in <code>aigenerate</code>, simply provide the template name as a symbol, eg, <code>aigenerate(:MyTemplate; placeholder1 = value1)</code></p><h2 id="classification-templates-classification-templates" tabindex="-1">Classification Templates {#Classification-Templates} <a class="header-anchor" href="#classification-templates-classification-templates" aria-label="Permalink to &quot;Classification Templates {#Classification-Templates}&quot;">​</a></h2><h3 id="template-inputclassifier-template-inputclassifier" tabindex="-1">Template: InputClassifier {#Template:-InputClassifier} <a class="header-anchor" href="#template-inputclassifier-template-inputclassifier" aria-label="Permalink to &quot;Template: InputClassifier {#Template:-InputClassifier}&quot;">​</a></h3><ul><li><p>Description: For classification tasks and routing of queries with aiclassify. It expects a list of choices to be provided (starting with their IDs) and will pick one that best describes the user input. Placeholders: <code>input</code>, <code>choices</code></p></li><li><p>Placeholders: <code>choices</code>, <code>input</code></p></li><li><p>Word count: 366</p></li><li><p>Source:</p></li><li><p>Version: 1.1</p></li></ul><p><strong>System Prompt:</strong></p><blockquote><p>You are a world-class classification specialist.</p><p>Your task is to select the most appropriate label from the given choices for the given user input.</p><p>MarkdownAST.Heading(2)</p><p>MarkdownAST.Heading(2)</p><p><strong>Instructions:</strong></p><ul><li><p>You must respond in one word.</p></li><li><p>You must respond only with the label ID (e.g., &quot;1&quot;, &quot;2&quot;, ...) that best fits the input.</p></li></ul></blockquote><p><strong>User Prompt:</strong></p>', 8);
const _hoisted_9 = /* @__PURE__ */ createBaseVNode("p", null, "Label:", -1);
const _hoisted_10 = /* @__PURE__ */ createStaticVNode('<h3 id="template-judgeisittrue-template-judgeisittrue" tabindex="-1">Template: JudgeIsItTrue {#Template:-JudgeIsItTrue} <a class="header-anchor" href="#template-judgeisittrue-template-judgeisittrue" aria-label="Permalink to &quot;Template: JudgeIsItTrue {#Template:-JudgeIsItTrue}&quot;">​</a></h3><ul><li><p>Description: LLM-based classification whether the provided statement is true/false/unknown. Statement is provided via <code>it</code> placeholder.</p></li><li><p>Placeholders: <code>it</code></p></li><li><p>Word count: 151</p></li><li><p>Source:</p></li><li><p>Version: 1.1</p></li></ul><p><strong>System Prompt:</strong></p><blockquote><p>You are an impartial AI judge evaluating whether the provided statement is &quot;true&quot; or &quot;false&quot;. Answer &quot;unknown&quot; if you cannot decide.</p></blockquote><p><strong>User Prompt:</strong></p>', 5);
const _hoisted_15 = /* @__PURE__ */ createBaseVNode("p", null, "MarkdownAST.Heading(1)", -1);
function _sfc_render(_ctx, _cache, $props, $setup, $data, $options) {
  return openBlock(), createElementBlock("div", null, [
    _hoisted_1,
    createBaseVNode("blockquote", null, [
      createBaseVNode("p", null, "User Input: " + toDisplayString(_ctx.input), 1),
      _hoisted_9
    ]),
    _hoisted_10,
    createBaseVNode("blockquote", null, [
      _hoisted_15,
      createBaseVNode("p", null, toDisplayString(_ctx.it), 1)
    ])
  ]);
}
const classification = /* @__PURE__ */ _export_sfc(_sfc_main, [["render", _sfc_render]]);
export {
  __pageData,
  classification as default
};
