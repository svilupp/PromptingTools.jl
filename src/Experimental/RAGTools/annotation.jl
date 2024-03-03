
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
    AnnotatedNode{T}  <: AbstractAnnotatedNode

A node to add annotations to the generated answer in `airag`

Annotations can be: sources, scores, whether its supported or not by the context, etc.

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
@kwdef mutable struct AnnotatedNode{T} <: AbstractAnnotatedNode
    group_id::Int = 0
    parent::Union{AnnotatedNode, Nothing} = nothing
    children::Vector{AnnotatedNode} = AnnotatedNode[]
    score::Union{Nothing, Float64} = nothing
    hits::Int = 0
    content::T = SubString{String}("")
    sources::Vector{Int} = Int[]
    style::Styler = Styler()
end
Base.IteratorEltype(::Type{<:TreeIterator{AbstractAnnotatedNode}}) = Base.HasEltype()
function Base.eltype(::Type{<:TreeIterator{T}}) where {T <: AbstractAnnotatedNode}
    T
end
function AbstractTrees.childtype(::Type{T}) where {T <: AbstractAnnotatedNode}
    T
end
function AbstractTrees.nodevalue(n::AbstractAnnotatedNode)
    !isempty(n.children) ? "Group: $(n.group_id)" :
    "$(n.content)($(isnothing(n.score) ? nothing : round(n.score;digits=2)))"
end

function AbstractTrees.children(node::AbstractAnnotatedNode)
    return node.children
end
AbstractTrees.parent(n::AbstractAnnotatedNode) = n.parent
## AbstractTrees.nodevalue(n::SampleNode) = n.data
function Base.show(io::IO, node::AbstractAnnotatedNode;
        annotater::Union{Nothing, AbstractAnnotater} = nothing)
    ## score_str = isnothing(scoring) ? "" : ", score: $(round(score(node, scoring),digits=2))"
    ## length_str = node.data isa AbstractVector ? ", length: $(length(node.data))" : ""
    print(io,
        "$(nameof(typeof(node)))(id: $(node.group_id), length: $(length(node.content)), score: $(node.score))")
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

#### TEXT UTILITIES
function tokenize(input::Union{String, SubString{String}})
    pattern = r"(\s+|=>|\(;|,|\.|\(|\)|\{|\}|\[|\]|;|:|\+|-|\*|/|<|>|=|&|\||!|@|#|\$|%|\^|~|`|\"|'|\w+)"
    SubString{String}[m.match for m in eachmatch(pattern, input)]
end

function trigrams(input_string::AbstractString)
    trigrams = SubString{String}[]
    # Ensure the input string length is at least 3 to form a trigram
    if length(input_string) >= 3
        for i in 1:(length(input_string) - 2)
            push!(trigrams, @views input_string[i:(i + 2)])
        end
    end
    return trigrams
end
function trigrams_hashed(input_string::AbstractString)
    trigrams = Set{UInt64}()
    # Ensure the input string length is at least 3 to form a trigram
    if length(input_string) >= 3
        for i in 1:(length(input_string) - 2)
            push!(trigrams, hash(@views input_string[i:(i + 2)]))
        end
    else
        push!(trigrams, hash(input_string))
    end
    return trigrams
end

"Add boundaries to the token to improve the matched context (ie, separate partial matches from exact match)"
function token_with_boundaries(
        prev_token::Union{Nothing, AbstractString}, curr_token::AbstractString,
        next_token::Union{Nothing, AbstractString})
    ##
    len1 = isnothing(prev_token) ? 0 : length(prev_token)
    len2 = length(curr_token)
    len3 = isnothing(next_token) ? 0 : length(next_token)

    ## concat only if single token boundaries!
    token = if len2 == 1
        curr_token
    elseif len1 == 1 && len3 == 1
        prev_token * curr_token * next_token
    elseif len1 == 0 && len3 == 1
        ## no prev_token, but next_token
        curr_token * next_token
    elseif len3 == 1
        curr_token * next_token
    elseif len1 == 1
        ## convert both len3=0 and len3>1
        prev_token * curr_token
    else
        curr_token
    end
