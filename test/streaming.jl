using PromptingTools: StreamCallback, StreamChunk, OpenAIStream, AnthropicStream,
                      configure_callback!
using PromptingTools: is_done, extract_chunks, extract_content, print_content, callback,
                      build_response_body, streamed_request!
using PromptingTools: OpenAISchema, AnthropicSchema, GoogleSchema

@testset "StreamCallback" begin
    # Test default constructor
    cb = StreamCallback()
    @test cb.out == stdout
    @test isnothing(cb.flavor)
    @test isempty(cb.chunks)
    @test cb.verbose == false
    @test cb.throw_on_error == false
    @test isempty(cb.kwargs)

    # Test custom constructor
    custom_out = IOBuffer()
    custom_flavor = OpenAIStream()
    custom_chunks = [StreamChunk(event = :test, data = "test data")]
    custom_cb = StreamCallback(;
        out = custom_out,
        flavor = custom_flavor,
        chunks = custom_chunks,
        verbose = true,
        throw_on_error = true,
        kwargs = (custom_key = "custom_value",)
    )
    @test custom_cb.out == custom_out
    @test custom_cb.flavor == custom_flavor
    @test custom_cb.chunks == custom_chunks
    @test custom_cb.verbose == true
    @test custom_cb.throw_on_error == true
    @test custom_cb.kwargs == (custom_key = "custom_value",)

    # Test Base methods
    cb = StreamCallback()
    @test isempty(cb)
    push!(cb, StreamChunk(event = :test, data = "test data"))
    @test length(cb) == 1
    @test !isempty(cb)
    empty!(cb)
    @test isempty(cb)

    # Test show method
    cb = StreamCallback(out = IOBuffer(), flavor = OpenAIStream())
    str = sprint(show, cb)
    @test occursin("StreamCallback(out=IOBuffer", str)
    @test occursin("flavor=OpenAIStream()", str)
    @test occursin("silent, no_throw", str)

    chunk = StreamChunk(event = :test, data = "{\"a\": 1}", json = JSON3.read("{\"a\": 1}"))
    str = sprint(show, chunk)
    @test occursin("StreamChunk(event=test", str)
    @test occursin("data={\"a\": 1}", str)
    @test occursin("json keys=a", str)

    push!(cb, chunk)
    @test length(cb) == 1
    @test !isempty(cb)
    empty!(cb)
    @test isempty(cb)

    # Test configure_callback! method
    cb, api_kwargs = configure_callback!(StreamCallback(), OpenAISchema())
    @test cb.flavor isa OpenAIStream
    @test api_kwargs[:stream] == true
    @test api_kwargs[:stream_options] == (include_usage = true,)

    cb, api_kwargs = configure_callback!(StreamCallback(), AnthropicSchema())
    @test cb.flavor isa AnthropicStream
    @test api_kwargs[:stream] == true

    # Test error for unsupported schema
    @test_throws ErrorException configure_callback!(StreamCallback(), GoogleSchema())

    # Test configure_callback! with output stream
    cb, _ = configure_callback!(IOBuffer(), OpenAISchema())
    @test cb isa StreamCallback
    @test cb.out isa IOBuffer
    @test cb.flavor isa OpenAIStream
end

@testset "is_done" begin
    # Test OpenAIStream
    openai_flavor = PT.OpenAIStream()

    # Test when streaming is done
    done_chunk = PT.StreamChunk(data = "[DONE]")
    @test PT.is_done(openai_flavor, done_chunk) == true

    # Test when streaming is not done
    not_done_chunk = PT.StreamChunk(data = "Some content")
    @test PT.is_done(openai_flavor, not_done_chunk) == false

    # Test with empty data
    empty_chunk = PT.StreamChunk(data = "")
    @test PT.is_done(openai_flavor, empty_chunk) == false

    # Test AnthropicStream
    anthropic_flavor = PT.AnthropicStream()

    # Test when streaming is done due to error
    error_chunk = PT.StreamChunk(event = :error)
    @test PT.is_done(anthropic_flavor, error_chunk) == true

    # Test when streaming is done due to message stop
    stop_chunk = PT.StreamChunk(event = :message_stop)
    @test PT.is_done(anthropic_flavor, stop_chunk) == true

    # Test when streaming is not done
    continue_chunk = PT.StreamChunk(event = :content_block_start)
    @test PT.is_done(anthropic_flavor, continue_chunk) == false

    # Test with nil event
    nil_event_chunk = PT.StreamChunk(event = nothing)
    @test PT.is_done(anthropic_flavor, nil_event_chunk) == false

    # Test with unsupported flavor
    struct UnsupportedFlavor <: PT.AbstractStreamFlavor end
    unsupported_flavor = UnsupportedFlavor()
    @test_throws ArgumentError PT.is_done(unsupported_flavor, PT.StreamChunk())
