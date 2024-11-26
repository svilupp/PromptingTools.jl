### RENDERING
role4render(::AbstractShareGPTSchema, ::AIMessage) = "gpt"
role4render(::AbstractShareGPTSchema, ::UserMessage) = "human"
role4render(::AbstractShareGPTSchema, ::SystemMessage) = "system"
function role4render(::AbstractShareGPTSchema, ::UserMessageWithImages)
    throw(ArgumentError("UserMessageWithImages is not supported in ShareGPT schema"))
end

function render(schema::AbstractShareGPTSchema, conv::AbstractVector{<:AbstractMessage})
    Dict("conversations" => [Dict("from" => role4render(schema, msg),
                                 "value" => msg.content)
                             for msg in conv if !isabstractannotationmessage(msg)])
end

### AI Functions
function aigenerate(prompt_schema::AbstractShareGPTSchema, prompt::ALLOWED_PROMPT_TYPE;
        kwargs...)
    error("ShareGPT schema does not support aigenerate. Please use OpenAISchema instead.")
end
function aiembed(prompt_schema::AbstractShareGPTSchema, prompt::ALLOWED_PROMPT_TYPE;
        kwargs...)
    error("ShareGPT schema does not support aiembed. Please use OpenAISchema instead.")
end
function aiclassify(prompt_schema::AbstractShareGPTSchema, prompt::ALLOWED_PROMPT_TYPE;
        kwargs...)
    error("ShareGPT schema does not support aiclassify. Please use OpenAISchema instead.")
end
function aiextract(prompt_schema::AbstractShareGPTSchema, prompt::ALLOWED_PROMPT_TYPE;
        kwargs...)
    error("ShareGPT schema does not support aiextract. Please use OpenAISchema instead.")
end
function aitools(prompt_schema::AbstractShareGPTSchema, prompt::ALLOWED_PROMPT_TYPE;
        kwargs...)
    error("ShareGPT schema does not support aitools. Please use OpenAISchema instead.")
end
function aiscan(prompt_schema::AbstractShareGPTSchema, prompt::ALLOWED_PROMPT_TYPE;
        kwargs...)
    error("ShareGPT schema does not support aiscan. Please use OpenAISchema instead.")
end
function aiimage(prompt_schema::AbstractShareGPTSchema, prompt::ALLOWED_PROMPT_TYPE;
        kwargs...)
    error("ShareGPT schema does not support aiimage. Please use OpenAISchema instead.")
end
