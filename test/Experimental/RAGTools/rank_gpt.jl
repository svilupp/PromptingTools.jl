using PromptingTools.Experimental.RAGTools: RankGPTResult, create_permutation_instruction,
                                            extract_ranking, receive_permutation!,
                                            permutation_step!, rank_sliding_window!,
                                            rank_gpt
using PromptingTools: TestEchoOpenAISchema

@testset "RankGPTResult" begin
    # Test creation of RankGPTResult with default parameters
    result = RankGPTResult(question = "What is AI?", chunks = ["chunk1", "chunk2"])
    @test result.question == "What is AI?" # Check question
    @test result.chunks == ["chunk1", "chunk2"] # Check chunks
    @test result.positions == [1, 2] # Check default positions
    @test result.elapsed == 0.0 # Check default elapsed time
    @test result.cost == 0.0 # Check default cost
    @test result.tokens == 0 # Check default tokens

    # Test creation of RankGPTResult with custom positions
    result = RankGPTResult(
        question = "What is AI?", chunks = ["chunk1", "chunk2"], positions = [2, 1])
    @test result.positions == [2, 1] # Check custom positions

    # Test creation of RankGPTResult with custom elapsed time, cost, and tokens
    result = RankGPTResult(question = "What is AI?", chunks = ["chunk1", "chunk2"],
        elapsed = 5.0, cost = 10.0, tokens = 100)
    @test result.elapsed == 5.0 # Check custom elapsed time
    @test result.cost == 10.0 # Check custom cost
    @test result.tokens == 100 # Check custom tokens

    # Test show method for RankGPTResult
    io = IOBuffer()
    show(io, result)
    output = String(take!(io))
    @test occursin("question:", output) # Check if question is in the output
    @test occursin("What is AI?", output)
    @test occursin("chunks:", output) # Check if chunks are in the output
    @test occursin("positions:", output) # Check if positions are in the output
    @test occursin("elapsed:", output) # Check if elapsed time is in the output
    @test occursin("cost:", output) # Check if cost is in the output
    @test occursin("tokens:", output) # Check if tokens are in the output

    # Test creation of RankGPTResult with empty chunks
    result = RankGPTResult(question = "What is AI?", chunks = String[])
    @test result.chunks == String[] # Check empty chunks
    @test result.positions == [] # Check positions for empty chunks
end

@testset "create_permutation_instruction" begin
    # Test with basic context and default parameters
    context = ["This is a test.", "Another test document."]
    messages, num = create_permutation_instruction(context)
    @test num == 2 # Check number of messages
    @test length(messages) == 4 + 4 # Check total messages including AI responses
    @test messages[begin] isa PT.SystemMessage # Check first message type
    @test messages[4].content == "[1] This is a test."
    @test messages[5].content == "Received passage [1]."
    @test messages[6].content == "[2] Another test document."
    @test messages[7].content == "Received passage [2]."
    @test messages[end] isa PT.UserMessage # Check second message type

    # Test with custom rank_start and rank_end
    messages, num = create_permutation_instruction(context; rank_start = 2, rank_end = 2)
    @test num == 1 # Check number of messages
    @test length(messages) == 4 + 2 * 1 # Check total messages including AI responses
    @test messages[begin] isa PT.SystemMessage # Check first message type
    @test messages[4].content == "[1] Another test document."
    @test messages[5].content == "Received passage [1]."
    @test messages[end] isa PT.UserMessage # Check second message type

    # Test with max_length parameter
    long_context = ["This is a very long test document that exceeds the max length parameter."]
    messages, num = create_permutation_instruction(long_context; max_length = 10)
    @test num == 1 # Check number of messages
    @test length(messages) == 4 + 2 * 1 # Check total messages including AI responses
    @test length(messages[4].content) <= 10 + 5 # Check if content is truncated (+5 for the markers at the beginning)

    # Test with different template
    @test_throws ErrorException create_permutation_instruction(
        context; template = :AnotherTemplateNotExist)

    # Test with empty context
    empty_context = String[]
    messages, num = create_permutation_instruction(empty_context)
    @test num == 0 # Check number of messages
    @test length(messages) == 4 # Check total messages including AI responses
