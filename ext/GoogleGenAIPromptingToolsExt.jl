module GoogleGenAIPromptingToolsExt

using GoogleGenAI
using PromptingTools
using HTTP, JSON3
const PT = PromptingTools

"Wrapper for GoogleGenAI.generate_content with new interface."
function PromptingTools.ggi_generate_content(prompt_schema::PT.AbstractGoogleSchema,
        api_key::AbstractString, model_name::AbstractString,
        conversation; system_instruction = nothing, http_kwargs = NamedTuple(),
        api_kwargs = NamedTuple(), kwargs...)
    config_kwargs = PT.process_google_config(api_kwargs, system_instruction, http_kwargs)

    config = GoogleGenAI.GenerateContentConfig(; config_kwargs...)

    try
        r = GoogleGenAI.generate_content(
            api_key, model_name, conversation; config = config)

        return r
    catch e
        @error "Error in generate_content:" e
        rethrow(e)
    end
end

end # end of module
