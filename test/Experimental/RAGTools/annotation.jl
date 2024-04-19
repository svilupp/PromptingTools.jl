using PromptingTools.Experimental.RAGTools: AnnotatedNode, AbstractAnnotater,
                                            AbstractAnnotatedNode,
                                            set_node_style!,
                                            align_node_styles!, TrigramAnnotater, Styler,
                                            HTMLStyler,
                                            pprint, print_html
using PromptingTools.Experimental.RAGTools: trigram_support!, add_node_metadata!,
                                            annotate_support, RAGResult, text_to_trigrams

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

    # Show
    node = AnnotatedNode()
    io = IOBuffer()
    show(io, node)
    output = String(take!(io))
    @test output == "AnnotatedNode(group id: 0, length: 0, score: -"
    # test inequality
    struct Random123AnnotatedNode <: AbstractAnnotatedNode end
    @test AnnotatedNode() != Random123AnnotatedNode()
end

@testset "AnnotatedNode-pprint" begin
    # Test pprint function for a single node
    node = AnnotatedNode(content = "test", group_id = 123)
    io = IOBuffer()
    pprint(io, node; add_newline = false)
    @test String(take!(io)) == "test"

    ## Multiple nodes
    parent_node = AnnotatedNode(content = "parent")
    child_node = AnnotatedNode(parent = parent_node, content = "child")
    push!(parent_node.children, child_node)
    child_node2 = AnnotatedNode(parent = parent_node, content = "child2")
    push!(parent_node.children, child_node2)
    io = IOBuffer()
    pprint(io, parent_node; add_newline = false)
    output = String(take!(io))
    # iterate over all nodes with no children
    @test output == "childchild2"

    # Add one more child
    child_node3 = AnnotatedNode(parent = child_node2, content = "child3")
    push!(child_node2.children, child_node3)
    io = IOBuffer()
    pprint(io, parent_node)
    output = String(take!(io))
    @test output == "childchild3\n"
end

@testset "set_node_style!" begin
    annotater = TrigramAnnotater()

    # Test with a high score exceeding high_threshold
    node = AnnotatedNode(score = 0.9)
    set_node_style!(annotater, node; high_styler = Styler(color = :green),
        high_threshold = 0.8, low_threshold = 0.3)
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
    set_node_style!(annotater, node; high_threshold = 0.8, bold_multihits = true,
        high_styler = Styler(color = :green))
    @test node.style.color == :green
    @test node.style.bold == true

    # Test not applying bold style when bold_multihits is false
    node = AnnotatedNode(score = 0.9, hits = 2)
    set_node_style!(annotater, node; high_threshold = 0.8, bold_multihits = false,
        high_styler = Styler(color = :green))
    @test node.style.color == :green
    @test node.style.bold == false

    # Test with isnothing(node.score), expecting default style
    node = AnnotatedNode(score = nothing)
    set_node_style!(annotater, node)
    @test node.style.color == :nothing
    @test node.style.bold == false

    # Unknown types
    struct Random123Annotater <: AbstractAnnotater end
    node = AnnotatedNode()
    @test node == set_node_style!(
        Random123Annotater(), node)

    # Styler inequality
    styler1 = Styler()
    styler2 = Styler()
    @test styler1 == styler2
    styler3 = HTMLStyler("", "")
    @test styler1 != styler3
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

    # Unknown types
    struct Random123Annotater <: AbstractAnnotater end
    nodes = [AnnotatedNode(), AnnotatedNode(), AnnotatedNode()]
    @test nodes == align_node_styles!(
        Random123Annotater(), nodes)
end

