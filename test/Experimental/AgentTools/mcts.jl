using PromptingTools.Experimental.AgentTools: expand!, find_node, backpropagate!, SampleNode
using PromptingTools.Experimental.AgentTools: print_tree,
                                              print_samples, reset_success!,
                                              collect_all_feedback
using PromptingTools.Experimental.AgentTools: score,
                                              UCT, ThompsonSampling,
                                              AbstractScoringMethod, select_best

@testset "SampleNode,expand!,find_node,reset_success!,print_samples" begin
    data = PT.AbstractMessage[]
    root = SampleNode(; data)
    child1 = expand!(root, data)
    child2 = expand!(root, data)
    child11 = expand!(child1, data; success = true)

    ## parent, children
    @test AbstractTrees.parent(root) == nothing
    @test AbstractTrees.children(root) == [child1, child2]
    @test AbstractTrees.children(child1) == [child11]

    ## Getindex, find_node
    @test root[child11.id] == child11
    @test root[-1] == nothing

    # length
    @test length(root) == 4
    @test length(child1) == 2
    @test length(child11) == 1

    ## Show method
    io = IOBuffer()
    show(io, child1)
    @test String(take!(io)) == "SampleNode(id: $(child1.id), stats: 0/0, length: 0)"

    ## print_tree
    io = IOBuffer()
    print_tree(io, root)
    s = String(take!(io))
    @test occursin("id: $(root.id)", s)
    @test occursin("id: $(child1.id)", s)
    @test occursin("id: $(child2.id)", s)
    @test occursin("id: $(child11.id)", s)

    ## print_samples
    io = IOBuffer()
    print_samples(io, root)
    s = String(take!(io))
    @test occursin("id: $(root.id)", s)
    @test occursin("id: $(child1.id)", s)
    @test occursin("id: $(child2.id)", s)
    @test occursin("id: $(child11.id)", s)
    @test occursin("score: ", s)

    ## expand! kwargs
    @test root.success == nothing
    @test child11.success == true

    ## reset_success!
    reset_success!(root, true)
    @test root.success == true
    @test child1.success == true
    @test child2.success == true
    @test child11.success == true

    ## copy
    root_copy = copy(root)
    @test root_copy.id == root.id
    @test root_copy.data == root.data
    @test root_copy.success == root.success
    @test root_copy.feedback == root.feedback
    @test root_copy !== root
end

@testset "collect_all_feedback" begin
    data = PT.AbstractMessage[]
    root = SampleNode(; data, feedback = "Feedback 3")
    child1 = expand!(root, data, feedback = "Feedback 2")
    child2 = expand!(root, data, feedback = "")
    child11 = expand!(child1, data; feedback = "Feedback 0")

    # Test for collecting feedback of the toplevel node
    @test collect_all_feedback(root) == "Feedback 3"

    @test collect_all_feedback(child11) ==
          "Feedback 3\n----------\nFeedback 2\n----------\nFeedback 0"

    # Test for correct handling of custom separator
    alternative_separator = " | "
    @test collect_all_feedback(child11, separator = alternative_separator) ==
          "Feedback 3 | Feedback 2 | Feedback 0"

    # Test to ensure function works with empty feedback strings
    node_without_feedback = SampleNode(; data, feedback = "")
    @test collect_all_feedback(node_without_feedback) == ""

    # Test functionality when nodes have a mix of empty and non-empty feedback
    @test collect_all_feedback(child2) == "Feedback 3"
end

@testset "score" begin
    data = PT.AbstractMessage[]
    node_with_parent = SampleNode(; data, wins = 10, visits = 20) # Provide necessary fields
    parent_node = SampleNode(; data, wins = 15, visits = 30)
    node_with_parent.parent = parent_node

    node_without_parent = SampleNode(; data, wins = 5, visits = 10)
    ## UCT
    uct_scoring = UCT(exploration = 2)
    @test score(node_with_parent, uct_scoring) ≈ 0.5 + sqrt(log(30) / 20) * 2
    @test score(node_without_parent, uct_scoring) == 0.5

    ## Thompson Sampling -- beta_sample is a random function, so we can only test for the range
    ts_scoring = ThompsonSampling(alpha = 1, beta = 1)
    @test 0 <= score(node_with_parent, ts_scoring) <= 1
    @test 0 <= score(node_without_parent, ts_scoring) <= 1
    ## high alpha means closer to 1
    ts_scoring_high = ThompsonSampling(alpha = 1001, beta = 1)
    @test score(node_with_parent, ts_scoring_high) >= 1001 / 1002 - 0.2 # tolerance
    ts_scoring_low = ThompsonSampling(alpha = 1, beta = 1001)
    @test score(node_with_parent, ts_scoring_low) <= 1 / 1002 + 0.2 # tolerance

    ## unsupported scoring method
    struct MyRand125Scoring <: AbstractScoringMethod end
    @test_throws ArgumentError score(node_with_parent, MyRand125Scoring()) # should throw an error
