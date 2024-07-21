using PromptingTools.Experimental.RAGTools: ChunkEmbeddingsIndex, ChunkKeywordsIndex,
                                            MultiIndex,
                                            CandidateChunks,
                                            MultiCandidateChunks,
                                            AbstractCandidateChunks, DocumentTermMatrix,
                                            document_term_matrix, HasEmbeddings,
                                            HasKeywords,
                                            ChunkKeywordsIndex, AbstractChunkIndex,
                                            AbstractDocumentIndex
using PromptingTools.Experimental.RAGTools: embeddings, chunks, tags, tags_vocab, sources,
                                            extras, positions, scores, parent,
                                            RAGResult, chunkdata, preprocess_tokens
using PromptingTools.Experimental.RAGTools: SubChunkIndex, indexid, indexids
using PromptingTools: last_message, last_output

@testset "ChunkEmbeddingsIndex" begin
    # Test constructors and basic accessors
    chunks_test = ["chunk1", "chunk2"]
    emb_test = ones(2, 2)
    tags_test = sparse([1, 2], [1, 2], [true, true], 2, 2)
    tags_vocab_test = ["vocab1", "vocab2"]
    sources_test = ["source1", "source2"]
    ci = ChunkEmbeddingsIndex(chunks = chunks_test,
        embeddings = emb_test,
        tags = tags_test,
        tags_vocab = tags_vocab_test,
        sources = sources_test)

    @test chunks(ci) == chunks_test
    @test (embeddings(ci)) == emb_test
    @test (chunkdata(ci)) == emb_test
    @test tags(ci) == tags_test
    @test tags_vocab(ci) == tags_vocab_test
    @test sources(ci) == sources_test
    @test length(ci) == 2

    # Test identity/equality
    ci1 = ChunkEmbeddingsIndex(
        chunks = ["chunk1", "chunk2"], sources = ["source1", "source2"])
    ci2 = ChunkEmbeddingsIndex(
        chunks = ["chunk1", "chunk2"], sources = ["source1", "source2"])
    @test ci1 == ci2

    # Test equality with different chunks and sources
    ci2 = ChunkEmbeddingsIndex(
        chunks = ["chunk3", "chunk4"], sources = ["source3", "source4"])
    @test ci1 != ci2

    # Test hcat with ChunkEmbeddingsIndex
    # Setup two different ChunkEmbeddingsIndex with different tags and then hcat them
    chunks1 = ["chunk1", "chunk2"]
    tags1 = sparse([1, 2], [1, 2], [true, true], 2, 3)
    tags_vocab1 = ["vocab1", "vocab2", "vocab3"]
    sources1 = ["source1", "source1"]
    ci1 = ChunkEmbeddingsIndex(chunks = chunks1,
        tags = tags1,
        tags_vocab = tags_vocab1,
        sources = sources1)

    chunks2 = ["chunk3", "chunk4"]
    tags2 = sparse([1, 2], [1, 3], [true, true], 2, 3)
    tags_vocab2 = ["vocab1", "vocab3", "vocab4"]
    sources2 = ["source2", "source2"]
    ci2 = ChunkEmbeddingsIndex(chunks = chunks2,
        tags = tags2,
        tags_vocab = tags_vocab2,
        sources = sources2)

    combined_ci = vcat(ci1, ci2)
    @test size(tags(combined_ci), 1) == 4
    @test size(tags(combined_ci), 2) == 4
    @test length(unique(vcat(tags_vocab(ci1), tags_vocab(ci2)))) ==
          length(tags_vocab(combined_ci))
    @test sources(combined_ci) == vcat(sources(ci1), (sources(ci2)))
    @test length(combined_ci) == 4

    # Test base var"==" with ChunkEmbeddingsIndex
    ci1 = ChunkEmbeddingsIndex(chunks = ["chunk1"],
        id = :ci1,
        tags = trues(3, 1),
        tags_vocab = ["vocab1"],
        sources = ["source1"])
    ci2 = ChunkEmbeddingsIndex(chunks = ["chunk1"],
        tags = trues(3, 1),
        tags_vocab = ["vocab1"],
        sources = ["source1"])
    @test ci1 == ci2

    # HasEmbeddings
    @test HasEmbeddings(ci1) == true
    @test HasKeywords(ci1) == false

    # Getindex
    @test ci1[:ci1] == ci1
    @test ci1[:ci2] == nothing

    ## Test general accessors
    @kwdef struct TestBadMultiIndex <: AbstractDocumentIndex
        indices::Vector{AbstractChunkIndex} = [ChunkEmbeddingsIndex(
            chunks = ["chunk1"], sources = ["source1"])]
    end
    bad_idx = TestBadMultiIndex()
    @test_throws ArgumentError chunkdata(bad_idx)
    @test_throws ArgumentError embeddings(bad_idx)
    @test_throws ArgumentError tags(bad_idx)
    @test_throws ArgumentError tags_vocab(bad_idx)
    @test_throws ArgumentError extras(bad_idx)

    @kwdef struct TestBadChunkIndex <: AbstractChunkIndex
        chunks::Vector{String}
        sources::Vector{String}
    end
    bad_chunk_idx = TestBadChunkIndex(chunks = ["chunk1"], sources = ["source1"])
    @test_throws ArgumentError embeddings(bad_chunk_idx)
