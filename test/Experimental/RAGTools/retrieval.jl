using PromptingTools: TestEchoOpenAISchema
using PromptingTools.Experimental.RAGTools: ContextEnumerator, NoRephraser, SimpleRephraser,
                                            HyDERephraser,
                                            CosineSimilarity, BinaryCosineSimilarity,
                                            MultiFinder, BM25Similarity,
                                            NoTagFilter, AnyTagFilter,
                                            SimpleRetriever, AdvancedRetriever
using PromptingTools.Experimental.RAGTools: AbstractRephraser, AbstractTagFilter,
                                            AbstractSimilarityFinder, AbstractReranker
using PromptingTools.Experimental.RAGTools: find_closest, hamming_distance, find_tags,
                                            rerank, rephrase,
                                            retrieve
using PromptingTools.Experimental.RAGTools: NoReranker, CohereReranker
using PromptingTools.Experimental.RAGTools: hamming_distance, BitPackedCosineSimilarity,
                                            pack_bits, unpack_bits
using PromptingTools.Experimental.RAGTools: bm25, document_term_matrix, DocumentTermMatrix

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

    ## ORIGINAL TESTS
    # Test for matching number of rows
    @test_throws ArgumentError hamming_distance(
        [true false; false true], [true, false, true])

    # Test for correct calculation of distances
    @test hamming_distance([true false; false true], [true, false]) == [0, 2]
    @test hamming_distance([true false; false true], [false, true]) == [2, 0]
    @test hamming_distance([true false; false true], [true, true]) == [1, 1]
    @test hamming_distance([true false; false true], [false, false]) == [1, 1]

    ## NEW TESTS
    # Test for Bool vectors
    vec1 = Bool[1, 0, 1, 0, 1, 0, 1, 0]
    vec2 = Bool[0, 1, 0, 1, 0, 1, 0, 1]
    # Basic functionality
    @test hamming_distance(vec1, vec2) == 8

    # Edge cases
    vec3 = Bool[1, 1, 1, 1, 1, 1, 1, 1]
    vec4 = Bool[0, 0, 0, 0, 0, 0, 0, 0]
    @test hamming_distance(vec3, vec4) == 8

    vec5 = Bool[1, 1, 1, 1, 1, 1, 1, 1]
    vec6 = Bool[1, 1, 1, 1, 1, 1, 1, 1]
    @test hamming_distance(vec5, vec6) == 0

    # Test for UInt64 (bitpacked) vectors
    vec7 = pack_bits(repeat(vec1, 8))
    vec8 = pack_bits(repeat(vec2, 8))
    @test hamming_distance(vec7, vec8) == 64

    vec9 = pack_bits(repeat(vec3, 8))
    vec10 = pack_bits(repeat(vec4, 8))
    @test hamming_distance(vec9, vec10) == 64

    vec11 = pack_bits(repeat(vec5, 8))
    vec12 = pack_bits(repeat(vec6, 8))
    @test hamming_distance(vec11, vec12) == 0

    # Test for Bool matrices
    mat1 = [vec1 vec2]
    mat2 = [vec3 vec4]
    @test hamming_distance(mat1, vec2) == [8, 0]
    @test hamming_distance(mat2, vec3) == [0, 8]

    # Test for UInt64 (bitpacked) matrices
    mat3 = pack_bits(repeat(mat1; outer = 8))
    mat4 = pack_bits(repeat(mat2; outer = 8))
    @test hamming_distance(mat3, vec8) == [64, 0]
    @test hamming_distance(mat4, vec9) == [0, 64]

    # Test for mismatched dimensions
    vec13 = Bool[1, 0, 1]
    @test_throws ArgumentError hamming_distance(mat1, vec13)

    # Additional edge cases
    # Empty vectors
    vec_empty1 = Bool[]
    vec_empty2 = Bool[]
    @test hamming_distance(vec_empty1, vec_empty2) == 0

    # Single element vectors
    vec_single1 = Bool[1]
    vec_single2 = Bool[0]
    @test hamming_distance(vec_single1, vec_single2) == 1

    # Large vectors
    vec_large1 = Bool[1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0,
        1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0]
    vec_large2 = Bool[0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1,
        0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1]
    @test hamming_distance(vec_large1, vec_large2) == 32

    # Large vectors with bitpacking
    vec_large_packed1 = pack_bits(repeat(vec_large1, 2))
    vec_large_packed2 = pack_bits(repeat(vec_large2, 2))
    @test hamming_distance(vec_large_packed1, vec_large_packed2) == 64

    ## Compare packed vs binary results
    mat_rand1 = rand(Bool, 128, 10)
    q_rand2 = rand(Bool, 128)
    hamming_dist_binary = hamming_distance(mat_rand1, q_rand2)
    hamming_dist_packed = hamming_distance(pack_bits(mat_rand1), pack_bits(q_rand2))
    @test hamming_dist_binary == hamming_dist_packed
end

