using PromptingTools.Experimental.RAGTools: ContextEnumerator, NoRephraser, SimpleRephraser,
                                            HyDERephraser,
                                            CosineSimilarity, BinaryCosineSimilarity,
                                            NoTagFilter, AnyTagFilter,
                                            SimpleRetriever, AdvancedRetriever
using PromptingTools.Experimental.RAGTools: AbstractRephraser, AbstractTagFilter,
                                            AbstractSimilarityFinder, AbstractReranker
using PromptingTools.Experimental.RAGTools: find_closest, hamming_distance, find_tags,
                                            rerank, rephrase,
                                            retrieve
using PromptingTools.Experimental.RAGTools: NoReranker, CohereReranker

@testset "rephrase" begin
    # Test rephrase with NoRephraser, simple passthrough
    @test rephrase(NoRephraser(), "test") == ["test"]

    # Test rephrase with SimpleRephraser
    response = Dict(
        :choices => [
            Dict(:message => Dict(:content => "new question"), :finish_reason => "stop")
        ],
        :usage => Dict(:total_tokens => 3,
            :prompt_tokens => 2,
            :completion_tokens => 1))
    schema = TestEchoOpenAISchema(; response, status = 200)
    PT.register_model!(; name = "mock-gen", schema)
    output = rephrase(
        SimpleRephraser(), "old question", model = "mock-gen")
    @test output == ["old question", "new question"]

    output = rephrase(
        HyDERephraser(), "old question", model = "mock-gen")
    @test output == ["old question", "new question"]

    # with unknown rephraser
    struct UnknownRephraser123 <: AbstractRephraser end
    @test_throws ArgumentError rephrase(UnknownRephraser123(), "test question")
end

@testset "hamming_distance" begin
    # Test for matching number of rows
    @test_throws ArgumentError hamming_distance(
        [true false; false true], [true, false, true])

    # Test for correct calculation of distances
    @test hamming_distance([true false; false true], [true, false]) == [0, 2]
    @test hamming_distance([true false; false true], [false, true]) == [2, 0]
    @test hamming_distance([true false; false true], [true, true]) == [1, 1]
    @test hamming_distance([true false; false true], [false, false]) == [1, 1]
end

@testset "find_closest" begin
    finder = CosineSimilarity()
    test_embeddings = [1.0 2.0 -1.0; 3.0 4.0 -3.0; 5.0 6.0 -6.0] |>
                      x -> mapreduce(normalize, hcat, eachcol(x))
    query_embedding = [0.1, 0.35, 0.5] |> normalize
    positions, distances = find_closest(finder, test_embeddings, query_embedding, top_k = 2)
    # The query vector should be closer to the first embedding
    @test positions == [1, 2]
    @test isapprox(distances, [0.9975694083904584
                               0.9939123761133188], atol = 1e-3)

    # Test when top_k is more than available embeddings
    positions, _ = find_closest(finder, test_embeddings, query_embedding, top_k = 5)
    @test length(positions) == size(test_embeddings, 2)

    # Test with minimum_similarity
    positions, _ = find_closest(finder, test_embeddings, query_embedding, top_k = 5,
        minimum_similarity = 0.995)
    @test length(positions) == 1

    # Test behavior with edge values (top_k == 0)
    @test find_closest(finder, test_embeddings, query_embedding, top_k = 0) == ([], [])

    ## Test with ChunkIndex
    embeddings1 = ones(Float32, 2, 2)
    embeddings1[2, 2] = 5.0
    embeddings1 = mapreduce(normalize, hcat, eachcol(embeddings1))
    ci1 = ChunkIndex(id = :TestChunkIndex1,
        chunks = ["chunk1", "chunk2"],
        sources = ["source1", "source2"],
        embeddings = embeddings1)
    ci2 = ChunkIndex(id = :TestChunkIndex2,
        chunks = ["chunk1", "chunk2"],
        sources = ["source1", "source2"],
        embeddings = ones(Float32, 2, 2))
    ci3 = ChunkIndex(id = :TestChunkIndex3,
        chunks = ["chunk1", "chunk2"],
        sources = ["source1", "source2"],
        embeddings = nothing)

    ## find_closest with ChunkIndex
    query_emb = [0.5, 0.5] # Example query embedding vector
    result = find_closest(finder, ci1, query_emb)
    @test result isa CandidateChunks
    @test result.positions == [1, 2]
    @test all(1.0 .>= result.scores .>= -1.0)   # Assuming default minimum_similarity

    ## empty index
    query_emb = [0.5, 0.5] # Example query embedding vector
    result = find_closest(finder, ci3, query_emb)
    @test isempty(result)

    ## Unknown type
    struct RandomSimilarityFinder123 <: AbstractSimilarityFinder end
    @test_throws ArgumentError find_closest(
        RandomSimilarityFinder123(), ones(5, 5), ones(5))

    ## find_closest with multiple embeddings
    query_emb = [0.5 0.5; 0.5 1.0] |> x -> mapreduce(normalize, hcat, eachcol(x))
    result = find_closest(finder, ci1, query_emb; top_k = 2)
    @test result.positions == [1, 2]
    @test isapprox(result.scores, [1.0, 0.965], atol = 1e-2)

    # bad top_k -- too low, leads to 0 results
    result = find_closest(finder, ci1, query_emb; top_k = 1)
    @test isempty(result)
    # but it works in general, because 1/1 = 1 is a valid top_k
    result = find_closest(finder, ci1, query_emb[:, 1]; top_k = 1)
    @test result.positions == [1]
    @test result.scores == [1.0]

    ## find_closest with MultiIndex
    ## mi = MultiIndex(id = :multi, indexes = [ci1, ci2])
    ## query_emb = [0.5, 0.5] # Example query embedding vector
    ## result = find_closest(mi, query_emb)
    ## @test result isa CandidateChunks
    ## @test result.positions == [1, 2]
    ## @test all(1.0 .>= result.distances .>= -1.0)   # Assuming default minimum_similarity

    ### For Binary embeddings
    # Test for correct retrieval of closest positions and scores
    emb = [true false; false true]
    query_emb = [true, false]
    positions, scores = find_closest(BinaryCosineSimilarity(), emb, query_emb)
    @test positions == [1, 2]
    @test scores ≈ [1, 0] #query_emb' * emb[:, positions]

    query_emb = [0.5, -0.5]
    positions, scores = find_closest(BinaryCosineSimilarity(), emb, query_emb)
    @test positions == [1, 2]
    @test scores ≈ [0.5, -0.5] #query_emb' * emb[:, positions]

    # Test for custom top_k and minimum_similarity values
    positions, scores = find_closest(
        BinaryCosineSimilarity(), emb, query_emb; top_k = 1, minimum_similarity = 0.5)
    @test positions == [1]
    @test scores ≈ [0.5]

    positions, scores = find_closest(
        BinaryCosineSimilarity(), emb, query_emb; top_k = 1, minimum_similarity = 0.6)
    @test isempty(positions)
    @test iesmpty(scores)
