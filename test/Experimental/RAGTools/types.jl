
@testset "merge_labeled_matrices" begin
    # Test with dense matrices and overlapping vocabulary
    mat1 = [1 2; 3 4]
    vocab1 = ["word1", "word2"]
    mat2 = [5 6; 7 8]
    vocab2 = ["word2", "word3"]

    merged_mat, combined_vocab = merge_labeled_matrices(mat1, vocab1, mat2, vocab2)

    @test size(merged_mat) == (4, 3)
    @test combined_vocab == ["word1", "word2", "word3"]
    @test merged_mat == [1 2 0; 3 4 0; 0 5 6; 0 7 8]

    # Test with sparse matrices and disjoint vocabulary
    mat1 = sparse([1 0; 0 2])
    vocab1 = ["word1", "word2"]
    mat2 = sparse([3 0; 0 4])
    vocab2 = ["word3", "word4"]

    merged_mat, combined_vocab = merge_labeled_matrices(mat1, vocab1, mat2, vocab2)

    @test size(merged_mat) == (4, 4)
    @test combined_vocab == ["word1", "word2", "word3", "word4"]
    @test merged_mat == sparse([1 0 0 0; 0 2 0 0; 0 0 3 0; 0 0 0 4])

    # Test with different data types
    mat1 = [1.0 2.0; 3.0 4.0]
    vocab1 = ["word1", "word2"]
    mat2 = [5 6; 7 8]
    vocab2 = ["word2", "word3"]

    merged_mat, combined_vocab = merge_labeled_matrices(mat1, vocab1, mat2, vocab2)

    @test eltype(merged_mat) == Float64
    @test size(merged_mat) == (4, 3)
    @test combined_vocab == ["word1", "word2", "word3"]
    @test merged_mat ≈ [1.0 2.0 0.0; 3.0 4.0 0.0; 0.0 5.0 6.0; 0.0 7.0 8.0]
end

@testset "ChunkIndex and MultiIndex getindex Tests" begin
    @testset "ChunkIndex getindex" begin
        ci = ChunkIndex(:index1, ["chunk1", "chunk2", "chunk3"])
        candidate = CandidateChunks(:index1, [1, 3])

        @test getindex(ci, candidate) == ["chunk1", "chunk3"]
        @test getindex(ci, candidate, :chunks) == ["chunk1", "chunk3"]
        @test_throws AssertionError getindex(ci, candidate, :unsupported_field)

        # Test with non-matching index_id
        candidate_wrong_id = CandidateChunks(:index2, [1, 3])
        @test getindex(ci, candidate_wrong_id) == String[]
    end

    @testset "MultiIndex getindex" begin
        ci1 = ChunkIndex(:index1, ["chunk1", "chunk2"])
        ci2 = ChunkIndex(:index2, ["chunk3", "chunk4"])
        mi = MultiIndex([ci1, ci2])
        candidate = CandidateChunks(:index2, [2])

        @test getindex(mi, candidate) == ["chunk4"]
        @test getindex(mi, candidate, :chunks) == ["chunk4"]
        @test_throws AssertionError getindex(mi, candidate, :unsupported_field)

        # Test with non-existing index_id
        candidate_non_existing = CandidateChunks(:index3, [1])
        @test getindex(mi, candidate_non_existing) == String[]
    end
end

@testset "MultiIndex Equality Tests" begin
    index1 = ChunkIndex(:A)
    index2 = ChunkIndex(:B)
    index3 = ChunkIndex(:C)

    mi1 = MultiIndex([index1, index2])
    mi2 = MultiIndex([index1, index2])
    mi3 = MultiIndex([index2, index3])
    mi4 = MultiIndex([index1, index2, index3])
    mi5 = MultiIndex([index2, index1])

    @test mi1 == mi2  # Identical MultiIndexes
    @test mi1 != mi3  # Different indexes
    @test mi1 != mi4  # Different number of indexes
    @test mi3 != mi4  # Different indexes and different lengths
    @test mi1 == mi5  # Same indexes, different order
end

@testset "CandidateChunks" begin
    # Different Index IDs and Intersecting Positions
    cc1 = CandidateChunks(index_id = :index1,
        positions = [1, 2, 3],
        distances = [0.1, 0.2, 0.3])
    cc2 = CandidateChunks(index_id = :index2,
        positions = [2, 3, 4],
        distances = [0.3, 0.2, 0.1])
    cc3 = CandidateChunks(index_id = :index1,
        positions = [3, 4, 5],
        distances = [0.3, 0.4, 0.5])

    # Different index IDs
    result_diff_id = cc1 & cc2
    @test result_diff_id.index_id == :index1
    @test isempty(result_diff_id.positions)
    @test isempty(result_diff_id.distances)

    # Intersecting positions
    result_intersect = cc1 & cc3
    @test result_intersect.index_id == :index1
    @test result_intersect.positions == [3]
    @test result_intersect.distances ≈ [0.4]

    # Missing Distances
    cc1 = CandidateChunks(index_id = :index1, positions = [1, 2], distances = Float32[])
    cc2 = CandidateChunks(index_id = :index1, positions = [2, 3], distances = [0.2, 0.3])

    result = cc1 & cc2
    @test result.index_id == :index1
    @test result.positions == [2]
    @test isempty(result.distances)
end
