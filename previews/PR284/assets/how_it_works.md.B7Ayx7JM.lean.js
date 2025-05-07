import { _ as _export_sfc, c as createElementBlock, o as openBlock, ai as createStaticVNode, j as createBaseVNode, a as createTextVNode, t as toDisplayString } from "./chunks/framework.D43-INTV.js";
const __pageData = JSON.parse('{"title":"How It Works","description":"","frontmatter":{},"headers":[],"relativePath":"how_it_works.md","filePath":"how_it_works.md","lastUpdated":null}');
const _sfc_main = { name: "how_it_works.md" };
function _sfc_render(_ctx, _cache, $props, $setup, $data, $options) {
  return openBlock(), createElementBlock("div", null, [
    _cache[10] || (_cache[10] = createStaticVNode("", 24)),
    createBaseVNode("p", null, [
      _cache[0] || (_cache[0] = createTextVNode('We want to have re-usable "prompts", so we provide you with a system to retrieve pre-defined prompts with placeholders (eg, ')),
      createBaseVNode("code", null, toDisplayString(_ctx.name), 1),
      _cache[1] || (_cache[1] = createTextVNode(") that you can replace with your inputs at the time of making the request."))
    ]),
    _cache[11] || (_cache[11] = createStaticVNode("", 3)),
    createBaseVNode("p", null, [
      _cache[2] || (_cache[2] = createTextVNode("Notice that we have a placeholder ")),
      _cache[3] || (_cache[3] = createBaseVNode("code", null, "ask", -1)),
      _cache[4] || (_cache[4] = createTextVNode(" (")),
      createBaseVNode("code", null, toDisplayString(_ctx.ask), 1),
      _cache[5] || (_cache[5] = createTextVNode(") that you can replace with your question without having to re-write the generic system instructions."))
    ]),
    _cache[12] || (_cache[12] = createStaticVNode("", 64)),
    createBaseVNode("p", null, [
      _cache[6] || (_cache[6] = createTextVNode("Let's define a prompt and ")),
      _cache[7] || (_cache[7] = createBaseVNode("code", null, "return_type", -1)),
      _cache[8] || (_cache[8] = createTextVNode(". Notice that we add several placeholders (eg, ")),
      createBaseVNode("code", null, toDisplayString(_ctx.description), 1),
      _cache[9] || (_cache[9] = createTextVNode(") to fill with user inputs later."))
    ]),
    _cache[13] || (_cache[13] = createStaticVNode("", 16))
  ]);
}
const how_it_works = /* @__PURE__ */ _export_sfc(_sfc_main, [["render", _sfc_render]]);
export {
  __pageData,
  how_it_works as default
};
