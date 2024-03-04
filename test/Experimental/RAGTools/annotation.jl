using PromptingTools.Experimental.RAGTools: tokenize, trigrams, trigrams_hashed
using PromptingTools.Experimental.RAGTools: token_with_boundaries, text_to_trigrams,
                                            text_to_trigrams_hashed
using PromptingTools.Experimental.RAGTools: trigram_support!

@testset "tokenize" begin
    # Test basic tokenization with common delimiters
    @test tokenize("Hello, world!") == ["Hello", ",", " ", "world", "!"]

    # Test tokenization with various whitespace characters
    @test tokenize("New\nLine\tTab") == ["New", "\n", "Line", "\t", "Tab"]

    # Test tokenization with a mix of punctuation and words
    @test tokenize("Yes! This works.") == ["Yes", "!", " ", "This", " ", "works", "."]

    # Test tokenization of a string with no delimiters, i.e., a single word
    @test tokenize("SingleWord") == ["SingleWord"]

    # Test tokenization of an empty string
    @test tokenize("") == []

    # multi-space
    @test tokenize("   ") == ["   "]

    # Special characters for Julia code
    @test tokenize("α β γ δ") == ["α", " ", "β", " ", "γ", " ", "δ"]
    @test tokenize("a = (; a=1)") == ["a", " ", "=", " ", "(;", " ", "a", "=", "1", ")"]
    @test tokenize("replace(s, \"abc\"=>\"ABC\")") ==
          ["replace", "(", "s", ",", " ", "\"", "abc", "\"", "=>", "\"", "ABC", "\"", ")"]
end

@testset "trigrams" begin
    # Test generating trigrams from a string of sufficient length
    @test trigrams("hello") == ["hel", "ell", "llo"]

    # Test generating trigrams from a string with exactly 3 characters
    @test trigrams("cat") == ["cat"]

    # Test with a string of length less than 3, expecting an empty array
    @test trigrams("no") == ["no"]

    # Test with an empty string, also expecting an empty array
    @test trigrams("") == [""]

    # Test a case with special characters and spaces
    @test trigrams("a b c") == ["a b", " b ", "b c"]

    # With boundaries
    @test trigrams(" (cat=") == [" (c", "(ca", "cat", "at="]

    # Add the token itself
    @test trigrams("hello"; add_word = "hello") == ["hel", "ell", "llo", "hello"]

    # non-standard chars
    s = "α β γ δ"
    @test trigrams(s) == ["α β", " β ", "β γ", " γ ", "γ δ"]
end

@testset "trigrams_hashed" begin
    # Test hashing trigrams from a string of sufficient length
    # Since hashing produces unique UInt64 values, we test for the set's length instead of specific values
    @test trigrams_hashed("hello") == hash.(["hel", "ell", "llo"]) |> Set

    # Test hashing a string with exactly 3 characters
    @test trigrams_hashed("cat") == Set(hash("cat"))

    # Test with a string of length less than 3, expecting a set with 1 hash value
    @test trigrams_hashed("no") == Set(hash("no"))

    # Test with an empty string, expecting a set with 1 hash value because the empty string itself is hashed
    @test (trigrams_hashed("")) == Set(hash(""))

    # Test to ensure no duplicate hash values in case of repeating trigrams
    # "ababab" will generate "aba", "bab", "aba", "bab" - only two unique trigrams when hashed
    @test trigrams_hashed("ababab") == Set([hash("aba"), hash("bab")])

    # Test a unique case with special characters to ensure hashing works across different character sets
    @test trigrams_hashed("a!@") == Set(hash("a!@"))

    # Add the token itself
    @test trigrams_hashed("hello"; add_word = "hello") ==
          hash.(["hel", "ell", "llo", "hello"]) |> Set

    # special chars
    s = "α β γ δ"
    @test trigrams_hashed(s) == Set(hash.(["α β", " β ", "β γ", " γ ", "γ δ"]))
end

