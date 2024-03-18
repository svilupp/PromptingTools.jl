using PromptingTools.Experimental.RAGTools: QAItem, QAEvalItem, QAEvalResult
using PromptingTools.Experimental.RAGTools: score_retrieval_hit, score_retrieval_rank
using PromptingTools.Experimental.RAGTools: build_qa_evals, run_qa_evals, chunks, sources
using PromptingTools.Experimental.RAGTools: JudgeAllScores, Tag, MaybeTags

@testset "QAEvalItem" begin
    empty_qa = QAEvalItem()
    @test !isvalid(empty_qa)
    full_qa = QAEvalItem(; question = "a", answer = "b", context = "c")
    @test isvalid(full_qa)
end

@testset "Base.show,JSON3.write" begin
    # Helper function to simulate the IO capture for custom show methods
    function capture_show(io::IOBuffer, x)
        show(io, x)
        return String(take!(io))
    end

    # Testing Base.show for QAItem
    qa_item = QAItem("What is Julia?",
        "Julia is a high-level, high-performance programming language.")

    test_output = capture_show(IOBuffer(), qa_item)
    @test test_output ==
          "QAItem:\n question: What is Julia?\n answer: Julia is a high-level, high-performance programming language.\n"
    json_output = JSON3.write(qa_item)
    @test JSON3.read(json_output, QAItem) == qa_item

    # Testing Base.show for QAEvalItem
    qa_eval_item = QAEvalItem(source = "testsource.jl",
        context = "Julia is a high-level, high-performance programming language.",
        question = "What is Julia?",
        answer = "A language.")

    test_output = capture_show(IOBuffer(), qa_eval_item)
    @test test_output ==
          "QAEvalItem:\n source: testsource.jl\n context: Julia is a high-level, high-performance programming language.\n question: What is Julia?\n answer: A language.\n"
    json_output = JSON3.write(qa_eval_item)
    @test JSON3.read(json_output, QAEvalItem) == qa_eval_item

    # Testing Base.show for QAEvalResult
    params = Dict(:key1 => "value1", :key2 => 2)
    qa_eval_result = QAEvalResult(source = "testsource.jl",
        context = "Julia is amazing for technical computing.",
        question = "Why is Julia good?",
        answer = "Because of its speed and ease of use.",
        retrieval_score = 0.89,
        retrieval_rank = 1,
        answer_score = 100.0,
        parameters = params)

    test_output = capture_show(IOBuffer(), qa_eval_result)
    @test test_output ==
          "QAEvalResult:\n source: testsource.jl\n context: Julia is amazing for technical computing.\n question: Why is Julia good?\n answer: Because of its speed and ease of use.\n retrieval_score: 0.89\n retrieval_rank: 1\n answer_score: 100.0\n parameters: Dict{Symbol, Any}(:key2 => 2, :key1 => \"value1\")\n"
    json_output = JSON3.write(qa_eval_result)
    @test JSON3.read(json_output, QAEvalResult) == qa_eval_result
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

