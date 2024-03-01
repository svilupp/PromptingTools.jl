
# Reference for APITools {#Reference-for-APITools}
- [`PromptingTools.Experimental.APITools.create_websearch`](#PromptingTools.Experimental.APITools.create_websearch-Tuple{AbstractString})
- [`PromptingTools.Experimental.APITools.tavily_api`](#PromptingTools.Experimental.APITools.tavily_api-Tuple{})

<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.APITools.create_websearch-Tuple{AbstractString}' href='#PromptingTools.Experimental.APITools.create_websearch-Tuple{AbstractString}'>#</a>&nbsp;<b><u>PromptingTools.Experimental.APITools.create_websearch</u></b> &mdash; <i>Method</i>.




```julia
create_websearch(query::AbstractString;
    api_key::AbstractString,
    search_depth::AbstractString = "basic")
```


**Arguments**
- `query::AbstractString`: The query to search for.
  
- `api_key::AbstractString`: The API key to use for the search. Get an API key from [Tavily](https://tavily.com).
  
- `search_depth::AbstractString`: The depth of the search. Can be either "basic" or "advanced". Default is "basic". Advanced search calls equal to 2 requests.
  
- `include_answer::Bool`: Whether to include the answer in the search results. Default is `false`.
  
- `include_raw_content::Bool`: Whether to include the raw content in the search results. Default is `false`.
  
- `max_results::Integer`: The maximum number of results to return. Default is 5.
  
- `include_images::Bool`: Whether to include images in the search results. Default is `false`.
  
- `include_domains::AbstractVector{<:AbstractString}`: A list of domains to include in the search results. Default is an empty list.
  
- `exclude_domains::AbstractVector{<:AbstractString}`: A list of domains to exclude from the search results. Default is an empty list.
  

**Example**

```julia
r = create_websearch("Who is King Charles?")
```


Even better, you can get not just the results but also the answer:

```julia
r = create_websearch("Who is King Charles?"; include_answer = true)
```


See [Rest API documentation](https://docs.tavily.com/docs/tavily-api/rest_api) for more information.


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/Experimental/APITools/tavily_api.jl#L31-L59)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.APITools.tavily_api-Tuple{}' href='#PromptingTools.Experimental.APITools.tavily_api-Tuple{}'>#</a>&nbsp;<b><u>PromptingTools.Experimental.APITools.tavily_api</u></b> &mdash; <i>Method</i>.




```julia
tavily_api(;
    api_key::AbstractString,
    endpoint::String = "search",
    url::AbstractString = "https://api.tavily.com",
    http_kwargs::NamedTuple = NamedTuple(),
    kwargs...)
```


Sends API requests to [Tavily](https://tavily.com) and returns the response.


[source](https://github.com/svilupp/PromptingTools.jl/blob/cb7a5e4eb1227f2511004e777084b7f8a6756bb6/src/Experimental/APITools/tavily_api.jl#L1-L10)

</div>
<br>
