using PromptingTools: split_by_length, replace_words
using PromptingTools: _extract_handlebar_variables, call_cost, _report_stats
using PromptingTools: _string_to_vector, _encode_local_image
using PromptingTools: DataMessage, AIMessage
using PromptingTools: push_conversation!,
    resize_conversation!, @timeout, preview, auth_header

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

@testset "split_by_length" begin
    text = "Hello world. How are you?"
    chunks = split_by_length(text, max_length = 100)
    @test length(chunks) == 1
    @test chunks[1] == text
    chunks = split_by_length(text, max_length = 25)
    @test length(chunks) == 1
    @test chunks[1] == text
    @test maximum(length.(chunks)) <= 25
    chunks = split_by_length(text, max_length = 10)
    @test length(chunks) == 4
    @test maximum(length.(chunks)) <= 10
    chunks = split_by_length(text, max_length = 11)
    @test length(chunks) == 3
    @test maximum(length.(chunks)) <= 11
    @test join(chunks, "") == text

    # Test with empty text
    chunks = split_by_length("")
    @test chunks == [""]

    # Test custom separator
    text = "Hello,World,"^50
    chunks = split_by_length(text, separator = ",", max_length = length(text))
    @test length(chunks) == 1
    @test chunks[1] == text
    chunks = split_by_length(text, separator = ",", max_length = 20)
    @test length(chunks) == 34
    @test maximum(length.(chunks)) <= 20
    @test join(chunks, "") == text

    ### Multiple separators
    # Single separator
    text = "First sentence. Second sentence. Third sentence."
    chunks = split_by_length(text, ["."], max_length = 15)
    @test length(chunks) == 3
    @test chunks == ["First sentence.", " Second sentence.", " Third sentence."]

    # Multiple separators
    text = "Paragraph 1\n\nParagraph 2. Sentence 1. Sentence 2.\nParagraph 3"
    separators = ["\n\n", ". ", "\n"]
    chunks = split_by_length(text, separators, max_length = 20)
    @test length(chunks) == 5
    @test chunks[1] == "Paragraph 1\n\n"
    @test chunks[2] == "Paragraph 2. "
    @test chunks[3] == "Sentence 1. "
    @test chunks[4] == "Sentence 2.\n"
    @test chunks[5] == "Paragraph 3"

    # empty separators
    text = "Some text without separators."
    @test_throws AssertionError split_by_length(text, String[], max_length = 10)

    # edge cases
    text = "Short text"
    separators = ["\n\n", ". ", "\n"]
    chunks = split_by_length(text, separators, max_length = 50)
    @test length(chunks) == 1
    @test chunks[1] == text

    # do not mutate separators input
    text = "Paragraph 1\n\nParagraph 2. Sentence 1. Sentence 2.\nParagraph 3"
    separators = ["\n\n", ". ", "\n"]
    sep_length = length(separators)
    chunks = split_by_length(text, separators, max_length = 20)
    chunks = split_by_length(text, separators, max_length = 20)
    chunks = split_by_length(text, separators, max_length = 20)
    @test length(separators) == sep_length
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
    msg = AIMessage(; content = "", tokens = (1000, 2000))
    cost = call_cost(msg, "unknown_model")
    @test cost == 0.0
    @test call_cost(msg, "gpt-3.5-turbo") ≈ 1000 * 0.5e-6 + 1.5e-6 * 2000

    msg = DataMessage(; content = nothing, tokens = (1000, 1000))
    cost = call_cost(msg, "unknown_model")
    @test cost == 0.0
    @test call_cost(msg, "gpt-3.5-turbo") ≈ 1000 * 0.5e-6 + 1.5e-6 * 1000

    @test call_cost(msg,
        "gpt-3.5-turbo";
        cost_of_token_prompt = 1,
        cost_of_token_generation = 1) ≈ 1000 + 1000
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
        PT.DataMessage(; content = ones(10)),
    ]
    preview_output = preview(conversation)
    expected_output = Markdown.parse("# System Message\n\nWelcome\n\n---\n\n# User Message\n\nHello\n\n---\n\n# AI Message\n\nWorld\n\n---\n\n# Data Message\n\nData: Vector{Float64} (Size: (10,))\n")
    @test preview_output == expected_output
end

@testset "auth_header" begin
    headers = auth_header("<my-api-key>")
    @test headers == [
        "Authorization" => "Bearer <my-api-key>",
        "Content-Type" => "application/json",
        "Accept" => "application/json",
    ]
    @test_throws ArgumentError auth_header("")
end