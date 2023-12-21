@testset "rerank" begin
    # Mock data for testing
    index = "mock_index"
    question = "mock_question"
    candidate_chunks = ["chunk1", "chunk2", "chunk3"]

    # Passthrough Strategy
    strategy = Passthrough()
    @test rerank(strategy, index, question, candidate_chunks) === candidate_chunks
end