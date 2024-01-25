using PromptingTools.Experimental.RAGTools: metadata_extract, MetadataItem
using PromptingTools.Experimental.RAGTools: MaybeMetadataItems, build_tags, build_index

@testset "metadata_extract" begin
    # MetadataItem Structure
    item = MetadataItem("value", "category")
    @test item.value == "value"
    @test item.category == "category"

    # MaybeMetadataItems Structure
    items = MaybeMetadataItems([
        MetadataItem("value1", "category1"),
        MetadataItem("value2", "category2"),
    ])
    @test length(items.items) == 2
    @test items.items[1].value == "value1"
    @test items.items[1].category == "category1"

    empty_items = MaybeMetadataItems(nothing)
    @test isempty(metadata_extract(empty_items.items))

    # Metadata Extraction Function
    single_item = MetadataItem("DataFrames", "Julia Package")
    multiple_items = [
        MetadataItem("pandas", "Software"),
        MetadataItem("Python", "Language"),
        MetadataItem("DataFrames", "Julia Package"),
    ]

    @test metadata_extract(single_item) == "julia_package:::dataframes"
    @test metadata_extract(multiple_items) ==
          ["software:::pandas", "language:::python", "julia_package:::dataframes"]

    @test metadata_extract(nothing) == String[]
end

@testset "build_tags" begin
    # Single Tag
    chunk_metadata = [["tag1"]]
    tags_, tags_vocab_ = build_tags(chunk_metadata)

    @test length(tags_vocab_) == 1
    @test tags_vocab_ == ["tag1"]
    @test nnz(tags_) == 1
    @test tags_[1, 1] == true

    # Multiple Tags with Repetition
    chunk_metadata = [["tag1", "tag2"], ["tag2", "tag3"]]
    tags_, tags_vocab_ = build_tags(chunk_metadata)

    @test length(tags_vocab_) == 3
    @test tags_vocab_ == ["tag1", "tag2", "tag3"]
    @test nnz(tags_) == 4
    @test all([tags_[1, 1], tags_[1, 2], tags_[2, 2], tags_[2, 3]])

    # Empty Metadata
    chunk_metadata = [String[]]
    tags_, tags_vocab_ = build_tags(chunk_metadata)

    @test isempty(tags_vocab_)
    @test size(tags_) == (1, 0)

    # Mixed Empty and Non-Empty Metadata
    chunk_metadata = [["tag1"], String[], ["tag2", "tag3"]]
    tags_, tags_vocab_ = build_tags(chunk_metadata)

    @test length(tags_vocab_) == 3
    @test tags_vocab_ == ["tag1", "tag2", "tag3"]
    @test nnz(tags_) == 3
    @test all([tags_[1, 1], tags_[3, 2], tags_[3, 3]])
end

@testset "build_index" begin
    # test with a mock server
    PORT = rand(9000:11000)
    PT.register_model!(; name = "mock-emb", schema = PT.CustomOpenAISchema())
    PT.register_model!(; name = "mock-meta", schema = PT.CustomOpenAISchema())
    PT.register_model!(; name = "mock-get", schema = PT.CustomOpenAISchema())

    echo_server = HTTP.serve!(PORT; verbose = -1) do req
        content = JSON3.read(req.body)

        if content[:model] == "mock-gen"
            user_msg = last(content[:messages])
            response = Dict(:choices => [Dict(:message => user_msg)],
                :model => content[:model],
                :usage => Dict(:total_tokens => length(user_msg[:content]),
                    :prompt_tokens => length(user_msg[:content]),
                    :completion_tokens => 0))
        elseif content[:model] == "mock-emb"
            response = Dict(:data => [Dict(:embedding => ones(Float32, 128))
                                      for i in 1:length(content[:input])],
                :usage => Dict(:total_tokens => length(content[:input]),
                    :prompt_tokens => length(content[:input]),
                    :completion_tokens => 0))
        elseif content[:model] == "mock-meta"
            user_msg = last(content[:messages])
            response = Dict(:choices => [
                    Dict(:message => Dict(:function_call => Dict(:arguments => JSON3.write(MaybeMetadataItems([
                        MetadataItem("yes", "category"),
                    ]))))),
                ],
                :model => content[:model],
                :usage => Dict(:total_tokens => length(user_msg[:content]),
                    :prompt_tokens => length(user_msg[:content]),
                    :completion_tokens => 0))
        else
            @info content
        end
        return HTTP.Response(200, JSON3.write(response))
    end

    text = "This is a long text that will be split into chunks.\n\n It will be split by the separator. And also by the separator '\n'."
    tmp, _ = mktemp()
    write(tmp, text)
    mini_files = [tmp, tmp]
    index = build_index(mini_files; max_length = 10, extract_metadata = true,
        model_embedding = "mock-emb",
        model_metadata = "mock-meta", api_kwargs = (; url = "http://localhost:$(PORT)"))
    @test index.embeddings == hcat(fill(normalize(ones(Float32, 128)), 8)...)
    @test index.chunks[1:4] == index.chunks[5:8]
    @test index.sources == fill(tmp, 8)
    @test index.tags == ones(8, 1)
    @test index.tags_vocab == ["category:::yes"]

    ## Test docs reader
    index = build_index([text, text]; reader = :docs, sources = ["x", "x"], max_length = 10,
        extract_metadata = true,
        model_embedding = "mock-emb",
        model_metadata = "mock-meta", api_kwargs = (; url = "http://localhost:$(PORT)"))
    @test index.embeddings == hcat(fill(normalize(ones(Float32, 128)), 8)...)
    @test index.chunks[1:4] == index.chunks[5:8]
    @test index.sources == fill("x", 8)
    @test index.tags == ones(8, 1)
    @test index.tags_vocab == ["category:::yes"]

    # Assertion if sources is missing
    @test_throws AssertionError build_index([text, text]; reader = :docs)

    # clean up
    close(echo_server)
end