end

@testset "find_tags" begin
    tagger = AnyTagFilter()
    test_embeddings = [1.0 2.0; 3.0 4.0; 5.0 6.0] |>
                      x -> mapreduce(normalize, hcat, eachcol(x))
    query_embedding = [0.1, 0.35, 0.5] |> normalize
    test_tags_vocab = ["julia", "python", "jr"]
    test_tags_matrix = sparse([1, 2], [1, 3], [true, true], 2, 3)
    index = ChunkIndex(;
        sources = [".", "."],
        chunks = ["julia", "jr"],
        embeddings = test_embeddings,
        tags = test_tags_matrix,
        tags_vocab = test_tags_vocab)

    # Test for finding the correct positions of a specific tag
    @test find_tags(tagger, index, "julia").positions == [1]
    @test find_tags(tagger, index, "julia").scores == [1.0]

    # Test for no tag found // not in vocab
    @test find_tags(tagger, index, "python").positions |> isempty
    @test find_tags(tagger, index, "java").positions |> isempty

    # Test with regex matching
    @test find_tags(tagger, index, r"^j").positions == [1, 2]

    # Test with multiple tags in vocab
    @test find_tags(tagger, index, ["python", "jr", "x"]).positions == [2]

    # No filter tag -- give everything
    cc = find_tags(NoTagFilter(), index, "julia")
    @test cc.positions == [1, 2]
    @test cc.scores == [0.0, 0.0]

    cc = find_tags(NoTagFilter(), index, nothing)
    @test cc.positions == [1, 2]
    @test cc.scores == [0.0, 0.0]

    # Unknown type
    struct RandomTagFilter123 <: AbstractTagFilter end
    @test_throws ArgumentError find_tags(RandomTagFilter123(), index, "hello")
    @test_throws ArgumentError find_tags(RandomTagFilter123(), index, ["hello"])
end

