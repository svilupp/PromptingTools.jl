"""
    tavily_api(;
        api_key::AbstractString,
        endpoint::String = "search",
        url::AbstractString = "https://api.tavily.com",
        http_kwargs::NamedTuple = NamedTuple(),
        kwargs...)

Sends API requests to [Tavily](https://tavily.com) and returns the response.
"""
function tavily_api(;
        api_key::AbstractString,
        endpoint::String = "search",
        url::AbstractString = "https://api.tavily.com",
        http_kwargs::NamedTuple = NamedTuple(),
        kwargs...)
    @assert !isempty(api_key) "Tavily `api_key` cannot be empty. Check `PT.TAVILY_API_KEY` or pass it as a keyword argument."

    ## api_key is sent in the POST body, not headers
    input_body = Dict("api_key" => api_key, kwargs...)

    # eg, https://api.tavily.com/search
    api_url = string(url, "/", endpoint)
    headers = PT.auth_header(nothing) # no API key provided
    resp = HTTP.post(api_url, headers,
        JSON3.write(input_body); http_kwargs...)
    body = JSON3.read(resp.body)
    return (; response = body, status = resp.status)
end

"""
    create_websearch(query::AbstractString;
        api_key::AbstractString,
        search_depth::AbstractString = "basic")

# Arguments
- `query::AbstractString`: The query to search for.
- `api_key::AbstractString`: The API key to use for the search. Get an API key from [Tavily](https://tavily.com).
- `search_depth::AbstractString`: The depth of the search. Can be either "basic" or "advanced". Default is "basic". Advanced search calls equal to 2 requests.
- `include_answer::Bool`: Whether to include the answer in the search results. Default is `false`.
- `include_raw_content::Bool`: Whether to include the raw content in the search results. Default is `false`.
- `max_results::Integer`: The maximum number of results to return. Default is 5.
- `include_images::Bool`: Whether to include images in the search results. Default is `false`.
- `include_domains::AbstractVector{<:AbstractString}`: A list of domains to include in the search results. Default is an empty list.
- `exclude_domains::AbstractVector{<:AbstractString}`: A list of domains to exclude from the search results. Default is an empty list.

# Example
```julia
r = create_websearch("Who is King Charles?")
```

Even better, you can get not just the results but also the answer:
```julia
r = create_websearch("Who is King Charles?"; include_answer = true)
```

See [Rest API documentation](https://docs.tavily.com/docs/tavily-api/rest_api) for more information.

"""
function create_websearch(query::AbstractString;
        api_key::AbstractString = PT.TAVILY_API_KEY,
        search_depth::AbstractString = "basic",
        include_answer::Bool = false,
        include_raw_content::Bool = false,
        max_results::Integer = 5,
        include_images::Bool = false,
        include_domains::AbstractVector{<:AbstractString} = String[],
        exclude_domains::AbstractVector{<:AbstractString} = String[])
    @assert search_depth in ["basic", "advanced"] "Search depth must be either 'basic' or 'advanced'"
    @assert max_results>0 "Max results must be a positive integer"

    tavily_api(; api_key, endpoint = "search",
        query,
        search_depth,
        include_answer,
        include_raw_content,
        max_results,
        include_images,
        include_domains,
        exclude_domains)
end