@testset "build_qa_evals" begin
    # test with a mock server
    PORT = rand(10001:40001)
    PT.register_model!(; name = "mock-emb", schema = PT.CustomOpenAISchema())
    PT.register_model!(; name = "mock-meta", schema = PT.CustomOpenAISchema())
    PT.register_model!(; name = "mock-gen", schema = PT.CustomOpenAISchema())
    PT.register_model!(; name = "mock-qa", schema = PT.CustomOpenAISchema())
    PT.register_model!(; name = "mock-judge", schema = PT.CustomOpenAISchema())

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
            # for i in 1:length(content[:input])
            response = Dict(:data => [Dict(:embedding => ones(Float32, 128))],
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
        elseif content[:model] == "mock-qa"
            user_msg = last(content[:messages])
            response = Dict(
                :choices => [
                    Dict(:finish_reason => "stop",
                    :message => Dict(:tool_calls => [
                        Dict(:function => Dict(:arguments => JSON3.write(QAItem("Question",
                        "Answer"))))]))],
                :model => content[:model],
                :usage => Dict(:total_tokens => length(user_msg[:content]),
                    :prompt_tokens => length(user_msg[:content]),
                    :completion_tokens => 0))
        elseif content[:model] == "mock-judge"
            user_msg = last(content[:messages])
            response = Dict(
                :choices => [
                    Dict(:message => Dict(:tool_calls => [
                    Dict(:function => Dict(:arguments => JSON3.write(JudgeAllScores(5,
                    5,
                    5,
                    5,
                    5,
                    "Some reasons",
                    5.0))))]))],
                :model => content[:model],
                :usage => Dict(:total_tokens => length(user_msg[:content]),
                    :prompt_tokens => length(user_msg[:content]),
                    :completion_tokens => 0))
        else
            @info content
        end
        return HTTP.Response(200, JSON3.write(response))
    end

    # Index setup
    index = ChunkIndex(;
        sources = [".", ".", "."],
        chunks = ["a", "b", "c"],
        embeddings = zeros(128, 3),
        tags = vcat(trues(2, 2), falses(1, 2)),
        tags_vocab = ["yes", "no"])

    # Test for successful Q&A extraction from document chunks
    qa_evals = build_qa_evals(chunks(index),
        sources(index),
        instructions = "Some instructions.",
        model = "mock-qa",
        api_kwargs = (; url = "http://localhost:$(PORT)"))

    @test length(qa_evals) == length(chunks(index))
    @test all(getproperty.(qa_evals, :source) .== ".")
    @test all(getproperty.(qa_evals, :context) == ["a", "b", "c"])
    @test all(getproperty.(qa_evals, :question) .== "Question")
    @test all(getproperty.(qa_evals, :answer) .== "Answer")

    # Error checks
    @test_throws AssertionError build_qa_evals(chunks(index),
        String[])
    @test_throws AssertionError build_qa_evals(chunks(index),
        String[]; qa_template = :BlankSystemUser)

    # Test run_qa_evals on 1 item
    result = airag(index; question = qa_evals[1].question, model_embedding = "mock-emb",
        model_chat = "mock-gen",
        model_metadata = "mock-meta", api_kwargs = (; url = "http://localhost:$(PORT)"),
        tag_filter = :auto,
        extract_metadata = false, verbose = false,
        return_all = true)

    result = run_qa_evals(qa_evals[1], ctx;
        model_judge = "mock-judge",
        api_kwargs = (; url = "http://localhost:$(PORT)"),
        parameters_dict = Dict(:key1 => "value1", :key2 => 2))
    @test result.retrieval_score == 1.0
    @test result.retrieval_rank == 1
    @test result.answer_score == 5
    @test result.parameters == Dict(:key1 => "value1", :key2 => 2)

    # Test all evals at once
    # results = run_qa_evals(index, qa_evals; model_judge = "mock-judge",
    #     api_kwargs = (; url = "http://localhost:$(PORT)"))
    results = run_qa_evals(index, qa_evals;
        airag_kwargs = (;
            model_embedding = "mock-emb",
            model_chat = "mock-gen",
            model_metadata = "mock-meta"),
        qa_evals_kwargs = (; model_judge = "mock-judge"),
        api_kwargs = (; url = "http://localhost:$(PORT)"),
        parameters_dict = Dict(:key1 => "value1", :key2 => 2))

    @test length(results) == length(qa_evals)
    @test all(getproperty.(results, :retrieval_score) .== 1.0)
    @test all(getproperty.(results, :retrieval_rank) .== 1)
    @test all(getproperty.(results, :answer_score) .== 5)
    @test all(getproperty.(results, :parameters) .==
              Ref(Dict(:key1 => "value1", :key2 => 2)))
    # clean up
    close(echo_server)
end
