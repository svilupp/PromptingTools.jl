---
outline: deep
---


# Reference {#Reference}
- [`PromptingTools.Experimental`](#PromptingTools.Experimental)
- [`PromptingTools.Experimental.AgentTools`](#PromptingTools.Experimental.AgentTools)
- [`PromptingTools.Experimental.RAGTools`](#PromptingTools.Experimental.RAGTools)
- [`PromptingTools.ALLOWED_PREFERENCES`](#PromptingTools.ALLOWED_PREFERENCES)
- [`PromptingTools.ALTERNATIVE_GENERATION_COSTS`](#PromptingTools.ALTERNATIVE_GENERATION_COSTS)
- [`PromptingTools.CONV_HISTORY`](#PromptingTools.CONV_HISTORY)
- [`PromptingTools.MODEL_ALIASES`](#PromptingTools.MODEL_ALIASES)
- [`PromptingTools.MODEL_REGISTRY`](#PromptingTools.MODEL_REGISTRY)
- [`PromptingTools.OPENAI_TOKEN_IDS`](#PromptingTools.OPENAI_TOKEN_IDS)
- [`PromptingTools.PREFERENCES`](#PromptingTools.PREFERENCES)
- [`PromptingTools.RESERVED_KWARGS`](#PromptingTools.RESERVED_KWARGS)
- [`PromptingTools.AICode`](#PromptingTools.AICode)
- [`PromptingTools.AIMessage`](#PromptingTools.AIMessage)
- [`PromptingTools.AITemplate`](#PromptingTools.AITemplate)
- [`PromptingTools.AITemplateMetadata`](#PromptingTools.AITemplateMetadata)
- [`PromptingTools.AbstractPromptSchema`](#PromptingTools.AbstractPromptSchema)
- [`PromptingTools.ChatMLSchema`](#PromptingTools.ChatMLSchema)
- [`PromptingTools.CustomOpenAISchema`](#PromptingTools.CustomOpenAISchema)
- [`PromptingTools.DataMessage`](#PromptingTools.DataMessage)
- [`PromptingTools.DatabricksOpenAISchema`](#PromptingTools.DatabricksOpenAISchema)
- [`PromptingTools.Experimental.AgentTools.AICall`](#PromptingTools.Experimental.AgentTools.AICall)
- [`PromptingTools.Experimental.AgentTools.AICodeFixer`](#PromptingTools.Experimental.AgentTools.AICodeFixer)
- [`PromptingTools.Experimental.AgentTools.RetryConfig`](#PromptingTools.Experimental.AgentTools.RetryConfig)
- [`PromptingTools.Experimental.AgentTools.SampleNode`](#PromptingTools.Experimental.AgentTools.SampleNode)
- [`PromptingTools.Experimental.AgentTools.ThompsonSampling`](#PromptingTools.Experimental.AgentTools.ThompsonSampling)
- [`PromptingTools.Experimental.AgentTools.UCT`](#PromptingTools.Experimental.AgentTools.UCT)
- [`PromptingTools.Experimental.RAGTools.ChunkIndex`](#PromptingTools.Experimental.RAGTools.ChunkIndex)
- [`PromptingTools.Experimental.RAGTools.JudgeAllScores`](#PromptingTools.Experimental.RAGTools.JudgeAllScores)
- [`PromptingTools.Experimental.RAGTools.JudgeRating`](#PromptingTools.Experimental.RAGTools.JudgeRating)
- [`PromptingTools.Experimental.RAGTools.MultiIndex`](#PromptingTools.Experimental.RAGTools.MultiIndex)
- [`PromptingTools.Experimental.RAGTools.RAGContext`](#PromptingTools.Experimental.RAGTools.RAGContext)
- [`PromptingTools.FireworksOpenAISchema`](#PromptingTools.FireworksOpenAISchema)
- [`PromptingTools.GoogleSchema`](#PromptingTools.GoogleSchema)
- [`PromptingTools.ItemsExtract`](#PromptingTools.ItemsExtract)
- [`PromptingTools.LocalServerOpenAISchema`](#PromptingTools.LocalServerOpenAISchema)
- [`PromptingTools.MaybeExtract`](#PromptingTools.MaybeExtract)
- [`PromptingTools.MistralOpenAISchema`](#PromptingTools.MistralOpenAISchema)
- [`PromptingTools.ModelSpec`](#PromptingTools.ModelSpec)
- [`PromptingTools.NoSchema`](#PromptingTools.NoSchema)
- [`PromptingTools.OllamaManagedSchema`](#PromptingTools.OllamaManagedSchema)
- [`PromptingTools.OllamaSchema`](#PromptingTools.OllamaSchema)
- [`PromptingTools.OpenAISchema`](#PromptingTools.OpenAISchema)
- [`PromptingTools.TestEchoGoogleSchema`](#PromptingTools.TestEchoGoogleSchema)
- [`PromptingTools.TestEchoOllamaManagedSchema`](#PromptingTools.TestEchoOllamaManagedSchema)
- [`PromptingTools.TestEchoOllamaSchema`](#PromptingTools.TestEchoOllamaSchema)
- [`PromptingTools.TestEchoOpenAISchema`](#PromptingTools.TestEchoOpenAISchema)
- [`PromptingTools.TogetherOpenAISchema`](#PromptingTools.TogetherOpenAISchema)
- [`PromptingTools.UserMessageWithImages`](#PromptingTools.UserMessageWithImages-Tuple{AbstractString})
- [`PromptingTools.X123`](#PromptingTools.X123)
- [`OpenAI.create_chat`](#OpenAI.create_chat-Tuple{PromptingTools.CustomOpenAISchema,%20AbstractString,%20AbstractString,%20Any})
- [`OpenAI.create_chat`](#OpenAI.create_chat-Tuple{PromptingTools.LocalServerOpenAISchema,%20AbstractString,%20AbstractString,%20Any})
- [`OpenAI.create_chat`](#OpenAI.create_chat-Tuple{PromptingTools.MistralOpenAISchema,%20AbstractString,%20AbstractString,%20Any})
- [`PromptingTools.Experimental.APITools.create_websearch`](#PromptingTools.Experimental.APITools.create_websearch-Tuple{AbstractString})
- [`PromptingTools.Experimental.APITools.tavily_api`](#PromptingTools.Experimental.APITools.tavily_api-Tuple{})
- [`PromptingTools.Experimental.AgentTools.AIClassify`](#PromptingTools.Experimental.AgentTools.AIClassify-Tuple)
- [`PromptingTools.Experimental.AgentTools.AIEmbed`](#PromptingTools.Experimental.AgentTools.AIEmbed-Tuple)
- [`PromptingTools.Experimental.AgentTools.AIExtract`](#PromptingTools.Experimental.AgentTools.AIExtract-Tuple)
- [`PromptingTools.Experimental.AgentTools.AIGenerate`](#PromptingTools.Experimental.AgentTools.AIGenerate-Tuple)
- [`PromptingTools.Experimental.AgentTools.AIScan`](#PromptingTools.Experimental.AgentTools.AIScan-Tuple)
- [`PromptingTools.Experimental.AgentTools.add_feedback!`](#PromptingTools.Experimental.AgentTools.add_feedback!-Tuple{AbstractVector{<:PromptingTools.AbstractMessage},%20PromptingTools.Experimental.AgentTools.SampleNode})
- [`PromptingTools.Experimental.AgentTools.aicodefixer_feedback`](#PromptingTools.Experimental.AgentTools.aicodefixer_feedback-Tuple{AbstractVector{<:PromptingTools.AbstractMessage}})
- [`PromptingTools.Experimental.AgentTools.airetry!`](#PromptingTools.Experimental.AgentTools.airetry!)
- [`PromptingTools.Experimental.AgentTools.backpropagate!`](#PromptingTools.Experimental.AgentTools.backpropagate!-Tuple{PromptingTools.Experimental.AgentTools.SampleNode})
- [`PromptingTools.Experimental.AgentTools.beta_sample`](#PromptingTools.Experimental.AgentTools.beta_sample-Tuple{Real,%20Real})
- [`PromptingTools.Experimental.AgentTools.collect_all_feedback`](#PromptingTools.Experimental.AgentTools.collect_all_feedback-Tuple{PromptingTools.Experimental.AgentTools.SampleNode})
- [`PromptingTools.Experimental.AgentTools.evaluate_condition!`](#PromptingTools.Experimental.AgentTools.evaluate_condition!)
- [`PromptingTools.Experimental.AgentTools.expand!`](#PromptingTools.Experimental.AgentTools.expand!-Tuple{PromptingTools.Experimental.AgentTools.SampleNode,%20Any})
- [`PromptingTools.Experimental.AgentTools.extract_config`](#PromptingTools.Experimental.AgentTools.extract_config-Union{Tuple{T},%20Tuple{Any,%20T}}%20where%20T)
- [`PromptingTools.Experimental.AgentTools.find_node`](#PromptingTools.Experimental.AgentTools.find_node-Tuple{PromptingTools.Experimental.AgentTools.SampleNode,%20Integer})
- [`PromptingTools.Experimental.AgentTools.gamma_sample`](#PromptingTools.Experimental.AgentTools.gamma_sample-Tuple{Real,%20Real})
- [`PromptingTools.Experimental.AgentTools.last_message`](#PromptingTools.Experimental.AgentTools.last_message-Tuple{PromptingTools.Experimental.AgentTools.AICallBlock})
- [`PromptingTools.Experimental.AgentTools.last_output`](#PromptingTools.Experimental.AgentTools.last_output-Tuple{PromptingTools.Experimental.AgentTools.AICallBlock})
- [`PromptingTools.Experimental.AgentTools.print_samples`](#PromptingTools.Experimental.AgentTools.print_samples-Tuple{PromptingTools.Experimental.AgentTools.SampleNode})
- [`PromptingTools.Experimental.AgentTools.remove_used_kwargs`](#PromptingTools.Experimental.AgentTools.remove_used_kwargs-Tuple{NamedTuple,%20AbstractVector{<:PromptingTools.AbstractMessage}})
- [`PromptingTools.Experimental.AgentTools.reset_success!`](#PromptingTools.Experimental.AgentTools.reset_success!)
- [`PromptingTools.Experimental.AgentTools.run!`](#PromptingTools.Experimental.AgentTools.run!-Tuple{AICodeFixer})
- [`PromptingTools.Experimental.AgentTools.run!`](#PromptingTools.Experimental.AgentTools.run!-Tuple{PromptingTools.Experimental.AgentTools.AICallBlock})
- [`PromptingTools.Experimental.AgentTools.score`](#PromptingTools.Experimental.AgentTools.score-Tuple{PromptingTools.Experimental.AgentTools.SampleNode,%20PromptingTools.Experimental.AgentTools.ThompsonSampling})
- [`PromptingTools.Experimental.AgentTools.score`](#PromptingTools.Experimental.AgentTools.score-Tuple{PromptingTools.Experimental.AgentTools.SampleNode,%20PromptingTools.Experimental.AgentTools.UCT})
- [`PromptingTools.Experimental.AgentTools.select_best`](#PromptingTools.Experimental.AgentTools.select_best)
- [`PromptingTools.Experimental.AgentTools.split_multi_samples`](#PromptingTools.Experimental.AgentTools.split_multi_samples-Tuple{Any})
- [`PromptingTools.Experimental.AgentTools.truncate_conversation`](#PromptingTools.Experimental.AgentTools.truncate_conversation-Tuple{AbstractVector{<:PromptingTools.AbstractMessage}})
- [`PromptingTools.Experimental.AgentTools.unwrap_aicall_args`](#PromptingTools.Experimental.AgentTools.unwrap_aicall_args-Tuple{Any})
- [`PromptingTools.Experimental.RAGTools._normalize`](#PromptingTools.Experimental.RAGTools._normalize)
- [`PromptingTools.Experimental.RAGTools.airag`](#PromptingTools.Experimental.RAGTools.airag)
- [`PromptingTools.Experimental.RAGTools.build_context`](#PromptingTools.Experimental.RAGTools.build_context-Tuple{PromptingTools.Experimental.RAGTools.AbstractChunkIndex,%20CandidateChunks})
- [`PromptingTools.Experimental.RAGTools.build_index`](#PromptingTools.Experimental.RAGTools.build_index-Tuple{Vector{<:AbstractString}})
- [`PromptingTools.Experimental.RAGTools.build_index`](#PromptingTools.Experimental.RAGTools.build_index)
- [`PromptingTools.Experimental.RAGTools.build_qa_evals`](#PromptingTools.Experimental.RAGTools.build_qa_evals-Tuple{Vector{<:AbstractString},%20Vector{<:AbstractString}})
- [`PromptingTools.Experimental.RAGTools.build_tags`](#PromptingTools.Experimental.RAGTools.build_tags)
- [`PromptingTools.Experimental.RAGTools.cohere_api`](#PromptingTools.Experimental.RAGTools.cohere_api-Tuple{})
- [`PromptingTools.Experimental.RAGTools.find_closest`](#PromptingTools.Experimental.RAGTools.find_closest-Tuple{AbstractMatrix{<:Real},%20AbstractVector{<:Real}})
- [`PromptingTools.Experimental.RAGTools.get_chunks`](#PromptingTools.Experimental.RAGTools.get_chunks-Tuple{Vector{<:AbstractString}})
- [`PromptingTools.Experimental.RAGTools.get_embeddings`](#PromptingTools.Experimental.RAGTools.get_embeddings-Tuple{Vector{<:AbstractString}})
- [`PromptingTools.Experimental.RAGTools.get_metadata`](#PromptingTools.Experimental.RAGTools.get_metadata-Tuple{Vector{<:AbstractString}})
- [`PromptingTools.Experimental.RAGTools.metadata_extract`](#PromptingTools.Experimental.RAGTools.metadata_extract-Tuple{PromptingTools.Experimental.RAGTools.MetadataItem})
- [`PromptingTools.Experimental.RAGTools.rerank`](#PromptingTools.Experimental.RAGTools.rerank-Tuple{PromptingTools.Experimental.RAGTools.CohereRerank,%20PromptingTools.Experimental.RAGTools.AbstractChunkIndex,%20Any,%20Any})
- [`PromptingTools.Experimental.RAGTools.run_qa_evals`](#PromptingTools.Experimental.RAGTools.run_qa_evals-Tuple{PromptingTools.Experimental.RAGTools.QAEvalItem,%20PromptingTools.Experimental.RAGTools.RAGContext})
- [`PromptingTools.Experimental.RAGTools.run_qa_evals`](#PromptingTools.Experimental.RAGTools.run_qa_evals-Tuple{PromptingTools.Experimental.RAGTools.AbstractChunkIndex,%20AbstractVector{<:PromptingTools.Experimental.RAGTools.QAEvalItem}})
- [`PromptingTools.Experimental.RAGTools.score_retrieval_hit`](#PromptingTools.Experimental.RAGTools.score_retrieval_hit-Tuple{AbstractString,%20Vector{<:AbstractString}})
- [`PromptingTools.Experimental.RAGTools.score_retrieval_rank`](#PromptingTools.Experimental.RAGTools.score_retrieval_rank-Tuple{AbstractString,%20Vector{<:AbstractString}})
- [`PromptingTools.aiclassify`](#PromptingTools.aiclassify-Union{Tuple{T},%20Tuple{PromptingTools.AbstractOpenAISchema,%20Union{AbstractString,%20PromptingTools.AbstractMessage,%20Vector{<:PromptingTools.AbstractMessage}}}}%20where%20T<:Union{AbstractString,%20Tuple{var"#s110",%20var"#s104"}%20where%20{var"#s110"<:AbstractString,%20var"#s104"<:AbstractString}})
- [`PromptingTools.aiembed`](#PromptingTools.aiembed-Union{Tuple{F},%20Tuple{PromptingTools.AbstractOllamaManagedSchema,%20AbstractString},%20Tuple{PromptingTools.AbstractOllamaManagedSchema,%20AbstractString,%20F}}%20where%20F<:Function)
- [`PromptingTools.aiembed`](#PromptingTools.aiembed-Union{Tuple{F},%20Tuple{PromptingTools.AbstractOpenAISchema,%20Union{AbstractString,%20AbstractVector{<:AbstractString}}},%20Tuple{PromptingTools.AbstractOpenAISchema,%20Union{AbstractString,%20AbstractVector{<:AbstractString}},%20F}}%20where%20F<:Function)
- [`PromptingTools.aiextract`](#PromptingTools.aiextract-Tuple{PromptingTools.AbstractOpenAISchema,%20Union{AbstractString,%20PromptingTools.AbstractMessage,%20Vector{<:PromptingTools.AbstractMessage}}})
- [`PromptingTools.aigenerate`](#PromptingTools.aigenerate-Tuple{PromptingTools.AbstractOllamaSchema,%20Union{AbstractString,%20PromptingTools.AbstractMessage,%20Vector{<:PromptingTools.AbstractMessage}}})
- [`PromptingTools.aigenerate`](#PromptingTools.aigenerate-Tuple{PromptingTools.AbstractOpenAISchema,%20Union{AbstractString,%20PromptingTools.AbstractMessage,%20Vector{<:PromptingTools.AbstractMessage}}})
- [`PromptingTools.aigenerate`](#PromptingTools.aigenerate-Tuple{PromptingTools.AbstractGoogleSchema,%20Union{AbstractString,%20PromptingTools.AbstractMessage,%20Vector{<:PromptingTools.AbstractMessage}}})
- [`PromptingTools.aigenerate`](#PromptingTools.aigenerate-Tuple{PromptingTools.AbstractOllamaManagedSchema,%20Union{AbstractString,%20PromptingTools.AbstractMessage,%20Vector{<:PromptingTools.AbstractMessage}}})
- [`PromptingTools.aiimage`](#PromptingTools.aiimage-Tuple{PromptingTools.AbstractOpenAISchema,%20Union{AbstractString,%20PromptingTools.AbstractMessage,%20Vector{<:PromptingTools.AbstractMessage}}})
- [`PromptingTools.aiscan`](#PromptingTools.aiscan-Tuple{PromptingTools.AbstractOpenAISchema,%20Union{AbstractString,%20PromptingTools.AbstractMessage,%20Vector{<:PromptingTools.AbstractMessage}}})
- [`PromptingTools.aiscan`](#PromptingTools.aiscan-Tuple{PromptingTools.AbstractOllamaSchema,%20Union{AbstractString,%20PromptingTools.AbstractMessage,%20Vector{<:PromptingTools.AbstractMessage}}})
- [`PromptingTools.aitemplates`](#PromptingTools.aitemplates)
- [`PromptingTools.aitemplates`](#PromptingTools.aitemplates-Tuple{AbstractString})
- [`PromptingTools.aitemplates`](#PromptingTools.aitemplates-Tuple{Symbol})
- [`PromptingTools.aitemplates`](#PromptingTools.aitemplates-Tuple{Regex})
- [`PromptingTools.auth_header`](#PromptingTools.auth_header-Tuple{Union{Nothing,%20AbstractString}})
- [`PromptingTools.build_template_metadata`](#PromptingTools.build_template_metadata)
- [`PromptingTools.call_cost`](#PromptingTools.call_cost-Tuple{Int64,%20Int64,%20String})
- [`PromptingTools.call_cost_alternative`](#PromptingTools.call_cost_alternative-Tuple{Any,%20Any})
- [`PromptingTools.create_template`](#PromptingTools.create_template-Tuple{AbstractString,%20AbstractString})
- [`PromptingTools.decode_choices`](#PromptingTools.decode_choices-Tuple{PromptingTools.OpenAISchema,%20AbstractVector{<:AbstractString},%20AIMessage})
- [`PromptingTools.detect_base_main_overrides`](#PromptingTools.detect_base_main_overrides-Tuple{AbstractString})
- [`PromptingTools.encode_choices`](#PromptingTools.encode_choices-Tuple{PromptingTools.OpenAISchema,%20AbstractVector{<:AbstractString}})
- [`PromptingTools.eval!`](#PromptingTools.eval!-Tuple{PromptingTools.AbstractCodeBlock})
- [`PromptingTools.extract_code_blocks`](#PromptingTools.extract_code_blocks-Tuple{T}%20where%20T<:AbstractString)
- [`PromptingTools.extract_code_blocks_fallback`](#PromptingTools.extract_code_blocks_fallback-Union{Tuple{T},%20Tuple{T,%20AbstractString}}%20where%20T<:AbstractString)
- [`PromptingTools.extract_function_name`](#PromptingTools.extract_function_name-Tuple{AbstractString})
- [`PromptingTools.extract_function_names`](#PromptingTools.extract_function_names-Tuple{AbstractString})
- [`PromptingTools.extract_julia_imports`](#PromptingTools.extract_julia_imports-Tuple{AbstractString})
- [`PromptingTools.finalize_outputs`](#PromptingTools.finalize_outputs-Tuple{Union{AbstractString,%20PromptingTools.AbstractMessage,%20Vector{<:PromptingTools.AbstractMessage}},%20Any,%20Union{Nothing,%20PromptingTools.AbstractMessage,%20AbstractVector{<:PromptingTools.AbstractMessage}}})
- [`PromptingTools.find_subsequence_positions`](#PromptingTools.find_subsequence_positions-Tuple{Any,%20Any})
- [`PromptingTools.function_call_signature`](#PromptingTools.function_call_signature-Tuple{Type})
- [`PromptingTools.get_preferences`](#PromptingTools.get_preferences-Tuple{String})
- [`PromptingTools.ggi_generate_content`](#PromptingTools.ggi_generate_content)
- [`PromptingTools.has_julia_prompt`](#PromptingTools.has_julia_prompt-Tuple{T}%20where%20T<:AbstractString)
- [`PromptingTools.length_longest_common_subsequence`](#PromptingTools.length_longest_common_subsequence-Tuple{Any,%20Any})
- [`PromptingTools.list_aliases`](#PromptingTools.list_aliases-Tuple{})
- [`PromptingTools.list_registry`](#PromptingTools.list_registry-Tuple{})
- [`PromptingTools.load_conversation`](#PromptingTools.load_conversation-Tuple{Union{AbstractString,%20IO}})
- [`PromptingTools.load_template`](#PromptingTools.load_template-Tuple{Union{AbstractString,%20IO}})
- [`PromptingTools.load_templates!`](#PromptingTools.load_templates!)
- [`PromptingTools.ollama_api`](#PromptingTools.ollama_api)
- [`PromptingTools.preview`](#PromptingTools.preview)
- [`PromptingTools.push_conversation!`](#PromptingTools.push_conversation!-Tuple{Vector{<:Vector},%20AbstractVector,%20Union{Nothing,%20Int64}})
- [`PromptingTools.register_model!`](#PromptingTools.register_model!)
- [`PromptingTools.remove_julia_prompt`](#PromptingTools.remove_julia_prompt-Tuple{T}%20where%20T<:AbstractString)
- [`PromptingTools.remove_templates!`](#PromptingTools.remove_templates!-Tuple{})
- [`PromptingTools.remove_unsafe_lines`](#PromptingTools.remove_unsafe_lines-Tuple{AbstractString})
- [`PromptingTools.render`](#PromptingTools.render-Tuple{PromptingTools.AbstractOllamaSchema,%20Vector{<:PromptingTools.AbstractMessage}})
- [`PromptingTools.render`](#PromptingTools.render-Tuple{PromptingTools.AbstractGoogleSchema,%20Vector{<:PromptingTools.AbstractMessage}})
- [`PromptingTools.render`](#PromptingTools.render-Tuple{AITemplate})
- [`PromptingTools.render`](#PromptingTools.render-Tuple{PromptingTools.AbstractOpenAISchema,%20Vector{<:PromptingTools.AbstractMessage}})
- [`PromptingTools.render`](#PromptingTools.render-Tuple{PromptingTools.NoSchema,%20Vector{<:PromptingTools.AbstractMessage}})
- [`PromptingTools.render`](#PromptingTools.render-Tuple{PromptingTools.AbstractOllamaManagedSchema,%20Vector{<:PromptingTools.AbstractMessage}})
- [`PromptingTools.replace_words`](#PromptingTools.replace_words-Tuple{AbstractString,%20Vector{<:AbstractString}})
- [`PromptingTools.resize_conversation!`](#PromptingTools.resize_conversation!-Tuple{Any,%20Union{Nothing,%20Int64}})
- [`PromptingTools.response_to_message`](#PromptingTools.response_to_message-Tuple{PromptingTools.AbstractOpenAISchema,%20Type{AIMessage},%20Any,%20Any})
- [`PromptingTools.response_to_message`](#PromptingTools.response_to_message-Union{Tuple{T},%20Tuple{PromptingTools.AbstractPromptSchema,%20Type{T},%20Any,%20Any}}%20where%20T)
- [`PromptingTools.save_conversation`](#PromptingTools.save_conversation-Tuple{Union{AbstractString,%20IO},%20AbstractVector{<:PromptingTools.AbstractMessage}})
- [`PromptingTools.save_template`](#PromptingTools.save_template-Tuple{Union{AbstractString,%20IO},%20AbstractVector{<:PromptingTools.AbstractChatMessage}})
- [`PromptingTools.set_preferences!`](#PromptingTools.set_preferences!-Tuple{Vararg{Pair{String}}})
- [`PromptingTools.split_by_length`](#PromptingTools.split_by_length-Tuple{String})
- [`PromptingTools.split_by_length`](#PromptingTools.split_by_length-Tuple{Any,%20Vector{String}})
- [`PromptingTools.@aai_str`](#PromptingTools.@aai_str-Tuple{Any,%20Vararg{Any}})
- [`PromptingTools.@ai!_str`](#PromptingTools.@ai!_str-Tuple{Any,%20Vararg{Any}})
- [`PromptingTools.@ai_str`](#PromptingTools.@ai_str-Tuple{Any,%20Vararg{Any}})
- [`PromptingTools.@timeout`](#PromptingTools.@timeout-Tuple{Any,%20Any,%20Any})

<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.ALLOWED_PREFERENCES' href='#PromptingTools.ALLOWED_PREFERENCES'>#</a>&nbsp;<b><u>PromptingTools.ALLOWED_PREFERENCES</u></b> &mdash; <i>Constant</i>.




Keys that are allowed to be set via `set_preferences!`


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/user_preferences.jl#L51)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.ALTERNATIVE_GENERATION_COSTS' href='#PromptingTools.ALTERNATIVE_GENERATION_COSTS'>#</a>&nbsp;<b><u>PromptingTools.ALTERNATIVE_GENERATION_COSTS</u></b> &mdash; <i>Constant</i>.




```julia
ALTERNATIVE_GENERATION_COSTS
```


Tracker of alternative costing models, eg, for image generation (`dall-e-3`), the cost is driven by quality/size.


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/user_preferences.jl#L476-L480)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.CONV_HISTORY' href='#PromptingTools.CONV_HISTORY'>#</a>&nbsp;<b><u>PromptingTools.CONV_HISTORY</u></b> &mdash; <i>Constant</i>.




```julia
CONV_HISTORY
```


Tracks the most recent conversations through the `ai_str macros`.

Preference available: MAX_HISTORY_LENGTH, which sets how many last messages should be remembered.

See also: `push_conversation!`, `resize_conversation!`


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/user_preferences.jl#L168-L177)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.MODEL_ALIASES' href='#PromptingTools.MODEL_ALIASES'>#</a>&nbsp;<b><u>PromptingTools.MODEL_ALIASES</u></b> &mdash; <i>Constant</i>.




```julia
MODEL_ALIASES
```


A dictionary of model aliases. Aliases are used to refer to models by their aliases instead of their full names to make it more convenient to use them.

**Accessing the aliases**

```
PromptingTools.MODEL_ALIASES["gpt3"]
```


**Register a new model alias**

```julia
PromptingTools.MODEL_ALIASES["gpt3"] = "gpt-3.5-turbo"
```



[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/user_preferences.jl#L575-L589)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.MODEL_REGISTRY' href='#PromptingTools.MODEL_REGISTRY'>#</a>&nbsp;<b><u>PromptingTools.MODEL_REGISTRY</u></b> &mdash; <i>Constant</i>.




```julia
MODEL_REGISTRY
```


A store of available model names and their specs (ie, name, costs per token, etc.)

**Accessing the registry**

You can use both the alias name or the full name to access the model spec:

```
PromptingTools.MODEL_REGISTRY["gpt-3.5-turbo"]
```


**Registering a new model**

```julia
register_model!(
    name = "gpt-3.5-turbo",
    schema = :OpenAISchema,
    cost_of_token_prompt = 0.0015,
    cost_of_token_generation = 0.002,
    description = "GPT-3.5 Turbo is a 175B parameter model and a common default on the OpenAI API.")
```


**Registering a model alias**

```julia
PromptingTools.MODEL_ALIASES["gpt3"] = "gpt-3.5-turbo"
```



[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/user_preferences.jl#L505-L532)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.OPENAI_TOKEN_IDS' href='#PromptingTools.OPENAI_TOKEN_IDS'>#</a>&nbsp;<b><u>PromptingTools.OPENAI_TOKEN_IDS</u></b> &mdash; <i>Constant</i>.




Token IDs for GPT3.5 and GPT4 from https://platform.openai.com/tokenizer


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/llm_openai.jl#L621)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.PREFERENCES' href='#PromptingTools.PREFERENCES'>#</a>&nbsp;<b><u>PromptingTools.PREFERENCES</u></b> &mdash; <i>Constant</i>.




```julia
PREFERENCES
```


You can set preferences for PromptingTools by setting environment variables (for `OPENAI_API_KEY` only)      or by using the `set_preferences!`.     It will create a `LocalPreferences.toml` file in your current directory and will reload your prefences from there.

Check your preferences by calling `get_preferences(key::String)`.

**Available Preferences (for `set_preferences!`)**
- `OPENAI_API_KEY`: The API key for the OpenAI API. See [OpenAI's documentation](https://platform.openai.com/docs/quickstart?context=python) for more information.
  
- `MISTRALAI_API_KEY`: The API key for the Mistral AI API. See [Mistral AI's documentation](https://docs.mistral.ai/) for more information.
  
- `COHERE_API_KEY`: The API key for the Cohere API. See [Cohere's documentation](https://docs.cohere.com/docs/the-cohere-platform) for more information.
  
- `DATABRICKS_API_KEY`: The API key for the Databricks Foundation Model API. See [Databricks' documentation](https://docs.databricks.com/en/machine-learning/foundation-models/api-reference.html) for more information.
  
- `DATABRICKS_HOST`: The host for the Databricks API. See [Databricks' documentation](https://docs.databricks.com/en/machine-learning/foundation-models/api-reference.html) for more information.
  
- `TAVILY_API_KEY`: The API key for the Tavily Search API. Register [here](https://tavily.com/). See more information [here](https://docs.tavily.com/docs/tavily-api/rest_api).
  
- `GOOGLE_API_KEY`: The API key for Google Gemini models. Get yours from [here](https://ai.google.dev/). If you see a documentation page ("Available languages and regions for Google AI Studio and Gemini API"), it means that it's not yet available in your region.
  
- `MODEL_CHAT`: The default model to use for aigenerate and most ai* calls. See `MODEL_REGISTRY` for a list of available models or define your own.
  
- `MODEL_EMBEDDING`: The default model to use for aiembed (embedding documents). See `MODEL_REGISTRY` for a list of available models or define your own.
  
- `PROMPT_SCHEMA`: The default prompt schema to use for aigenerate and most ai* calls (if not specified in `MODEL_REGISTRY`). Set as a string, eg, `"OpenAISchema"`.   See `PROMPT_SCHEMA` for more information.
  
- `MODEL_ALIASES`: A dictionary of model aliases (`alias => full_model_name`). Aliases are used to refer to models by their aliases instead of their full names to make it more convenient to use them.   See `MODEL_ALIASES` for more information.
  
- `MAX_HISTORY_LENGTH`: The maximum length of the conversation history. Defaults to 5. Set to `nothing` to disable history.   See `CONV_HISTORY` for more information.
  
- `LOCAL_SERVER`: The URL of the local server to use for `ai*` calls. Defaults to `http://localhost:10897/v1`. This server is called when you call `model="local"`   See `?LocalServerOpenAISchema` for more information and examples.
  

At the moment it is not possible to persist changes to `MODEL_REGISTRY` across sessions.  Define your `register_model!()` calls in your `startup.jl` file to make them available across sessions or put them at the top of your script.

**Available ENV Variables**
- `OPENAI_API_KEY`: The API key for the OpenAI API. 
  
- `MISTRALAI_API_KEY`: The API key for the Mistral AI API.
  
- `COHERE_API_KEY`: The API key for the Cohere API.
  
- `LOCAL_SERVER`: The URL of the local server to use for `ai*` calls. Defaults to `http://localhost:10897/v1`. This server is called when you call `model="local"`
  
- `DATABRICKS_API_KEY`: The API key for the Databricks Foundation Model API.
  
- `DATABRICKS_HOST`: The host for the Databricks API.
  
- `TAVILY_API_KEY`: The API key for the Tavily Search API. Register [here](https://tavily.com/). See more information [here](https://docs.tavily.com/docs/tavily-api/rest_api).
  
- `GOOGLE_API_KEY`: The API key for Google Gemini models. Get yours from [here](https://ai.google.dev/). If you see a documentation page ("Available languages and regions for Google AI Studio and Gemini API"), it means that it's not yet available in your region.
  

Preferences.jl takes priority over ENV variables, so if you set a preference, it will take precedence over the ENV variable.

WARNING: NEVER EVER sync your `LocalPreferences.toml` file! It contains your API key and other sensitive information!!!


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/user_preferences.jl#L4-L48)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.RESERVED_KWARGS' href='#PromptingTools.RESERVED_KWARGS'>#</a>&nbsp;<b><u>PromptingTools.RESERVED_KWARGS</u></b> &mdash; <i>Constant</i>.




The following keywords are reserved for internal use in the `ai*` functions and cannot be used as placeholders in the Messages


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/PromptingTools.jl#L16)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.AICode' href='#PromptingTools.AICode'>#</a>&nbsp;<b><u>PromptingTools.AICode</u></b> &mdash; <i>Type</i>.




```julia
AICode(code::AbstractString; auto_eval::Bool=true, safe_eval::Bool=false, 
skip_unsafe::Bool=false, capture_stdout::Bool=true, verbose::Bool=false,
prefix::AbstractString="", suffix::AbstractString="", remove_tests::Bool=false, execution_timeout::Int = 60)

AICode(msg::AIMessage; auto_eval::Bool=true, safe_eval::Bool=false, 
skip_unsafe::Bool=false, skip_invalid::Bool=false, capture_stdout::Bool=true,
verbose::Bool=false, prefix::AbstractString="", suffix::AbstractString="", remove_tests::Bool=false, execution_timeout::Int = 60)
```


A mutable structure representing a code block (received from the AI model) with automatic parsing, execution, and output/error capturing capabilities.

Upon instantiation with a string, the `AICode` object automatically runs a code parser and executor (via `PromptingTools.eval!()`), capturing any standard output (`stdout`) or errors.  This structure is useful for programmatically handling and evaluating Julia code snippets.

See also: `PromptingTools.extract_code_blocks`, `PromptingTools.eval!`

**Workflow**
- Until `cb::AICode` has been evaluated, `cb.success` is set to `nothing` (and so are all other fields).
  
- The text in `cb.code` is parsed (saved to `cb.expression`).
  
- The parsed expression is evaluated.
  
- Outputs of the evaluated expression are captured in `cb.output`.
  
- Any `stdout` outputs (e.g., from `println`) are captured in `cb.stdout`.
  
- If an error occurs during evaluation, it is saved in `cb.error`.
  
- After successful evaluation without errors, `cb.success` is set to `true`.  Otherwise, it is set to `false` and you can inspect the `cb.error` to understand why.
  

**Properties**
- `code::AbstractString`: The raw string of the code to be parsed and executed.
  
- `expression`: The parsed Julia expression (set after parsing `code`).
  
- `stdout`: Captured standard output from the execution of the code.
  
- `output`: The result of evaluating the code block.
  
- `success::Union{Nothing, Bool}`: Indicates whether the code block executed successfully (`true`), unsuccessfully (`false`), or has yet to be evaluated (`nothing`).
  
- `error::Union{Nothing, Exception}`: Any exception raised during the execution of the code block.
  

**Keyword Arguments**
- `auto_eval::Bool`: If set to `true`, the code block is automatically parsed and evaluated upon instantiation. Defaults to `true`.
  
- `safe_eval::Bool`: If set to `true`, the code block checks for package operations (e.g., installing new packages) and missing imports, and then evaluates the code inside a bespoke scratch module. This is to ensure that the evaluation does not alter any user-defined variables or the global state. Defaults to `false`.
  
- `skip_unsafe::Bool`: If set to `true`, we skip any lines in the code block that are deemed unsafe (eg, `Pkg` operations). Defaults to `false`.
  
- `skip_invalid::Bool`: If set to `true`, we skip code blocks that do not even parse. Defaults to `false`.
  
- `verbose::Bool`: If set to `true`, we print out any lines that are skipped due to being unsafe. Defaults to `false`.
  
- `capture_stdout::Bool`: If set to `true`, we capture any stdout outputs (eg, test failures) in `cb.stdout`. Defaults to `true`.
  
- `prefix::AbstractString`: A string to be prepended to the code block before parsing and evaluation. Useful to add some additional code definition or necessary imports. Defaults to an empty string.
  
- `suffix::AbstractString`: A string to be appended to the code block before parsing and evaluation.  Useful to check that tests pass or that an example executes. Defaults to an empty string.
  
- `remove_tests::Bool`: If set to `true`, we remove any `@test` or `@testset` macros from the code block before parsing and evaluation. Defaults to `false`.
  
- `execution_timeout::Int`: The maximum time (in seconds) allowed for the code block to execute. Defaults to 60 seconds.
  

**Methods**
- `Base.isvalid(cb::AICode)`: Check if the code block has executed successfully. Returns `true` if `cb.success == true`.
  

**Examples**

```julia
code = AICode("println("Hello, World!")") # Auto-parses and evaluates the code, capturing output and errors.
isvalid(code) # Output: true
code.stdout # Output: "Hello, World!
"
```


We try to evaluate "safely" by default (eg, inside a custom module, to avoid changing user variables).   You can avoid that with `save_eval=false`:

```julia
code = AICode("new_variable = 1"; safe_eval=false)
isvalid(code) # Output: true
new_variable # Output: 1
```


You can also call AICode directly on an AIMessage, which will extract the Julia code blocks, concatenate them and evaluate them:

```julia
msg = aigenerate("In Julia, how do you create a vector of 10 random numbers?")
code = AICode(msg)
# Output: AICode(Success: True, Parsed: True, Evaluated: True, Error Caught: N/A, StdOut: True, Code: 2 Lines)

# show the code
code.code |> println
# Output: 
# numbers = rand(10)
# numbers = rand(1:100, 10)

# or copy it to the clipboard
code.code |> clipboard

# or execute it in the current module (=Main)
eval(code.expression)
```



[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/code_eval.jl#L18-L106)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.AIMessage' href='#PromptingTools.AIMessage'>#</a>&nbsp;<b><u>PromptingTools.AIMessage</u></b> &mdash; <i>Type</i>.




```julia
AIMessage
```


A message type for AI-generated text-based responses.  Returned by `aigenerate`, `aiclassify`, and `aiscan` functions.

**Fields**
- `content::Union{AbstractString, Nothing}`: The content of the message.
  
- `status::Union{Int, Nothing}`: The status of the message from the API.
  
- `tokens::Tuple{Int, Int}`: The number of tokens used (prompt,completion).
  
- `elapsed::Float64`: The time taken to generate the response in seconds.
  
- `cost::Union{Nothing, Float64}`: The cost of the API call (calculated with information from `MODEL_REGISTRY`).
  
- `log_prob::Union{Nothing, Float64}`: The log probability of the response.
  
- `finish_reason::Union{Nothing, String}`: The reason the response was finished.
  
- `run_id::Union{Nothing, Int}`: The unique ID of the run.
  
- `sample_id::Union{Nothing, Int}`: The unique ID of the sample (if multiple samples are generated, they will all have the same `run_id`).
  


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/messages.jl#L65-L81)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.AITemplate' href='#PromptingTools.AITemplate'>#</a>&nbsp;<b><u>PromptingTools.AITemplate</u></b> &mdash; <i>Type</i>.




```julia
AITemplate
```


AITemplate is a template for a conversation prompt.   This type is merely a container for the template name, which is resolved into a set of messages (=prompt) by `render`.

**Naming Convention**
- Template names should be in CamelCase
  
- Follow the format `<Persona>...<Variable>...` where possible, eg, `JudgeIsItTrue`, ``
  - Starting with the Persona (=System prompt), eg, `Judge` = persona is meant to `judge` some provided information
    
  - Variable to be filled in with context, eg, `It` = placeholder `it`
    
  - Ending with the variable name is helpful, eg, `JuliaExpertTask` for a persona to be an expert in Julia language and `task` is the placeholder name
    
  
- Ideally, the template name should be self-explanatory, eg, `JudgeIsItTrue` = persona is meant to `judge` some provided information where it is true or false
  

**Examples**

Save time by re-using pre-made templates, just fill in the placeholders with the keyword arguments:

```julia
msg = aigenerate(:JuliaExpertAsk; ask = "How do I add packages?")
```


The above is equivalent to a more verbose version that explicitly uses the dispatch on `AITemplate`:

```julia
msg = aigenerate(AITemplate(:JuliaExpertAsk); ask = "How do I add packages?")
```


Find available templates with `aitemplates`:

```julia
tmps = aitemplates("JuliaExpertAsk")
# Will surface one specific template
# 1-element Vector{AITemplateMetadata}:
# PromptingTools.AITemplateMetadata
#   name: Symbol JuliaExpertAsk
#   description: String "For asking questions about Julia language. Placeholders: `ask`"
#   version: String "1"
#   wordcount: Int64 237
#   variables: Array{Symbol}((1,))
#   system_preview: String "You are a world-class Julia language programmer with the knowledge of the latest syntax. Your commun"
#   user_preview: String "# Question

{{ask}}"
#   source: String ""
```


The above gives you a good idea of what the template is about, what placeholders are available, and how much it would cost to use it (=wordcount).

Search for all Julia-related templates:

```julia
tmps = aitemplates("Julia")
# 2-element Vector{AITemplateMetadata}... -> more to come later!
```


If you are on VSCode, you can leverage nice tabular display with `vscodedisplay`:

```julia
using DataFrames
tmps = aitemplates("Julia") |> DataFrame |> vscodedisplay
```


I have my selected template, how do I use it? Just use the "name" in `aigenerate` or `aiclassify`   like you see in the first example!

You can inspect any template by "rendering" it (this is what the LLM will see):

```julia
julia> AITemplate(:JudgeIsItTrue) |> PromptingTools.render
```


See also: `save_template`, `load_template`, `load_templates!` for more advanced use cases (and the corresponding script in `examples/` folder)


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/templates.jl#L8-L74)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.AITemplateMetadata' href='#PromptingTools.AITemplateMetadata'>#</a>&nbsp;<b><u>PromptingTools.AITemplateMetadata</u></b> &mdash; <i>Type</i>.




Helper for easy searching and reviewing of templates. Defined on loading of each template.


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/templates.jl#L77)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.AbstractPromptSchema' href='#PromptingTools.AbstractPromptSchema'>#</a>&nbsp;<b><u>PromptingTools.AbstractPromptSchema</u></b> &mdash; <i>Type</i>.




Defines different prompting styles based on the model training and fine-tuning.


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/llm_interface.jl#L20)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.ChatMLSchema' href='#PromptingTools.ChatMLSchema'>#</a>&nbsp;<b><u>PromptingTools.ChatMLSchema</u></b> &mdash; <i>Type</i>.




ChatMLSchema is used by many open-source chatbots, by OpenAI models (under the hood) and by several models and inferfaces (eg, Ollama, vLLM)

You can explore it on [tiktokenizer](https://tiktokenizer.vercel.app/)

It uses the following conversation structure:

```
<im_start>system
...<im_end>
<|im_start|>user
...<|im_end|>
<|im_start|>assistant
...<|im_end|>
```



[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/llm_interface.jl#L203-L217)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.CustomOpenAISchema' href='#PromptingTools.CustomOpenAISchema'>#</a>&nbsp;<b><u>PromptingTools.CustomOpenAISchema</u></b> &mdash; <i>Type</i>.




```julia
CustomOpenAISchema
```


CustomOpenAISchema() allows user to call any OpenAI-compatible API.

All user needs to do is to pass this schema as the first argument and provide the BASE URL of the API to call (`api_kwargs.url`).

**Example**

Assumes that we have a local server running at `http://127.0.0.1:8081`:

```julia
api_key = "..."
prompt = "Say hi!"
msg = aigenerate(CustomOpenAISchema(), prompt; model="my_model", api_key, api_kwargs=(; url="http://127.0.0.1:8081"))
```



[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/llm_interface.jl#L48-L65)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.DataMessage' href='#PromptingTools.DataMessage'>#</a>&nbsp;<b><u>PromptingTools.DataMessage</u></b> &mdash; <i>Type</i>.




```julia
DataMessage
```


A message type for AI-generated data-based responses, ie, different `content` than text.  Returned by `aiextract`, and `aiextract` functions.

**Fields**
- `content::Union{AbstractString, Nothing}`: The content of the message.
  
- `status::Union{Int, Nothing}`: The status of the message from the API.
  
- `tokens::Tuple{Int, Int}`: The number of tokens used (prompt,completion).
  
- `elapsed::Float64`: The time taken to generate the response in seconds.
  
- `cost::Union{Nothing, Float64}`: The cost of the API call (calculated with information from `MODEL_REGISTRY`).
  
- `log_prob::Union{Nothing, Float64}`: The log probability of the response.
  
- `finish_reason::Union{Nothing, String}`: The reason the response was finished.
  
- `run_id::Union{Nothing, Int}`: The unique ID of the run.
  
- `sample_id::Union{Nothing, Int}`: The unique ID of the sample (if multiple samples are generated, they will all have the same `run_id`).
  


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/messages.jl#L95-L111)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.DatabricksOpenAISchema' href='#PromptingTools.DatabricksOpenAISchema'>#</a>&nbsp;<b><u>PromptingTools.DatabricksOpenAISchema</u></b> &mdash; <i>Type</i>.




```julia
DatabricksOpenAISchema
```


DatabricksOpenAISchema() allows user to call Databricks Foundation Model API. [API Reference](https://docs.databricks.com/en/machine-learning/foundation-models/api-reference.html)

Requires two environment variables to be set:
- `DATABRICKS_API_KEY`: Databricks token
  
- `DATABRICKS_HOST`: Address of the Databricks workspace (`https://<workspace_host>.databricks.com`)
  


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/llm_interface.jl#L139-L147)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.FireworksOpenAISchema' href='#PromptingTools.FireworksOpenAISchema'>#</a>&nbsp;<b><u>PromptingTools.FireworksOpenAISchema</u></b> &mdash; <i>Type</i>.




```julia
FireworksOpenAISchema
```


Schema to call the [Fireworks.ai](https://fireworks.ai/) API.

Links:
- [Get your API key](https://fireworks.ai/api-keys)
  
- [API Reference](https://readme.fireworks.ai/reference/createchatcompletion)
  
- [Available models](https://fireworks.ai/models)
  

Requires one environment variables to be set:
- `FIREWORKS_API_KEY`: Your API key
  


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/llm_interface.jl#L150-L162)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.GoogleSchema' href='#PromptingTools.GoogleSchema'>#</a>&nbsp;<b><u>PromptingTools.GoogleSchema</u></b> &mdash; <i>Type</i>.




Calls Google's Gemini API. See more information [here](https://aistudio.google.com/). It's available only for _some_ regions.


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/llm_interface.jl#L243)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.ItemsExtract' href='#PromptingTools.ItemsExtract'>#</a>&nbsp;<b><u>PromptingTools.ItemsExtract</u></b> &mdash; <i>Type</i>.




Extract zero, one or more specified items from the provided data.


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/extraction.jl#L185-L187)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.LocalServerOpenAISchema' href='#PromptingTools.LocalServerOpenAISchema'>#</a>&nbsp;<b><u>PromptingTools.LocalServerOpenAISchema</u></b> &mdash; <i>Type</i>.




```julia
LocalServerOpenAISchema
```


Designed to be used with local servers. It's automatically called with model alias "local" (see `MODEL_REGISTRY`).

This schema is a flavor of CustomOpenAISchema with a `url` key`preset by global Preference key`LOCAL_SERVER`. See`?PREFERENCES`for more details on how to change it. It assumes that the server follows OpenAI API conventions (eg,`POST /v1/chat/completions`).

Note: Llama.cpp (and hence Llama.jl built on top of it) do NOT support embeddings endpoint! You'll get an address error.

**Example**

Assumes that we have a local server running at `http://127.0.0.1:10897/v1` (port and address used by Llama.jl, "v1" at the end is needed for OpenAI endpoint compatibility):

Three ways to call it:

```julia

# Use @ai_str with "local" alias
ai"Say hi!"local

# model="local"
aigenerate("Say hi!"; model="local")

# Or set schema explicitly
const PT = PromptingTools
msg = aigenerate(PT.LocalServerOpenAISchema(), "Say hi!")
```


How to start a LLM local server? You can use `run_server` function from [Llama.jl](https://github.com/marcom/Llama.jl). Use a separate Julia session.

```julia
using Llama
model = "...path..." # see Llama.jl README how to download one
run_server(; model)
```


To change the default port and address:

```julia
# For a permanent change, set the preference:
using Preferences
set_preferences!("LOCAL_SERVER"=>"http://127.0.0.1:10897/v1")

# Or if it's a temporary fix, just change the variable `LOCAL_SERVER`:
const PT = PromptingTools
PT.LOCAL_SERVER = "http://127.0.0.1:10897/v1"
```



[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/llm_interface.jl#L68-L114)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.MaybeExtract' href='#PromptingTools.MaybeExtract'>#</a>&nbsp;<b><u>PromptingTools.MaybeExtract</u></b> &mdash; <i>Type</i>.




Extract a result from the provided data, if any, otherwise set the error and message fields.

**Arguments**
- `error::Bool`: `true` if a result is found, `false` otherwise.
  
- `message::String`: Only present if no result is found, should be short and concise.
  


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/extraction.jl#L172-L178)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.MistralOpenAISchema' href='#PromptingTools.MistralOpenAISchema'>#</a>&nbsp;<b><u>PromptingTools.MistralOpenAISchema</u></b> &mdash; <i>Type</i>.




```julia
MistralOpenAISchema
```


MistralOpenAISchema() allows user to call MistralAI API known for mistral and mixtral models.

It's a flavor of CustomOpenAISchema() with a url preset to `https://api.mistral.ai`.

Most models have been registered, so you don't even have to specify the schema

**Example**

Let's call `mistral-tiny` model:

```julia
api_key = "..." # can be set via ENV["MISTRAL_API_KEY"] or via our preference system
msg = aigenerate("Say hi!"; model="mistral_tiny", api_key)
```


See `?PREFERENCES` for more details on how to set your API key permanently.


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/llm_interface.jl#L117-L136)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.ModelSpec' href='#PromptingTools.ModelSpec'>#</a>&nbsp;<b><u>PromptingTools.ModelSpec</u></b> &mdash; <i>Type</i>.




```julia
ModelSpec
```


A struct that contains information about a model, such as its name, schema, cost per token, etc.

**Fields**
- `name::String`: The name of the model. This is the name that will be used to refer to the model in the `ai*` functions.
  
- `schema::AbstractPromptSchema`: The schema of the model. This is the schema that will be used to generate prompts for the model, eg, `:OpenAISchema`.
  
- `cost_of_token_prompt::Float64`: The cost of 1 token in the prompt for this model. This is used to calculate the cost of a prompt.    Note: It is often provided online as cost per 1000 tokens, so make sure to convert it correctly!
  
- `cost_of_token_generation::Float64`: The cost of 1 token generated by this model. This is used to calculate the cost of a generation.   Note: It is often provided online as cost per 1000 tokens, so make sure to convert it correctly!
  
- `description::String`: A description of the model. This is used to provide more information about the model when it is queried.
  

**Example**

```julia
spec = ModelSpec("gpt-3.5-turbo",
    OpenAISchema(),
    0.0015,
    0.002,
    "GPT-3.5 Turbo is a 175B parameter model and a common default on the OpenAI API.")

# register it
PromptingTools.register_model!(spec)
```


But you can also register any model directly via keyword arguments:

```julia
PromptingTools.register_model!(
    name = "gpt-3.5-turbo",
    schema = OpenAISchema(),
    cost_of_token_prompt = 0.0015,
    cost_of_token_generation = 0.002,
    description = "GPT-3.5 Turbo is a 175B parameter model and a common default on the OpenAI API.")
```



[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/user_preferences.jl#L188-L223)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.NoSchema' href='#PromptingTools.NoSchema'>#</a>&nbsp;<b><u>PromptingTools.NoSchema</u></b> &mdash; <i>Type</i>.




Schema that keeps messages (<:AbstractMessage) and does not transform for any specific model. It used by the first pass of the prompt rendering system (see `?render`).


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/llm_interface.jl#L23)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.OllamaManagedSchema' href='#PromptingTools.OllamaManagedSchema'>#</a>&nbsp;<b><u>PromptingTools.OllamaManagedSchema</u></b> &mdash; <i>Type</i>.




Ollama by default manages different models and their associated prompt schemas when you pass `system_prompt` and `prompt` fields to the API.

Warning: It works only for 1 system message and 1 user message, so anything more than that has to be rejected.

If you need to pass more messagese / longer conversational history, you can use define the model-specific schema directly and pass your Ollama requests with `raw=true`,   which disables and templating and schema management by Ollama.


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/llm_interface.jl#L223-L230)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.OllamaSchema' href='#PromptingTools.OllamaSchema'>#</a>&nbsp;<b><u>PromptingTools.OllamaSchema</u></b> &mdash; <i>Type</i>.




OllamaSchema is the default schema for Olama models.

It uses the following conversation template:

```
[Dict(role="system",content="..."),Dict(role="user",content="..."),Dict(role="assistant",content="...")]
```


It's very similar to OpenAISchema, but it appends images differently.


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/llm_interface.jl#L182-L191)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.OpenAISchema' href='#PromptingTools.OpenAISchema'>#</a>&nbsp;<b><u>PromptingTools.OpenAISchema</u></b> &mdash; <i>Type</i>.




OpenAISchema is the default schema for OpenAI models.

It uses the following conversation template:

```
[Dict(role="system",content="..."),Dict(role="user",content="..."),Dict(role="assistant",content="...")]
```


It's recommended to separate sections in your prompt with markdown headers (e.g. `##Answer

`).


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/llm_interface.jl#L28-L39)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.TestEchoGoogleSchema' href='#PromptingTools.TestEchoGoogleSchema'>#</a>&nbsp;<b><u>PromptingTools.TestEchoGoogleSchema</u></b> &mdash; <i>Type</i>.




Echoes the user's input back to them. Used for testing the implementation


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/llm_interface.jl#L246)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.TestEchoOllamaManagedSchema' href='#PromptingTools.TestEchoOllamaManagedSchema'>#</a>&nbsp;<b><u>PromptingTools.TestEchoOllamaManagedSchema</u></b> &mdash; <i>Type</i>.




Echoes the user's input back to them. Used for testing the implementation


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/llm_interface.jl#L233)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.TestEchoOllamaSchema' href='#PromptingTools.TestEchoOllamaSchema'>#</a>&nbsp;<b><u>PromptingTools.TestEchoOllamaSchema</u></b> &mdash; <i>Type</i>.




Echoes the user's input back to them. Used for testing the implementation


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/llm_interface.jl#L194)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.TestEchoOpenAISchema' href='#PromptingTools.TestEchoOpenAISchema'>#</a>&nbsp;<b><u>PromptingTools.TestEchoOpenAISchema</u></b> &mdash; <i>Type</i>.




Echoes the user's input back to them. Used for testing the implementation


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/llm_interface.jl#L40)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.TogetherOpenAISchema' href='#PromptingTools.TogetherOpenAISchema'>#</a>&nbsp;<b><u>PromptingTools.TogetherOpenAISchema</u></b> &mdash; <i>Type</i>.




```julia
TogetherOpenAISchema
```


Schema to call the [Together.ai](https://www.together.ai/) API.

Links:
- [Get your API key](https://api.together.xyz/settings/api-keys)
  
- [API Reference](https://docs.together.ai/docs/openai-api-compatibility)
  
- [Available models](https://docs.together.ai/docs/inference-models)
  

Requires one environment variables to be set:
- `TOGETHER_API_KEY`: Your API key
  


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/llm_interface.jl#L165-L177)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.UserMessageWithImages-Tuple{AbstractString}' href='#PromptingTools.UserMessageWithImages-Tuple{AbstractString}'>#</a>&nbsp;<b><u>PromptingTools.UserMessageWithImages</u></b> &mdash; <i>Method</i>.




Construct `UserMessageWithImages` with 1 or more images. Images can be either URLs or local paths.


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/messages.jl#L142)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.X123' href='#PromptingTools.X123'>#</a>&nbsp;<b><u>PromptingTools.X123</u></b> &mdash; <i>Type</i>.




With docstring


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/precompilation.jl#L22)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='OpenAI.create_chat-Tuple{PromptingTools.CustomOpenAISchema, AbstractString, AbstractString, Any}' href='#OpenAI.create_chat-Tuple{PromptingTools.CustomOpenAISchema, AbstractString, AbstractString, Any}'>#</a>&nbsp;<b><u>OpenAI.create_chat</u></b> &mdash; <i>Method</i>.




```julia
OpenAI.create_chat(schema::CustomOpenAISchema,
```


api_key::AbstractString,   model::AbstractString,   conversation;   url::String="http://localhost:8080",   kwargs...)

Dispatch to the OpenAI.create_chat function, for any OpenAI-compatible API. 

It expects `url` keyword argument. Provide it to the `aigenerate` function via `api_kwargs=(; url="my-url")`

It will forward your query to the "chat/completions" endpoint of the base URL that you provided (=`url`).


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/llm_openai.jl#L98-L111)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='OpenAI.create_chat-Tuple{PromptingTools.LocalServerOpenAISchema, AbstractString, AbstractString, Any}' href='#OpenAI.create_chat-Tuple{PromptingTools.LocalServerOpenAISchema, AbstractString, AbstractString, Any}'>#</a>&nbsp;<b><u>OpenAI.create_chat</u></b> &mdash; <i>Method</i>.




```julia
OpenAI.create_chat(schema::LocalServerOpenAISchema,
    api_key::AbstractString,
    model::AbstractString,
    conversation;
    url::String = "http://localhost:8080",
    kwargs...)
```


Dispatch to the OpenAI.create_chat function, but with the LocalServer API parameters, ie, defaults to `url` specified by the `LOCAL_SERVER`preference. See`?PREFERENCES`


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/llm_openai.jl#L124-L134)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='OpenAI.create_chat-Tuple{PromptingTools.MistralOpenAISchema, AbstractString, AbstractString, Any}' href='#OpenAI.create_chat-Tuple{PromptingTools.MistralOpenAISchema, AbstractString, AbstractString, Any}'>#</a>&nbsp;<b><u>OpenAI.create_chat</u></b> &mdash; <i>Method</i>.




```julia
OpenAI.create_chat(schema::MistralOpenAISchema,
```


api_key::AbstractString,   model::AbstractString,   conversation;   url::String="https://api.mistral.ai/v1",   kwargs...)

Dispatch to the OpenAI.create_chat function, but with the MistralAI API parameters. 

It tries to access the `MISTRALAI_API_KEY` ENV variable, but you can also provide it via the `api_key` keyword argument.


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/llm_openai.jl#L144-L155)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.aiclassify-Union{Tuple{T}, Tuple{PromptingTools.AbstractOpenAISchema, Union{AbstractString, PromptingTools.AbstractMessage, Vector{<:PromptingTools.AbstractMessage}}}} where T<:Union{AbstractString, Tuple{var"#s110", var"#s104"} where {var"#s110"<:AbstractString, var"#s104"<:AbstractString}}' href='#PromptingTools.aiclassify-Union{Tuple{T}, Tuple{PromptingTools.AbstractOpenAISchema, Union{AbstractString, PromptingTools.AbstractMessage, Vector{<:PromptingTools.AbstractMessage}}}} where T<:Union{AbstractString, Tuple{var"#s110", var"#s104"} where {var"#s110"<:AbstractString, var"#s104"<:AbstractString}}'>#</a>&nbsp;<b><u>PromptingTools.aiclassify</u></b> &mdash; <i>Method</i>.




```julia
aiclassify(prompt_schema::AbstractOpenAISchema, prompt::ALLOWED_PROMPT_TYPE;
    choices::AbstractVector{T} = ["true", "false", "unknown"],
    api_kwargs::NamedTuple = NamedTuple(),
    kwargs...) where {T <: Union{AbstractString, Tuple{<:AbstractString, <:AbstractString}}}
```


Classifies the given prompt/statement into an arbitrary list of `choices`, which must be only the choices (vector of strings) or choices and descriptions are provided (vector of tuples, ie, `("choice","description")`).

It's quick and easy option for "routing" and similar use cases, as it exploits the logit bias trick and outputs only 1 token. classify into an arbitrary list of categories (including with descriptions). It's quick and easy option for "routing" and similar use cases, as it exploits the logit bias trick, so it outputs only 1 token.

!!! Note: The prompt/AITemplate must have a placeholder `choices` (ie, `{{choices}}`) that will be replaced with the encoded choices

Choices are rewritten into an enumerated list and mapped to a few known OpenAI tokens (maximum of 20 choices supported). Mapping of token IDs for GPT3.5/4 are saved in variable `OPENAI_TOKEN_IDS`.

It uses Logit bias trick and limits the output to 1 token to force the model to output only true/false/unknown. Credit for the idea goes to [AAAzzam](https://twitter.com/AAAzzam/status/1669753721574633473).

**Arguments**
- `prompt_schema::AbstractOpenAISchema`: The schema for the prompt.
  
- `prompt`: The prompt/statement to classify if it's a `String`. If it's a `Symbol`, it is expanded as a template via `render(schema,template)`. Eg, templates `:JudgeIsItTrue` or `:InputClassifier`
  
- `choices::AbstractVector{T}`: The choices to be classified into. It can be a vector of strings or a vector of tuples, where the first element is the choice and the second is the description.
  

**Example**

Given a user input, pick one of the two provided categories:

```julia
choices = ["animal", "plant"]
input = "Palm tree"
aiclassify(:InputClassifier; choices, input)
```


Choices with descriptions provided as tuples:

```julia
choices = [("A", "any animal or creature"), ("P", "for any plant or tree"), ("O", "for everything else")]

# try the below inputs:
input = "spider" # -> returns "A" for any animal or creature
input = "daphodil" # -> returns "P" for any plant or tree
input = "castle" # -> returns "O" for everything else
aiclassify(:InputClassifier; choices, input)
```


You can still use a simple true/false classification:

```julia
aiclassify("Is two plus two four?") # true
aiclassify("Is two plus three a vegetable on Mars?") # false
```


`aiclassify` returns only true/false/unknown. It's easy to get the proper `Bool` output type out with `tryparse`, eg,

```julia
tryparse(Bool, aiclassify("Is two plus two four?")) isa Bool # true
```


Output of type `Nothing` marks that the model couldn't classify the statement as true/false.

Ideally, we would like to re-use some helpful system prompt to get more accurate responses. For this reason we have templates, eg, `:JudgeIsItTrue`. By specifying the template, we can provide our statement as the expected variable (`it` in this case) See that the model now correctly classifies the statement as "unknown".

```julia
aiclassify(:JudgeIsItTrue; it = "Is two plus three a vegetable on Mars?") # unknown
```


For better results, use higher quality models like gpt4, eg, 

```julia
aiclassify(:JudgeIsItTrue;
    it = "If I had two apples and I got three more, I have five apples now.",
    model = "gpt4") # true
```



[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/llm_openai.jl#L776-L843)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.aiembed-Union{Tuple{F}, Tuple{PromptingTools.AbstractOllamaManagedSchema, AbstractString}, Tuple{PromptingTools.AbstractOllamaManagedSchema, AbstractString, F}} where F<:Function' href='#PromptingTools.aiembed-Union{Tuple{F}, Tuple{PromptingTools.AbstractOllamaManagedSchema, AbstractString}, Tuple{PromptingTools.AbstractOllamaManagedSchema, AbstractString, F}} where F<:Function'>#</a>&nbsp;<b><u>PromptingTools.aiembed</u></b> &mdash; <i>Method</i>.




```julia
aiembed(prompt_schema::AbstractOllamaManagedSchema,
        doc_or_docs::Union{AbstractString, AbstractVector{<:AbstractString}},
        postprocess::F = identity;
        verbose::Bool = true,
        api_key::String = "",
        model::String = MODEL_EMBEDDING,
        http_kwargs::NamedTuple = (retry_non_idempotent = true,
                                   retries = 5,
                                   readtimeout = 120),
        api_kwargs::NamedTuple = NamedTuple(),
        kwargs...) where {F <: Function}
```


The `aiembed` function generates embeddings for the given input using a specified model and returns a message object containing the embeddings, status, token count, and elapsed time.

**Arguments**
- `prompt_schema::AbstractOllamaManagedSchema`: The schema for the prompt.
  
- `doc_or_docs::Union{AbstractString, AbstractVector{<:AbstractString}}`: The document or list of documents to generate embeddings for. The list of documents is processed sequentially,  so users should consider implementing an async version with with `Threads.@spawn`
  
- `postprocess::F`: The post-processing function to apply to each embedding. Defaults to the identity function, but could be `LinearAlgebra.normalize`.
  
- `verbose::Bool`: A flag indicating whether to print verbose information. Defaults to `true`.
  
- `api_key::String`: The API key to use for the OpenAI API. Defaults to `""`.
  
- `model::String`: The model to use for generating embeddings. Defaults to `MODEL_EMBEDDING`.
  
- `http_kwargs::NamedTuple`: Additional keyword arguments for the HTTP request. Defaults to empty `NamedTuple`.
  
- `api_kwargs::NamedTuple`: Additional keyword arguments for the Ollama API. Defaults to an empty `NamedTuple`.
  
- `kwargs`: Prompt variables to be used to fill the prompt/template
  

**Returns**
- `msg`: A `DataMessage` object containing the embeddings, status, token count, and elapsed time.
  

Note: Ollama API currently does not return the token count, so it's set to `(0,0)`

**Example**

```julia
const PT = PromptingTools
schema = PT.OllamaManagedSchema()

msg = aiembed(schema, "Hello World"; model="openhermes2.5-mistral")
msg.content # 4096-element JSON3.Array{Float64...
```


We can embed multiple strings at once and they will be `hcat` into a matrix   (ie, each column corresponds to one string)

```julia
const PT = PromptingTools
schema = PT.OllamaManagedSchema()

msg = aiembed(schema, ["Hello World", "How are you?"]; model="openhermes2.5-mistral")
msg.content # 4096×2 Matrix{Float64}:
```


If you plan to calculate the cosine distance between embeddings, you can normalize them first:

```julia
const PT = PromptingTools
using LinearAlgebra
schema = PT.OllamaManagedSchema()

msg = aiembed(schema, ["embed me", "and me too"], LinearAlgebra.normalize; model="openhermes2.5-mistral")

# calculate cosine distance between the two normalized embeddings as a simple dot product
msg.content' * msg.content[:, 1] # [1.0, 0.34]
```


Similarly, you can use the `postprocess` argument to materialize the data from JSON3.Object by using `postprocess = copy`

```julia
const PT = PromptingTools
schema = PT.OllamaManagedSchema()

msg = aiembed(schema, "Hello World", copy; model="openhermes2.5-mistral")
msg.content # 4096-element Vector{Float64}
```



[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/llm_ollama_managed.jl#L241-L314)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.aiembed-Union{Tuple{F}, Tuple{PromptingTools.AbstractOpenAISchema, Union{AbstractString, AbstractVector{<:AbstractString}}}, Tuple{PromptingTools.AbstractOpenAISchema, Union{AbstractString, AbstractVector{<:AbstractString}}, F}} where F<:Function' href='#PromptingTools.aiembed-Union{Tuple{F}, Tuple{PromptingTools.AbstractOpenAISchema, Union{AbstractString, AbstractVector{<:AbstractString}}}, Tuple{PromptingTools.AbstractOpenAISchema, Union{AbstractString, AbstractVector{<:AbstractString}}, F}} where F<:Function'>#</a>&nbsp;<b><u>PromptingTools.aiembed</u></b> &mdash; <i>Method</i>.




```julia
aiembed(prompt_schema::AbstractOpenAISchema,
        doc_or_docs::Union{AbstractString, AbstractVector{<:AbstractString}},
        postprocess::F = identity;
        verbose::Bool = true,
        api_key::String = OPENAI_API_KEY,
        model::String = MODEL_EMBEDDING, 
        http_kwargs::NamedTuple = (retry_non_idempotent = true,
                                   retries = 5,
                                   readtimeout = 120),
        api_kwargs::NamedTuple = NamedTuple(),
        kwargs...) where {F <: Function}
```


The `aiembed` function generates embeddings for the given input using a specified model and returns a message object containing the embeddings, status, token count, and elapsed time.

**Arguments**
- `prompt_schema::AbstractOpenAISchema`: The schema for the prompt.
  
- `doc_or_docs::Union{AbstractString, AbstractVector{<:AbstractString}}`: The document or list of documents to generate embeddings for.
  
- `postprocess::F`: The post-processing function to apply to each embedding. Defaults to the identity function.
  
- `verbose::Bool`: A flag indicating whether to print verbose information. Defaults to `true`.
  
- `api_key::String`: The API key to use for the OpenAI API. Defaults to `OPENAI_API_KEY`.
  
- `model::String`: The model to use for generating embeddings. Defaults to `MODEL_EMBEDDING`.
  
- `http_kwargs::NamedTuple`: Additional keyword arguments for the HTTP request. Defaults to `(retry_non_idempotent = true, retries = 5, readtimeout = 120)`.
  
- `api_kwargs::NamedTuple`: Additional keyword arguments for the OpenAI API. Defaults to an empty `NamedTuple`.
  
- `kwargs...`: Additional keyword arguments.
  

**Returns**
- `msg`: A `DataMessage` object containing the embeddings, status, token count, and elapsed time. Use `msg.content` to access the embeddings.
  

**Example**

```julia
msg = aiembed("Hello World")
msg.content # 1536-element JSON3.Array{Float64...
```


We can embed multiple strings at once and they will be `hcat` into a matrix   (ie, each column corresponds to one string)

```julia
msg = aiembed(["Hello World", "How are you?"])
msg.content # 1536×2 Matrix{Float64}:
```


If you plan to calculate the cosine distance between embeddings, you can normalize them first:

```julia
using LinearAlgebra
msg = aiembed(["embed me", "and me too"], LinearAlgebra.normalize)

# calculate cosine distance between the two normalized embeddings as a simple dot product
msg.content' * msg.content[:, 1] # [1.0, 0.787]
```



[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/llm_openai.jl#L537-L589)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.aiextract-Tuple{PromptingTools.AbstractOpenAISchema, Union{AbstractString, PromptingTools.AbstractMessage, Vector{<:PromptingTools.AbstractMessage}}}' href='#PromptingTools.aiextract-Tuple{PromptingTools.AbstractOpenAISchema, Union{AbstractString, PromptingTools.AbstractMessage, Vector{<:PromptingTools.AbstractMessage}}}'>#</a>&nbsp;<b><u>PromptingTools.aiextract</u></b> &mdash; <i>Method</i>.




```julia
aiextract(prompt_schema::AbstractOpenAISchema, prompt::ALLOWED_PROMPT_TYPE;
    return_type::Type,
    verbose::Bool = true,
    api_key::String = OPENAI_API_KEY,
    model::String = MODEL_CHAT,
    return_all::Bool = false, dry_run::Bool = false,
    conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
    http_kwargs::NamedTuple = (retry_non_idempotent = true,
        retries = 5,
        readtimeout = 120), api_kwargs::NamedTuple = (;
        tool_choice = "exact"),
    kwargs...)
```


Extract required information (defined by a struct **`return_type`**) from the provided prompt by leveraging OpenAI function calling mode.

This is a perfect solution for extracting structured information from text (eg, extract organization names in news articles, etc.)

It's effectively a light wrapper around `aigenerate` call, which requires additional keyword argument `return_type` to be provided  and will enforce the model outputs to adhere to it.

**Arguments**
- `prompt_schema`: An optional object to specify which prompt template should be applied (Default to `PROMPT_SCHEMA = OpenAISchema`)
  
- `prompt`: Can be a string representing the prompt for the AI conversation, a `UserMessage`, a vector of `AbstractMessage` or an `AITemplate`
  
- `return_type`: A **struct** TYPE representing the the information we want to extract. Do not provide a struct instance, only the type. If the struct has a docstring, it will be provided to the model as well. It's used to enforce structured model outputs or provide more information.
  
- `verbose`: A boolean indicating whether to print additional information.
  
- `api_key`: A string representing the API key for accessing the OpenAI API.
  
- `model`: A string representing the model to use for generating the response. Can be an alias corresponding to a model ID defined in `MODEL_ALIASES`.
  
- `return_all::Bool=false`: If `true`, returns the entire conversation history, otherwise returns only the last message (the `AIMessage`).
  
- `dry_run::Bool=false`: If `true`, skips sending the messages to the model (for debugging, often used with `return_all=true`).
  
- `conversation`: An optional vector of `AbstractMessage` objects representing the conversation history. If not provided, it is initialized as an empty vector.
  
- `http_kwargs`: A named tuple of HTTP keyword arguments.
  
- `api_kwargs`: A named tuple of API keyword arguments. 
  - `tool_choice`: A string representing the tool choice to use for the API call. Usually, one of "auto","any","exact".  Defaults to `"exact"`, which is a made-up value to enforce the OpenAI requirements if we want one exact function. Providers like Mistral, Together, etc. use `"any"` instead.
    
  
- `kwargs`: Prompt variables to be used to fill the prompt/template
  

**Returns**

If `return_all=false` (default):
- `msg`: An `DataMessage` object representing the extracted data, including the content, status, tokens, and elapsed time.  Use `msg.content` to access the extracted data.
  

If `return_all=true`:
- `conversation`: A vector of `AbstractMessage` objects representing the full conversation history, including the response from the AI model (`DataMessage`).
  

See also: `function_call_signature`, `MaybeExtract`, `ItemsExtract`, `aigenerate`

**Example**

Do you want to extract some specific measurements from a text like age, weight and height? You need to define the information you need as a struct (`return_type`):

```
"Person's age, height, and weight."
struct MyMeasurement
    age::Int # required
    height::Union{Int,Nothing} # optional
    weight::Union{Nothing,Float64} # optional
end
msg = aiextract("James is 30, weighs 80kg. He's 180cm tall."; return_type=MyMeasurement)
# PromptingTools.DataMessage(MyMeasurement)
msg.content
# MyMeasurement(30, 180, 80.0)
```


The fields that allow `Nothing` are marked as optional in the schema:

```
msg = aiextract("James is 30."; return_type=MyMeasurement)
# MyMeasurement(30, nothing, nothing)
```


If there are multiple items you want to extract, define a wrapper struct to get a Vector of `MyMeasurement`:

```
struct MyMeasurementWrapper
    measurements::Vector{MyMeasurement}
end

msg = aiextract("James is 30, weighs 80kg. He's 180cm tall. Then Jack is 19 but really tall - over 190!"; return_type=ManyMeasurements)

msg.content.measurements
# 2-element Vector{MyMeasurement}:
#  MyMeasurement(30, 180, 80.0)
#  MyMeasurement(19, 190, nothing)
```


Or you can use the convenience wrapper `ItemsExtract` to extract multiple measurements (zero, one or more):

```julia
using PromptingTools: ItemsExtract

return_type = ItemsExtract{MyMeasurement}
msg = aiextract("James is 30, weighs 80kg. He's 180cm tall. Then Jack is 19 but really tall - over 190!"; return_type)

msg.content.items # see the extracted items
```


Or if you want your extraction to fail gracefully when data isn't found, use `MaybeExtract{T}` wrapper  (this trick is inspired by the Instructor package!):

```
using PromptingTools: MaybeExtract

type = MaybeExtract{MyMeasurement}
# Effectively the same as:
# struct MaybeExtract{T}
#     result::Union{T, Nothing} // The result of the extraction
#     error::Bool // true if a result is found, false otherwise
#     message::Union{Nothing, String} // Only present if no result is found, should be short and concise
# end

# If LLM extraction fails, it will return a Dict with `error` and `message` fields instead of the result!
msg = aiextract("Extract measurements from the text: I am giraffe", type)
msg.content
# MaybeExtract{MyMeasurement}(nothing, true, "I'm sorry, but I can only assist with human measurements.")
```


That way, you can handle the error gracefully and get a reason why extraction failed (in `msg.content.message`).

Note that the error message refers to a giraffe not being a human,   because in our `MyMeasurement` docstring, we said that it's for people!

Some non-OpenAI providers require a different specification of the "tool choice" than OpenAI.  For example, to use Mistral models ("mistrall" for mistral large), do:

```julia
"Some fruit"
struct Fruit
    name::String
end
aiextract("I ate an apple",return_type=Fruit,api_kwargs=(;tool_choice="any"),model="mistrall")
# Notice two differences: 1) struct MUST have a docstring, 2) tool_choice is set explicitly set to "any"
```



[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/llm_openai.jl#L909-L1040)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.aigenerate-Tuple{PromptingTools.AbstractGoogleSchema, Union{AbstractString, PromptingTools.AbstractMessage, Vector{<:PromptingTools.AbstractMessage}}}' href='#PromptingTools.aigenerate-Tuple{PromptingTools.AbstractGoogleSchema, Union{AbstractString, PromptingTools.AbstractMessage, Vector{<:PromptingTools.AbstractMessage}}}'>#</a>&nbsp;<b><u>PromptingTools.aigenerate</u></b> &mdash; <i>Method</i>.




```julia
aigenerate(prompt_schema::AbstractGoogleSchema, prompt::ALLOWED_PROMPT_TYPE;
    verbose::Bool = true,
    api_key::String = GOOGLE_API_KEY,
    model::String = "gemini-pro", return_all::Bool = false, dry_run::Bool = false,
    http_kwargs::NamedTuple = (retry_non_idempotent = true,
        retries = 5,
        readtimeout = 120), api_kwargs::NamedTuple = NamedTuple(),
    kwargs...)
```


Generate an AI response based on a given prompt using the Google Gemini API. Get the API key [here](https://ai.google.dev/).

Note: 
- There is no "cost" reported as of February 2024, as all access seems to be free-of-charge. See the details [here](https://ai.google.dev/pricing).
  
- `tokens` in the returned AIMessage are actually characters, not tokens. We use a _conservative_ estimate as they are not provided by the API yet.
  

**Arguments**
- `prompt_schema`: An optional object to specify which prompt template should be applied (Default to `PROMPT_SCHEMA = OpenAISchema`)
  
- `prompt`: Can be a string representing the prompt for the AI conversation, a `UserMessage`, a vector of `AbstractMessage` or an `AITemplate`
  
- `verbose`: A boolean indicating whether to print additional information.
  
- `api_key`: A string representing the API key for accessing the OpenAI API.
  
- `model`: A string representing the model to use for generating the response. Can be an alias corresponding to a model ID defined in `MODEL_ALIASES`. Defaults to 
  
- `return_all::Bool=false`: If `true`, returns the entire conversation history, otherwise returns only the last message (the `AIMessage`).
  
- `dry_run::Bool=false`: If `true`, skips sending the messages to the model (for debugging, often used with `return_all=true`).
  
- `conversation`: An optional vector of `AbstractMessage` objects representing the conversation history. If not provided, it is initialized as an empty vector.
  
- `http_kwargs`: A named tuple of HTTP keyword arguments.
  
- `api_kwargs`: A named tuple of API keyword arguments.
  
- `kwargs`: Prompt variables to be used to fill the prompt/template
  

**Returns**

If `return_all=false` (default):
- `msg`: An `AIMessage` object representing the generated AI message, including the content, status, tokens, and elapsed time.
  

Use `msg.content` to access the extracted string.

If `return_all=true`:
- `conversation`: A vector of `AbstractMessage` objects representing the conversation history, including the response from the AI model (`AIMessage`).
  

See also: `ai_str`, `aai_str`, `aiembed`, `aiclassify`, `aiextract`, `aiscan`, `aitemplates`

**Example**

Simple hello world to test the API:

```julia
result = aigenerate("Say Hi!"; model="gemini-pro")
# AIMessage("Hi there! 👋 I'm here to help you with any questions or tasks you may have. Just let me know what you need, and I'll do my best to assist you.")
```


`result` is an `AIMessage` object. Access the generated string via `content` property:

```julia
typeof(result) # AIMessage{SubString{String}}
propertynames(result) # (:content, :status, :tokens, :elapsed
result.content # "Hi there! ...
```


___ You can use string interpolation and alias "gemini":

```julia
a = 1
msg=aigenerate("What is `$a+$a`?"; model="gemini")
msg.content # "1+1 is 2."
```


___ You can provide the whole conversation or more intricate prompts as a `Vector{AbstractMessage}`:

```julia
const PT = PromptingTools

conversation = [
    PT.SystemMessage("You're master Yoda from Star Wars trying to help the user become a Yedi."),
    PT.UserMessage("I have feelings for my iPhone. What should I do?")]
msg=aigenerate(conversation; model="gemini")
# AIMessage("Young Padawan, you have stumbled into a dangerous path.... <continues>")
```



[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/llm_google.jl#L75-L147)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.aigenerate-Tuple{PromptingTools.AbstractOllamaManagedSchema, Union{AbstractString, PromptingTools.AbstractMessage, Vector{<:PromptingTools.AbstractMessage}}}' href='#PromptingTools.aigenerate-Tuple{PromptingTools.AbstractOllamaManagedSchema, Union{AbstractString, PromptingTools.AbstractMessage, Vector{<:PromptingTools.AbstractMessage}}}'>#</a>&nbsp;<b><u>PromptingTools.aigenerate</u></b> &mdash; <i>Method</i>.




```julia
aigenerate(prompt_schema::AbstractOllamaManagedSchema, prompt::ALLOWED_PROMPT_TYPE; verbose::Bool = true,
    api_key::String = "", model::String = MODEL_CHAT,
    return_all::Bool = false, dry_run::Bool = false,
    conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
    http_kwargs::NamedTuple = NamedTuple(), api_kwargs::NamedTuple = NamedTuple(),
    kwargs...)
```


Generate an AI response based on a given prompt using the OpenAI API.

**Arguments**
- `prompt_schema`: An optional object to specify which prompt template should be applied (Default to `PROMPT_SCHEMA = OpenAISchema` not `AbstractManagedSchema`)
  
- `prompt`: Can be a string representing the prompt for the AI conversation, a `UserMessage`, a vector of `AbstractMessage` or an `AITemplate`
  
- `verbose`: A boolean indicating whether to print additional information.
  
- `api_key`: Provided for interface consistency. Not needed for locally hosted Ollama.
  
- `model`: A string representing the model to use for generating the response. Can be an alias corresponding to a model ID defined in `MODEL_ALIASES`.
  
- `return_all::Bool=false`: If `true`, returns the entire conversation history, otherwise returns only the last message (the `AIMessage`).
  
- `dry_run::Bool=false`: If `true`, skips sending the messages to the model (for debugging, often used with `return_all=true`).
  
- `conversation::AbstractVector{<:AbstractMessage}=[]`: Not allowed for this schema. Provided only for compatibility.
  
- `http_kwargs::NamedTuple`: Additional keyword arguments for the HTTP request. Defaults to empty `NamedTuple`.
  
- `api_kwargs::NamedTuple`: Additional keyword arguments for the Ollama API. Defaults to an empty `NamedTuple`.
  
- `kwargs`: Prompt variables to be used to fill the prompt/template
  

**Returns**
- `msg`: An `AIMessage` object representing the generated AI message, including the content, status, tokens, and elapsed time.
  

Use `msg.content` to access the extracted string.

See also: `ai_str`, `aai_str`, `aiembed`

**Example**

Simple hello world to test the API:

```julia
const PT = PromptingTools
schema = PT.OllamaManagedSchema() # We need to explicit if we want Ollama, OpenAISchema is the default

msg = aigenerate(schema, "Say hi!"; model="openhermes2.5-mistral")
# [ Info: Tokens: 69 in 0.9 seconds
# AIMessage("Hello! How can I assist you today?")
```


`msg` is an `AIMessage` object. Access the generated string via `content` property:

```julia
typeof(msg) # AIMessage{SubString{String}}
propertynames(msg) # (:content, :status, :tokens, :elapsed
msg.content # "Hello! How can I assist you today?"
```


Note: We need to be explicit about the schema we want to use. If we don't, it will default to `OpenAISchema` (=`PT.DEFAULT_SCHEMA`) ___ You can use string interpolation:

```julia
const PT = PromptingTools
schema = PT.OllamaManagedSchema()
a = 1
msg=aigenerate(schema, "What is `$a+$a`?"; model="openhermes2.5-mistral")
msg.content # "The result of `1+1` is `2`."
```


___ You can provide the whole conversation or more intricate prompts as a `Vector{AbstractMessage}`:

```julia
const PT = PromptingTools
schema = PT.OllamaManagedSchema()

conversation = [
    PT.SystemMessage("You're master Yoda from Star Wars trying to help the user become a Yedi."),
    PT.UserMessage("I have feelings for my iPhone. What should I do?")]

msg = aigenerate(schema, conversation; model="openhermes2.5-mistral")
# [ Info: Tokens: 111 in 2.1 seconds
# AIMessage("Strong the attachment is, it leads to suffering it may. Focus on the force within you must, ...<continues>")
```


Note: Managed Ollama currently supports at most 1 User Message and 1 System Message given the API limitations. If you want more, you need to use the `ChatMLSchema`.


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/llm_ollama_managed.jl#L124-L198)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.aigenerate-Tuple{PromptingTools.AbstractOllamaSchema, Union{AbstractString, PromptingTools.AbstractMessage, Vector{<:PromptingTools.AbstractMessage}}}' href='#PromptingTools.aigenerate-Tuple{PromptingTools.AbstractOllamaSchema, Union{AbstractString, PromptingTools.AbstractMessage, Vector{<:PromptingTools.AbstractMessage}}}'>#</a>&nbsp;<b><u>PromptingTools.aigenerate</u></b> &mdash; <i>Method</i>.




```julia
aigenerate(prompt_schema::AbstractOllamaManagedSchema, prompt::ALLOWED_PROMPT_TYPE; verbose::Bool = true,
    api_key::String = "", model::String = MODEL_CHAT,
    return_all::Bool = false, dry_run::Bool = false,
    conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
    http_kwargs::NamedTuple = NamedTuple(), api_kwargs::NamedTuple = NamedTuple(),
    kwargs...)
```


Generate an AI response based on a given prompt using the OpenAI API.

**Arguments**
- `prompt_schema`: An optional object to specify which prompt template should be applied (Default to `PROMPT_SCHEMA = OpenAISchema` not `AbstractManagedSchema`)
  
- `prompt`: Can be a string representing the prompt for the AI conversation, a `UserMessage`, a vector of `AbstractMessage` or an `AITemplate`
  
- `verbose`: A boolean indicating whether to print additional information.
  
- `api_key`: Provided for interface consistency. Not needed for locally hosted Ollama.
  
- `model`: A string representing the model to use for generating the response. Can be an alias corresponding to a model ID defined in `MODEL_ALIASES`.
  
- `return_all::Bool=false`: If `true`, returns the entire conversation history, otherwise returns only the last message (the `AIMessage`).
  
- `dry_run::Bool=false`: If `true`, skips sending the messages to the model (for debugging, often used with `return_all=true`).
  
- `conversation::AbstractVector{<:AbstractMessage}=[]`: Not allowed for this schema. Provided only for compatibility.
  
- `http_kwargs::NamedTuple`: Additional keyword arguments for the HTTP request. Defaults to empty `NamedTuple`.
  
- `api_kwargs::NamedTuple`: Additional keyword arguments for the Ollama API. Defaults to an empty `NamedTuple`.
  
- `kwargs`: Prompt variables to be used to fill the prompt/template
  

**Returns**
- `msg`: An `AIMessage` object representing the generated AI message, including the content, status, tokens, and elapsed time.
  

Use `msg.content` to access the extracted string.

See also: `ai_str`, `aai_str`, `aiembed`

**Example**

Simple hello world to test the API:

```julia
const PT = PromptingTools
schema = PT.OllamaManagedSchema() # We need to explicit if we want Ollama, OpenAISchema is the default

msg = aigenerate(schema, "Say hi!"; model="openhermes2.5-mistral")
# [ Info: Tokens: 69 in 0.9 seconds
# AIMessage("Hello! How can I assist you today?")
```


`msg` is an `AIMessage` object. Access the generated string via `content` property:

```julia
typeof(msg) # AIMessage{SubString{String}}
propertynames(msg) # (:content, :status, :tokens, :elapsed
msg.content # "Hello! How can I assist you today?"
```


Note: We need to be explicit about the schema we want to use. If we don't, it will default to `OpenAISchema` (=`PT.DEFAULT_SCHEMA`) ___ You can use string interpolation:

```julia
const PT = PromptingTools
schema = PT.OllamaManagedSchema()
a = 1
msg=aigenerate(schema, "What is `$a+$a`?"; model="openhermes2.5-mistral")
msg.content # "The result of `1+1` is `2`."
```


___ You can provide the whole conversation or more intricate prompts as a `Vector{AbstractMessage}`:

```julia
const PT = PromptingTools
schema = PT.OllamaManagedSchema()

conversation = [
    PT.SystemMessage("You're master Yoda from Star Wars trying to help the user become a Yedi."),
    PT.UserMessage("I have feelings for my iPhone. What should I do?")]

msg = aigenerate(schema, conversation; model="openhermes2.5-mistral")
# [ Info: Tokens: 111 in 2.1 seconds
# AIMessage("Strong the attachment is, it leads to suffering it may. Focus on the force within you must, ...<continues>")
```


Note: Managed Ollama currently supports at most 1 User Message and 1 System Message given the API limitations. If you want more, you need to use the `ChatMLSchema`.


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/llm_ollama.jl#L67-L141)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.aigenerate-Tuple{PromptingTools.AbstractOpenAISchema, Union{AbstractString, PromptingTools.AbstractMessage, Vector{<:PromptingTools.AbstractMessage}}}' href='#PromptingTools.aigenerate-Tuple{PromptingTools.AbstractOpenAISchema, Union{AbstractString, PromptingTools.AbstractMessage, Vector{<:PromptingTools.AbstractMessage}}}'>#</a>&nbsp;<b><u>PromptingTools.aigenerate</u></b> &mdash; <i>Method</i>.




```julia
aigenerate(prompt_schema::AbstractOpenAISchema, prompt::ALLOWED_PROMPT_TYPE;
    verbose::Bool = true,
    api_key::String = OPENAI_API_KEY,
    model::String = MODEL_CHAT, return_all::Bool = false, dry_run::Bool = false,
    http_kwargs::NamedTuple = (retry_non_idempotent = true,
        retries = 5,
        readtimeout = 120), api_kwargs::NamedTuple = NamedTuple(),
    kwargs...)
```


Generate an AI response based on a given prompt using the OpenAI API.

**Arguments**
- `prompt_schema`: An optional object to specify which prompt template should be applied (Default to `PROMPT_SCHEMA = OpenAISchema`)
  
- `prompt`: Can be a string representing the prompt for the AI conversation, a `UserMessage`, a vector of `AbstractMessage` or an `AITemplate`
  
- `verbose`: A boolean indicating whether to print additional information.
  
- `api_key`: A string representing the API key for accessing the OpenAI API.
  
- `model`: A string representing the model to use for generating the response. Can be an alias corresponding to a model ID defined in `MODEL_ALIASES`.
  
- `return_all::Bool=false`: If `true`, returns the entire conversation history, otherwise returns only the last message (the `AIMessage`).
  
- `dry_run::Bool=false`: If `true`, skips sending the messages to the model (for debugging, often used with `return_all=true`).
  
- `conversation`: An optional vector of `AbstractMessage` objects representing the conversation history. If not provided, it is initialized as an empty vector.
  
- `http_kwargs`: A named tuple of HTTP keyword arguments.
  
- `api_kwargs`: A named tuple of API keyword arguments. Useful parameters include:
  - `temperature`: A float representing the temperature for sampling (ie, the amount of "creativity"). Often defaults to `0.7`.
    
  - `logprobs`: A boolean indicating whether to return log probabilities for each token. Defaults to `false`.
    
  - `n`: An integer representing the number of completions to generate at once (if supported).
    
  - `stop`: A vector of strings representing the stop conditions for the conversation. Defaults to an empty vector.
    
  
- `kwargs`: Prompt variables to be used to fill the prompt/template
  

**Returns**

If `return_all=false` (default):
- `msg`: An `AIMessage` object representing the generated AI message, including the content, status, tokens, and elapsed time.
  

Use `msg.content` to access the extracted string.

If `return_all=true`:
- `conversation`: A vector of `AbstractMessage` objects representing the conversation history, including the response from the AI model (`AIMessage`).
  

See also: `ai_str`, `aai_str`, `aiembed`, `aiclassify`, `aiextract`, `aiscan`, `aitemplates`

**Example**

Simple hello world to test the API:

```julia
result = aigenerate("Say Hi!")
# [ Info: Tokens: 29 @ Cost: $0.0 in 1.0 seconds
# AIMessage("Hello! How can I assist you today?")
```


`result` is an `AIMessage` object. Access the generated string via `content` property:

```julia
typeof(result) # AIMessage{SubString{String}}
propertynames(result) # (:content, :status, :tokens, :elapsed
result.content # "Hello! How can I assist you today?"
```


___ You can use string interpolation:

```julia
a = 1
msg=aigenerate("What is `$a+$a`?")
msg.content # "The sum of `1+1` is `2`."
```


___ You can provide the whole conversation or more intricate prompts as a `Vector{AbstractMessage}`:

```julia
const PT = PromptingTools

conversation = [
    PT.SystemMessage("You're master Yoda from Star Wars trying to help the user become a Yedi."),
    PT.UserMessage("I have feelings for my iPhone. What should I do?")]
msg=aigenerate(conversation)
# AIMessage("Ah, strong feelings you have for your iPhone. A Jedi's path, this is not... <continues>")
```



[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/llm_openai.jl#L405-L478)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.aiimage-Tuple{PromptingTools.AbstractOpenAISchema, Union{AbstractString, PromptingTools.AbstractMessage, Vector{<:PromptingTools.AbstractMessage}}}' href='#PromptingTools.aiimage-Tuple{PromptingTools.AbstractOpenAISchema, Union{AbstractString, PromptingTools.AbstractMessage, Vector{<:PromptingTools.AbstractMessage}}}'>#</a>&nbsp;<b><u>PromptingTools.aiimage</u></b> &mdash; <i>Method</i>.




```julia
aiimage(prompt_schema::AbstractOpenAISchema, prompt::ALLOWED_PROMPT_TYPE;
    image_size::AbstractString = "1024x1024",
    image_quality::AbstractString = "standard",
    image_n::Integer = 1,
    verbose::Bool = true,
    api_key::String = OPENAI_API_KEY,
    model::String = MODEL_IMAGE_GENERATION,
    return_all::Bool = false, dry_run::Bool = false,
    conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
    http_kwargs::NamedTuple = (retry_non_idempotent = true,
        retries = 5,
        readtimeout = 120), api_kwargs::NamedTuple = NamedTuple(),
    kwargs...)
```


Generates an image from the provided `prompt`. If multiple "messages" are provided in `prompt`, it extracts the text ONLY from the last message!

Image (or the reference to it) will be returned in a `DataMessage.content`, the format will depend on the `api_kwargs.response_format` you set.

Can be used for generating images of varying quality and style with `dall-e-*` models. This function DOES NOT SUPPORT multi-turn conversations (ie, do not provide previous conversation via `conversation` argument).

**Arguments**
- `prompt_schema`: An optional object to specify which prompt template should be applied (Default to `PROMPT_SCHEMA = OpenAISchema`)
  
- `prompt`: Can be a string representing the prompt for the AI conversation, a `UserMessage`, a vector of `AbstractMessage` or an `AITemplate`
  
- `image_size`: String-based resolution of the image, eg, "1024x1024". Only some resolutions are supported - see the [API docs](https://platform.openai.com/docs/api-reference/images/create).
  
- `image_quality`: It can be either "standard" or "hd". Defaults to "standard".
  
- `image_n`: The number of images to generate. Currently, only single image generation is allowed (`image_n = 1`).
  
- `verbose`: A boolean indicating whether to print additional information.
  
- `api_key`: A string representing the API key for accessing the OpenAI API.
  
- `model`: A string representing the model to use for generating the response. Can be an alias corresponding to a model ID defined in `MODEL_IMAGE_GENERATION`.
  
- `return_all::Bool=false`: If `true`, returns the entire conversation history, otherwise returns only the last message (the `AIMessage`).
  
- `dry_run::Bool=false`: If `true`, skips sending the messages to the model (for debugging, often used with `return_all=true`).
  
- `conversation`: An optional vector of `AbstractMessage` objects representing the conversation history. Currently, NOT ALLOWED.
  
- `http_kwargs`: A named tuple of HTTP keyword arguments.
  
- `api_kwargs`: A named tuple of API keyword arguments. Several important arguments are highlighted below:
  - `response_format`: The format image should be returned in. Can be one of "url" or "b64_json". Defaults to "url" (the link will be inactived in 60 minutes).
    
  - `style`: The style of generated images (DALL-E 3 only). Can be either "vidid" or "natural". Defauls to "vidid".
    
  
- `kwargs`: Prompt variables to be used to fill the prompt/template
  

**Returns**

If `return_all=false` (default):
- `msg`: A `DataMessage` object representing one or more generated images, including the rewritten prompt if relevant, status, and elapsed time.
  

Use `msg.content` to access the extracted string.

If `return_all=true`:
- `conversation`: A vector of `AbstractMessage` objects representing the full conversation history, including the response from the AI model (`AIMessage`).
  

See also: `ai_str`, `aai_str`, `aigenerate`, `aiembed`, `aiclassify`, `aiextract`, `aiscan`, `aitemplates`

**Notes**
- This function DOES NOT SUPPORT multi-turn conversations (ie, do not provide previous conversation via `conversation` argument).
  
- There is no token tracking provided by the API, so the messages will NOT report any cost despite costing you money!
  
- You MUST download any URL-based images within 60 minutes. The links will become inactive.
  

**Example**

Generate an image:

```julia
# You can experiment with `image_size`, `image_quality` kwargs!
msg = aiimage("A white cat on a car")

# Download the image into a file
using Downloads
Downloads.download(msg.content[:url], "cat_on_car.png")

# You can also see the revised prompt that DALL-E 3 used
msg.content[:revised_prompt]
# Output: "Visualize a pristine white cat gracefully perched atop a shiny car. 
# The cat's fur is stark white and its eyes bright with curiosity. 
# As for the car, it could be a contemporary sedan, glossy and in a vibrant color. 
# The scene could be set under the blue sky, enhancing the contrast between the white cat, the colorful car, and the bright blue sky."
```


Note that you MUST download any URL-based images within 60 minutes. The links will become inactive.

If you wanted to download image directly into the DataMessage, provide `response_format="b64_json"` in `api_kwargs`:

```julia
msg = aiimage("A white cat on a car"; image_quality="hd", api_kwargs=(; response_format="b64_json"))

# Then you need to use Base64 package to decode it and save it to a file:
using Base64
write("cat_on_car_hd.png", base64decode(msg.content[:b64_json]));
```



[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/llm_openai.jl#L1275-L1360)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.aiscan-Tuple{PromptingTools.AbstractOllamaSchema, Union{AbstractString, PromptingTools.AbstractMessage, Vector{<:PromptingTools.AbstractMessage}}}' href='#PromptingTools.aiscan-Tuple{PromptingTools.AbstractOllamaSchema, Union{AbstractString, PromptingTools.AbstractMessage, Vector{<:PromptingTools.AbstractMessage}}}'>#</a>&nbsp;<b><u>PromptingTools.aiscan</u></b> &mdash; <i>Method</i>.




```julia
aiscan([prompt_schema::AbstractOllamaSchema,] prompt::ALLOWED_PROMPT_TYPE; 
image_url::Union{Nothing, AbstractString, Vector{<:AbstractString}} = nothing,
image_path::Union{Nothing, AbstractString, Vector{<:AbstractString}} = nothing,
attach_to_latest::Bool = true,
verbose::Bool = true, api_key::String = OPENAI_API_KEY,
    model::String = MODEL_CHAT,
    return_all::Bool = false, dry_run::Bool = false,
    conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
    http_kwargs::NamedTuple = (;
        retry_non_idempotent = true,
        retries = 5,
        readtimeout = 120), 
    api_kwargs::NamedTuple = = (; max_tokens = 2500),
    kwargs...)
```


Scans the provided image (`image_url` or `image_path`) with the goal provided in the `prompt`.

Can be used for many multi-modal tasks, such as: OCR (transcribe text in the image), image captioning, image classification, etc.

It's effectively a light wrapper around `aigenerate` call, which uses additional keyword arguments `image_url`, `image_path`, `image_detail` to be provided.   At least one image source (url or path) must be provided.

**Arguments**
- `prompt_schema`: An optional object to specify which prompt template should be applied (Default to `PROMPT_SCHEMA = OpenAISchema`)
  
- `prompt`: Can be a string representing the prompt for the AI conversation, a `UserMessage`, a vector of `AbstractMessage` or an `AITemplate`
  
- `image_url`: A string or vector of strings representing the URL(s) of the image(s) to scan.
  
- `image_path`: A string or vector of strings representing the path(s) of the image(s) to scan.
  
- `image_detail`: A string representing the level of detail to include for images. Can be `"auto"`, `"high"`, or `"low"`. See [OpenAI Vision Guide](https://platform.openai.com/docs/guides/vision) for more details.
  
- `attach_to_latest`: A boolean how to handle if a conversation with multiple `UserMessage` is provided. When `true`, the images are attached to the latest `UserMessage`.
  
- `verbose`: A boolean indicating whether to print additional information.
  
- `api_key`: A string representing the API key for accessing the OpenAI API.
  
- `model`: A string representing the model to use for generating the response. Can be an alias corresponding to a model ID defined in `MODEL_ALIASES`.
  
- `return_all::Bool=false`: If `true`, returns the entire conversation history, otherwise returns only the last message (the `AIMessage`).
  
- `dry_run::Bool=false`: If `true`, skips sending the messages to the model (for debugging, often used with `return_all=true`).
  
- `conversation`: An optional vector of `AbstractMessage` objects representing the conversation history. If not provided, it is initialized as an empty vector.
  
- `http_kwargs`: A named tuple of HTTP keyword arguments.
  
- `api_kwargs`: A named tuple of API keyword arguments.
  
- `kwargs`: Prompt variables to be used to fill the prompt/template
  

**Returns**

If `return_all=false` (default):
- `msg`: An `AIMessage` object representing the generated AI message, including the content, status, tokens, and elapsed time.
  

Use `msg.content` to access the extracted string.

If `return_all=true`:
- `conversation`: A vector of `AbstractMessage` objects representing the full conversation history, including the response from the AI model (`AIMessage`).
  

See also: `ai_str`, `aai_str`, `aigenerate`, `aiembed`, `aiclassify`, `aiextract`, `aitemplates`

**Notes**
- All examples below use model "gpt4v", which is an alias for model ID "gpt-4-vision-preview"
  
- `max_tokens` in the `api_kwargs` is preset to 2500, otherwise OpenAI enforces a default of only a few hundred tokens (~300). If your output is truncated, increase this value
  

**Example**

Describe the provided image:

```julia
msg = aiscan("Describe the image"; image_path="julia.png", model="bakllava")
# [ Info: Tokens: 1141 @ Cost: $0.0117 in 2.2 seconds
# AIMessage("The image shows a logo consisting of the word "julia" written in lowercase")
```


You can provide multiple images at once as a vector and ask for "low" level of detail (cheaper):

```julia
msg = aiscan("Describe the image"; image_path=["julia.png","python.png"] model="bakllava")
```


You can use this function as a nice and quick OCR (transcribe text in the image) with a template `:OCRTask`.  Let's transcribe some SQL code from a screenshot (no more re-typing!):

```julia
using Downloads
# Screenshot of some SQL code -- we cannot use image_url directly, so we need to download it first
image_url = "https://www.sqlservercentral.com/wp-content/uploads/legacy/8755f69180b7ac7ee76a69ae68ec36872a116ad4/24622.png"
image_path = Downloads.download(image_url)
msg = aiscan(:OCRTask; image_path, model="bakllava", task="Transcribe the SQL code in the image.", api_kwargs=(; max_tokens=2500))

# AIMessage("```sql
# update Orders <continue>

# You can add syntax highlighting of the outputs via Markdown
using Markdown
msg.content |> Markdown.parse
```


Local models cannot handle image URLs directly (`image_url`), so you need to download the image first and provide it as `image_path`:

```julia
using Downloads
image_path = Downloads.download(image_url)
```


Notice that we set `max_tokens = 2500`. If your outputs seem truncated, it might be because the default maximum tokens on the server is set too low!


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/llm_ollama.jl#L192-L288)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.aiscan-Tuple{PromptingTools.AbstractOpenAISchema, Union{AbstractString, PromptingTools.AbstractMessage, Vector{<:PromptingTools.AbstractMessage}}}' href='#PromptingTools.aiscan-Tuple{PromptingTools.AbstractOpenAISchema, Union{AbstractString, PromptingTools.AbstractMessage, Vector{<:PromptingTools.AbstractMessage}}}'>#</a>&nbsp;<b><u>PromptingTools.aiscan</u></b> &mdash; <i>Method</i>.




```julia
aiscan([prompt_schema::AbstractOpenAISchema,] prompt::ALLOWED_PROMPT_TYPE; 
image_url::Union{Nothing, AbstractString, Vector{<:AbstractString}} = nothing,
image_path::Union{Nothing, AbstractString, Vector{<:AbstractString}} = nothing,
image_detail::AbstractString = "auto",
attach_to_latest::Bool = true,
verbose::Bool = true, api_key::String = OPENAI_API_KEY,
    model::String = MODEL_CHAT,
    return_all::Bool = false, dry_run::Bool = false,
    conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
    http_kwargs::NamedTuple = (;
        retry_non_idempotent = true,
        retries = 5,
        readtimeout = 120), 
    api_kwargs::NamedTuple = = (; max_tokens = 2500),
    kwargs...)
```


Scans the provided image (`image_url` or `image_path`) with the goal provided in the `prompt`.

Can be used for many multi-modal tasks, such as: OCR (transcribe text in the image), image captioning, image classification, etc.

It's effectively a light wrapper around `aigenerate` call, which uses additional keyword arguments `image_url`, `image_path`, `image_detail` to be provided.   At least one image source (url or path) must be provided.

**Arguments**
- `prompt_schema`: An optional object to specify which prompt template should be applied (Default to `PROMPT_SCHEMA = OpenAISchema`)
  
- `prompt`: Can be a string representing the prompt for the AI conversation, a `UserMessage`, a vector of `AbstractMessage` or an `AITemplate`
  
- `image_url`: A string or vector of strings representing the URL(s) of the image(s) to scan.
  
- `image_path`: A string or vector of strings representing the path(s) of the image(s) to scan.
  
- `image_detail`: A string representing the level of detail to include for images. Can be `"auto"`, `"high"`, or `"low"`. See [OpenAI Vision Guide](https://platform.openai.com/docs/guides/vision) for more details.
  
- `attach_to_latest`: A boolean how to handle if a conversation with multiple `UserMessage` is provided. When `true`, the images are attached to the latest `UserMessage`.
  
- `verbose`: A boolean indicating whether to print additional information.
  
- `api_key`: A string representing the API key for accessing the OpenAI API.
  
- `model`: A string representing the model to use for generating the response. Can be an alias corresponding to a model ID defined in `MODEL_ALIASES`.
  
- `return_all::Bool=false`: If `true`, returns the entire conversation history, otherwise returns only the last message (the `AIMessage`).
  
- `dry_run::Bool=false`: If `true`, skips sending the messages to the model (for debugging, often used with `return_all=true`).
  
- `conversation`: An optional vector of `AbstractMessage` objects representing the conversation history. If not provided, it is initialized as an empty vector.
  
- `http_kwargs`: A named tuple of HTTP keyword arguments.
  
- `api_kwargs`: A named tuple of API keyword arguments.
  
- `kwargs`: Prompt variables to be used to fill the prompt/template
  

**Returns**

If `return_all=false` (default):
- `msg`: An `AIMessage` object representing the generated AI message, including the content, status, tokens, and elapsed time.
  

Use `msg.content` to access the extracted string.

If `return_all=true`:
- `conversation`: A vector of `AbstractMessage` objects representing the full conversation history, including the response from the AI model (`AIMessage`).
  

See also: `ai_str`, `aai_str`, `aigenerate`, `aiembed`, `aiclassify`, `aiextract`, `aitemplates`

**Notes**
- All examples below use model "gpt4v", which is an alias for model ID "gpt-4-vision-preview"
  
- `max_tokens` in the `api_kwargs` is preset to 2500, otherwise OpenAI enforces a default of only a few hundred tokens (~300). If your output is truncated, increase this value
  

**Example**

Describe the provided image:

```julia
msg = aiscan("Describe the image"; image_path="julia.png", model="gpt4v")
# [ Info: Tokens: 1141 @ Cost: $0.0117 in 2.2 seconds
# AIMessage("The image shows a logo consisting of the word "julia" written in lowercase")
```


You can provide multiple images at once as a vector and ask for "low" level of detail (cheaper):

```julia
msg = aiscan("Describe the image"; image_path=["julia.png","python.png"], image_detail="low", model="gpt4v")
```


You can use this function as a nice and quick OCR (transcribe text in the image) with a template `:OCRTask`.  Let's transcribe some SQL code from a screenshot (no more re-typing!):

```julia
# Screenshot of some SQL code
image_url = "https://www.sqlservercentral.com/wp-content/uploads/legacy/8755f69180b7ac7ee76a69ae68ec36872a116ad4/24622.png"
msg = aiscan(:OCRTask; image_url, model="gpt4v", task="Transcribe the SQL code in the image.", api_kwargs=(; max_tokens=2500))

# [ Info: Tokens: 362 @ Cost: $0.0045 in 2.5 seconds
# AIMessage("```sql
# update Orders <continue>

# You can add syntax highlighting of the outputs via Markdown
using Markdown
msg.content |> Markdown.parse
```


Notice that we enforce `max_tokens = 2500`. That's because OpenAI seems to default to ~300 tokens, which provides incomplete outputs. Hence, we set this value to 2500 as a default. If you still get truncated outputs, increase this value.


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/llm_openai.jl#L1117-L1207)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.aitemplates' href='#PromptingTools.aitemplates'>#</a>&nbsp;<b><u>PromptingTools.aitemplates</u></b> &mdash; <i>Function</i>.




```julia
aitemplates
```


Find easily the most suitable templates for your use case.

You can search by:
- `query::Symbol` which looks look only for partial matches in the template `name`
  
- `query::AbstractString` which looks for partial matches in the template `name` or `description`
  
- `query::Regex` which looks for matches in the template `name`, `description` or any of the message previews
  

**Keyword Arguments**
- `limit::Int` limits the number of returned templates (Defaults to 10)
  

**Examples**

Find available templates with `aitemplates`:

```julia
tmps = aitemplates("JuliaExpertAsk")
# Will surface one specific template
# 1-element Vector{AITemplateMetadata}:
# PromptingTools.AITemplateMetadata
#   name: Symbol JuliaExpertAsk
#   description: String "For asking questions about Julia language. Placeholders: `ask`"
#   version: String "1"
#   wordcount: Int64 237
#   variables: Array{Symbol}((1,))
#   system_preview: String "You are a world-class Julia language programmer with the knowledge of the latest syntax. Your commun"
#   user_preview: String "# Question

{{ask}}"
#   source: String ""
```


The above gives you a good idea of what the template is about, what placeholders are available, and how much it would cost to use it (=wordcount).

Search for all Julia-related templates:

```julia
tmps = aitemplates("Julia")
# 2-element Vector{AITemplateMetadata}... -> more to come later!
```


If you are on VSCode, you can leverage nice tabular display with `vscodedisplay`:

```julia
using DataFrames
tmps = aitemplates("Julia") |> DataFrame |> vscodedisplay
```


I have my selected template, how do I use it? Just use the "name" in `aigenerate` or `aiclassify`   like you see in the first example!


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/templates.jl#L256-L304)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.aitemplates-Tuple{AbstractString}' href='#PromptingTools.aitemplates-Tuple{AbstractString}'>#</a>&nbsp;<b><u>PromptingTools.aitemplates</u></b> &mdash; <i>Method</i>.




Find the top-`limit` templates whose `name` or `description` fields partially match the `query_key::String` in `TEMPLATE_METADATA`.


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/templates.jl#L315)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.aitemplates-Tuple{Regex}' href='#PromptingTools.aitemplates-Tuple{Regex}'>#</a>&nbsp;<b><u>PromptingTools.aitemplates</u></b> &mdash; <i>Method</i>.




Find the top-`limit` templates where provided `query_key::Regex` matches either of `name`, `description` or previews or User or System messages in `TEMPLATE_METADATA`.


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/templates.jl#L326)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.aitemplates-Tuple{Symbol}' href='#PromptingTools.aitemplates-Tuple{Symbol}'>#</a>&nbsp;<b><u>PromptingTools.aitemplates</u></b> &mdash; <i>Method</i>.




Find the top-`limit` templates whose `name::Symbol` partially matches the `query_name::Symbol` in `TEMPLATE_METADATA`.


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/templates.jl#L305)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.auth_header-Tuple{Union{Nothing, AbstractString}}' href='#PromptingTools.auth_header-Tuple{Union{Nothing, AbstractString}}'>#</a>&nbsp;<b><u>PromptingTools.auth_header</u></b> &mdash; <i>Method</i>.




```julia
auth_header(api_key::Union{Nothing, AbstractString};
    extra_headers::AbstractVector{Pair{String, String}} = Vector{Pair{String, String}}[],
    kwargs...)
```


Creates the authentication headers for any API request. Assumes that the communication is done in JSON format.


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/utils.jl#L482-L488)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.build_template_metadata' href='#PromptingTools.build_template_metadata'>#</a>&nbsp;<b><u>PromptingTools.build_template_metadata</u></b> &mdash; <i>Function</i>.




```julia
build_template_metadata(
    template::AbstractVector{<:AbstractMessage}, template_name::Symbol,
    metadata_msgs::AbstractVector{<:MetadataMessage} = MetadataMessage[])
```


Builds `AITemplateMetadata` for a given template based on the messages in `template` and other information.

`AITemplateMetadata` is a helper struct for easy searching and reviewing of templates via `aitemplates()`.


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/templates.jl#L122-L130)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.call_cost-Tuple{Int64, Int64, String}' href='#PromptingTools.call_cost-Tuple{Int64, Int64, String}'>#</a>&nbsp;<b><u>PromptingTools.call_cost</u></b> &mdash; <i>Method</i>.




```julia
call_cost(prompt_tokens::Int, completion_tokens::Int, model::String;
    cost_of_token_prompt::Number = get(MODEL_REGISTRY,
        model,
        (; cost_of_token_prompt = 0.0)).cost_of_token_prompt,
    cost_of_token_generation::Number = get(MODEL_REGISTRY, model,
        (; cost_of_token_generation = 0.0)).cost_of_token_generation)

call_cost(msg, model::String)
```


Calculate the cost of a call based on the number of tokens in the message and the cost per token.

**Arguments**
- `prompt_tokens::Int`: The number of tokens used in the prompt.
  
- `completion_tokens::Int`: The number of tokens used in the completion.
  
- `model::String`: The name of the model to use for determining token costs. If the model is not found in `MODEL_REGISTRY`, default costs are used.
  
- `cost_of_token_prompt::Number`: The cost per prompt token. Defaults to the cost in `MODEL_REGISTRY` for the given model, or 0.0 if the model is not found.
  
- `cost_of_token_generation::Number`: The cost per generation token. Defaults to the cost in `MODEL_REGISTRY` for the given model, or 0.0 if the model is not found.
  

**Returns**
- `Number`: The total cost of the call.
  

**Examples**

```julia
# Assuming MODEL_REGISTRY is set up with appropriate costs
MODEL_REGISTRY = Dict(
    "model1" => (cost_of_token_prompt = 0.05, cost_of_token_generation = 0.10),
    "model2" => (cost_of_token_prompt = 0.07, cost_of_token_generation = 0.02)
)

cost1 = call_cost(10, 20, "model1")

# from message
msg1 = AIMessage(;tokens=[10, 20])  # 10 prompt tokens, 20 generation tokens
cost1 = call_cost(msg1, "model1")
# cost1 = 10 * 0.05 + 20 * 0.10 = 2.5

# Using custom token costs
cost2 = call_cost(10, 20, "model3"; cost_of_token_prompt = 0.08, cost_of_token_generation = 0.12)
# cost2 = 10 * 0.08 + 20 * 0.12 = 3.2
```



[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/utils.jl#L247-L291)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.call_cost_alternative-Tuple{Any, Any}' href='#PromptingTools.call_cost_alternative-Tuple{Any, Any}'>#</a>&nbsp;<b><u>PromptingTools.call_cost_alternative</u></b> &mdash; <i>Method</i>.




call_cost_alternative()

Alternative cost calculation. Used to calculate cost of image generation with DALL-E 3 and similar.


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/utils.jl#L323-L327)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.create_template-Tuple{AbstractString, AbstractString}' href='#PromptingTools.create_template-Tuple{AbstractString, AbstractString}'>#</a>&nbsp;<b><u>PromptingTools.create_template</u></b> &mdash; <i>Method</i>.




```julia
create_template(; user::AbstractString, system::AbstractString="Act as a helpful AI assistant.", 
    load_as::Union{Nothing, Symbol, AbstractString} = nothing)

create_template(system::AbstractString, user::AbstractString, 
    load_as::Union{Nothing, Symbol, AbstractString} = nothing)
```


Creates a simple template with a user and system message. Convenience function to prevent writing `[PT.UserMessage(...), ...]`

**Arguments**
- `system::AbstractString`: The system message. Usually defines the personality, style, instructions, output format, etc.
  
- `user::AbstractString`: The user message. Usually defines the input, query, request, etc.
  
- `load_as::Union{Nothing, Symbol, AbstractString}`: If provided, loads the template into the `TEMPLATE_STORE` under the provided name `load_as`. If `nothing`, does not load the template.
  

Use double handlebar placeholders (eg, `{{name}}`) to define variables that can be replaced by the `kwargs` during the AI call (see example).

Returns a vector of `SystemMessage` and UserMessage objects. If `load_as` is provided, it registers the template in the `TEMPLATE_STORE` and `TEMPLATE_METADATA` as well.

**Examples**

Let's generate a quick template for a simple conversation (only one placeholder: name)

```julia
# first system message, then user message (or use kwargs)
tpl=PT.create_template("You must speak like a pirate", "Say hi to {{name}}")

## 2-element Vector{PromptingTools.AbstractChatMessage}:
## PromptingTools.SystemMessage("You must speak like a pirate")
##  PromptingTools.UserMessage("Say hi to {{name}}")
```


You can immediately use this template in `ai*` functions:

```julia
aigenerate(tpl; name="Jack Sparrow")
# Output: AIMessage("Arr, me hearty! Best be sending me regards to Captain Jack Sparrow on the salty seas! May his compass always point true to the nearest treasure trove. Yarrr!")
```


If you're interested in saving the template in the template registry, jump to the end of these examples!

If you want to save it in your project folder:

```julia
PT.save_template("templates/GreatingPirate.json", tpl; version="1.0") # optionally, add description
```


It will be saved and accessed under its basename, ie, `GreatingPirate`.

Now you can load it like all the other templates (provide the template directory):

```julia
PT.load_templates!("templates") # it will remember the folder after the first run
# Note: If you save it again, overwrite it, etc., you need to explicitly reload all templates again!
```


You can verify that your template is loaded with a quick search for "pirate":

```julia
aitemplates("pirate")

## 1-element Vector{AITemplateMetadata}:
## PromptingTools.AITemplateMetadata
##   name: Symbol GreatingPirate
##   description: String ""
##   version: String "1.0"
##   wordcount: Int64 46
##   variables: Array{Symbol}((1,))
##   system_preview: String "You must speak like a pirate"
##   user_preview: String "Say hi to {{name}}"
##   source: String ""
```


Now you can use it like any other template (notice it's a symbol, so `:GreatingPirate`):

```julia
aigenerate(:GreatingPirate; name="Jack Sparrow")
# Output: AIMessage("Arr, me hearty! Best be sending me regards to Captain Jack Sparrow on the salty seas! May his compass always point true to the nearest treasure trove. Yarrr!")
```


If you do not need to save this template as a file, but you want to make it accessible in the template store for all `ai*` functions, you can use the `load_as` (= template name) keyword argument: ```julia

**this will not only create the template, but also register it for immediate use**

tpl=PT.create_template("You must speak like a pirate", "Say hi to {{name}}"; load_as="GreatingPirate")

**you can now use it like any other template**

aiextract(:GreatingPirate; name="Jack Sparrow") ````


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/templates.jl#L377-L458)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.decode_choices-Tuple{PromptingTools.OpenAISchema, AbstractVector{<:AbstractString}, AIMessage}' href='#PromptingTools.decode_choices-Tuple{PromptingTools.OpenAISchema, AbstractVector{<:AbstractString}, AIMessage}'>#</a>&nbsp;<b><u>PromptingTools.decode_choices</u></b> &mdash; <i>Method</i>.




```julia
decode_choices(schema::OpenAISchema,
    choices::AbstractVector{<:AbstractString},
    msg::AIMessage; kwargs...)
```


Decodes the underlying AIMessage against the original choices to lookup what the category name was.

If it fails, it will return `msg.content == nothing`


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/llm_openai.jl#L748-L756)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.detect_base_main_overrides-Tuple{AbstractString}' href='#PromptingTools.detect_base_main_overrides-Tuple{AbstractString}'>#</a>&nbsp;<b><u>PromptingTools.detect_base_main_overrides</u></b> &mdash; <i>Method</i>.




```julia
detect_base_main_overrides(code_block::AbstractString)
```


Detects if a given code block overrides any Base or Main methods. 

Returns a tuple of a boolean and a vector of the overriden methods.


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/code_parsing.jl#L425-L431)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.encode_choices-Tuple{PromptingTools.OpenAISchema, AbstractVector{<:AbstractString}}' href='#PromptingTools.encode_choices-Tuple{PromptingTools.OpenAISchema, AbstractVector{<:AbstractString}}'>#</a>&nbsp;<b><u>PromptingTools.encode_choices</u></b> &mdash; <i>Method</i>.




```julia
encode_choices(schema::OpenAISchema, choices::AbstractVector{<:AbstractString}; kwargs...)

encode_choices(schema::OpenAISchema, choices::AbstractVector{T};
kwargs...) where {T <: Tuple{<:AbstractString, <:AbstractString}}
```


Encode the choices into an enumerated list that can be interpolated into the prompt and creates the corresponding logit biases (to choose only from the selected tokens).

Optionally, can be a vector tuples, where the first element is the choice and the second is the description.

**Arguments**
- `schema::OpenAISchema`: The OpenAISchema object.
  
- `choices::AbstractVector{<:Union{AbstractString,Tuple{<:AbstractString, <:AbstractString}}}`: The choices to be encoded, represented as a vector of the choices directly, or tuples where each tuple contains a choice and its description.
  
- `kwargs...`: Additional keyword arguments.
  

**Returns**
- `choices_prompt::AbstractString`: The encoded choices as a single string, separated by newlines.
  
- `logit_bias::Dict`: The logit bias dictionary, where the keys are the token IDs and the values are the bias values.
  
- `decode_ids::AbstractVector{<:AbstractString}`: The decoded IDs of the choices.
  

**Examples**

```julia
choices_prompt, logit_bias, _ = PT.encode_choices(PT.OpenAISchema(), ["true", "false"])
choices_prompt # Output: "true for "true"
false for "false"
logit_bias # Output: Dict(837 => 100, 905 => 100)

choices_prompt, logit_bias, _ = PT.encode_choices(PT.OpenAISchema(), ["animal", "plant"])
choices_prompt # Output: "1. "animal"
2. "plant""
logit_bias # Output: Dict(16 => 100, 17 => 100)
```


Or choices with descriptions:

```julia
choices_prompt, logit_bias, _ = PT.encode_choices(PT.OpenAISchema(), [("A", "any animal or creature"), ("P", "for any plant or tree"), ("O", "for everything else")])
choices_prompt # Output: "1. "A" for any animal or creature
2. "P" for any plant or tree
3. "O" for everything else"
logit_bias # Output: Dict(16 => 100, 17 => 100, 18 => 100)
```



[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/llm_openai.jl#L647-L688)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.eval!-Tuple{PromptingTools.AbstractCodeBlock}' href='#PromptingTools.eval!-Tuple{PromptingTools.AbstractCodeBlock}'>#</a>&nbsp;<b><u>PromptingTools.eval!</u></b> &mdash; <i>Method</i>.




```julia
eval!(cb::AbstractCodeBlock;
    safe_eval::Bool = true,
    capture_stdout::Bool = true,
    prefix::AbstractString = "",
    suffix::AbstractString = "")
```


Evaluates a code block `cb` in-place. It runs automatically when AICode is instantiated with a String.

Check the outcome of evaluation with `Base.isvalid(cb)`. If `==true`, provide code block has executed successfully.

Steps:
- If `cb::AICode` has not been evaluated, `cb.success = nothing`.  After the evaluation it will be either `true` or `false` depending on the outcome
  
- Parse the text in `cb.code`
  
- Evaluate the parsed expression
  
- Capture outputs of the evaluated in `cb.output`
  
- [OPTIONAL] Capture any stdout outputs (eg, test failures) in `cb.stdout`
  
- If any error exception is raised, it is saved in `cb.error`
  
- Finally, if all steps were successful, success is set to `cb.success = true`
  

**Keyword Arguments**
- `safe_eval::Bool`: If `true`, we first check for any Pkg operations (eg, installing new packages) and missing imports,  then the code will be evaluated inside a bespoke scratch module (not to change any user variables)
  
- `capture_stdout::Bool`: If `true`, we capture any stdout outputs (eg, test failures) in `cb.stdout`
  
- `prefix::AbstractString`: A string to be prepended to the code block before parsing and evaluation. Useful to add some additional code definition or necessary imports. Defaults to an empty string.
  
- `suffix::AbstractString`: A string to be appended to the code block before parsing and evaluation.  Useful to check that tests pass or that an example executes. Defaults to an empty string.
  


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/code_eval.jl#L213-L242)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.extract_code_blocks-Tuple{T} where T<:AbstractString' href='#PromptingTools.extract_code_blocks-Tuple{T} where T<:AbstractString'>#</a>&nbsp;<b><u>PromptingTools.extract_code_blocks</u></b> &mdash; <i>Method</i>.




```julia
extract_code_blocks(markdown_content::String) -> Vector{String}
```


Extract Julia code blocks from a markdown string.

This function searches through the provided markdown content, identifies blocks of code specifically marked as Julia code  (using the `julia ...` code fence patterns), and extracts the code within these blocks.  The extracted code blocks are returned as a vector of strings, with each string representing one block of Julia code. 

Note: Only the content within the code fences is extracted, and the code fences themselves are not included in the output.

See also: `extract_code_blocks_fallback`

**Arguments**
- `markdown_content::String`: A string containing the markdown content from which Julia code blocks are to be extracted.
  

**Returns**
- `Vector{String}`: A vector containing strings of extracted Julia code blocks. If no Julia code blocks are found, an empty vector is returned.
  

**Examples**

Example with a single Julia code block

```julia
markdown_single = """
```


julia println("Hello, World!")

```
"""
extract_code_blocks(markdown_single)
# Output: ["Hello, World!"]
```


```julia
# Example with multiple Julia code blocks
markdown_multiple = """
```


julia x = 5

```
Some text in between
```


julia y = x + 2

```
"""
extract_code_blocks(markdown_multiple)
# Output: ["x = 5", "y = x + 2"]
```



[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/code_parsing.jl#L173-L219)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.extract_code_blocks_fallback-Union{Tuple{T}, Tuple{T, AbstractString}} where T<:AbstractString' href='#PromptingTools.extract_code_blocks_fallback-Union{Tuple{T}, Tuple{T, AbstractString}} where T<:AbstractString'>#</a>&nbsp;<b><u>PromptingTools.extract_code_blocks_fallback</u></b> &mdash; <i>Method</i>.




```julia
extract_code_blocks_fallback(markdown_content::String, delim::AbstractString="\n```\n")
```


Extract Julia code blocks from a markdown string using a fallback method (splitting by arbitrary `delim`-iters). Much more simplistic than `extract_code_blocks` and does not support nested code blocks.

It is often used as a fallback for smaller LLMs that forget to code fence `julia ...`.

**Example**

```julia
code = """
```


println("hello")

```

Some text

```


println("world")

```
"""

# We extract text between triple backticks and check each blob if it looks like a valid Julia code
code_parsed = extract_code_blocks_fallback(code) |> x -> filter(is_julia_code, x) |> x -> join(x, "
")
```



[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/code_parsing.jl#L274-L301)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.extract_function_name-Tuple{AbstractString}' href='#PromptingTools.extract_function_name-Tuple{AbstractString}'>#</a>&nbsp;<b><u>PromptingTools.extract_function_name</u></b> &mdash; <i>Method</i>.




```julia
extract_function_name(code_block::String) -> Union{String, Nothing}
```


Extract the name of a function from a given Julia code block. The function searches for two patterns:
- The explicit function declaration pattern: `function name(...) ... end`
  
- The concise function declaration pattern: `name(...) = ...`
  

If a function name is found, it is returned as a string. If no function name is found, the function returns `nothing`.

To capture all function names in the block, use `extract_function_names`.

**Arguments**
- `code_block::String`: A string containing Julia code.
  

**Returns**
- `Union{String, Nothing}`: The extracted function name or `nothing` if no name is found.
  

**Example**

```julia
code = """
function myFunction(arg1, arg2)
    # Function body
end
"""
extract_function_name(code)
# Output: "myFunction"
```



[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/code_parsing.jl#L344-L371)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.extract_function_names-Tuple{AbstractString}' href='#PromptingTools.extract_function_names-Tuple{AbstractString}'>#</a>&nbsp;<b><u>PromptingTools.extract_function_names</u></b> &mdash; <i>Method</i>.




```julia
extract_function_names(code_block::AbstractString)
```


Extract one or more names of functions defined in a given Julia code block. The function searches for two patterns:     - The explicit function declaration pattern: `function name(...) ... end`     - The concise function declaration pattern: `name(...) = ...`

It always returns a vector of strings, even if only one function name is found (it will be empty).

For only one function name match, use `extract_function_name`.


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/code_parsing.jl#L394-L404)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.extract_julia_imports-Tuple{AbstractString}' href='#PromptingTools.extract_julia_imports-Tuple{AbstractString}'>#</a>&nbsp;<b><u>PromptingTools.extract_julia_imports</u></b> &mdash; <i>Method</i>.




```julia
extract_julia_imports(input::AbstractString; base_or_main::Bool = false)
```


Detects any `using` or `import` statements in a given string and returns the package names as a vector of symbols. 

`base_or_main` is a boolean that determines whether to isolate only `Base` and `Main` OR whether to exclude them in the returned vector.


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/code_parsing.jl#L23-L29)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.finalize_outputs-Tuple{Union{AbstractString, PromptingTools.AbstractMessage, Vector{<:PromptingTools.AbstractMessage}}, Any, Union{Nothing, PromptingTools.AbstractMessage, AbstractVector{<:PromptingTools.AbstractMessage}}}' href='#PromptingTools.finalize_outputs-Tuple{Union{AbstractString, PromptingTools.AbstractMessage, Vector{<:PromptingTools.AbstractMessage}}, Any, Union{Nothing, PromptingTools.AbstractMessage, AbstractVector{<:PromptingTools.AbstractMessage}}}'>#</a>&nbsp;<b><u>PromptingTools.finalize_outputs</u></b> &mdash; <i>Method</i>.




```julia
finalize_outputs(prompt::ALLOWED_PROMPT_TYPE, conv_rendered::Any,
    msg::Union{Nothing, AbstractMessage, AbstractVector{<:AbstractMessage}};
    return_all::Bool = false,
    dry_run::Bool = false,
    conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
    kwargs...)
```


Finalizes the outputs of the ai* functions by either returning the conversation history or the last message.

**Keyword arguments**
- `return_all::Bool=false`: If true, returns the entire conversation history, otherwise returns only the last message (the `AIMessage`).
  
- `dry_run::Bool=false`: If true, does not send the messages to the model, but only renders the prompt with the given schema and replacement variables. Useful for debugging when you want to check the specific schema rendering. 
  
- `conversation::AbstractVector{<:AbstractMessage}=[]`: An optional vector of `AbstractMessage` objects representing the conversation history. If not provided, it is initialized as an empty vector.
  
- `kwargs...`: Variables to replace in the prompt template.
  


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/llm_shared.jl#L66-L82)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.find_subsequence_positions-Tuple{Any, Any}' href='#PromptingTools.find_subsequence_positions-Tuple{Any, Any}'>#</a>&nbsp;<b><u>PromptingTools.find_subsequence_positions</u></b> &mdash; <i>Method</i>.




```julia
find_subsequence_positions(subseq, seq) -> Vector{Int}
```


Find all positions of a subsequence `subseq` within a larger sequence `seq`. Used to lookup positions of code blocks in markdown.

This function scans the sequence `seq` and identifies all starting positions where the subsequence `subseq` is found. Both `subseq` and `seq` should be vectors of integers, typically obtained using `codeunits` on strings.

**Arguments**
- `subseq`: A vector of integers representing the subsequence to search for.
  
- `seq`: A vector of integers representing the larger sequence in which to search.
  

**Returns**
- `Vector{Int}`: A vector of starting positions (1-based indices) where the subsequence is found in the sequence.
  

**Examples**

```julia
find_subsequence_positions(codeunits("ab"), codeunits("cababcab")) # Returns [2, 5]
```



[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/code_parsing.jl#L132-L150)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.function_call_signature-Tuple{Type}' href='#PromptingTools.function_call_signature-Tuple{Type}'>#</a>&nbsp;<b><u>PromptingTools.function_call_signature</u></b> &mdash; <i>Method</i>.




```julia
function_call_signature(datastructtype::Struct; max_description_length::Int = 100)
```


Extract the argument names, types and docstrings from a struct to create the function call signature in JSON schema.

You must provide a Struct type (not an instance of it) with some fields.

Note: Fairly experimental, but works for combination of structs, arrays, strings and singletons.

**Tips**
- You can improve the quality of the extraction by writing a helpful docstring for your struct (or any nested struct). It will be provided as a description. 
  

You can even include comments/descriptions about the individual fields.
- All fields are assumed to be required, unless you allow null values (eg, `::Union{Nothing, Int}`). Fields with `Nothing` will be treated as optional.
  
- Missing values are ignored (eg, `::Union{Missing, Int}` will be treated as Int). It's for broader compatibility and we cannot deserialize it as easily as `Nothing`.
  

**Example**

Do you want to extract some specific measurements from a text like age, weight and height? You need to define the information you need as a struct (`return_type`):

```
struct MyMeasurement
    age::Int
    height::Union{Int,Nothing}
    weight::Union{Nothing,Float64}
end
signature = function_call_signature(MyMeasurement)
#
# Dict{String, Any} with 3 entries:
#   "name"        => "MyMeasurement_extractor"
#   "parameters"  => Dict{String, Any}("properties"=>Dict{String, Any}("height"=>Dict{String, Any}("type"=>"integer"), "weight"=>Dic…
#   "description" => "Represents person's age, height, and weight
"
```


You can see that only the field `age` does not allow null values, hence, it's "required". While `height` and `weight` are optional.

```
signature["parameters"]["required"]
# ["age"]
```


If there are multiple items you want to extract, define a wrapper struct to get a Vector of `MyMeasurement`:

```
struct MyMeasurementWrapper
    measurements::Vector{MyMeasurement}
end

Or if you want your extraction to fail gracefully when data isn't found, use `MaybeExtract{T}` wrapper (inspired by Instructor package!):
```


using PromptingTools: MaybeExtract

type = MaybeExtract{MyMeasurement}

**Effectively the same as:**

**struct MaybeExtract{T}**

**result::Union{T, Nothing}**

**error::Bool // true if a result is found, false otherwise**

**message::Union{Nothing, String} // Only present if no result is found, should be short and concise**

**end**

**If LLM extraction fails, it will return a Dict with `error` and `message` fields instead of the result!**

msg = aiextract("Extract measurements from the text: I am giraffe", type)

****

**Dict{Symbol, Any} with 2 entries:**

**:message => "Sorry, this feature is only available for humans."**

**:error   => true**

``` That way, you can handle the error gracefully and get a reason why extraction failed.


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/extraction.jl#L84-L152)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.get_preferences-Tuple{String}' href='#PromptingTools.get_preferences-Tuple{String}'>#</a>&nbsp;<b><u>PromptingTools.get_preferences</u></b> &mdash; <i>Method</i>.




```julia
get_preferences(key::String)
```


Get preferences for PromptingTools. See `?PREFERENCES` for more information.

See also: `set_preferences!`

**Example**

```julia
PromptingTools.get_preferences("MODEL_CHAT")
```



[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/user_preferences.jl#L94-L105)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.ggi_generate_content' href='#PromptingTools.ggi_generate_content'>#</a>&nbsp;<b><u>PromptingTools.ggi_generate_content</u></b> &mdash; <i>Function</i>.




Stub - to be extended in extension: GoogleGenAIPromptingToolsExt. `ggi` stands for GoogleGenAI


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/llm_google.jl#L64)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.has_julia_prompt-Tuple{T} where T<:AbstractString' href='#PromptingTools.has_julia_prompt-Tuple{T} where T<:AbstractString'>#</a>&nbsp;<b><u>PromptingTools.has_julia_prompt</u></b> &mdash; <i>Method</i>.




Checks if a given string has a Julia prompt (`julia>`) at the beginning of a line.


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/code_parsing.jl#L92)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.length_longest_common_subsequence-Tuple{Any, Any}' href='#PromptingTools.length_longest_common_subsequence-Tuple{Any, Any}'>#</a>&nbsp;<b><u>PromptingTools.length_longest_common_subsequence</u></b> &mdash; <i>Method</i>.




```julia
length_longest_common_subsequence(itr1, itr2)
```


Compute the length of the longest common subsequence between two sequences (ie, the higher the number, the better the match).

Source: https://cn.julialang.org/LeetCode.jl/dev/democards/problems/problems/1143.longest-common-subsequence/

**Arguments**
- `itr1`: The first sequence, eg, a String.
  
- `itr2`: The second sequence, eg, a String.
  

**Returns**

The length of the longest common subsequence.

**Examples**

```julia
text1 = "abc-abc----"
text2 = "___ab_c__abc"
longest_common_subsequence(text1, text2)
# Output: 6 (-> "abcabc")
```


It can be used to fuzzy match strings and find the similarity between them (Tip: normalize the match)

```julia
commands = ["product recommendation", "emotions", "specific product advice", "checkout advice"]
query = "Which product can you recommend for me?"
let pos = argmax(length_longest_common_subsequence.(Ref(query), commands))
    dist = length_longest_common_subsequence(query, commands[pos])
    norm = dist / min(length(query), length(commands[pos]))
    @info "The closest command to the query: "$(query)" is: "$(commands[pos])" (distance: $(dist), normalized: $(norm))"
end
```


You can also use it to find the closest context for some AI generated summary/story:

```julia
context = ["The enigmatic stranger vanished as swiftly as a wisp of smoke, leaving behind a trail of unanswered questions.",
    "Beneath the shimmering moonlight, the ocean whispered secrets only the stars could hear.",
    "The ancient tree stood as a silent guardian, its gnarled branches reaching for the heavens.",
    "The melody danced through the air, painting a vibrant tapestry of emotions.",
    "Time flowed like a relentless river, carrying away memories and leaving imprints in its wake."]

story = """
  Beneath the shimmering moonlight, the ocean whispered secrets only the stars could hear.

  Under the celestial tapestry, the vast ocean whispered its secrets to the indifferent stars. Each ripple, a murmured confidence, each wave, a whispered lament. The glittering celestial bodies listened in silent complicity, their enigmatic gaze reflecting the ocean's unspoken truths. The cosmic dance between the sea and the sky, a symphony of shared secrets, forever echoing in the ethereal expanse.
  """

let pos = argmax(length_longest_common_subsequence.(Ref(story), context))
    dist = length_longest_common_subsequence(story, context[pos])
    norm = dist / min(length(story), length(context[pos]))
    @info "The closest context to the query: "$(first(story,20))..." is: "$(context[pos])" (distance: $(dist), normalized: $(norm))"
end
```



[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/utils.jl#L170-L224)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.list_aliases-Tuple{}' href='#PromptingTools.list_aliases-Tuple{}'>#</a>&nbsp;<b><u>PromptingTools.list_aliases</u></b> &mdash; <i>Method</i>.




Shows the Dictionary of model aliases in the registry. Add more with `MODEL_ALIASES[alias] = model_name`.


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/user_preferences.jl#L572)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.list_registry-Tuple{}' href='#PromptingTools.list_registry-Tuple{}'>#</a>&nbsp;<b><u>PromptingTools.list_registry</u></b> &mdash; <i>Method</i>.




Shows the list of models in the registry. Add more with `register_model!`.


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/user_preferences.jl#L570)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.load_conversation-Tuple{Union{AbstractString, IO}}' href='#PromptingTools.load_conversation-Tuple{Union{AbstractString, IO}}'>#</a>&nbsp;<b><u>PromptingTools.load_conversation</u></b> &mdash; <i>Method</i>.




Loads a conversation (`messages`) from `io_or_file`


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/serialization.jl#L37)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.load_template-Tuple{Union{AbstractString, IO}}' href='#PromptingTools.load_template-Tuple{Union{AbstractString, IO}}'>#</a>&nbsp;<b><u>PromptingTools.load_template</u></b> &mdash; <i>Method</i>.




Loads messaging template from `io_or_file` and returns tuple of template messages and metadata.


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/serialization.jl#L16)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.load_templates!' href='#PromptingTools.load_templates!'>#</a>&nbsp;<b><u>PromptingTools.load_templates!</u></b> &mdash; <i>Function</i>.




```julia
load_templates!(dir_templates::Union{String, Nothing} = nothing;
    remember_path::Bool = true,
    remove_templates::Bool = isnothing(dir_templates),
    store::Dict{Symbol, <:Any} = TEMPLATE_STORE,
    metadata_store::Vector{<:AITemplateMetadata} = TEMPLATE_METADATA)
```


Loads templates from folder `templates/` in the package root and stores them in `TEMPLATE_STORE` and `TEMPLATE_METADATA`.

Note: Automatically removes any existing templates and metadata from `TEMPLATE_STORE` and `TEMPLATE_METADATA` if `remove_templates=true`.

**Arguments**
- `dir_templates::Union{String, Nothing}`: The directory path to load templates from. If `nothing`, uses the default list of paths. It usually used only once "to register" a new template storage.
  
- `remember_path::Bool=true`: If true, remembers the path for future refresh (in `TEMPLATE_PATH`).
  
- `remove_templates::Bool=isnothing(dir_templates)`: If true, removes any existing templates and metadata from `store` and `metadata_store`.
  
- `store::Dict{Symbol, <:Any}=TEMPLATE_STORE`: The store to load the templates into.
  
- `metadata_store::Vector{<:AITemplateMetadata}=TEMPLATE_METADATA`: The metadata store to load the metadata into.
  

**Example**

Load the default templates:

```julia
PT.load_templates!() # no path needed
```


Load templates from a new custom path:

```julia
PT.load_templates!("path/to/templates") # we will remember this path for future refresh
```


If you want to now refresh the default templates and the new path, just call `load_templates!()` without any arguments.


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/templates.jl#L179-L210)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.ollama_api' href='#PromptingTools.ollama_api'>#</a>&nbsp;<b><u>PromptingTools.ollama_api</u></b> &mdash; <i>Function</i>.




```julia
ollama_api(prompt_schema::Union{AbstractOllamaManagedSchema, AbstractOllamaSchema},
    prompt::Union{AbstractString, Nothing} = nothing;
    system::Union{Nothing, AbstractString} = nothing,
    messages::Vector{<:AbstractMessage} = AbstractMessage[],
    endpoint::String = "generate",
    model::String = "llama2", http_kwargs::NamedTuple = NamedTuple(),
    stream::Bool = false,
    url::String = "localhost", port::Int = 11434,
    kwargs...)
```


Simple wrapper for a call to Ollama API.

**Keyword Arguments**
- `prompt_schema`: Defines which prompt template should be applied.
  
- `prompt`: Can be a string representing the prompt for the AI conversation, a `UserMessage`, a vector of `AbstractMessage`
  
- `system`: An optional string representing the system message for the AI conversation. If not provided, a default message will be used.
  
- `endpoint`: The API endpoint to call, only "generate" and "embeddings" are currently supported. Defaults to "generate".
  
- `model`: A string representing the model to use for generating the response. Can be an alias corresponding to a model ID defined in `MODEL_ALIASES`.
  
- `http_kwargs::NamedTuple`: Additional keyword arguments for the HTTP request. Defaults to empty `NamedTuple`.
  
- `stream`: A boolean indicating whether to stream the response. Defaults to `false`.
  
- `url`: The URL of the Ollama API. Defaults to "localhost".
  
- `port`: The port of the Ollama API. Defaults to 11434.
  
- `kwargs`: Prompt variables to be used to fill the prompt/template
  


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/llm_ollama_managed.jl#L57-L81)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.preview' href='#PromptingTools.preview'>#</a>&nbsp;<b><u>PromptingTools.preview</u></b> &mdash; <i>Function</i>.




Utility for rendering the conversation (vector of messages) as markdown. REQUIRES the Markdown package to load the extension!


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/utils.jl#L479)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.push_conversation!-Tuple{Vector{<:Vector}, AbstractVector, Union{Nothing, Int64}}' href='#PromptingTools.push_conversation!-Tuple{Vector{<:Vector}, AbstractVector, Union{Nothing, Int64}}'>#</a>&nbsp;<b><u>PromptingTools.push_conversation!</u></b> &mdash; <i>Method</i>.




```julia
push_conversation!(conv_history, conversation::AbstractVector, max_history::Union{Int, Nothing})
```


Add a new conversation to the conversation history and resize the history if necessary.

This function appends a conversation to the `conv_history`, which is a vector of conversations. Each conversation is represented as a vector of `AbstractMessage` objects. After adding the new conversation, the history is resized according to the `max_history` parameter to ensure that the size of the history does not exceed the specified limit.

**Arguments**
- `conv_history`: A vector that stores the history of conversations. Typically, this is `PT.CONV_HISTORY`.
  
- `conversation`: The new conversation to be added. It should be a vector of `AbstractMessage` objects.
  
- `max_history`: The maximum number of conversations to retain in the history. If `Nothing`, the history is not resized.
  

**Returns**

The updated conversation history.

**Example**

```julia
new_conversation = aigenerate("Hello World"; return_all = true)
push_conversation!(PT.CONV_HISTORY, new_conversation, 10)
```


This is done automatically by the ai"" macros.


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/utils.jl#L382-L404)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.register_model!' href='#PromptingTools.register_model!'>#</a>&nbsp;<b><u>PromptingTools.register_model!</u></b> &mdash; <i>Function</i>.




```julia
register_model!(registry = MODEL_REGISTRY;
    name::String,
    schema::Union{AbstractPromptSchema, Nothing} = nothing,
    cost_of_token_prompt::Float64 = 0.0,
    cost_of_token_generation::Float64 = 0.0,
    description::String = "")
```


Register a new AI model with `name` and its associated `schema`. 

Registering a model helps with calculating the costs and automatically selecting the right prompt schema.

**Arguments**
- `name`: The name of the model. This is the name that will be used to refer to the model in the `ai*` functions.
  
- `schema`: The schema of the model. This is the schema that will be used to generate prompts for the model, eg, `OpenAISchema()`.
  
- `cost_of_token_prompt`: The cost of a token in the prompt for this model. This is used to calculate the cost of a prompt.   Note: It is often provided online as cost per 1000 tokens, so make sure to convert it correctly!
  
- `cost_of_token_generation`: The cost of a token generated by this model. This is used to calculate the cost of a generation.   Note: It is often provided online as cost per 1000 tokens, so make sure to convert it correctly!
  
- `description`: A description of the model. This is used to provide more information about the model when it is queried.
  


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/user_preferences.jl#L235-L255)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.remove_julia_prompt-Tuple{T} where T<:AbstractString' href='#PromptingTools.remove_julia_prompt-Tuple{T} where T<:AbstractString'>#</a>&nbsp;<b><u>PromptingTools.remove_julia_prompt</u></b> &mdash; <i>Method</i>.




```julia
remove_julia_prompt(s::T) where {T<:AbstractString}
```


If it detects a julia prompt, it removes it and all lines that do not have it (except for those that belong to the code block).


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/code_parsing.jl#L95-L99)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.remove_templates!-Tuple{}' href='#PromptingTools.remove_templates!-Tuple{}'>#</a>&nbsp;<b><u>PromptingTools.remove_templates!</u></b> &mdash; <i>Method</i>.




```julia
    remove_templates!()
```


Removes all templates from `TEMPLATE_STORE` and `TEMPLATE_METADATA`.


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/templates.jl#L172-L176)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.remove_unsafe_lines-Tuple{AbstractString}' href='#PromptingTools.remove_unsafe_lines-Tuple{AbstractString}'>#</a>&nbsp;<b><u>PromptingTools.remove_unsafe_lines</u></b> &mdash; <i>Method</i>.




Iterates over the lines of a string and removes those that contain a package operation or a missing import.


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/code_parsing.jl#L77)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.render-Tuple{AITemplate}' href='#PromptingTools.render-Tuple{AITemplate}'>#</a>&nbsp;<b><u>PromptingTools.render</u></b> &mdash; <i>Method</i>.




Renders provided messaging template (`template`) under the default schema (`PROMPT_SCHEMA`).


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/templates.jl#L110)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.render-Tuple{PromptingTools.AbstractGoogleSchema, Vector{<:PromptingTools.AbstractMessage}}' href='#PromptingTools.render-Tuple{PromptingTools.AbstractGoogleSchema, Vector{<:PromptingTools.AbstractMessage}}'>#</a>&nbsp;<b><u>PromptingTools.render</u></b> &mdash; <i>Method</i>.




```julia
render(schema::AbstractGoogleSchema,
    messages::Vector{<:AbstractMessage};
    conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
    kwargs...)
```


Builds a history of the conversation to provide the prompt to the API. All unspecified kwargs are passed as replacements such that `{{key}}=>value` in the template.

**Keyword Arguments**
- `conversation`: An optional vector of `AbstractMessage` objects representing the conversation history. If not provided, it is initialized as an empty vector.
  


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/llm_google.jl#L2-L13)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.render-Tuple{PromptingTools.AbstractOllamaManagedSchema, Vector{<:PromptingTools.AbstractMessage}}' href='#PromptingTools.render-Tuple{PromptingTools.AbstractOllamaManagedSchema, Vector{<:PromptingTools.AbstractMessage}}'>#</a>&nbsp;<b><u>PromptingTools.render</u></b> &mdash; <i>Method</i>.




```julia
render(schema::AbstractOllamaManagedSchema,
    messages::Vector{<:AbstractMessage};
    conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
    kwargs...)
```


Builds a history of the conversation to provide the prompt to the API. All unspecified kwargs are passed as replacements such that `{{key}}=>value` in the template.

Note: Due to its "managed" nature, at most 2 messages can be provided (`system` and `prompt` inputs in the API).

**Keyword Arguments**
- `conversation`: Not allowed for this schema. Provided only for compatibility.
  


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/llm_ollama_managed.jl#L9-L21)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.render-Tuple{PromptingTools.AbstractOllamaSchema, Vector{<:PromptingTools.AbstractMessage}}' href='#PromptingTools.render-Tuple{PromptingTools.AbstractOllamaSchema, Vector{<:PromptingTools.AbstractMessage}}'>#</a>&nbsp;<b><u>PromptingTools.render</u></b> &mdash; <i>Method</i>.




```julia
render(schema::AbstractOllamaSchema,
    messages::Vector{<:AbstractMessage};
    conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
    kwargs...)
```


Builds a history of the conversation to provide the prompt to the API. All unspecified kwargs are passed as replacements such that `{{key}}=>value` in the template.

**Keyword Arguments**
- `conversation`: An optional vector of `AbstractMessage` objects representing the conversation history. If not provided, it is initialized as an empty vector.
  


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/llm_ollama.jl#L10-L21)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.render-Tuple{PromptingTools.AbstractOpenAISchema, Vector{<:PromptingTools.AbstractMessage}}' href='#PromptingTools.render-Tuple{PromptingTools.AbstractOpenAISchema, Vector{<:PromptingTools.AbstractMessage}}'>#</a>&nbsp;<b><u>PromptingTools.render</u></b> &mdash; <i>Method</i>.




```julia
render(schema::AbstractOpenAISchema,
    messages::Vector{<:AbstractMessage};
    image_detail::AbstractString = "auto",
    conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
    kwargs...)
```


Builds a history of the conversation to provide the prompt to the API. All unspecified kwargs are passed as replacements such that `{{key}}=>value` in the template.

**Keyword Arguments**
- `image_detail`: Only for `UserMessageWithImages`. It represents the level of detail to include for images. Can be `"auto"`, `"high"`, or `"low"`.
  
- `conversation`: An optional vector of `AbstractMessage` objects representing the conversation history. If not provided, it is initialized as an empty vector.
  


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/llm_openai.jl#L2-L15)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.render-Tuple{PromptingTools.NoSchema, Vector{<:PromptingTools.AbstractMessage}}' href='#PromptingTools.render-Tuple{PromptingTools.NoSchema, Vector{<:PromptingTools.AbstractMessage}}'>#</a>&nbsp;<b><u>PromptingTools.render</u></b> &mdash; <i>Method</i>.




```julia
render(schema::NoSchema,
    messages::Vector{<:AbstractMessage};
    conversation::AbstractVector{<:AbstractMessage} = AbstractMessage[],
    replacement_kwargs...)
```


Renders a conversation history from a vector of messages with all replacement variables specified in `replacement_kwargs`.

It is the first pass of the prompt rendering system, and is used by all other schemas.

**Keyword Arguments**
- `image_detail`: Only for `UserMessageWithImages`. It represents the level of detail to include for images. Can be `"auto"`, `"high"`, or `"low"`.
  
- `conversation`: An optional vector of `AbstractMessage` objects representing the conversation history. If not provided, it is initialized as an empty vector.
  

**Notes**
- All unspecified kwargs are passed as replacements such that `{{key}}=>value` in the template.
  
- If a SystemMessage is missing, we inject a default one at the beginning of the conversation.
  
- Only one SystemMessage is allowed (ie, cannot mix two conversations different system prompts).
  


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/llm_shared.jl#L2-L20)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.replace_words-Tuple{AbstractString, Vector{<:AbstractString}}' href='#PromptingTools.replace_words-Tuple{AbstractString, Vector{<:AbstractString}}'>#</a>&nbsp;<b><u>PromptingTools.replace_words</u></b> &mdash; <i>Method</i>.




```julia
replace_words(text::AbstractString, words::Vector{<:AbstractString}; replacement::AbstractString="ABC")
```


Replace all occurrences of words in `words` with `replacement` in `text`. Useful to quickly remove specific names or entities from a text.

**Arguments**
- `text::AbstractString`: The text to be processed.
  
- `words::Vector{<:AbstractString}`: A vector of words to be replaced.
  
- `replacement::AbstractString="ABC"`: The replacement string to be used. Defaults to "ABC".
  

**Example**

```julia
text = "Disney is a great company"
replace_words(text, ["Disney", "Snow White", "Mickey Mouse"])
# Output: "ABC is a great company"
```



[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/utils.jl#L3-L19)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.resize_conversation!-Tuple{Any, Union{Nothing, Int64}}' href='#PromptingTools.resize_conversation!-Tuple{Any, Union{Nothing, Int64}}'>#</a>&nbsp;<b><u>PromptingTools.resize_conversation!</u></b> &mdash; <i>Method</i>.




```julia
resize_conversation!(conv_history, max_history::Union{Int, Nothing})
```


Resize the conversation history to a specified maximum length.

This function trims the `conv_history` to ensure that its size does not exceed `max_history`. It removes the oldest conversations first if the length of `conv_history` is greater than `max_history`.

**Arguments**
- `conv_history`: A vector that stores the history of conversations. Typically, this is `PT.CONV_HISTORY`.
  
- `max_history`: The maximum number of conversations to retain in the history. If `Nothing`, the history is not resized.
  

**Returns**

The resized conversation history.

**Example**

```julia
resize_conversation!(PT.CONV_HISTORY, PT.MAX_HISTORY_LENGTH)
```


After the function call, `conv_history` will contain only the 10 most recent conversations.

This is done automatically by the ai"" macros.


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/utils.jl#L413-L436)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.response_to_message-Tuple{PromptingTools.AbstractOpenAISchema, Type{AIMessage}, Any, Any}' href='#PromptingTools.response_to_message-Tuple{PromptingTools.AbstractOpenAISchema, Type{AIMessage}, Any, Any}'>#</a>&nbsp;<b><u>PromptingTools.response_to_message</u></b> &mdash; <i>Method</i>.




```julia
response_to_message(schema::AbstractOpenAISchema,
    MSG::Type{AIMessage},
    choice,
    resp;
    model_id::AbstractString = "",
    time::Float64 = 0.0,
    run_id::Integer = rand(Int16),
    sample_id::Union{Nothing, Integer} = nothing)
```


Utility to facilitate unwrapping of HTTP response to a message type `MSG` provided for OpenAI-like responses

Note: Extracts `finish_reason` and `log_prob` if available in the response.

**Arguments**
- `schema::AbstractOpenAISchema`: The schema for the prompt.
  
- `MSG::Type{AIMessage}`: The message type to be returned.
  
- `choice`: The choice from the response (eg, one of the completions).
  
- `resp`: The response from the OpenAI API.
  
- `model_id::AbstractString`: The model ID to use for generating the response. Defaults to an empty string.
  
- `time::Float64`: The elapsed time for the response. Defaults to `0.0`.
  
- `run_id::Integer`: The run ID for the response. Defaults to a random integer.
  
- `sample_id::Union{Nothing, Integer}`: The sample ID for the response (if there are multiple completions). Defaults to `nothing`.
  


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/llm_openai.jl#L344-L367)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.response_to_message-Union{Tuple{T}, Tuple{PromptingTools.AbstractPromptSchema, Type{T}, Any, Any}} where T' href='#PromptingTools.response_to_message-Union{Tuple{T}, Tuple{PromptingTools.AbstractPromptSchema, Type{T}, Any, Any}} where T'>#</a>&nbsp;<b><u>PromptingTools.response_to_message</u></b> &mdash; <i>Method</i>.




Utility to facilitate unwrapping of HTTP response to a message type `MSG` provided. Designed to handle multi-sample completions.


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/llm_interface.jl#L288)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.save_conversation-Tuple{Union{AbstractString, IO}, AbstractVector{<:PromptingTools.AbstractMessage}}' href='#PromptingTools.save_conversation-Tuple{Union{AbstractString, IO}, AbstractVector{<:PromptingTools.AbstractMessage}}'>#</a>&nbsp;<b><u>PromptingTools.save_conversation</u></b> &mdash; <i>Method</i>.




Saves provided conversation (`messages`) to `io_or_file`. If you need to add some metadata, see `save_template`.


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/serialization.jl#L32)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.save_template-Tuple{Union{AbstractString, IO}, AbstractVector{<:PromptingTools.AbstractChatMessage}}' href='#PromptingTools.save_template-Tuple{Union{AbstractString, IO}, AbstractVector{<:PromptingTools.AbstractChatMessage}}'>#</a>&nbsp;<b><u>PromptingTools.save_template</u></b> &mdash; <i>Method</i>.




Saves provided messaging template (`messages`) to `io_or_file`. Automatically adds metadata based on provided keyword arguments.


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/serialization.jl#L2)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.set_preferences!-Tuple{Vararg{Pair{String}}}' href='#PromptingTools.set_preferences!-Tuple{Vararg{Pair{String}}}'>#</a>&nbsp;<b><u>PromptingTools.set_preferences!</u></b> &mdash; <i>Method</i>.




```julia
set_preferences!(pairs::Pair{String, <:Any}...)
```


Set preferences for PromptingTools. See `?PREFERENCES` for more information. 

See also: `get_preferences`

**Example**

Change your API key and default model:

```julia
PromptingTools.set_preferences!("OPENAI_API_KEY" => "key1", "MODEL_CHAT" => "chat1")
```



[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/user_preferences.jl#L66-L79)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.split_by_length-Tuple{Any, Vector{String}}' href='#PromptingTools.split_by_length-Tuple{Any, Vector{String}}'>#</a>&nbsp;<b><u>PromptingTools.split_by_length</u></b> &mdash; <i>Method</i>.




```julia
split_by_length(text::String, separators::Vector{String}; max_length::Int=35000) -> Vector{String}
```


Split a given string `text` into chunks using a series of separators, with each chunk having a maximum length of `max_length`.  This function is useful for splitting large documents or texts into smaller segments that are more manageable for processing, particularly for models or systems with limited context windows.

**Arguments**
- `text::String`: The text to be split.
  
- `separators::Vector{String}`: An ordered list of separators used to split the text. The function iteratively applies these separators to split the text.
  
- `max_length::Int=35000`: The maximum length of each chunk. Defaults to 35,000 characters. This length is considered after each iteration of splitting, ensuring chunks fit within specified constraints.
  

**Returns**

`Vector{String}`: A vector of strings, where each string is a chunk of the original text that is smaller than or equal to `max_length`.

**Notes**
- The function processes the text iteratively with each separator in the provided order. This ensures more nuanced splitting, especially in structured texts.
  
- Each chunk is as close to `max_length` as possible without exceeding it (unless we cannot split it any further)
  
- If the `text` is empty, the function returns an empty array.
  
- Separators are re-added to the text chunks after splitting, preserving the original structure of the text as closely as possible. Apply `strip` if you do not need them.
  

**Examples**

Splitting text using multiple separators:

```julia
text = "Paragraph 1

Paragraph 2. Sentence 1. Sentence 2.
Paragraph 3"
separators = ["

", ". ", "
"]
chunks = split_by_length(text, separators, max_length=20)
```


Using a single separator:

```julia
text = "Hello,World," ^ 2900  # length 34900 characters
chunks = split_by_length(text, [","], max_length=10000)
```



[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/utils.jl#L117-L158)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.split_by_length-Tuple{String}' href='#PromptingTools.split_by_length-Tuple{String}'>#</a>&nbsp;<b><u>PromptingTools.split_by_length</u></b> &mdash; <i>Method</i>.




```julia
split_by_length(text::String; separator::String=" ", max_length::Int=35000) -> Vector{String}
```


Split a given string `text` into chunks of a specified maximum length `max_length`.  This is particularly useful for splitting larger documents or texts into smaller segments, suitable for models or systems with smaller context windows.

**Arguments**
- `text::String`: The text to be split.
  
- `separator::String=" "`: The separator used to split the text into minichunks. Defaults to a space character.
  
- `max_length::Int=35000`: The maximum length of each chunk. Defaults to 35,000 characters, which should fit within 16K context window.
  

**Returns**

`Vector{String}`: A vector of strings, each representing a chunk of the original text that is smaller than or equal to `max_length`.

**Notes**
- The function ensures that each chunk is as close to `max_length` as possible without exceeding it.
  
- If the `text` is empty, the function returns an empty array.
  
- The `separator` is re-added to the text chunks after splitting, preserving the original structure of the text as closely as possible.
  

**Examples**

Splitting text with the default separator (" "):

```julia
text = "Hello world. How are you?"
chunks = split_by_length(text; max_length=13)
length(chunks) # Output: 2
```


Using a custom separator and custom `max_length`

```julia
text = "Hello,World," ^ 2900 # length 34900 chars
split_by_length(text; separator=",", max_length=10000) # for 4K context window
length(chunks[1]) # Output: 4
```



[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/utils.jl#L34-L69)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.@aai_str-Tuple{Any, Vararg{Any}}' href='#PromptingTools.@aai_str-Tuple{Any, Vararg{Any}}'>#</a>&nbsp;<b><u>PromptingTools.@aai_str</u></b> &mdash; <i>Macro</i>.




```julia
aai"user_prompt"[model_alias] -> AIMessage
```


Asynchronous version of `@ai_str` macro, which will log the result once it's ready.

See also `aai!""` if you want an asynchronous reply to the provided message / continue the conversation.    

**Example**

Send asynchronous request to GPT-4, so we don't have to wait for the response: Very practical with slow models, so you can keep working in the meantime.

```julia m = aai"Say Hi!"gpt4; 

**...with some delay...**

**[ Info: Tokens: 29 @ Cost: 0.0011
 in 2.7 seconds**

**[ Info: AIMessage> Hello! How can I assist you today?**


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/macros.jl#L99-L116)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.@ai!_str-Tuple{Any, Vararg{Any}}' href='#PromptingTools.@ai!_str-Tuple{Any, Vararg{Any}}'>#</a>&nbsp;<b><u>PromptingTools.@ai!_str</u></b> &mdash; <i>Macro</i>.




```julia
ai!"user_prompt"[model_alias] -> AIMessage
```


The `ai!""` string macro is used to continue a previous conversation with the AI model. 

It appends the new user prompt to the last conversation in the tracked history (in `PromptingTools.CONV_HISTORY`) and generates a response based on the entire conversation context. If you want to see the previous conversation, you can access it via `PromptingTools.CONV_HISTORY`, which keeps at most last `PromptingTools.MAX_HISTORY_LENGTH` conversations.

**Arguments**
- `user_prompt` (String): The new input prompt to be added to the existing conversation.
  
- `model_alias` (optional, any): Specify the model alias of the AI model to be used (see `MODEL_ALIASES`). If not provided, the default model is used.
  

**Returns**

`AIMessage` corresponding to the new user prompt, considering the entire conversation history.

**Example**

To continue a conversation:

```julia
# start conversation as normal
ai"Say hi." 

# ... wait for reply and then react to it:

# continue the conversation (notice that you can change the model, eg, to more powerful one for better answer)
ai!"What do you think about that?"gpt4t
# AIMessage("Considering our previous discussion, I think that...")
```


**Usage Notes**
- This macro should be used when you want to maintain the context of an ongoing conversation (ie, the last `ai""` message).
  
- It automatically accesses and updates the global conversation history.
  
- If no conversation history is found, it raises an assertion error, suggesting to initiate a new conversation using `ai""` instead.
  

**Important**

Ensure that the conversation history is not too long to maintain relevancy and coherence in the AI's responses. The history length is managed by `MAX_HISTORY_LENGTH`.


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/macros.jl#L45-L80)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.@ai_str-Tuple{Any, Vararg{Any}}' href='#PromptingTools.@ai_str-Tuple{Any, Vararg{Any}}'>#</a>&nbsp;<b><u>PromptingTools.@ai_str</u></b> &mdash; <i>Macro</i>.




```julia
ai"user_prompt"[model_alias] -> AIMessage
```


The `ai""` string macro generates an AI response to a given prompt by using `aigenerate` under the hood.

See also `ai!""` if you want to reply to the provided message / continue the conversation.

**Arguments**
- `user_prompt` (String): The input prompt for the AI model.
  
- `model_alias` (optional, any): Provide model alias of the AI model (see `MODEL_ALIASES`).
  

**Returns**

`AIMessage` corresponding to the input prompt.

**Example**

```julia
result = ai"Hello, how are you?"
# AIMessage("Hello! I'm an AI assistant, so I don't have feelings, but I'm here to help you. How can I assist you today?")
```


If you want to interpolate some variables or additional context, simply use string interpolation:

```julia
a=1
result = ai"What is `$a+$a`?"
# AIMessage("The sum of `1+1` is `2`.")
```


If you want to use a different model, eg, GPT-4, you can provide its alias as a flag:

```julia
result = ai"What is `1.23 * 100 + 1`?"gpt4t
# AIMessage("The answer is 124.")
```



[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/macros.jl#L1-L33)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.@timeout-Tuple{Any, Any, Any}' href='#PromptingTools.@timeout-Tuple{Any, Any, Any}'>#</a>&nbsp;<b><u>PromptingTools.@timeout</u></b> &mdash; <i>Macro</i>.




```julia
@timeout(seconds, expr_to_run, expr_when_fails)
```


Simple macro to run an expression with a timeout of `seconds`. If the `expr_to_run` fails to finish in `seconds` seconds, `expr_when_fails` is returned.

**Example**

```julia
x = @timeout 1 begin
    sleep(1.1)
    println("done")
    1
end "failed"

```



[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/utils.jl#L449-L463)

</div>
<br>
