using PromptingTools: split_by_length
using PromptingTools: _extract_handlebar_variables, _report_stats
using PromptingTools: _string_to_vector, _encode_local_image

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
    @test isempty(chunks)

    # Test custom separator
    text = "Hello,World,"^50
    chunks = split_by_length(text, separator = ",", max_length = length(text))
    @test length(chunks) == 1
    @test chunks[1] == text
    chunks = split_by_length(text, separator = ",", max_length = 20)
    @test length(chunks) == 34
    @test maximum(length.(chunks)) <= 20
    @test join(chunks, "") == text
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

@testset "report_stats" begin
    # Returns a string with the total number of tokens and elapsed time when given a message and model
    msg = AIMessage(; content = "", tokens = (1, 5), elapsed = 5.0)
    model = "model"
    expected_output = "Tokens: 6 in 5.0 seconds"
    @test _report_stats(msg, model) == expected_output

    # Returns a string with a cost
    expected_output = "Tokens: 6 @ Cost: \$0.007 in 5.0 seconds"
    @test _report_stats(msg, model, Dict(model => (2, 1))) == expected_output

    # Returns a string without cost when it's zero
    expected_output = "Tokens: 6 in 5.0 seconds"
    @test _report_stats(msg, model, Dict(model => (0, 0))) == expected_output
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
end
