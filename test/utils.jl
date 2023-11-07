using PromptingTools: _extract_handlebar_variables, _report_stats

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