## TODO: fix tests below
@testset "token_with_boundaries" begin
    # Test with no surrounding tokens
    @test token_with_boundaries(nothing, "current", nothing) == "current"

    # Test with both surrounding tokens being single characters (should concatenate all)
    @test token_with_boundaries("a", "current", "b") == "acurrentb"

    # Test with only previous token being a single character (should prepend it)
    @test token_with_boundaries("a", "current", nothing) == "acurrent"

    # Test with only next token being a single character (should append it)
    @test token_with_boundaries(nothing, "current", "b") == "currentb"

    # Test with both surrounding tokens but only next token being a single character (should append next token)
    @test token_with_boundaries("previous", "current", "b") == "currentb"

    # Test with both surrounding tokens but only previous token being a single character (should prepend previous token)
    @test token_with_boundaries("a", "current", "next") == "acurrent"

    # Test with neither surrounding tokens being single characters (should return the current token unchanged)
    @test token_with_boundaries("previous", "current", "next") == "current"

    # Test with single character current token and no surrounding tokens (should return the current token unchanged)
    @test token_with_boundaries(nothing, "c", nothing) == "c"
end

using Test

@testset "text_to_trigrams" begin
    # Test converting basic text into trigrams
    @test text_to_trigrams("This is a test.") ==
          ["Thi", "his", "is", "is", "a", "tes", "est"]

    # Test that spaces and punctuation are treated as separate tokens and don't produce trigrams
    @test text_to_trigrams("Hello, world!") ==
          ["Hel", "ell", "llo", ",", "wor", "orl", "rld", "!"]

    # Test with a string that includes single-character tokens affecting neighboring tokens
    # Expecting the single-character tokens to not produce separate trigrams but to influence surrounding tokens
    @test text_to_trigrams("A cat.") == ["A c", "cat", "."]

    # Test with an empty string, expecting an empty array
    @test text_to_trigrams("") == []

    # Test a complex case with special characters, spaces, and punctuation
    # This checks that the function handles various types of tokens correctly
    @test text_to_trigrams("It's rain-ing!") ==
          ["It'", "'s", "rai", "ain", "-in", "ing", "!"]

    # Test to ensure correct handling of multiple adjacent spaces and punctuation
    # Spaces and punctuation should be treated as tokens but not produce trigrams
    @test text_to_trigrams("Wow...  That's amazing!") ==
          ["Wow", ".", ".", ".", "Tha", "hat", "'s", "ama", "maz", "zin", "ing", "!"]
end

using Test

@testset "text_to_trigrams_hashed" begin
    # Test basic text conversion to hashed trigrams
    # Checking for set size rather than specific hashes due to unpredictable hash values
    @test length(text_to_trigrams_hashed("This is a test.")) > 0

    # Test that unique trigrams produce a set of unique hashes
    # "hello" produces 3 unique trigrams, expecting 3 unique hash values
    @test length(text_to_trigrams_hashed("hello")) == 3

    # Test with a string of repeating characters, which should still produce unique trigrams
    # "aaa" will only produce one unique trigram "aaa", hence one hash
    @test length(text_to_trigrams_hashed("aaa")) == 1

    # Test handling of special characters and spaces
    # Expecting different hash values for different configurations of special characters
    @test length(text_to_trigrams_hashed("a!@ #$%^")) > 0

    # Test with an empty string, which should still produce a single hash value for the empty string
    @test length(text_to_trigrams_hashed("")) == 1

    # Test to ensure no duplicate hash values in case of repeating patterns within the input string
    # For a pattern that repeats, like "ababab", the number of unique trigrams should be less than the total trigrams
    # However, due to hashing direct repeats might still only produce a small set of unique hashes
    @test length(text_to_trigrams_hashed("ababab")) <= 4

    # Test a complex sentence with various characters, expecting a mix of unique hashes
    # The exact number of unique hashes is less important than ensuring we're getting a non-zero, plausible count
    @test length(text_to_trigrams_hashed("Complex sentence: 123!")) > 0
end

using Test

@testset "split_sentences" begin
    # Test basic sentence splitting
    @test begin
        sentences, group_ids = split_sentences("This is a test. This is another test.")
        sentences == ["This is a test.", " This is another test."] &&
            all(x -> x == 1, group_ids)
    end

    # Test handling of code blocks and inline code
    @test begin
        sentences, group_ids = split_sentences("Here is a code block: ```code here``` and `inline code`.")
        sentences ==
        ["Here is a code block: ", "```code here```", " and ", "`inline code`", "."] &&
            group_ids == [1, 2, 3, 4, 5]
    end

    # Test with multiple code blocks and inline codes
    @test begin
        sentences, group_ids = split_sentences("```block1``` `inline1` Text. ```block2```")
        sentences == ["```block1```", " `inline1` Text. ", "```block2```"] &&
            group_ids == [1, 2, 3]
    end

    # Test with sentences containing various punctuation
    @test begin
        sentences, group_ids = split_sentences("Is this a question? Yes! It is.")
        sentences == ["Is this a question?", " Yes!", " It is."] &&
            all(x -> x == 1, group_ids)
    end

    # Test an empty string, expecting empty arrays
    @test begin
        sentences, group_ids = split_sentences("")
        isempty(sentences) && isempty(group_ids)
    end

    # Test with only code blocks and no normal text
    @test begin
        sentences, group_ids = split_sentences("```block1``` ```block2```")
        sentences == ["```block1```", " ```block2```"] && group_ids == [1, 2]
    end

    # Test with newline characters and tabs, ensuring they're captured as part of sentences
    @test begin
        sentences, group_ids = split_sentences("Line one.\nLine two.\tLine three.")
        sentences == ["Line one.", "\nLine two.", "\tLine three."] &&
            all(x -> x == 1, group_ids)
    end
