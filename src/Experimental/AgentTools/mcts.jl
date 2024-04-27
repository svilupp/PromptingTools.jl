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
@kwdef struct ThompsonSampling <: AbstractScoringMethod
    alpha::Float64 = 1.0  # Alpha parameter for the Beta distribution
    beta::Float64 = 1.0  # Beta parameter for the Beta distribution
end

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
function Base.show(io::IO, node::SampleNode;
        scoring::Union{Nothing, AbstractScoringMethod} = nothing)
    score_str = isnothing(scoring) ? "" : ", score: $(round(score(node, scoring),digits=2))"
    length_str = node.data isa AbstractVector ? ", length: $(length(node.data))" : ""
    print(io,
        "SampleNode(id: $(node.id), stats: $(node.wins)/$(node.visits)$(score_str)$(length_str))")
end
function Base.getindex(node::SampleNode, id::Integer)
    find_node(node, id)
end
function Base.length(node::SampleNode)
    PreOrderDFS(node) |> collect |> length
end
function Base.var"=="(n1::SampleNode, n2::SampleNode)
    all(fieldnames(typeof(n1))) do f
        if f == :parent
            ## both must have a parent or both must not have a parent
            ## if they don't have a parent, they are equal
            ## if they have a parent, the parent id must be the same
            isnothing(n1.parent) == isnothing(n2.parent) &&
                (isnothing(n1.parent) || (n1.parent.id == n2.parent.id))
        elseif f == :children
            all(x -> x[1].id == x[2].id, zip(n1.children, n2.children))
        else
            getfield(n1, f) == getfield(n2, f)
        end
    end
end
function Base.copy(n::SampleNode)
    return deepcopy(n)
end

"Expands the tree with a new node from `parent` using the given `data` and `success`."
function expand!(parent::SampleNode, data;
        success::Union{Nothing, Bool} = true, feedback::String = "")
    child = SampleNode(; data, parent, success, feedback)
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
    throw(ArgumentError("Scoring method not implemented for `score` with $(typeof(scoring))"))
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
    (; alpha, beta) = scoring
    s = beta_sample(alpha + node.wins, beta + node.visits - node.wins)
end

"""
    select_best(node::SampleNode, scoring::AbstractScoringMethod = UCT();
        ordering::Symbol = :PostOrderDFS)

Selects the best node from the tree using the given `scoring` (`UCT` or `ThompsonSampling`). Defaults to UCT.
Thompson Sampling is more random with small samples, while UCT stabilizes much quicker thanks to looking at parent nodes as well.

Ordering can be either `:PreOrderDFS` or `:PostOrderDFS`. Defaults to `:PostOrderDFS`, which favors the leaves (end points of the tree).

# Example
Compare the different scoring methods:
```julia
# Set up mock samples and scores
data = PT.AbstractMessage[]
root = SampleNode(; data)
child1 = expand!(root, data)
backpropagate!(child1; wins = 1, visits = 1)
child2 = expand!(root, data)
backpropagate!(child2; wins = 0, visits = 1)
child11 = expand!(child1, data)
backpropagate!(child11; wins = 1, visits = 1)

# Select with UCT
n = select_best(root, UCT())
SampleNode(id: 29826, stats: 1/1, length: 0)

# Show the tree:
print_samples(root; scoring = UCT())
## SampleNode(id: 13184, stats: 2/3, score: 0.67, length: 0)
## ├─ SampleNode(id: 26078, stats: 2/2, score: 2.05, length: 0)
## │  └─ SampleNode(id: 29826, stats: 1/1, score: 2.18, length: 0)
## └─ SampleNode(id: 39931, stats: 0/1, score: 1.48, length: 0)

# Select with ThompsonSampling - much more random with small samples
n = select_best(root, ThompsonSampling())
SampleNode(id: 26078, stats: 2/2, length: 0)

# Show the tree (run it a few times and see how the scores jump around):
print_samples(root; scoring = ThompsonSampling())
## SampleNode(id: 13184, stats: 2/3, score: 0.6, length: 0)
## ├─ SampleNode(id: 26078, stats: 2/2, score: 0.93, length: 0)
## │  └─ SampleNode(id: 29826, stats: 1/1, score: 0.22, length: 0)
## └─ SampleNode(id: 39931, stats: 0/1, score: 0.84, length: 0)

```
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
    print_samples(stdout, node; scoring)
end
function print_samples(io::IO, node::SampleNode; scoring::AbstractScoringMethod = UCT())
    print_tree(show, io, node; printnode_kw = (; scoring))
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