@testset "trigram_support!" begin
    # Preparing a mock context of trigrams for testing, capitalize IS to avoid STOPWORDS
    context_trigrams = text_to_trigrams.(["This IS a test.", "Another test.",
        "More content here."])

    # Test updating a node with no matching trigrams in context
    node = AnnotatedNode(content = "xyz")
    trigram_support!(node, context_trigrams)
    @test node.children[1].score ≈ 0
    @test node.hits == 0

    # Test updating a node with partial matching trigrams in context
    node = AnnotatedNode(content = "This IS")
    trigram_support!(node, context_trigrams)
    @test length(node.children) == 3
    @test node.score == 1.0
    @test node.children[1].hits == 1
    @test node.children[3].hits == 1

    # Test updating a node with full matching trigrams in context
    node = AnnotatedNode(content = "Another test.")
    trigram_support!(node, context_trigrams)
    @test node.children[1].hits == 1
    @test node.children[3].hits == 2

    # Test handling of a single-character content, which should not be scored
    node = AnnotatedNode(content = "A")
    trigram_support!(node, context_trigrams)
    @test node.children[1].score == nothing

    # Test with an empty content, expecting no children and 0 score
    node = AnnotatedNode(content = "")
    trigram_support!(node, context_trigrams)
    @test isempty(node.children)
    @test node.score ≈ 0
end

@testset "add_node_metadata!" begin
    annotater = TrigramAnnotater()

    # Empty root node
    root = AnnotatedNode()
    modified_root = add_node_metadata!(annotater, root)
    @test isempty(modified_root.children)

    # Single group, no sources or scores addition
    root = AnnotatedNode()
    child1 = AnnotatedNode(group_id = 1, content = "Child 1", score = 0.5, sources = [1])
    push!(root.children, child1)
    add_node_metadata!(annotater, root, add_sources = false, add_scores = false)
    @test length(root.children) == 1
    @test root.children[1].content == "Child 1"

    # Multiple groups with sources and scores
    root = AnnotatedNode()
    child1 = AnnotatedNode(group_id = 1, content = "Child 1", score = 0.5, sources = [1])
    child2 = AnnotatedNode(group_id = 2, content = "Child 2", score = 0.8, sources = [2])
    push!(root.children, child1, child2)
    add_node_metadata!(annotater, root)
    @test length(root.children) == 4 # Two original children + two metadata node
    @test occursin("[1,0.5]", root.children[2].content)
    @test occursin("[2,0.8]", root.children[4].content)

    # Handle last group metadata correctly for the same group
    root = AnnotatedNode()
    child1 = AnnotatedNode(group_id = 1, content = "Child 1", score = 0.5, sources = [1])
    child2 = AnnotatedNode(
        group_id = 1, content = "Child 2", score = 0.9, sources = [1])
    push!(root.children, child1, child2)
    add_node_metadata!(annotater, root)
    @test occursin("[1,0.7]", root.children[end].content) # Checks if score is averaged correctly

    # Add sources list at the end
    root = AnnotatedNode()
    child = AnnotatedNode(group_id = 1, content = "Child 1", score = 0.5, sources = [1])
    push!(root.children, child)
    add_node_metadata!(annotater, root, sources = ["Source 1"])
    @test occursin("\nSOURCES\n", root.children[end].content)
    @test occursin("1. Source 1", root.children[end].content)

    # Passthrough for unknown
    struct Random123Annotater <: AbstractAnnotater end
    struct Random123AnnotatedNode <: AbstractAnnotatedNode end
    node = Random123AnnotatedNode()
    @test node == add_node_metadata!(
        Random123Annotater(), node)
end

