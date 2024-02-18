module GoogleGenAIPromptingToolsExt

using GoogleGenAI
using PromptingTools
using HTTP, JSON3
const PT = PromptingTools

"Wrapper for GoogleGenAI.generate_content."
function PromptingTools.ggi_generate_content(prompt_schema::PT.AbstractGoogleSchema,
        api_key::AbstractString, model_name::AbstractString,
        conversation; http_kwargs, api_kwargs...)
    ## Build the provider
    provider = GoogleGenAI.GoogleProvider(; api_key)
    url = "$(provider.base_url)/models/$model_name:generateContent?key=$(provider.api_key)"
    generation_config = Dict{String, Any}()
    for (key, value) in api_kwargs
        generation_config[string(key)] = value
    end

    body = Dict("contents" => conversation,
        "generationConfig" => generation_config)
    response = HTTP.post(url; headers = Dict("Content-Type" => "application/json"),
        body = JSON3.write(body), http_kwargs...)
    if response.status >= 200 && response.status < 300
        return GoogleGenAI._parse_response(response)
    else
        error("Request failed with status $(response.status): $(String(response.body))")
    end
end

end # end of module
