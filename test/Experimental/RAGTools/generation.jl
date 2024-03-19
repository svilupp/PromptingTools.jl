using PromptingTools.Experimental.RAGTools: ChunkIndex,
                                            CandidateChunks, build_context, build_context!
using PromptingTools.Experimental.RAGTools: MaybeTags, Tag, ContextEnumerator,
                                            AbstractContextBuilder
using PromptingTools.Experimental.RAGTools: SimpleAnswerer, AbstractAnswerer, answer!,
                                            NoRefiner, SimpleRefiner, AbstractRefiner,
                                            refine!
using PromptingTools.Experimental.RAGTools: NoPostprocessor, AbstractPostprocessor,
                                            postprocess!, SimpleGenerator,
                                            AdvancedGenerator, generate!, airag, RAGConfig

@testset "build_context!" begin
    index = ChunkIndex(;
        sources = [".", ".", "."],
        chunks = ["a", "b", "c"],
        embeddings = zeros(128, 3),
        tags = vcat(trues(2, 2), falses(1, 2)),
        tags_vocab = ["yes", "no"])
    candidates = CandidateChunks(index.id, [1, 2], [0.1, 0.2])

    # Standard Case
    contexter = ContextEnumerator()
    context = build_context(contexter, index, candidates)
    expected_output = ["1. a\nb",
        "2. a\nb\nc"]
    @test context == expected_output

    # No Surrounding Chunks
    context = build_context(contexter, index, candidates; chunks_window_margin = (0, 0))
    expected_output = ["1. a",
        "2. b"]
    @test context == expected_output

    # Wrong inputs
    @test_throws AssertionError build_context(contexter, index,
        candidates;
        chunks_window_margin = (-1, 0))

    # From result/index
    result = RAGResult(;
        question, rephrased_questions = [question], emb_candidates = candidates,
        tag_candidates = candidates, filtered_candidates = candidates, reranked_candidates = candidates,
        context = String[], sources = String[])
    build_context!(contexter, index, result)
    expected_output = ["1. a\nb",
        "2. a\nb\nc"]
    @test result.context == expected_output

    # Unknown type
    struct RandomContextEnumerator123 <: AbstractContextBuilder end
    @test_throws ArgumentError build_context!(
        RandomContextEnumerator123(), index, result)
end

@testset "answer!" begin
    # Setup
    index = ChunkIndex(id = :TestChunkIndex1,
        chunks = ["chunk1", "chunk2"],
        sources = ["source1", "source2"],
        embeddings = ones(Float32, 2, 2))

    question = "why?"
    cc1 = CandidateChunks(index_id = :TestChunkIndex1)

    result = RAGResult(; question, rephrased_questions = [question], emb_candidates = cc1,
        tag_candidates = cc1, filtered_candidates = cc1, reranked_candidates = cc1,
        context = String["a", "b"], sources = String[])

    # Test refine with SimpleAnswerer
    response = Dict(
        :choices => [
            Dict(:message => Dict(:content => "answer"), :finish_reason => "stop")
        ],
        :usage => Dict(:total_tokens => 3,
            :prompt_tokens => 2,
            :completion_tokens => 1))
    schema = TestEchoOpenAISchema(; response, status = 200)
    PT.register_model!(; name = "mock-gen", schema)

    output = answer!(
        SimpleAnswerer(), index, result; model = "mock-gen")
    @test result.answer == "answer"
    @test result.conversations[:answer][end].content == "answer"

    # with unknown rephraser
    struct UnknownAnswerer123 <: AbstractAnswerer end
    @test_throws ArgumentError answer!(UnknownAnswerer123(), index, result)
end