end

@testset "ChunkKeywordsIndex" begin
    # Test creation of ChunkKeywordsIndex
    chunks_ = ["chunk1", "chunk2"]
    sources_ = ["source1", "source2"]
    ci = ChunkKeywordsIndex(chunks = chunks_, sources = sources_)
    @test chunks(ci) == chunks_
    @test sources(ci) == sources_
    @test chunkdata(ci) == nothing
    @test tags(ci) == nothing
    @test tags_vocab(ci) == nothing
    @test extras(ci) == nothing

    # Test equality of ChunkKeywordsIndex
    chunks_ = ["this is a test", "this is another test", "foo bar baz"]
    sources_ = ["source1", "source2", "source3"]
    dtm = document_term_matrix(chunks_)
    ci1 = ChunkKeywordsIndex(chunks = chunks_, sources = sources_, chunkdata = dtm)
    ci2 = ChunkKeywordsIndex(chunks = chunks_, sources = sources_, chunkdata = dtm)
    @test ci1 == ci2

    ci3 = ChunkKeywordsIndex(chunks = ["chunk2"], sources = ["source2"])
    @test ci1 != ci3

    # Test hcat with ChunkKeywordsIndex
    chunks1 = ["chunk1", "chunk2"]
    sources1 = ["source1", "source1"]
    ci1 = ChunkKeywordsIndex(
        chunks = chunks1, sources = sources1, chunkdata = document_term_matrix(chunks1))

    chunks2 = ["chunk3", "chunk4"]
    sources2 = ["source2", "source2"]
    ci2 = ChunkKeywordsIndex(
        chunks = chunks2, sources = sources2, chunkdata = document_term_matrix(chunks2))

    combined_ci = vcat(ci1, ci2)
    @test length(combined_ci.chunks) == 4
    @test length(combined_ci.sources) == 4
    @test combined_ci.chunks == ["chunk1", "chunk2", "chunk3", "chunk4"]
    @test combined_ci.sources == ["source1", "source1", "source2", "source2"]

    # HasEmbeddings
    @test HasEmbeddings(ci1) == false
    @test HasKeywords(ci1) == true
    @test_throws ArgumentError embeddings(ci1)
end

@testset "DocumentTermMatrix" begin
    # Simple case
    documents = [["this", "is", "a", "test"],
        ["this", "is", "another", "test"], ["foo", "bar", "baz"]]
    dtm = document_term_matrix(documents)
    @test size(dtm.tf) == (3, 8)
    @test Set(dtm.vocab) == Set(["a", "another", "bar", "baz", "foo", "is", "test", "this"])
    avgdl = 3.666666666666667
    @test all(dtm.doc_rel_length .≈ [4 / avgdl, 4 / avgdl, 3 / avgdl])
    @test length(dtm.idf) == 8

    # Edge case: single document
    documents = [["this", "is", "a", "test"]]
    dtm = document_term_matrix(documents)
    @test size(dtm.tf) == (1, 4)
    @test Set(dtm.vocab) == Set(["a", "is", "test", "this"])
    @test dtm.doc_rel_length == ones(1)
    @test length(dtm.idf) == 4

    # Edge case: duplicate tokens
    documents = [["this", "is", "this", "test"],
        ["this", "is", "another", "test"], ["this", "bar", "baz"]]
    dtm = document_term_matrix(documents)
    @test size(dtm.tf) == (3, 6)
    @test Set(dtm.vocab) == Set(["another", "bar", "baz", "is", "test", "this"])
    avgdl = 3.666666666666667
    @test all(dtm.doc_rel_length .≈ [4 / avgdl, 4 / avgdl, 3 / avgdl])
    @test length(dtm.idf) == 6

    # Edge case: no tokens
    documents = [String[], String[], String[]]
    dtm = document_term_matrix(documents)
    @test size(dtm.tf) == (3, 0)
    @test isempty(dtm.vocab)
    @test isempty(dtm.vocab_lookup)
    @test isempty(dtm.idf)
    @test dtm.doc_rel_length == zeros(3)

    ## Methods - hcat
    documents = [["this", "is", "a", "test"],
        ["this", "is", "another", "test"], ["foo", "bar", "baz"]]
    dtm1 = document_term_matrix(documents)
    documents = [["this", "is", "a", "test"],
        ["this", "is", "another", "test"], ["foo", "bar", "baz"]]
    dtm2 = document_term_matrix(documents)
    dtm = hcat(dtm1, dtm2)
    @test size(dtm.tf) == (6, 8)
    @test length(dtm.vocab) == 8
    @test length(dtm.idf) == 8
    @test isapprox(dtm.doc_rel_length,
        [4 / 3.666666666666667, 4 / 3.666666666666667, 3 / 3.666666666666667,
            4 / 3.666666666666667, 4 / 3.666666666666667, 3 / 3.666666666666667])

    # Check stubs that they throw
    @test_throws ArgumentError RT._stem(nothing, "abc")
    @test_throws ArgumentError RT._unicode_normalize(nothing)
