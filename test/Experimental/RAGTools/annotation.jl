using PromptingTools.Experimental.RAGTools: AnnotatedNode, set_node_style!,
                                            align_node_styles!, TrigramAnnotater
using PromptingTools.Experimental.RAGTools: trigram_support!, add_node_metadata!,
                                            annotate_support

@testset "AnnotatedNode" begin
    # Test node creation with default values
    @test begin
        node = AnnotatedNode()
        @test node.group_id == 0
        @test isnothing(node.parent)
        @test isempty(node.children)
        @test isnothing(node.score)
        @test node.hits == 0
        @test node.content == ""
        @test isempty(node.sources)
        @test typeof(node.style) == Styler && node.style.color == :nothing
    end

    # Test node creation with specific values
    @test begin
        parent_node = AnnotatedNode(content = "parent")
        child_node = AnnotatedNode(parent = parent_node, content = "child")
        @test child_node.parent === parent_node
        @test child_node.content == "child"
    end

    # Test adding a child node updates children array correctly
    @test begin
        parent_node = AnnotatedNode()
        child_node = AnnotatedNode(content = "child")
        push!(parent_node.children, child_node)
        @test length(parent_node.children) == 1
        @test parent_node.children[1] === child_node
    end

    # Test AbstractTrees interface compatibility
    @test begin
        parent_node = AnnotatedNode(content = "parent")
        child_node1 = AnnotatedNode(content = "child1")
        child_node2 = AnnotatedNode(content = "child2")
        push!(parent_node.children, child_node1)
        push!(parent_node.children, child_node2)

        @test AbstractTrees.children(parent_node) == [child_node1, child_node2]
        @test AbstractTrees.parent(child_node1) === parent_node
        @test AbstractTrees.parent(child_node2) === parent_node
    end

    # Test nodevalue and childtype methods for tree traversal
    @test begin
        node = AnnotatedNode(content = "root", group_id = 1)
        child_node = AnnotatedNode(content = "child", group_id = 2)
        push!(node.children, child_node)
        @test AbstractTrees.nodevalue(node) == 1
        @test AbstractTrees.childtype(node) === AnnotatedNode
    end

    # Test pprint function for a single node
    @test begin
        node = AnnotatedNode(content = "test", group_id = 123)
        io = IOBuffer()
        pprint(io, node)
        @test occursin("AnnotatedNode(id: 123, 4)", String(take!(io)))
    end
end

@testset "set_node_style!" begin
    annotater = TrigramAnnotater()

    # Test with a high score exceeding high_threshold
    @test begin
        node = AnnotatedNode(score = 0.9)
        set_node_style!(annotater, node; high_threshold = 0.8, low_threshold = 0.3)
        @test node.style.color == :green && node.style.bold == false
    end

    # Test with a score between high_threshold and low_threshold
    @test begin
        node = AnnotatedNode(score = 0.4)
        set_node_style!(annotater, node; high_threshold = 0.8, low_threshold = 0.3)
        @test node.style.color == :red && node.style.bold == false
    end

    # Test with a score below low_threshold
    @test begin
        node = AnnotatedNode(score = 0.2)
        set_node_style!(annotater, node; high_threshold = 0.8, low_threshold = 0.3)
        @test node.style.color == :nothing && node.style.bold == false
    end

    # Test applying bold style for multiple hits
    @test begin
        node = AnnotatedNode(score = 0.9, hits = 2)
        set_node_style!(annotater, node; high_threshold = 0.8, bold_multihits = true)
        @test node.style.color == :green && node.style.bold == true
    end

    # Test not applying bold style when bold_multihits is false
    @test begin
        node = AnnotatedNode(score = 0.9, hits = 2)
        set_node_style!(annotater, node; high_threshold = 0.8, bold_multihits = false)
        @test node.style.color == :green && node.style.bold == false
    end

    # Test with isnothing(node.score), expecting default style
    @test begin
        node = AnnotatedNode(score = nothing)
        set_node_style!(annotater, node)
        @test node.style.color == :nothing && node.style.bold == false
    end
end