end

@testset "extract_ranking" begin
    @test extract_ranking("asdas1asdas") == [1] # Test single number
    @test extract_ranking("[1] > [2] > [3]") == [1, 2, 3] # Test multiple numbers
    @test extract_ranking("[3] > [2] > [1]") == [3, 2, 1] # Test numbers in reverse order
    @test extract_ranking("[1], [2], [3]") == [1, 2, 3] # Test numbers with commas
    @test extract_ranking("[1] > [2] > [2] > [3]") == [1, 2, 3] # Test duplicate numbers
    @test extract_ranking("[1] > [2] > [3] > [3] > [2] > [1]") == [1, 2, 3] # Test multiple duplicates
    @test extract_ranking("a1b2c3") == [1, 2, 3] # Test numbers with letters
    @test extract_ranking("[1] > [2] > [3] > [4] > [5] > [6] > [7] > [8] > [9] > [10]") ==
          [1, 2, 3, 4, 5, 6, 7, 8, 9, 10] # Test larger range of numbers
    @test extract_ranking("10 9 8 7 6 5 4 3 2 1") == [10, 9, 8, 7, 6, 5, 4, 3, 2, 1] # Test larger range in reverse order
    @test extract_ranking("1 2 3 4 5 6 7 8 9 10 10 9 8 7 6 5 4 3 2 1") ==
          [1, 2, 3, 4, 5, 6, 7, 8, 9, 10] # Test larger range with duplicates
end

@testset "receive_permutation!" begin
    # Test with basic ranking and response
    curr_rank = [1, 2, 3]
    response = "[1] > [2] > [3]"
    @test receive_permutation!(curr_rank, response) == [1, 2, 3] # Basic case

    # Test with reversed ranking in response
    curr_rank = [1, 2, 3]
    response = "[3] > [2] > [1]"
    @test receive_permutation!(curr_rank, response) == [3, 2, 1] # Reversed ranking

    # Test with missing ranks in response
    curr_rank = [1, 2, 3, 4, 5]
    response = "[5] > [3] > [1]"
    @test receive_permutation!(curr_rank, response) == [5, 3, 1, 2, 4] # Missing ranks

    # Test with extra ranks in response
    curr_rank = [1, 2, 3]
    response = "[1] > [2] > [3] > [4] > [5]"
    @test receive_permutation!(curr_rank, response) == [1, 2, 3] # Extra ranks

    # Test with duplicate ranks in response
    curr_rank = [1, 2, 3]
    response = "[1] > [2] > [2] > [3]"
    @test receive_permutation!(curr_rank, response) == [1, 2, 3] # Duplicate ranks

    # Test with non-sequential ranks in response
    curr_rank = [1, 2, 3, 4, 5]
    response = "[5] > [1] > [3]"
    @test receive_permutation!(curr_rank, response) == [5, 1, 3, 2, 4] # Non-sequential ranks

    # Test with rank_start and rank_end parameters
    curr_rank = [1, 2, 3, 4, 5]
    response = "[4] > [5]"
    @test receive_permutation!(curr_rank, response; rank_start = 4, rank_end = 5) ==
          [1, 2, 3, 4, 5] # Rank start and end

    # Test with rank_start and rank_end parameters, non-sequential
    curr_rank = [1, 2, 3, 4, 5]
    response = "[2] > [1]"
    @test receive_permutation!(curr_rank, response; rank_start = 4, rank_end = 5) ==
          [1, 2, 3, 5, 4] # Rank start and end, non-sequential

    # Test with rank_start and rank_end parameters, missing ranks
    curr_rank = [1, 2, 3, 4, 5]
    response = "[2]"
    @test receive_permutation!(curr_rank, response; rank_start = 4, rank_end = 5) ==
          [1, 2, 3, 5, 4] # Rank start and end, missing ranks

    # Test with rank_start and rank_end parameters, duplicate ranks
    curr_rank = [1, 2, 3, 4, 5]
    response = "[2 ] > [2]"
    @test receive_permutation!(curr_rank, response; rank_start = 4, rank_end = 5) ==
          [1, 2, 3, 5, 4] # Rank start and end, duplicate ranks
