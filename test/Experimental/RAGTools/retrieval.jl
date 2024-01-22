using PromptingTools.Experimental.RAGTools: find_closest, find_tags
using PromptingTools.Experimental.RAGTools: Passthrough, rerank, CohereRerank

@testset "find_closest" begin
    test_embeddings = [1.0 2.0 -1.0; 3.0 4.0 -3.0; 5.0 6.0 -6.0] |>
                      x -> mapreduce(normalize, hcat, eachcol(x))
    query_embedding = [0.1, 0.35, 0.5] |> normalize
    positions, distances = find_closest(test_embeddings, query_embedding, top_k = 2)
    # The query vector should be closer to the first embedding
    @test positions == [1, 2]
    @test isapprox(distances, [0.9975694083904584
            0.9939123761133188], atol = 1e-3)

    # Test when top_k is more than available embeddings
    positions, _ = find_closest(test_embeddings, query_embedding, top_k = 5)
    @test length(positions) == size(test_embeddings, 2)

    # Test with minimum_similarity
    positions, _ = find_closest(test_embeddings, query_embedding, top_k = 5,
        minimum_similarity = 0.995)
    @test length(positions) == 1

    # Test behavior with edge values (top_k == 0)
    @test find_closest(test_embeddings, query_embedding, top_k = 0) == ([], [])

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
    mi = MultiIndex(id = :multi, indexes = [ci1, ci2])

    ## find_closest with ChunkIndex
    query_emb = [0.5, 0.5] # Example query embedding vector
    result = find_closest(ci1, query_emb)
    @test result isa CandidateChunks
    @test result.positions == [1, 2]
    @test all(1.0 .>= result.distances .>= -1.0)   # Assuming default minimum_similarity

    ## find_closest with MultiIndex
    ## query_emb = [0.5, 0.5] # Example query embedding vector
    ## result = find_closest(mi, query_emb)
    ## @test result isa CandidateChunks
    ## @test result.positions == [1, 2]
    ## @test all(1.0 .>= result.distances .>= -1.0)   # Assuming default minimum_similarity
end

@testset "find_tags" begin
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
    @test find_tags(index, "julia").positions == [1]
    @test find_tags(index, "julia").distances == [1.0]

    # Test for no tag found // not in vocab
    @test find_tags(index, "python").positions |> isempty
    @test find_tags(index, "java").positions |> isempty

    # Test with regex matching
    @test find_tags(index, r"^j").positions == [1, 2]

    # Test with multiple tags in vocab
    @test find_tags(index, ["python", "jr", "x"]).positions == [2]
end

@testset "rerank" begin
    # Mock data for testing
    index = "mock_index"
    question = "mock_question"
    candidate_chunks = ["chunk1", "chunk2", "chunk3"]

    # Passthrough Strategy
    strategy = Passthrough()
    @test rerank(strategy, index, question, candidate_chunks) ==
          candidate_chunks

    # Cohere assertion
    ci1 = ChunkIndex(id = :TestChunkIndex1,
        chunks = ["chunk1", "chunk2"],
        sources = ["source1", "source2"])
    ci2 = ChunkIndex(id = :TestChunkIndex2,
        chunks = ["chunk1", "chunk2"],
        sources = ["source1", "source2"])
    mi = MultiIndex(; id = :multi, indexes = [ci1, ci2])
    @test_throws ArgumentError rerank(CohereRerank(),
        mi,
        question,
        candidate_chunks)

    # Bad top_n
    @test_throws AssertionError rerank(CohereRerank(),
        ci1,
        question,
        candidate_chunks; top_n = 0)

    # Bad index_id
    cc2 = CandidateChunks(index_id = :TestChunkIndex2,
        positions = [1, 2],
        distances = [0.3, 0.4])
    @test_throws AssertionError rerank(CohereRerank(),
        ci1,
        question,
        cc2; top_n = 1)
end