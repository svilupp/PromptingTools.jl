import { _ as _export_sfc, c as createElementBlock, o as openBlock, ai as createStaticVNode, j as createBaseVNode, a as createTextVNode, t as toDisplayString } from "./chunks/framework.DEs4tLG6.js";
const __pageData = JSON.parse('{"title":"Theme 1: [Theme Description]","description":"","frontmatter":{},"headers":[],"relativePath":"prompts/persona-task.md","filePath":"prompts/persona-task.md","lastUpdated":null}');
const _sfc_main = { name: "prompts/persona-task.md" };
function _sfc_render(_ctx, _cache, $props, $setup, $data, $options) {
  return openBlock(), createElementBlock("div", null, [
    _cache[31] || (_cache[31] = createStaticVNode("", 10)),
    createBaseVNode("ul", null, [
      createBaseVNode("li", null, [
        createBaseVNode("p", null, [
          _cache[0] || (_cache[0] = createTextVNode("Description: Template for summarizing transcripts of videos and meetings into the decisions made and the agreed next steps. If you don't need the instructions, set ", -1)),
          _cache[1] || (_cache[1] = createBaseVNode("code", null, 'instructions="None."', -1)),
          createTextVNode(". Placeholders: " + toDisplayString(_ctx.transcript) + ", " + toDisplayString(_ctx.instructions), 1)
        ])
      ]),
      _cache[2] || (_cache[2] = createBaseVNode("li", null, [
        createBaseVNode("p", null, [
          createTextVNode("Placeholders: "),
          createBaseVNode("code", null, "transcript"),
          createTextVNode(", "),
          createBaseVNode("code", null, "instructions")
        ])
      ], -1)),
      _cache[3] || (_cache[3] = createBaseVNode("li", null, [
        createBaseVNode("p", null, "Word count: 2190")
      ], -1)),
      _cache[4] || (_cache[4] = createBaseVNode("li", null, [
        createBaseVNode("p", null, [
          createTextVNode("Source: Evolved from "),
          createBaseVNode("a", {
            href: "https://github.com/jxnl/youtubechapters-backend/blob/main/summary_app/md_summarize.py",
            target: "_blank",
            rel: "noreferrer"
          }, "jxnl's Youtube Chapters prompt")
        ])
      ], -1)),
      _cache[5] || (_cache[5] = createBaseVNode("li", null, [
        createBaseVNode("p", null, "Version: 1.1")
      ], -1))
    ]),
    _cache[32] || (_cache[32] = createStaticVNode("", 5)),
    createBaseVNode("ul", null, [
      createBaseVNode("li", null, [
        createBaseVNode("p", null, [
          _cache[6] || (_cache[6] = createTextVNode("Description: Template for summarizing survey verbatim responses into 3-5 themes with an example for each theme. If you don't need the instructions, set ", -1)),
          _cache[7] || (_cache[7] = createBaseVNode("code", null, 'instructions="None."', -1)),
          createTextVNode(". Placeholders: " + toDisplayString(_ctx.question) + ", " + toDisplayString(_ctx.responses) + ", " + toDisplayString(_ctx.instructions), 1)
        ])
      ]),
      _cache[8] || (_cache[8] = createStaticVNode("", 4))
    ]),
    _cache[33] || (_cache[33] = createStaticVNode("", 28)),
    createBaseVNode("ul", null, [
      createBaseVNode("li", null, [
        createBaseVNode("p", null, [
          _cache[9] || (_cache[9] = createTextVNode("Description: Template for quick email drafts. Provide a brief in 5-7 words as headlines, eg, ", -1)),
          _cache[10] || (_cache[10] = createBaseVNode("code", null, "Follow up email. Sections: Agreements, Next steps", -1)),
          createTextVNode(" Placeholders: " + toDisplayString(_ctx.brief), 1)
        ])
      ]),
      _cache[11] || (_cache[11] = createBaseVNode("li", null, [
        createBaseVNode("p", null, [
          createTextVNode("Placeholders: "),
          createBaseVNode("code", null, "brief")
        ])
      ], -1)),
      _cache[12] || (_cache[12] = createBaseVNode("li", null, [
        createBaseVNode("p", null, "Word count: 1501")
      ], -1)),
      _cache[13] || (_cache[13] = createBaseVNode("li", null, [
        createBaseVNode("p", null, "Source:")
      ], -1)),
      _cache[14] || (_cache[14] = createBaseVNode("li", null, [
        createBaseVNode("p", null, "Version: 1.2")
      ], -1))
    ]),
    _cache[34] || (_cache[34] = createStaticVNode("", 41)),
    createBaseVNode("ul", null, [
      createBaseVNode("li", null, [
        createBaseVNode("p", null, [
          _cache[15] || (_cache[15] = createTextVNode("Description: For writing Julia-style unit tests. It expects ", -1)),
          _cache[16] || (_cache[16] = createBaseVNode("code", null, "code", -1)),
          _cache[17] || (_cache[17] = createTextVNode(" provided as a string (it can be the whole source code of your app). Instructions are a good way to guide the model which functions to test and how. If you don't need the instructions, set ", -1)),
          _cache[18] || (_cache[18] = createBaseVNode("code", null, 'instructions="None."', -1)),
          createTextVNode(". Placeholders: " + toDisplayString(_ctx.code) + ", " + toDisplayString(_ctx.instructions), 1)
        ])
      ]),
      _cache[19] || (_cache[19] = createBaseVNode("li", null, [
        createBaseVNode("p", null, [
          createTextVNode("Placeholders: "),
          createBaseVNode("code", null, "code"),
          createTextVNode(", "),
          createBaseVNode("code", null, "instructions")
        ])
      ], -1)),
      _cache[20] || (_cache[20] = createBaseVNode("li", null, [
        createBaseVNode("p", null, "Word count: 1475")
      ], -1)),
      _cache[21] || (_cache[21] = createBaseVNode("li", null, [
        createBaseVNode("p", null, "Source:")
      ], -1)),
      _cache[22] || (_cache[22] = createBaseVNode("li", null, [
        createBaseVNode("p", null, "Version: 1.1")
      ], -1))
    ]),
    _cache[35] || (_cache[35] = createStaticVNode("", 42)),
    createBaseVNode("ul", null, [
      createBaseVNode("li", null, [
        createBaseVNode("p", null, [
          _cache[23] || (_cache[23] = createTextVNode("Description: For writing Julia-style unit tests. The prompt is XML-formatted - useful for Anthropic models. It expects ", -1)),
          _cache[24] || (_cache[24] = createBaseVNode("code", null, "code", -1)),
          _cache[25] || (_cache[25] = createTextVNode(" provided as a string (it can be the whole source code of your app). Instructions are a good way to guide the model which functions to test and how. If you don't need the instructions, set ", -1)),
          _cache[26] || (_cache[26] = createBaseVNode("code", null, 'instructions="None."', -1)),
          createTextVNode(". Placeholders: " + toDisplayString(_ctx.code) + ", " + toDisplayString(_ctx.instructions), 1)
        ])
      ]),
      _cache[27] || (_cache[27] = createBaseVNode("li", null, [
        createBaseVNode("p", null, [
          createTextVNode("Placeholders: "),
          createBaseVNode("code", null, "code"),
          createTextVNode(", "),
          createBaseVNode("code", null, "instructions")
        ])
      ], -1)),
      _cache[28] || (_cache[28] = createBaseVNode("li", null, [
        createBaseVNode("p", null, "Word count: 1643")
      ], -1)),
      _cache[29] || (_cache[29] = createBaseVNode("li", null, [
        createBaseVNode("p", null, "Source:")
      ], -1)),
      _cache[30] || (_cache[30] = createBaseVNode("li", null, [
        createBaseVNode("p", null, "Version: 1.0")
      ], -1))
    ]),
    _cache[36] || (_cache[36] = createStaticVNode("", 4))
  ]);
}
const personaTask = /* @__PURE__ */ _export_sfc(_sfc_main, [["render", _sfc_render]]);
export {
  __pageData,
  personaTask as default
};