end

@testset "permutation_step!" begin
    # Mocking the aigenerate function
    response = Dict(
        :choices => [
            Dict(:message => Dict(:content => "[1] > [2]"), :finish_reason => "stop")
        ],
        :usage => Dict(:total_tokens => 3,
            :prompt_tokens => 2,
            :completion_tokens => 1))
    schema = TestEchoOpenAISchema(; response, status = 200)
    PT.register_model!(; name = "mock-gen", schema)

    # Simple case with default parameters
    result = RankGPTResult(question = "What is AI?", chunks = ["chunk1", "chunk2"])
    @test permutation_step!(result; model = "mock-gen").positions == [1, 2] # Simple case

    # Case with more chunks
    result = RankGPTResult(
        question = "What is AI?", chunks = ["chunk1", "chunk2", "chunk3"])
    @test permutation_step!(result; model = "mock-gen").positions == [1, 2, 3] # More chunks

    # Case with rank_start and rank_end parameters
    result = RankGPTResult(question = "What is AI?",
        chunks = ["chunk1", "chunk2", "chunk3", "chunk4", "chunk5"])
    @test permutation_step!(
        result; rank_start = 2, rank_end = 4, model = "mock-gen").positions ==
          [1, 2, 3, 4, 5] # Rank start and end

    # Case with non-sequential ranks in response
    response = Dict(
        :choices => [
            Dict(:message => Dict(:content => "[3] > [1] > [2]"), :finish_reason => "stop")
        ],
        :usage => Dict(:total_tokens => 3,
            :prompt_tokens => 2,
            :completion_tokens => 1))
    schema = TestEchoOpenAISchema(; response, status = 200)
    PT.register_model!(; name = "mock-gen", schema)
    result = RankGPTResult(
        question = "What is AI?", chunks = ["chunk1", "chunk2", "chunk3"])
    @test permutation_step!(result; model = "mock-gen").positions == [3, 1, 2] # Non-sequential ranks

    # Case with duplicate ranks in response
    response = Dict(
        :choices => [
            Dict(:message => Dict(:content => "[2] > [2] > [1]"), :finish_reason => "stop")
        ],
        :usage => Dict(:total_tokens => 3,
            :prompt_tokens => 2,
            :completion_tokens => 1))
    schema = TestEchoOpenAISchema(; response, status = 200)
    PT.register_model!(; name = "mock-gen", schema)
    result = RankGPTResult(
        question = "What is AI?", chunks = ["chunk1", "chunk2", "chunk3"])
    @test permutation_step!(result; model = "mock-gen").positions == [2, 1, 3] # Duplicate ranks

    # Case with missing ranks in response
    response = Dict(
        :choices => [
            Dict(:message => Dict(:content => "[1] > [3]"), :finish_reason => "stop")
        ],
        :usage => Dict(:total_tokens => 3,
            :prompt_tokens => 2,
            :completion_tokens => 1))
    schema = TestEchoOpenAISchema(; response, status = 200)
    PT.register_model!(; name = "mock-gen", schema)
    result = RankGPTResult(
        question = "What is AI?", chunks = ["chunk1", "chunk2", "chunk3"])
    @test permutation_step!(result; model = "mock-gen").positions == [1, 3, 2] # Missing ranks
end

