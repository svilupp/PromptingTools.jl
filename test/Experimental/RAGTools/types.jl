using PromptingTools.Experimental.RAGTools: ChunkIndex, MultiIndex, CandidateChunks,
                                            AbstractCandidateChunks
using PromptingTools.Experimental.RAGTools: embeddings, chunks, tags, tags_vocab, sources

@testset "ChunkIndex" begin
    # Test constructors and basic accessors
    chunks_test = ["chunk1", "chunk2"]
    emb_test = ones(2, 2)
    tags_test = sparse([1, 2], [1, 2], [true, true], 2, 2)
    tags_vocab_test = ["vocab1", "vocab2"]
    sources_test = ["source1", "source2"]
    ci = ChunkIndex(chunks = chunks_test,
        embeddings = emb_test,
        tags = tags_test,
        tags_vocab = tags_vocab_test,
        sources = sources_test)

    @test chunks(ci) == chunks_test
    @test (embeddings(ci)) == emb_test
    @test tags(ci) == tags_test
    @test tags_vocab(ci) == tags_vocab_test
    @test sources(ci) == sources_test

    # Test identity/equality
    ci1 = ChunkIndex(chunks = ["chunk1", "chunk2"], sources = ["source1", "source2"])
    ci2 = ChunkIndex(chunks = ["chunk1", "chunk2"], sources = ["source1", "source2"])
    @test ci1 == ci2

    # Test equality with different chunks and sources
    ci2 = ChunkIndex(chunks = ["chunk3", "chunk4"], sources = ["source3", "source4"])
    @test ci1 != ci2

    # Test hcat with ChunkIndex
    # Setup two different ChunkIndex with different tags and then hcat them
    chunks1 = ["chunk1", "chunk2"]
    tags1 = sparse([1, 2], [1, 2], [true, true], 2, 3)
    tags_vocab1 = ["vocab1", "vocab2", "vocab3"]
    sources1 = ["source1", "source1"]
    ci1 = ChunkIndex(chunks = chunks1,
        tags = tags1,
        tags_vocab = tags_vocab1,
        sources = sources1)

    chunks2 = ["chunk3", "chunk4"]
    tags2 = sparse([1, 2], [1, 3], [true, true], 2, 3)
    tags_vocab2 = ["vocab1", "vocab3", "vocab4"]
    sources2 = ["source2", "source2"]
    ci2 = ChunkIndex(chunks = chunks2,
        tags = tags2,
        tags_vocab = tags_vocab2,
        sources = sources2)

    combined_ci = vcat(ci1, ci2)
    @test size(tags(combined_ci), 1) == 4
    @test size(tags(combined_ci), 2) == 4
    @test length(unique(vcat(tags_vocab(ci1), tags_vocab(ci2)))) ==
          length(tags_vocab(combined_ci))
    @test sources(combined_ci) == vcat(sources(ci1), (sources(ci2)))

    # Test base var"==" with ChunkIndex
    ci1 = ChunkIndex(chunks = ["chunk1"],
        tags = trues(3, 1),
        tags_vocab = ["vocab1"],
        sources = ["source1"])
    ci2 = ChunkIndex(chunks = ["chunk1"],
        tags = trues(3, 1),
        tags_vocab = ["vocab1"],
        sources = ["source1"])
    @test ci1 == ci2
end

@testset "MultiIndex" begin
    # Test constructors/accessors
    # MultiIndex behaves as a container for ChunkIndexes
    cin1 = ChunkIndex(chunks = ["chunk1"], sources = ["source1"])
    cin2 = ChunkIndex(chunks = ["chunk2"], sources = ["source2"])
    multi_index = MultiIndex(indexes = [cin1, cin2])
    @test length(multi_index.indexes) == 2
    @test cin1 in multi_index.indexes
    @test cin2 in multi_index.indexes

    # Test base var"==" with MultiIndex
    # Case where MultiIndexes are equal
    cin1 = ChunkIndex(chunks = ["chunk1"], sources = ["source1"])
    cin2 = ChunkIndex(chunks = ["chunk2"], sources = ["source2"])
    mi1 = MultiIndex(indexes = [cin1, cin2])
    mi2 = MultiIndex(indexes = [cin1, cin2])
    @test mi1 == mi2

    # Test equality with different ChunkIndexes inside
    cin1 = ChunkIndex(chunks = ["chunk1"], sources = ["source1"])
    cin2 = ChunkIndex(chunks = ["chunk2"], sources = ["source2"])
    mi1 = MultiIndex(indexes = [cin1])
    mi2 = MultiIndex(indexes = [cin2])
    @test mi1 != mi2

    ## not implemented
    @test_throws ArgumentError vcat(mi1, mi2)
end