@testset "bm25" begin
    # Simple case
    documents = [["this", "is", "a", "test"],
        ["this", "is", "another", "test"], ["foo", "bar", "baz"]]
    dtm = document_term_matrix(documents)
    query = ["this"]
    scores = bm25(dtm, query)
    idf = log(1 + (3 - 2 + 0.5) / (2 + 0.5))
    tf = 1
    expected = idf * (tf * (1.2 + 1)) /
               (tf + 1.2 * (1 - 0.75 + 0.75 * 4 / 3.666666666666667))
    @test scores[1] ≈ expected
    @test scores[2] ≈ expected
    @test scores[3] ≈ 0

    # Two words, both existing
    query = ["this", "test"]
    scores = bm25(dtm, query)
    @test scores[1] ≈ expected * 2
    @test scores[2] ≈ expected * 2
    @test scores[3] ≈ 0

    # Multiwords with no hits
    query = ["baz", "unknown", "words", "xyz"]
    scores = bm25(dtm, query)
    idf = log(1 + (3 - 1 + 0.5) / (1 + 0.5))
    tf = 1
    expected = idf * (tf * (1.2 + 1)) /
               (tf + 1.2 * (1 - 0.75 + 0.75 * 3 / 3.666666666666667))
    @test scores[1] ≈ 0
    @test scores[2] ≈ 0
    @test scores[3] ≈ expected

    # Edge case: empty query
    @test bm25(dtm, String[]) == zeros(Float32, size(dtm.tf, 1))

    # Edge case: query with no matches
    query = ["food", "bard"]
    @test bm25(dtm, query) == zeros(Float32, size(dtm.tf, 1))

    # Edge case: query with multiple matches and repeats
    query = ["this", "is", "this", "this"]
    scores = bm25(dtm, query)
    idf = log(1 + (3 - 2 + 0.5) / (2 + 0.5))
    tf = 1
    expected = idf * (tf * (1.2 + 1)) /
               (tf + 1.2 * (1 - 0.75 + 0.75 * 4 / 3.666666666666667))
    @test scores[1] ≈ expected * 4
    @test scores[2] ≈ expected * 4
    @test scores[3] ≈ 0
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
    @test isempty(scores)

    ### Sense check for approximate methods

    # Generate random embeddings as a sense check
    Random.seed!(1234)  # For reproducibility
    emb = mapreduce(normalize, hcat, eachcol(randn(128, 1000)))
    query_emb = randn(128) |> normalize  # Normalize the query embedding

    # Calculate positions and scores using normal CosineSimilarity
    positions_cosine, scores_cosine = find_closest(
        CosineSimilarity(), emb, query_emb; top_k = 10)

    # Calculate positions and scores using BinaryCosineSimilarity
    binary_emb = map(>(0), emb)
    positions_binary, scores_binary = find_closest(
        BinaryCosineSimilarity(), binary_emb, query_emb; top_k = 10)
    @test length(intersect(positions_cosine, positions_binary)) >= 1

    # Calculate positions and scores using BinaryCosineSimilarity
    packed_emb = pack_bits(binary_emb)
    positions_packed, scores_packed = find_closest(
        BitPackedCosineSimilarity(), packed_emb, query_emb; top_k = 10)
    @test length(intersect(positions_cosine, positions_packed)) >= 1
end

## find_closest with MultiIndex
## mi = MultiIndex(id = :multi, indexes = [ci1, ci2])
## query_emb = [0.5, 0.5] # Example query embedding vector
## result = find_closest(mi, query_emb)
## @test result isa CandidateChunks
## @test result.positions == [1, 2]
## @test all(1.0 .>= result.distances .>= -1.0)   # Assuming default minimum_similarity

