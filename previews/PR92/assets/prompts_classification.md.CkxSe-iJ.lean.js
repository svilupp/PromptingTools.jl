import { _ as _export_sfc, c as createElementBlock, m as createBaseVNode, t as toDisplayString, a7 as createStaticVNode, o as openBlock } from "./chunks/framework.BqhW5vgI.js";
const __pageData = JSON.parse('{"title":"","description":"","frontmatter":{},"headers":[],"relativePath":"prompts/classification.md","filePath":"prompts/classification.md","lastUpdated":null}');
const _sfc_main = { name: "prompts/classification.md" };
const _hoisted_1 = /* @__PURE__ */ createStaticVNode("", 8);
const _hoisted_9 = /* @__PURE__ */ createBaseVNode("p", null, "Label:", -1);
const _hoisted_10 = /* @__PURE__ */ createStaticVNode("", 5);
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
