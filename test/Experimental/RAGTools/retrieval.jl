using PromptingTools.Experimental.RAGTools: find_closest, find_tags
using PromptingTools.Experimental.RAGTools: Passthrough, rerank

@testset "find_closest" begin
    test_embeddings = [1.0 2.0; 3.0 4.0; 5.0 6.0] |>
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

    # Test behavior with edge values (top_k == 0)
    @test find_closest(test_embeddings, query_embedding, top_k = 0) == ([], [])
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
    @test rerank(strategy, index, question, candidate_chunks) === candidate_chunks
end