end

@testset "extract_content" begin
    # Test OpenAIStream
    openai_flavor = PT.OpenAIStream()

    # Test with valid JSON content
    valid_json_chunk = PT.StreamChunk(
        json = JSON3.read("""
        {
            "choices": [
                {
                    "delta": {
                        "content": "Hello, world!"
                    }
                }
            ]
        }
        """)
    )
    @test PT.extract_content(openai_flavor, valid_json_chunk) == "Hello, world!"

    # Test with empty choices
    empty_choices_chunk = PT.StreamChunk(
        json = JSON3.read("""
        {
            "choices": []
        }
        """)
    )
    @test isnothing(PT.extract_content(openai_flavor, empty_choices_chunk))

    # Test with missing delta
    missing_delta_chunk = PT.StreamChunk(
        json = JSON3.read("""
        {
            "choices": [
                {
                    "index": 0
                }
            ]
        }
        """)
    )
    @test isnothing(PT.extract_content(openai_flavor, missing_delta_chunk))

    # Test with missing content in delta
    missing_content_chunk = PT.StreamChunk(
        json = JSON3.read("""
        {
            "choices": [
                {
                    "delta": {
                        "role": "assistant"
                    }
                }
            ]
        }
        """)
    )
    @test isnothing(PT.extract_content(openai_flavor, missing_content_chunk))

    # Test with non-JSON chunk
    non_json_chunk = PT.StreamChunk(data = "Plain text")
    @test isnothing(PT.extract_content(openai_flavor, non_json_chunk))

    # Test AnthropicStream
    anthropic_flavor = PT.AnthropicStream()

    # Test with valid content block
    valid_anthropic_chunk = PT.StreamChunk(
        json = JSON3.read("""
        {
            "content_block": {
                "text": "Hello from Anthropic!"
            }
        }
        """)
    )
    @test PT.extract_content(anthropic_flavor, valid_anthropic_chunk) ==
          "Hello from Anthropic!"

    # Test with valid delta
    valid_delta_chunk = PT.StreamChunk(
        json = JSON3.read("""
        {
            "delta": {
                "text": "Delta text"
            }
        }
        """)
    )
    @test PT.extract_content(anthropic_flavor, valid_delta_chunk) == "Delta text"

    # Test with missing text in content block
    missing_text_chunk = PT.StreamChunk(
        json = JSON3.read("""
        {
            "content_block": {
                "type": "text"
            }
        }
        """)
    )
    @test isnothing(PT.extract_content(anthropic_flavor, missing_text_chunk))

    # Test with non-zero index (should return nothing)
    non_zero_index_chunk = PT.StreamChunk(
        json = JSON3.read("""
        {
            "index": 1,
            "content_block": {
                "text": "This should be ignored"
            }
        }
        """)
    )
    @test isnothing(PT.extract_content(anthropic_flavor, non_zero_index_chunk))

    # Test with non-JSON chunk for Anthropic
    non_json_anthropic_chunk = PT.StreamChunk(data = "Plain Anthropic text")
    @test isnothing(PT.extract_content(anthropic_flavor, non_json_anthropic_chunk))

    # Test with unsupported flavor
    struct UnsupportedFlavor <: PT.AbstractStreamFlavor end
    unsupported_flavor = UnsupportedFlavor()
    @test_throws ArgumentError PT.extract_content(unsupported_flavor, PT.StreamChunk())
end