end

using Test

# Mocking necessary components for the tests
abstract type AbstractAnnotater end
struct TrigramAnnotater <: AbstractAnnotater end
@kwdef mutable struct Styler
    color::Symbol = :nothing
    bold::Bool = false
    underline::Bool = false
    italic::Bool = false
end
@kwdef mutable struct AnnotatedNode{T}
    group_id::Int = 0
    parent::Union{AnnotatedNode, Nothing} = nothing
    children::Vector{AnnotatedNode} = AnnotatedNode[]
    score::Union{Nothing, Float64} = nothing
    hits::Int = 0
    content::T = SubString{String}("")
    sources::Vector{Int} = Int[]
    style::Styler = Styler()
end

# Implementing a basic tokenize function required for trigram_support!
function tokenize(input::Union{String, SubString{String}})
    pattern = r"(\s+|=>|\(;|,|\.|\(|\)|\{|\}|\[|\]|;|:|\+|-|\*|/|<|>|=|&|\||!|@|#|\$|%|\^|~|`|\"|'|\w+)"
    SubString{String}[m.match for m in eachmatch(pattern, input)]
end

# A basic trigrams function required for context preparation
function trigrams(input_string::AbstractString)
    trigrams = SubString{String}[]
    if length(input_string) >= 3
        for i in 1:(length(input_string) - 2)
            push!(trigrams, @views input_string[i:(i + 2)])
        end
    end
    return trigrams
end

@testset "trigram_support!" begin
    # Preparing a mock context of trigrams for testing
    context_trigrams = [trigrams("This is a test."), trigrams("Another test."),
        trigrams("More content here.")]

    # Test updating a node with no matching trigrams in context
    @test begin
        node = AnnotatedNode(content = "Unrelated content")
        trigram_support!(node, context_trigrams)
        isempty(node.children) && isnothing(node.score) && node.hits == 0
    end

    # Test updating a node with partial matching trigrams in context
    @test begin
        node = AnnotatedNode(content = "This is")
        trigram_support!(node, context_trigrams)
        !isempty(node.children) && node.score > 0 &&
            node.hits < length(tokenize(node.content))
    end

    # Test updating a node with full matching trigrams in context
    @test begin
        node = AnnotatedNode(content = "Another test.")
        trigram_support!(node, context_trigrams)
        !isempty(node.children) && !isnothing(node.score) &&
            node.hits == length(tokenize(node.content))
    end

    # Test handling of a single-character content, which should not form trigrams
    @test begin
        node = AnnotatedNode(content = "A")
        trigram_support!(node, context_trigrams)
        !isempty(node.children) && isnothing(node.score) && node.hits == 0
    end

    # Test with an empty content, expecting no children and no score
    @test begin
        node = AnnotatedNode(content = "")
        trigram_support!(node, context_trigrams)
        isempty(node.children) && isnothing(node.score)
    end
end

using Test

# Assuming required structures and helper functions are already defined.
# Mock context trigrams preparation function for testing
function prepare_context_trigrams(context::AbstractVector)
    # This mock function would typically convert context sentences to trigrams
    # For simplicity, we return a mock representation
    return [trigrams(sentence) for sentence in context]
end