@testset "rank_sliding_window!" begin
    # Mocking the aigenerate function
    response = Dict(
        :choices => [
            Dict(:message => Dict(:content => "[1] > [2]"), :finish_reason => "stop")
        ],
        :usage => Dict(:total_tokens => 3,
            :prompt_tokens => 2,
            :completion_tokens => 1))
    schema = TestEchoOpenAISchema(; response, status = 200)
    PT.register_model!(; name = "mock-gen", schema)
    # Simple case with default parameters
    result = RankGPTResult(question = "What is AI?", chunks = ["chunk1", "chunk2"])
    @test rank_sliding_window!(result; model = "mock-gen").positions == [1, 2] # Simple case

    # Case with more chunks
    result = RankGPTResult(
        question = "What is AI?", chunks = ["chunk1", "chunk2", "chunk3"])
    @test rank_sliding_window!(result; model = "mock-gen").positions == [1, 2, 3] # More chunks

    # Case with rank_start and rank_end parameters
    result = RankGPTResult(question = "What is AI?",
        chunks = ["chunk1", "chunk2", "chunk3", "chunk4", "chunk5"])
    @test rank_sliding_window!(
        result; rank_start = 2, rank_end = 4, window_size = 2,
        step = 2, model = "mock-gen").positions ==
          [1, 2, 3, 4, 5] # Rank start and end

    # Case with non-sequential ranks in response
    response = Dict(
        :choices => [
            Dict(:message => Dict(:content => "[3] > [1] > [2]"), :finish_reason => "stop")
        ],
        :usage => Dict(:total_tokens => 3,
            :prompt_tokens => 2,
            :completion_tokens => 1))
    schema = TestEchoOpenAISchema(; response, status = 200)
    PT.register_model!(; name = "mock-gen", schema)
    result = RankGPTResult(
        question = "What is AI?", chunks = ["chunk1", "chunk2", "chunk3"])
    @test rank_sliding_window!(result; model = "mock-gen").positions == [3, 1, 2] # Non-sequential ranks

    # Case with duplicate ranks in response
    response = Dict(
        :choices => [
            Dict(:message => Dict(:content => "[2] > [2] > [1]"), :finish_reason => "stop")
        ],
        :usage => Dict(:total_tokens => 3,
            :prompt_tokens => 2,
            :completion_tokens => 1))
    schema = TestEchoOpenAISchema(; response, status = 200)
    PT.register_model!(; name = "mock-gen", schema)
    result = RankGPTResult(
        question = "What is AI?", chunks = ["chunk1", "chunk2", "chunk3"])
    @test rank_sliding_window!(result; model = "mock-gen").positions == [2, 1, 3] # Duplicate ranks

    # Case with missing ranks in response
    response = Dict(
        :choices => [
            Dict(:message => Dict(:content => "[1] > [3]"), :finish_reason => "stop")
        ],
        :usage => Dict(:total_tokens => 3,
            :prompt_tokens => 2,
            :completion_tokens => 1))
    schema = TestEchoOpenAISchema(; response, status = 200)
    PT.register_model!(; name = "mock-gen", schema)
    result = RankGPTResult(
        question = "What is AI?", chunks = ["chunk1", "chunk2", "chunk3"])
    @test rank_sliding_window!(result; model = "mock-gen").positions == [1, 3, 2] # Missing ranks

    ## Wrong inputs
    result = RankGPTResult(
        question = "What is AI?", chunks = ["chunk1", "chunk2", "chunk3"])
    @test_throws AssertionError rank_sliding_window!(
        result; rank_start = 2, rank_end = 4, window_size = 2,
        step = 3)
    @test_throws AssertionError rank_sliding_window!(
        result; rank_start = 2, rank_end = 4, window_size = 5,
        step = 1)
    @test_throws AssertionError rank_sliding_window!(
        result; rank_start = 2, rank_end = 4)
end

