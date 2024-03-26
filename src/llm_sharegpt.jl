### RENDERING
function sharegpt_role(::AbstractMessage)
    throw(ArgumentError("Unsupported message type $(typeof(msg))"))
end
sharegpt_role(::AIMessage) = "gpt"
sharegpt_role(::UserMessage) = "human"
sharegpt_role(::SystemMessage) = "system"

function render(::AbstractShareGPTSchema, conv::AbstractVector{<:PT.AbstractMessage})
    Dict("conversations" => [Dict("from" => sharegpt_role(msg), "value" => msg.content)
                             for msg in conv])
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
function aiscan(prompt_schema::AbstractShareGPTSchema, prompt::ALLOWED_PROMPT_TYPE;
        kwargs...)
    error("ShareGPT schema does not support aiscan. Please use OpenAISchema instead.")
end
function aiimage(prompt_schema::AbstractShareGPTSchema, prompt::ALLOWED_PROMPT_TYPE;
        kwargs...)
    error("ShareGPT schema does not support aiimage. Please use OpenAISchema instead.")
end