end

function text_to_trigrams(input::Union{String, SubString{String}})
    tokens = tokenize(input)
    length_toks = length(tokens)
    trig = SubString{String}[]
    prev_token = nothing
    for i in eachindex(tokens)
        next_tok = i == length_toks ? nothing : tokens[i + 1]
        curr_tok = tokens[i]
        ## if too short, just add the token directly
        if length(curr_tok) == 1
            push!(trig, curr_tok)
        else
            full_tok = token_with_boundaries(prev_token, curr_tok, next_tok)
            append!(trig, trigrams(full_tok))
        end
        prev_token = curr_tok
    end
    return trig
end
function text_to_trigrams_hashed(input::AbstractString)
    tokens = tokenize(input)
    length_toks = length(tokens)
    trig = Set{UInt64}()
    prev_token = nothing
    for i in eachindex(tokens)
        next_tok = i == length_toks ? nothing : tokens[i + 1]
        curr_tok = tokens[i]
        ## if too short, just add the token directly
        if length(curr_tok) == 1
            push!(trig, hash(curr_tok))
        else
            full_tok = token_with_boundaries(prev_token, curr_tok, next_tok)
            union!(trig, trigrams_hashed(full_tok))
        end
        prev_token = curr_tok
    end
    return trig
end

function split_sentences(input::Union{String, SubString{String}})
    # Pattern to match code blocks in triple backticks, inline code in backticks, and sentences in normal text
    # This regex captures code blocks, inline code, and sentences, retaining their delimiters
    pattern = r"(\n|\t|```[\s\S]+?```|^\s*[*+-]\s+|^\s*\d+\.\s+|[^.!?]+[.!?]|[\s\S]+)"ms
    # TODO: single code line? `.+?`

    # Initialize an empty array to store the split sentences
    sentences = SubString{String}[]
    group_ids = Int[]

    # Process each match to handle code blocks and normal sentences differently
    for (i, m) in enumerate(eachmatch(pattern, input))
        sentence = m.match
        # Check if the match is a code block with triple backticks
        if startswith(sentence, "```") && endswith(sentence, "```")
            # Split code block by newline, retaining the backticks
            block_lines = split(sentence, "\n", keepempty = false)
            append!(sentences, block_lines)
            # all the lines of the chode block are the same group to have one source annotation
            append!(group_ids, fill(i, length(block_lines)))
        else
            # For inline code and normal sentences, add them directly to the sentences array
            push!(sentences, sentence)
            push!(group_ids, i)
        end
    end

    return sentences, group_ids
end

### ANNOTATION METHODS -- TrigramAnnotater

"""
    TrigramAnnotater

Annotation method where we score answer versus each context based on word-level trigrams that match.

It's very simple method (and it can loose some semantic meaning in longer sequences like negative), but it works reasonably well for both text and code.
"""
struct TrigramAnnotater <: AbstractAnnotater end

