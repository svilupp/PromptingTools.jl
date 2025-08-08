using PromptingTools: TestEchoAnthropicSchema, render, AnthropicSchema
using PromptingTools: AIMessage, SystemMessage, AbstractMessage
using PromptingTools: UserMessage, UserMessageWithImages, DataMessage, AIToolRequest,
                      ToolMessage, Tool
using PromptingTools: call_cost, anthropic_api, function_call_signature,
                      anthropic_extra_headers, ToolRef, BETA_HEADERS_ANTHROPIC

@testset "render-Anthropic" begin
    schema = AnthropicSchema()
    # Given a schema and a vector of messages with handlebar variables, it should replace the variables with the correct values in the conversation dictionary.
    messages = [
        SystemMessage("Act as a helpful AI assistant"),
        UserMessage("Hello, my name is {{name}}")
    ]
    expected_output = (; system = "Act as a helpful AI assistant",
        conversation = [Dict("role" => "user",
            "content" => [Dict("type" => "text", "text" => "Hello, my name is John")])])
    conversation = render(schema, messages; name = "John")
    @test conversation == expected_output
    # Test with dry_run=true on ai* functions
    @test aigenerate(schema, messages; name = "John", dry_run = true) == nothing
    @test aigenerate(schema, messages; name = "John", dry_run = true, return_all = true) ==
          expected_output

    # AI message does NOT replace variables
    messages = [
        SystemMessage("Act as a helpful AI assistant"),
        AIMessage("Hello, my name is {{name}}")
    ]
    expected_output = (; system = "Act as a helpful AI assistant",
        conversation = [Dict(
            "role" => "assistant",
            "content" => [Dict("type" => "text", "text" => "Hello, my name is {{name}}")])])
    conversation = render(schema, messages; name = "John")
    # AIMessage does not replace handlebar variables
    @test conversation == expected_output

    # Given a schema and a vector of messages with no system messages, it should add a default system prompt to the conversation dictionary.
    messages = [
        UserMessage("User message")
    ]
    conversation = render(schema, messages)
    expected_output = (; system = "Act as a helpful AI assistant",
        conversation = [Dict("role" => "user",
            "content" => [Dict("type" => "text", "text" => "User message")])])
    @test conversation == expected_output

    # Given a schema and a vector of messages, it should return a conversation dictionary with the correct roles and contents for each message.
    messages = [
        UserMessage("Hello"),
        AIMessage("Hi there"),
        UserMessage("How are you?"),
        AIMessage("I'm doing well, thank you!")
    ]
    expected_output = (; system = "Act as a helpful AI assistant",
        conversation = [
            Dict(
                "role" => "user", "content" => [Dict("type" => "text", "text" => "Hello")]),
            Dict("role" => "assistant",
                "content" => [Dict("type" => "text", "text" => "Hi there")]),
            Dict("role" => "user",
                "content" => [Dict("type" => "text", "text" => "How are you?")]),
            Dict("role" => "assistant",
                "content" => [Dict(
                    "type" => "text", "text" => "I'm doing well, thank you!")])
        ])
    conversation = render(schema, messages)
    @test conversation == expected_output

    # Given a schema and a vector of messages with a system message, it should move the system to the separate slot
    messages = [
        UserMessage("Hello"),
        AIMessage("Hi there"),
        SystemMessage("This is a system message")
    ]
    expected_output = (; system = "This is a system message",
        conversation = [
            Dict(
                "role" => "user", "content" => [Dict("type" => "text", "text" => "Hello")]),
            Dict("role" => "assistant",
                "content" => [Dict("type" => "text", "text" => "Hi there")])
        ])
    conversation = render(schema, messages)
    @test conversation == expected_output

    # Given an empty vector of messages, it throws an error.
    messages = AbstractMessage[]
    @test_throws AssertionError render(schema, messages)

    # Given a schema and a vector of messages with an unknown message type, it should skip the message and continue building the conversation dictionary.
    messages = [
        UserMessage("Hello"),
        DataMessage(; content = ones(3, 3)),
        AIMessage("Hi there")
    ]
    expected_output = (; system = "Act as a helpful AI assistant",
        conversation = [
            Dict(
                "role" => "user", "content" => [Dict("type" => "text", "text" => "Hello")]),
            Dict("role" => "assistant",
                "content" => [Dict("type" => "text", "text" => "Hi there")])
        ])
    conversation = render(schema, messages)
    @test conversation == expected_output

    ### IMAGES
    # Test UserMessageWithImages -- errors for now
    messages = [
        SystemMessage("System message 1"),
        UserMessageWithImages("User message"; image_url = "https://example.com/image.png")
    ]
    ## We don't support URL format!
    @test_throws Exception render(schema, messages)

    ## Unsupported format
    messages = [
        SystemMessage("System message 1"),
        UserMessageWithImages(
            "User message"; image_url = "data:image/svg;base64,iVBORw0KGgoAAAANSUhEUgAABQAA")
    ]
    @test_throws AssertionError render(schema, messages)

    ## Base64 format
    messages = [
        SystemMessage("System message 1"),
        UserMessageWithImages(
            "User message"; image_url = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAABQAA")
    ]
    rendered = render(schema, messages)
    @test rendered.conversation[1] == Dict{String, Any}("role" => "user",
        "content" => Dict{String, Any}[Dict("text" => "User message", "type" => "text"),
            Dict(
                "source" => Dict("media_type" => "image/png",
                    "data" => "iVBORw0KGgoAAAANSUhEUgAABQAA", "type" => "base64"),
                "type" => "image")])

    ### Tool calling
    "abc"
    struct FruitCountX
        fruit::String
        count::Int
    end
    tools = [Dict("name" => "function_xyz", "description" => "ABC",
        "input_schema" => "")]
    messages = [
        SystemMessage("Act as a helpful AI assistant"),
        UserMessage("Hello, my name is {{name}}")
    ]
    conversation = render(schema, messages; name = "John")

    tools = [Dict("name" => "function_xyz", "description" => "ABC",
            "input_schema" => ""),
        Dict("name" => "function_abc", "description" => "ABC",
            "input_schema" => "")]

    ## Cache variables
    messages = [
        SystemMessage("Act as a helpful AI assistant"),
        UserMessage("Hello, my name is {{name}}")
    ]
    conversation = render(schema, messages; name = "John", cache = :system)
    expected_output = (;
        system = Dict{String, Any}[Dict(
            "cache_control" => Dict("type" => "ephemeral"),
            "text" => "Act as a helpful AI assistant", "type" => "text")],
        conversation = [Dict("role" => "user",
            "content" => [Dict("type" => "text", "text" => "Hello, my name is John")])])
    @test conversation == expected_output

    conversation = render(schema, messages; name = "John", cache = :last)
    expected_output = (;
        system = "Act as a helpful AI assistant",
        conversation = [Dict("role" => "user",
            "content" => [Dict("type" => "text", "text" => "Hello, my name is John",
                "cache_control" => Dict("type" => "ephemeral"))])])
    @test conversation == expected_output

    ## We mark only user messages
    messages_with_ai = [
        SystemMessage("Act as a helpful AI assistant"),
        UserMessage("Hello, my name is {{name}}"),
        AIMessage("Hi there")
    ]
    conversation = render(schema, messages_with_ai; name = "John", cache = :last)
    expected_output = (;
        system = "Act as a helpful AI assistant",
        conversation = [
            Dict("role" => "user",
                "content" => [Dict("type" => "text", "text" => "Hello, my name is John",
                    "cache_control" => Dict("type" => "ephemeral"))]),
            Dict("role" => "assistant",
                "content" => [Dict("type" => "text", "text" => "Hi there")])])
    @test conversation == expected_output

    conversation = render(schema, messages; name = "John", cache = :all)
    expected_output = (;
        system = Dict{String, Any}[Dict(
            "cache_control" => Dict("type" => "ephemeral"),
            "text" => "Act as a helpful AI assistant", "type" => "text")],
        conversation = [Dict("role" => "user",
            "content" => [Dict("type" => "text", "text" => "Hello, my name is John",
                "cache_control" => Dict("type" => "ephemeral"))])])
    @test conversation == expected_output

    conversation = render(schema, messages_with_ai; name = "John", cache = :all)
    expected_output = (;
        system = Dict{String, Any}[Dict(
            "cache_control" => Dict("type" => "ephemeral"),
            "text" => "Act as a helpful AI assistant", "type" => "text")],
        conversation = [
            Dict("role" => "user",
                "content" => [Dict("type" => "text", "text" => "Hello, my name is John",
                    "cache_control" => Dict("type" => "ephemeral"))]),
            Dict("role" => "assistant",
                "content" => [Dict("type" => "text", "text" => "Hi there")])])
    @test conversation == expected_output

    ## Longer conversation
    messages_longer = [
        SystemMessage("Act as a helpful AI assistant"),
        UserMessage("Hello, my name is {{name}}"),
        AIMessage("Hi there"),
        UserMessage("How are you?"),
        AIMessage("I'm doing well, thank you!")
    ]
    system, conversation = render(schema, messages_longer; name = "John", cache = :all)
    ## marks last user message
    @test conversation[end - 1]["content"][end]["cache_control"] ==
          Dict("type" => "ephemeral")
    ## marks one before last user message
    @test conversation[end - 3]["content"][end]["cache_control"] ==
          Dict("type" => "ephemeral")
    ## marks system message
    @test system[1]["cache_control"] == Dict("type" => "ephemeral")

    ## all_but_last
    system,
    conversation = render(
        schema, messages_longer; name = "John", cache = :all_but_last)
    ## does not mark last user message
    @test !haskey(conversation[end - 1]["content"][end], "cache_control")
    ## marks one before last user message
    @test conversation[end - 3]["content"][end]["cache_control"] ==
          Dict("type" => "ephemeral")
    ## marks system message
    @test system[1]["cache_control"] == Dict("type" => "ephemeral")

    ### aiprefill functionality
    messages = [
        SystemMessage("Act as a helpful AI assistant"),
        UserMessage("Hello, what's your name?")
    ]

    # Test with aiprefill
    conversation = render(schema, messages; aiprefill = "My name is Claude")
    expected_output = (;
        system = "Act as a helpful AI assistant",
        conversation = [
            Dict("role" => "user",
                "content" => [Dict("type" => "text", "text" => "Hello, what's your name?")]),
            Dict("role" => "assistant",
                "content" => [Dict("type" => "text", "text" => "My name is Claude")])
        ])
    @test conversation == expected_output

    # Test without aiprefill
    conversation_without_prefill = render(schema, messages)
    expected_output_without_prefill = (;
        system = "Act as a helpful AI assistant",
        conversation = [
            Dict("role" => "user",
            "content" => [Dict("type" => "text", "text" => "Hello, what's your name?")])
        ])
    @test conversation_without_prefill == expected_output_without_prefill

    # Test with empty aiprefill
    conversation_empty_prefill = render(schema, messages; aiprefill = "")
    @test conversation_empty_prefill == expected_output_without_prefill

    # Test aiprefill with cache
    conversation_with_cache = render(
        schema, messages; aiprefill = "My name is Claude", cache = :all)
    expected_output_with_cache = (;
        system = Dict{String, Any}[Dict(
            "cache_control" => Dict("type" => "ephemeral"),
            "text" => "Act as a helpful AI assistant", "type" => "text")],
        conversation = [
            Dict("role" => "user",
                "content" => [Dict("type" => "text", "text" => "Hello, what's your name?",
                    "cache_control" => Dict("type" => "ephemeral"))]),
            Dict("role" => "assistant",
                "content" => [Dict("type" => "text", "text" => "My name is Claude")])
        ])
    @test conversation_with_cache == expected_output_with_cache
end

@testset "render-tools for Anthropic" begin
    schema = AnthropicSchema()

    # Test rendering a single tool
    tool = Tool(
        name = "get_weather",
        description = "Get the current weather in a given location",
        parameters = Dict(
            "type" => "object",
            "properties" => Dict(
                "location" => Dict("type" => "string"),
                "unit" => Dict("type" => "string", "enum" => ["celsius", "fahrenheit"])
            ),
            "required" => ["location"]
        ),
        callable = identity
    )

    rendered = render(schema, [tool])
    @test length(rendered) == 1
    @test rendered[1][:name] == "get_weather"
    @test rendered[1][:description] == "Get the current weather in a given location"
    @test rendered[1][:input_schema] == tool.parameters

    # Test rendering multiple tools
    tool2 = Tool(
        name = "get_time",
        description = "Get the current time in a given timezone",
        parameters = Dict(
            "type" => "object",
            "properties" => Dict(
                "timezone" => Dict("type" => "string")
            ),
            "required" => ["timezone"]
        ),
        callable = identity
    )

    rendered = render(schema, [tool, tool2])
    @test length(rendered) == 2
    @test rendered[1][:name] == "get_weather"
    @test rendered[2][:name] == "get_time"

    # Test rendering with no description
    tool_no_desc = PromptingTools.Tool(
        name = "no_description_tool",
        parameters = Dict(
            "type" => "object",
            "properties" => Dict(
                "input" => Dict("type" => "string")
            ),
            "required" => ["input"]
        ),
        callable = identity
    )

    rendered = render(schema, [tool_no_desc])
    @test rendered[1][:description] == ""

    # From from dictionary of tools
    tool_map = Dict("get_weather" => tool, "get_time" => tool2)
    rendered = render(schema, tool_map)
    @test length(rendered) == 2
    @test Set(t[:name] for t in rendered) == Set(["get_weather", "get_time"])

    ## ToolRef
    schema = AnthropicSchema()

    # Test computer tool rendering
    computer_tool = ToolRef(ref = :computer)
    rendered = render(schema, computer_tool)
    @test rendered["type"] == "computer_20241022"
    @test rendered["name"] == "computer"
    @test rendered["display_width_px"] == 1024
    @test rendered["display_height_px"] == 768
    @test !haskey(rendered, "display_number")

    computer_tool2 = ToolRef(ref = :computer,
        extras = Dict("display_width_px" => 1920,
            "display_height_px" => 1080, "display_number" => 1))
    rendered = render(schema, computer_tool2)
    @test rendered["type"] == "computer_20241022"
    @test rendered["name"] == "computer"
    @test rendered["display_width_px"] == 1920
    @test rendered["display_height_px"] == 1080
    @test rendered["display_number"] == 1

    # Test text editor tool rendering
    editor_tool = ToolRef(ref = :str_replace_editor)
    rendered = render(schema, editor_tool)
    @test rendered["type"] == "text_editor_20250124"
    @test rendered["name"] == "str_replace_editor"

    # Test bash tool rendering
    bash_tool = ToolRef(ref = :bash)
    rendered = render(schema, bash_tool)
    @test rendered["type"] == "bash_20241022"
    @test rendered["name"] == "bash"

    # Test code execution tool rendering
    code_exec_tool = ToolRef(ref = :code_execution)
    rendered = render(schema, code_exec_tool)
    @test rendered["type"] == "code_execution_20250522"
    @test rendered["name"] == "code_execution"

    # Test web search tool rendering
    web_search_tool = ToolRef(ref = :web_search)
    rendered = render(schema, web_search_tool)
    @test rendered["type"] == "web_search_20250305"
    @test rendered["name"] == "web_search"

    # Test web search tool with custom max_uses
    web_search_tool_custom = ToolRef(ref = :web_search, extras = Dict("max_uses" => 10))
    rendered = render(schema, web_search_tool_custom)
    @test rendered["type"] == "web_search_20250305"
    @test rendered["name"] == "web_search"
    @test rendered["max_uses"] == 10

    # Test invalid tool reference
    @test_throws ArgumentError render(schema, ToolRef(ref = :invalid_tool))

    # Test rendering multiple tool refs
    tools = [computer_tool, editor_tool, bash_tool, code_exec_tool, web_search_tool]
    rendered = render(schema, tools)
    @test length(rendered) == 5
    @test rendered[1]["name"] == "computer"
    @test rendered[2]["name"] == "str_replace_editor"
    @test rendered[3]["name"] == "bash"
    @test rendered[4]["name"] == "code_execution"
    @test rendered[5]["name"] == "web_search"
end

@testset "anthropic_extra_headers" begin
    @test anthropic_extra_headers() == ["anthropic-version" => "2023-06-01"]

    @test anthropic_extra_headers(has_tools = true) == [
        "anthropic-version" => "2023-06-01",
        "anthropic-beta" => "tools-2024-04-04"
    ]

    @test anthropic_extra_headers(has_cache = true) == [
        "anthropic-version" => "2023-06-01",
        "anthropic-beta" => "prompt-caching-2024-07-31"
    ]

    @test anthropic_extra_headers(has_tools = true, has_cache = true) == [
        "anthropic-version" => "2023-06-01",
        "anthropic-beta" => "tools-2024-04-04,prompt-caching-2024-07-31"
    ]
    @test anthropic_extra_headers(
        has_tools = true, has_cache = true, has_long_output = true) == [
        "anthropic-version" => "2023-06-01",
        "anthropic-beta" => "tools-2024-04-04,prompt-caching-2024-07-31,max-tokens-3-5-sonnet-2024-07-15"
    ]

    # Test with betas
    @test anthropic_extra_headers(betas = [:tools]) == [
        "anthropic-version" => "2023-06-01",
        "anthropic-beta" => "tools-2024-04-04"
    ]

    @test anthropic_extra_headers(betas = [:cache]) == [
        "anthropic-version" => "2023-06-01",
        "anthropic-beta" => "prompt-caching-2024-07-31"
    ]

    @test anthropic_extra_headers(betas = [:long_output]) == [
        "anthropic-version" => "2023-06-01",
        "anthropic-beta" => "max-tokens-3-5-sonnet-2024-07-15"
    ]

    @test anthropic_extra_headers(betas = [:computer_use]) == [
        "anthropic-version" => "2023-06-01",
        "anthropic-beta" => "computer-use-2024-10-22"
    ]

    # Test multiple betas
    @test anthropic_extra_headers(betas = [:tools, :cache, :computer_use]) == [
        "anthropic-version" => "2023-06-01",
        "anthropic-beta" => "tools-2024-04-04,prompt-caching-2024-07-31,computer-use-2024-10-22"
    ]

    # Test all betas
    @test anthropic_extra_headers(betas = BETA_HEADERS_ANTHROPIC) ==
          ["anthropic-version" => "2023-06-01",
        "anthropic-beta" => "tools-2024-04-04,prompt-caching-2024-07-31,max-tokens-3-5-sonnet-2024-07-15,output-128k-2025-02-19,computer-use-2024-10-22"]

    # Test invalid beta
    @test_throws AssertionError anthropic_extra_headers(betas = [:invalid_beta])

    # Test mixing has_* flags with betas
    @test anthropic_extra_headers(has_tools = true, betas = [:cache]) == [
        "anthropic-version" => "2023-06-01",
        "anthropic-beta" => "tools-2024-04-04,prompt-caching-2024-07-31"
    ]
end

@testset "anthropic_api" begin
    # Invalid endpoint
    @test_throws AssertionError anthropic_api(
        AnthropicSchema(); api_key = "abc", endpoint = "embedding")

    # Invalid API key
    e = try
        anthropic_api(AnthropicSchema(); api_key = "abc")
    catch e
        e
    end
    @test e.status == 401
    s = String(e.response.body)
    @test occursin("authentication_error", s)
    @test occursin("invalid x-api-key", s)
end

@testset "aigenerate-Anthropic" begin
    # corresponds to Anthropic version 2023 June, v1
    response = Dict(
        :content => [
            Dict(:text => "Hello!")],
        :stop_reason => "stop",
        :usage => Dict(:input_tokens => 2, :output_tokens => 1))

    # Real generation API
    schema1 = TestEchoAnthropicSchema(; response, status = 200)
    msg = aigenerate(schema1, "Hello World"; model = "claudeo")
    expected_output = AIMessage(;
        content = "Hello!" |> strip,
        status = 200,
        tokens = (2, 1),
        finish_reason = "stop",
        cost = msg.cost,
        extras = Dict{Symbol, Any}(),
        elapsed = msg.elapsed)
    @test msg == expected_output
    @test schema1.inputs.system == "Act as a helpful AI assistant"
    @test schema1.inputs.messages == [Dict(
        "role" => "user", "content" => [Dict("type" => "text", "text" => "Hello World")])]
    @test schema1.model_id == "claude-opus-4-20250514"

    # Test different input combinations and different prompts
    schema2 = TestEchoAnthropicSchema(; response, status = 200)
    msg = aigenerate(schema2, UserMessage("Hello {{name}}"),
        model = "claudes", http_kwargs = (; verbose = 3), api_kwargs = (; temperature = 0),
        name = "World")
    expected_output = AIMessage(;
        content = "Hello!" |> strip,
        status = 200,
        tokens = (2, 1),
        finish_reason = "stop",
        cost = msg.cost,
        extras = Dict{Symbol, Any}(),
        elapsed = msg.elapsed)
    @test msg == expected_output
    @test schema2.inputs.system == "Act as a helpful AI assistant"
    @test schema2.inputs.messages == [Dict(
        "role" => "user", "content" => [Dict("type" => "text", "text" => "Hello World")])]
    @test schema2.model_id == "claude-sonnet-4-20250514"

    # Test aiprefill functionality
    schema2 = TestEchoAnthropicSchema(;
        response = Dict(
            :content => [Dict(:text => "The answer is 42")],
            :stop_reason => "stop",
            :usage => Dict(:input_tokens => 5, :output_tokens => 4)),
        status = 200)

    aiprefill = "The answer to the ultimate question of life, the universe, and everything is:"
    msg = aigenerate(schema2, UserMessage("What is the answer to everything?"),
        model = "claudes", http_kwargs = (; verbose = 3), api_kwargs = (; temperature = 0),
        aiprefill = aiprefill)

    expected_output = AIMessage(;
        content = aiprefill * "The answer is 42" |> strip,
        status = 200,
        tokens = (5, 4),
        finish_reason = "stop",
        cost = msg.cost,
        run_id = msg.run_id,
        sample_id = msg.sample_id,
        extras = Dict{Symbol, Any}(),
        elapsed = msg.elapsed)

    @test msg.content == expected_output.content
    @test schema2.inputs.system == "Act as a helpful AI assistant"
    @test schema2.inputs.messages == [
        Dict("role" => "user",
            "content" => [Dict(
                "type" => "text", "text" => "What is the answer to everything?")]),
        Dict("role" => "assistant",
            "content" => [Dict("type" => "text", "text" => aiprefill)])
    ]
    @test schema2.model_id == "claude-sonnet-4-20250514"

    # With caching
    response3 = Dict(
        :content => [
            Dict(:text => "Hello!")],
        :stop_reason => "stop",
        :usage => Dict(:input_tokens => 2, :output_tokens => 1,
            :cache_creation_input_tokens => 1, :cache_read_input_tokens => 0))

    schema3 = TestEchoAnthropicSchema(; response = response3, status = 200)
    msg = aigenerate(schema3, UserMessage("Hello {{name}}"),
        model = "claudes", http_kwargs = (; verbose = 3), api_kwargs = (; temperature = 0),
        cache = :all,
        name = "World")
    expected_output = AIMessage(;
        content = "Hello!" |> strip,
        status = 200,
        tokens = (2, 1),
        finish_reason = "stop",
        cost = msg.cost,
        extras = Dict{Symbol, Any}(
            :cache_read_input_tokens => 0, :cache_creation_input_tokens => 1),
        elapsed = msg.elapsed)
    @test msg == expected_output
    @test schema3.inputs.system == [Dict("cache_control" => Dict("type" => "ephemeral"),
        "text" => "Act as a helpful AI assistant", "type" => "text")]
    @test schema3.inputs.messages == [Dict("role" => "user",
        "content" => Dict{String, Any}[Dict("cache_control" => Dict("type" => "ephemeral"),
            "text" => "Hello World", "type" => "text")])]
    @test schema3.model_id == "claude-sonnet-4-20250514"

    ## Bad cache
    @test_throws AssertionError aigenerate(
        schema3, UserMessage("Hello {{name}}"); model = "claudeo", cache = :bad)

    # Test error throw if aiprefill is empty string
    @test_throws AssertionError aigenerate(
        AnthropicSchema(),
        "Hello World";
        model = "claudeh",
        aiprefill = ""
    )

    @test_throws AssertionError aigenerate(
        AnthropicSchema(),
        "Hello World";
        model = "claudeh",
        aiprefill = "   "  # Only whitespace
    )
end

@testset "aiextract-Anthropic" begin
    # corresponds to Anthropic version 2023 June, v1 // tool beta!
    struct Fruit
        name::String
    end
    response = Dict(
        :content => [
            Dict(:type => "tool_use", :id => "1", :name => "Fruit",
            :input => Dict("name" => "banana"))],
        :stop_reason => "tool_use",
        :usage => Dict(:input_tokens => 2, :output_tokens => 1))

    # Real generation API
    schema1 = TestEchoAnthropicSchema(; response, status = 200)
    msg = aiextract(schema1, "Hello World! Banana"; model = "claudeo", return_type = Fruit)
    expected_output = DataMessage(;
        content = Fruit("banana"),
        status = 200,
        tokens = (2, 1),
        finish_reason = "tool_use",
        cost = msg.cost,
        extras = Dict{Symbol, Any}(),
        elapsed = msg.elapsed)
    @test msg == expected_output
    @test schema1.inputs.system ==
          "Act as a helpful AI assistant"
    @test schema1.inputs.messages ==
          [Dict("role" => "user",
        "content" => Dict{String, Any}[Dict(
            "text" => "Hello World! Banana", "type" => "text")])]
    @test schema1.model_id == "claude-opus-4-20250514"

    # Test badly formatted response
    response = Dict(
        :content => [
            Dict(:type => "tool_use", :id => "1", :name => "Fruit",
            :input => Dict("namexxx" => "banana"))],
        :stop_reason => "tool_use",
        :usage => Dict(:input_tokens => 2, :output_tokens => 1))
    schema2 = TestEchoAnthropicSchema(; response, status = 200)
    msg = aiextract(schema2, "Hello World! Banana"; model = "claudeo", return_type = Fruit)
    @test msg.content isa AbstractDict
    @test msg.content[:namexxx] == "banana"

    # Bad finish reason
    response = Dict(
        :content => [
            Dict(:type => "text", :text => "No tools for you!")],
        :stop_reason => "stop",
        :usage => Dict(:input_tokens => 2, :output_tokens => 1))
    schema3 = TestEchoAnthropicSchema(; response, status = 200)
    msg = aiextract(schema3, "Hello World! Banana"; model = "claudeo", return_type = Fruit)
    @test msg.content == "No tools for you!"

    # With Cache
    response4 = Dict(
        :content => [
            Dict(:type => "tool_use", :id => "1", :name => "Fruit",
            :input => Dict("name" => "banana"))],
        :stop_reason => "tool_use",
        :usage => Dict(:input_tokens => 2, :output_tokens => 1,
            :cache_creation_input_tokens => 1, :cache_read_input_tokens => 0))
    schema4 = TestEchoAnthropicSchema(; response = response4, status = 200)
    msg = aiextract(
        schema4, "Hello World! Banana"; model = "claudeo", return_type = Fruit, cache = :all)
    expected_output = DataMessage(;
        content = Fruit("banana"),
        status = 200,
        tokens = (2, 1),
        finish_reason = "tool_use",
        cost = msg.cost,
        extras = Dict{Symbol, Any}(
            :cache_read_input_tokens => 0, :cache_creation_input_tokens => 1),
        elapsed = msg.elapsed)
    @test msg == expected_output

    # Bad cache
    @test_throws AssertionError aiextract(
        schema4, "Hello World! Banana"; model = "claudeo",
        return_type = Fruit, cache = :bad)
end

@testset "aitools-Anthropic" begin
    # Define a test tool
    struct WeatherTool
        location::String
        date::String
    end

    # Mock response for a single tool call
    single_tool_response = Dict(
        :content => [
            Dict(:type => "tool_use", :id => "123", :name => "get_weather",
            :input => Dict(:location => "New York", :date => "2023-05-01"))
        ],
        :stop_reason => "tool_use",
        :usage => Dict(:input_tokens => 15, :output_tokens => 5)
    )

    schema_single = TestEchoAnthropicSchema(; response = single_tool_response, status = 200)

    msg_single = aitools(schema_single, "What's the weather in New York on May 1st, 2023?";
        tools = [Tool(; name = "get_weather", callable = WeatherTool)],
        model = "claudeh",
        api_kwargs = (; temperature = 0))

    @test isaitoolrequest(msg_single)
    @test msg_single.tool_calls[1].tool_call_id == "123"
    @test msg_single.tool_calls[1].name == "get_weather"
    @test msg_single.tool_calls[1].args[:location] == "New York"
    @test msg_single.tool_calls[1].args[:date] == "2023-05-01"
    @test msg_single.tokens == (15, 5)

    # Mock response for multiple tool calls
    multi_tool_response = Dict(
        :content => [
            Dict(:type => "tool_use", :id => "123", :name => "get_weatherUS",
                :input => Dict(:location => "New York", :date => "2023-05-01")),
            Dict(:type => "tool_use", :id => "456", :name => "get_weatherUK",
                :input => Dict(:location => "London", :date => "2023-05-02"))
        ],
        :stop_reason => "tool_use",
        :usage => Dict(:input_tokens => 20, :output_tokens => 10)
    )

    schema_multi = TestEchoAnthropicSchema(; response = multi_tool_response, status = 200)

    msg_multi = aitools(
        schema_multi, "Compare the weather in New York on May 1st and London on May 2nd, 2023.";
        tools = [Tool(; name = "get_weatherUS", callable = WeatherTool),
            Tool(; name = "get_weatherUK", callable = WeatherTool)],
        model = "claudeh",
        api_kwargs = (; temperature = 0))

    @test isaitoolrequest(msg_multi)
    @test length(msg_multi.tool_calls) == 2
    @test msg_multi.tool_calls[1].tool_call_id == "123"
    @test msg_multi.tool_calls[1].name == "get_weatherUS"
    @test msg_multi.tool_calls[1].args[:location] == "New York"
    @test msg_multi.tool_calls[1].args[:date] == "2023-05-01"
    @test msg_multi.tool_calls[2].tool_call_id == "456"
    @test msg_multi.tool_calls[2].name == "get_weatherUK"
    @test msg_multi.tool_calls[2].args[:location] == "London"
    @test msg_multi.tool_calls[2].args[:date] == "2023-05-02"
    @test msg_multi.tokens == (20, 10)

    # Test with dry_run
    msg_dry_run = aitools(schema_single, "What's the weather in Paris tomorrow?";
        tools = [Tool(; name = "get_weather", callable = WeatherTool)],
        model = "claudeh",
        dry_run = true)

    @test msg_dry_run === nothing

    # Test with return_all
    msg_return_all = aitools(
        schema_single, "What's the weather in New York on May 1st, 2023?";
        tools = [Tool(; name = "get_weather", callable = WeatherTool)],
        model = "claudeh",
        return_all = true,
        api_kwargs = (; temperature = 0))

    @test msg_return_all isa Vector
    @test length(msg_return_all) == 3
    @test msg_return_all[1] isa SystemMessage
    @test msg_return_all[2] isa UserMessage
    @test isaitoolrequest(msg_return_all[3])
    @test msg_return_all[end].tool_calls[1].name == "get_weather"
    @test msg_return_all[end].tool_calls[1].args[:location] == "New York"
    @test msg_return_all[end].tool_calls[1].args[:date] == "2023-05-01"

    # Test with cache
    cache_response = Dict(
        :content => [
            Dict(:type => "tool_use", :id => "123", :name => "get_weather",
            :input => Dict(:location => "Tokyo", :date => "2023-05-03"))
        ],
        :stop_reason => "tool_use",
        :usage => Dict(:input_tokens => 18, :output_tokens => 7,
            :cache_creation_input_tokens => 1, :cache_read_input_tokens => 0)
    )

    schema_cache = TestEchoAnthropicSchema(; response = cache_response, status = 200)

    msg_cache = aitools(schema_cache, "What's the weather in Tokyo on May 3rd, 2023?";
        tools = [Tool(; name = "get_weather", callable = WeatherTool)],
        model = "claudeh",
        cache = :all,
        api_kwargs = (; temperature = 0))

    @test msg_cache.tool_calls[1].tool_call_id == "123"
    @test msg_cache.tool_calls[1].name == "get_weather"
    @test msg_cache.tool_calls[1].args[:location] == "Tokyo"
    @test msg_cache.tool_calls[1].args[:date] == "2023-05-03"
    @test msg_cache.tokens == (18, 7)
    @test msg_cache.extras[:cache_creation_input_tokens] == 1
    @test msg_cache.extras[:cache_read_input_tokens] == 0

    # Test with invalid cache
    @test_throws AssertionError aitools(schema_cache, "What's the weather in Tokyo?";
        tools = [Tool(; name = "get_weather", callable = WeatherTool)],
        model = "claudeh",
        cache = :invalid)
end

@testset "not implemented ai* functions" begin
    @test_throws ErrorException aiembed(AnthropicSchema(), "prompt")
    @test_throws ErrorException aiclassify(AnthropicSchema(), "prompt")
    @test_throws ErrorException aiscan(AnthropicSchema(), "prompt")
    @test_throws ErrorException aiimage(AnthropicSchema(), "prompt")
end

@testset "Anthropic thinking budget validation" begin
    # Test that an assertion error is thrown when thinking budget exceeds max_tokens
    @test_throws AssertionError PromptingTools.anthropic_api(
        PromptingTools.AnthropicSchema(),
        [Dict("role" => "user", "content" => [Dict("type" => "text", "text" => "Hello")])];
        model = "claude-3-haiku-20240307",
        max_tokens = 100,
        thinking = Dict(:type => "enabled", :budget_tokens => 200)
    )

    # Set up a dummy response for the test echo schema
    dummy_response = Dict(
        "content" => [Dict("text" => "Test response", "type" => "text")],
        "model" => "claude-3-haiku-20240307",
        "id" => "test-id",
        "type" => "message",
        "role" => "assistant",
        "stop_reason" => "end_turn",
        "usage" => Dict("input_tokens" => 10, "output_tokens" => 20)
    )

    # Test that no error is thrown when thinking budget is equal to max_tokens
    try
        PromptingTools.anthropic_api(
            PromptingTools.TestEchoAnthropicSchema(
                response = dummy_response,
                status = 200
            ),
            [Dict("role" => "user",
                "content" => [Dict("type" => "text", "text" => "Hello")])];
            model = "claude-3-haiku-20240307",
            max_tokens = 100,
            thinking = Dict(:type => "enabled", :budget_tokens => 100)
        )
        @test true  # No exception thrown
    catch e
        @test false  # Should not reach here
    end

    # Test that no error is thrown when thinking budget is less than max_tokens
    try
        PromptingTools.anthropic_api(
            PromptingTools.TestEchoAnthropicSchema(
                response = dummy_response,
                status = 200
            ),
            [Dict("role" => "user",
                "content" => [Dict("type" => "text", "text" => "Hello")])];
            model = "claude-3-haiku-20240307",
            max_tokens = 100,
            thinking = Dict(:type => "enabled", :budget_tokens => 50)
        )
        @test true  # No exception thrown
    catch e
        @test false  # Should not reach here
    end
end