@testset "extract_chunks" begin
    # Test basic functionality
    blob = "event: start\ndata: {\"key\": \"value\"}\n\nevent: end\ndata: {\"status\": \"complete\"}\n\n"
    chunks, spillover = PT.extract_chunks(PT.OpenAIStream(), blob)
    @test length(chunks) == 2
    @test chunks[1].event == :start
    @test chunks[1].json == JSON3.read("{\"key\": \"value\"}")
    @test chunks[2].event == :end
    @test chunks[2].json == JSON3.read("{\"status\": \"complete\"}")
    @test spillover == ""

    # Test with spillover
    blob_with_spillover = "event: start\ndata: {\"key\": \"value\"}\n\nevent: continue\ndata: {\"partial\": \"data"
    @test_logs (:info, r"Incomplete message detected") chunks, spillover=PT.extract_chunks(
        PT.OpenAIStream(), blob_with_spillover; verbose = true)
    chunks, spillover = PT.extract_chunks(
        PT.OpenAIStream(), blob_with_spillover; verbose = true)
    @test length(chunks) == 1
    @test chunks[1].event == :start
    @test chunks[1].json == JSON3.read("{\"key\": \"value\"}")
    @test spillover == "{\"partial\": \"data"

    # Test with incoming spillover
    incoming_spillover = spillover
    blob_after_spillover = "\"}\n\nevent: end\ndata: {\"status\": \"complete\"}\n\n"
    chunks, spillover = PT.extract_chunks(
        PT.OpenAIStream(), blob_after_spillover; spillover = incoming_spillover)
    @test length(chunks) == 2
    @test chunks[1].json == JSON3.read("{\"partial\": \"data\"}")
    @test chunks[2].event == :end
    @test chunks[2].json == JSON3.read("{\"status\": \"complete\"}")
    @test spillover == ""

    # Test with multiple data fields per event
    multi_data_blob = "event: multi\ndata: line1\ndata: line2\n\n"
    chunks, spillover = PT.extract_chunks(PT.OpenAIStream(), multi_data_blob)
    @test length(chunks) == 1
    @test chunks[1].event == :multi
    @test chunks[1].data == "line1line2"

    # Test with non-JSON data
    non_json_blob = "event: text\ndata: This is plain text\n\n"
    chunks, spillover = PT.extract_chunks(PT.OpenAIStream(), non_json_blob)
    @test length(chunks) == 1
    @test chunks[1].event == :text
    @test chunks[1].data == "This is plain text"
    @test isnothing(chunks[1].json)

    # Test with empty blob
    empty_blob = ""
    chunks, spillover = PT.extract_chunks(PT.OpenAIStream(), empty_blob)
    @test isempty(chunks)
    @test spillover == ""

    # Test with malformed JSON
    malformed_json_blob = "event: error\ndata: {\"key\": \"value\",}\n\n"
    chunks, spillover = PT.extract_chunks(
        PT.OpenAIStream(), malformed_json_blob; verbose = true)
    @test length(chunks) == 1
    @test chunks[1].event == :error
    @test chunks[1].data == "{\"key\": \"value\",}"
    @test isnothing(chunks[1].json)

    # Test with multiple data fields, no event
    blob_no_event = "data: {\"key\": \"value\"}\n\ndata: {\"partial\": \"data\"}\n\ndata: {\"status\": \"complete\"}\n\n"
    chunks, spillover = PT.extract_chunks(PT.OpenAIStream(), blob_no_event)
    @test length(chunks) == 3
    @test chunks[1].data == "{\"key\": \"value\"}"
    @test chunks[2].data == "{\"partial\": \"data\"}"
    @test chunks[3].data == "{\"status\": \"complete\"}"
    @test spillover == ""

    # Test case for s1: Multiple events and data chunks
    s1 = """event: test
    data: {"id":"chatcmpl-A3zvq9GWhji7h1Gz0gKNIn9r2tABJ","object":"chat.completion.chunk","created":1725516414,"model":"gpt-4o-mini-2024-07-18","system_fingerprint":"fp_f905cf32a9","choices":[{"index":0,"delta":{"content":","},"logprobs":null,"finish_reason":null}]}

    event: test2
    data: {"id":"chatcmpl-A3zvq9GWhji7h1Gz0gKNIn9r2tABJ","object":"chat.completion.chunk","created":1725516414,"model":"gpt-4o-mini-2024-07-18","system_fingerprint":"fp_f905cf32a9","choices":[{"index":0,"delta":{"content":" "},"logprobs":null,"finish_reason":null}]}

    data: [DONE]

    """
    chunks, spillover = PT.extract_chunks(PT.OpenAIStream(), s1)
    @test length(chunks) == 3
    @test chunks[1].event == :test
    @test chunks[2].event == :test2
    @test chunks[3].data == "[DONE]"
    @test spillover == ""

    @test PT.extract_content(PT.OpenAIStream(), chunks[1]) == ","
    @test PT.extract_content(PT.OpenAIStream(), chunks[2]) == " "

    # Test case for s2: Multiple data chunks without events
    s2 = """data: {"id":"chatcmpl-A3zvq9GWhji7h1Gz0gKNIn9r2tABJ","object":"chat.completion.chunk","created":1725516414,"model":"gpt-4o-mini-2024-07-18","system_fingerprint":"fp_f905cf32a9","choices":[{"index":0,"delta":{"content":","},"logprobs":null,"finish_reason":null}]}

      data: {"id":"chatcmpl-A3zvq9GWhji7h1Gz0gKNIn9r2tABJ","object":"chat.completion.chunk","created":1725516414,"model":"gpt-4o-mini-2024-07-18","system_fingerprint":"fp_f905cf32a9","choices":[{"index":0,"delta":{"content":" "},"logprobs":null,"finish_reason":null}]}

      data: [DONE]

      """
    chunks, spillover = PT.extract_chunks(PT.OpenAIStream(), s2)
    @test length(chunks) == 3
    @test all(chunk.event === nothing for chunk in chunks)
    @test chunks[3].data == "[DONE]"
    @test spillover == ""

    # Test case for s3: Simple data chunks
    s3 = """data: a
    data: b
    data: c

    data: [DONE]

    """
    chunks, spillover = PT.extract_chunks(PT.OpenAIStream(), s3)
    @test length(chunks) == 2
    @test chunks[1].data == "abc"
    @test chunks[2].data == "[DONE]"
    @test spillover == ""

    # Test case for s4a and s4b: Handling spillover
    s4a = """event: test
    data: {"id":"chatcmpl-A3zvq9GWhji7h1Gz0gKNIn9r2tABJ","object":"chat.completion.chunk","created":1725516414,"model":"gpt-4o-mini-2024-07-18","system_fingerprint":"fp_f905cf32a9","choices":[{"index":0,"delta":{"content":","},"logprobs":null,"finish_reason":null}]}

    event: test2
    data: {"id":"chatcmpl-A3zvq9GWhji7h1Gz0gKNIn9r2tABJ","object":"chat.completion.chunk","created"""
    s4b = """":1725516414,"model":"gpt-4o-mini-2024-07-18","system_fingerprint":"fp_f905cf32a9","choices":[{"index":0,"delta":{"content":" "},"logprobs":null,"finish_reason":null}]}

    data: [DONE]

    """
    chunks, spillover = PT.extract_chunks(PT.OpenAIStream(), s4a)
    @test length(chunks) == 1
    @test chunks[1].event == :test
    @test !isempty(spillover)

    chunks, final_spillover = PT.extract_chunks(
        PT.OpenAIStream(), s4b; spillover = spillover)
    @test length(chunks) == 2
    @test chunks[2].data == "[DONE]"
    @test final_spillover == ""
