import { _ as _export_sfc, c as createElementBlock, m as createBaseVNode, t as toDisplayString, a7 as createStaticVNode, o as openBlock } from "./chunks/framework.BqhW5vgI.js";
const __pageData = JSON.parse('{"title":"","description":"","frontmatter":{},"headers":[],"relativePath":"prompts/general.md","filePath":"prompts/general.md","lastUpdated":null}');
const _sfc_main = { name: "prompts/general.md" };
const _hoisted_1 = /* @__PURE__ */ createStaticVNode('<p>The following file is auto-generated from the <code>templates</code> folder. For any changes, please modify the source files in the <code>templates</code> folder.</p><p>To use these templates in <code>aigenerate</code>, simply provide the template name as a symbol, eg, <code>aigenerate(:MyTemplate; placeholder1 = value1)</code></p><h2 id="general-templates-general-templates" tabindex="-1">General Templates {#General-Templates} <a class="header-anchor" href="#general-templates-general-templates" aria-label="Permalink to &quot;General Templates {#General-Templates}&quot;">​</a></h2><h3 id="template-blanksystemuser-template-blanksystemuser" tabindex="-1">Template: BlankSystemUser {#Template:-BlankSystemUser} <a class="header-anchor" href="#template-blanksystemuser-template-blanksystemuser" aria-label="Permalink to &quot;Template: BlankSystemUser {#Template:-BlankSystemUser}&quot;">​</a></h3><ul><li><p>Description: Blank template for easy prompt entry without the <code>*Message</code> objects. Simply provide keyword arguments for <code>system</code> (=system prompt/persona) and <code>user</code> (=user/task/data prompt). Placeholders: <code>system</code>, <code>user</code></p></li><li><p>Placeholders: <code>system</code>, <code>user</code></p></li><li><p>Word count: 18</p></li><li><p>Source:</p></li><li><p>Version: 1.1</p></li></ul><p><strong>System Prompt:</strong></p>', 6);
const _hoisted_7 = /* @__PURE__ */ createBaseVNode("p", null, [
  /* @__PURE__ */ createBaseVNode("strong", null, "User Prompt:")
], -1);
const _hoisted_8 = /* @__PURE__ */ createStaticVNode('<h3 id="template-promptengineerfortask-template-promptengineerfortask" tabindex="-1">Template: PromptEngineerForTask {#Template:-PromptEngineerForTask} <a class="header-anchor" href="#template-promptengineerfortask-template-promptengineerfortask" aria-label="Permalink to &quot;Template: PromptEngineerForTask {#Template:-PromptEngineerForTask}&quot;">​</a></h3><ul><li><p>Description: Prompt engineer that suggests what could be a good system prompt/user prompt for a given <code>task</code>. Placeholder: <code>task</code></p></li><li><p>Placeholders: <code>task</code></p></li><li><p>Word count: 402</p></li><li><p>Source:</p></li><li><p>Version: 1</p></li></ul><p><strong>System Prompt:</strong></p><blockquote><p>You are a world-class prompt engineering assistant. Generate a clear, effective prompt that accurately interprets and structures the user&#39;s task, ensuring it is comprehensive, actionable, and tailored to elicit the most relevant and precise output from an AI model. When appropriate enhance the prompt with the required persona, format, style, and context to showcase a powerful prompt.</p></blockquote><p><strong>User Prompt:</strong></p>', 5);
const _hoisted_13 = /* @__PURE__ */ createBaseVNode("p", null, "MarkdownAST.Heading(1)", -1);
function _sfc_render(_ctx, _cache, $props, $setup, $data, $options) {
  return openBlock(), createElementBlock("div", null, [
    _hoisted_1,
    createBaseVNode("blockquote", null, [
      createBaseVNode("p", null, toDisplayString(_ctx.system), 1)
    ]),
    _hoisted_7,
    createBaseVNode("blockquote", null, [
      createBaseVNode("p", null, toDisplayString(_ctx.user), 1)
    ]),
    _hoisted_8,
    createBaseVNode("blockquote", null, [
      _hoisted_13,
      createBaseVNode("p", null, toDisplayString(_ctx.task), 1)
    ])
  ]);
}
const general = /* @__PURE__ */ _export_sfc(_sfc_main, [["render", _sfc_render]]);
export {
  __pageData,
  general as default
};
