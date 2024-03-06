
# # Interface

function annotate_support(
        annotater::AbstractAnnotater, answer::AbstractString, context::AbstractVector)
    throw(ArgumentError("Not implemented for type $(typeof(annotater))"))
end

# Passthrough by default
function set_node_style!(
        annotater::AbstractAnnotater, node::AbstractAnnotatedNode; kwargs...)
    node
end

# Passthrough by default
function align_node_styles!(
        annotater::AbstractAnnotater, nodes::AbstractVector{<:AbstractAnnotatedNode}; kwargs...)
    node
end

# Passthrough by default
function add_node_metadata!(annotater::AbstractAnnotater,
        root::AbstractAnnotatedNode; kwargs...)
    node
end

"""
    Styler

Defines styling keywords for `printstyled` for each `AbstractAnnotatedNode`
"""
@kwdef mutable struct Styler <: AbstractAnnotationStyler
    color::Symbol = :nothing
    bold::Bool = false
    underline::Bool = false
    italic::Bool = false
end

"""
    HTMLStyler

Defines styling via classes (attribute `class`) and styles (attribute `style`) for HTML formatting of `AbstractAnnotatedNode`
"""
@kwdef mutable struct HTMLStyler <: AbstractAnnotationStyler
    classes::AbstractString
    styles::AbstractString
end
Base.var"=="(a::AbstractAnnotationStyler, b::AbstractAnnotationStyler) = false
function Base.var"=="(a::T, b::T) where {T <: AbstractAnnotationStyler}
    all(x -> getfield(a, x) == getfield(b, x), fieldnames(Styler))
end

"""
    AnnotatedNode{T}  <: AbstractAnnotatedNode

A node to add annotations to the generated answer in `airag`

Annotations can be: sources, scores, whether its supported or not by the context, etc.

# Fields
- `group_id::Int`: Unique identifier for the same group of nodes (eg, different lines of the same code block)
- `parent::Union{AnnotatedNode, Nothing}`: Parent node that current node was built on
- `children::Vector{AnnotatedNode}`: Children nodes
- `score::
"""
@kwdef mutable struct AnnotatedNode{T} <: AbstractAnnotatedNode
    group_id::Int = 0
    parent::Union{AnnotatedNode, Nothing} = nothing
    children::Vector{AnnotatedNode} = AnnotatedNode[]
    score::Union{Nothing, Float64} = nothing
    hits::Int = 0
    content::T = SubString{String}("")
    sources::Vector{Int} = Int[]
    style::AbstractAnnotationStyler = Styler()
end
Base.IteratorEltype(::Type{<:TreeIterator{AbstractAnnotatedNode}}) = Base.HasEltype()
function Base.eltype(::Type{<:TreeIterator{T}}) where {T <: AbstractAnnotatedNode}
    T
end
function AbstractTrees.childtype(::Type{T}) where {T <: AbstractAnnotatedNode}
    T
end
function AbstractTrees.nodevalue(n::AbstractAnnotatedNode)
    !isempty(n.children) ?
    "Group: $(n.group_id)($(isnothing(n.score) ? nothing : round(n.score;digits=2)))" :
    "$(n.content)($(isnothing(n.score) ? nothing : round(n.score;digits=2)))"
end

function AbstractTrees.children(node::AbstractAnnotatedNode)
    return node.children
end
AbstractTrees.parent(n::AbstractAnnotatedNode) = n.parent
## AbstractTrees.nodevalue(n::SampleNode) = n.data
function Base.show(io::IO, node::AbstractAnnotatedNode;
        annotater::Union{Nothing, AbstractAnnotater} = nothing)
    print(io,
        "$(nameof(typeof(node)))(group id: $(node.group_id), length: $(length(node.content)), score: $(node.score))")
end

"""
    pprint(io::IO, node::AbstractAnnotatedNode)

Pretty print the `node` to the `io` stream, including all its children
"""
function PromptingTools.pprint(io::IO, node::AbstractAnnotatedNode)
    for node in AbstractTrees.PreOrderDFS(node)
        ## print out text only for leaf nodes (ie, with no children)
        if isempty(node.children)
            printstyled(io, node.content; node.style.bold, node.style.color,
                node.style.underline, node.style.italic)
        end
    end
    return nothing
end

PromptingTools.pprint(node::AbstractAnnotatedNode) = pprint(stdout, node)

### ANNOTATION METHODS -- TrigramAnnotater

"""
    TrigramAnnotater

Annotation method where we score answer versus each context based on word-level trigrams that match.

It's very simple method (and it can loose some semantic meaning in longer sequences like negative), but it works reasonably well for both text and code.
"""
struct TrigramAnnotater <: AbstractAnnotater end