end

@testset "extract_content" begin
    ### OpenAIStream
    # Test case 1: Valid JSON with content
    valid_chunk = PT.StreamChunk(
        nothing,
        """{"choices":[{"delta":{"content":"Hello"}}]}""",
        JSON3.read("""{"choices":[{"delta":{"content":"Hello"}}]}""")
    )
    @test PT.extract_content(PT.OpenAIStream(), valid_chunk) == "Hello"

    # Test case 2: Valid JSON without content
    no_content_chunk = PT.StreamChunk(
        nothing,
        """{"choices":[{"delta":{}}]}""",
        JSON3.read("""{"choices":[{"delta":{}}]}""")
    )
    @test isnothing(PT.extract_content(PT.OpenAIStream(), no_content_chunk))

    # Test case 3: Valid JSON with empty content
    empty_content_chunk = PT.StreamChunk(
        nothing,
        """{"choices":[{"delta":{"content":""}}]}""",
        JSON3.read("""{"choices":[{"delta":{"content":""}}]}""")
    )
    @test PT.extract_content(PT.OpenAIStream(), empty_content_chunk) == ""

    # Test case 4: Invalid JSON structure
    invalid_chunk = PT.StreamChunk(
        nothing,
        """{"invalid":"structure"}""",
        JSON3.read("""{"invalid":"structure"}""")
    )
    @test isnothing(PT.extract_content(PT.OpenAIStream(), invalid_chunk))

    # Test case 5: Chunk with non-JSON data
    non_json_chunk = PT.StreamChunk(
        nothing,
        "This is not JSON",
        nothing
    )
    @test isnothing(PT.extract_content(PT.OpenAIStream(), non_json_chunk))

    # Test case 6: Multiple choices (should still return first choice)
    multiple_choices_chunk = PT.StreamChunk(
        nothing,
        """{"choices":[{"delta":{"content":"First"}},{"delta":{"content":"Second"}}]}""",
        JSON3.read("""{"choices":[{"delta":{"content":"First"}},{"delta":{"content":"Second"}}]}""")
    )
    @test PT.extract_content(PT.OpenAIStream(), multiple_choices_chunk) == "First"

    ### AnthropicStream
    # Test case 1: Valid JSON with content in content_block
    valid_chunk = PT.StreamChunk(
        nothing,
        """{"index":0,"content_block":{"text":"Hello from Anthropic"}}""",
        JSON3.read("""{"index":0,"content_block":{"text":"Hello from Anthropic"}}""")
    )
    @test PT.extract_content(PT.AnthropicStream(), valid_chunk) == "Hello from Anthropic"

    # Test case 2: Valid JSON with content in delta
    delta_chunk = PT.StreamChunk(
        nothing,
        """{"index":0,"delta":{"text":"Delta content"}}""",
        JSON3.read("""{"index":0,"delta":{"text":"Delta content"}}""")
    )
    @test PT.extract_content(PT.AnthropicStream(), delta_chunk) == "Delta content"

    # Test case 3: Valid JSON without text in content_block
    no_text_chunk = PT.StreamChunk(
        nothing,
        """{"index":0,"content_block":{"type":"text"}}""",
        JSON3.read("""{"index":0,"content_block":{"type":"text"}}""")
    )
    @test isnothing(PT.extract_content(PT.AnthropicStream(), no_text_chunk))

    # Test case 4: Valid JSON with non-zero index
    non_zero_index_chunk = PT.StreamChunk(
        nothing,
        """{"index":1,"content_block":{"text":"Should be ignored"}}""",
        JSON3.read("""{"index":1,"content_block":{"text":"Should be ignored"}}""")
    )
    @test isnothing(PT.extract_content(PT.AnthropicStream(), non_zero_index_chunk))

    # Test case 5: Chunk with non-JSON data
    non_json_chunk = PT.StreamChunk(
        nothing,
        "This is not JSON",
        nothing
    )
    @test isnothing(PT.extract_content(PT.AnthropicStream(), non_json_chunk))

    # Test case 6: Valid JSON with empty content
    empty_content_chunk = PT.StreamChunk(
        nothing,
        """{"index":0,"content_block":{"text":""}}""",
        JSON3.read("""{"index":0,"content_block":{"text":""}}""")
    )
    @test PT.extract_content(PT.AnthropicStream(), empty_content_chunk) == ""

    # Test case 7: Unknown flavor
    struct UnknownFlavor <: PT.AbstractStreamFlavor end
    unknown_flavor = UnknownFlavor()
    unknown_chunk = PT.StreamChunk(
        nothing,
        """{"content": "Test content"}""",
        JSON3.read("""{"content": "Test content"}""")
    )
    @test_throws ArgumentError PT.extract_content(unknown_flavor, unknown_chunk)
