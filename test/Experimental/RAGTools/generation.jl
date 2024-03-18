using PromptingTools.Experimental.RAGTools: ChunkIndex,
                                            CandidateChunks, build_context, airag
using PromptingTools.Experimental.RAGTools: MaybeMetadataItems, MetadataItem

@testset "build_context" begin
    index = ChunkIndex(;
        sources = [".", ".", "."],
        chunks = ["a", "b", "c"],
        embeddings = zeros(128, 3),
        tags = vcat(trues(2, 2), falses(1, 2)),
        tags_vocab = ["yes", "no"])
    candidates = CandidateChunks(index.id, [1, 2], [0.1, 0.2])

    # Standard Case
    context = build_context(index, candidates)
    expected_output = ["1. a\nb",
        "2. a\nb\nc"]
    @test context == expected_output

    # No Surrounding Chunks
    context = build_context(index, candidates; chunks_window_margin = (0, 0))
    expected_output = ["1. a",
        "2. b"]
    @test context == expected_output

    # Wrong inputs
    @test_throws AssertionError build_context(index,
        candidates;
        chunks_window_margin = (-1, 0))
end

@testset "airag" begin
    # test with a mock server
    PORT = rand(20000:40000)
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
                        Dict(:function => Dict(:arguments => JSON3.write(MaybeMetadataItems([
                        MetadataItem("yes", "category")
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
    metadata_msg = aiextract(:RAGExtractMetadataShort; return_type = MaybeMetadataItems,
        text = "x",
        model = "mock-meta", api_kwargs = (; url = "http://localhost:$(PORT)"))
    @test metadata_msg.content.items == [MetadataItem("yes", "category")]
    answer_msg = aigenerate(:RAGAnswerFromContext;
        question = "Time?",
        context = "XYZ",
        model = "mock-gen", api_kwargs = (; url = "http://localhost:$(PORT)"))
    @test occursin("Time?", answer_msg.content)
    ## E2E
    msg = airag(index; question = "Time?", model_embedding = "mock-emb",
        model_chat = "mock-gen",
        model_metadata = "mock-meta", api_kwargs = (; url = "http://localhost:$(PORT)"),
        tag_filter = ["yes"],
        return_all = false)
    @test occursin("Time?", msg.content)

    # test kwargs passing
    api_kwargs = (; url = "http://localhost:$(PORT)")
    msg = airag(index; question = "Time?", model_embedding = "mock-emb",
        model_chat = "mock-gen",
        model_metadata = "mock-meta",
        tag_filter = ["yes"],
        return_all = false, aiembed_kwargs = (; api_kwargs),
        aigenerate_kwargs = (; api_kwargs), aiextract_kwargs = (; api_kwargs))
    @test occursin("Time?", msg.content)

    ## Test different kwargs
    msg, details = airag(index; question = "Time?", model_embedding = "mock-emb",
        model_chat = "mock-gen",
        model_metadata = "mock-meta", api_kwargs = (; url = "http://localhost:$(PORT)"),
        tag_filter = :auto,
        extract_metadata = false, verbose = false,
        return_all = true)
    @test details.context == ["1. a\nb\nc", "2. a\nb"]
    @test details.emb_candidates.positions == [3, 2, 1]
    @test details.emb_candidates.distances == zeros(3)
    @test details.tag_candidates.positions == [1, 2]
    @test details.tag_candidates.distances == ones(2)
    @test details.filtered_candidates.positions == [2, 1] #re-sort
    @test details.filtered_candidates.distances == 0.5ones(2)
    @test details.reranked_candidates.positions == [2, 1] # no change
    @test details.reranked_candidates.distances == 0.5ones(2) # no change

    ## Not tag filter
    msg, details = airag(index; question = "Time?", model_embedding = "mock-emb",
        model_chat = "mock-gen",
        model_metadata = "mock-meta", api_kwargs = (; url = "http://localhost:$(PORT)"),
        tag_filter = nothing,
        return_all = true)
    @test details.context == ["1. b\nc", "2. a\nb\nc", "3. a\nb"]
    @test details.emb_candidates.positions == [3, 2, 1]
    @test details.emb_candidates.distances == zeros(3)
    @test details.tag_candidates == nothing
    @test details.filtered_candidates.positions == [3, 2, 1] #re-sort
    @test details.reranked_candidates.positions == [3, 2, 1] # no change

    ## Pretty printing
    result = airag(index; question = "Time?", model_embedding = "mock-emb",
        model_chat = "mock-gen",
        model_metadata = "mock-meta", api_kwargs = (; url = "http://localhost:$(PORT)"),
        tag_filter = nothing,
        return_all = true)
    io = IOBuffer()
    PT.pprint(io, result)
    result_str = String(take!(io))
    expected_str = "--------------------\nQUESTION(s)\n--------------------\n- Time?\n\n--------------------\nANSWER\n--------------------\n# Question\n\nTime\n\n\n\n# Answer\n\n--------------------\nSOURCES\n--------------------\n1. .\n2. .\n3. ."
    @test result_str == expected_str

    # clean up
    close(echo_server)
end
