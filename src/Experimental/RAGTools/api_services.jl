"""
    cohere_api(;
    api_key::AbstractString,
    endpoint::String,
    url::AbstractString="https://api.cohere.ai/v1",
    http_kwargs::NamedTuple=NamedTuple(),
    kwargs...)

Lightweight wrapper around the Cohere API. See https://cohere.com/docs for more details.

# Arguments
- `api_key`: Your Cohere API key. You can get one from https://dashboard.cohere.com/welcome/register (trial access is for free).
- `endpoint`: The Cohere endpoint to call. 
- `url`: The base URL for the Cohere API. Default is `https://api.cohere.ai/v1`.
- `http_kwargs`: Any additional keyword arguments to pass to `HTTP.post`.
- `kwargs`: Any additional keyword arguments to pass to the Cohere API.
"""
function cohere_api(;
        api_key::AbstractString,
        endpoint::String,
        url::AbstractString = "https://api.cohere.ai/v1",
        http_kwargs::NamedTuple = NamedTuple(),
        kwargs...)
    @assert endpoint in ["chat", "generate", "embed", "rerank", "classify"] "Only 'chat', 'generate',`embed`,`rerank`,`classify` Cohere endpoints are supported."
    @assert !isempty(api_key) "Cohere `api_key` cannot be empty. Check `PT.COHERE_API_KEY` or pass it as a keyword argument."
    ##
    input_body = Dict(kwargs...)

    # https://api.cohere.ai/v1/rerank
    api_url = string(url, "/", endpoint)
    resp = HTTP.post(api_url,
        PT.auth_header(api_key),
        JSON3.write(input_body); http_kwargs...)
    body = JSON3.read(resp.body)
    return (; response = body)
end
