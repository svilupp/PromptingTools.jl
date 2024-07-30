import { _ as _export_sfc, c as createElementBlock, m as createBaseVNode, a as createTextVNode, t as toDisplayString, a7 as createStaticVNode, o as openBlock } from "./chunks/framework.Cd2NaM5v.js";
const __pageData = JSON.parse('{"title":"Various Examples","description":"","frontmatter":{},"headers":[],"relativePath":"examples/readme_examples.md","filePath":"examples/readme_examples.md","lastUpdated":null}');
const _sfc_main = { name: "examples/readme_examples.md" };
const _hoisted_1 = /* @__PURE__ */ createStaticVNode("", 28);
const _hoisted_29 = /* @__PURE__ */ createBaseVNode("code", null, "aigenerate", -1);
const _hoisted_30 = /* @__PURE__ */ createStaticVNode("", 104);
function _sfc_render(_ctx, _cache, $props, $setup, $data, $options) {
  return openBlock(), createElementBlock("div", null, [
    _hoisted_1,
    createBaseVNode("p", null, [
      createTextVNode("You can use the "),
      _hoisted_29,
      createTextVNode(" function to replace handlebar variables (eg, "),
      createBaseVNode("code", null, toDisplayString(_ctx.name), 1),
      createTextVNode(") via keyword arguments.")
    ]),
    _hoisted_30
  ]);
}
const readme_examples = /* @__PURE__ */ _export_sfc(_sfc_main, [["render", _sfc_render]]);
export {
  __pageData,
  readme_examples as default
};
