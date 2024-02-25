### Monte Carlo Tree Search
# Lightweight implementation of the Monte Carlo Tree Search algorithm.
# Source: [Wikipedia: Monte Carlo Tree Search](https://en.wikipedia.org/wiki/Monte_Carlo_tree_search)
# Source: [Language Agent Tree Search Unifies Reasoning Acting and Planning in Language Models](https://arxiv.org/abs/2310.04406)
#
# Key types:
# - `SampleNode`
# - `UCT`

abstract type AbstractScoringMethod end

"""
    ThompsonSampling <: AbstractScoringMethod

Implements scoring and selection for Thompson Sampling method. See https://en.wikipedia.org/wiki/Thompson_sampling for more details.
"""
struct ThompsonSampling <: AbstractScoringMethod
end
# TODO: implement Thompson Sampling

"""
    UCT <: AbstractScoringMethod

Implements scoring and selection for UCT (Upper Confidence Bound for Trees) sampling method. See https://en.wikipedia.org/wiki/Monte_Carlo_tree_search#Exploration_and_exploitation for more details.
"""
@kwdef struct UCT <: AbstractScoringMethod
    exploration::Float64 = sqrt(2.0)  # Exploration parameter, higher values encourage more exploration
end

"""
    SampleNode{T}

A node in the Monte Carlo Tree Search tree. 

It's used to hold the `data` we're trying to optimize/discover (eg, a conversation), the scores from evaluation (`wins`, `visits`) and the results of the evaluations upon failure (`feedback`).

# Fields
- `id::UInt16`: Unique identifier for the node
- `parent::Union{SampleNode, Nothing}`: Parent node that current node was built on
- `children::Vector{SampleNode}`: Children nodes
- `wins::Int`: Number of successful outcomes
- `visits::Int`: Number of condition checks done (eg, losses are `checks - wins`)
- `data::T`: eg, the conversation or some parameter to be optimized
- `feedback::String`: Feedback from the evaluation, always a string! Defaults to empty string.
- `success::Union{Nothing, Bool}`: Success of the generation and subsequent evaluations, proxy for whether it should be further evaluated. Defaults to nothing.
"""
@kwdef mutable struct SampleNode{T}
    id::UInt16 = rand(UInt16)
    parent::Union{SampleNode, Nothing} = nothing
    children::Vector{SampleNode} = SampleNode[]
    wins::Int = 0  # Number of successful outcomes
    visits::Int = 0  # Number of condition checks done (eg, losses are `checks - wins`)
    data::T  # eg, the conversation or some parameter to be optimized
    feedback::String = ""
    success::Union{Nothing, Bool} = nothing # succes of the generation/tests, proxy for whether it should be further evaluated
end

Base.IteratorEltype(::Type{<:TreeIterator{SampleNode}}) = Base.HasEltype()
Base.eltype(::Type{<:TreeIterator{SampleNode{T}}}) where {T} = SampleNode{T}
AbstractTrees.childtype(::Type{SampleNode{T}}) where {T} = SampleNode{T}

function AbstractTrees.children(node::SampleNode)
    return node.children
end
AbstractTrees.parent(n::SampleNode) = n.parent
## AbstractTrees.nodevalue(n::SampleNode) = n.data
function Base.show(
        io::IO, node::SampleNode; scoring::Union{Nothing, AbstractScoringMethod} = nothing)
    score_str = isnothing(scoring) ? "" : ", score: $(round(score(node, scoring),digits=2))"
    length_str = node.data isa AbstractVector ? ", length: $(length(node.data))" : ""
    print(io,
        "SampleNode(id: $(node.id), stats: $(node.wins)/$(node.visits)$(score_str)$(length_str))")
end
function Base.getindex(node::SampleNode, id::Integer)
    find_node(node, id)
end

"Expands the tree with a new node from `parent` using the given `data` and `success`."
function expand!(parent::SampleNode, data; success::Union{Nothing, Bool} = true)
    child = SampleNode(; data, parent, success)
    push!(AbstractTrees.children(parent), child)
    return child