@testset "refine!" begin
    # Setup
    index = ChunkIndex(id = :TestChunkIndex1,
        chunks = ["chunk1", "chunk2"],
        sources = ["source1", "source2"],
        embeddings = ones(Float32, 2, 2))

    question = "why?"
    cc1 = CandidateChunks(index_id = :TestChunkIndex1)

    # Test refine with NoRefiner, simple passthrough
    result = RAGResult(; question, rephrased_questions = [question], emb_candidates = cc1,
        tag_candidates = cc1, filtered_candidates = cc1, reranked_candidates = cc1,
        context = String[], sources = String[], answer = "ABC",
        conversations = Dict(:answer => [PT.UserMessage("MESSAGE")]))

    result = refine!(NoRefiner(), index, result)
    @test result.final_answer == "ABC"
    @test result.conversations[:final_answer] == [PT.UserMessage("MESSAGE")]

    # Test refine with SimpleRefiner
    response = Dict(
        :choices => [
            Dict(:message => Dict(:content => "new answer"), :finish_reason => "stop")
        ],
        :usage => Dict(:total_tokens => 3,
            :prompt_tokens => 2,
            :completion_tokens => 1))
    schema = TestEchoOpenAISchema(; response, status = 200)
    PT.register_model!(; name = "mock-gen", schema)
    result = RAGResult(; question, rephrased_questions = [question], emb_candidates = cc1,
        tag_candidates = cc1, filtered_candidates = cc1, reranked_candidates = cc1,
        context = String[], sources = String[], answer = "ABC",
        conversations = Dict(:answer => [PT.UserMessage("MESSAGE")]))

    output = refine!(
        SimpleRefiner(), index, result; model = "mock-gen")
    @test result.final_answer == "new answer"
    @test result.conversations[:final_answer][end].content == "new answer"

    # with unknown rephraser
    struct UnknownRefiner123 <: AbstractRefiner end
    @test_throws ArgumentError refine!(UnknownRefiner123(), index, result)
end

@testset "postprocess!" begin
    question = "why?"
    cc1 = CandidateChunks(index_id = :TestChunkIndex1)
    result = RAGResult(; question, rephrased_questions = [question], emb_candidates = cc1,
        tag_candidates = cc1, filtered_candidates = cc1, reranked_candidates = cc1,
        context = String[], sources = String[])
    index = ChunkIndex(id = :TestChunkIndex1,
        chunks = ["chunk1", "chunk2"],
        sources = ["source1", "source2"],
        embeddings = ones(Float32, 2, 2))

    # passthrough
    @test postprocess!(NoPostprocessor(), index, result) == result
    # Unknown type
    struct RandomPostprocessor123 <: AbstractPostprocessor end
    @test_throws ArgumentError postprocess!(RandomPostprocessor123(), index, result)
end

@testset "generate!" begin
    response = Dict(
        :choices => [
            Dict(:message => Dict(:content => "answer"), :finish_reason => "stop")
        ],
        :usage => Dict(:total_tokens => 3,
            :prompt_tokens => 2,
            :completion_tokens => 1))
    schema = TestEchoOpenAISchema(; response, status = 200)
    PT.register_model!(; name = "mock-gen", schema)

    index = ChunkIndex(id = :TestChunkIndex1,
        chunks = ["chunk1", "chunk2"],
        sources = ["source1", "source2"],
        embeddings = ones(Float32, 2, 2))

    question = "why?"
    cc1 = CandidateChunks(index_id = :TestChunkIndex1)

    result = RAGResult(; question, rephrased_questions = [question], emb_candidates = cc1,
        tag_candidates = cc1, filtered_candidates = cc1, reranked_candidates = cc1,
        context = String["a", "b"], sources = String[])

    # SimpleGenerator - no refinement
    output = generate!(SimpleGenerator(), index, result;
        answerer_kwargs = (; model = "mock-gen"))
    @test output.answer == "answer"
    @test output.final_answer == "answer"

    # with defaults 
    output = generate!(index, result)
    @test output.answer == "answer"
    @test output.final_answer == "answer"

    # Test with refinement - AdvancedGenerator
    output = generate!(AdvancedGenerator(), index, result;
        answerer_kwargs = (; model = "mock-gen"),
        refiner_kwargs = (; model = "mock-gen"))
    @test output.answer == "answer"
    @test output.final_answer == "answer"
end

