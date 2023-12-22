using PromptingTools.Experimental.RAGTools: MaybeMetadataItems, MetadataItem
@testset "airag" begin
    # test with a mock server
    PORT = rand(1000:2000)
    PT.register_model!(; name = "mock-emb", schema = PT.CustomOpenAISchema())
    PT.register_model!(; name = "mock-meta", schema = PT.CustomOpenAISchema())
    PT.register_model!(; name = "mock-gen", schema = PT.CustomOpenAISchema())

    echo_server = HTTP.serve!(PORT; verbose = -1) do req
        content = JSON3.read(req.body)

        if content[:model] == "mock-gen"
            user_msg = last(content[:messages])
            response = Dict(:choices => [Dict(:message => user_msg)],
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
            response = Dict(:choices => [
                    Dict(:message => Dict(:function_call => Dict(:arguments => JSON3.write(MaybeMetadataItems([
                        MetadataItem("yes", "category"),
                    ]))))),
                ],
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
        tags_vocab = ["yes", "no"],)
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
        return_context = false)
    @test occursin("Time?", msg.content)
    # different kwargs
    msg, ctx = airag(index; question = "Time?", model_embedding = "mock-emb",
        model_chat = "mock-gen",
        model_metadata = "mock-meta", api_kwargs = (; url = "http://localhost:$(PORT)"),
        tag_filter = :auto,
        extract_metadata = false, verbose = false,
        return_context = true)
    @test ctx.context == ["1. a\nb\nc", "2. a\nb"]
    @test ctx.emb_candidates.positions == [3, 2, 1]
    @test ctx.emb_candidates.distances == zeros(3)
    @test ctx.tag_candidates.positions == [1, 2]
    @test ctx.tag_candidates.distances == ones(2)
    @test ctx.filtered_candidates.positions == [2, 1] #re-sort
    @test ctx.filtered_candidates.distances == 0.5ones(2)
    @test ctx.reranked_candidates.positions == [2, 1] # no change
    @test ctx.reranked_candidates.distances == 0.5ones(2) # no change
    # clean up
    close(echo_server)
end
