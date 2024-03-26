module GoogleGenAIPromptingToolsExt

using GoogleGenAI
using PromptingTools
using HTTP, JSON3
const PT = PromptingTools

"Wrapper for GoogleGenAI.generate_content."
function PromptingTools.ggi_generate_content(prompt_schema::PT.AbstractGoogleSchema,
        api_key::AbstractString, model_name::AbstractString,
        conversation; http_kwargs, api_kwargs...)
    r = GoogleGenAI.generate_content(
        api_key, model_name, conversation; api_kwargs, http_kwargs)
    return r
end

end # end of module
