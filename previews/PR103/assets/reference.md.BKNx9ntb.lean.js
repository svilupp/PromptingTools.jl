import { _ as _export_sfc, c as createElementBlock, m as createBaseVNode, a as createTextVNode, t as toDisplayString, a7 as createStaticVNode, o as openBlock } from "./chunks/framework.C1vzEJDW.js";
const __pageData = JSON.parse('{"title":"Reference","description":"","frontmatter":{"outline":"deep"},"headers":[],"relativePath":"reference.md","filePath":"reference.md","lastUpdated":null}');
const _sfc_main = { name: "reference.md" };
const _hoisted_1 = /* @__PURE__ */ createStaticVNode("", 78);
const _hoisted_79 = { style: { "border-width": "1px", "border-style": "solid", "border-color": "black", "padding": "1em", "border-radius": "25px" } };
const _hoisted_80 = /* @__PURE__ */ createBaseVNode("a", {
  id: 'PromptingTools.aiclassify-Union{Tuple{T}, Tuple{PromptingTools.AbstractOpenAISchema, Union{AbstractString, PromptingTools.AbstractMessage, Vector{<:PromptingTools.AbstractMessage}}}} where T<:Union{AbstractString, Tuple{var"#s110", var"#s104"} where {var"#s110"<:AbstractString, var"#s104"<:AbstractString}}',
  href: '#PromptingTools.aiclassify-Union{Tuple{T}, Tuple{PromptingTools.AbstractOpenAISchema, Union{AbstractString, PromptingTools.AbstractMessage, Vector{<:PromptingTools.AbstractMessage}}}} where T<:Union{AbstractString, Tuple{var"#s110", var"#s104"} where {var"#s110"<:AbstractString, var"#s104"<:AbstractString}}'
}, "#", -1);
const _hoisted_81 = /* @__PURE__ */ createBaseVNode("b", null, [
  /* @__PURE__ */ createBaseVNode("u", null, "PromptingTools.aiclassify")
], -1);
const _hoisted_82 = /* @__PURE__ */ createBaseVNode("i", null, "Method", -1);
const _hoisted_83 = /* @__PURE__ */ createStaticVNode("", 3);
const _hoisted_86 = /* @__PURE__ */ createBaseVNode("code", null, "choices", -1);
const _hoisted_87 = /* @__PURE__ */ createStaticVNode("", 19);
const _hoisted_106 = /* @__PURE__ */ createStaticVNode("", 37);
const _hoisted_143 = { style: { "border-width": "1px", "border-style": "solid", "border-color": "black", "padding": "1em", "border-radius": "25px" } };
const _hoisted_144 = /* @__PURE__ */ createBaseVNode("a", {
  id: "PromptingTools.create_template-Tuple{AbstractString, AbstractString}",
  href: "#PromptingTools.create_template-Tuple{AbstractString, AbstractString}"
}, "#", -1);
const _hoisted_145 = /* @__PURE__ */ createBaseVNode("b", null, [
  /* @__PURE__ */ createBaseVNode("u", null, "PromptingTools.create_template")
], -1);
const _hoisted_146 = /* @__PURE__ */ createBaseVNode("i", null, "Method", -1);
const _hoisted_147 = /* @__PURE__ */ createStaticVNode("", 4);
const _hoisted_151 = /* @__PURE__ */ createBaseVNode("code", null, "kwargs", -1);
const _hoisted_152 = /* @__PURE__ */ createStaticVNode("", 19);
const _hoisted_171 = /* @__PURE__ */ createStaticVNode("", 25);
const _hoisted_196 = /* @__PURE__ */ createBaseVNode("div", { style: { "border-width": "1px", "border-style": "solid", "border-color": "black", "padding": "1em", "border-radius": "25px" } }, [
  /* @__PURE__ */ createBaseVNode("a", {
    id: "PromptingTools.function_call_signature-Tuple{Type}",
    href: "#PromptingTools.function_call_signature-Tuple{Type}"
  }, "#"),
  /* @__PURE__ */ createTextVNode(" "),
  /* @__PURE__ */ createBaseVNode("b", null, [
    /* @__PURE__ */ createBaseVNode("u", null, "PromptingTools.function_call_signature")
  ]),
  /* @__PURE__ */ createTextVNode(" — "),
  /* @__PURE__ */ createBaseVNode("i", null, "Method"),
  /* @__PURE__ */ createTextVNode(". "),
  /* @__PURE__ */ createBaseVNode("div", { class: "language-julia vp-adaptive-theme" }, [
    /* @__PURE__ */ createBaseVNode("button", {
      title: "Copy Code",
      class: "copy"
    }),
    /* @__PURE__ */ createBaseVNode("span", { class: "lang" }, "julia"),
    /* @__PURE__ */ createBaseVNode("pre", { class: "shiki shiki-themes github-light github-dark vp-code" }, [
      /* @__PURE__ */ createBaseVNode("code", null, [
        /* @__PURE__ */ createBaseVNode("span", { class: "line" }, [
          /* @__PURE__ */ createBaseVNode("span", { style: { "--shiki-light": "#005CC5", "--shiki-dark": "#79B8FF" } }, "function_call_signature"),
          /* @__PURE__ */ createBaseVNode("span", { style: { "--shiki-light": "#24292E", "--shiki-dark": "#E1E4E8" } }, "(datastructtype"),
          /* @__PURE__ */ createBaseVNode("span", { style: { "--shiki-light": "#D73A49", "--shiki-dark": "#F97583" } }, "::"),
          /* @__PURE__ */ createBaseVNode("span", { style: { "--shiki-light": "#005CC5", "--shiki-dark": "#79B8FF" } }, "Struct"),
          /* @__PURE__ */ createBaseVNode("span", { style: { "--shiki-light": "#24292E", "--shiki-dark": "#E1E4E8" } }, "; max_description_length"),
          /* @__PURE__ */ createBaseVNode("span", { style: { "--shiki-light": "#D73A49", "--shiki-dark": "#F97583" } }, "::"),
          /* @__PURE__ */ createBaseVNode("span", { style: { "--shiki-light": "#005CC5", "--shiki-dark": "#79B8FF" } }, "Int"),
          /* @__PURE__ */ createBaseVNode("span", { style: { "--shiki-light": "#D73A49", "--shiki-dark": "#F97583" } }, " ="),
          /* @__PURE__ */ createBaseVNode("span", { style: { "--shiki-light": "#005CC5", "--shiki-dark": "#79B8FF" } }, " 100"),
          /* @__PURE__ */ createBaseVNode("span", { style: { "--shiki-light": "#24292E", "--shiki-dark": "#E1E4E8" } }, ")")
        ])
      ])
    ])
  ]),
  /* @__PURE__ */ createBaseVNode("p", null, "Extract the argument names, types and docstrings from a struct to create the function call signature in JSON schema."),
  /* @__PURE__ */ createBaseVNode("p", null, "You must provide a Struct type (not an instance of it) with some fields."),
  /* @__PURE__ */ createBaseVNode("p", null, "Note: Fairly experimental, but works for combination of structs, arrays, strings and singletons."),
  /* @__PURE__ */ createBaseVNode("p", null, [
    /* @__PURE__ */ createBaseVNode("strong", null, "Tips")
  ]),
  /* @__PURE__ */ createBaseVNode("ul", null, [
    /* @__PURE__ */ createBaseVNode("li", null, "You can improve the quality of the extraction by writing a helpful docstring for your struct (or any nested struct). It will be provided as a description.")
  ]),
  /* @__PURE__ */ createBaseVNode("p", null, "You can even include comments/descriptions about the individual fields."),
  /* @__PURE__ */ createBaseVNode("ul", null, [
    /* @__PURE__ */ createBaseVNode("li", null, [
      /* @__PURE__ */ createBaseVNode("p", null, [
        /* @__PURE__ */ createTextVNode("All fields are assumed to be required, unless you allow null values (eg, "),
        /* @__PURE__ */ createBaseVNode("code", null, "::Union{Nothing, Int}"),
        /* @__PURE__ */ createTextVNode("). Fields with "),
        /* @__PURE__ */ createBaseVNode("code", null, "Nothing"),
        /* @__PURE__ */ createTextVNode(" will be treated as optional.")
      ])
    ]),
    /* @__PURE__ */ createBaseVNode("li", null, [
      /* @__PURE__ */ createBaseVNode("p", null, [
        /* @__PURE__ */ createTextVNode("Missing values are ignored (eg, "),
        /* @__PURE__ */ createBaseVNode("code", null, "::Union{Missing, Int}"),
        /* @__PURE__ */ createTextVNode(" will be treated as Int). It's for broader compatibility and we cannot deserialize it as easily as "),
        /* @__PURE__ */ createBaseVNode("code", null, "Nothing"),
        /* @__PURE__ */ createTextVNode(".")
      ])
    ])
  ]),
  /* @__PURE__ */ createBaseVNode("p", null, [
    /* @__PURE__ */ createBaseVNode("strong", null, "Example")
  ]),
  /* @__PURE__ */ createBaseVNode("p", null, [
    /* @__PURE__ */ createTextVNode("Do you want to extract some specific measurements from a text like age, weight and height? You need to define the information you need as a struct ("),
    /* @__PURE__ */ createBaseVNode("code", null, "return_type"),
    /* @__PURE__ */ createTextVNode("):")
  ]),
  /* @__PURE__ */ createBaseVNode("div", { class: "language- vp-adaptive-theme" }, [
    /* @__PURE__ */ createBaseVNode("button", {
      title: "Copy Code",
      class: "copy"
    }),
    /* @__PURE__ */ createBaseVNode("span", { class: "lang" }),
    /* @__PURE__ */ createBaseVNode("pre", { class: "shiki shiki-themes github-light github-dark vp-code" }, [
      /* @__PURE__ */ createBaseVNode("code", null, [
        /* @__PURE__ */ createBaseVNode("span", { class: "line" }, [
          /* @__PURE__ */ createBaseVNode("span", null, "struct MyMeasurement")
        ]),
        /* @__PURE__ */ createTextVNode("\n"),
        /* @__PURE__ */ createBaseVNode("span", { class: "line" }, [
          /* @__PURE__ */ createBaseVNode("span", null, "    age::Int")
        ]),
        /* @__PURE__ */ createTextVNode("\n"),
        /* @__PURE__ */ createBaseVNode("span", { class: "line" }, [
          /* @__PURE__ */ createBaseVNode("span", null, "    height::Union{Int,Nothing}")
        ]),
        /* @__PURE__ */ createTextVNode("\n"),
        /* @__PURE__ */ createBaseVNode("span", { class: "line" }, [
          /* @__PURE__ */ createBaseVNode("span", null, "    weight::Union{Nothing,Float64}")
        ]),
        /* @__PURE__ */ createTextVNode("\n"),
        /* @__PURE__ */ createBaseVNode("span", { class: "line" }, [
          /* @__PURE__ */ createBaseVNode("span", null, "end")
        ]),
        /* @__PURE__ */ createTextVNode("\n"),
        /* @__PURE__ */ createBaseVNode("span", { class: "line" }, [
          /* @__PURE__ */ createBaseVNode("span", null, "signature = function_call_signature(MyMeasurement)")
        ]),
        /* @__PURE__ */ createTextVNode("\n"),
        /* @__PURE__ */ createBaseVNode("span", { class: "line" }, [
          /* @__PURE__ */ createBaseVNode("span", null, "#")
        ]),
        /* @__PURE__ */ createTextVNode("\n"),
        /* @__PURE__ */ createBaseVNode("span", { class: "line" }, [
          /* @__PURE__ */ createBaseVNode("span", null, "# Dict{String, Any} with 3 entries:")
        ]),
        /* @__PURE__ */ createTextVNode("\n"),
        /* @__PURE__ */ createBaseVNode("span", { class: "line" }, [
          /* @__PURE__ */ createBaseVNode("span", null, '#   "name"        => "MyMeasurement_extractor"')
        ]),
        /* @__PURE__ */ createTextVNode("\n"),
        /* @__PURE__ */ createBaseVNode("span", { class: "line" }, [
          /* @__PURE__ */ createBaseVNode("span", null, '#   "parameters"  => Dict{String, Any}("properties"=>Dict{String, Any}("height"=>Dict{String, Any}("type"=>"integer"), "weight"=>Dic…')
        ]),
        /* @__PURE__ */ createTextVNode("\n"),
        /* @__PURE__ */ createBaseVNode("span", { class: "line" }, [
          /* @__PURE__ */ createBaseVNode("span", null, `#   "description" => "Represents person's age, height, and weight`)
        ]),
        /* @__PURE__ */ createTextVNode("\n"),
        /* @__PURE__ */ createBaseVNode("span", { class: "line" }, [
          /* @__PURE__ */ createBaseVNode("span", null, '"')
        ])
      ])
    ])
  ]),
  /* @__PURE__ */ createBaseVNode("p", null, [
    /* @__PURE__ */ createTextVNode("You can see that only the field "),
    /* @__PURE__ */ createBaseVNode("code", null, "age"),
    /* @__PURE__ */ createTextVNode(` does not allow null values, hence, it's "required". While `),
    /* @__PURE__ */ createBaseVNode("code", null, "height"),
    /* @__PURE__ */ createTextVNode(" and "),
    /* @__PURE__ */ createBaseVNode("code", null, "weight"),
    /* @__PURE__ */ createTextVNode(" are optional.")
  ]),
  /* @__PURE__ */ createBaseVNode("div", { class: "language- vp-adaptive-theme" }, [
    /* @__PURE__ */ createBaseVNode("button", {
      title: "Copy Code",
      class: "copy"
    }),
    /* @__PURE__ */ createBaseVNode("span", { class: "lang" }),
    /* @__PURE__ */ createBaseVNode("pre", { class: "shiki shiki-themes github-light github-dark vp-code" }, [
      /* @__PURE__ */ createBaseVNode("code", null, [
        /* @__PURE__ */ createBaseVNode("span", { class: "line" }, [
          /* @__PURE__ */ createBaseVNode("span", null, 'signature["parameters"]["required"]')
        ]),
        /* @__PURE__ */ createTextVNode("\n"),
        /* @__PURE__ */ createBaseVNode("span", { class: "line" }, [
          /* @__PURE__ */ createBaseVNode("span", null, '# ["age"]')
        ])
      ])
    ])
  ]),
  /* @__PURE__ */ createBaseVNode("p", null, [
    /* @__PURE__ */ createTextVNode("If there are multiple items you want to extract, define a wrapper struct to get a Vector of "),
    /* @__PURE__ */ createBaseVNode("code", null, "MyMeasurement"),
    /* @__PURE__ */ createTextVNode(":")
  ]),
  /* @__PURE__ */ createBaseVNode("div", { class: "language- vp-adaptive-theme" }, [
    /* @__PURE__ */ createBaseVNode("button", {
      title: "Copy Code",
      class: "copy"
    }),
    /* @__PURE__ */ createBaseVNode("span", { class: "lang" }),
    /* @__PURE__ */ createBaseVNode("pre", { class: "shiki shiki-themes github-light github-dark vp-code" }, [
      /* @__PURE__ */ createBaseVNode("code", null, [
        /* @__PURE__ */ createBaseVNode("span", { class: "line" }, [
          /* @__PURE__ */ createBaseVNode("span", null, "struct MyMeasurementWrapper")
        ]),
        /* @__PURE__ */ createTextVNode("\n"),
        /* @__PURE__ */ createBaseVNode("span", { class: "line" }, [
          /* @__PURE__ */ createBaseVNode("span", null, "    measurements::Vector{MyMeasurement}")
        ]),
        /* @__PURE__ */ createTextVNode("\n"),
        /* @__PURE__ */ createBaseVNode("span", { class: "line" }, [
          /* @__PURE__ */ createBaseVNode("span", null, "end")
        ]),
        /* @__PURE__ */ createTextVNode("\n"),
        /* @__PURE__ */ createBaseVNode("span", { class: "line" }, [
          /* @__PURE__ */ createBaseVNode("span")
        ]),
        /* @__PURE__ */ createTextVNode("\n"),
        /* @__PURE__ */ createBaseVNode("span", { class: "line" }, [
          /* @__PURE__ */ createBaseVNode("span", null, "Or if you want your extraction to fail gracefully when data isn't found, use `MaybeExtract{T}` wrapper (inspired by Instructor package!):")
        ])
      ])
    ])
  ]),
  /* @__PURE__ */ createBaseVNode("p", null, "using PromptingTools: MaybeExtract"),
  /* @__PURE__ */ createBaseVNode("p", { MyMeasurement: "" }, "type = MaybeExtract"),
  /* @__PURE__ */ createBaseVNode("p", null, [
    /* @__PURE__ */ createBaseVNode("strong", null, "Effectively the same as:")
  ]),
  /* @__PURE__ */ createBaseVNode("p", null, [
    /* @__PURE__ */ createBaseVNode("strong", null, "struct MaybeExtract{T}")
  ]),
  /* @__PURE__ */ createBaseVNode("p", null, [
    /* @__PURE__ */ createBaseVNode("strong", null, "result::Union{T, Nothing}")
  ]),
  /* @__PURE__ */ createBaseVNode("p", null, [
    /* @__PURE__ */ createBaseVNode("strong", null, "error::Bool // true if a result is found, false otherwise")
  ]),
  /* @__PURE__ */ createBaseVNode("p", null, [
    /* @__PURE__ */ createBaseVNode("strong", null, "message::Union{Nothing, String} // Only present if no result is found, should be short and concise")
  ]),
  /* @__PURE__ */ createBaseVNode("p", null, [
    /* @__PURE__ */ createBaseVNode("strong", null, "end")
  ]),
  /* @__PURE__ */ createBaseVNode("p", null, [
    /* @__PURE__ */ createBaseVNode("strong", null, [
      /* @__PURE__ */ createTextVNode("If LLM extraction fails, it will return a Dict with "),
      /* @__PURE__ */ createBaseVNode("code", null, "error"),
      /* @__PURE__ */ createTextVNode(" and "),
      /* @__PURE__ */ createBaseVNode("code", null, "message"),
      /* @__PURE__ */ createTextVNode(" fields instead of the result!")
    ])
  ]),
  /* @__PURE__ */ createBaseVNode("p", null, 'msg = aiextract("Extract measurements from the text: I am giraffe", type)'),
  /* @__PURE__ */ createBaseVNode("hr"),
  /* @__PURE__ */ createBaseVNode("p", null, [
    /* @__PURE__ */ createBaseVNode("strong", null, "Dict{Symbol, Any} with 2 entries:")
  ]),
  /* @__PURE__ */ createBaseVNode("p", null, [
    /* @__PURE__ */ createBaseVNode("strong", null, ':message => "Sorry, this feature is only available for humans."')
  ]),
  /* @__PURE__ */ createBaseVNode("p", null, [
    /* @__PURE__ */ createBaseVNode("strong", null, ":error => true")
  ]),
  /* @__PURE__ */ createBaseVNode("div", { class: "language-That vp-adaptive-theme" }, [
    /* @__PURE__ */ createBaseVNode("button", {
      title: "Copy Code",
      class: "copy"
    }),
    /* @__PURE__ */ createBaseVNode("span", { class: "lang" }, "That"),
    /* @__PURE__ */ createBaseVNode("pre", { class: "shiki shiki-themes github-light github-dark vp-code" }, [
      /* @__PURE__ */ createBaseVNode("code", null, [
        /* @__PURE__ */ createBaseVNode("span", { class: "line" }, [
          /* @__PURE__ */ createBaseVNode("span")
        ]),
        /* @__PURE__ */ createTextVNode("\n"),
        /* @__PURE__ */ createBaseVNode("span", { class: "line" }, [
          /* @__PURE__ */ createBaseVNode("span")
        ]),
        /* @__PURE__ */ createTextVNode("\n"),
        /* @__PURE__ */ createBaseVNode("span", { class: "line" }, [
          /* @__PURE__ */ createBaseVNode("span", null, "[source](https://github.com/svilupp/PromptingTools.jl/blob/1671239c38c0b309f52f81d9522c51f593517a4f/src/extraction.jl#L84-L152)")
        ]),
        /* @__PURE__ */ createTextVNode("\n"),
        /* @__PURE__ */ createBaseVNode("span", { class: "line" }, [
          /* @__PURE__ */ createBaseVNode("span")
        ]),
        /* @__PURE__ */ createTextVNode("\n"),
        /* @__PURE__ */ createBaseVNode("span", { class: "line" }, [
          /* @__PURE__ */ createBaseVNode("span", null, "</div>")
        ]),
        /* @__PURE__ */ createTextVNode("\n"),
        /* @__PURE__ */ createBaseVNode("span", { class: "line" }, [
          /* @__PURE__ */ createBaseVNode("span", null, "<br>")
        ]),
        /* @__PURE__ */ createTextVNode("\n"),
        /* @__PURE__ */ createBaseVNode("span", { class: "line" }, [
          /* @__PURE__ */ createBaseVNode("span", null, "<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>")
        ]),
        /* @__PURE__ */ createTextVNode("\n"),
        /* @__PURE__ */ createBaseVNode("span", { class: "line" }, [
          /* @__PURE__ */ createBaseVNode("span", null, "<a id='PromptingTools.get_preferences-Tuple{String}' href='#PromptingTools.get_preferences-Tuple{String}'>#</a>&nbsp;<b><u>PromptingTools.get_preferences</u></b> &mdash; <i>Method</i>.")
        ]),
        /* @__PURE__ */ createTextVNode("\n"),
        /* @__PURE__ */ createBaseVNode("span", { class: "line" }, [
          /* @__PURE__ */ createBaseVNode("span")
        ]),
        /* @__PURE__ */ createTextVNode("\n"),
        /* @__PURE__ */ createBaseVNode("span", { class: "line" }, [
          /* @__PURE__ */ createBaseVNode("span")
        ]),
        /* @__PURE__ */ createTextVNode("\n"),
        /* @__PURE__ */ createBaseVNode("span", { class: "line" }, [
          /* @__PURE__ */ createBaseVNode("span")
        ]),
        /* @__PURE__ */ createTextVNode("\n"),
        /* @__PURE__ */ createBaseVNode("span", { class: "line" }, [
          /* @__PURE__ */ createBaseVNode("span")
        ]),
        /* @__PURE__ */ createTextVNode("\n"),
        /* @__PURE__ */ createBaseVNode("span", { class: "line" }, [
          /* @__PURE__ */ createBaseVNode("span", null, "```julia")
        ]),
        /* @__PURE__ */ createTextVNode("\n"),
        /* @__PURE__ */ createBaseVNode("span", { class: "line" }, [
          /* @__PURE__ */ createBaseVNode("span", null, "get_preferences(key::String)")
        ])
      ])
    ])
  ]),
  /* @__PURE__ */ createBaseVNode("p", null, [
    /* @__PURE__ */ createTextVNode("Get preferences for PromptingTools. See "),
    /* @__PURE__ */ createBaseVNode("code", null, "?PREFERENCES"),
    /* @__PURE__ */ createTextVNode(" for more information.")
  ]),
  /* @__PURE__ */ createBaseVNode("p", null, [
    /* @__PURE__ */ createTextVNode("See also: "),
    /* @__PURE__ */ createBaseVNode("code", null, "set_preferences!")
  ]),
  /* @__PURE__ */ createBaseVNode("p", null, [
    /* @__PURE__ */ createBaseVNode("strong", null, "Example")
  ]),
  /* @__PURE__ */ createBaseVNode("div", { class: "language-julia vp-adaptive-theme" }, [
    /* @__PURE__ */ createBaseVNode("button", {
      title: "Copy Code",
      class: "copy"
    }),
    /* @__PURE__ */ createBaseVNode("span", { class: "lang" }, "julia"),
    /* @__PURE__ */ createBaseVNode("pre", { class: "shiki shiki-themes github-light github-dark vp-code" }, [
      /* @__PURE__ */ createBaseVNode("code", null, [
        /* @__PURE__ */ createBaseVNode("span", { class: "line" }, [
          /* @__PURE__ */ createBaseVNode("span", { style: { "--shiki-light": "#24292E", "--shiki-dark": "#E1E4E8" } }, "PromptingTools"),
          /* @__PURE__ */ createBaseVNode("span", { style: { "--shiki-light": "#D73A49", "--shiki-dark": "#F97583" } }, "."),
          /* @__PURE__ */ createBaseVNode("span", { style: { "--shiki-light": "#005CC5", "--shiki-dark": "#79B8FF" } }, "get_preferences"),
          /* @__PURE__ */ createBaseVNode("span", { style: { "--shiki-light": "#24292E", "--shiki-dark": "#E1E4E8" } }, "("),
          /* @__PURE__ */ createBaseVNode("span", { style: { "--shiki-light": "#032F62", "--shiki-dark": "#9ECBFF" } }, '"MODEL_CHAT"'),
          /* @__PURE__ */ createBaseVNode("span", { style: { "--shiki-light": "#24292E", "--shiki-dark": "#E1E4E8" } }, ")")
        ])
      ])
    ])
  ]),
  /* @__PURE__ */ createBaseVNode("p", null, [
    /* @__PURE__ */ createBaseVNode("a", {
      href: "https://github.com/svilupp/PromptingTools.jl/blob/1671239c38c0b309f52f81d9522c51f593517a4f/src/user_preferences.jl#L94-L105",
      target: "_blank",
      rel: "noreferrer"
    }, "source")
  ])
], -1);
const _hoisted_197 = /* @__PURE__ */ createStaticVNode("", 41);
const _hoisted_238 = { style: { "border-width": "1px", "border-style": "solid", "border-color": "black", "padding": "1em", "border-radius": "25px" } };
const _hoisted_239 = /* @__PURE__ */ createBaseVNode("a", {
  id: "PromptingTools.render-Tuple{PromptingTools.AbstractGoogleSchema, Vector{<:PromptingTools.AbstractMessage}}",
  href: "#PromptingTools.render-Tuple{PromptingTools.AbstractGoogleSchema, Vector{<:PromptingTools.AbstractMessage}}"
}, "#", -1);
const _hoisted_240 = /* @__PURE__ */ createBaseVNode("b", null, [
  /* @__PURE__ */ createBaseVNode("u", null, "PromptingTools.render")
], -1);
const _hoisted_241 = /* @__PURE__ */ createBaseVNode("i", null, "Method", -1);
const _hoisted_242 = /* @__PURE__ */ createStaticVNode("", 1);
const _hoisted_243 = /* @__PURE__ */ createBaseVNode("p", null, [
  /* @__PURE__ */ createBaseVNode("strong", null, "Keyword Arguments")
], -1);
const _hoisted_244 = /* @__PURE__ */ createBaseVNode("ul", null, [
  /* @__PURE__ */ createBaseVNode("li", null, [
    /* @__PURE__ */ createBaseVNode("code", null, "conversation"),
    /* @__PURE__ */ createTextVNode(": An optional vector of "),
    /* @__PURE__ */ createBaseVNode("code", null, "AbstractMessage"),
    /* @__PURE__ */ createTextVNode(" objects representing the conversation history. If not provided, it is initialized as an empty vector.")
  ])
], -1);
const _hoisted_245 = /* @__PURE__ */ createBaseVNode("p", null, [
  /* @__PURE__ */ createBaseVNode("a", {
    href: "https://github.com/svilupp/PromptingTools.jl/blob/1671239c38c0b309f52f81d9522c51f593517a4f/src/llm_google.jl#L2-L13",
    target: "_blank",
    rel: "noreferrer"
  }, "source")
], -1);
const _hoisted_246 = /* @__PURE__ */ createBaseVNode("br", null, null, -1);
const _hoisted_247 = { style: { "border-width": "1px", "border-style": "solid", "border-color": "black", "padding": "1em", "border-radius": "25px" } };
const _hoisted_248 = /* @__PURE__ */ createBaseVNode("a", {
  id: "PromptingTools.render-Tuple{PromptingTools.AbstractOllamaManagedSchema, Vector{<:PromptingTools.AbstractMessage}}",
  href: "#PromptingTools.render-Tuple{PromptingTools.AbstractOllamaManagedSchema, Vector{<:PromptingTools.AbstractMessage}}"
}, "#", -1);
const _hoisted_249 = /* @__PURE__ */ createBaseVNode("b", null, [
  /* @__PURE__ */ createBaseVNode("u", null, "PromptingTools.render")
], -1);
const _hoisted_250 = /* @__PURE__ */ createBaseVNode("i", null, "Method", -1);
const _hoisted_251 = /* @__PURE__ */ createStaticVNode("", 1);
const _hoisted_252 = /* @__PURE__ */ createBaseVNode("p", null, [
  /* @__PURE__ */ createTextVNode('Note: Due to its "managed" nature, at most 2 messages can be provided ('),
  /* @__PURE__ */ createBaseVNode("code", null, "system"),
  /* @__PURE__ */ createTextVNode(" and "),
  /* @__PURE__ */ createBaseVNode("code", null, "prompt"),
  /* @__PURE__ */ createTextVNode(" inputs in the API).")
], -1);
const _hoisted_253 = /* @__PURE__ */ createBaseVNode("p", null, [
  /* @__PURE__ */ createBaseVNode("strong", null, "Keyword Arguments")
], -1);
const _hoisted_254 = /* @__PURE__ */ createBaseVNode("ul", null, [
  /* @__PURE__ */ createBaseVNode("li", null, [
    /* @__PURE__ */ createBaseVNode("code", null, "conversation"),
    /* @__PURE__ */ createTextVNode(": Not allowed for this schema. Provided only for compatibility.")
  ])
], -1);
const _hoisted_255 = /* @__PURE__ */ createBaseVNode("p", null, [
  /* @__PURE__ */ createBaseVNode("a", {
    href: "https://github.com/svilupp/PromptingTools.jl/blob/1671239c38c0b309f52f81d9522c51f593517a4f/src/llm_ollama_managed.jl#L9-L21",
    target: "_blank",
    rel: "noreferrer"
  }, "source")
], -1);
const _hoisted_256 = /* @__PURE__ */ createBaseVNode("br", null, null, -1);
const _hoisted_257 = { style: { "border-width": "1px", "border-style": "solid", "border-color": "black", "padding": "1em", "border-radius": "25px" } };
const _hoisted_258 = /* @__PURE__ */ createBaseVNode("a", {
  id: "PromptingTools.render-Tuple{PromptingTools.AbstractOllamaSchema, Vector{<:PromptingTools.AbstractMessage}}",
  href: "#PromptingTools.render-Tuple{PromptingTools.AbstractOllamaSchema, Vector{<:PromptingTools.AbstractMessage}}"
}, "#", -1);
const _hoisted_259 = /* @__PURE__ */ createBaseVNode("b", null, [
  /* @__PURE__ */ createBaseVNode("u", null, "PromptingTools.render")
], -1);
const _hoisted_260 = /* @__PURE__ */ createBaseVNode("i", null, "Method", -1);
const _hoisted_261 = /* @__PURE__ */ createStaticVNode("", 1);
const _hoisted_262 = /* @__PURE__ */ createBaseVNode("p", null, [
  /* @__PURE__ */ createBaseVNode("strong", null, "Keyword Arguments")
], -1);
const _hoisted_263 = /* @__PURE__ */ createBaseVNode("ul", null, [
  /* @__PURE__ */ createBaseVNode("li", null, [
    /* @__PURE__ */ createBaseVNode("code", null, "conversation"),
    /* @__PURE__ */ createTextVNode(": An optional vector of "),
    /* @__PURE__ */ createBaseVNode("code", null, "AbstractMessage"),
    /* @__PURE__ */ createTextVNode(" objects representing the conversation history. If not provided, it is initialized as an empty vector.")
  ])
], -1);
const _hoisted_264 = /* @__PURE__ */ createBaseVNode("p", null, [
  /* @__PURE__ */ createBaseVNode("a", {
    href: "https://github.com/svilupp/PromptingTools.jl/blob/1671239c38c0b309f52f81d9522c51f593517a4f/src/llm_ollama.jl#L10-L21",
    target: "_blank",
    rel: "noreferrer"
  }, "source")
], -1);
const _hoisted_265 = /* @__PURE__ */ createBaseVNode("br", null, null, -1);
const _hoisted_266 = { style: { "border-width": "1px", "border-style": "solid", "border-color": "black", "padding": "1em", "border-radius": "25px" } };
const _hoisted_267 = /* @__PURE__ */ createBaseVNode("a", {
  id: "PromptingTools.render-Tuple{PromptingTools.AbstractOpenAISchema, Vector{<:PromptingTools.AbstractMessage}}",
  href: "#PromptingTools.render-Tuple{PromptingTools.AbstractOpenAISchema, Vector{<:PromptingTools.AbstractMessage}}"
}, "#", -1);
const _hoisted_268 = /* @__PURE__ */ createBaseVNode("b", null, [
  /* @__PURE__ */ createBaseVNode("u", null, "PromptingTools.render")
], -1);
const _hoisted_269 = /* @__PURE__ */ createBaseVNode("i", null, "Method", -1);
const _hoisted_270 = /* @__PURE__ */ createStaticVNode("", 1);
const _hoisted_271 = /* @__PURE__ */ createStaticVNode("", 3);
const _hoisted_274 = /* @__PURE__ */ createBaseVNode("br", null, null, -1);
const _hoisted_275 = { style: { "border-width": "1px", "border-style": "solid", "border-color": "black", "padding": "1em", "border-radius": "25px" } };
const _hoisted_276 = /* @__PURE__ */ createBaseVNode("a", {
  id: "PromptingTools.render-Tuple{PromptingTools.NoSchema, Vector{<:PromptingTools.AbstractMessage}}",
  href: "#PromptingTools.render-Tuple{PromptingTools.NoSchema, Vector{<:PromptingTools.AbstractMessage}}"
}, "#", -1);
const _hoisted_277 = /* @__PURE__ */ createBaseVNode("b", null, [
  /* @__PURE__ */ createBaseVNode("u", null, "PromptingTools.render")
], -1);
const _hoisted_278 = /* @__PURE__ */ createBaseVNode("i", null, "Method", -1);
const _hoisted_279 = /* @__PURE__ */ createStaticVNode("", 6);
const _hoisted_285 = /* @__PURE__ */ createBaseVNode("li", null, [
  /* @__PURE__ */ createBaseVNode("p", null, "If a SystemMessage is missing, we inject a default one at the beginning of the conversation.")
], -1);
const _hoisted_286 = /* @__PURE__ */ createBaseVNode("li", null, [
  /* @__PURE__ */ createBaseVNode("p", null, "Only one SystemMessage is allowed (ie, cannot mix two conversations different system prompts).")
], -1);
const _hoisted_287 = /* @__PURE__ */ createBaseVNode("p", null, [
  /* @__PURE__ */ createBaseVNode("a", {
    href: "https://github.com/svilupp/PromptingTools.jl/blob/1671239c38c0b309f52f81d9522c51f593517a4f/src/llm_shared.jl#L2-L20",
    target: "_blank",
    rel: "noreferrer"
  }, "source")
], -1);
const _hoisted_288 = /* @__PURE__ */ createStaticVNode("", 23);
function _sfc_render(_ctx, _cache, $props, $setup, $data, $options) {
  return openBlock(), createElementBlock("div", null, [
    _hoisted_1,
    createBaseVNode("div", _hoisted_79, [
      _hoisted_80,
      createTextVNode(" "),
      _hoisted_81,
      createTextVNode(" — "),
      _hoisted_82,
      createTextVNode(". "),
      _hoisted_83,
      createBaseVNode("p", null, [
        createTextVNode("!!! Note: The prompt/AITemplate must have a placeholder "),
        _hoisted_86,
        createTextVNode(" (ie, "),
        createBaseVNode("code", null, toDisplayString(_ctx.choices), 1),
        createTextVNode(") that will be replaced with the encoded choices")
      ]),
      _hoisted_87
    ]),
    _hoisted_106,
    createBaseVNode("div", _hoisted_143, [
      _hoisted_144,
      createTextVNode(" "),
      _hoisted_145,
      createTextVNode(" — "),
      _hoisted_146,
      createTextVNode(". "),
      _hoisted_147,
      createBaseVNode("p", null, [
        createTextVNode("Use double handlebar placeholders (eg, "),
        createBaseVNode("code", null, toDisplayString(_ctx.name), 1),
        createTextVNode(") to define variables that can be replaced by the "),
        _hoisted_151,
        createTextVNode(" during the AI call (see example).")
      ]),
      _hoisted_152
    ]),
    _hoisted_171,
    _hoisted_196,
    _hoisted_197,
    createBaseVNode("div", _hoisted_238, [
      _hoisted_239,
      createTextVNode(" "),
      _hoisted_240,
      createTextVNode(" — "),
      _hoisted_241,
      createTextVNode(". "),
      _hoisted_242,
      createBaseVNode("p", null, [
        createTextVNode("Builds a history of the conversation to provide the prompt to the API. All unspecified kwargs are passed as replacements such that "),
        createBaseVNode("code", null, toDisplayString(_ctx.key) + "=>value", 1),
        createTextVNode(" in the template.")
      ]),
      _hoisted_243,
      _hoisted_244,
      _hoisted_245
    ]),
    _hoisted_246,
    createBaseVNode("div", _hoisted_247, [
      _hoisted_248,
      createTextVNode(" "),
      _hoisted_249,
      createTextVNode(" — "),
      _hoisted_250,
      createTextVNode(". "),
      _hoisted_251,
      createBaseVNode("p", null, [
        createTextVNode("Builds a history of the conversation to provide the prompt to the API. All unspecified kwargs are passed as replacements such that "),
        createBaseVNode("code", null, toDisplayString(_ctx.key) + "=>value", 1),
        createTextVNode(" in the template.")
      ]),
      _hoisted_252,
      _hoisted_253,
      _hoisted_254,
      _hoisted_255
    ]),
    _hoisted_256,
    createBaseVNode("div", _hoisted_257, [
      _hoisted_258,
      createTextVNode(" "),
      _hoisted_259,
      createTextVNode(" — "),
      _hoisted_260,
      createTextVNode(". "),
      _hoisted_261,
      createBaseVNode("p", null, [
        createTextVNode("Builds a history of the conversation to provide the prompt to the API. All unspecified kwargs are passed as replacements such that "),
        createBaseVNode("code", null, toDisplayString(_ctx.key) + "=>value", 1),
        createTextVNode(" in the template.")
      ]),
      _hoisted_262,
      _hoisted_263,
      _hoisted_264
    ]),
    _hoisted_265,
    createBaseVNode("div", _hoisted_266, [
      _hoisted_267,
      createTextVNode(" "),
      _hoisted_268,
      createTextVNode(" — "),
      _hoisted_269,
      createTextVNode(". "),
      _hoisted_270,
      createBaseVNode("p", null, [
        createTextVNode("Builds a history of the conversation to provide the prompt to the API. All unspecified kwargs are passed as replacements such that "),
        createBaseVNode("code", null, toDisplayString(_ctx.key) + "=>value", 1),
        createTextVNode(" in the template.")
      ]),
      _hoisted_271
    ]),
    _hoisted_274,
    createBaseVNode("div", _hoisted_275, [
      _hoisted_276,
      createTextVNode(" "),
      _hoisted_277,
      createTextVNode(" — "),
      _hoisted_278,
      createTextVNode(". "),
      _hoisted_279,
      createBaseVNode("ul", null, [
        createBaseVNode("li", null, [
          createBaseVNode("p", null, [
            createTextVNode("All unspecified kwargs are passed as replacements such that "),
            createBaseVNode("code", null, toDisplayString(_ctx.key) + "=>value", 1),
            createTextVNode(" in the template.")
          ])
        ]),
        _hoisted_285,
        _hoisted_286
      ]),
      _hoisted_287
    ]),
    _hoisted_288
  ]);
}
const reference = /* @__PURE__ */ _export_sfc(_sfc_main, [["render", _sfc_render]]);
export {
  __pageData,
  reference as default
};
