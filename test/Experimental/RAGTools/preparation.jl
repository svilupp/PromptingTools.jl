using PromptingTools.Experimental.RAGTools: load_text, FileChunker, TextChunker,
                                            BatchEmbedder, BinaryBatchEmbedder,
                                            EmbedderEltype,
                                            NoTagger, PassthroughTagger, OpenTagger
using PromptingTools.Experimental.RAGTools: AbstractTagger, AbstractChunker,
                                            AbstractEmbedder, AbstractIndexBuilder
using PromptingTools.Experimental.RAGTools: tags_extract, Tag, MaybeTags
using PromptingTools.Experimental.RAGTools: build_tags, build_index, SimpleIndexer,
                                            get_tags, get_chunks, get_embeddings
using PromptingTools.Experimental.RAGTools: build_tags, build_index
using PromptingTools: TestEchoOpenAISchema

@testset "load_text" begin
    # from file
    fp, io = mktemp()
    write(io, "text")
    close(io)
    @test load_text(FileChunker(), fp) == ("text", fp)
    @test_throws AssertionError load_text(FileChunker(), "nonexistent" * fp)

    # from provided text
    @test load_text(TextChunker(), "text"; source = "POMA") == ("text", "POMA")
    @test_throws AssertionError load_text(TextChunker(), "text"; source = "a"^520) # catch long doc - cant be a source

    # unknown chunker
    struct RandomChunker123 <: AbstractChunker end
    @test_throws ArgumentError load_text(RandomChunker123(), "text")
end

@testset "get_chunks" begin
    ochunks, osources = get_chunks(
        TextChunker(), ["text1", "text2"]; max_length = 10, sources = ["doc1", "doc2"])
    @test ochunks == ["text1", "text2"]
    @test osources == ["doc1", "doc2"]

    # Mismatch in source length
    @test_throws AssertionError get_chunks(
        TextChunker(), ["text1", "text2"]; max_length = 10, sources = ["doc1"])
    # too long to be a source
    @test_throws AssertionError get_chunks(
        TextChunker(), ["text1", "text2"]; max_length = 10, sources = ["a"^520, "b"^520])

    # FileChunker
    fp, io = mktemp()
    write(io, "text")
    close(io)
    fp2, io = mktemp()
    write(io, "text2")
    close(io)
    ochunks, osources = get_chunks(
        FileChunker(), [fp, fp2]; max_length = 10)
    @test ochunks == ["text", "text2"]
    @test osources == [fp, fp2]
end

@testset "get_embeddings" begin
    # corresponds to OpenAI API v1
    response1 = Dict(:data => [Dict(:embedding => ones(128, 2))],
        :usage => Dict(:total_tokens => 2, :prompt_tokens => 2, :completion_tokens => 0))
    schema = TestEchoOpenAISchema(; response = response1, status = 200)
    PT.register_model!(; name = "mock-emb", schema)

    docs = ["Hello World", "Hello World"]
    output = get_embeddings(
        BatchEmbedder(), docs; model = "mock-emb", truncate_dimension = 100)
    @test size(output) == (100, 2)
    ## value of 0 for truncation, skips the step
    output = get_embeddings(
        BatchEmbedder(), docs; model = "mock-emb", truncate_dimension = 0)
    @test size(output) == (128, 2)

    # Unknown type
    struct RandomEmbedder123 <: AbstractEmbedder end
    @test_throws ArgumentError get_embeddings(
        RandomEmbedder123(), ["text1", "text2"])

    # BinaryBatchEmbedder
    output = get_embeddings(
        BinaryBatchEmbedder(), docs; model = "mock-emb", truncate_dimension = 100)
    @test size(output) == (100, 2)
    @test eltype(output) == Bool

    # EmbedderEltype
    @test EmbedderEltype(BinaryBatchEmbedder()) == Bool
    @test EmbedderEltype(BatchEmbedder()) == Float32
end

@testset "tags_extract" begin
    # Tag Structure
    item = Tag("value", "category")
    @test item.value == "value"
    @test item.category == "category"

    # MaybeTags Structure
    items = MaybeTags([
        Tag("value1", "category1"),
        Tag("value2", "category2")
    ])
    @test length(items.items) == 2
    @test items.items[1].value == "value1"
    @test items.items[1].category == "category1"

    empty_items = MaybeTags(nothing)
    @test isempty(tags_extract(empty_items.items))

    # Metadata Extraction Function
    single_item = Tag("DataFrames", "Julia Package")
    multiple_items = [
        Tag("pandas", "Software"),
        Tag("Python", "Language"),
        Tag("DataFrames", "Julia Package")
    ]

    @test tags_extract(single_item) == "julia_package:::dataframes"
    @test tags_extract(multiple_items) ==
          ["software:::pandas", "language:::python", "julia_package:::dataframes"]

    @test tags_extract(nothing) == String[]
end

@testset "get_tags" begin
    # Unknown Tagger
    struct RandomTagger123 <: AbstractTagger end
    @test_throws ArgumentError get_tags(RandomTagger123(), String[])

    # NoTagger
    @test get_tags(NoTagger(), String[]) == nothing

    # PassthroughTagger
    tags_ = [["tag1"], ["tag2"]]
    @test get_tags(PassthroughTagger(), ["doc1", "docs2"]; tags = tags_) == tags_
    @test_throws AssertionError get_tags(
        PassthroughTagger(), ["doc1", "docs2"]; tags = [["tag1"]]) # length mismatch

    # OpenTagger - mock server
    response = Dict(
        :choices => [
            Dict(:finish_reason => "stop",
            :message => Dict(:tool_calls => [
                Dict(:function => Dict(:arguments => JSON3.write(MaybeTags([
                Tag("yes", "categoryx")
            ]))))]))],
        :usage => Dict(:total_tokens => 3, :prompt_tokens => 2, :completion_tokens => 1))
    schema = TestEchoOpenAISchema(; response = response, status = 200)
    PT.register_model!(; name = "mock-meta", schema)
    tags_ = get_tags(OpenTagger(), String["Say yes"]; model = "mock-meta")
    @test tags_ == [["categoryx:::yes"]]
