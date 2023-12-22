using PromptingTools.Experimental.RAGTools: _check_aiextract_capability,
    merge_labeled_matrices

@testset "_check_aiextract_capability" begin
    @test _check_aiextract_capability("gpt-3.5-turbo") == nothing
    @test_throws AssertionError _check_aiextract_capability("llama2")
end

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