end

@testset "print_content" begin
    # Test printing to IO
    io = IOBuffer()
    PT.print_content(io, "Test content")
    @test String(take!(io)) == "Test content"

    # Test printing to Channel
    ch = Channel{String}(1)
    PT.print_content(ch, "Channel content")
    @test take!(ch) == "Channel content"

    # Test printing to nothing
    @test PT.print_content(nothing, "No output") === nothing
end

@testset "callback" begin
    # Test with valid content
    io = IOBuffer()
    cb = PT.StreamCallback(out = io, flavor = PT.OpenAIStream())
    valid_chunk = PT.StreamChunk(
        nothing,
        """{"choices":[{"delta":{"content":"Hello"}}]}""",
        JSON3.read("""{"choices":[{"delta":{"content":"Hello"}}]}""")
    )
    PT.callback(cb, valid_chunk)
    @test String(take!(io)) == "Hello"

    # Test with no content
    io = IOBuffer()
    cb = PT.StreamCallback(out = io, flavor = PT.OpenAIStream())
    no_content_chunk = PT.StreamChunk(
        nothing,
        """{"choices":[{"delta":{}}]}""",
        JSON3.read("""{"choices":[{"delta":{}}]}""")
    )
    PT.callback(cb, no_content_chunk)
    @test isempty(take!(io))

    # Test with Channel output
    ch = Channel{String}(1)
    cb = PT.StreamCallback(out = ch, flavor = PT.OpenAIStream())
    PT.callback(cb, valid_chunk)
    @test take!(ch) == "Hello"

    # Test with nothing output
    cb = PT.StreamCallback(out = nothing, flavor = PT.OpenAIStream())
    @test PT.callback(cb, valid_chunk) === nothing
end

