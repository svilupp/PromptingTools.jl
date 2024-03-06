using PromptingTools.Experimental.RAGTools: AnnotatedNode, set_node_style!,
                                            align_node_styles!, TrigramAnnotater, Styler,
                                            pprint
using PromptingTools.Experimental.RAGTools: trigram_support!, add_node_metadata!,
                                            annotate_support

@testset "AnnotatedNode" begin
    # Test node creation with default values
    node = AnnotatedNode()
    @test node.group_id == 0
    @test isnothing(node.parent)
    @test isempty(node.children)
    @test isnothing(node.score)
    @test node.hits == 0
    @test node.content == ""
    @test isempty(node.sources)
    @test typeof(node.style) == Styler && node.style.color == :nothing

    # Test node creation with specific values
    parent_node = AnnotatedNode(content = "parent")
    child_node = AnnotatedNode(parent = parent_node, content = "child")
    push!(parent_node.children, child_node)
    child_node2 = AnnotatedNode(parent = parent_node, content = "child2")
    push!(parent_node.children, child_node2)

    @test child_node.parent === parent_node
    @test child_node.content == "child"
    @test length(parent_node.children) == 2
    @test parent_node.children[1] === child_node

    # Test AbstractTrees interface compatibility
    @test AbstractTrees.children(parent_node) == [child_node, child_node2]
    @test AbstractTrees.parent(child_node) === parent_node
    @test AbstractTrees.parent(child_node2) === parent_node

    # Test nodevalue and childtype methods for tree traversal
    @test AbstractTrees.nodevalue(child_node) == "child(nothing)"
    @test AbstractTrees.childtype(node) === AnnotatedNode
end

@testset "AnnotatedNode-pprint" begin
    # Test pprint function for a single node
    node = AnnotatedNode(content = "test", group_id = 123)
    io = IOBuffer()
    pprint(io, node)
    @test String(take!(io)) == "test"

    ## Multiple nodes
    parent_node = AnnotatedNode(content = "parent")
    child_node = AnnotatedNode(parent = parent_node, content = "child")
    push!(parent_node.children, child_node)
    child_node2 = AnnotatedNode(parent = parent_node, content = "child2")
    push!(parent_node.children, child_node2)
    io = IOBuffer()
    pprint(io, parent_node)
    output = String(take!(io))
    # iterate over all nodes with no children
    @test output == "childchild2"

    # Add one more child
    child_node3 = AnnotatedNode(parent = child_node2, content = "child3")
    push!(child_node2.children, child_node3)
    io = IOBuffer()
    pprint(io, parent_node)
    output = String(take!(io))
    @test output == "childchild3"
end

@testset "set_node_style!" begin
    annotater = TrigramAnnotater()

    # Test with a high score exceeding high_threshold
    node = AnnotatedNode(score = 0.9)
    set_node_style!(annotater, node; high_threshold = 0.8, low_threshold = 0.3)
    @test node.style.color == :green
    @test node.style.bold == false

    # Test with a score between high_threshold and low_threshold
    node = AnnotatedNode(score = 0.4)
    set_node_style!(annotater, node; high_threshold = 0.8, low_threshold = 0.3)
    @test node.style.color == :magenta
    @test node.style.bold == false

    # Test with a score below low_threshold
    node = AnnotatedNode(score = 0.2)
    set_node_style!(annotater, node; high_threshold = 0.8, low_threshold = 0.3)
    @test node.style.color == :nothing
    @test node.style.bold == false

    # Test applying bold style for multiple hits
    node = AnnotatedNode(score = 0.9, hits = 2)
    set_node_style!(annotater, node; high_threshold = 0.8, bold_multihits = true)
    @test node.style.color == :green
    @test node.style.bold == true

    # Test not applying bold style when bold_multihits is false
    node = AnnotatedNode(score = 0.9, hits = 2)
    set_node_style!(annotater, node; high_threshold = 0.8, bold_multihits = false)
    @test node.style.color == :green
    @test node.style.bold == false

    # Test with isnothing(node.score), expecting default style
    node = AnnotatedNode(score = nothing)
    set_node_style!(annotater, node)
    @test node.style.color == :nothing
    @test node.style.bold == false
end

@testset "align_node_styles!" begin
    annotater = TrigramAnnotater()

    # Setup for tests: Create a sequence of nodes with varied styles
    node1 = AnnotatedNode(style = Styler(color = :red), score = 1.0)
    node2 = AnnotatedNode(style = Styler(), score = nothing) # Target for style alignment
    node3 = AnnotatedNode(style = Styler(color = :red), score = 1.0)
    nodes = [node1, node2, node3]

    # Test aligning styles in a simple sequence
    align_node_styles!(annotater, nodes)
    @test nodes[2].style.color == :red

    # Test with non-matching surrounding styles, expecting no change
    node4 = AnnotatedNode(style = Styler(color = :green), score = 1.0) # Different style
    node5 = AnnotatedNode(style = Styler(), score = nothing) # Target for style alignment
    node6 = AnnotatedNode(style = Styler(color = :red), score = 1.0)
    nodes2 = [node4, node5, node6]

    align_node_styles!(annotater, nodes2)
    @test nodes2[2].style.color == :nothing # Should remain unchanged

    # Test with first and last nodes, which should not be aligned
    node7 = AnnotatedNode(style = Styler(), score = nothing) # First node
    node8 = AnnotatedNode(style = Styler(color = :blue), score = 1.0)
    node9 = AnnotatedNode(style = Styler(), score = nothing) # Last node
    nodes3 = [node7, node8, node9]

    align_node_styles!(annotater, nodes3)
    @test nodes3[1].style.color == :nothing
    @test nodes3[3].style.color == :nothing # Should remain unchanged

    # Test aligning styles with more complex sequences
    node10 = AnnotatedNode(style = Styler(color = :blue), score = 1.0)
    node11 = AnnotatedNode(style = Styler(), score = nothing) # Target for style alignment
    node12 = AnnotatedNode(style = Styler(color = :blue), score = 1.0)
    node13 = AnnotatedNode(style = Styler(), score = nothing) # Another target, but no adjacent same styles
    nodes4 = [node10, node11, node12, node13]

    align_node_styles!(annotater, nodes4)
    @test nodes4[2].style.color == :blue
    @test nodes4[4].style.color == :nothing
end

# TODO: continue
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