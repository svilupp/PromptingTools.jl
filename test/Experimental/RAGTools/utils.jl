using PromptingTools.Experimental.RAGTools: _check_aiextract_capability,
                                            merge_labeled_matrices
using PromptingTools.Experimental.RAGTools: tokenize, trigrams, trigrams_hashed
using PromptingTools.Experimental.RAGTools: token_with_boundaries, text_to_trigrams,
                                            text_to_trigrams_hashed
using PromptingTools.Experimental.RAGTools: split_into_code_and_sentences

@testset "_check_aiextract_capability" begin
    @test _check_aiextract_capability("gpt-3.5-turbo") == nothing
    @test_throws AssertionError _check_aiextract_capability("llama2")
end

@testset "merge_labeled_matrices" begin
    # Test with dense matrices and overlapping vocabulary
    mat1 = [1 2; 3 4]
    vocab1 = ["word1", "word2"]
    mat2 = [5 6; 7 8]
    vocab2 = ["word2", "word3"]

    merged_mat, combined_vocab = merge_labeled_matrices(mat1, vocab1, mat2, vocab2)

    @test size(merged_mat) == (4, 3)
    @test combined_vocab == ["word1", "word2", "word3"]
    @test merged_mat == [1 2 0; 3 4 0; 0 5 6; 0 7 8]

    # Test with sparse matrices and disjoint vocabulary
    mat1 = sparse([1 0; 0 2])
    vocab1 = ["word1", "word2"]
    mat2 = sparse([3 0; 0 4])
    vocab2 = ["word3", "word4"]

    merged_mat, combined_vocab = merge_labeled_matrices(mat1, vocab1, mat2, vocab2)

    @test size(merged_mat) == (4, 4)
    @test combined_vocab == ["word1", "word2", "word3", "word4"]
    @test merged_mat == sparse([1 0 0 0; 0 2 0 0; 0 0 3 0; 0 0 0 4])

    # Test with different data types
    mat1 = [1.0 2.0; 3.0 4.0]
    vocab1 = ["word1", "word2"]
    mat2 = [5 6; 7 8]
    vocab2 = ["word2", "word3"]

    merged_mat, combined_vocab = merge_labeled_matrices(mat1, vocab1, mat2, vocab2)

    @test eltype(merged_mat) == Float64
    @test size(merged_mat) == (4, 3)
    @test combined_vocab == ["word1", "word2", "word3"]
    @test merged_mat ≈ [1.0 2.0 0.0; 3.0 4.0 0.0; 0.0 5.0 6.0; 0.0 7.0 8.0]
end

### Text-manipulation utilities

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
    @test trigrams("no") == []

    # Test with an empty string, also expecting an empty array
    @test trigrams("") == []

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
    @test trigrams_hashed("no") == Set()

    # Test with an empty string, expecting a set with 1 hash value because the empty string itself is hashed
    @test (trigrams_hashed("")) == Set()

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

@testset "text_to_trigrams" begin
    # Test converting basic text into trigrams
    exp_output = [
        "Thi", "his", "is ", "This", " is", "is ", "is", " te", "tes", "est", "st.", "test"]
    @test text_to_trigrams("This is a test."; add_word = true) == exp_output

    # Test converting without adding the word itself
    exp_output = ["Thi", "his", "is ", " is", "is ", " te", "tes", "est", "st."]
    @test text_to_trigrams("This is a test."; add_word = false) == exp_output

    # Test that spaces and punctuation are treated as separate tokens
    exp_output = ["Hel", "ell", "llo", "lo,", " wo", "wor", "orl", "rld", "ld!"]
    @test text_to_trigrams("Hello, world!"; add_word = false) == exp_output

    # Test with a string that includes single-character tokens affecting neighboring tokens
    # Expecting the single-character tokens to not produce separate trigrams but to influence surrounding tokens
    @test text_to_trigrams("A cat."; add_word = false) == [" ca", "cat", "at."]

    # Test with an empty string, expecting an empty array
    @test text_to_trigrams("") == []

    # Test a complex case with special characters, spaces, and punctuation
    # This checks that the function handles various types of tokens correctly
    @test text_to_trigrams("It's rain-ing!"; add_word = false) ==
          ["It'", " ra", "rai", "ain", "in-", "-in", "ing", "ng!"]

    # Test to ensure correct handling of multiple adjacent spaces and punctuation
    # Spaces and punctuation should be treated as tokens but not produce trigrams
    @test text_to_trigrams("Wow...  That's amazing!"; add_word = false) ==
          ["Wow", "ow.", ".  ", "Tha", "hat", "at'", " am",
        "ama", "maz", "azi", "zin", "ing", "ng!"]

    # Special characters
    text_to_trigrams("a!@ #\$%^"; add_word = false) == []