end

@testset "MultiIndex" begin
    # Test constructors/accessors
    # MultiIndex behaves as a container for ChunkEmbeddingsIndexes
    cin1 = ChunkEmbeddingsIndex(chunks = ["chunk1"], sources = ["source1"])
    cin2 = ChunkEmbeddingsIndex(chunks = ["chunk2"], sources = ["source2"])
    multi_index = MultiIndex(indexes = [cin1, cin2])
    @test length(multi_index.indexes) == 2
    @test cin1 in multi_index.indexes
    @test cin2 in multi_index.indexes

    # Test base var"==" with MultiIndex
    # Case where MultiIndexes are equal
    cin1 = ChunkEmbeddingsIndex(chunks = ["chunk1"], sources = ["source1"])
    cin2 = ChunkEmbeddingsIndex(chunks = ["chunk2"], sources = ["source2"])
    mi1 = MultiIndex(indexes = [cin1, cin2])
    mi2 = MultiIndex(indexes = [cin1, cin2])
    @test mi1 == mi2

    # Test equality with different ChunkEmbeddingsIndexes inside
    cin1 = ChunkEmbeddingsIndex(chunks = ["chunk1"], sources = ["source1"])
    cin2 = ChunkEmbeddingsIndex(chunks = ["chunk2"], sources = ["source2"])
    mi1 = MultiIndex([cin1])
    mi2 = MultiIndex(cin2)
    @test mi1 != mi2

    # HasEmbeddings
    @test HasEmbeddings(mi1) == true
    @test HasKeywords(mi1) == false

    ci = ChunkKeywordsIndex(chunks = ["chunk1"], sources = ["source1"])
    mi2 = MultiIndex(indexes = [ci])
    @test HasEmbeddings(mi2) == false

    cin1 = ChunkEmbeddingsIndex(chunks = ["chunk1"], sources = ["source1"], id = :cin1)
    cin2 = ChunkKeywordsIndex(chunks = ["chunk1"], sources = ["source1"], id = :cin2)
    mi3 = MultiIndex(indexes = [cin1, cin2], id = :mi3)
    @test HasEmbeddings(mi3) == true
    @test HasKeywords(mi3) == true

    ## not implemented
    @test_throws ArgumentError vcat(mi1, mi2)

    # Get index
    @test mi3[:cin1] == cin1
    @test mi3[:cin2] == cin2
    @test mi3[:xyz] == nothing
    @test mi3[:mi3] == mi3
end

@testset "CandidateChunks" begin
    chunk_sym = Symbol("TestChunkEmbeddingsIndex")
    cc1 = CandidateChunks(index_id = chunk_sym,
        positions = [1, 3],
        scores = [0.1, 0.2])
    @test Base.length(cc1) == 2
    out = Base.first(cc1, 1)
    @test out.positions == [3]
    @test out.scores == [0.2]
    @test indexid(cc1) == chunk_sym
    @test indexids(cc1) == [chunk_sym, chunk_sym]

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

    # Serialization
    tmp, _ = mktemp()
    JSON3.write(tmp, cc1)
    cc1x = JSON3.read(tmp, CandidateChunks)
    @test cc1x.index_id == cc1.index_id
    @test cc1x.positions == cc1.positions
    @test cc1x.scores ≈ cc1.scores
end