end

@testset "build_tags" begin
    ## empty tags
    @test build_tags(NoTagger(), nothing) == (nothing, nothing)

    tagger = OpenTagger()
    # Single Tag
    chunk_metadata = [["tag1"]]
    tags_, tags_vocab_ = build_tags(tagger, chunk_metadata)

    @test length(tags_vocab_) == 1
    @test tags_vocab_ == ["tag1"]
    @test nnz(tags_) == 1
    @test tags_[1, 1] == true

    # Multiple Tags with Repetition
    chunk_metadata = [["tag1", "tag2"], ["tag2", "tag3"]]
    tags_, tags_vocab_ = build_tags(tagger, chunk_metadata)

    @test length(tags_vocab_) == 3
    @test tags_vocab_ == ["tag1", "tag2", "tag3"]
    @test nnz(tags_) == 4
    @test all([tags_[1, 1], tags_[1, 2], tags_[2, 2], tags_[2, 3]])

    # Empty Metadata
    chunk_metadata = [String[]]
    tags_, tags_vocab_ = build_tags(tagger, chunk_metadata)

    @test isempty(tags_vocab_)
    @test size(tags_) == (1, 0)

    # Mixed Empty and Non-Empty Metadata
    chunk_metadata = [["tag1"], String[], ["tag2", "tag3"]]
    tags_, tags_vocab_ = build_tags(tagger, chunk_metadata)

    @test length(tags_vocab_) == 3
    @test tags_vocab_ == ["tag1", "tag2", "tag3"]
    @test nnz(tags_) == 3
    @test all([tags_[1, 1], tags_[3, 2], tags_[3, 3]])
end

@testset "build_index" begin
    # test with a mock server
    PORT = rand(9000:31000)
    PT.register_model!(; name = "mock-emb", schema = PT.CustomOpenAISchema())
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
            response = Dict(
                :data => [Dict(:embedding => ones(Float32, 128))
                          for i in 1:length(content[:input])],
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

    text = "This is a long text that will be split into chunks.\n\n It will be split by the separator. And also by the separator '\n'."

    ## Default - file reader
    tmp, _ = mktemp()
    write(tmp, text)
    mini_files = [tmp, tmp]
    indexer = SimpleIndexer()
    index = build_index(
        indexer, mini_files; chunker = FileChunker(), chunker_kwargs = (; max_length = 10),
        embedder_kwargs = (; model = "mock-emb"),
        tagger_kwargs = (; model = "mock-meta"), api_kwargs = (;
            url = "http://localhost:$(PORT)"))
    @test index.embeddings ==
          hcat(fill(normalize(ones(Float32, 128)), length(index.chunks))...)
    @test index.chunks[begin:(length(index.chunks) ÷ 2)] ==
          index.chunks[((length(index.chunks) ÷ 2) + 1):end]
    @test index.sources == fill(tmp, length(index.chunks))
    @test index.tags == nothing
    @test index.tags_vocab == nothing

    ## With metadata
    indexer = SimpleIndexer(; chunker = FileChunker(), tagger = OpenTagger())
    index = build_index(indexer, mini_files; chunker_kwargs = (; max_length = 10),
        embedder_kwargs = (; model = "mock-emb"),
        tagger_kwargs = (; model = "mock-meta"), api_kwargs = (;
            url = "http://localhost:$(PORT)"))
    @test index.tags == ones(30, 1)
    @test index.tags_vocab == ["category:::yes"]

    ## Test docs reader - customize via kwarg
    indexer = SimpleIndexer()
    index = build_index(indexer, [text, text]; chunker = TextChunker(),
        chunker_kwargs = (;
            sources = ["x", "x"], max_length = 10),
        embedder_kwargs = (; model = "mock-emb"),
        tagger_kwargs = (; model = "mock-meta"), api_kwargs = (;
            url = "http://localhost:$(PORT)"))
    @test index.embeddings ==
          hcat(fill(normalize(ones(Float32, 128)), length(index.chunks))...)
    @test index.chunks[begin:(length(index.chunks) ÷ 2)] ==
          index.chunks[((length(index.chunks) ÷ 2) + 1):end]
    @test index.sources == fill("x", length(index.chunks))
    @test index.tags == nothing
    @test index.tags_vocab == nothing

    # Test default behavior - text chunker
    index = build_index([text, text];
        chunker_kwargs = (;
            sources = ["x", "x"], max_length = 10),
        embedder_kwargs = (; model = "mock-emb"),
        tagger_kwargs = (; model = "mock-meta"), api_kwargs = (;
            url = "http://localhost:$(PORT)"))
    @test index.embeddings ==
          hcat(fill(normalize(ones(Float32, 128)), length(index.chunks))...)
    @test index.chunks[begin:(length(index.chunks) ÷ 2)] ==
          index.chunks[((length(index.chunks) ÷ 2) + 1):end]
    @test index.sources == fill("x", length(index.chunks))
    @test index.tags == nothing
    @test index.tags_vocab == nothing
    # clean up
    close(echo_server)
end