end

@testset "backpropagate!" begin
    data = PT.AbstractMessage[]
    root = SampleNode(; data)
    child1 = expand!(root, data)
    backpropagate!(child1; wins = 1, visits = 1)
    child2 = expand!(root, data)
    backpropagate!(child2; wins = 0, visits = 1)
    child11 = expand!(child1, data)
    backpropagate!(child11; wins = 1, visits = 1)

    @test root.wins == 2
    @test root.visits == 3
    @test child1.wins == 2
    @test child1.visits == 2
    @test child2.wins == 0
    @test child2.visits == 1
    @test child11.wins == 1
    @test child11.visits == 1

    # Scenario: applying backpropagate! to the root node (only affects the root)
    backpropagate!(root; wins = 2, visits = 2)
    @test root.wins == 4
    @test root.visits == 5

    # Scenario: applying backpropagate! to a child node (affects the child and the root)
    backpropagate!(child11; wins = 2, visits = 2)
    @test child11.wins == 3
    @test child11.visits == 3
    @test root.wins == 6
    @test root.visits == 7
    # no change
    @test child2.wins == 0
    @test child2.visits == 1
end

@testset "select_best" begin
    data = PT.AbstractMessage[]
    root = SampleNode(; data)
    child1 = expand!(root, data)
    backpropagate!(child1; wins = 1, visits = 1)
    child2 = expand!(root, data)
    backpropagate!(child2; wins = 0, visits = 1)
    child11 = expand!(child1, data)
    backpropagate!(child11; wins = 1, visits = 1)

    for scoring in [UCT(), ThompsonSampling()]
        for ordering in [:PreOrderDFS, :PostOrderDFS]
            s = select_best(root, scoring, ordering = ordering)
            @test s isa SampleNode
        end
    end

    # Ensure that an assertion error is raised for invalid `ordering` values
    @test_throws AssertionError select_best(root, UCT(), ordering = :InvalidOrder)

    ## UCT is quite stable
    best_uct1 = select_best(root, UCT(); ordering = :PreOrderDFS)
    best_uct2 = select_best(root, UCT(); ordering = :PostOrderDFS)
    @test child11 == best_uct1 == best_uct2

    ## ThompsonSampling test with stronger statistics to avoid flakiness
    # Create a separate tree with more visits to make selection deterministic
    data2 = PT.AbstractMessage[]
    root2 = SampleNode(; data = data2)
    good_child = expand!(root2, data2)
    backpropagate!(good_child; wins = 10, visits = 10)  # 100% win rate
    bad_child = expand!(root2, data2)
    backpropagate!(bad_child; wins = 0, visits = 10)    # 0% win rate
    # With these stats: good_child ~ Beta(11,1), bad_child ~ Beta(1,11)
    # Probability of bad_child winning is negligible (~1e-6)
    best_ts = select_best(root2, ThompsonSampling())
    @test bad_child != best_ts  # Should never select the clearly losing node

    ## if no scores, Pre/Post with UCT determines which node is selected
    data = PT.AbstractMessage[]
    root = SampleNode(; data)
    child1 = expand!(root, data)
    child2 = expand!(root, data)
    child11 = expand!(child1, data)

    # PreOrder picks the root node
    best_uct1 = select_best(root, UCT(); ordering = :PreOrderDFS)
    @test root == best_uct1
    # PostOrder picks the leaf node
    best_uct2 = select_best(root, UCT(); ordering = :PostOrderDFS)
    @test child11 == best_uct2
end
