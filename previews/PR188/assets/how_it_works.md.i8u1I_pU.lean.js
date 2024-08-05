import { _ as _export_sfc, c as createElementBlock, m as createBaseVNode, a as createTextVNode, t as toDisplayString, a7 as createStaticVNode, o as openBlock } from "./chunks/framework.CYJKcgTj.js";
const __pageData = JSON.parse('{"title":"How It Works","description":"","frontmatter":{},"headers":[],"relativePath":"how_it_works.md","filePath":"how_it_works.md","lastUpdated":null}');
const _sfc_main = { name: "how_it_works.md" };
const _hoisted_1 = /* @__PURE__ */ createStaticVNode("", 24);
const _hoisted_25 = /* @__PURE__ */ createStaticVNode("", 3);
const _hoisted_28 = /* @__PURE__ */ createBaseVNode("code", null, "ask", -1);
const _hoisted_29 = /* @__PURE__ */ createStaticVNode("", 64);
const _hoisted_93 = /* @__PURE__ */ createBaseVNode("code", null, "return_type", -1);
const _hoisted_94 = /* @__PURE__ */ createStaticVNode("", 16);
function _sfc_render(_ctx, _cache, $props, $setup, $data, $options) {
  return openBlock(), createElementBlock("div", null, [
    _hoisted_1,
    createBaseVNode("p", null, [
      createTextVNode('We want to have re-usable "prompts", so we provide you with a system to retrieve pre-defined prompts with placeholders (eg, '),
      createBaseVNode("code", null, toDisplayString(_ctx.name), 1),
      createTextVNode(") that you can replace with your inputs at the time of making the request.")
    ]),
    _hoisted_25,
    createBaseVNode("p", null, [
      createTextVNode("Notice that we have a placeholder "),
      _hoisted_28,
      createTextVNode(" ("),
      createBaseVNode("code", null, toDisplayString(_ctx.ask), 1),
      createTextVNode(") that you can replace with your question without having to re-write the generic system instructions.")
    ]),
    _hoisted_29,
    createBaseVNode("p", null, [
      createTextVNode("Let's define a prompt and "),
      _hoisted_93,
      createTextVNode(". Notice that we add several placeholders (eg, "),
      createBaseVNode("code", null, toDisplayString(_ctx.description), 1),
      createTextVNode(") to fill with user inputs later.")
    ]),
    _hoisted_94
  ]);
}
const how_it_works = /* @__PURE__ */ _export_sfc(_sfc_main, [["render", _sfc_render]]);
export {
  __pageData,
  how_it_works as default
};