@testset "MultiCandidateChunks" begin
    chunk_sym1 = Symbol("TestChunkEmbeddingsIndex1")
    chunk_sym2 = Symbol("TestChunkEmbeddingsIndex2")
    mcc1 = MultiCandidateChunks(index_ids = [chunk_sym1, chunk_sym2],
        positions = [1, 3],
        scores = [0.1, 0.2])
    @test Base.length(mcc1) == 2
    out = Base.first(mcc1, 1)
    @test out.positions == [3]
    @test out.scores == [0.2]
    @test indexids(mcc1) == [chunk_sym1, chunk_sym2]

    # Test vcat
    mcc2 = MultiCandidateChunks(index_ids = [chunk_sym1, chunk_sym2],
        positions = [2, 4],
        scores = [0.3, 0.4])
    vcat1 = vcat(mcc1, mcc2)
    @test Base.length(vcat1) == 4
    vcat2 = vcat(mcc1,
        MultiCandidateChunks(index_ids = [chunk_sym1, chunk_sym2],
            positions = [1, 4],
            scores = [0.3, 0.5]))
    @test vcat2.positions == [4, 1, 3]
    @test vcat2.scores == [0.5, 0.3, 0.2]

    # Test copy
    mcc1_copy = copy(mcc1)
    @test mcc1 == mcc1_copy
    @test mcc1.positions !== mcc1_copy.positions # not the same array

    chunk_sym1 = Symbol("TestChunkEmbeddingsIndex1")
    chunk_sym2 = Symbol("TestChunkEmbeddingsIndex2")
    # Test intersection with overlapping positions
    mcc3 = MultiCandidateChunks(index_ids = [chunk_sym1, chunk_sym2],
        positions = [1, 4],
        scores = [0.3, 0.5])
    joint = (mcc1 & mcc3)
    @test joint.positions == [1]
    @test joint.scores == [0.3]
    joint2 = (mcc2 & mcc3)
    @test joint2.positions == [4]
    @test joint2.scores == [0.5]

    # Test intersection with no overlapping positions
    mcc4 = MultiCandidateChunks(index_ids = [chunk_sym1, chunk_sym2],
        positions = [6, 7],
        scores = [0.6, 0.7])
    joint3 = (mcc1 & mcc4)
    @test isempty(joint3.positions)
    @test isempty(joint3.scores)
    @test isempty(joint3) == true

    # Test intersection with long positions
    mcc5 = MultiCandidateChunks(index_ids = fill(chunk_sym2, 7),
        positions = [5, 6, 7, 8, 9, 10, 4],
        scores = 0.1 * ones(7))
    joint4 = (mcc2 & mcc5)
    @test joint4.positions == [4]
    @test joint4.scores == [0.4]

    # Test intersection with wrong index
    mcc6 = MultiCandidateChunks(index_ids = [:xyz, :abc],
        positions = [2, 4],
        scores = [0.3, 0.4])
    joint5 = (mcc2 & mcc6)
    @test isempty(joint5.positions)
    @test isempty(joint5.scores)
    @test isempty(joint5) == true

    # Test intersection with unknown type
    struct RandomMultiCandidateChunks123 <: AbstractCandidateChunks end
    @test_throws ArgumentError (mcc1&RandomMultiCandidateChunks123())
end