@testset "build_response_body-OpenAIStream" begin
    # Test case 1: Empty chunks
    cb_empty = PT.StreamCallback()
    response = PT.build_response_body(PT.OpenAIStream(), cb_empty)
    @test isnothing(response)

    # Test case 2: Single complete chunk
    cb_single = PT.StreamCallback()
    push!(cb_single.chunks,
        PT.StreamChunk(
            nothing,
            """{"id":"chatcmpl-123","object":"chat.completion.chunk","created":1234567890,"model":"gpt-4","choices":[{"index":0,"delta":{"role":"assistant","content":"Hello"},"finish_reason":null}]}""",
            JSON3.read("""{"id":"chatcmpl-123","object":"chat.completion.chunk","created":1234567890,"model":"gpt-4","choices":[{"index":0,"delta":{"role":"assistant","content":"Hello"},"finish_reason":null}]}""")
        ))
    response = PT.build_response_body(PT.OpenAIStream(), cb_single)
    @test response[:id] == "chatcmpl-123"
    @test response[:object] == "chat.completion"
    @test response[:model] == "gpt-4"
    @test length(response[:choices]) == 1
    @test response[:choices][1][:index] == 0
    @test response[:choices][1][:message][:role] == "assistant"
    @test response[:choices][1][:message][:content] == "Hello"

    # Test case 3: Multiple chunks forming a complete response
    cb_multiple = PT.StreamCallback()
    push!(cb_multiple.chunks,
        PT.StreamChunk(
            nothing,
            """{"id":"chatcmpl-456","object":"chat.completion.chunk","created":1234567890,"model":"gpt-4","choices":[{"index":0,"delta":{"role":"assistant","content":"Hello"},"finish_reason":null}]}""",
            JSON3.read("""{"id":"chatcmpl-456","object":"chat.completion.chunk","created":1234567890,"model":"gpt-4","choices":[{"index":0,"delta":{"role":"assistant","content":"Hello"},"finish_reason":null}]}""")
        ))
    push!(cb_multiple.chunks,
        PT.StreamChunk(
            nothing,
            """{"id":"chatcmpl-456","object":"chat.completion.chunk","created":1234567890,"model":"gpt-4","choices":[{"index":0,"delta":{"content":" world"},"finish_reason":null}]}""",
            JSON3.read("""{"id":"chatcmpl-456","object":"chat.completion.chunk","created":1234567890,"model":"gpt-4","choices":[{"index":0,"delta":{"content":" world"},"finish_reason":null}]}""")
        ))
    push!(cb_multiple.chunks,
        PT.StreamChunk(
            nothing,
            """{"id":"chatcmpl-456","object":"chat.completion.chunk","created":1234567890,"model":"gpt-4","choices":[{"index":0,"delta":{},"finish_reason":"stop"}]}""",
            JSON3.read("""{"id":"chatcmpl-456","object":"chat.completion.chunk","created":1234567890,"model":"gpt-4","choices":[{"index":0,"delta":{},"finish_reason":"stop"}]}""")
        ))
    response = PT.build_response_body(PT.OpenAIStream(), cb_multiple)
    @test response[:id] == "chatcmpl-456"
    @test response[:object] == "chat.completion"
    @test response[:model] == "gpt-4"
    @test length(response[:choices]) == 1
    @test response[:choices][1][:index] == 0
    @test response[:choices][1][:message][:role] == "assistant"
    @test response[:choices][1][:message][:content] == "Hello world"
    @test response[:choices][1][:finish_reason] == "stop"

    # Test case 4: Multiple choices
    cb_multi_choice = PT.StreamCallback()
    push!(cb_multi_choice.chunks,
        PT.StreamChunk(
            nothing,
            """{"id":"chatcmpl-789","object":"chat.completion.chunk","created":1234567890,"model":"gpt-4","choices":[{"index":0,"delta":{"role":"assistant","content":"First"},"finish_reason":null},{"index":1,"delta":{"role":"assistant","content":"Second"},"finish_reason":null}]}""",
            JSON3.read("""{"id":"chatcmpl-789","object":"chat.completion.chunk","created":1234567890,"model":"gpt-4","choices":[{"index":0,"delta":{"role":"assistant","content":"First"},"finish_reason":null},{"index":1,"delta":{"role":"assistant","content":"Second"},"finish_reason":null}]}""")
        ))
    response = PT.build_response_body(PT.OpenAIStream(), cb_multi_choice)
    @test response[:id] == "chatcmpl-789"
    @test length(response[:choices]) == 2
    @test response[:choices][1][:index] == 0
    @test response[:choices][1][:message][:content] == "First"
    @test response[:choices][2][:index] == 1
    @test response[:choices][2][:message][:content] == "Second"

    # Test case 5: Usage information
    cb_usage = PT.StreamCallback()
    push!(cb_usage.chunks,
        PT.StreamChunk(
            nothing,
            """{"id":"chatcmpl-101112","object":"chat.completion.chunk","created":1234567890,"model":"gpt-4","choices":[{"index":0,"delta":{"role":"assistant","content":"Test"},"finish_reason":null}],"usage":{"prompt_tokens":10,"completion_tokens":1,"total_tokens":11}}""",
            JSON3.read("""{"id":"chatcmpl-101112","object":"chat.completion.chunk","created":1234567890,"model":"gpt-4","choices":[{"index":0,"delta":{"role":"assistant","content":"Test"},"finish_reason":null}],"usage":{"prompt_tokens":10,"completion_tokens":1,"total_tokens":11}}""")
        ))
    response = PT.build_response_body(PT.OpenAIStream(), cb_usage)
    @test response[:usage][:prompt_tokens] == 10
    @test response[:usage][:completion_tokens] == 1
    @test response[:usage][:total_tokens] == 11