@testset "annotate_support" begin
    # Context setup for testing
    annotater = TrigramAnnotater()
    context = [
        "This is a test context.", "Another context sentence.", "Final piece of context."]

    # Test annotating an answer that partially matches the context
    answer = "This is a test answer. It has multiple sentences."
    annotated_root = annotate_support(annotater, answer, context)
    @test length(annotated_root.children) == 3 # One for each sentence + metadata
    @test annotated_root.score≈0.42 atol=0.01
    io = IOBuffer()
    pprint(io, annotated_root)
    output = String(take!(io))
    @test occursin("[1,0.67]", output)
    @test occursin("This is a test answer.", output)
    @test occursin("It has multiple sentences.", output)

    # Test annotating an answer that fully matches the context
    answer = "This is a test context. Another context sentence."
    annotated_root = annotate_support(annotater, answer, context)
    @test annotated_root.score ≈ 1.0
    @test all(child -> isnothing(child.score) || child.score == 1, annotated_root.children)

    # Test annotating an answer with no matching content in the context
    answer = "Unrelated content here. Completely different."
    annotated_root = annotate_support(annotater, answer, context)
    @test annotated_root.score < 0.2 # some trigram matches on content vs context

    # Test annotating an empty answer, expecting a root node with no children
    answer = ""
    annotated_root = annotate_support(annotater, answer, context)
    @test isempty(annotated_root.children)

    # Test handling of special characters and punctuation in the answer
    answer = "Special characters: !@#\$%. Punctuation marks: ,;:."
    annotated_root = annotate_support(
        annotater, answer, context; add_sources = false, add_scores = false)
    # no scores, so no extra children
    @test length(annotated_root.children) == 3
    io = IOBuffer()
    pprint(io, annotated_root; add_newline = false)
    output = String(take!(io))
    @test answer == output

    # Test adding sources
    answer = "This is a test answer."
    annotated_root = annotate_support(
        annotater, answer, context; sources = ["Source 1", "Source 2", "Source 3"])
    io = IOBuffer()
    pprint(io, annotated_root)
    output = String(take!(io))
    @test occursin("\nSOURCES\n", output)
    @test occursin("1. Source 1", output)

    # Catch empty context
    answer = "This is a test answer."
    @test_throws AssertionError annotated_root=annotate_support(
        annotater, answer, String[])

    ## RAG Details dispatch
    answer = "This is a test answer."
    r = RAGResult(;
        question = "?", final_answer = answer, context, sources = [
            "Source 1", "Source 2", "Source 3"])
    annotated_root = annotate_support(annotater, r)
    io = IOBuffer()
    pprint(io, annotated_root; add_newline = false)
    output = String(take!(io))
    @test occursin("This is a test answer.", output)
    @test occursin("[1,0.67]", output)
    @test occursin("\nSOURCES\n", output)
    @test occursin("1. Source 1", output)

    # Invalid types
    struct Random123Annotater <: AbstractAnnotater end
    @test_throws ArgumentError annotate_support(Random123Annotater(), "test", context)
end

@testset "print_html" begin
    # Test for plain text without any HTML styler
    node = AnnotatedNode(content = "text\nNew line", score = 0.5)
    str = print_html(node)
    @test str == "<div>text<br>New line</div>"

    # Test for single HTMLStyler with no new lines
    styler = HTMLStyler(styles = "font-weight:bold", classes = "highlight")
    node = AnnotatedNode(content = "text\nNew line", score = 0.5, style = styler)
    str = print_html(node)
    @test str ==
          "<div><span style=\"font-weight:bold\" class=\"highlight\">text<br>New line</span></div>"

    # Test for HTMLStyler without styling
    styler = HTMLStyler()
    node = AnnotatedNode(content = "text\nNew line", score = 0.5, style = styler)
    str = print_html(node)
    @test str == "<div>text<br>New line</div>"

    styler = HTMLStyler(styles = "color:red", classes = "error")
    node = AnnotatedNode(
        content = "Error message\nSecond line", score = 0.5, style = styler)
    str = print_html(node)
    @test str ==
          "<div><span style=\"color:red\" class=\"error\">Error message<br>Second line</span></div>"

    ## Test with proper highlighting of context and answer
    styler_kwargs = (;
        default_styler = HTMLStyler(),
        low_styler = HTMLStyler(styles = "color:magenta", classes = ""),
        medium_styler = HTMLStyler(styles = "color:blue", classes = ""),
        high_styler = HTMLStyler(styles = "", classes = ""))

    # annotate the text
    context = [
        "This is a test context.", "Another context sentence.", "Final piece of context."]
    answer = "This is a test answer. It has multiple sentences."

    parent_node = annotate_support(
        TrigramAnnotater(), answer, context; add_sources = false, add_scores = false, styler_kwargs...)

    # print the HTML
    str = print_html(parent_node)
    expected_output = "<div>This is a test <span style=\"color:magenta\">answer</span>. <span style=\"color:magenta\">It</span> has <span style=\"color:magenta\">multiple</span> <span style=\"color:blue\">sentences</span>.</div>"
    @test str == expected_output
    # Test RAGResult overload
    rag = RAGResult(; context, final_answer = answer, question = "")
    str = print_html(rag)
    @test str == expected_output
end