end

@testset "text_to_trigrams_hashed" begin
    # Test basic text conversion to hashed trigrams
    exp_output = [
        "Thi", "his", "is ", "This", " is", "is ", "is", " te", "tes", "est", "st.", "test"]
    @test text_to_trigrams_hashed("This is a test."; add_word = true) ==
          Set(hash.(exp_output))

    # Test converting without adding the word itself
    exp_output = ["Thi", "his", "is ", " is", "is ", " te", "tes", "est", "st."]
    @test text_to_trigrams_hashed("This is a test."; add_word = false) ==
          Set(hash.(exp_output))

    # Test that unique trigrams produce a set of unique hashes
    # "hello" produces 3 unique trigrams, expecting 3 unique hash values
    @test length(text_to_trigrams_hashed("hello"; add_word = false)) == 3

    # Test with a string of repeating characters, which should still produce unique trigrams
    @test text_to_trigrams_hashed("A cat."; add_word = false) ==
          Set(hash.([" ca", "cat", "at."]))

    # Test handling of special characters and spaces -- nothing produces (too short)
    text_to_trigrams_hashed("a!@ #\$%^"; add_word = false) == Set()

    # Test with an empty string, it's empty
    @test text_to_trigrams_hashed("") == Set()

    # Test to ensure no duplicate hash values in case of repeating patterns within the input string
    # For a pattern that repeats, like "ababab", the number of unique trigrams should be 2
    @test text_to_trigrams_hashed("ababab"; add_word = false) == Set(hash.(["aba", "bab"]))

    # Test a complex sentence with various characters, expecting a mix of unique hashes
    # The exact number of unique hashes is less important than ensuring we're getting a non-zero, plausible count
    @test text_to_trigrams_hashed("Complex sentence: 123!") ==
          Set(hash.(text_to_trigrams("Complex sentence: 123!")))
end

@testset "split_into_code_and_sentences" begin
    # Test basic sentence splitting
    input = "This is a test. This is another test."
    sentences, group_ids = split_into_code_and_sentences(input)
    @test sentences == ["This is a test.", " This is another test."]
    @test join(sentences, "") == input # lossless
    @test group_ids == [1, 2]

    # Test handling of code blocks and inline code
    input = """Here is a code block: 
      ```julia
      code here
      ```
      and `inline code`."""
    sentences, group_ids = split_into_code_and_sentences(input)
    @test sentences == ["Here is a code block: ", "\n", "```julia", "\n",
        "code here", "\n", "```", "\n", "and ", "`inline code`", "."]
    @test join(sentences, "") == input
    @test group_ids == [1, 2, 3, 3, 3, 3, 3, 4, 5, 6, 7]

    ## Multi-faceted code
    input = """Here is a code block: 
    ```julia
    code here
    ```
    and `inline code`.
    Sentences here.
    Bullets:
    - I like this
    - But does it work?
    ```julia
    another code
    ```
    1. Tester
    Third sentence - but what happened.
    """
    sentences, group_ids = split_into_code_and_sentences(input)
    @test sentences ==
          [
        "Here is a code block: ", "\n", "```julia", "\n", "code here", "\n", "```", "\n",
        "and ", "`inline code`", ".", "\n", "Sentences here.", "\n", "Bullets:", "\n", "- ",
        "I like this", "\n", "- ", "But does it work?", "\n", "```julia", "\n", "another code",
        "\n", "```", "\n", "1. ", "Tester", "\n", "Third sentence - but what happened.", "\n"]
    @test join(sentences, "") == input
    @test group_ids == [1, 2, 3, 3, 3, 3, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14,
        15, 16, 17, 18, 19, 19, 19, 19, 19, 20, 21, 22, 23, 24, 25]
end