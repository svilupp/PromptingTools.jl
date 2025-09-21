import { _ as _export_sfc, c as createElementBlock, o as openBlock, ai as createStaticVNode, j as createBaseVNode, a as createTextVNode, t as toDisplayString } from "./chunks/framework.CTGYd72t.js";
const __pageData = JSON.parse('{"title":"Various Examples","description":"","frontmatter":{},"headers":[],"relativePath":"examples/readme_examples.md","filePath":"examples/readme_examples.md","lastUpdated":null}');
const _sfc_main = { name: "examples/readme_examples.md" };
function _sfc_render(_ctx, _cache, $props, $setup, $data, $options) {
  return openBlock(), createElementBlock("div", null, [
    _cache[4] || (_cache[4] = createStaticVNode("", 26)),
    createBaseVNode("p", null, [
      _cache[0] || (_cache[0] = createTextVNode("You can use the ", -1)),
      _cache[1] || (_cache[1] = createBaseVNode("code", null, "aigenerate", -1)),
      _cache[2] || (_cache[2] = createTextVNode(" function to replace handlebar variables (eg, ", -1)),
      createBaseVNode("code", null, toDisplayString(_ctx.name), 1),
      _cache[3] || (_cache[3] = createTextVNode(") via keyword arguments.", -1))
    ]),
    _cache[5] || (_cache[5] = createStaticVNode("", 104))
  ]);
}
const readme_examples = /* @__PURE__ */ _export_sfc(_sfc_main, [["render", _sfc_render]]);
export {
  __pageData,
  readme_examples as default
};