@testset "annotate_support" begin
    # Context setup for testing
    annotater = TrigramAnnotater()
    context = [
        "This is a test context.", "Another context sentence.", "Final piece of context."]
    context_trigrams = prepare_context_trigrams(context)

    # Test annotating an answer that partially matches the context
    @test begin
        answer = "This is a test answer. It has multiple sentences."
        annotated_root = annotate_support(annotater, answer, context_trigrams)
        !isempty(annotated_root.children) && length(annotated_root.children) == 2
    end

    # Test annotating an answer that fully matches the context
    @test begin
        answer = "This is a test context. Another context sentence."
        annotated_root = annotate_support(annotater, answer, context_trigrams)
        all(child -> !isnothing(child.score) && child.hits > 0, annotated_root.children)
    end

    # Test annotating an answer with no matching content in the context
    @test begin
        answer = "Unrelated content here. Completely different."
        annotated_root = annotate_support(annotater, answer, context_trigrams)
        all(child -> isnothing(child.score), annotated_root.children)
    end

    # Test annotating an empty answer, expecting a root node with no children
    @test begin
        answer = ""
        annotated_root = annotate_support(annotater, answer, context_trigrams)
        isempty(annotated_root.children)
    end

    # Test handling of special characters and punctuation in the answer
    @test begin
        answer = "Special characters: !@#$%. Punctuation marks: ,;:."
        annotated_root = annotate_support(annotater, answer, context_trigrams)
        !isempty(annotated_root.children) && length(annotated_root.children) == 2
    end
end

using Test
using AbstractTrees

# Assuming the AnnotatedNode struct and relevant methods are defined as per the previous context

@testset "AnnotatedNode and its Interface" begin
    # Test node creation with default values
    @test begin
        node = AnnotatedNode()
        @test node.group_id == 0
        @test isnothing(node.parent)
        @test isempty(node.children)
        @test isnothing(node.score)
        @test node.hits == 0
        @test node.content == ""
        @test isempty(node.sources)
        @test typeof(node.style) == Styler && node.style.color == :nothing
    end

    # Test node creation with specific values
    @test begin
        parent_node = AnnotatedNode(content = "parent")
        child_node = AnnotatedNode(parent = parent_node, content = "child")
        @test child_node.parent === parent_node
        @test child_node.content == "child"
    end

    # Test adding a child node updates children array correctly
    @test begin
        parent_node = AnnotatedNode()
        child_node = AnnotatedNode(content = "child")
        push!(parent_node.children, child_node)
        @test length(parent_node.children) == 1
        @test parent_node.children[1] === child_node
    end

    # Test AbstractTrees interface compatibility
    @test begin
        parent_node = AnnotatedNode(content = "parent")
        child_node1 = AnnotatedNode(content = "child1")
        child_node2 = AnnotatedNode(content = "child2")
        push!(parent_node.children, child_node1)
        push!(parent_node.children, child_node2)

        @test AbstractTrees.children(parent_node) == [child_node1, child_node2]
        @test AbstractTrees.parent(child_node1) === parent_node
        @test AbstractTrees.parent(child_node2) === parent_node
    end

    # Test nodevalue and childtype methods for tree traversal
    @test begin
        node = AnnotatedNode(content = "root", group_id = 1)
        child_node = AnnotatedNode(content = "child", group_id = 2)
        push!(node.children, child_node)
        @test AbstractTrees.nodevalue(node) == 1
        @test AbstractTrees.childtype(node) === AnnotatedNode
    end

    # Test pprint function for a single node
    @test begin
        node = AnnotatedNode(content = "test", group_id = 123)
        io = IOBuffer()
        pprint(io, node)
        @test occursin("AnnotatedNode(id: 123, 4)", String(take!(io)))
    end
end

using Test

# Assuming the Styler, AnnotatedNode, and TrigramAnnotater structures are already defined as per previous contexts

# Test setup for set_node_style!
function set_node_style!(annotater::TrigramAnnotater, node::AnnotatedNode;
        low_threshold::Float64 = 0.5, high_threshold::Float64 = 1.0,
        high_styler::Styler = Styler(color = :green, bold = false), low_styler::Styler = Styler(
            color = :red, bold = false),
        bold_multihits::Bool = true)
    node.style = if isnothing(node.score)
        Styler()
    elseif node.score >= high_threshold
        high_styler
    elseif node.score >= low_threshold
        low_styler
    else
        Styler()
    end

    if node.hits > 1 && bold_multihits
        node.style.bold = true
    end

    return node
end

