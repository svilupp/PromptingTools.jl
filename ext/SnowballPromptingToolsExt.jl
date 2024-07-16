module SnowballPromptingToolsExt

using PromptingTools
const PT = PromptingTools

using PromptingTools.Experimental.RAGTools
const RT = PromptingTools.Experimental.RAGTools

using Snowball

# forward to Stemmer.stem
RT._stem(stemmer::Snowball.Stemmer, text::AbstractString) = Snowball.stem(stemmer, text)

"""
    get_keywords(processor::KeywordsProcessor, docs::AbstractVector{<:AbstractString};
        verbose::Bool = true,
        stemmer = nothing,
        stopwords::Set{String} = Set(STOPWORDS),
        return_keywords::Bool = false,
        min_length::Integer = 3,
        kwargs...)

Generate a `DocumentTermMatrix` from a vector of `docs` using the provided `stemmer` and `stopwords`.

# Arguments
- `docs`: A vector of strings to be embedded.
- `verbose`: A boolean flag for verbose output. Default is `true`.
- `stemmer`: A stemmer to use for stemming. Default is `nothing`.
- `stopwords`: A set of stopwords to remove. Default is `Set(STOPWORDS)`.
- `return_keywords`: A boolean flag for returning the keywords. Default is `false`. Useful for query processing in search time.
- `min_length`: The minimum length of the keywords. Default is `3`.
"""
function RT.get_keywords(
        processor::RT.KeywordsProcessor, docs::AbstractVector{<:AbstractString};
        verbose::Bool = true,
        stemmer = nothing,
        stopwords::Set{String} = Set(RT.STOPWORDS),
        return_keywords::Bool = false,
        min_length::Integer = 3,
        kwargs...)
    ## check if extension is available
    ext = Base.get_extension(PromptingTools, :RAGToolsExperimentalExt)
    if isnothing(ext)
        error("You need to also import LinearAlgebra and SparseArrays to use this function")
    end
    ## ext = Base.get_extension(PromptingTools, :SnowballPromptingToolsExt)
    ## if isnothing(ext)
    ##     error("You need to also import Snowball.jl to use this function")
    ## end
    ## Preprocess text into tokens
    stemmer = !isnothing(stemmer) ? stemmer : Snowball.Stemmer("english")
    # Single-threaded as stemmer is not thread-safe
    keywords = RT.preprocess_tokens(docs, stemmer; stopwords, min_length)

    ## Early exit if we only want keywords (search time)
    return_keywords && return keywords

    ## Create DTM
    dtm = RT.document_term_matrix(keywords)

    verbose && @info "Done processing DocumentTermMatrix."
    return dtm
end

end # end of module
