module SnowballPromptingToolsExt

using PromptingTools
const PT = PromptingTools

using PromptingTools.Experimental.RAGTools
const RT = PromptingTools.Experimental.RAGTools

using Snowball

# forward to Stemmer.stem
RT._stem(stemmer::Snowball.Stemmer, text::AbstractString) = Snowball.stem(stemmer, text)

"""
    RT.get_keywords(
        processor::RT.KeywordsProcessor, docs::AbstractVector{<:AbstractString};
        verbose::Bool = true,
        stemmer = nothing,
        stopwords::Set{String} = Set(RT.STOPWORDS),
        return_keywords::Bool = false,
        min_length::Integer = 3,
        min_term_freq::Int = 1, max_terms::Int = typemax(Int),
        kwargs...)

Generate a `DocumentTermMatrix` from a vector of `docs` using the provided `stemmer` and `stopwords`.

# Arguments
- `docs`: A vector of strings to be embedded.
- `verbose`: A boolean flag for verbose output. Default is `true`.
- `stemmer`: A stemmer to use for stemming. Default is `nothing`.
- `stopwords`: A set of stopwords to remove. Default is `Set(STOPWORDS)`.
- `return_keywords`: A boolean flag for returning the keywords. Default is `false`. Useful for query processing in search time.
- `min_length`: The minimum length of the keywords. Default is `3`.
- `min_term_freq`: The minimum frequency a term must have to be included in the vocabulary, eg, `min_term_freq = 2` means only terms that appear at least twice will be included.
- `max_terms`: The maximum number of terms to include in the vocabulary, eg, `max_terms = 100` means only the 100 most frequent terms will be included.
"""
function RT.get_keywords(
        processor::RT.KeywordsProcessor, docs::AbstractVector{<:AbstractString};
        verbose::Bool = true,
        stemmer = nothing,
        stopwords::Set{String} = Set(RT.STOPWORDS),
        return_keywords::Bool = false,
        min_length::Integer = 3,
        min_term_freq::Int = 1, max_terms::Int = typemax(Int),
        kwargs...)
    ## check if extension is available
    ext = Base.get_extension(PromptingTools, :RAGToolsExperimentalExt)
    if isnothing(ext)
        error("You need to also import LinearAlgebra and SparseArrays to use this function")
    end
    ## Preprocess text into tokens
    stemmer = !isnothing(stemmer) ? stemmer : Snowball.Stemmer("english")
    # Single-threaded as stemmer is not thread-safe
    keywords = RT.preprocess_tokens(docs, stemmer; stopwords, min_length)

    ## Early exit if we only want keywords (search time)
    return_keywords && return keywords

    ## Create DTM
    dtm = RT.document_term_matrix(keywords; min_term_freq, max_terms)

    verbose && @info "Done processing DocumentTermMatrix."
    return dtm
end

end # end of module