@testset "rerank" begin
    # Mock data for testing
    ci1 = ChunkIndex(id = :TestChunkIndex1,
        chunks = ["chunk1", "chunk2"],
        sources = ["source1", "source2"])
    question = "mock_question"
    cc1 = CandidateChunks(index_id = :TestChunkIndex1,
        positions = [1, 2],
        scores = [0.3, 0.4])

    # Passthrough Strategy
    ranker = NoReranker()
    reranked = rerank(ranker, ci1, question, cc1)
    @test reranked.positions == [2, 1] # gets resorted by score
    @test reranked.scores == [0.4, 0.3]

    reranked = rerank(ranker, ci1, question, cc1; top_n = 1)
    @test reranked.positions == [2] # gets resorted by score
    @test reranked.scores == [0.4]

    # Cohere assertion
    ci2 = ChunkIndex(id = :TestChunkIndex2,
        chunks = ["chunk1", "chunk2"],
        sources = ["source1", "source2"])
    mi = MultiIndex(; id = :multi, indexes = [ci1, ci2])
    @test_throws ArgumentError rerank(CohereReranker(),
        mi,
        question,
        cc1)

    # Bad top_n
    @test_throws AssertionError rerank(CohereReranker(),
        ci1,
        question,
        cc1; top_n = 0)

    # Bad index_id
    cc2 = CandidateChunks(index_id = :TestChunkIndex2,
        positions = [1, 2],
        scores = [0.3, 0.4])
    @test_throws AssertionError rerank(CohereReranker(),
        ci1,
        question,
        cc2; top_n = 1)

    ## Unknown type
    struct RandomReranker123 <: AbstractReranker end
    @test_throws ArgumentError rerank(RandomReranker123(), ci1, "hello", cc2)

    ## TODO: add testing of Cohere reranker API call -- not done yet
end

@testset "retrieve" begin
    # test with a mock server
    PORT = rand(20000:40000)
    PT.register_model!(; name = "mock-emb", schema = PT.CustomOpenAISchema())
    PT.register_model!(; name = "mock-emb2", schema = PT.CustomOpenAISchema())
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
            response = Dict(:data => [Dict(:embedding => ones(Float32, 10))],
                :usage => Dict(:total_tokens => length(content[:input]),
                    :prompt_tokens => length(content[:input]),
                    :completion_tokens => 0))
        elseif content[:model] == "mock-emb2"
            response = Dict(
                :data => [Dict(:embedding => ones(Float32, 10)),
                    Dict(:embedding => ones(Float32, 10))],
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

    embeddings1 = ones(Float32, 10, 4)
    embeddings1[10, 3:4] .= 5.0
    embeddings1 = mapreduce(normalize, hcat, eachcol(embeddings1))
    index = ChunkIndex(id = :TestChunkIndex1,
        chunks = ["chunk1", "chunk2", "chunk3", "chunk4"],
        sources = ["source1", "source2", "source3", "source4"],
        embeddings = embeddings1)
    question = "test question"

    ## Test with SimpleRetriever
    simple = SimpleRetriever()

    result = retrieve(simple, index, question;
        rephraser_kwargs = (; model = "mock-gen"),
        embedder_kwargs = (; model = "mock-emb"),
        tagger_kwargs = (; model = "mock-meta"), api_kwargs = (;
            url = "http://localhost:$(PORT)"))
    @test result.question == question
    @test result.rephrased_questions == [question]
    @test result.answer == nothing
    @test result.final_answer == nothing
    @test result.reranked_candidates.positions == [2, 1, 4, 3]
    @test result.context == ["chunk2", "chunk1", "chunk4", "chunk3"]
    @test result.sources isa Vector{String}

    # Reduce number of candidates
    result = retrieve(simple, index, question;
        top_n = 2, top_k = 3,
        rephraser_kwargs = (; model = "mock-gen"),
        embedder_kwargs = (; model = "mock-emb"),
        tagger_kwargs = (; model = "mock-meta"), api_kwargs = (;
            url = "http://localhost:$(PORT)"))
    @test result.emb_candidates.positions == [2, 1, 4]
    @test result.reranked_candidates.positions == [2, 1]

    # with default dispatch
    result = retrieve(index, question;
        top_n = 2, top_k = 3,
        rephraser_kwargs = (; model = "mock-gen"),
        embedder_kwargs = (; model = "mock-emb"),
        tagger_kwargs = (; model = "mock-meta"), api_kwargs = (;
            url = "http://localhost:$(PORT)"))
    @test result.emb_candidates.positions == [2, 1, 4]
    @test result.reranked_candidates.positions == [2, 1]

    ## AdvancedRetriever
    adv = AdvancedRetriever()
    result = retrieve(adv, index, question;
        reranker = NoReranker(), # we need to disable cohere as we cannot test it
        rephraser_kwargs = (; model = "mock-gen"),
        embedder_kwargs = (; model = "mock-emb2"),
        tagger_kwargs = (; model = "mock-meta"), api_kwargs = (;
            url = "http://localhost:$(PORT)"))
    @test result.question == question
    @test result.rephrased_questions == [question, "Query: test question\n\nPassage:"] # from the template we use
    @test result.answer == nothing
    @test result.final_answer == nothing
    @test result.reranked_candidates.positions == [2, 1, 4, 3]
    @test result.context == ["chunk2", "chunk1", "chunk4", "chunk3"]
    @test result.sources isa Vector{String}

    # clean up
    close(echo_server)
end