import { _ as _export_sfc, c as createElementBlock, m as createBaseVNode, t as toDisplayString, a7 as createStaticVNode, o as openBlock } from "./chunks/framework.BqhW5vgI.js";
const __pageData = JSON.parse('{"title":"","description":"","frontmatter":{},"headers":[],"relativePath":"prompts/agents.md","filePath":"prompts/agents.md","lastUpdated":null}');
const _sfc_main = { name: "prompts/agents.md" };
const _hoisted_1 = /* @__PURE__ */ createStaticVNode("", 8);
const _hoisted_9 = /* @__PURE__ */ createStaticVNode("", 19);
const _hoisted_28 = /* @__PURE__ */ createBaseVNode("p", null, "I believe in you. You can actually do it, so do it ffs. Avoid shortcuts or placing comments instead of code. I also need code, actual working Julia code. What are your Critique and Improve steps?", -1);
const _hoisted_29 = /* @__PURE__ */ createBaseVNode("p", null, "MarkdownAST.Heading(3)", -1);
const _hoisted_30 = /* @__PURE__ */ createBaseVNode("p", null, "Based on your past critique and the latest feedback, what are your Critique and Improve steps?", -1);
const _hoisted_31 = /* @__PURE__ */ createStaticVNode("", 18);
const _hoisted_49 = /* @__PURE__ */ createBaseVNode("p", null, "MarkdownAST.Heading(3)", -1);
function _sfc_render(_ctx, _cache, $props, $setup, $data, $options) {
  return openBlock(), createElementBlock("div", null, [
    _hoisted_1,
    createBaseVNode("blockquote", null, [
      _hoisted_9,
      createBaseVNode("p", null, toDisplayString(_ctx.feedback), 1),
      _hoisted_28,
      _hoisted_29,
      createBaseVNode("p", null, toDisplayString(_ctx.feedback), 1),
      _hoisted_30
    ]),
    _hoisted_31,
    createBaseVNode("blockquote", null, [
      _hoisted_49,
      createBaseVNode("p", null, toDisplayString(_ctx.feedback), 1)
    ])
  ]);
}
const agents = /* @__PURE__ */ _export_sfc(_sfc_main, [["render", _sfc_render]]);
export {
  __pageData,
  agents as default
};