end
@testset "build_response_body-AnthropicStream" begin
    # Test case 1: Empty chunks
    cb_empty = PT.StreamCallback(flavor = PT.AnthropicStream())
    response = PT.build_response_body(PT.AnthropicStream(), cb_empty)
    @test isnothing(response)

    # Test case 2: Single message
    cb_single = PT.StreamCallback(flavor = PT.AnthropicStream())
    push!(cb_single.chunks,
        PT.StreamChunk(
            :message_start,
            """{"message":{"content":[],"model":"claude-2","stop_reason":null,"stop_sequence":null}}""",
            JSON3.read("""{"message":{"content":[],"model":"claude-2","stop_reason":null,"stop_sequence":null}}""")
        ))
    response = PT.build_response_body(PT.AnthropicStream(), cb_single)
    @test response[:content][1][:type] == "text"
    @test response[:content][1][:text] == ""
    @test response[:model] == "claude-2"
    @test isnothing(response[:stop_reason])
    @test isnothing(response[:stop_sequence])

    # Test case 3: Multiple content blocks
    cb_multiple = PT.StreamCallback(flavor = PT.AnthropicStream())
    push!(cb_multiple.chunks,
        PT.StreamChunk(
            :message_start,
            """{"message":{"content":[],"model":"claude-2","stop_reason":null,"stop_sequence":null}}""",
            JSON3.read("""{"message":{"content":[],"model":"claude-2","stop_reason":null,"stop_sequence":null}}""")
        ))
    push!(cb_multiple.chunks,
        PT.StreamChunk(
            :content_block_start,
            """{"content_block":{"type":"text","text":"Hello"}}""",
            JSON3.read("""{"content_block":{"type":"text","text":"Hello"}}""")
        ))
    push!(cb_multiple.chunks,
        PT.StreamChunk(
            :content_block_delta,
            """{"delta":{"type":"text","text":" world"}}""",
            JSON3.read("""{"delta":{"type":"text","text":" world"}}""")
        ))
    push!(cb_multiple.chunks,
        PT.StreamChunk(
            :content_block_stop,
            """{"content_block":{"type":"text","text":"!"}}""",
            JSON3.read("""{"content_block":{"type":"text","text":"!"}}""")
        ))
    response = PT.build_response_body(PT.AnthropicStream(), cb_multiple)
    @test response[:content][1][:type] == "text"
    @test response[:content][1][:text] == "Hello world!"
    @test response[:model] == "claude-2"

    # Test case 4: With usage information
    cb_usage = PT.StreamCallback(flavor = PT.AnthropicStream())
    push!(cb_usage.chunks,
        PT.StreamChunk(
            :message_start,
            """{"message":{"content":[],"model":"claude-2","stop_reason":null,"stop_sequence":null,"usage":{"input_tokens":10,"output_tokens":5}}}""",
            JSON3.read("""{"message":{"content":[],"model":"claude-2","stop_reason":null,"stop_sequence":null,"usage":{"input_tokens":10,"output_tokens":5}}}""")
        ))
    push!(cb_usage.chunks,
        PT.StreamChunk(
            :content_block_start,
            """{"content_block":{"type":"text","text":"Test"}}""",
            JSON3.read("""{"content_block":{"type":"text","text":"Test"}}""")
        ))
    push!(cb_usage.chunks,
        PT.StreamChunk(
            :message_delta,
            """{"delta":{"stop_reason": "end_turn"},"usage":{"output_tokens":7}}""",
            JSON3.read("""{"delta":{"stop_reason": "end_turn"},"usage":{"output_tokens":7}}""")
        ))
    response = PT.build_response_body(PT.AnthropicStream(), cb_usage)
    @test response[:content][1][:type] == "text"
    @test response[:content][1][:text] == "Test"
    @test response[:usage][:input_tokens] == 10
    @test response[:usage][:output_tokens] == 7
    @test response[:stop_reason] == "end_turn"

    # Test case 5: With stop reason
    cb_stop = PT.StreamCallback(flavor = PT.AnthropicStream())
    push!(cb_stop.chunks,
        PT.StreamChunk(
            :message_start,
            """{"message":{"content":[],"model":"claude-2","stop_reason":null,"stop_sequence":null}}""",
            JSON3.read("""{"message":{"content":[],"model":"claude-2","stop_reason":null,"stop_sequence":null}}""")
        ))
    push!(cb_stop.chunks,
        PT.StreamChunk(
            :content_block_start,
            """{"content_block":{"type":"text","text":"Final"}}""",
            JSON3.read("""{"content_block":{"type":"text","text":"Final"}}""")
        ))
    push!(cb_stop.chunks,
        PT.StreamChunk(
            :message_delta,
            """{"delta":{"stop_reason":"max_tokens","stop_sequence":null}}""",
            JSON3.read("""{"delta":{"stop_reason":"max_tokens","stop_sequence":null}}""")
        ))
    response = PT.build_response_body(PT.AnthropicStream(), cb_stop)
    @test response[:content][1][:type] == "text"
    @test response[:content][1][:text] == "Final"
    @test response[:stop_reason] == "max_tokens"
    @test isnothing(response[:stop_sequence])