end

"Provides scores for a given node (and all its ancestors) based on the evaluation (`wins`, `visits`)."
function backpropagate!(node::SampleNode; wins::Integer, visits::Int = 1)
    # Update current node and all ancestors
    while node !== nothing
        node.wins += wins
        node.visits += visits
        # Backprop to parent
        node = AbstractTrees.parent(node)
    end
end

function score(node::SampleNode, scoring::AbstractScoringMethod)
    throw(ArgumentError("Scoring method not implemented for `score` with $(typeof(method))"))
end

"Scores a node using the UCT (Upper Confidence Bound for Trees) method."
function score(node::SampleNode, scoring::UCT)
    parent_node = AbstractTrees.parent(node)
    parent_node_score = isnothing(parent_node) || iszero(parent_node.visits) ? 0.0 :
                        scoring.exploration * sqrt(log(parent_node.visits) / node.visits)
    s = iszero(node.visits) ? 0.0 : node.wins / node.visits + parent_node_score
end

"Scores a node using the ThomsonSampling method, similar to Bandit algorithms."
function score(node::SampleNode, scoring::ThompsonSampling)
    parent_node = AbstractTrees.parent(node)
    ## parent_node_score = isnothing(parent_node) || iszero(parent_node.visits) ? 0.0 :
    ##                     scoring.exploration * sqrt(log(parent_node.visits) / node.visits)
    ## s = iszero(node.visits) ? 0.0 : node.wins / node.visits + parent_node_score
    # TODO: implement Thompson Sampling
    s = 0.0
end

"""
    select_best(node::SampleNode, scoring::AbstractScoringMethod = UCT();
        ordering::Symbol = :PostOrderDFS)

Selects the best node from the tree using the given `scoring`. Defaults to UCT.

Ordering can be either `:PreOrderDFS` or `:PostOrderDFS`. Defaults to `:PostOrderDFS`, which favors the leaves (end points of the tree).
"""
function select_best(node::SampleNode, scoring::AbstractScoringMethod = UCT();
        ordering::Symbol = :PostOrderDFS)
    @assert ordering in (:PreOrderDFS, :PostOrderDFS) "Only PreOrderDFS and PostOrderDFS are supported for `ordering` (provided: $ordering)."
    best_val = -Inf
    best_node = nothing
    if ordering == :PreOrderDFS
        for n in AbstractTrees.PreOrderDFS(node)
            val = score(n, scoring)
            if val > best_val
                best_val = val
                best_node = n
            end
        end
    elseif ordering == :PostOrderDFS
        for n in AbstractTrees.PostOrderDFS(node)
            val = score(n, scoring)
            if val > best_val
                best_val = val
                best_node = n
            end
        end
    end
    return best_node
end

"Finds a node with a given `id` in the tree starting from `node`."
function find_node(node::SampleNode, id::Integer)
    for n in AbstractTrees.PreOrderDFS(node)
        if n.id == id
            return n
        end
    end
    return nothing
end

"Pretty prints the samples tree starting from `node`. Usually, `node` is the root of the tree. Example: `print_samples(aicall.samples)`."
function print_samples(node::SampleNode; scoring::AbstractScoringMethod = UCT())
    print_tree(show, stdout, node; printnode_kw = (; scoring = UCT()))
end
function Base.copy(n::SampleNode)
    return deepcopy(n)
end

"Sets the `success` field of all nodes in the tree to `success` value."
function reset_success!(node::SampleNode, success::Bool = true)
    for n in AbstractTrees.PreOrderDFS(node)
        n.success = success
    end
    return nothing
end

"Collects all feedback from the node and its ancestors (parents). Returns a string separated by `separator`."
function collect_all_feedback(node::SampleNode; separator::String = "\n$("-"^10)\n")
    feedback = String[]
    while node !== nothing
        !isempty(node.feedback) && push!(feedback, node.feedback)
        node = AbstractTrees.parent(node)
    end
    return join(reverse(feedback), separator)
end