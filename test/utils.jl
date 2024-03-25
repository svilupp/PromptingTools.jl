using PromptingTools: recursive_splitter, wrap_string, replace_words,
                      length_longest_common_subsequence, distance_longest_common_subsequence
using PromptingTools: _extract_handlebar_variables, call_cost, call_cost_alternative,
                      _report_stats
using PromptingTools: _string_to_vector, _encode_local_image
using PromptingTools: DataMessage, AIMessage
using PromptingTools: push_conversation!,
                      resize_conversation!, @timeout, preview, pprint, auth_header

@testset "replace_words" begin
    words = ["Disney", "Snow White", "Mickey Mouse"]
    @test replace_words("Disney is a great company",
        ["Disney", "Snow White", "Mickey Mouse"]) == "ABC is a great company"
    @test replace_words("Snow White and Mickey Mouse are great",
        ["Disney", "Snow White", "Mickey Mouse"]) == "ABC and ABC are great"
    @test replace_words("LSTM is a great model", "LSTM") == "ABC is a great model"
    @test replace_words("LSTM is a great model", "LSTM"; replacement = "XYZ") ==
          "XYZ is a great model"
end

@testset "recursive_splitter" begin
    text = "Hello world. How are you?"
    chunks = recursive_splitter(text, max_length = 100)
    @test length(chunks) == 1
    @test chunks[1] == text
    chunks = recursive_splitter(text, max_length = 25)
    @test length(chunks) == 1
    @test chunks[1] == text
    @test maximum(length.(chunks)) <= 25
    chunks = recursive_splitter(text, max_length = 10)
    @test length(chunks) == 4
    @test maximum(length.(chunks)) <= 10
    chunks = recursive_splitter(text, max_length = 11)
    @test length(chunks) == 3
    @test maximum(length.(chunks)) <= 11
    @test join(chunks, "") == text

    # Test with empty text
    chunks = recursive_splitter("")
    @test chunks == [""]

    # Test custom separator
    text = "Hello,World,"^50
    chunks = recursive_splitter(text, separator = ",", max_length = length(text))
    @test length(chunks) == 1
    @test chunks[1] == text
    chunks = recursive_splitter(text, separator = ",", max_length = 20)
    @test length(chunks) == 34
    @test maximum(length.(chunks)) <= 20
    @test join(chunks, "") == text

    ### Multiple separators
    # Single separator
    text = "First sentence. Second sentence. Third sentence."
    chunks = recursive_splitter(text, ["."], max_length = 15)
    @test length(chunks) == 3
    @test chunks == ["First sentence.", " Second sentence.", " Third sentence."]

    # Multiple separators
    text = "Paragraph 1\n\nParagraph 2. Sentence 1. Sentence 2.\nParagraph 3"
    separators = ["\n\n", ". ", "\n"]
    chunks = recursive_splitter(text, separators, max_length = 20)
    @test length(chunks) == 5
    @test chunks[1] == "Paragraph 1\n\n"
    @test chunks[2] == "Paragraph 2. "
    @test chunks[3] == "Sentence 1. "
    @test chunks[4] == "Sentence 2.\n"
    @test chunks[5] == "Paragraph 3"

    # empty separators
    text = "Some text without separators."
    @test_throws AssertionError recursive_splitter(text, String[], max_length = 10)

    # edge cases
    text = "Short text"
    separators = ["\n\n", ". ", "\n"]
    chunks = recursive_splitter(text, separators, max_length = 50)
    @test length(chunks) == 1
    @test chunks[1] == text

    # do not mutate separators input
    text = "Paragraph 1\n\nParagraph 2. Sentence 1. Sentence 2.\nParagraph 3"
    separators = ["\n\n", ". ", "\n"]
    sep_length = length(separators)
    chunks = recursive_splitter(text, separators, max_length = 20)
    chunks = recursive_splitter(text, separators, max_length = 20)
    chunks = recursive_splitter(text, separators, max_length = 20)
    @test length(separators) == sep_length