"""
    set_node_style!(annotater::TrigramAnnotater, node::AnnotatedNode; low_threshold::Float64=0.5, high_threshold::Float64=1.0,
    high_styler::Styler=Styler(color=:green, bold=false), low_styler::Styler=Styler(color=:red, bold=false), bold_multihits::Bool=true)

Sets style of `node` based on the provided rules
"""
function set_node_style!(annotater::TrigramAnnotater, node::AnnotatedNode;
        low_threshold::Float64 = 0.0, medium_threshold::Float64 = 0.5, high_threshold::Float64 = 1.0,
        low_styler::Styler = Styler(color = :magenta, bold = false),
        medium_styler::Styler = Styler(color = :yellow, bold = false),
        high_styler::Styler = Styler(color = :green, bold = false),
        bold_multihits::Bool = true)
    node.style = if isnothing(node.score)
        ## skip for now
        Styler()
    elseif node.score >= high_threshold
        high_styler
    elseif node.score >= medium_threshold
        medium_styler
    elseif node.score >= low_threshold
        low_styler
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
        context_trigrams::AbstractVector; min_score::Float64 = 0.5,
        styler_kwargs...)
    method = TrigramAnnotater()
    context_scores = zeros(Float64, length(context_trigrams))
    ## Iterate max-sim over all the tokens (find match via trigrams)
    tokens = tokenize(parent_node.content)
    length_toks = length(tokens)
    prev_token = nothing
    for i in eachindex(tokens)
        next_tok = i == length_toks ? nothing : tokens[i + 1]
        curr_tok = tokens[i]
        node = AnnotatedNode(; content = curr_tok, parent_node.group_id,
            score = nothing, sources = Int[], parent = parent_node)
        push!(parent_node.children, node)
        ## find the highest scoring source based on trigrams
        for si in eachindex(context_trigrams)
            ## if too short, skip scoring
            length(curr_tok) == 1 && continue
            ## load trigrams in the context source
            src = context_trigrams[si]
            ## Score the trigram
            full_tok = token_with_boundaries(prev_token, curr_tok, next_tok)
            trig = trigrams(full_tok)
            ## count portion of trigrams that match
            score = count(in(src), trig) / length(trig)
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
    max_score = context_scores[idx]
    if max_score >= min_score ## unnecessary, it's a sum of scores, so it will be over 0
        parent_node.score = max_score / length_toks # avg score
        parent_node.sources = [idx]
    end

    return parent_node
end

function add_node_metadata!(annotater::TrigramAnnotater,
        root::AnnotatedNode; add_sources::Bool = true, add_scores::Bool = true,
        sources::Union{Nothing, AbstractVector{<:AbstractString}} = nothing)
    # Ensure there are children to process
    if isempty(root.children)
        return
    end

    # Placeholder for new children array with metadata nodes
    new_children = AnnotatedNode[]
    current_group_id = root.children[1].group_id
    best_source = root.children[1].sources[1]
    best_score = isnothing(root.children[1].score) ? 0 :
                 root.children[1].score * length(root.children[1].content)
    for child in root.children
        # Check if group_id has changed or it's the last child
        if child.group_id != current_group_id
            # Add a metadata node for the previous group
            metadata_content = add_scores ?
                               "[$best_source,$(round(best_score, digits=2))]" :
                               "[$best_source]"
            push!(new_children, AnnotatedNode(content = metadata_content))
            # Reset tracking variables
            current_group_id = child.group_id
            best_source = child.sources[1]
            best_score = isnothing(child.score) ? 0 : child.score * length(child.content)
        else
            # Update best source based on score * content length
            current_score = isnothing(child.score) ? 0 : child.score * length(child.content)
            if current_score > best_score
                best_source = child.sources[1]
                best_score = current_score
            end
        end
        push!(new_children, child)
    end
    # Add metadata for the last group if necessary
    if add_sources
        metadata_content = add_scores ? "[$best_source,$(round(best_score, digits=2))]" :
                           "[$best_source]"
        push!(new_children, AnnotatedNode(content = metadata_content))
    end

    # Replace old children with new ones including metadata nodes
    root.children = new_children

    # TODO: Add the actual sources at the end if provided

    return root
end

"Annotates the `answer` with the `context` and returns the annotated tree of nodes representing the `answer`"
function annotate_support(annotater::TrigramAnnotater, answer::AbstractString,
        context::AbstractVector; min_score::Float64 = 0.5, add_sources::Bool = true,
        add_scores::Bool = true, kwargs...)
    # TODO: add RAG sources - inline and at the end of the context
    sentences, group_ids = split_sentences(answer)
    context_trigrams = text_to_trigrams.(context)
    root = AnnotatedNode()
    for i in eachindex(sentences, group_ids)
        node = AnnotatedNode(;
            content = sentences[i], group_id = group_ids[i], parent = root)
        push!(root.children, node)
        trigram_support!(node, context_trigrams; min_score, kwargs...)
    end
    ## add_sources/scores if requested
    ## add_node_metadata!(annotater, root; add_sources, add_scores)
    return root
end