"""
    set_node_style!(::TrigramAnnotater, node::AnnotatedNode;
        low_threshold::Float64 = 0.0, medium_threshold::Float64 = 0.5, high_threshold::Float64 = 1.0,
        low_styler::Styler = Styler(color = :magenta, bold = false),
        medium_styler::Styler = Styler(color = :blue, bold = false),
        high_styler::Styler = Styler(color = :green, bold = false),
        bold_multihits::Bool = false)

Sets style of `node` based on the provided rules
"""
function set_node_style!(::TrigramAnnotater, node::AnnotatedNode;
        low_threshold::Float64 = 0.0, medium_threshold::Float64 = 0.5, high_threshold::Float64 = 1.0,
        low_styler::Styler = Styler(color = :magenta, bold = false),
        medium_styler::Styler = Styler(color = :blue, bold = false),
        high_styler::Styler = Styler(color = :green, bold = false),
        bold_multihits::Bool = false)
    node.style = if isnothing(node.score)
        ## skip for now
        Styler()
    elseif node.score >= high_threshold
        high_styler
    elseif node.score >= medium_threshold
        medium_styler
    elseif node.score >= low_threshold
        low_styler
    else
        Styler()
    end
    if node.hits > 1 && bold_multihits
        node.style.bold = true
    end
    return node
end

"""
    align_node_styles!(annotater::TrigramAnnotater, nodes::AbstractVector{<:AnnotatedNode}; kwargs...)

Aligns the styles of the nodes based on the surrounding nodes ("fill-in-the-middle"). 

If the node has no score, but the surrounding nodes have the same style, the node will inherit the style of the surrounding nodes.
"""
function align_node_styles!(
        annotater::TrigramAnnotater, nodes::AbstractVector{<:AnnotatedNode}; kwargs...)
    children_length = length(nodes)
    for ci in eachindex(nodes)
        if ci == 1 || ci == children_length
            continue
        else
            prev, child, next = nodes[ci - 1], nodes[ci], nodes[ci + 1]
            ## missing style and surrounding styles are the same
            if isnothing(child.score) && prev.style == next.style
                child.style = prev.style
            end
        end
    end
    return nodes
end

"Find if the `parent_node.content` is supported by the provided `context_trigrams`"
function trigram_support!(parent_node::AnnotatedNode,
        context_trigrams::AbstractVector, trigram_func::F = trigrams;
        skip_trigrams::Bool = false, min_score::Float64 = 0.5,
        min_source_score::Float64 = 0.25,
        stop_words::AbstractVector{<:String} = STOPWORDS,
        styler_kwargs...) where {F <: Function}
    method = TrigramAnnotater()
    context_scores = zeros(Float64, length(context_trigrams))
    ## Iterate max-sim over all the tokens (find match via trigrams)
    tokens = tokenize(parent_node.content)
    length_toks = length(tokens)
    cnt_scored_toks = 0 # number of tokens scored
    prev_token = nothing
    for i in eachindex(tokens)
        next_tok = i == length_toks ? nothing : tokens[i + 1]
        curr_tok = tokens[i]
        node = AnnotatedNode(; content = curr_tok, parent_node.group_id,
            score = nothing, sources = Int[], parent = parent_node)
        push!(parent_node.children, node)
        ## if too short, skip scoring
        length(curr_tok) == 1 && continue
        ## if a stop word, skip scoring
        (curr_tok in stop_words) && continue
        cnt_scored_toks += 1
        ## find the highest scoring source based on trigrams
        for si in eachindex(context_trigrams)
            ## load trigrams in the context source
            src = context_trigrams[si]
            ## Score the match of the word itself if found
            direct_match = skip_trigrams ? in(curr_tok, src) : false
            if !direct_match
                ## Score the trigram if direct match failed
                full_tok = token_with_boundaries(prev_token, curr_tok, next_tok)
                trig = trigrams(full_tok; add_word = curr_tok)
                ## count portion of trigrams that match
                score = count(in(src), trig) / length(trig)
            else
                score = 1.0
            end
            # Add up cumulative score for each separate context
            context_scores[si] += score
            # if 1.0, increment hits
            if score == 1
                node.hits += 1
            end
            # log the highest score and sources, always log if exact match
            if isnothing(node.score) || score > node.score || score == 1
                node.score = score
            end
            if score >= min_score
                push!(node.sources, si)
            end
        end
        ## Set styles
        set_node_style!(method, node; styler_kwargs...)

        ## Next iteration
        prev_token = curr_tok
    end
    ## Fill-in-middle Styler, based on the previous token and next token
    align_node_styles!(method, parent_node.children)

    ## Evaluate best source
    idx = argmax(context_scores)
    # avg score = max_score / tokens
    parent_node.score = (cnt_scored_toks) > 0 ? context_scores[idx] / cnt_scored_toks : 0.0
    if parent_node.score >= min_source_score
        parent_node.sources = [idx]
    end

    return parent_node