@testset "airag" begin
    # test with a mock server
    PORT = rand(20010:40001)
    PT.register_model!(; name = "mock-emb", schema = PT.CustomOpenAISchema())
    PT.register_model!(; name = "mock-meta", schema = PT.CustomOpenAISchema())
    PT.register_model!(; name = "mock-gen", schema = PT.CustomOpenAISchema())

    echo_server = HTTP.serve!(PORT; verbose = -1) do req
        content = JSON3.read(req.body)

        if content[:model] == "mock-gen"
            user_msg = last(content[:messages])
            response = Dict(
                :choices => [
                    Dict(:message => user_msg, :finish_reason => "stop")
                ],
                :model => content[:model],
                :usage => Dict(:total_tokens => length(user_msg[:content]),
                    :prompt_tokens => length(user_msg[:content]),
                    :completion_tokens => 0))
        elseif content[:model] == "mock-emb"
            # for i in 1:length(content[:input])
            response = Dict(:data => [Dict(:embedding => ones(Float32, 128))],
                :usage => Dict(:total_tokens => length(content[:input]),
                    :prompt_tokens => length(content[:input]),
                    :completion_tokens => 0))
        elseif content[:model] == "mock-meta"
            user_msg = last(content[:messages])
            response = Dict(
                :choices => [
                    Dict(:finish_reason => "stop",
                    :message => Dict(:tool_calls => [
                        Dict(:function => Dict(:arguments => JSON3.write(MaybeTags([
                        Tag("yes", "category")
                    ]))))]))],
                :model => content[:model],
                :usage => Dict(:total_tokens => length(user_msg[:content]),
                    :prompt_tokens => length(user_msg[:content]),
                    :completion_tokens => 0))
        else
            @info content
        end
        return HTTP.Response(200, JSON3.write(response))
    end

    ## Index
    index = ChunkIndex(;
        sources = [".", ".", "."],
        chunks = ["a", "b", "c"],
        embeddings = zeros(128, 3),
        tags = vcat(trues(2, 2), falses(1, 2)),
        tags_vocab = ["yes", "no"])
    ## Sub-calls
    question_emb = aiembed(["x", "x"];
        model = "mock-emb",
        api_kwargs = (; url = "http://localhost:$(PORT)"))
    @test question_emb.content == ones(128)
    metadata_msg = aiextract(:RAGExtractMetadataShort; return_type = MaybeTags,
        text = "x",
        model = "mock-meta", api_kwargs = (; url = "http://localhost:$(PORT)"))
    @test metadata_msg.content.items == [Tag("yes", "category")]
    answer_msg = aigenerate(:RAGAnswerFromContext;
        question = "Time?",
        context = "XYZ",
        model = "mock-gen", api_kwargs = (; url = "http://localhost:$(PORT)"))
    @test occursin("Time?", answer_msg.content)
    ## E2E - default type
    msg = airag(index; question = "Time?",
        retriever_kwargs = (;
            tagger_kwargs = (; model = "mock-gen", tag = ["yes"]), embedder_kwargs = (;
                model = "mock-emb")),
        generator_kwargs = (;
            answerer_kwargs = (; model = "mock-gen"), embedder_kwargs = (;
                model = "mock-emb")),
        api_kwargs = (; url = "http://localhost:$(PORT)"),
        return_all = false)
    @test occursin("Time?", msg.content)

    ## E2E - with type
    msg = airag(RAGConfig(), index; question = "Time?",
        retriever_kwargs = (;
            tagger_kwargs = (; model = "mock-gen", tag = ["yes"]), embedder_kwargs = (;
                model = "mock-emb")),
        generator_kwargs = (;
            answerer_kwargs = (; model = "mock-gen"), embedder_kwargs = (;
                model = "mock-emb")),
        api_kwargs = (; url = "http://localhost:$(PORT)"),
        return_all = false)
    @test occursin("Time?", msg.content)

    ## Return RAG result
    result = airag(RAGConfig(), index; question = "Time?",
        retriever_kwargs = (;
            tagger_kwargs = (; model = "mock-gen", tag = ["yes"]), embedder_kwargs = (;
                model = "mock-emb")),
        generator_kwargs = (;
            answerer_kwargs = (; model = "mock-gen"), embedder_kwargs = (;
                model = "mock-emb")),
        api_kwargs = (; url = "http://localhost:$(PORT)"),
        return_all = true)
    @test occursin("Time?", result.answer)
    @test occursin("Time?", result.final_answer)

    ## Pretty printing
    io = IOBuffer()
    PT.pprint(io, result)
    result_str = String(take!(io))
    expected_str = "--------------------\nQUESTION(s)\n--------------------\n- Time?\n\n--------------------\nANSWER\n--------------------\n# Question\n\nTime\n\n\n\n# Answer\n\n--------------------\nSOURCES\n--------------------\n1. .\n2. .\n3. ."
    @test result_str == expected_str

    # clean up
    close(echo_server)
end