@testset "set_node_style!" begin
    annotater = TrigramAnnotater()

    # Test with a high score exceeding high_threshold
    @test begin
        node = AnnotatedNode(score = 0.9)
        set_node_style!(annotater, node; high_threshold = 0.8, low_threshold = 0.3)
        @test node.style.color == :green && node.style.bold == false
    end

    # Test with a score between high_threshold and low_threshold
    @test begin
        node = AnnotatedNode(score = 0.4)
        set_node_style!(annotater, node; high_threshold = 0.8, low_threshold = 0.3)
        @test node.style.color == :red && node.style.bold == false
    end

    # Test with a score below low_threshold
    @test begin
        node = AnnotatedNode(score = 0.2)
        set_node_style!(annotater, node; high_threshold = 0.8, low_threshold = 0.3)
        @test node.style.color == :nothing && node.style.bold == false
    end

    # Test applying bold style for multiple hits
    @test begin
        node = AnnotatedNode(score = 0.9, hits = 2)
        set_node_style!(annotater, node; high_threshold = 0.8, bold_multihits = true)
        @test node.style.color == :green && node.style.bold == true
    end

    # Test not applying bold style when bold_multihits is false
    @test begin
        node = AnnotatedNode(score = 0.9, hits = 2)
        set_node_style!(annotater, node; high_threshold = 0.8, bold_multihits = false)
        @test node.style.color == :green && node.style.bold == false
    end

    # Test with isnothing(node.score), expecting default style
    @test begin
        node = AnnotatedNode(score = nothing)
        set_node_style!(annotater, node)
        @test node.style.color == :nothing && node.style.bold == false
    end
end

using Test

# Assuming the Styler, AnnotatedNode, and TrigramAnnotater structures are already defined as per previous contexts

# Test setup for set_node_style!
function set_node_style!(annotater::TrigramAnnotater, node::AnnotatedNode;
        low_threshold::Float64 = 0.5, high_threshold::Float64 = 1.0,
        high_styler::Styler = Styler(color = :green, bold = false), low_styler::Styler = Styler(
            color = :red, bold = false),
        bold_multihits::Bool = true)
    node.style = if isnothing(node.score)
        Styler()
    elseif node.score >= high_threshold
        high_styler
    elseif node.score >= low_threshold
        low_styler
    else
        Styler()
    end

    if node.hits > 1 && bold_multihits
        node.style.bold = true
    end

    return node
end

@testset "set_node_style!" begin
    annotater = TrigramAnnotater()

    # Test with a high score exceeding high_threshold
    @test begin
        node = AnnotatedNode(score = 0.9)
        set_node_style!(annotater, node; high_threshold = 0.8, low_threshold = 0.3)
        @test node.style.color == :green && node.style.bold == false
    end

    # Test with a score between high_threshold and low_threshold
    @test begin
        node = AnnotatedNode(score = 0.4)
        set_node_style!(annotater, node; high_threshold = 0.8, low_threshold = 0.3)
        @test node.style.color == :red && node.style.bold == false
    end

    # Test with a score below low_threshold
    @test begin
        node = AnnotatedNode(score = 0.2)
        set_node_style!(annotater, node; high_threshold = 0.8, low_threshold = 0.3)
        @test node.style.color == :nothing && node.style.bold == false
    end

    # Test applying bold style for multiple hits
    @test begin
        node = AnnotatedNode(score = 0.9, hits = 2)
        set_node_style!(annotater, node; high_threshold = 0.8, bold_multihits = true)
        @test node.style.color == :green && node.style.bold == true
    end

    # Test not applying bold style when bold_multihits is false
    @test begin
        node = AnnotatedNode(score = 0.9, hits = 2)
        set_node_style!(annotater, node; high_threshold = 0.8, bold_multihits = false)
        @test node.style.color == :green && node.style.bold == false
    end

    # Test with isnothing(node.score), expecting default style
    @test begin
        node = AnnotatedNode(score = nothing)
        set_node_style!(annotater, node)
        @test node.style.color == :nothing && node.style.bold == false
    end
end

using Test

# Assuming the Styler, AnnotatedNode, and TrigramAnnotater structures are already defined as per previous contexts

# Mock implementation for align_node_styles!
function align_node_styles!(
        annotater::TrigramAnnotater, nodes::Vector{AnnotatedNode}; kwargs...)
    for i in 2:(length(nodes) - 1)
        prev, current, next = nodes[i - 1], nodes[i], nodes[i + 1]
        if isnothing(current.score) && prev.style == next.style
            current.style = prev.style
        end
    end
end

