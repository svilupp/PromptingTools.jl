import { _ as _export_sfc, c as createElementBlock, m as createBaseVNode, t as toDisplayString, a7 as createStaticVNode, o as openBlock } from "./chunks/framework.BqhW5vgI.js";
const __pageData = JSON.parse('{"title":"","description":"","frontmatter":{},"headers":[],"relativePath":"prompts/general.md","filePath":"prompts/general.md","lastUpdated":null}');
const _sfc_main = { name: "prompts/general.md" };
const _hoisted_1 = /* @__PURE__ */ createStaticVNode("", 6);
const _hoisted_7 = /* @__PURE__ */ createBaseVNode("p", null, [
  /* @__PURE__ */ createBaseVNode("strong", null, "User Prompt:")
], -1);
const _hoisted_8 = /* @__PURE__ */ createStaticVNode("", 5);
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
