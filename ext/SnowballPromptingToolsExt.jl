module SnowballPromptingToolsExt

using PromptingTools
const PT = PromptingTools

using PromptingTools.Experimental.RAGTools
const RT = PromptingTools.Experimental.RAGTools

using Snowball

# forward to Stemmer.stem
RT._stem(stemmer::Snowball.Stemmer, text::AbstractString) = Snowball.stem(stemmer, text)
end # end of module