@testset "CandidateChunks" begin
    chunk_sym = Symbol("TestChunkIndex")
    cc1 = CandidateChunks(index_id = chunk_sym,
        positions = [1, 3],
        scores = [0.1, 0.2])
    @test Base.length(cc1) == 2
    out = Base.first(cc1, 1)
    @test out.positions == [3]
    @test out.scores == [0.2]

    # Test intersection &
    cc2 = CandidateChunks(index_id = chunk_sym,
        positions = [2, 4],
        scores = [0.3, 0.4])
    @test isempty((cc1 & cc2).positions)
    cc3 = CandidateChunks(index_id = chunk_sym,
        positions = [1, 4],
        scores = [0.3, 0.5])
    joint = (cc1 & cc3)
    @test joint.positions == [1]
    @test joint.scores == [0.3]
    joint2 = (cc2 & cc3)
    @test joint2.positions == [4]
    @test joint2.scores == [0.5]

    # long positions intersection
    cc5 = CandidateChunks(index_id = chunk_sym,
        positions = [5, 6, 7, 8, 9, 10, 4],
        scores = 0.1 * ones(7))
    joint5 = (cc2 & cc5)
    @test joint5.positions == [4]
    @test joint5.scores == [0.4]

    # wrong index
    cc4 = CandidateChunks(index_id = :xyz,
        positions = [2, 4],
        scores = [0.3, 0.4])
    joint4 = (cc2 & cc4)
    @test isempty(joint4.positions)
    @test isempty(joint4.scores)
    @test isempty(joint4) == true

    # Test unknown type
    struct RandomCandidateChunks123 <: AbstractCandidateChunks end
    @test_throws ArgumentError (cc1&RandomCandidateChunks123())

    # Test vcat
    vcat1 = vcat(cc1, cc2)
    @test Base.length(vcat1) == 4
    vcat2 = vcat(cc1, cc3)
    @test vcat2.positions == [4, 1, 3]
    @test vcat2.scores == [0.5, 0.3, 0.2]
    # wrong index
    @test_throws ArgumentError vcat(cc1, cc4)
    # uknown type
    @test_throws ArgumentError vcat(cc1, RandomCandidateChunks123())

    # Test copy
    cc1_copy = copy(cc1)
    @test cc1 == cc1_copy
    @test cc1.positions !== cc1_copy.positions # not the same array
end

@testset "getindex with CandidateChunks" begin
    # Initialize a ChunkIndex with test data
    chunks_data = ["First chunk", "Second chunk", "Third chunk"]
    embeddings_data = rand(3, 3)  # Random matrix with 3 embeddings
    tags_data = sparse(Bool[1 1; 0 1; 1 0])  # Some arbitrary sparse matrix representation
    tags_vocab_data = ["tag1", "tag2"]
    chunk_sym = Symbol("TestChunkIndex")
    test_chunk_index = ChunkIndex(chunks = chunks_data,
        embeddings = embeddings_data,
        tags = tags_data,
        tags_vocab = tags_vocab_data,
        sources = repeat(["test_source"], 3),
        id = chunk_sym)

    # Test to get chunks based on valid CandidateChunks
    candidate_chunks = CandidateChunks(index_id = chunk_sym,
        positions = [1, 3],
        scores = [0.1, 0.2])
    @test collect(test_chunk_index[candidate_chunks]) == ["First chunk", "Third chunk"]
    @test collect(test_chunk_index[candidate_chunks, :chunks]) ==
          ["First chunk", "Third chunk"]
    @test collect(test_chunk_index[candidate_chunks, :sources]) ==
          ["test_source", "test_source"]
    @test collect(test_chunk_index[candidate_chunks, :embeddings]) ==
          embeddings_data[:, [1, 3]]

    # Test with empty positions, which should result in an empty array
    candidate_chunks_empty = CandidateChunks(index_id = chunk_sym,
        positions = Int[],
        scores = Float32[])
    @test isempty(test_chunk_index[candidate_chunks_empty])
    @test isempty(test_chunk_index[candidate_chunks_empty, :chunks])
    @test isempty(test_chunk_index[candidate_chunks_empty, :embeddings])
    @test isempty(test_chunk_index[candidate_chunks_empty, :sources])

    # Test with positions out of bounds, should handle gracefully without errors
    candidate_chunks_oob = CandidateChunks(index_id = chunk_sym,
        positions = [10, -1],
        scores = [0.5, 0.6])
    @test_throws AssertionError test_chunk_index[candidate_chunks_oob]

    # Test with an incorrect index_id, which should also result in an empty array
    wrong_sym = Symbol("InvalidIndex")
    candidate_chunks_wrong_id = CandidateChunks(index_id = wrong_sym,
        positions = [1, 2],
        scores = [0.3, 0.4])
    @test isempty(test_chunk_index[candidate_chunks_wrong_id])

    # Test when chunks are requested from a MultiIndex, only chunks from the corresponding ChunkIndex should be returned
    another_chuck_index = ChunkIndex(chunks = chunks_data,
        embeddings = nothing,
        tags = nothing,
        tags_vocab = nothing,
        sources = repeat(["another_source"], 3),
        id = Symbol("AnotherChunkIndex"))
    test_multi_index = MultiIndex(indexes = [
        test_chunk_index,
        another_chuck_index
    ])
    @test collect(test_multi_index[candidate_chunks]) == ["First chunk", "Third chunk"]

    # Test when wrong index_id is used with MultiIndex, resulting in an empty array
    @test isempty(test_multi_index[candidate_chunks_wrong_id])

    # Test error case when trying to use a non-chunks field, should assert error as only :chunks field is supported
    @test_throws AssertionError test_chunk_index[candidate_chunks, :nonexistent_field]

    # Multi-Candidate CandidateChunks
    cc1 = CandidateChunks(index_id = :TestChunkIndex1,
        positions = [1, 2],
        scores = [0.3, 0.4])
    cc2 = CandidateChunks(index_id = :TestChunkIndex2,
        positions = [2],
        scores = [0.1])
    cc = CandidateChunks(; index_id = :multi, positions = [cc1, cc2], scores = zeros(2))
    ci1 = ChunkIndex(id = :TestChunkIndex1,
        chunks = ["chunk1", "chunk2"],
        sources = ["source1", "source2"])
    ci2 = ChunkIndex(id = :TestChunkIndex2,
        chunks = ["chunk1", "chunk2"],
        sources = ["source1", "source2"])
    @test ci1[cc] == ["chunk1", "chunk2"]
    @test ci2[cc] == ["chunk2"]

    # with MultiIndex
    mi = MultiIndex(; id = :multi, indexes = [ci1, ci2])
    @test mi[cc] == ["chunk1", "chunk2", "chunk2"]
end
