### Monte Carlo Tree Search
# Lightweight implementation of the Monte Carlo Tree Search algorithm.
# Source: [Wikipedia: Monte Carlo Tree Search](https://en.wikipedia.org/wiki/Monte_Carlo_tree_search)
# Source: [Language Agent Tree Search Unifies Reasoning Acting and Planning in Language Models](https://arxiv.org/abs/2310.04406)
#
# Key types:
# - `SampleNode`
# - `UCT`

abstract type AbstractSamplingMethod end

"""
    ThompsonSampling <: AbstractSamplingMethod

Implements scoring and selection for Thompson Sampling method. See https://en.wikipedia.org/wiki/Thompson_sampling for more details.
"""
struct ThompsonSampling <: AbstractSamplingMethod
end

"""
    UCT <: AbstractSamplingMethod

Implements scoring and selection for UCT (Upper Confidence Bound for Trees) sampling method. See https://en.wikipedia.org/wiki/Monte_Carlo_tree_search#Exploration_and_exploitation for more details.
"""
@kwdef struct UCT <: AbstractSamplingMethod
    exploration::Float64 = sqrt(2.0)  # Exploration parameter, higher values encourage more exploration
end

@kwdef mutable struct SampleNode{T}
    id::UInt16 = rand(UInt16)
    parent::Union{SampleNode, Nothing} = nothing
    children::Vector{SampleNode} = SampleNode[]
    wins::Int = 0  # Number of successful outcomes
    visits::Int = 0  # Number of condition checks done (eg, losses are `checks - wins`)
    data::T  # eg, the conversation or some parameter to be optimized
    success::Union{Nothing, Bool} = nothing # succes of the generation/tests, proxy for whether it should be further evaluated
end

Base.IteratorEltype(::Type{<:TreeIterator{SampleNode}}) = Base.HasEltype()
Base.eltype(::Type{<:TreeIterator{SampleNode{T}}}) where {T} = SampleNode{T}

function AbstractTrees.children(node::SampleNode)
    return node.children
end
AbstractTrees.parent(n::SampleNode) = n.parent
## AbstractTrees.nodevalue(n::SampleNode) = n.data
function Base.show(
        io::IO, node::SampleNode; method::Union{Nothing, AbstractSamplingMethod} = nothing)
    score_str = method === nothing ? "" : ", score: $(round(score(node, method),digits=2))"
    print(io, "SampleNode(id: $(node.id), stats: $(node.wins)/$(node.visits)$(score_str))")
end

function expand!(parent::SampleNode, data; success::Union{Nothing, Bool} = nothing)
    child = SampleNode(; data, parent, success)
    push!(AbstractTrees.children(parent), child)
    return child
end
function backpropagate!(node::SampleNode; wins::Int, visits::Int = 1)
    # Update current node and all ancestors
    while node !== nothing
        node.wins += wins
        node.visits += visits
        # Backprop to parent
        node = AbstractTrees.parent(node)
    end
end
function score(node::SampleNode, method::AbstractSamplingMethod)
    throw(ArgumentError("Method not implemented for `score` with type $(typeof(method))"))
end
function score(node::SampleNode, method::UCT)
    parent_node = AbstractTrees.parent(node)
    parent_node_score = isnothing(parent_node) ? 0.0 :
                        method.exploration * sqrt(log(parent_node.visits) / node.visits)
    s = node.wins / node.visits + parent_node_score
end
function select_best(node::SampleNode, method::AbstractSamplingMethod = UCT())
    best_val = -Inf
    best_node = nothing
    for n in AbstractTrees.PostOrderDFS(node)
        val = score(n, method)
        if val > best_val
            best_val = val
            best_node = n
        end
    end
    return best_node
end