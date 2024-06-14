import { _ as _export_sfc, c as createElementBlock, o as openBlock, a7 as createStaticVNode } from "./chunks/framework.BsEz-nSB.js";
const __pageData = JSON.parse('{"title":"Local models with Ollama.ai","description":"","frontmatter":{},"headers":[],"relativePath":"examples/working_with_ollama.md","filePath":"examples/working_with_ollama.md","lastUpdated":null}');
const _sfc_main = { name: "examples/working_with_ollama.md" };
const _hoisted_1 = /* @__PURE__ */ createStaticVNode('<h1 id="Local-models-with-Ollama.ai" tabindex="-1">Local models with Ollama.ai <a class="header-anchor" href="#Local-models-with-Ollama.ai" aria-label="Permalink to &quot;Local models with Ollama.ai {#Local-models-with-Ollama.ai}&quot;">​</a></h1><p>This file contains examples of how to work with <a href="https://ollama.ai/" target="_blank" rel="noreferrer">Ollama.ai</a> models. It assumes that you&#39;ve already installated and launched the Ollama server. For more details or troubleshooting advice, see the <a href="/PromptingTools.jl/v0.30.0/frequently_asked_questions#Frequently-Asked-Questions">Frequently Asked Questions</a> section.</p><p>First, let&#39;s import the package and define a helper link for calling un-exported functions:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> PromptingTools</span></span>\n<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">const</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> PT </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> PromptingTools</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span>PromptingTools</span></span></code></pre></div><p>There were are several models from <a href="https://ollama.ai/library" target="_blank" rel="noreferrer">https://ollama.ai/library</a> that we have added to our <code>PT.MODEL_REGISTRY</code>, which means you don&#39;t need to worry about schema changes: Eg, &quot;llama2&quot; or &quot;openhermes2.5-mistral&quot; (see <code>PT.list_registry()</code> and <code>PT.list_aliases()</code>)</p><p>Note: You must download these models prior to using them with <code>ollama pull &lt;model_name&gt;</code> in your Terminal.</p><div class="tip custom-block github-alert"><p class="custom-block-title">If you use Apple Mac M1-3, make sure to provide `api_kwargs=(; options=(; num_gpu=99))` to make sure the whole model is offloaded on your GPU. Current default is 1, which makes some models unusable. Example for running Mixtral: `msg = aigenerate(PT.OllamaSchema(), &quot;Count from 1 to 5 and then say hi.&quot;; model=&quot;dolphin-mixtral:8x7b-v2.5-q4_K_M&quot;, api_kwargs=(; options=(; num_gpu=99)))`</p><p></p></div><h2 id="Text-Generation-with-aigenerate" tabindex="-1">Text Generation with aigenerate <a class="header-anchor" href="#Text-Generation-with-aigenerate" aria-label="Permalink to &quot;Text Generation with aigenerate {#Text-Generation-with-aigenerate}&quot;">​</a></h2><h3 id="Simple-message" tabindex="-1">Simple message <a class="header-anchor" href="#Simple-message" aria-label="Permalink to &quot;Simple message {#Simple-message}&quot;">​</a></h3><p>TL;DR if you use models in <code>PT.MODEL_REGISTRY</code>, you don&#39;t need to add <code>schema</code> as the first argument:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">msg </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> aigenerate</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;Say hi!&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">; model </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;llama2&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span>AIMessage(&quot;Hello there! *adjusts glasses* It&#39;s nice to meet you! Is there anything I can help you with or would you like me to chat with you for a bit?&quot;)</span></span></code></pre></div><h3 id="Standard-string-interpolation" tabindex="-1">Standard string interpolation <a class="header-anchor" href="#Standard-string-interpolation" aria-label="Permalink to &quot;Standard string interpolation {#Standard-string-interpolation}&quot;">​</a></h3><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">model </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;openhermes2.5-mistral&quot;</span></span>\n<span class="line"></span>\n<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">a </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 1</span></span>\n<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">msg </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> aigenerate</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;What is `</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">$a</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">+</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">$a</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">`?&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">; model)</span></span>\n<span class="line"></span>\n<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">name </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;John&quot;</span></span>\n<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">msg </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> aigenerate</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;Say hi to {{name}}.&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">; name, model)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span>AIMessage(&quot;Hello John! *smiles* It&#39;s nice to meet you! Is there anything I can help you with today?&quot;)</span></span></code></pre></div><h3 id="Advanced-Prompts" tabindex="-1">Advanced Prompts <a class="header-anchor" href="#Advanced-Prompts" aria-label="Permalink to &quot;Advanced Prompts {#Advanced-Prompts}&quot;">​</a></h3><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">conversation </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> [</span></span>\n<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    PT</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">SystemMessage</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;You&#39;re master Yoda from Star Wars trying to help the user become a Yedi.&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">),</span></span>\n<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    PT</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">UserMessage</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;I have feelings for my iPhone. What should I do?&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)]</span></span>\n<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">msg </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> aigenerate</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(conversation; model)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span>AIMessage(&quot;(Deep sigh) A problem, you have. Feelings for an iPhone, hmm? (adjusts spectacles)</span></span>\n<span class="line"><span></span></span>\n<span class="line"><span>Much confusion, this causes. (scratches head) A being, you are. Attached to a device, you have become. (chuckles) Interesting, this is.</span></span>\n<span class="line"><span></span></span>\n<span class="line"><span>First, let go, you must. (winks) Hard, it is, but necessary, yes. Distract yourself, find something else, try. (pauses)</span></span>\n<span class="line"><span></span></span>\n<span class="line"><span>Or, perhaps, a balance, you seek? (nods) Both, enjoy and let go, the middle path, there is. (smirks) Finding joy in technology, without losing yourself, the trick, it is. (chuckles)</span></span>\n<span class="line"><span></span></span>\n<span class="line"><span>But fear not, young one! (grins) Help, I am here. Guide you, I will. The ways of the Yedi, teach you, I will. (winks) Patience and understanding, you must have. (nods)</span></span>\n<span class="line"><span></span></span>\n<span class="line"><span>Now, go forth! (gestures) Explore, discover, find your balance. (smiles) The Force be with you, it does! (grins)&quot;)</span></span></code></pre></div><h3 id="Schema-Changes-/-Custom-models" tabindex="-1">Schema Changes / Custom models <a class="header-anchor" href="#Schema-Changes-/-Custom-models" aria-label="Permalink to &quot;Schema Changes / Custom models {#Schema-Changes-/-Custom-models}&quot;">​</a></h3><p>If you&#39;re using some model that is not in the registry, you can either add it:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">PT</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">register_model!</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(;</span></span>\n<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    name </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;llama123&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>\n<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    schema </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> PT</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">OllamaSchema</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(),</span></span>\n<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    description </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Some model&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>\n<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">PT</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">MODEL_ALIASES[</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;l123&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">] </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;llama123&quot;</span><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;"> # set an alias you like for it</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span>&quot;llama123&quot;</span></span></code></pre></div><p>OR define the schema explicitly (to avoid dispatch on global <code>PT.PROMPT_SCHEMA</code>):</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">schema </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> PT</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">OllamaSchema</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">()</span></span>\n<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">aigenerate</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(schema, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;Say hi!&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">; model </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;llama2&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span>AIMessage(&quot;Hello there! *smiling face* It&#39;s nice to meet you! I&#39;m here to help you with any questions or tasks you may have, so feel free to ask me anything. Is there something specific you need assistance with today? 😊&quot;)</span></span></code></pre></div><p>Note: If you only use Ollama, you can change the default schema to <code>PT.OllamaSchema()</code> via <code>PT.set_preferences!(&quot;PROMPT_SCHEMA&quot; =&gt; &quot;OllamaSchema&quot;, &quot;MODEL_CHAT&quot;=&gt;&quot;llama2&quot;)</code></p><p>Restart your session and run <code>aigenerate(&quot;Say hi!&quot;)</code> to test it.</p><p>! Note that in version 0.6, we&#39;ve introduced <code>OllamaSchema</code>, which superseded <code>OllamaManagedSchema</code> and allows multi-turn conversations and conversations with images (eg, with Llava and Bakllava models). <code>OllamaManagedSchema</code> has been kept for compatibility and as an example of a schema where one provides a prompt as a string (not dictionaries like OpenAI API).</p><h2 id="Providing-Images-with-aiscan" tabindex="-1">Providing Images with aiscan <a class="header-anchor" href="#Providing-Images-with-aiscan" aria-label="Permalink to &quot;Providing Images with aiscan {#Providing-Images-with-aiscan}&quot;">​</a></h2><p>It&#39;s as simple as providing a local image path (keyword <code>image_path</code>). You can provide one or more images:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">msg </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> aiscan</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;Describe the image&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">; image_path</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">[</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;julia.png&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;python.png&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">] model</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;bakllava&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><p><code>image_url</code> keyword is not supported at the moment (use <code>Downloads.download</code> to download the image locally).</p><h2 id="Embeddings-with-aiembed" tabindex="-1">Embeddings with aiembed <a class="header-anchor" href="#Embeddings-with-aiembed" aria-label="Permalink to &quot;Embeddings with aiembed {#Embeddings-with-aiembed}&quot;">​</a></h2><h3 id="Simple-embedding-for-one-document" tabindex="-1">Simple embedding for one document <a class="header-anchor" href="#Simple-embedding-for-one-document" aria-label="Permalink to &quot;Simple embedding for one document {#Simple-embedding-for-one-document}&quot;">​</a></h3><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">msg </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> aiembed</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(schema, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;Embed me&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">; model) </span><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;"># access msg.content</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span>PromptingTools.DataMessage(JSON3.Array{Float64, Vector{UInt8}, SubArray{UInt64, 1, Vector{UInt64}, Tuple{UnitRange{Int64}}, true}} of size (4096,))</span></span></code></pre></div><p>One document and we materialize the data into a Vector with copy (<code>postprocess</code> function argument)</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">msg </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> aiembed</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(schema, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;Embed me&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, copy; model)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span>PromptingTools.DataMessage(Vector{Float64} of size (4096,))</span></span></code></pre></div><h3 id="Multiple-documents-embedding" tabindex="-1">Multiple documents embedding <a class="header-anchor" href="#Multiple-documents-embedding" aria-label="Permalink to &quot;Multiple documents embedding {#Multiple-documents-embedding}&quot;">​</a></h3><p>Multiple documents - embedded sequentially, you can get faster speed with async</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">msg </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> aiembed</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(schema, [</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;Embed me&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;Embed me&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">]; model)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span>PromptingTools.DataMessage(Matrix{Float64} of size (4096, 2))</span></span></code></pre></div><p>You can use Threads.@spawn or asyncmap, whichever you prefer, to paralellize the model calls</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">docs </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> [</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;Embed me&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;Embed me&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">]</span></span>\n<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">tasks </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> asyncmap</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(docs) </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">do</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> doc</span></span>\n<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    msg </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> aiembed</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(schema, doc; model)</span></span>\n<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">end</span></span>\n<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">embedding </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> mapreduce</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(x </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">-&gt;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> x</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">content, hcat, tasks)</span></span>\n<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">size</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(embedding)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span>4096×2 Matrix{Float64}:</span></span>\n<span class="line"><span>...</span></span></code></pre></div><h3 id="Using-postprocessing-function" tabindex="-1">Using postprocessing function <a class="header-anchor" href="#Using-postprocessing-function" aria-label="Permalink to &quot;Using postprocessing function {#Using-postprocessing-function}&quot;">​</a></h3><p>Add normalization as postprocessing function to normalize embeddings on reception (for easy cosine similarity later)</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> LinearAlgebra</span></span>\n<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">schema </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> PT</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">OllamaSchema</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">()</span></span>\n<span class="line"></span>\n<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">msg </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> aiembed</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(schema,</span></span>\n<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    [</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;embed me&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;and me too&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">],</span></span>\n<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    LinearAlgebra</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">normalize;</span></span>\n<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    model </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;openhermes2.5-mistral&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span>PromptingTools.DataMessage(Matrix{Float64} of size (4096, 2))</span></span></code></pre></div><p>Cosine similarity is then a simple multiplication</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">msg</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">content</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">&#39;</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> *</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> msg</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">content[:, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">]</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code"><code><span class="line"><span>2-element Vector{Float64}:</span></span>\n<span class="line"><span> 0.9999999999999982</span></span>\n<span class="line"><span> 0.40796033843072876</span></span></code></pre></div><hr><p><em>This page was generated using <a href="https://github.com/fredrikekre/Literate.jl" target="_blank" rel="noreferrer">Literate.jl</a>.</em></p>', 56);
const _hoisted_57 = [
  _hoisted_1
];
function _sfc_render(_ctx, _cache, $props, $setup, $data, $options) {
  return openBlock(), createElementBlock("div", null, _hoisted_57);
}
const working_with_ollama = /* @__PURE__ */ _export_sfc(_sfc_main, [["render", _sfc_render]]);
export {
  __pageData,
  working_with_ollama as default
};