end

@testset "wrap_string" begin
    @test wrap_string("", 10) == ""
    @test wrap_string("Hi", 10) == "Hi"
    @test wrap_string(strip(" Hi "), 10) == "Hi" # SubString type
    output = wrap_string("This function will wrap words into lines", 10)
    @test maximum(length.(split(output, "\n"))) <= 10
    output = wrap_string("This function will wrap words into lines", 20)
    @test_broken maximum(length.(split(output, "\n"))) <= 20 #bug, it adds back the separator
    str = "This function will wrap words into lines"
    @test wrap_string(str, length(str)) == str
end

@testset "length_longest_common_subsequence" begin
    # Test for equal strings
    @test length_longest_common_subsequence("abcde", "abcde") == 5
    # flip the order of the strings -> abcd only
    @test length_longest_common_subsequence("abcde", "abced") == 4

    # Test for empty string
    @test length_longest_common_subsequence("", "") == 0

    # Test for no common subsequence
    @test length_longest_common_subsequence("abcde", "xyz") == 0

    # Test for partial common subsequence
    @test length_longest_common_subsequence("abcde", "ace") == 3

    # Test for common subsequence with repeated characters
    @test length_longest_common_subsequence("abc-abc----", "___ab_c__abc") == 6
end

@testset "distance_longest_common_subsequence" begin
    # Test for equal strings
    @test distance_longest_common_subsequence("abcde", "abcde") == 0

    # test for different strings
    @test distance_longest_common_subsequence("xyzut", "abced") == 1
    @test distance_longest_common_subsequence("xyzut", "") == 1

    # Test for empty string, they are the same, but we need to treat them as different
    @test_broken distance_longest_common_subsequence("", "") == 0.0

    # Test for partial common subsequence -> full match for seq2
    @test distance_longest_common_subsequence("abcde", "ace") == 0.0

    # Test for common subsequence with repeated characters
    @test distance_longest_common_subsequence("abc-abc----", "___ab_c__abc")≈0.45 atol=0.01

    # array dispatch
    context = [
        "The enigmatic stranger vanished as swiftly as a wisp of smoke, leaving behind a trail of unanswered questions.",
        "Beneath the shimmering moonlight, the ocean whispered secrets only the stars could hear.",
        "The ancient tree stood as a silent guardian, its gnarled branches reaching for the heavens.",
        "The melody danced through the air, painting a vibrant tapestry of emotions.",
        "Time flowed like a relentless river, carrying away memories and leaving imprints in its wake."]

    story = """
        Beneath the shimmering moonlight, the ocean whispered secrets only the stars could hear.

        Under the celestial tapestry, the vast ocean whispered its secrets to the indifferent stars. Each ripple, a murmured confidence, each wave, a whispered lament. The glittering celestial bodies listened in silent complicity, their enigmatic gaze reflecting the ocean's unspoken truths. The cosmic dance between the sea and the sky, a symphony of shared secrets, forever echoing in the ethereal expanse.
        """
    dist = distance_longest_common_subsequence(story, context)
    @test dist[2] == 0.0
end

@testset "extract_handlebar_variables" begin
    # Extracts handlebar variables enclosed in double curly braces
    input_string = "Hello {{name}}, how are you?"
    expected_output = [Symbol("name")]
    actual_output = _extract_handlebar_variables(input_string)
    @test actual_output == expected_output
    # Returns an empty array when there are no handlebar variables in the input string
    input_string = "Hello, how are you?"
    expected_output = Symbol[]
    actual_output = _extract_handlebar_variables(input_string)
    @test actual_output == expected_output
    # Returns an empty array when the input string is empty
    input_string = ""
    expected_output = Symbol[]
    actual_output = _extract_handlebar_variables(input_string)
    @test actual_output == expected_output
    # Extracts handlebar variables with alphanumeric characters, underscores, and dots
    input_string = "Hello {{user.name_1}}, your age is {{user.age-2}}."
    expected_output = [Symbol("user.name_1"), Symbol("user.age-2")]
    actual_output = _extract_handlebar_variables(input_string)
    @test actual_output == expected_output