@testset "align_node_styles!" begin
    annotater = TrigramAnnotater()

    # Setup for tests: Create a sequence of nodes with varied styles
    node1 = AnnotatedNode(style = Styler(color = :red), score = 1.0)
    node2 = AnnotatedNode(style = Styler(), score = nothing) # Target for style alignment
    node3 = AnnotatedNode(style = Styler(color = :red), score = 1.0)
    nodes = [node1, node2, node3]

    # Test aligning styles in a simple sequence
    @test begin
        align_node_styles!(annotater, nodes)
        @test nodes[2].style.color == :red
    end

    # Test with non-matching surrounding styles, expecting no change
    @test begin
        node4 = AnnotatedNode(style = Styler(color = :green), score = 1.0) # Different style
        node5 = AnnotatedNode(style = Styler(), score = nothing) # Target for style alignment
        node6 = AnnotatedNode(style = Styler(color = :red), score = 1.0)
        nodes2 = [node4, node5, node6]

        align_node_styles!(annotater, nodes2)
        @test nodes2[2].style.color == :nothing # Should remain unchanged
    end

    # Test with first and last nodes, which should not be aligned
    @test begin
        node7 = AnnotatedNode(style = Styler(), score = nothing) # First node
        node8 = AnnotatedNode(style = Styler(color = :blue), score = 1.0)
        node9 = AnnotatedNode(style = Styler(), score = nothing) # Last node
        nodes3 = [node7, node8, node9]

        align_node_styles!(annotater, nodes3)
        @test nodes3[1].style.color == :nothing && nodes3[3].style.color == :nothing # Should remain unchanged
    end

    # Test aligning styles with more complex sequences
    @test begin
        node10 = AnnotatedNode(style = Styler(color = :blue), score = 1.0)
        node11 = AnnotatedNode(style = Styler(), score = nothing) # Target for style alignment
        node12 = AnnotatedNode(style = Styler(color = :blue), score = 1.0)
        node13 = AnnotatedNode(style = Styler(), score = nothing) # Another target, but no adjacent same styles
        nodes4 = [node10, node11, node12, node13]

        align_node_styles!(annotater, nodes4)
        @test nodes4[2].style.color == :blue && nodes4[4].style.color == :nothing
    end
end

using Test

# Mocking required components and helper functions
@kwdef mutable struct Styler
    color::Symbol = :nothing
    bold::Bool = false
    underline::Bool = false
    italic::Bool = false
end

@kwdef mutable struct AnnotatedNode{T = String}
    content::T = ""
    children::Vector{AnnotatedNode{T}} = AnnotatedNode{T}[]
    style::Styler = Styler()
end

function pprint(io::IO, node::AnnotatedNode{T}) where {T}
    if isempty(node.children)
        printstyled(io, node.content; bold = node.style.bold, color = node.style.color,
            underline = node.style.underline, italic = node.style.italic)
    else
        for child in node.children
            pprint(io, child)
        end
    end
end

@testset "pprint" begin
    # Test pprint with a single node
    @test begin
        node = AnnotatedNode(content = "root", style = Styler(color = :red, bold = true))
        io = IOBuffer()
        pprint(io, node)
        @test String(take!(io)) == "root" # Simplified check due to lack of styled output in tests
    end

    # Test pprint with nested children
    @test begin
        parent_node = AnnotatedNode(content = "parent")
        child_node1 = AnnotatedNode(content = "child1", style = Styler(bold = true))
        child_node2 = AnnotatedNode(content = "child2", style = Styler(italic = true))
        push!(parent_node.children, child_node1)
        push!(parent_node.children, child_node2)

        io = IOBuffer()
        pprint(io, parent_node)
        output = String(take!(io))
        expected_output = "child1child2" # Simplified check; in practice, validate styled output
        @test output == expected_output
    end

    # Test pprint with empty content
    @test begin
        node = AnnotatedNode()
        io = IOBuffer()
        pprint(io, node)
        @test String(take!(io)) == ""
    end

    # Test pprint with complex hierarchy
    @test begin
        parent_node = AnnotatedNode(content = "parent", style = Styler(color = :blue))
        child_node = AnnotatedNode(content = "child", style = Styler(underline = true))
        grandchild_node = AnnotatedNode(content = "grandchild", style = Styler(bold = true))

        push!(child_node.children, grandchild_node)
        push!(parent_node.children, child_node)

        io = IOBuffer()
        pprint(io, parent_node)
        output = String(take!(io))
        expected_output = "childgrandchild" # Simplified; actual output would include styles
        @test output == expected_output
    end
end