@testset "SubChunkIndex" begin
    ci1 = ChunkEmbeddingsIndex(chunks = ["chunk1", "chunk2", "chunk3"],
        embeddings = nothing,
        tags = nothing,
        tags_vocab = nothing,
        sources = ["source1", "source2", "source3"],
        id = Symbol("TestChunkIndex"))

    # Test creating a SubChunkIndex with CandidateChunks
    cc = CandidateChunks(ci1, 1:2)
    sub_index = view(ci1, cc)
    @test chunks(sub_index) == ["chunk1", "chunk2"]

    # Test creating a SubChunkIndex with different CandidateChunks
    cc = CandidateChunks(ci1, [2, 3])
    sub_index = view(ci1, cc)
    @test chunks(sub_index) == ["chunk2", "chunk3"]
    @test sources(sub_index) == ["source2", "source3"]

    # Test accessing chunks from SubChunkIndex
    cc = CandidateChunks(ci1, [2])
    sub_index = view(ci1, cc)
    @test sub_index[cc, :chunks] == ["chunk2"]
    @test sub_index[cc, :sources] == ["source2"]
    @test sub_index[cc, :embeddings] == nothing
    @test sub_index[cc, :chunkdata] == nothing
    @test parent(sub_index)[cc, :chunks] == ["chunk2"]

    # Test creating a SubChunkIndex with out-of-bounds CandidateChunks
    cc = CandidateChunks(ci1, [4])
    @test_throws BoundsError view(ci1, cc)
    cc = CandidateChunks(ci1, 1:4)
    @test_throws BoundsError view(ci1, cc)

    chunks_test = ["chunk1", "chunk2", "chunk3"]
    emb_test = ones(2, 3) ./ (1:3)'
    tags_test = sparse([1, 2, 3], [1, 2, 3], [true, true, true], 3, 3)
    tags_vocab_test = ["vocab1", "vocab2", "vocab3"]
    sources_test = ["source1", "source2", "source3"]
    ci2 = ChunkEmbeddingsIndex(id = :TestChunkIndex2, chunks = chunks_test,
        embeddings = emb_test,
        tags = tags_test,
        tags_vocab = tags_vocab_test,
        sources = sources_test)

    # Create a SubChunkIndex for testing
    cc11 = CandidateChunks(ci2, [1, 2])
    sub_index11 = @view ci2[cc11]

    @test indexid(sub_index11) == indexid(ci2)
    @test positions(sub_index11) == [1, 2]
    @test parent(sub_index11) == ci2
    @test HasEmbeddings(sub_index11) == true
    @test HasKeywords(sub_index11) == false
    @test chunks(sub_index11) == ["chunk1", "chunk2"]
    @test sources(sub_index11) == ["source1", "source2"]
    @test chunkdata(sub_index11) ≈ [1.0 0.5; 1.0 0.5]
    @test embeddings(sub_index11) ≈ [1.0 0.5; 1.0 0.5]
    @test tags(sub_index11) == Bool[1 0 0; 0 1 0]
    @test tags_vocab(sub_index11) == tags_vocab_test
    @test extras(sub_index11) == nothing
    @test length(sub_index11) == 2
    @test unique(sub_index11) == sub_index11

    cc2 = CandidateChunks(ci2, [1, 2, 1, 2])
    sub_index2 = @view ci2[cc2]
    @test length(sub_index2) == 4
    @test chunks(sub_index2) == ["chunk1", "chunk2", "chunk1", "chunk2"]
    @test sources(sub_index2) == ["source1", "source2", "source1", "source2"]
    @test unique(sub_index2) == sub_index11
    @test positions(vcat(sub_index11, sub_index2)) == [1, 2, 1, 2, 1, 2]

    # Test vcat not implemented for different types
    ci3 = ChunkEmbeddingsIndex(chunks = ["chunk4", "chunk5"],
        embeddings = nothing,
        tags = nothing,
        tags_vocab = nothing,
        sources = ["source4", "source5"],
        id = Symbol("TestChunkIndex3"))
    cc3 = CandidateChunks(ci3, [1, 2])
    sub_index3 = view(ci3, cc3)
    @test_throws ArgumentError vcat(sub_index, sub_index3)

    # Test vcat for same parent
    cc = CandidateChunks(ci1, [1, 2])
    sub_index = view(ci1, cc)
    cc4 = CandidateChunks(ci1, [3])
    sub_index4 = view(ci1, cc4)
    vcat_index = vcat(sub_index, sub_index4)
    @test vcat_index == SubChunkIndex(ci1, [1, 2, 3])

    # Test edge cases
    # Empty positions
    cc_empty = CandidateChunks(ci1, Int[])
    sub_index_empty = view(ci1, cc_empty)
    @test length(sub_index_empty) == 0
    @test chunks(sub_index_empty) == String[]
    @test sources(sub_index_empty) == String[]
    @test isempty(sub_index_empty) == true

    # Out of bounds positions
    cc_oob = CandidateChunks(ci1, [10])
    @test_throws BoundsError view(ci1, cc_oob)

    # Duplicate positions
    cc_dup = CandidateChunks(ci1, [1, 1, 2])
    sub_index_dup = view(ci1, cc_dup)
    @test length(sub_index_dup) == 3
    @test chunks(sub_index_dup) == ["chunk1", "chunk1", "chunk2"]
    @test unique(sub_index_dup) == SubChunkIndex(ci1, [1, 2])

    # Test show method
    io = IOBuffer()
    show(io, sub_index)
    @test String(take!(io)) ==
          "A view of ChunkEmbeddingsIndex (id: TestChunkIndex) with 2 chunks"

    ## Nested SubChunkIndex
    # Test SubChunkIndex created from SubChunkIndex
    cc_sub = CandidateChunks(sub_index, [1])
    sub_sub_index = view(sub_index, cc_sub)
    @test length(sub_sub_index) == 1
    @test chunks(sub_sub_index) == ["chunk1"]
    @test sources(sub_sub_index) == ["source1"]
    @test parent(sub_sub_index) == ci1
    @test parent(@view sub_sub_index[cc_sub]) == ci1

    # Test edge cases for SubChunkIndex created from SubChunkIndex
    # Empty positions
    cc_empty_sub = CandidateChunks(sub_index, Int[])
    sub_index_empty_sub = view(sub_index, cc_empty_sub)
    @test length(sub_index_empty_sub) == 0
    @test chunks(sub_index_empty_sub) == String[]
    @test sources(sub_index_empty_sub) == String[]
    @test isempty(sub_index_empty_sub) == true

    # Out of bounds positions
    cc_oob_sub = CandidateChunks(sub_index, [10])
    @test_throws BoundsError view(sub_index, cc_oob_sub)

    # Duplicate positions
    cc_dup_sub = CandidateChunks(sub_index, [1, 1, 2])
    sub_index_dup_sub = view(sub_index, cc_dup_sub)
    @test length(sub_index_dup_sub) == 3
    @test chunks(sub_index_dup_sub) == ["chunk1", "chunk1", "chunk2"]
    @test unique(sub_index_dup_sub) == SubChunkIndex(ci1, [1, 2])

    # Test show method for SubChunkIndex created from SubChunkIndex
    io_sub = IOBuffer()
    show(io_sub, sub_sub_index)
    @test String(take!(io_sub)) ==
          "A view of ChunkEmbeddingsIndex (id: TestChunkIndex) with 1 chunks"

    ## MultiCandidateChunks
    # Test SubChunkIndex with MultiCandidateChunks
    mcc = MultiCandidateChunks(ci2, [2, 3])
    sub_index_mcc = view(ci2, mcc)
    @test length(sub_index_mcc) == 2
    @test chunks(sub_index_mcc) == ["chunk2", "chunk3"]
    @test sources(sub_index_mcc) == ["source2", "source3"]
    @test chunkdata(sub_index_mcc) ≈ [0.5 0.3333333333333333; 0.5 0.3333333333333333]
    @test embeddings(sub_index_mcc) ≈ [0.5 0.3333333333333333; 0.5 0.3333333333333333]
    @test tags(sub_index_mcc) == Bool[0 1 0; 0 0 1]
    @test tags_vocab(sub_index_mcc) == tags_vocab_test
    @test extras(sub_index_mcc) == nothing

    ## Nested sub-chunk index
    sub_sub_index = @view sub_index_mcc[mcc]
    @test length(sub_sub_index) == 2
    @test chunks(sub_sub_index) == ["chunk2", "chunk3"]
    @test sources(sub_sub_index) == ["source2", "source3"]

    ## With keyword index
    chunks_ = ["chunk1", "chunk2"]
    sources_ = ["source1", "source2"]
    cki = ChunkKeywordsIndex(chunks = chunks_, sources = sources_)
    cck = CandidateChunks(cki, [2])
    sub_cki = @view cki[cck]
    @test length(cki) == 2
    @test length(cck) == 1
    @test length(sub_cki) == 1
    @test chunks(sub_cki) == ["chunk2"]
    @test sources(sub_cki) == ["source2"]
    @test parent(sub_cki) == cki
    @test chunkdata(sub_cki) == nothing
    @test HasEmbeddings(sub_cki) == false
    @test HasKeywords(sub_cki) == true
    @test_throws ArgumentError embeddings(sub_cki)
    @test tags(sub_cki) == nothing
    @test tags_vocab(sub_cki) == nothing
    @test extras(sub_cki) == nothing

    ## MultiIndex not implemented yet
    mi = MultiIndex(indexes = [ci1, cki])
    mccx = MultiCandidateChunks(index_ids = [:TestChunkIndex1, :TestChunkIndex2],
        positions = [1, 2], scores = [0.1, 0.2])
    @test_throws ArgumentError @view mi[mccx]
