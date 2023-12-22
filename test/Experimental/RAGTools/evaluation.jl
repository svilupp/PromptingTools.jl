using PromptingTools.Experimental.RAGTools: QAEvalItem
using PromptingTools.Experimental.RAGTools: score_retrieval_hit, score_retrieval_rank

@testset "QAEvalItem" begin
    empty_qa = QAEvalItem()
    @test !isvalid(empty_qa)
    full_qa = QAEvalItem(; question = "a", answer = "b", context = "c")
    @test isvalid(full_qa)
end

@testset "score_retrieval_hit,score_retrieval_rank" begin
    orig_context = "I am a horse."
    candidate_context = ["Hello", "World", "I am a horse...."]
    candidate_context2 = ["Hello", "I am a hors"]
    candidate_context3 = ["Hello", "World", "I am X horse...."]
    @test score_retrieval_hit(orig_context, candidate_context) == 1.0
    @test score_retrieval_hit(orig_context, candidate_context2) == 1.0
    @test score_retrieval_hit(orig_context, candidate_context[1:2]) == 0.0
    @test score_retrieval_hit(orig_context, candidate_context3) == 0.0

    @test score_retrieval_rank(orig_context, candidate_context) == 3
    @test score_retrieval_rank(orig_context, candidate_context2) == 2
    @test score_retrieval_rank(orig_context, candidate_context[1:2]) == nothing
    @test score_retrieval_rank(orig_context, candidate_context3) == nothing
end