end

@testset "call_cost" begin
    @test cost = call_cost(1000, 100, "unknown_model";
        cost_of_token_prompt = 1,
        cost_of_token_generation = 1) ≈ 1100
    msg = AIMessage(; content = "", tokens = (1000, 2000))
    cost = call_cost(msg, "unknown_model")
    @test cost == 0.0
    @test call_cost(msg, "gpt-3.5-turbo") ≈ 1000 * 0.5e-6 + 1.5e-6 * 2000

    # Test vector - same message, count once
    @test call_cost([msg, msg], "gpt-3.5-turbo") ≈ (1000 * 0.5e-6 + 1.5e-6 * 2000)
    msg2 = AIMessage(; content = "", tokens = (1000, 2000))
    @test call_cost([msg, msg2], "gpt-3.5-turbo") ≈ (1000 * 0.5e-6 + 1.5e-6 * 2000) * 2

    msg = DataMessage(; content = nothing, tokens = (1000, 1000))
    cost = call_cost(msg, "unknown_model")
    @test cost == 0.0
    @test call_cost(msg, "gpt-3.5-turbo") ≈ 1000 * 0.5e-6 + 1.5e-6 * 1000

    # From message
    msg = DataMessage(; content = nothing, tokens = (-1, -1), cost = 1.0)
    cost = call_cost(msg, "unknown_model")
    @test cost == 1.0
end

@testset "call_cost_alternative" begin
    @test call_cost_alternative(
        1, "dall-e-3"; image_quality = "standard", image_size = "1024x1024") ≈ 0.04
    @test call_cost_alternative(
        5, "dall-e-3"; image_quality = "standard", image_size = "1024x1024") ≈ 0.2
    @test call_cost_alternative(
        2, "dall-e-2"; image_quality = "weird", image_size = "xxx") ≈ 0.0
    @test call_cost_alternative(
        2, "unknown"; image_quality = "weird", image_size = "xxx") ≈ 0.0
end

@testset "report_stats" begin
    # Returns a string with the total number of tokens and elapsed time when given a message and model
    msg = AIMessage(; content = "", tokens = (1, 5), elapsed = 5.0)
    model = "unknown_model"
    expected_output = "Tokens: 6 in 5.0 seconds"
    @test _report_stats(msg, model) == expected_output

    # Returns a string with a cost
    msg = AIMessage(; content = "", tokens = (1000, 5000), elapsed = 5.0)
    expected_output = "Tokens: 6000 @ Cost: \$0.008 in 5.0 seconds"
    @test _report_stats(msg, "gpt-3.5-turbo") == expected_output
end

@testset "_string_to_vector" begin
    @test _string_to_vector("Hello") == ["Hello"]
    @test _string_to_vector(["Hello", "World"]) == ["Hello", "World"]
end

@testset "_encode_local_image" begin
    image_path = joinpath(@__DIR__, "data", "julia.png")
    output = _encode_local_image(image_path)
    @test output isa String
    @test occursin("data:image/png;base64,", output)
    output2 = _encode_local_image([image_path, image_path])
    @test output2 isa Vector
    @test output2[1] == output2[2] == output
    @test_throws AssertionError _encode_local_image("not an path")
    ## Test with base64_only = true
    output3 = _encode_local_image(image_path; base64_only = true)
    @test !occursin("data:image/png;base64,", output3)
    @test "data:image/png;base64," * output3 == output
    # Nothing
    @test _encode_local_image(nothing) == String[]
end

