import { _ as _export_sfc, c as createElementBlock, a5 as createStaticVNode, o as openBlock } from "./chunks/framework.CHImlvd9.js";
const __pageData = JSON.parse('{"title":"Coverage of Model Providers","description":"","frontmatter":{},"headers":[],"relativePath":"coverage_of_model_providers.md","filePath":"coverage_of_model_providers.md","lastUpdated":null}');
const _sfc_main = { name: "coverage_of_model_providers.md" };
function _sfc_render(_ctx, _cache, $props, $setup, $data, $options) {
  return openBlock(), createElementBlock("div", null, _cache[0] || (_cache[0] = [
    createStaticVNode('<h1 id="Coverage-of-Model-Providers" tabindex="-1">Coverage of Model Providers <a class="header-anchor" href="#Coverage-of-Model-Providers" aria-label="Permalink to &quot;Coverage of Model Providers {#Coverage-of-Model-Providers}&quot;">​</a></h1><p>PromptingTools.jl routes AI calls through the use of subtypes of AbstractPromptSchema, which determine how data is formatted and where it is sent. (For example, OpenAI models have the corresponding subtype AbstractOpenAISchema, having the corresponding schemas - OpenAISchema, CustomOpenAISchema, etc.) This ensures that the data is correctly formatted for the specific AI model provider.</p><p>Below is an overview of the model providers supported by PromptingTools.jl, along with the corresponding schema information.</p><table tabindex="0"><thead><tr><th style="text-align:right;">Abstract Schema</th><th style="text-align:right;">Schema</th><th style="text-align:right;">Model Provider</th><th style="text-align:right;">aigenerate</th><th style="text-align:right;">aiembed</th><th style="text-align:right;">aiextract</th><th style="text-align:right;">aiscan</th><th style="text-align:right;">aiimage</th><th style="text-align:right;">aiclassify</th></tr></thead><tbody><tr><td style="text-align:right;">AbstractOpenAISchema</td><td style="text-align:right;">OpenAISchema</td><td style="text-align:right;">OpenAI</td><td style="text-align:right;">✅</td><td style="text-align:right;">✅</td><td style="text-align:right;">✅</td><td style="text-align:right;">✅</td><td style="text-align:right;">✅</td><td style="text-align:right;">✅</td></tr><tr><td style="text-align:right;">AbstractOpenAISchema</td><td style="text-align:right;">CustomOpenAISchema*</td><td style="text-align:right;">Any OpenAI-compatible API (eg, vLLM)*</td><td style="text-align:right;">✅</td><td style="text-align:right;">✅</td><td style="text-align:right;">✅</td><td style="text-align:right;">✅</td><td style="text-align:right;">✅</td><td style="text-align:right;">❌</td></tr><tr><td style="text-align:right;">AbstractOpenAISchema</td><td style="text-align:right;">LocalServerOpenAISchema**</td><td style="text-align:right;">Any OpenAI-compatible Local server**</td><td style="text-align:right;">✅</td><td style="text-align:right;">✅</td><td style="text-align:right;">✅</td><td style="text-align:right;">✅</td><td style="text-align:right;">✅</td><td style="text-align:right;">❌</td></tr><tr><td style="text-align:right;">AbstractOpenAISchema</td><td style="text-align:right;">MistralOpenAISchema</td><td style="text-align:right;">Mistral AI</td><td style="text-align:right;">✅</td><td style="text-align:right;">✅</td><td style="text-align:right;">✅</td><td style="text-align:right;">✅</td><td style="text-align:right;">✅</td><td style="text-align:right;">❌</td></tr><tr><td style="text-align:right;">AbstractOpenAISchema</td><td style="text-align:right;">DatabricksOpenAISchema</td><td style="text-align:right;">Databricks</td><td style="text-align:right;">✅</td><td style="text-align:right;">✅</td><td style="text-align:right;">✅</td><td style="text-align:right;">✅</td><td style="text-align:right;">✅</td><td style="text-align:right;">❌</td></tr><tr><td style="text-align:right;">AbstractOpenAISchema</td><td style="text-align:right;">FireworksOpenAISchema</td><td style="text-align:right;">Fireworks AI</td><td style="text-align:right;">✅</td><td style="text-align:right;">✅</td><td style="text-align:right;">✅</td><td style="text-align:right;">✅</td><td style="text-align:right;">✅</td><td style="text-align:right;">❌</td></tr><tr><td style="text-align:right;">AbstractOpenAISchema</td><td style="text-align:right;">TogetherOpenAISchema</td><td style="text-align:right;">Together AI</td><td style="text-align:right;">✅</td><td style="text-align:right;">✅</td><td style="text-align:right;">✅</td><td style="text-align:right;">✅</td><td style="text-align:right;">✅</td><td style="text-align:right;">❌</td></tr><tr><td style="text-align:right;">AbstractOpenAISchema</td><td style="text-align:right;">GroqOpenAISchema</td><td style="text-align:right;">Groq</td><td style="text-align:right;">✅</td><td style="text-align:right;">❌</td><td style="text-align:right;">✅</td><td style="text-align:right;">❌</td><td style="text-align:right;">❌</td><td style="text-align:right;">❌</td></tr><tr><td style="text-align:right;">AbstractOllamaSchema</td><td style="text-align:right;">OllamaSchema</td><td style="text-align:right;">Ollama (endpoint <code>api/chat</code>)</td><td style="text-align:right;">✅</td><td style="text-align:right;">✅</td><td style="text-align:right;">❌</td><td style="text-align:right;">✅</td><td style="text-align:right;">❌</td><td style="text-align:right;">❌</td></tr><tr><td style="text-align:right;">AbstractManagedSchema</td><td style="text-align:right;">AbstractOllamaManagedSchema</td><td style="text-align:right;">Ollama (endpoint <code>api/generate</code>)</td><td style="text-align:right;">✅</td><td style="text-align:right;">✅</td><td style="text-align:right;">❌</td><td style="text-align:right;">❌</td><td style="text-align:right;">❌</td><td style="text-align:right;">❌</td></tr><tr><td style="text-align:right;">AbstractAnthropicSchema</td><td style="text-align:right;">AnthropicSchema</td><td style="text-align:right;">Anthropic</td><td style="text-align:right;">✅</td><td style="text-align:right;">❌</td><td style="text-align:right;">✅</td><td style="text-align:right;">❌</td><td style="text-align:right;">❌</td><td style="text-align:right;">❌</td></tr><tr><td style="text-align:right;">AbstractGoogleSchema</td><td style="text-align:right;">GoogleSchema</td><td style="text-align:right;">Google Gemini</td><td style="text-align:right;">✅</td><td style="text-align:right;">❌</td><td style="text-align:right;">❌</td><td style="text-align:right;">❌</td><td style="text-align:right;">❌</td><td style="text-align:right;">❌</td></tr></tbody></table><ul><li>Catch-all implementation - Requires providing a <code>url</code> with <code>api_kwargs</code> and corresponding API key.</li></ul><p>** This schema is a flavor of CustomOpenAISchema with a <code>url</code> key preset by global preference key <code>LOCAL_SERVER</code>. It is specifically designed for seamless integration with Llama.jl and utilizes an ENV variable for the URL, making integration easier in certain workflows, such as when nested calls are involved and passing <code>api_kwargs</code> is more challenging.</p><p><strong>Note 1:</strong> <code>aitools</code> has identical support as <code>aiextract</code> for all providers, as it has the API requirements.</p><p><strong>Note 2:</strong> The <code>aiscan</code> and <code>aiimage</code> functions rely on specific endpoints being implemented by the provider. Ensure that the provider you choose supports these functionalities.</p><p>For more detailed explanations of the functions and schema information, refer to <a href="https://siml.earth/PromptingTools.jl/dev/how_it_works#ai*-Functions-Overview" target="_blank" rel="noreferrer">How It Works</a>.</p>', 9)
  ]));
}
const coverage_of_model_providers = /* @__PURE__ */ _export_sfc(_sfc_main, [["render", _sfc_render]]);
export {
  __pageData,
  coverage_of_model_providers as default
};