@testset "set_node_style!" begin
    annotater = TrigramAnnotater()

    # Test with a high score exceeding high_threshold
    @test begin
        node = AnnotatedNode(score = 0.9)
        set_node_style!(annotater, node; high_threshold = 0.8, low_threshold = 0.3)
        @test node.style.color == :green && node.style.bold == false
    end

    # Test with a score between high_threshold and low_threshold
    @test begin
        node = AnnotatedNode(score = 0.4)
        set_node_style!(annotater, node; high_threshold = 0.8, low_threshold = 0.3)
        @test node.style.color == :red && node.style.bold == false
    end

    # Test with a score below low_threshold
    @test begin
        node = AnnotatedNode(score = 0.2)
        set_node_style!(annotater, node; high_threshold = 0.8, low_threshold = 0.3)
        @test node.style.color == :nothing && node.style.bold == false
    end

    # Test applying bold style for multiple hits
    @test begin
        node = AnnotatedNode(score = 0.9, hits = 2)
        set_node_style!(annotater, node; high_threshold = 0.8, bold_multihits = true)
        @test node.style.color == :green && node.style.bold == true
    end

    # Test not applying bold style when bold_multihits is false
    @test begin
        node = AnnotatedNode(score = 0.9, hits = 2)
        set_node_style!(annotater, node; high_threshold = 0.8, bold_multihits = false)
        @test node.style.color == :green && node.style.bold == false
    end

    # Test with isnothing(node.score), expecting default style
    @test begin
        node = AnnotatedNode(score = nothing)
        set_node_style!(annotater, node)
        @test node.style.color == :nothing && node.style.bold == false
    end
end

@testset "align_node_styles!" begin
    annotater = TrigramAnnotater()

    # Setup for tests: Create a sequence of nodes with varied styles
    node1 = AnnotatedNode(style = Styler(color = :red), score = 1.0)
    node2 = AnnotatedNode(style = Styler(), score = nothing) # Target for style alignment
    node3 = AnnotatedNode(style = Styler(color = :red), score = 1.0)
    nodes = [node1, node2, node3]

    # Test aligning styles in a simple sequence
    @test begin
        align_node_styles!(annotater, nodes)
        @test nodes[2].style.color == :red
    end

    # Test with non-matching surrounding styles, expecting no change
    @test begin
        node4 = AnnotatedNode(style = Styler(color = :green), score = 1.0) # Different style
        node5 = AnnotatedNode(style = Styler(), score = nothing) # Target for style alignment
        node6 = AnnotatedNode(style = Styler(color = :red), score = 1.0)
        nodes2 = [node4, node5, node6]

        align_node_styles!(annotater, nodes2)
        @test nodes2[2].style.color == :nothing # Should remain unchanged
    end

    # Test with first and last nodes, which should not be aligned
    @test begin
        node7 = AnnotatedNode(style = Styler(), score = nothing) # First node
        node8 = AnnotatedNode(style = Styler(color = :blue), score = 1.0)
        node9 = AnnotatedNode(style = Styler(), score = nothing) # Last node
        nodes3 = [node7, node8, node9]

        align_node_styles!(annotater, nodes3)
        @test nodes3[1].style.color == :nothing && nodes3[3].style.color == :nothing # Should remain unchanged
    end

    # Test aligning styles with more complex sequences
    @test begin
        node10 = AnnotatedNode(style = Styler(color = :blue), score = 1.0)
        node11 = AnnotatedNode(style = Styler(), score = nothing) # Target for style alignment
        node12 = AnnotatedNode(style = Styler(color = :blue), score = 1.0)
        node13 = AnnotatedNode(style = Styler(), score = nothing) # Another target, but no adjacent same styles
        nodes4 = [node10, node11, node12, node13]

        align_node_styles!(annotater, nodes4)
        @test nodes4[2].style.color == :blue && nodes4[4].style.color == :nothing
    end
end

function pprint(io::IO, node::AnnotatedNode{T}) where {T}
    if isempty(node.children)
        printstyled(io, node.content; bold = node.style.bold, color = node.style.color,
            underline = node.style.underline, italic = node.style.italic)
    else
        for child in node.children
            pprint(io, child)
        end
    end
end