end

function add_node_metadata!(annotater::TrigramAnnotater,
        root::AnnotatedNode; add_sources::Bool = true, add_scores::Bool = true,
        sources::Union{Nothing, AbstractVector{<:AbstractString}} = nothing)
    # Ensure there are children to process
    children = AbstractTrees.children(root)
    if isempty(children)
        return root
    end
    # We track cumulative score (score*length) and length
    i = 1
    source_scores = Dict{Int, Float64}()
    source_lengths = Dict{Int, Int}()
    previous_group_id = children[1].group_id
    while i <= length(children)
        child = children[i]
        # Check if group_id has changed or it's the last child to record source
        if (child.group_id != previous_group_id) && !isempty(source_scores)
            # Add a metadata node for the previous group
            src, score_sum = maximum(source_scores)
            score = score_sum / source_lengths[src] # average score, length weighted
            metadata_content = string("[",
                add_sources ? src : "",
                add_sources ? "," : "",
                add_scores ? round(score, digits = 2) : "",
                "]")
            ## Check if there is any content, then add it
            if length(metadata_content) > 2
                src_node = AnnotatedNode(; parent = root, group_id = previous_group_id,
                    content = metadata_content)
                insert!(children, i, src_node)
            end
            # Reset tracking variables
            previous_group_id = child.group_id
            empty!(source_scores)
            empty!(source_lengths)
            # increment i, since we added item
            i += 1
        end

        # Update tracking
        if !isnothing(child.score) && !isempty(child.sources)
            src = only(child.sources)
            len = length(child.content)
            source_scores[src] = get(source_scores, src, 0) + child.score * len
            source_lengths[src] = get(source_lengths, src, 0) + len
        end
        # Next round
        i += 1
    end
    ## Run for the last item
    if !isempty(source_scores)
        # Add a metadata node for the previous group
        src, score_sum = maximum(source_scores)
        score = score_sum / source_lengths[src] # average score, length weighted
        metadata_content = string("[",
            add_sources ? src : "",
            add_sources ? "," : "",
            add_scores ? round(score, digits = 2) : "",
            "]")
        ## Check if there is any content, then add it
        if length(metadata_content) > 2
            src_node = AnnotatedNode(; parent = root, group_id = previous_group_id,
                content = metadata_content)
            insert!(children, i, src_node)
        end
    end

    ## Simply enumerate the sources at the end
    if !isnothing(sources)
        metadata_content = "\n\n**Sources:**\n" *
                           join(["$(i). $(src)" for (i, src) in enumerate(sources)], "\n")
        src_node = AnnotatedNode(; parent = root, group_id = previous_group_id + 1,
            content = metadata_content)
        push!(children, src_node)
    end

    return root
end

"Annotates the `answer` with the `context` and returns the annotated tree of nodes representing the `answer`"
function annotate_support(annotater::TrigramAnnotater, answer::AbstractString,
        context::AbstractVector; min_score::Float64 = 0.5,
        skip_trigrams::Bool = true, hashed::Bool = false,
        min_source_score::Float64 = 0.25,
        add_sources::Bool = true,
        add_scores::Bool = true, kwargs...)
    # TODO: add RAG sources - inline and at the end of the context
    ## use hashed trigrams?
    if hashed
        trigram_func = trigrams_hashed
        text_to_trigram_func = text_to_trigrams_hashed
    else
        trigram_func = trigrams
        text_to_trigram_func = text_to_trigrams
    end
    sentences, group_ids = split_into_code_and_sentences(answer)
    context_trigrams = text_to_trigram_func.(context)
    root = AnnotatedNode()
    for i in eachindex(sentences, group_ids)
        node = AnnotatedNode(;
            content = sentences[i], group_id = group_ids[i], parent = root)
        push!(root.children, node)
        trigram_support!(
            node, context_trigrams, trigram_func; skip_trigrams,
            min_score, min_source_score, kwargs...)
    end
    ## add_sources/scores if requested
    if add_sources || add_scores
        add_node_metadata!(annotater, root; add_sources, add_scores)
    end
    return root
end