end

@testset "getindex-CandidateChunks" begin
    # Initialize a ChunkEmbeddingsIndex with test data
    chunks_data = ["First chunk", "Second chunk", "Third chunk"]
    embeddings_data = rand(3, 3)  # Random matrix with 3 embeddings
    tags_data = sparse(Bool[1 1; 0 1; 1 0])  # Some arbitrary sparse matrix representation
    tags_vocab_data = ["tag1", "tag2"]
    chunk_sym = Symbol("TestChunkEmbeddingsIndex")
    test_chunk_index = ChunkEmbeddingsIndex(chunks = chunks_data,
        embeddings = embeddings_data,
        tags = tags_data,
        tags_vocab = tags_vocab_data,
        sources = ["test_source$i" for i in 1:3],
        id = chunk_sym)

    # Test to get chunks based on valid CandidateChunks
    candidate_chunks = CandidateChunks(index_id = chunk_sym,
        positions = [1, 3],
        scores = [0.1, 0.2])
    @test collect(test_chunk_index[candidate_chunks]) == ["First chunk", "Third chunk"]
    @test collect(test_chunk_index[candidate_chunks, :chunks, sorted = true]) ==
          ["Third chunk", "First chunk"]
    @test collect(test_chunk_index[candidate_chunks, :scores]) == [0.1, 0.2]
    @test collect(test_chunk_index[candidate_chunks, :sources]) ==
          ["test_source1", "test_source3"]
    @test collect(test_chunk_index[candidate_chunks, :embeddings]) ==
          embeddings_data[:, [1, 3]]
    @test collect(test_chunk_index[candidate_chunks, :chunkdata]) ==
          embeddings_data[:, [1, 3]]

    # Test with empty positions, which should result in an empty array
    candidate_chunks_empty = CandidateChunks(index_id = chunk_sym,
        positions = Int[],
        scores = Float32[])
    @test isempty(test_chunk_index[candidate_chunks_empty])
    @test isempty(test_chunk_index[candidate_chunks_empty, :chunks])
    @test isempty(test_chunk_index[candidate_chunks_empty, :embeddings])
    @test isempty(test_chunk_index[candidate_chunks_empty, :chunkdata])
    @test isempty(test_chunk_index[candidate_chunks_empty, :sources])

    # Test with positions out of bounds, should handle gracefully without errors
    candidate_chunks_oob = CandidateChunks(index_id = chunk_sym,
        positions = [10, -1],
        scores = [0.5, 0.6])
    @test_throws BoundsError test_chunk_index[candidate_chunks_oob]

    # Test with an incorrect index_id, which should also result in an empty array
    wrong_sym = Symbol("InvalidIndex")
    candidate_chunks_wrong_id = CandidateChunks(index_id = wrong_sym,
        positions = [1, 2],
        scores = [0.3, 0.4])
    @test isempty(test_chunk_index[candidate_chunks_wrong_id])
    @test isempty(test_chunk_index[candidate_chunks_wrong_id, :chunks])
    @test isempty(test_chunk_index[candidate_chunks_wrong_id, :embeddings])
    @test isempty(test_chunk_index[candidate_chunks_wrong_id, :chunkdata])
    @test size(test_chunk_index[candidate_chunks_wrong_id, :chunkdata]) == (0, 0) # check that it's an array to maintain type
    @test isempty(test_chunk_index[candidate_chunks_wrong_id, :sources])
    @test isempty(test_chunk_index[candidate_chunks_wrong_id, :scores])

    # Test when chunks are requested from a MultiIndex, only chunks from the corresponding ChunkEmbeddingsIndex should be returned
    another_chunk_index = ChunkEmbeddingsIndex(chunks = chunks_data,
        embeddings = nothing,
        tags = nothing,
        tags_vocab = nothing,
        sources = repeat(["another_source"], 3),
        id = Symbol("AnotherChunkEmbeddingsIndex"))
    test_multi_index = MultiIndex(indexes = [
        test_chunk_index,
        another_chunk_index
    ])
    @test collect(test_multi_index[candidate_chunks]) == ["First chunk", "Third chunk"]

    # Test when wrong index_id is used with MultiIndex, resulting in an empty array
    @test isempty(test_multi_index[candidate_chunks_wrong_id])

    # Test error case when trying to use a non-chunks field, should assert error as only :chunks field is supported
    @test_throws AssertionError test_chunk_index[candidate_chunks, :nonexistent_field]

    # Multi-Candidate CandidateChunks
    cc = MultiCandidateChunks(; index_ids = [:TestChunkIndex2, :TestChunkIndex1],
        positions = [2, 2], scores = [0.1, 0.4])
    ci1 = ChunkEmbeddingsIndex(id = :TestChunkIndex1,
        chunks = ["chunk1", "chunk2"],
        sources = ["source1", "source2"])
    ci2 = ChunkEmbeddingsIndex(id = :TestChunkIndex2,
        chunks = ["chunk1", "chunk2x"],
        sources = ["source1", "source2"])
    @test ci1[cc, :chunks] == ["chunk2"]
    @test ci1[cc, :scores] == [0.4]
    @test ci2[cc] == ["chunk2x"]
    @test Base.getindex(ci1, cc, :chunks; sorted = true) == ["chunk2"]
    @test Base.getindex(ci1, cc, :scores; sorted = true) == [0.4]
    @test Base.getindex(ci1, cc, :chunks; sorted = false) == ["chunk2"]
    @test Base.getindex(ci1, cc, :scores; sorted = false) == [0.4]

    # Wrong index
    cc_wrong = MultiCandidateChunks(index_ids = [:TestChunkIndex2xxx, :TestChunkIndex1xxx],
        positions = [2, 2], scores = [0.1, 0.4])
    @test isempty(ci1[cc_wrong])
    @test isempty(ci1[cc_wrong, :chunks])
    @test isempty(ci1[cc_wrong, :scores])

    # with MultiIndex
    mi = MultiIndex(; id = :multi, indexes = [ci1, ci2])
    @test mi[cc] == ["chunk2", "chunk2x"]  # default is sorted=false
    @test Base.getindex(mi, cc, :chunks; sorted = true) == ["chunk2", "chunk2x"]
    @test Base.getindex(mi, cc, :chunks; sorted = false) == ["chunk2", "chunk2x"]

    # with MultiIndex -- flip the order of indices
    mi = MultiIndex(; id = :multi, indexes = [ci2, ci1])
    @test mi[cc] == ["chunk2x", "chunk2"] # default is sorted=false
    @test Base.getindex(mi, cc, :chunks; sorted = true) == ["chunk2", "chunk2x"]
    @test Base.getindex(mi, cc, :chunks; sorted = false) == ["chunk2x", "chunk2"]
