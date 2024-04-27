using PromptingTools: @ai_str, @aai_str, @ai!_str, @aai!_str
using PromptingTools: TestEchoOpenAISchema, push_conversation!, CONV_HISTORY, UserMessage

# Develop the test for all ai"" macros...
# eg, ai"Hello echo"echo0 will send it to our echo model

# Global variables for conversation history and max length for testing purposes

@testset "ai_str,ai!_str" begin
    ## Setup echo
    # corresponds to OpenAI API v1
    response = Dict(:choices => [Dict(:message => Dict(:content => "Hello!"))],
        :usage => Dict(:total_tokens => 3, :prompt_tokens => 2, :completion_tokens => 1))
    PT.register_model!(;
        name = "echo0",
        schema = TestEchoOpenAISchema(; response, status = 200))

    # Test generation of AI response using the basic macro with no model alias (default model)
    response = ai"Hello, how are you?"echo0 # simple call using the default model
    @test response.content == "Hello!"
    schema_ref = PT.MODEL_REGISTRY["echo0"].schema
    @test schema_ref.inputs ==
          [Dict("role" => "system", "content" => "Act as a helpful AI assistant")
           Dict("role" => "user", "content" => "Hello, how are you?")]

    # Test the macro with string interpolation
    a = 1
    response = ai"What is `$a+$a`?"echo0 # Test with interpolated variable
    schema_ref = PT.MODEL_REGISTRY["echo0"].schema
    @test schema_ref.inputs ==
          [Dict("role" => "system", "content" => "Act as a helpful AI assistant")
           Dict("role" => "user", "content" => "What is `1+1`?")]

    # ai!_str_macro" begin
    # Prepopulate conversation history
    push_conversation!(CONV_HISTORY, [AIMessage("Say hi.")], 999)

    # Test if it continues the conversation as expected
    response = ai!"Hi again!"echo0 # continue the conversation
    schema_ref = PT.MODEL_REGISTRY["echo0"].schema
    @test schema_ref.inputs ==
          [Dict("role" => "system", "content" => "Act as a helpful AI assistant"),
        Dict("role" => "assistant", "content" => "Say hi."),
        Dict("role" => "user", "content" => "Hi again!")]

    @test CONV_HISTORY[end][end].content == "Hello!"

    # Test an assertion that there is conversation history
    empty!(CONV_HISTORY)
    @test_throws AssertionError ai!"Where are you located?"

    # clean up
    empty!(CONV_HISTORY)
end

@testset "aai_str,aai!_str" begin
    ## Setup echo
    # corresponds to OpenAI API v1
    response = Dict(:choices => [Dict(:message => Dict(:content => "Hello!"))],
        :usage => Dict(:total_tokens => 3, :prompt_tokens => 2, :completion_tokens => 1))
    PT.register_model!(;
        name = "echo0",
        schema = TestEchoOpenAISchema(; response, status = 200))

    # default test
    response = aai"Hello, how are you?"echo0 # simple call using the default model
    wait(response) # Wait for the task to complete
    @test fetch(response).content == "Hello!"
    schema_ref = PT.MODEL_REGISTRY["echo0"].schema
    @test schema_ref.inputs ==
          [Dict("role" => "system", "content" => "Act as a helpful AI assistant")
           Dict("role" => "user", "content" => "Hello, how are you?")]
    @test CONV_HISTORY[end][end].content == "Hello!"

    # continue conversation
    push_conversation!(CONV_HISTORY, [AIMessage("Say hi.")], 999)
    response = aai!"Hi again!"echo0 # continue the conversation
    wait(response) # Wait for the task to complete
    schema_ref = PT.MODEL_REGISTRY["echo0"].schema
    @test schema_ref.inputs ==
          [Dict("role" => "system", "content" => "Act as a helpful AI assistant"),
        Dict("role" => "assistant", "content" => "Say hi."),
        Dict("role" => "user", "content" => "Hi again!")]

    @test CONV_HISTORY[end][end].content == "Hello!"

    # clean up
    empty!(CONV_HISTORY)
end
