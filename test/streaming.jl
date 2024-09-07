using PromptingTools: StreamCallback, StreamChunk, OpenAIStream, AnthropicStream,
                      configure_callback!
using PromptingTools: is_done, extract_chunks, extract_content, print_content, callback,
                      build_response_body, streamed_request
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