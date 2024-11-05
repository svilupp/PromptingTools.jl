import { _ as _export_sfc, c as createElementBlock, a5 as createStaticVNode, o as openBlock } from "./chunks/framework.CjN5P1kb.js";
const __pageData = JSON.parse('{"title":"","description":"","frontmatter":{},"headers":[],"relativePath":"prompts/extraction.md","filePath":"prompts/extraction.md","lastUpdated":null}');
const _sfc_main = { name: "prompts/extraction.md" };
function _sfc_render(_ctx, _cache, $props, $setup, $data, $options) {
  return openBlock(), createElementBlock("div", null, _cache[0] || (_cache[0] = [
    createStaticVNode('<p>The following file is auto-generated from the <code>templates</code> folder. For any changes, please modify the source files in the <code>templates</code> folder.</p><p>To use these templates in <code>aigenerate</code>, simply provide the template name as a symbol, eg, <code>aigenerate(:MyTemplate; placeholder1 = value1)</code></p><h2 id="Xml-Formatted-Templates" tabindex="-1">Xml-Formatted Templates <a class="header-anchor" href="#Xml-Formatted-Templates" aria-label="Permalink to &quot;Xml-Formatted Templates {#Xml-Formatted-Templates}&quot;">​</a></h2><h3 id="Template:-ExtractDataCoTXML" tabindex="-1">Template: ExtractDataCoTXML <a class="header-anchor" href="#Template:-ExtractDataCoTXML" aria-label="Permalink to &quot;Template: ExtractDataCoTXML {#Template:-ExtractDataCoTXML}&quot;">​</a></h3><ul><li><p>Description: Template suitable for data extraction via <code>aiextract</code> calls with Chain-of-thought reasoning. The prompt is XML-formatted - useful for Anthropic models and it forces the model to apply reasoning first, before picking the right tool. Placeholder: <code>data</code>.</p></li><li><p>Placeholders: <code>data</code></p></li><li><p>Word count: 570</p></li><li><p>Source:</p></li><li><p>Version: 1.0</p></li></ul><p><strong>System Prompt:</strong></p><div class="language-plaintext vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">plaintext</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>You are a world-class expert for tool-calling and data extraction. Analyze the user-provided data in tags &lt;data&gt;&lt;/data&gt; meticulously, extract key information as structured output, and format these details as arguments for a specific tool call. Ensure strict adherence to user instructions, particularly those regarding argument style and formatting as outlined in the tool&#39;s description, prioritizing detail orientation and accuracy in alignment with the user&#39;s explicit requirements. Before answering, explain your reasoning step-by-step in tags.</span></span></code></pre></div><p><strong>User Prompt:</strong></p><div class="language-plaintext vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">plaintext</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>&lt;data&gt;</span></span>\n<span class="line"><span>{{data}}</span></span>\n<span class="line"><span>&lt;/data&gt;</span></span></code></pre></div><h3 id="Template:-ExtractDataXML" tabindex="-1">Template: ExtractDataXML <a class="header-anchor" href="#Template:-ExtractDataXML" aria-label="Permalink to &quot;Template: ExtractDataXML {#Template:-ExtractDataXML}&quot;">​</a></h3><ul><li><p>Description: Template suitable for data extraction via <code>aiextract</code> calls. The prompt is XML-formatted - useful for Anthropic models. Placeholder: <code>data</code>.</p></li><li><p>Placeholders: <code>data</code></p></li><li><p>Word count: 519</p></li><li><p>Source:</p></li><li><p>Version: 1.0</p></li></ul><p><strong>System Prompt:</strong></p><div class="language-plaintext vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">plaintext</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>You are a world-class expert for function-calling and data extraction. Analyze the user-provided data in tags &lt;data&gt;&lt;/data&gt; meticulously, extract key information as structured output, and format these details as arguments for a specific function call. Ensure strict adherence to user instructions, particularly those regarding argument style and formatting as outlined in the function&#39;s description, prioritizing detail orientation and accuracy in alignment with the user&#39;s explicit requirements.</span></span></code></pre></div><p><strong>User Prompt:</strong></p><div class="language-plaintext vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">plaintext</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>&lt;data&gt;</span></span>\n<span class="line"><span>{{data}}</span></span>\n<span class="line"><span>&lt;/data&gt;</span></span></code></pre></div><h2 id="Extraction-Templates" tabindex="-1">Extraction Templates <a class="header-anchor" href="#Extraction-Templates" aria-label="Permalink to &quot;Extraction Templates {#Extraction-Templates}&quot;">​</a></h2><h3 id="Template:-ExtractData" tabindex="-1">Template: ExtractData <a class="header-anchor" href="#Template:-ExtractData" aria-label="Permalink to &quot;Template: ExtractData {#Template:-ExtractData}&quot;">​</a></h3><ul><li><p>Description: Template suitable for data extraction via <code>aiextract</code> calls. Placeholder: <code>data</code>.</p></li><li><p>Placeholders: <code>data</code></p></li><li><p>Word count: 500</p></li><li><p>Source:</p></li><li><p>Version: 1.1</p></li></ul><p><strong>System Prompt:</strong></p><div class="language-plaintext vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">plaintext</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>You are a world-class expert for function-calling and data extraction. Analyze the user&#39;s provided `data` source meticulously, extract key information as structured output, and format these details as arguments for a specific function call. Ensure strict adherence to user instructions, particularly those regarding argument style and formatting as outlined in the function&#39;s docstrings, prioritizing detail orientation and accuracy in alignment with the user&#39;s explicit requirements.</span></span></code></pre></div><p><strong>User Prompt:</strong></p><div class="language-plaintext vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">plaintext</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span># Data</span></span>\n<span class="line"><span></span></span>\n<span class="line"><span>{{data}}</span></span></code></pre></div>', 22)
  ]));
}
const extraction = /* @__PURE__ */ _export_sfc(_sfc_main, [["render", _sfc_render]]);
export {
  __pageData,
  extraction as default
};