@testset "find_closest-MultiIndex" begin
    # Create mock data for testing
    emb1 = [0.1 0.2; 0.3 0.4; 0.5 0.6] |> x -> mapreduce(normalize, hcat, eachcol(x))
    emb2 = [0.7 0.8; 0.9 1.0; 1.1 1.2] |> x -> mapreduce(normalize, hcat, eachcol(x))
    query_emb = [0.1, 0.2, 0.3] |> normalize

    # Create ChunkIndex instances
    index1 = ChunkEmbeddingsIndex(id = :index1, chunks = ["chunk1", "chunk2"],
        embeddings = emb1, sources = ["source1", "source2"])
    index2 = ChunkEmbeddingsIndex(id = :index2, chunks = ["chunk3", "chunk4"],
        embeddings = emb2, sources = ["source3", "source4"])

    # Create MultiIndex instance
    multi_index = MultiIndex(id = :multi, indexes = [index1, index2])

    # Create MultiFinder instance
    multi_finder = MultiFinder([CosineSimilarity(), CosineSimilarity()])

    # Perform find_closest with MultiFinder
    result = find_closest(multi_finder, multi_index, query_emb; top_k = 2)
    @test result isa MultiCandidateChunks
    @test result.index_ids == [:index1, :index2]
    @test result.positions == [2, 1]
    @test query_emb' * emb1[:, 2] ≈ result.scores[1]
    @test query_emb' * emb2[:, 1] ≈ result.scores[2]
    # Check that the positions and scores are sorted correctly
    @test result.scores[1] >= result.scores[2]

    result = find_closest(multi_finder, multi_index, query_emb; top_k = 20)
    @test length(result.index_ids) == 4
    @test length(result.positions) == 4
    @test length(result.scores) == 4

    ## No embeddings
    index1 = ChunkEmbeddingsIndex(id = :index1, chunks = ["chunk1", "chunk2"],
        sources = ["source1", "source2"])
    index2 = ChunkEmbeddingsIndex(id = :index2, chunks = ["chunk3", "chunk4"],
        sources = ["source3", "source4"])
    result = find_closest(MultiFinder([CosineSimilarity(), CosineSimilarity()]),
        MultiIndex(id = :multi, indexes = [index1, index2]), query_emb; top_k = 20)
    @test isempty(result.index_ids)
    @test isempty(result.positions)
    @test isempty(result.scores)

    ### With mixed index types
    # Create mock data for testing
    emb1 = [0.1 0.2; 0.3 0.4; 0.5 0.6] |> x -> mapreduce(normalize, hcat, eachcol(x))
    query_emb = [0.1, 0.2, 0.3] |> normalize
    query_keywords = ["example", "query"]

    # Create ChunkIndex instances
    index1 = ChunkEmbeddingsIndex(id = :index1, chunks = ["chunk1", "chunk2"],
        embeddings = emb1, sources = ["source1", "source2"])
    index2 = ChunkKeywordsIndex(id = :index2, chunks = ["chunk3", "chunk4"],
        chunkdata = document_term_matrix([["example", "query"], ["random", "words"]]),
        sources = ["source3", "source4"])

    # Create MultiIndex instance
    multi_index = MultiIndex(id = :multi, indexes = [index1, index2])

    # Create MultiFinder instance
    multi_finder = MultiFinder([CosineSimilarity(), BM25Similarity()])

    # Perform find_closest with MultiFinder
    result = find_closest(multi_finder, multi_index, query_emb, query_keywords; top_k = 2)
    @test result isa MultiCandidateChunks
    @test result.index_ids == [:index2, :index1]
    @test result.positions == [1, 2]
    @test isapprox(result.scores, [1.387, 1.0], atol = 1e-1)
    # Check that the positions and scores are sorted correctly
    @test result.scores[1] >= result.scores[2]

    result = find_closest(multi_finder, multi_index, query_emb, query_keywords; top_k = 20)
    @test length(result.index_ids) == 4
    @test length(result.positions) == 4
    @test length(result.scores) == 4

    @test HasEmbeddings(index1)
    @test !HasEmbeddings(index2)
    @test HasEmbeddings(multi_index)
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

    ## Multi-index implementation
    # TODO: add AnyTag
    emb1 = [0.1 0.2; 0.3 0.4; 0.5 0.6] |> x -> mapreduce(normalize, hcat, eachcol(x))
    index1 = ChunkEmbeddingsIndex(id = :index1, chunks = ["chunk1", "chunk2"],
        embeddings = emb1, sources = ["source1", "source2"])
    index2 = ChunkKeywordsIndex(id = :index2, chunks = ["chunk3", "chunk4"],
        chunkdata = document_term_matrix([["example", "query"], ["random", "words"]]),
        sources = ["source3", "source4"])

    # Create MultiIndex instance
    multi_index = MultiIndex(id = :multi, indexes = [index1, index2])

    mcc = find_tags(NoTagFilter(), multi_index, "julia")
    @test mcc.positions == [1, 2, 3, 4]
    @test mcc.scores == [0.0, 0.0, 0.0, 0.0]

    mcc = find_tags(NoTagFilter(), multi_index, nothing)
    @test mcc.positions == [1, 2, 3, 4]
    @test mcc.scores == [0.0, 0.0, 0.0, 0.0]
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

    ci2 = ChunkIndex(id = :TestChunkIndex2,
        chunks = ["chunk1", "chunk2"],
        sources = ["source1", "source2"])
    mi = MultiIndex(; id = :multi, indexes = [ci1, ci2])
    reranked = rerank(NoReranker(),
        mi,
        question,
        cc1)
    @test reranked.positions == [2, 1] # gets resorted by score
    @test reranked.scores == [0.4, 0.3]

    # Cohere assertion
    ## @test reranked isa MultiCandidateChunks

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

    # Multi-index retriever
    index_keywords = ChunkKeywordsIndex(index, index_id = :TestChunkIndexX)
    # Create MultiIndex instance
    multi_index = MultiIndex(id = :multi, indexes = [index, index_keywords])

    # Create MultiFinder instance
    finder = MultiFinder([RT.CosineSimilarity(), RT.BM25Similarity()])
    retriever = SimpleRetriever(; processor = RT.KeywordsProcessor(), finder)
    result = retrieve(retriever, multi_index, question;
        reranker = NoReranker(), # we need to disable cohere as we cannot test it
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
    @test result.sources == ["source2", "source1", "source4", "source3"]

    # clean up
    close(echo_server)
end