end

@testset "getindex-MultiCandidateChunks" begin
    chunks_data = ["First chunk", "Second chunk", "Third chunk"]
    test_chunk_index = ChunkEmbeddingsIndex(chunks = chunks_data,
        embeddings = nothing,
        tags = nothing,
        tags_vocab = nothing,
        sources = ["test_source$i" for i in 1:3],
        id = Symbol("TestChunkIndex"))

    # Test with correct index_id and positions, expect correct chunks and scores
    multi_candidate_chunks = MultiCandidateChunks(
        index_ids = [Symbol("TestChunkIndex"), Symbol("TestChunkIndex")],
        positions = [1, 3],
        scores = [0.5, 0.6])
    @test test_chunk_index[multi_candidate_chunks] == ["First chunk", "Third chunk"]
    @test test_chunk_index[multi_candidate_chunks, :scores] == [0.5, 0.6]

    # Test with sorted option, expect chunks and scores sorted by scores in descending order
    @test Base.getindex(test_chunk_index, multi_candidate_chunks, :chunks; sorted = true) ==
          ["Third chunk", "First chunk"]
    @test Base.getindex(test_chunk_index, multi_candidate_chunks, :scores; sorted = true) ==
          [0.6, 0.5]
    @test Base.getindex(
        test_chunk_index, multi_candidate_chunks, :chunks; sorted = false) ==
          ["First chunk", "Third chunk"]
    @test Base.getindex(
        test_chunk_index, multi_candidate_chunks, :scores; sorted = false) ==
          [0.5, 0.6]

    # Test with incorrect index_id, expect empty array
    wrong_multi_candidate_chunks = MultiCandidateChunks(
        index_ids = [Symbol("WrongIndex"), Symbol("WrongIndex")],
        positions = [1, 3],
        scores = [0.5, 0.6])
    @test isempty(test_chunk_index[wrong_multi_candidate_chunks])
    @test isempty(test_chunk_index[wrong_multi_candidate_chunks, :scores])
    @test isempty(test_chunk_index[wrong_multi_candidate_chunks, :chunks])
    @test isempty(test_chunk_index[wrong_multi_candidate_chunks, :sources])

    # Test with a mix of correct and incorrect index_ids, expect only chunks and scores from correct index_id
    mixed_multi_candidate_chunks = MultiCandidateChunks(
        index_ids = [Symbol("TestChunkIndex"), Symbol("WrongIndex")],
        positions = [2, 3],
        scores = [0.5, 0.6])
    @test test_chunk_index[mixed_multi_candidate_chunks] == ["Second chunk"]
    @test test_chunk_index[mixed_multi_candidate_chunks, :scores] == [0.5]
    @test test_chunk_index[mixed_multi_candidate_chunks, :sources] == ["test_source2"]

    ## MultiIndex
    ci2 = ChunkEmbeddingsIndex(chunks = ["4", "5", "6"],
        embeddings = nothing,
        tags = nothing,
        tags_vocab = nothing,
        sources = ["other_source$i" for i in 1:3],
        id = Symbol("TestChunkIndex2"))
    mi = MultiIndex(; id = :multi, indexes = [test_chunk_index, ci2])
    mc1 = MultiCandidateChunks(
        index_ids = [Symbol("TestChunkIndex"), Symbol("TestChunkIndex2")],
        positions = [1, 3],  # Assuming chunks_data has only 3 elements, position 4 is out of bounds
        scores = [0.5, 0.7])
    ## sorted=false by default (Dict-like where order isn't guaranteed)
    ## sorting follows index order
    @test mi[mc1] == ["First chunk", "6"]
    @test Base.getindex(mi, mc1, :chunks; sorted = true) == ["6", "First chunk"]
    @test Base.getindex(mi, mc1, :sources; sorted = true) ==
          ["other_source3", "test_source1"]
    @test Base.getindex(mi, mc1, :chunks; sorted = false) == ["First chunk", "6"]
    @test Base.getindex(mi, mc1, :sources; sorted = false) ==
          ["test_source1", "other_source3"]
    ##
    @test Base.getindex(mi, mc1, :scores; sorted = true) == [0.7, 0.5]
    @test Base.getindex(mi, mc1, :scores; sorted = false) == [0.5, 0.7]
    @test Base.getindex(mi, mc1, :chunks; sorted = false) == ["First chunk", "6"]
    @test Base.getindex(mi, mc1, :sources; sorted = false) ==
          ["test_source1", "other_source3"]
    @test Base.getindex(mi, mc1, :scores; sorted = false) == [0.5, 0.7]
