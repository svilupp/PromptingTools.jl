import { _ as _export_sfc, c as createElementBlock, o as openBlock, ai as createStaticVNode, j as createBaseVNode, a as createTextVNode, t as toDisplayString } from "./chunks/framework.O_ioDgiM.js";
const __pageData = JSON.parse('{"title":"Reference","description":"","frontmatter":{"outline":"deep"},"headers":[],"relativePath":"reference.md","filePath":"reference.md","lastUpdated":null}');
const _sfc_main = { name: "reference.md" };
const _hoisted_1 = { style: { "border-width": "1px", "border-style": "solid", "border-color": "black", "padding": "1em", "border-radius": "25px" } };
const _hoisted_2 = { style: { "border-width": "1px", "border-style": "solid", "border-color": "black", "padding": "1em", "border-radius": "25px" } };
const _hoisted_3 = { style: { "border-width": "1px", "border-style": "solid", "border-color": "black", "padding": "1em", "border-radius": "25px" } };
const _hoisted_4 = { style: { "border-width": "1px", "border-style": "solid", "border-color": "black", "padding": "1em", "border-radius": "25px" } };
const _hoisted_5 = { style: { "border-width": "1px", "border-style": "solid", "border-color": "black", "padding": "1em", "border-radius": "25px" } };
const _hoisted_6 = { style: { "border-width": "1px", "border-style": "solid", "border-color": "black", "padding": "1em", "border-radius": "25px" } };
const _hoisted_7 = { style: { "border-width": "1px", "border-style": "solid", "border-color": "black", "padding": "1em", "border-radius": "25px" } };
const _hoisted_8 = { style: { "border-width": "1px", "border-style": "solid", "border-color": "black", "padding": "1em", "border-radius": "25px" } };
const _hoisted_9 = { style: { "border-width": "1px", "border-style": "solid", "border-color": "black", "padding": "1em", "border-radius": "25px" } };
function _sfc_render(_ctx, _cache, $props, $setup, $data, $options) {
  return openBlock(), createElementBlock("div", null, [
    _cache[47] || (_cache[47] = createStaticVNode("", 46)),
    createBaseVNode("div", _hoisted_1, [
      _cache[4] || (_cache[4] = createStaticVNode("", 11)),
      createBaseVNode("p", null, [
        _cache[0] || (_cache[0] = createTextVNode("It's recommended to separate sections in your prompt with XML markup (e.g. ", -1)),
        createBaseVNode("code", null, "<document> " + toDisplayString(_ctx.document) + " </document>", 1),
        _cache[1] || (_cache[1] = createTextVNode("). See ", -1)),
        _cache[2] || (_cache[2] = createBaseVNode("a", {
          href: "https://docs.anthropic.com/claude/docs/use-xml-tags",
          target: "_blank",
          rel: "noreferrer"
        }, "here", -1)),
        _cache[3] || (_cache[3] = createTextVNode(".", -1))
      ]),
      _cache[5] || (_cache[5] = createBaseVNode("p", null, [
        createBaseVNode("a", {
          href: "https://github.com/svilupp/PromptingTools.jl/blob/da7e7e8e605d4424e39f074b054d7195a036754c/src/llm_interface.jl#L421-L435",
          target: "_blank",
          rel: "noreferrer"
        }, "source")
      ], -1))
    ]),
    _cache[48] || (_cache[48] = createStaticVNode("", 129)),
    createBaseVNode("div", _hoisted_2, [
      _cache[10] || (_cache[10] = createStaticVNode("", 9)),
      createBaseVNode("p", null, [
        _cache[6] || (_cache[6] = createTextVNode("!!! Note: The prompt/AITemplate must have a placeholder ", -1)),
        _cache[7] || (_cache[7] = createBaseVNode("code", null, "choices", -1)),
        _cache[8] || (_cache[8] = createTextVNode(" (ie, ", -1)),
        createBaseVNode("code", null, toDisplayString(_ctx.choices), 1),
        _cache[9] || (_cache[9] = createTextVNode(") that will be replaced with the encoded choices", -1))
      ]),
      _cache[11] || (_cache[11] = createStaticVNode("", 21))
    ]),
    _cache[49] || (_cache[49] = createStaticVNode("", 85)),
    createBaseVNode("div", _hoisted_3, [
      _cache[16] || (_cache[16] = createStaticVNode("", 10)),
      createBaseVNode("p", null, [
        _cache[12] || (_cache[12] = createTextVNode("Use double handlebar placeholders (eg, ", -1)),
        createBaseVNode("code", null, toDisplayString(_ctx.name), 1),
        _cache[13] || (_cache[13] = createTextVNode(") to define variables that can be replaced by the ", -1)),
        _cache[14] || (_cache[14] = createBaseVNode("code", null, "kwargs", -1)),
        _cache[15] || (_cache[15] = createTextVNode(" during the AI call (see example).", -1))
      ]),
      _cache[17] || (_cache[17] = createStaticVNode("", 19))
    ]),
    _cache[50] || (_cache[50] = createStaticVNode("", 131)),
    createBaseVNode("div", _hoisted_4, [
      _cache[20] || (_cache[20] = createStaticVNode("", 7)),
      createBaseVNode("p", null, [
        _cache[18] || (_cache[18] = createTextVNode("Builds a history of the conversation to provide the prompt to the API. All unspecified kwargs are passed as replacements such that ", -1)),
        createBaseVNode("code", null, toDisplayString(_ctx.key) + "=>value", 1),
        _cache[19] || (_cache[19] = createTextVNode(" in the template.", -1))
      ]),
      _cache[21] || (_cache[21] = createStaticVNode("", 3))
    ]),
    _cache[51] || (_cache[51] = createStaticVNode("", 3)),
    createBaseVNode("div", _hoisted_5, [
      _cache[24] || (_cache[24] = createStaticVNode("", 7)),
      createBaseVNode("p", null, [
        _cache[22] || (_cache[22] = createTextVNode("Builds a history of the conversation to provide the prompt to the API. All unspecified kwargs are passed as replacements such that ", -1)),
        createBaseVNode("code", null, toDisplayString(_ctx.key) + "=>value", 1),
        _cache[23] || (_cache[23] = createTextVNode(" in the template.", -1))
      ]),
      _cache[25] || (_cache[25] = createStaticVNode("", 3))
    ]),
    _cache[52] || (_cache[52] = createBaseVNode("br", null, null, -1)),
    createBaseVNode("div", _hoisted_6, [
      _cache[28] || (_cache[28] = createStaticVNode("", 7)),
      createBaseVNode("p", null, [
        _cache[26] || (_cache[26] = createTextVNode("Builds a history of the conversation to provide the prompt to the API. All unspecified kwargs are passed as replacements such that ", -1)),
        createBaseVNode("code", null, toDisplayString(_ctx.key) + "=>value", 1),
        _cache[27] || (_cache[27] = createTextVNode(" in the template.", -1))
      ]),
      _cache[29] || (_cache[29] = createBaseVNode("p", null, [
        createTextVNode('Note: Due to its "managed" nature, at most 2 messages can be provided ('),
        createBaseVNode("code", null, "system"),
        createTextVNode(" and "),
        createBaseVNode("code", null, "prompt"),
        createTextVNode(" inputs in the API).")
      ], -1)),
      _cache[30] || (_cache[30] = createBaseVNode("p", null, [
        createBaseVNode("strong", null, "Keyword Arguments")
      ], -1)),
      _cache[31] || (_cache[31] = createBaseVNode("ul", null, [
        createBaseVNode("li", null, [
          createBaseVNode("code", null, "conversation"),
          createTextVNode(": Not allowed for this schema. Provided only for compatibility.")
        ])
      ], -1)),
      _cache[32] || (_cache[32] = createBaseVNode("p", null, [
        createBaseVNode("a", {
          href: "https://github.com/svilupp/PromptingTools.jl/blob/da7e7e8e605d4424e39f074b054d7195a036754c/src/llm_ollama_managed.jl#L9-L21",
          target: "_blank",
          rel: "noreferrer"
        }, "source")
      ], -1))
    ]),
    _cache[53] || (_cache[53] = createBaseVNode("br", null, null, -1)),
    createBaseVNode("div", _hoisted_7, [
      _cache[35] || (_cache[35] = createStaticVNode("", 7)),
      createBaseVNode("p", null, [
        _cache[33] || (_cache[33] = createTextVNode("Builds a history of the conversation to provide the prompt to the API. All unspecified kwargs are passed as replacements such that ", -1)),
        createBaseVNode("code", null, toDisplayString(_ctx.key) + "=>value", 1),
        _cache[34] || (_cache[34] = createTextVNode(" in the template.", -1))
      ]),
      _cache[36] || (_cache[36] = createStaticVNode("", 3))
    ]),
    _cache[54] || (_cache[54] = createStaticVNode("", 3)),
    createBaseVNode("div", _hoisted_8, [
      _cache[39] || (_cache[39] = createStaticVNode("", 7)),
      createBaseVNode("p", null, [
        _cache[37] || (_cache[37] = createTextVNode("Builds a history of the conversation to provide the prompt to the API. All unspecified kwargs are passed as replacements such that ", -1)),
        createBaseVNode("code", null, toDisplayString(_ctx.key) + "=>value", 1),
        _cache[38] || (_cache[38] = createTextVNode(" in the template.", -1))
      ]),
      _cache[40] || (_cache[40] = createStaticVNode("", 3))
    ]),
    _cache[55] || (_cache[55] = createStaticVNode("", 5)),
    createBaseVNode("div", _hoisted_9, [
      _cache[45] || (_cache[45] = createStaticVNode("", 12)),
      createBaseVNode("ul", null, [
        createBaseVNode("li", null, [
          createBaseVNode("p", null, [
            _cache[41] || (_cache[41] = createTextVNode("All unspecified kwargs are passed as replacements such that ", -1)),
            createBaseVNode("code", null, toDisplayString(_ctx.key) + "=>value", 1),
            _cache[42] || (_cache[42] = createTextVNode(" in the template.", -1))
          ])
        ]),
        _cache[43] || (_cache[43] = createBaseVNode("li", null, [
          createBaseVNode("p", null, "If a SystemMessage is missing, we inject a default one at the beginning of the conversation.")
        ], -1)),
        _cache[44] || (_cache[44] = createBaseVNode("li", null, [
          createBaseVNode("p", null, "Only one SystemMessage is allowed (ie, cannot mix two conversations different system prompts).")
        ], -1))
      ]),
      _cache[46] || (_cache[46] = createBaseVNode("p", null, [
        createBaseVNode("a", {
          href: "https://github.com/svilupp/PromptingTools.jl/blob/da7e7e8e605d4424e39f074b054d7195a036754c/src/llm_shared.jl#L12-L32",
          target: "_blank",
          rel: "noreferrer"
        }, "source")
      ], -1))
    ]),
    _cache[56] || (_cache[56] = createStaticVNode("", 19)),
    _cache[57] || (_cache[57] = createBaseVNode("div", { style: { "border-width": "1px", "border-style": "solid", "border-color": "black", "padding": "1em", "border-radius": "25px" } }, [
      createBaseVNode("a", {
        id: "PromptingTools.tool_call_signature-Tuple{Union{Method, Type}}",
        href: "#PromptingTools.tool_call_signature-Tuple{Union{Method, Type}}"
      }, "#"),
      createTextVNode(" "),
      createBaseVNode("b", null, [
        createBaseVNode("u", null, "PromptingTools.tool_call_signature")
      ]),
      createTextVNode(" — "),
      createBaseVNode("i", null, "Method"),
      createTextVNode(". "),
      createBaseVNode("div", { class: "language-julia vp-adaptive-theme" }, [
        createBaseVNode("button", {
          title: "Copy Code",
          class: "copy"
        }),
        createBaseVNode("span", { class: "lang" }, "julia"),
        createBaseVNode("pre", {
          class: "shiki shiki-themes github-light github-dark vp-code",
          tabindex: "0"
        }, [
          createBaseVNode("code", null, [
            createBaseVNode("span", { class: "line" }, [
              createBaseVNode("span", { style: { "--shiki-light": "#005CC5", "--shiki-dark": "#79B8FF" } }, "tool_call_signature"),
              createBaseVNode("span", { style: { "--shiki-light": "#24292E", "--shiki-dark": "#E1E4E8" } }, "(")
            ]),
            createTextVNode("\n"),
            createBaseVNode("span", { class: "line" }, [
              createBaseVNode("span", { style: { "--shiki-light": "#24292E", "--shiki-dark": "#E1E4E8" } }, "    type_or_method"),
              createBaseVNode("span", { style: { "--shiki-light": "#D73A49", "--shiki-dark": "#F97583" } }, "::"),
              createBaseVNode("span", { style: { "--shiki-light": "#005CC5", "--shiki-dark": "#79B8FF" } }, "Union{Type, Method}"),
              createBaseVNode("span", { style: { "--shiki-light": "#24292E", "--shiki-dark": "#E1E4E8" } }, "; strict"),
              createBaseVNode("span", { style: { "--shiki-light": "#D73A49", "--shiki-dark": "#F97583" } }, "::"),
              createBaseVNode("span", { style: { "--shiki-light": "#005CC5", "--shiki-dark": "#79B8FF" } }, "Union{Nothing, Bool}"),
              createBaseVNode("span", { style: { "--shiki-light": "#D73A49", "--shiki-dark": "#F97583" } }, " ="),
              createBaseVNode("span", { style: { "--shiki-light": "#005CC5", "--shiki-dark": "#79B8FF" } }, " nothing"),
              createBaseVNode("span", { style: { "--shiki-light": "#24292E", "--shiki-dark": "#E1E4E8" } }, ",")
            ]),
            createTextVNode("\n"),
            createBaseVNode("span", { class: "line" }, [
              createBaseVNode("span", { style: { "--shiki-light": "#24292E", "--shiki-dark": "#E1E4E8" } }, "    max_description_length"),
              createBaseVNode("span", { style: { "--shiki-light": "#D73A49", "--shiki-dark": "#F97583" } }, "::"),
              createBaseVNode("span", { style: { "--shiki-light": "#005CC5", "--shiki-dark": "#79B8FF" } }, "Int"),
              createBaseVNode("span", { style: { "--shiki-light": "#D73A49", "--shiki-dark": "#F97583" } }, " ="),
              createBaseVNode("span", { style: { "--shiki-light": "#005CC5", "--shiki-dark": "#79B8FF" } }, " 200"),
              createBaseVNode("span", { style: { "--shiki-light": "#24292E", "--shiki-dark": "#E1E4E8" } }, ", name"),
              createBaseVNode("span", { style: { "--shiki-light": "#D73A49", "--shiki-dark": "#F97583" } }, "::"),
              createBaseVNode("span", { style: { "--shiki-light": "#005CC5", "--shiki-dark": "#79B8FF" } }, "Union{Nothing, String}"),
              createBaseVNode("span", { style: { "--shiki-light": "#D73A49", "--shiki-dark": "#F97583" } }, " ="),
              createBaseVNode("span", { style: { "--shiki-light": "#005CC5", "--shiki-dark": "#79B8FF" } }, " nothing"),
              createBaseVNode("span", { style: { "--shiki-light": "#24292E", "--shiki-dark": "#E1E4E8" } }, ",")
            ]),
            createTextVNode("\n"),
            createBaseVNode("span", { class: "line" }, [
              createBaseVNode("span", { style: { "--shiki-light": "#24292E", "--shiki-dark": "#E1E4E8" } }, "    docs"),
              createBaseVNode("span", { style: { "--shiki-light": "#D73A49", "--shiki-dark": "#F97583" } }, "::"),
              createBaseVNode("span", { style: { "--shiki-light": "#005CC5", "--shiki-dark": "#79B8FF" } }, "Union{Nothing, String}"),
              createBaseVNode("span", { style: { "--shiki-light": "#D73A49", "--shiki-dark": "#F97583" } }, " ="),
              createBaseVNode("span", { style: { "--shiki-light": "#005CC5", "--shiki-dark": "#79B8FF" } }, " nothing"),
              createBaseVNode("span", { style: { "--shiki-light": "#24292E", "--shiki-dark": "#E1E4E8" } }, ", hidden_fields"),
              createBaseVNode("span", { style: { "--shiki-light": "#D73A49", "--shiki-dark": "#F97583" } }, "::"),
              createBaseVNode("span", { style: { "--shiki-light": "#005CC5", "--shiki-dark": "#79B8FF" } }, "AbstractVector"),
              createBaseVNode("span", { style: { "--shiki-light": "#24292E", "--shiki-dark": "#E1E4E8" } }, "{"),
              createBaseVNode("span", { style: { "--shiki-light": "#D73A49", "--shiki-dark": "#F97583" } }, "<:"),
              createBaseVNode("span", { style: { "--shiki-light": "#005CC5", "--shiki-dark": "#79B8FF" } }, "Union"),
              createBaseVNode("span", { style: { "--shiki-light": "#24292E", "--shiki-dark": "#E1E4E8" } }, "{")
            ]),
            createTextVNode("\n"),
            createBaseVNode("span", { class: "line" }, [
              createBaseVNode("span", { style: { "--shiki-light": "#24292E", "--shiki-dark": "#E1E4E8" } }, "        AbstractString, Regex}} "),
              createBaseVNode("span", { style: { "--shiki-light": "#D73A49", "--shiki-dark": "#F97583" } }, "="),
              createBaseVNode("span", { style: { "--shiki-light": "#24292E", "--shiki-dark": "#E1E4E8" } }, " String[])")
            ])
          ])
        ])
      ]),
      createBaseVNode("p", null, "Extract the argument names, types and docstrings from a struct to create the function call signature in JSON schema."),
      createBaseVNode("p", null, "You must provide a Struct type (not an instance of it) with some fields. The types must be CONCRETE, it helps with correct conversion to JSON schema and then conversion back to the struct."),
      createBaseVNode("p", null, "Note: Fairly experimental, but works for combination of structs, arrays, strings and singletons."),
      createBaseVNode("p", null, [
        createBaseVNode("strong", null, "Arguments")
      ]),
      createBaseVNode("ul", null, [
        createBaseVNode("li", null, [
          createBaseVNode("p", null, [
            createBaseVNode("code", null, "type_or_method::Union{Type, Method}"),
            createTextVNode(": The struct type or method to extract the signature from.")
          ])
        ]),
        createBaseVNode("li", null, [
          createBaseVNode("p", null, [
            createBaseVNode("code", null, "strict::Union{Nothing, Bool}"),
            createTextVNode(": Whether to enforce strict mode for the schema. Defaults to "),
            createBaseVNode("code", null, "nothing"),
            createTextVNode(".")
          ])
        ]),
        createBaseVNode("li", null, [
          createBaseVNode("p", null, [
            createBaseVNode("code", null, "max_description_length::Int"),
            createTextVNode(": Maximum length for descriptions. Defaults to 200.")
          ])
        ]),
        createBaseVNode("li", null, [
          createBaseVNode("p", null, [
            createBaseVNode("code", null, "name::Union{Nothing, String}"),
            createTextVNode(": The name of the tool. Defaults to the name of the struct.")
          ])
        ]),
        createBaseVNode("li", null, [
          createBaseVNode("p", null, [
            createBaseVNode("code", null, "docs::Union{Nothing, String}"),
            createTextVNode(": The description of the tool. Defaults to the docstring of the struct/overall function.")
          ])
        ]),
        createBaseVNode("li", null, [
          createBaseVNode("p", null, [
            createBaseVNode("code", null, "hidden_fields::AbstractVector{<:Union{AbstractString, Regex}}"),
            createTextVNode(": A list of fields to hide from the LLM (eg, "),
            createBaseVNode("code", null, '["ctx_user_id"]'),
            createTextVNode(" or "),
            createBaseVNode("code", null, 'r"ctx"'),
            createTextVNode(").")
          ])
        ])
      ]),
      createBaseVNode("p", null, [
        createBaseVNode("strong", null, "Returns")
      ]),
      createBaseVNode("ul", null, [
        createBaseVNode("li", null, [
          createBaseVNode("code", null, "Dict{String, AbstractTool}"),
          createTextVNode(": A dictionary representing the function call signature schema.")
        ])
      ]),
      createBaseVNode("p", null, [
        createBaseVNode("strong", null, "Tips")
      ]),
      createBaseVNode("ul", null, [
        createBaseVNode("li", null, "You can improve the quality of the extraction by writing a helpful docstring for your struct (or any nested struct). It will be provided as a description.")
      ]),
      createBaseVNode("p", null, "You can even include comments/descriptions about the individual fields."),
      createBaseVNode("ul", null, [
        createBaseVNode("li", null, [
          createBaseVNode("p", null, [
            createTextVNode("All fields are assumed to be required, unless you allow null values (eg, "),
            createBaseVNode("code", null, "::Union{Nothing, Int}"),
            createTextVNode("). Fields with "),
            createBaseVNode("code", null, "Nothing"),
            createTextVNode(" will be treated as optional.")
          ])
        ]),
        createBaseVNode("li", null, [
          createBaseVNode("p", null, [
            createTextVNode("Missing values are ignored (eg, "),
            createBaseVNode("code", null, "::Union{Missing, Int}"),
            createTextVNode(" will be treated as Int). It's for broader compatibility and we cannot deserialize it as easily as "),
            createBaseVNode("code", null, "Nothing"),
            createTextVNode(".")
          ])
        ])
      ]),
      createBaseVNode("p", null, [
        createBaseVNode("strong", null, "Example")
      ]),
      createBaseVNode("p", null, [
        createTextVNode("Do you want to extract some specific measurements from a text like age, weight and height? You need to define the information you need as a struct ("),
        createBaseVNode("code", null, "return_type"),
        createTextVNode("):")
      ]),
      createBaseVNode("div", { class: "language-julia vp-adaptive-theme" }, [
        createBaseVNode("button", {
          title: "Copy Code",
          class: "copy"
        }),
        createBaseVNode("span", { class: "lang" }, "julia"),
        createBaseVNode("pre", {
          class: "shiki shiki-themes github-light github-dark vp-code",
          tabindex: "0"
        }, [
          createBaseVNode("code", null, [
            createBaseVNode("span", { class: "line" }, [
              createBaseVNode("span", { style: { "--shiki-light": "#D73A49", "--shiki-dark": "#F97583" } }, "struct"),
              createBaseVNode("span", { style: { "--shiki-light": "#24292E", "--shiki-dark": "#E1E4E8" } }, " MyMeasurement")
            ]),
            createTextVNode("\n"),
            createBaseVNode("span", { class: "line" }, [
              createBaseVNode("span", { style: { "--shiki-light": "#24292E", "--shiki-dark": "#E1E4E8" } }, "    age"),
              createBaseVNode("span", { style: { "--shiki-light": "#D73A49", "--shiki-dark": "#F97583" } }, "::"),
              createBaseVNode("span", { style: { "--shiki-light": "#005CC5", "--shiki-dark": "#79B8FF" } }, "Int")
            ]),
            createTextVNode("\n"),
            createBaseVNode("span", { class: "line" }, [
              createBaseVNode("span", { style: { "--shiki-light": "#24292E", "--shiki-dark": "#E1E4E8" } }, "    height"),
              createBaseVNode("span", { style: { "--shiki-light": "#D73A49", "--shiki-dark": "#F97583" } }, "::"),
              createBaseVNode("span", { style: { "--shiki-light": "#005CC5", "--shiki-dark": "#79B8FF" } }, "Union{Int,Nothing}")
            ]),
            createTextVNode("\n"),
            createBaseVNode("span", { class: "line" }, [
              createBaseVNode("span", { style: { "--shiki-light": "#24292E", "--shiki-dark": "#E1E4E8" } }, "    weight"),
              createBaseVNode("span", { style: { "--shiki-light": "#D73A49", "--shiki-dark": "#F97583" } }, "::"),
              createBaseVNode("span", { style: { "--shiki-light": "#005CC5", "--shiki-dark": "#79B8FF" } }, "Union{Nothing,Float64}")
            ]),
            createTextVNode("\n"),
            createBaseVNode("span", { class: "line" }, [
              createBaseVNode("span", { style: { "--shiki-light": "#D73A49", "--shiki-dark": "#F97583" } }, "end")
            ]),
            createTextVNode("\n"),
            createBaseVNode("span", { class: "line" }, [
              createBaseVNode("span", { style: { "--shiki-light": "#24292E", "--shiki-dark": "#E1E4E8" } }, "tool_map "),
              createBaseVNode("span", { style: { "--shiki-light": "#D73A49", "--shiki-dark": "#F97583" } }, "="),
              createBaseVNode("span", { style: { "--shiki-light": "#005CC5", "--shiki-dark": "#79B8FF" } }, " tool_call_signature"),
              createBaseVNode("span", { style: { "--shiki-light": "#24292E", "--shiki-dark": "#E1E4E8" } }, "(MyMeasurement)")
            ]),
            createTextVNode("\n"),
            createBaseVNode("span", { class: "line" }, [
              createBaseVNode("span", { style: { "--shiki-light": "#6A737D", "--shiki-dark": "#6A737D" } }, "#")
            ]),
            createTextVNode("\n"),
            createBaseVNode("span", { class: "line" }, [
              createBaseVNode("span", { style: { "--shiki-light": "#6A737D", "--shiki-dark": "#6A737D" } }, '# Dict{String, PromptingTools.AbstractTool}("MyMeasurement" => PromptingTools.Tool')
            ]),
            createTextVNode("\n"),
            createBaseVNode("span", { class: "line" }, [
              createBaseVNode("span", { style: { "--shiki-light": "#6A737D", "--shiki-dark": "#6A737D" } }, '#   name: String "MyMeasurement"')
            ]),
            createTextVNode("\n"),
            createBaseVNode("span", { class: "line" }, [
              createBaseVNode("span", { style: { "--shiki-light": "#6A737D", "--shiki-dark": "#6A737D" } }, "#   parameters: Dict{String, Any}")
            ]),
            createTextVNode("\n"),
            createBaseVNode("span", { class: "line" }, [
              createBaseVNode("span", { style: { "--shiki-light": "#6A737D", "--shiki-dark": "#6A737D" } }, "#   description: Nothing nothing")
            ]),
            createTextVNode("\n"),
            createBaseVNode("span", { class: "line" }, [
              createBaseVNode("span", { style: { "--shiki-light": "#6A737D", "--shiki-dark": "#6A737D" } }, "#   strict: Nothing nothing")
            ]),
            createTextVNode("\n"),
            createBaseVNode("span", { class: "line" }, [
              createBaseVNode("span", { style: { "--shiki-light": "#6A737D", "--shiki-dark": "#6A737D" } }, "#   callable: MyMeasurement <: Any")
            ]),
            createTextVNode("\n"),
            createBaseVNode("span", { class: "line" }, [
              createBaseVNode("span", { style: { "--shiki-light": "#032F62", "--shiki-dark": "#9ECBFF" } }, '"')
            ])
          ])
        ])
      ]),
      createBaseVNode("p", null, [
        createTextVNode("You can see that only the field "),
        createBaseVNode("code", null, "age"),
        createTextVNode(` does not allow null values, hence, it's "required". While `),
        createBaseVNode("code", null, "height"),
        createTextVNode(" and "),
        createBaseVNode("code", null, "weight"),
        createTextVNode(" are optional.")
      ]),
      createBaseVNode("div", { class: "language-julia vp-adaptive-theme" }, [
        createBaseVNode("button", {
          title: "Copy Code",
          class: "copy"
        }),
        createBaseVNode("span", { class: "lang" }, "julia"),
        createBaseVNode("pre", {
          class: "shiki shiki-themes github-light github-dark vp-code",
          tabindex: "0"
        }, [
          createBaseVNode("code", null, [
            createBaseVNode("span", { class: "line" }, [
              createBaseVNode("span", { style: { "--shiki-light": "#24292E", "--shiki-dark": "#E1E4E8" } }, "tool_map["),
              createBaseVNode("span", { style: { "--shiki-light": "#032F62", "--shiki-dark": "#9ECBFF" } }, '"MyMeasurement"'),
              createBaseVNode("span", { style: { "--shiki-light": "#24292E", "--shiki-dark": "#E1E4E8" } }, "]"),
              createBaseVNode("span", { style: { "--shiki-light": "#D73A49", "--shiki-dark": "#F97583" } }, "."),
              createBaseVNode("span", { style: { "--shiki-light": "#24292E", "--shiki-dark": "#E1E4E8" } }, "parameters["),
              createBaseVNode("span", { style: { "--shiki-light": "#032F62", "--shiki-dark": "#9ECBFF" } }, '"required"'),
              createBaseVNode("span", { style: { "--shiki-light": "#24292E", "--shiki-dark": "#E1E4E8" } }, "]")
            ]),
            createTextVNode("\n"),
            createBaseVNode("span", { class: "line" }, [
              createBaseVNode("span", { style: { "--shiki-light": "#6A737D", "--shiki-dark": "#6A737D" } }, '# ["age"]')
            ])
          ])
        ])
      ]),
      createBaseVNode("p", null, [
        createTextVNode("If there are multiple items you want to extract, define a wrapper struct to get a Vector of "),
        createBaseVNode("code", null, "MyMeasurement"),
        createTextVNode(":")
      ]),
      createBaseVNode("div", { class: "language-julia vp-adaptive-theme" }, [
        createBaseVNode("button", {
          title: "Copy Code",
          class: "copy"
        }),
        createBaseVNode("span", { class: "lang" }, "julia"),
        createBaseVNode("pre", {
          class: "shiki shiki-themes github-light github-dark vp-code",
          tabindex: "0"
        }, [
          createBaseVNode("code", null, [
            createBaseVNode("span", { class: "line" }, [
              createBaseVNode("span", { style: { "--shiki-light": "#D73A49", "--shiki-dark": "#F97583" } }, "struct"),
              createBaseVNode("span", { style: { "--shiki-light": "#24292E", "--shiki-dark": "#E1E4E8" } }, " MyMeasurementWrapper")
            ]),
            createTextVNode("\n"),
            createBaseVNode("span", { class: "line" }, [
              createBaseVNode("span", { style: { "--shiki-light": "#24292E", "--shiki-dark": "#E1E4E8" } }, "    measurements"),
              createBaseVNode("span", { style: { "--shiki-light": "#D73A49", "--shiki-dark": "#F97583" } }, "::"),
              createBaseVNode("span", { style: { "--shiki-light": "#005CC5", "--shiki-dark": "#79B8FF" } }, "Vector{MyMeasurement}")
            ]),
            createTextVNode("\n"),
            createBaseVNode("span", { class: "line" }, [
              createBaseVNode("span", { style: { "--shiki-light": "#D73A49", "--shiki-dark": "#F97583" } }, "end")
            ]),
            createTextVNode("\n"),
            createBaseVNode("span", { class: "line" }),
            createTextVNode("\n"),
            createBaseVNode("span", { class: "line" }, [
              createBaseVNode("span", { style: { "--shiki-light": "#24292E", "--shiki-dark": "#E1E4E8" } }, "Or "),
              createBaseVNode("span", { style: { "--shiki-light": "#D73A49", "--shiki-dark": "#F97583" } }, "if"),
              createBaseVNode("span", { style: { "--shiki-light": "#24292E", "--shiki-dark": "#E1E4E8" } }, " you want your extraction to fail gracefully when data isn"),
              createBaseVNode("span", { style: { "--shiki-light": "#D73A49", "--shiki-dark": "#F97583" } }, "'"),
              createBaseVNode("span", { style: { "--shiki-light": "#24292E", "--shiki-dark": "#E1E4E8" } }, "t found, use "),
              createBaseVNode("span", { style: { "--shiki-light": "#032F62", "--shiki-dark": "#9ECBFF" } }, "`MaybeExtract{T}`"),
              createBaseVNode("span", { style: { "--shiki-light": "#24292E", "--shiki-dark": "#E1E4E8" } }, " wrapper (inspired by Instructor package!)"),
              createBaseVNode("span", { style: { "--shiki-light": "#D73A49", "--shiki-dark": "#F97583" } }, ":")
            ])
          ])
        ])
      ]),
      createBaseVNode("p", null, "using PromptingTools: MaybeExtract"),
      createBaseVNode("p", { MyMeasurement: "" }, "type = MaybeExtract"),
      createBaseVNode("p", null, [
        createBaseVNode("strong", null, "Effectively the same as:")
      ]),
      createBaseVNode("p", null, [
        createBaseVNode("strong", null, "struct MaybeExtract{T}")
      ]),
      createBaseVNode("p", null, [
        createBaseVNode("strong", null, "result::Union{T, Nothing}")
      ]),
      createBaseVNode("p", null, [
        createBaseVNode("strong", null, "error::Bool // true if a result is found, false otherwise")
      ]),
      createBaseVNode("p", null, [
        createBaseVNode("strong", null, "message::Union{Nothing, String} // Only present if no result is found, should be short and concise")
      ]),
      createBaseVNode("p", null, [
        createBaseVNode("strong", null, "end")
      ]),
      createBaseVNode("p", null, [
        createBaseVNode("strong", null, [
          createTextVNode("If LLM extraction fails, it will return a Dict with "),
          createBaseVNode("code", null, "error"),
          createTextVNode(" and "),
          createBaseVNode("code", null, "message"),
          createTextVNode(" fields instead of the result!")
        ])
      ]),
      createBaseVNode("p", null, 'msg = aiextract("Extract measurements from the text: I am giraffe", type)'),
      createBaseVNode("hr"),
      createBaseVNode("p", null, [
        createBaseVNode("strong", null, "Dict{Symbol, Any} with 2 entries:")
      ]),
      createBaseVNode("p", null, [
        createBaseVNode("strong", null, ':message => "Sorry, this feature is only available for humans."')
      ]),
      createBaseVNode("p", null, [
        createBaseVNode("strong", null, ":error => true")
      ]),
      createBaseVNode("div", { class: "language-julia vp-adaptive-theme" }, [
        createBaseVNode("button", {
          title: "Copy Code",
          class: "copy"
        }),
        createBaseVNode("span", { class: "lang" }, "julia"),
        createBaseVNode("pre", {
          class: "shiki shiki-themes github-light github-dark vp-code",
          tabindex: "0"
        }, [
          createBaseVNode("code", null, [
            createBaseVNode("span", { class: "line" }, [
              createBaseVNode("span", { style: { "--shiki-light": "#24292E", "--shiki-dark": "#E1E4E8" } }, "That way, you can handle the error gracefully and get a reason why extraction failed.")
            ]),
            createTextVNode("\n"),
            createBaseVNode("span", { class: "line" }),
            createTextVNode("\n"),
            createBaseVNode("span", { class: "line" }, [
              createBaseVNode("span", { style: { "--shiki-light": "#24292E", "--shiki-dark": "#E1E4E8" } }, "You can also hide certain fields "),
              createBaseVNode("span", { style: { "--shiki-light": "#D73A49", "--shiki-dark": "#F97583" } }, "in"),
              createBaseVNode("span", { style: { "--shiki-light": "#24292E", "--shiki-dark": "#E1E4E8" } }, " your "),
              createBaseVNode("span", { style: { "--shiki-light": "#D73A49", "--shiki-dark": "#F97583" } }, "function"),
              createBaseVNode("span", { style: { "--shiki-light": "#24292E", "--shiki-dark": "#E1E4E8" } }, " call signature with Strings or Regex patterns (eg, "),
              createBaseVNode("span", { style: { "--shiki-light": "#032F62", "--shiki-dark": "#9ECBFF" } }, '`r"ctx"`'),
              createBaseVNode("span", { style: { "--shiki-light": "#24292E", "--shiki-dark": "#E1E4E8" } }, ")"),
              createBaseVNode("span", { style: { "--shiki-light": "#D73A49", "--shiki-dark": "#F97583" } }, ".")
            ])
          ])
        ])
      ]),
      createBaseVNode("p", null, 'tool_map = tool_call_signature(MyMeasurement; hidden_fields = ["ctx_user_id"]) ```'),
      createBaseVNode("p", null, [
        createBaseVNode("a", {
          href: "https://github.com/svilupp/PromptingTools.jl/blob/da7e7e8e605d4424e39f074b054d7195a036754c/src/extraction.jl#L463-L555",
          target: "_blank",
          rel: "noreferrer"
        }, "source")
      ])
    ], -1)),
    _cache[58] || (_cache[58] = createStaticVNode("", 37))
  ]);
}
const reference = /* @__PURE__ */ _export_sfc(_sfc_main, [["render", _sfc_render]]);
export {
  __pageData,
  reference as default
};