@testset "rank_gpt" begin
    response = Dict(
        :choices => [
            Dict(
            :message => Dict(:content => "[4] > [2] > [3] > [1]"), :finish_reason => "stop")
        ],
        :usage => Dict(:total_tokens => 3,
            :prompt_tokens => 2,
            :completion_tokens => 1))
    schema = TestEchoOpenAISchema(; response, status = 200)
    PT.register_model!(; name = "mock-gen", schema)
    # Test with basic chunks and question
    result = rank_gpt(["chunk1", "chunk2"], "What is AI?"; model = "mock-gen")
    @test result.question == "What is AI?" # Check question
    @test result.chunks == ["chunk1", "chunk2"] # Check chunks
    @test result.positions == [2, 1] # Check default positions

    # Test with custom rank_start and rank_end
    result = rank_gpt(["chunk1", "chunk2", "chunk3", "chunk4"],
        "What is AI?"; rank_start = 2, rank_end = 3, window_size = 3, step = 2, model = "mock-gen")
    @test result.positions == [1, 3, 2, 4] # Flips because the signal say [2] > [1]
    result = rank_gpt(["chunk1", "chunk2", "chunk3", "chunk4"],
        "What is AI?"; rank_start = 1, rank_end = 4, window_size = 4,
        step = 2, model = "mock-gen")
    @test result.positions == [4, 2, 3, 1] # Check positions with custom rank_start and rank_end

    # Test with window_size and step
    result = rank_gpt(
        ["chunk1", "chunk2", "chunk3", "chunk4"], "What is AI?"; window_size = 4, step = 4, model = "mock-gen")
    @test result.positions == [4, 2, 3, 1] # Check positions with window_size and step

    # Test with multiple rounds
    result = rank_gpt(
        ["chunk1", "chunk2", "chunk3", "chunk4"], "What is AI?"; num_rounds = 2, model = "mock-gen", verbose = 0)
    @test result.positions == [1, 2, 3, 4] # Check positions with multiple rounds (flips twice)
    result = rank_gpt(
        ["chunk1", "chunk2", "chunk3", "chunk4"], "What is AI?"; num_rounds = 3, model = "mock-gen", verbose = 0)
    @test result.positions == [4, 2, 3, 1] # Check positions with multiple rounds (flips twice)

    # Test with non-sequential ranks in response
    response = Dict(
        :choices => [
            Dict(:message => Dict(:content => "[3] > [1] > [2]"), :finish_reason => "stop")
        ],
        :usage => Dict(:total_tokens => 3,
            :prompt_tokens => 2,
            :completion_tokens => 1))
    schema = TestEchoOpenAISchema(; response, status = 200)
    PT.register_model!(; name = "mock-gen", schema)
    result = rank_gpt(["chunk1", "chunk2", "chunk3"], "What is AI?"; model = "mock-gen")
    @test result.positions == [3, 1, 2] # Check non-sequential ranks

    # Test with duplicate ranks in response
    response = Dict(
        :choices => [
            Dict(:message => Dict(:content => "[2] > [2] > [1]"), :finish_reason => "stop")
        ],
        :usage => Dict(:total_tokens => 3,
            :prompt_tokens => 2,
            :completion_tokens => 1))
    schema = TestEchoOpenAISchema(; response, status = 200)
    PT.register_model!(; name = "mock-gen", schema)
    result = rank_gpt(["chunk1", "chunk2", "chunk3"], "What is AI?"; model = "mock-gen")
    @test result.positions == [2, 1, 3] # Check duplicate ranks

    # Test with missing ranks in response
    response = Dict(
        :choices => [
            Dict(:message => Dict(:content => "[1] > [3]"), :finish_reason => "stop")
        ],
        :usage => Dict(:total_tokens => 3,
            :prompt_tokens => 2,
            :completion_tokens => 1))
    schema = TestEchoOpenAISchema(; response, status = 200)
    PT.register_model!(; name = "mock-gen", schema)
    result = rank_gpt(["chunk1", "chunk2", "chunk3"], "What is AI?"; model = "mock-gen")
    @test result.positions == [1, 3, 2] # Check missing ranks
end