### Conversation Management
@testset "push_conversation!,resize_conversation!" begin
    # Test 1: Adding to Conversation History
    conv_history = Vector{Vector{<:Any}}()
    conversation = [AIMessage("Test message")]
    push_conversation!(conv_history, conversation, 5)
    @test length(conv_history) == 1
    @test conv_history[end] === conversation

    # Test 2: History Resize on Addition
    max_history = 5
    conv_history = [[AIMessage("Test message")] for i in 1:max_history]
    new_conversation = [AIMessage("Test message")]
    push_conversation!(conv_history, new_conversation, max_history)
    @test length(conv_history) == max_history
    @test conv_history[end] === new_conversation
    push_conversation!(conv_history, new_conversation, nothing)
    push_conversation!(conv_history, new_conversation, nothing)
    push_conversation!(conv_history, new_conversation, nothing)
    @test length(conv_history) > max_history
    @test conv_history[end] === new_conversation

    # Test 3: Manual Resize
    max_history = 5
    conv_history = [[AIMessage("Test message")] for i in 1:(max_history + 2)]
    resize_conversation!(conv_history, max_history)
    @test length(conv_history) == max_history

    # Test 4: No Resize with Nothing
    conv_history = [[AIMessage("Test message")] for i in 1:7]
    resize_conversation!(conv_history, nothing)
    @test length(conv_history) == 7
end

@testset "@timeout" begin
    #### Test 1: Successful Execution Within Timeout
    result = @timeout 2 begin
        sleep(1)
        "success"
    end "timeout"
    @test result == "success"

    #### Test 2: Execution Exceeds Timeout
    result = @timeout 1 begin
        sleep(2)
        "success"
    end "timeout"
    @test result == "timeout"

    #### Test 4: Negative Timeout
    @test_throws ArgumentError @timeout -1 begin
        "success"
    end "timeout"
end

@testset "preview" begin
    conversation = [
        PT.SystemMessage("Welcome"),
        PT.UserMessage("Hello"),
        PT.AIMessage("World"),
        PT.DataMessage(; content = ones(10))
    ]
    preview_output = preview(conversation)
    expected_output = Markdown.parse("# System Message\n\nWelcome\n\n---\n\n# User Message\n\nHello\n\n---\n\n# AI Message\n\nWorld\n\n---\n\n# Data Message\n\nData: Vector{Float64} (Size: (10,))\n")
    @test preview_output == expected_output
end

@testset "pprint" begin
    # anything -> passthrough to show
    x = "abc"
    io = IOBuffer()
    pprint(io, x)
    output = String(take!(io))
    @test output == "\"abc\""
    #
    conversation = [
        PT.SystemMessage("Welcome"),
        PT.UserMessage("Hello"),
        PT.AIMessage("World"),
        PT.DataMessage(; content = ones(10))
    ]
    io = IOBuffer()
    pprint(io, conversation)
    output = String(take!(io))
    exp_output = "--------------------\nSystem Message\n--------------------\nWelcome\n\n--------------------\nUser Message\n--------------------\nHello\n\n--------------------\nAI Message\n--------------------\nWorld\n\n--------------------\nData Message\n--------------------\nData: Vector{Float64} (Size: (10,))\n\n"
    @test output == exp_output

    struct RandomMessage1234x <: PT.AbstractMessage
        content::String
    end
    msgx = RandomMessage1234x("xyz")
    io = IOBuffer()
    pprint(io, msgx)
    output = String(take!(io))
    @test occursin("\nUnknown Message\n", output)
end

@testset "auth_header" begin
    headers = auth_header("<my-api-key>")
    @test headers == [
        "Authorization" => "Bearer <my-api-key>",
        "Content-Type" => "application/json",
        "Accept" => "application/json"
    ]
    @test_throws ArgumentError auth_header("")
    @test length(auth_header(nothing)) == 2

    # x-api-key format 
    headers = auth_header("<my-api-key>"; x_api_key = true, bearer = false,
        extra_headers = ["version" => "1.0"])
    @test headers == [
        "x-api-key" => "<my-api-key>",
        "Content-Type" => "application/json",
        "Accept" => "application/json",
        "version" => "1.0"
    ]
end