@testset "pprint" begin
    # Test pprint with a single node
    @test begin
        node = AnnotatedNode(content = "root", style = Styler(color = :red, bold = true))
        io = IOBuffer()
        pprint(io, node)
        @test String(take!(io)) == "root" # Simplified check due to lack of styled output in tests
    end

    # Test pprint with nested children
    @test begin
        parent_node = AnnotatedNode(content = "parent")
        child_node1 = AnnotatedNode(content = "child1", style = Styler(bold = true))
        child_node2 = AnnotatedNode(content = "child2", style = Styler(italic = true))
        push!(parent_node.children, child_node1)
        push!(parent_node.children, child_node2)

        io = IOBuffer()
        pprint(io, parent_node)
        output = String(take!(io))
        expected_output = "child1child2" # Simplified check; in practice, validate styled output
        @test output == expected_output
    end

    # Test pprint with empty content
    @test begin
        node = AnnotatedNode()
        io = IOBuffer()
        pprint(io, node)
        @test String(take!(io)) == ""
    end

    # Test pprint with complex hierarchy
    @test begin
        parent_node = AnnotatedNode(content = "parent", style = Styler(color = :blue))
        child_node = AnnotatedNode(content = "child", style = Styler(underline = true))
        grandchild_node = AnnotatedNode(content = "grandchild", style = Styler(bold = true))

        push!(child_node.children, grandchild_node)
        push!(parent_node.children, child_node)

        io = IOBuffer()
        pprint(io, parent_node)
        output = String(take!(io))
        expected_output = "childgrandchild" # Simplified; actual output would include styles
        @test output == expected_output
    end
end

@testset "trigram_support!" begin
    # Preparing a mock context of trigrams for testing
    context_trigrams = [trigrams("This is a test."), trigrams("Another test."),
        trigrams("More content here.")]

    # Test updating a node with no matching trigrams in context
    @test begin
        node = AnnotatedNode(content = "Unrelated content")
        trigram_support!(node, context_trigrams)
        isempty(node.children) && isnothing(node.score) && node.hits == 0
    end

    # Test updating a node with partial matching trigrams in context
    @test begin
        node = AnnotatedNode(content = "This is")
        trigram_support!(node, context_trigrams)
        !isempty(node.children) && node.score > 0 &&
            node.hits < length(tokenize(node.content))
    end

    # Test updating a node with full matching trigrams in context
    @test begin
        node = AnnotatedNode(content = "Another test.")
        trigram_support!(node, context_trigrams)
        !isempty(node.children) && !isnothing(node.score) &&
            node.hits == length(tokenize(node.content))
    end

    # Test handling of a single-character content, which should not form trigrams
    @test begin
        node = AnnotatedNode(content = "A")
        trigram_support!(node, context_trigrams)
        !isempty(node.children) && isnothing(node.score) && node.hits == 0
    end

    # Test with an empty content, expecting no children and no score
    @test begin
        node = AnnotatedNode(content = "")
        trigram_support!(node, context_trigrams)
        isempty(node.children) && isnothing(node.score)
    end
end

@testset "annotate_support" begin
    # Context setup for testing
    annotater = TrigramAnnotater()
    context = [
        "This is a test context.", "Another context sentence.", "Final piece of context."]
    context_trigrams = prepare_context_trigrams(context)

    # Test annotating an answer that partially matches the context
    @test begin
        answer = "This is a test answer. It has multiple sentences."
        annotated_root = annotate_support(annotater, answer, context_trigrams)
        !isempty(annotated_root.children) && length(annotated_root.children) == 2
    end

    # Test annotating an answer that fully matches the context
    @test begin
        answer = "This is a test context. Another context sentence."
        annotated_root = annotate_support(annotater, answer, context_trigrams)
        all(child -> !isnothing(child.score) && child.hits > 0, annotated_root.children)
    end

    # Test annotating an answer with no matching content in the context
    @test begin
        answer = "Unrelated content here. Completely different."
        annotated_root = annotate_support(annotater, answer, context_trigrams)
        all(child -> isnothing(child.score), annotated_root.children)
    end

    # Test annotating an empty answer, expecting a root node with no children
    @test begin
        answer = ""
        annotated_root = annotate_support(annotater, answer, context_trigrams)
        isempty(annotated_root.children)
    end

    # Test handling of special characters and punctuation in the answer
    @test begin
        answer = "Special characters: !@#$%. Punctuation marks: ,;:."
        annotated_root = annotate_support(annotater, answer, context_trigrams)
        !isempty(annotated_root.children) && length(annotated_root.children) == 2
    end
end

# TODO: add_node_metadata!