end

@testset "handle_error_message" begin
    # Test case 1: No error
    chunk = PT.StreamChunk(:content, "Normal content", nothing)
    @test isnothing(PT.handle_error_message(chunk))

    # Test case 2: Error event
    error_chunk = PT.StreamChunk(:error, "Error occurred", nothing)
    @test_logs (:warn, "Error detected in the streaming response: Error occurred") PT.handle_error_message(error_chunk)

    # Test case 4: Detailed error in JSON
    obj = Dict(:error => Dict(:message => "Invalid input", :type => "user_error"))
    detailed_error_chunk = PT.StreamChunk(
        nothing, JSON3.write(obj), JSON3.read(JSON3.write(obj)))
    @test_logs (:warn,
        r"Message: Invalid input") PT.handle_error_message(detailed_error_chunk)
    @test_logs (:warn,
        r"Type: user_error") PT.handle_error_message(detailed_error_chunk)

    # Test case 5: Throw on error
    @test_throws Exception PT.handle_error_message(error_chunk, throw_on_error = true)
end

## Not working yet!!
# @testset "streamed_request!" begin
#     # Setup mock server
#     PORT = rand(10000:20000)
#     server = HTTP.serve!(PORT; verbose = false) do request
#         if request.method == "POST" && request.target == "/v1/chat/completions"
#             # Simulate streaming response
#             return HTTP.Response() do io
#                 write(io, "data: {\"choices\":[{\"delta\":{\"content\":\"Hello\"}}]}\n\n")
#                 write(io, "data: {\"choices\":[{\"delta\":{\"content\":\" world\"}}]}\n\n")
#                 write(io, "data: [DONE]\n\n")
#             end
#         else
#             return HTTP.Response(404, "Not found")
#         end
#     end

#     # Test streamed_request!
#     url = "http://localhost:$PORT/v1/chat/completions"
#     headers = ["Content-Type" => "application/json"]
#     input = IOBuffer(JSON3.write(Dict(
#         "model" => "gpt-3.5-turbo",
#         "messages" => [Dict("role" => "user", "content" => "Say hello")]
#     )))

#     cb = PT.StreamCallback(flavor = PT.OpenAIStream())
#     response = PT.streamed_request!(cb, url, headers, input)

#     # Assertions
#     @test response.status == 200
#     @test length(cb.chunks) == 3
#     @test cb.chunks[1].json.choices[1].delta.content == "Hello"
#     @test cb.chunks[2].json.choices[1].delta.content == " world"
#     @test cb.chunks[3].data == "[DONE]"

#     # Test build_response_body
#     body = PT.build_response_body(PT.OpenAIStream(), cb)
#     @test body[:choices][1][:message][:content] == "Hello world"
#     # Cleanup
#     close(server)
# end