end

@testset "RAGResult" begin
    result = RAGResult(; question = "a", answer = "b", final_answer = "c")
    result2 = RAGResult(; question = "a", answer = "b", final_answer = "c")
    @test result == result2

    result3 = copy(result)
    @test result == result3
    @test result !== result3

    ## pprint checks - empty context fails
    io = IOBuffer()
    @test_throws AssertionError PT.pprint(io, result)

    ## RAG Details dispatch
    answer = "This is a test answer."
    sources_ = ["Source 1", "Source 2", "Source 3"]
    result = RAGResult(;
        question = "?", final_answer = answer, context = sources_, sources = sources_)
    io = IOBuffer()
    PT.pprint(io, result; add_context = true)
    output = String(take!(io))
    @test occursin("This is a test answer.", output)
    @test occursin("\nQUESTION", output)
    @test occursin("\nSOURCES\n", output)
    @test occursin("\nCONTEXT\n", output)
    @test occursin("1. Source 1", output)

    ## last_message, last_output
    result = RAGResult(; question = "a", answer = "b", final_answer = "c")
    @test isnothing(last_message(result))
    @test last_output(result) == "c"

    result = RAGResult(; question = "a", answer = "b", final_answer = "c",
        conversations = Dict(:final_answer => [PT.UserMessage("c")]))
    @test last_message(result) == PT.UserMessage("c")
    @test last_output(result) == "c"

    result = RAGResult(; question = "a", answer = "b", final_answer = "c",
        conversations = Dict(:answer => [PT.UserMessage("a")]))
    @test last_message(result) == PT.UserMessage("a")

    # serialization
    # We cannot recover all type information !!!
    result = RAGResult(; question = "a", answer = "b", final_answer = "c",
        conversations = Dict(:answer => [PT.UserMessage("a")]))
    tmp, _ = mktemp()
    JSON3.write(tmp, result)
    resultx = JSON3.read(tmp, RAGResult)
    @test resultx == result
end
