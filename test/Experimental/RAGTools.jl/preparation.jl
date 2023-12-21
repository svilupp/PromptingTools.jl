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