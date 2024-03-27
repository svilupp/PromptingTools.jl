
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
    nodes
end

# Passthrough by default
function add_node_metadata!(annotater::AbstractAnnotater,
        root::AbstractAnnotatedNode; kwargs...)
    root
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
    classes::AbstractString = ""
    styles::AbstractString = ""
end
Base.var"=="(a::AbstractAnnotationStyler, b::AbstractAnnotationStyler) = false
function Base.var"=="(a::T, b::T) where {T <: AbstractAnnotationStyler}
    all(x -> getfield(a, x) == getfield(b, x), fieldnames(T))
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
    score_str = isnothing(node.score) ? "-" : round(node.score; digits = 2)
    print(io,
        "$(nameof(typeof(node)))(group id: $(node.group_id), length: $(length(node.content)), score: $(score_str)")
end

"""
    PromptingTools.pprint(
        io::IO, node::AbstractAnnotatedNode; text_width::Int = displaysize(io)[2])

Pretty print the `node` to the `io` stream, including all its children

Supports only `node.style::Styler` for now.
"""
function PromptingTools.pprint(
        io::IO, node::AbstractAnnotatedNode; text_width::Int = displaysize(io)[2])
    for node in AbstractTrees.PreOrderDFS(node)
        ## print out text only for leaf nodes (ie, with no children)
        if isempty(node.children) && node.style isa Styler
            @static if VERSION ≥ v"1.10"
                printstyled(io, node.content; node.style.bold, node.style.color,
                    node.style.underline, node.style.italic)
            else
                ## Implies VERSION ≥ v"1.9" (not supported below)
                ## Remove italic keyword
                printstyled(io, node.content; node.style.bold, node.style.color,
                    node.style.underline)
            end
        elseif isempty(node.children)
            ## print without styling, we support only Styler for now
            print(io, node.content)
        end
    end
    return nothing
end

function PromptingTools.pprint(
        node::AbstractAnnotatedNode; text_width::Int = displaysize(stdout)[2])
    pprint(stdout, node; text_width)
end

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
        default_styler::AbstractAnnotationStyler = Styler(),
        low_styler::AbstractAnnotationStyler = Styler(color = :magenta, bold = false),
        medium_styler::AbstractAnnotationStyler = Styler(color = :blue, bold = false),
        high_styler::AbstractAnnotationStyler = Styler(color = :nothing, bold = false),
        bold_multihits::Bool = false)

Sets style of `node` based on the provided rules
"""
function set_node_style!(::TrigramAnnotater, node::AnnotatedNode;
        low_threshold::Float64 = 0.0, medium_threshold::Float64 = 0.5, high_threshold::Float64 = 1.0,
        default_styler::AbstractAnnotationStyler = Styler(),
        low_styler::AbstractAnnotationStyler = Styler(color = :magenta, bold = false),
        medium_styler::AbstractAnnotationStyler = Styler(color = :blue, bold = false),
        high_styler::AbstractAnnotationStyler = Styler(color = :nothing, bold = false),
        bold_multihits::Bool = false)
    node.style = if isnothing(node.score)
        ## skip for now
        default_styler
    elseif node.score >= high_threshold
        high_styler
    elseif node.score >= medium_threshold
        medium_styler
    elseif node.score >= low_threshold
        low_styler
    else
        default_styler
    end
    if node.hits > 1 && bold_multihits
        if hasproperty(node.style, :bold)
            node.style.bold = true
        else
            @warn "Cannot boldify the node, as it doesn't support bold (styler: $(typeof(node.style)))"
        end
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

"""
    trigram_support!(parent_node::AnnotatedNode,
        context_trigrams::AbstractVector, trigram_func::F1 = trigrams, token_transform::F2 = identity;
        skip_trigrams::Bool = false, min_score::Float64 = 0.5,
        min_source_score::Float64 = 0.25,
        stop_words::AbstractVector{<:String} = STOPWORDS,
        styler_kwargs...) where {F1 <: Function, F2 <: Function}

Find if the `parent_node.content` is supported by the provided `context_trigrams`.

Logic:
- Split the `parent_node.content` into tokens
- Create an `AnnotatedNode` for each token
- If `skip_trigrams` is enabled, it looks for an exact match in the `context_trigrams`
- If no exact match found, it counts trigram-based match (include the surrounding tokens for better contextual awareness) as a score
- Then it sets the style of the node based on the score
- Lastly, it aligns the styles of neighboring nodes with `score==nothing` (eg, single character tokens)
- Then, it rolls up the scores and sources to the parent node

For diagnostics, you can use `AbstractTrees.print_tree(parent_node)` to see the tree structure of each token and its score.

# Example
```julia
context_trigrams = text_to_trigrams.(["This IS a test.", "Another test.",
    "More content here."])

node = AnnotatedNode(content = "xyz") 
trigram_support!(node, context_trigrams) # updates node.children!
``
`"""
function trigram_support!(parent_node::AnnotatedNode,
        context_trigrams::AbstractVector, trigram_func::F1 = trigrams, token_transform::F2 = identity;
        skip_trigrams::Bool = false, min_score::Float64 = 0.5,
        min_source_score::Float64 = 0.25,
        stop_words::AbstractVector{<:String} = STOPWORDS,
        styler_kwargs...) where {F1 <: Function, F2 <: Function}
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
            ## Score the match of the word itself if found; if we use hashed trigrams, we must hash the word
            direct_match = skip_trigrams ? in(token_transform(curr_tok), src) : false
            if !direct_match
                ## Score the trigram if direct match failed
                full_tok = token_with_boundaries(prev_token, curr_tok, next_tok)
                trig = trigram_func(full_tok; add_word = curr_tok)
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

"""
    add_node_metadata!(annotater::TrigramAnnotater,
        root::AnnotatedNode; add_sources::Bool = true, add_scores::Bool = true,
        sources::Union{Nothing, AbstractVector{<:AbstractString}} = nothing)

Adds metadata to the children of `root`. Metadata includes sources and scores, if requested.

Optionally, it can add a list of `sources` at the end of the printed text.

The metadata is added by inserting new nodes in the `root` children list (with no children of its own to be printed out).
"""
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
    non_source_length = 0
    previous_group_id = children[1].group_id
    while i <= length(children)
        child = children[i]
        # Check if group_id has changed or it's the last child to record source
        if (child.group_id != previous_group_id) && !isempty(source_scores)
            # Add a metadata node for the previous group
            score_sum, src = findmax(source_scores)
            # average score weighted by the length of ALL text
            # the goal is to show the match of top source across all text, not just the tokens that matched - it could be misleading
            # the goal is "how confident are we that this source is the best match for the whole text"
            score = score_sum / (sum(values(source_lengths)) + non_source_length)
            metadata_content = string("[",
                add_sources ? src : "",
                add_sources ? "," : "",
                add_scores ? round(score, digits = 2) : "",
                "]")
            ## Check if there is any content, then add it
            if length(metadata_content) > 3
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
        elseif !isnothing(child.score)
            ## track the low match tokens without any source allocated
            non_source_length += length(child.content)
        end

        # Next round
        i += 1
    end
    ## Run for the last item
    if !isempty(source_scores)
        # Add a metadata node for the previous group
        score_sum, src = findmax(source_scores)
        score = score_sum / (sum(values(source_lengths)) + non_source_length)
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
        metadata_content = string("\n\n", "-"^20, "\n", "SOURCES", "\n", "-"^20, "\n") *
                           join(["$(i). $(src)" for (i, src) in enumerate(sources)], "\n")
        src_node = AnnotatedNode(; parent = root, group_id = previous_group_id + 1,
            content = metadata_content)
        push!(children, src_node)
    end

    return root
end

"""
    annotate_support(annotater::TrigramAnnotater, answer::AbstractString,
        context::AbstractVector; min_score::Float64 = 0.5,
        skip_trigrams::Bool = true, hashed::Bool = true,
        sources::Union{Nothing, AbstractVector{<:AbstractString}} = nothing,
        min_source_score::Float64 = 0.25,
        add_sources::Bool = true,
        add_scores::Bool = true, kwargs...)

Annotates the `answer` with the overlap/what's supported in `context` and returns the annotated tree of nodes representing the `answer`

Returns a "root" node with children nodes representing the sentences/code blocks in the `answer`. Only the "leaf" nodes are to be printed (to avoid duplication), "leaf" nodes are those with NO children.

Default logic: 
- Split into sentences/code blocks, then into tokens (~words).
- Then match each token (~word) exactly.
- If no exact match found, count trigram-based match (include the surrounding tokens for better contextual awareness).
- If the match is higher than `min_score`, it's recorded in the `score` of the node.

# Arguments
- `annotater::TrigramAnnotater`: Annotater to use
- `answer::AbstractString`: Text to annotate
- `context::AbstractVector`: Context to annotate against, ie, look for "support" in the texts in `context`
- `min_score::Float64`: Minimum score to consider a match. Default: 0.5, which means that half of the trigrams of each word should match
- `skip_trigrams::Bool`: Whether to potentially skip trigram matching if exact full match is found. Default: true
- `hashed::Bool`: Whether to use hashed trigrams. It's harder to debug, but it's much faster for larger texts (hashed text are held in a Set to deduplicate). Default: true
- `sources::Union{Nothing, AbstractVector{<:AbstractString}}`: Sources to add at the end of the context. Default: nothing
- `min_source_score::Float64`: Minimum score to consider/to display a source. Default: 0.25, which means that at least a quarter of the trigrams of each word should match to some context.
  The threshold is lower than `min_score`, because it's average across ALL words in a block, so it's much harder to match fully with generated text.
- `add_sources::Bool`: Whether to add sources at the end of each code block/sentence. Sources are addded in the square brackets like "[1]". Default: true
- `add_scores::Bool`: Whether to add source-matching scores at the end of each code block/sentence. Scores are added in the square brackets like "[0.75]". Default: true
- kwargs: Additional keyword arguments to pass to `trigram_support!` and `set_node_style!`. See their documentation for more details (eg, customize the colors of the nodes based on the score)

# Example
```julia
annotater = TrigramAnnotater()
context = [
    "This is a test context.", "Another context sentence.", "Final piece of context."]
answer = "This is a test context. Another context sentence."

annotated_root = annotate_support(annotater, answer, context)
pprint(annotated_root) # pretty print the annotated tree
```
"""
function annotate_support(annotater::TrigramAnnotater, answer::AbstractString,
        context::AbstractVector; min_score::Float64 = 0.5,
        skip_trigrams::Bool = true, hashed::Bool = true,
        sources::Union{Nothing, AbstractVector{<:AbstractString}} = nothing,
        min_source_score::Float64 = 0.25,
        add_sources::Bool = true,
        add_scores::Bool = true, kwargs...)
    @assert !isempty(context) "Context cannot be empty"
    ## use hashed trigrams by default (more efficient for larger sequences)
    if hashed
        trigram_func = trigrams_hashed
        word_transform = hash
        text_to_trigram_func = text_to_trigrams_hashed
    else
        trigram_func = trigrams
        word_transform = identity
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
            node, context_trigrams, trigram_func, word_transform; skip_trigrams,
            min_score, min_source_score, kwargs...)
    end
    ## add_sources/scores if requested
    if add_sources || add_scores
        add_node_metadata!(annotater, root; add_sources, add_scores, sources)
    end
    ## Roll up children scores, weighted by length
    score_sum = 0
    score_lengths = 0
    for child in AbstractTrees.children(root)
        if !isnothing(child.score)
            len_ = length(child.content)
            score_sum += child.score * len_
            score_lengths += len_
        end
    end
    root.score = score_lengths > 0 ? score_sum / score_lengths : 0.0

    return root
end

# Dispatch for RAGResult
"""
    annotate_support(
        annotater::TrigramAnnotater, result::AbstractRAGResult; min_score::Float64 = 0.5,
        skip_trigrams::Bool = true, hashed::Bool = true,
        min_source_score::Float64 = 0.25,
        add_sources::Bool = true,
        add_scores::Bool = true, kwargs...)

Dispatch for `annotate_support` for `AbstractRAGResult` type. It extracts the `final_answer` and `context` from the `result` and calls `annotate_support` with them.

See `annotate_support` for more details.

# Example
```julia
res = RAGResult(; question = "", final_answer = "This is a test.",
    context = ["Test context.", "Completely different"])
annotated_root = annotate_support(annotater, res)
PT.pprint(annotated_root)
```
"""
function annotate_support(
        annotater::TrigramAnnotater, result::AbstractRAGResult; min_score::Float64 = 0.5,
        skip_trigrams::Bool = true, hashed::Bool = true,
        min_source_score::Float64 = 0.25,
        add_sources::Bool = true,
        add_scores::Bool = true, kwargs...)
    final_answer = isnothing(result.final_answer) ? result.answer : result.final_answer
    return annotate_support(
        annotater, final_answer, result.context; min_score, skip_trigrams,
        hashed, result.sources, min_source_score, add_sources, add_scores, kwargs...)
end

"""
    print_html([io::IO,] parent_node::AbstractAnnotatedNode)

    print_html([io::IO,] rag::AbstractRAGResult; add_sources::Bool = false,
        add_scores::Bool = false, default_styler = HTMLStyler(),
        low_styler = HTMLStyler(styles = "color:magenta", classes = ""),
        medium_styler = HTMLStyler(styles = "color:blue", classes = ""),
        high_styler = HTMLStyler(styles = "", classes = ""), styler_kwargs...)

Pretty-prints the annotation `parent_node` (or `RAGResult`) to the `io` stream (or returns the string) in HTML format (assumes node is styled with styler `HTMLStyler`).

It wraps each "token" into a span with requested styling (HTMLStyler's properties `classes` and `styles`).
It also replaces new lines with `<br>` for better HTML formatting.

For any non-HTML styler, it prints the content as plain text.

# Returns 
- `nothing` if `io` is provided
- or the string with HTML-formatted text (if `io` is not provided, we print the result out)

See also `HTMLStyler`, `annotate_support`, and `set_node_style!` for how the styling is applied and what the arguments mean.

# Examples
Note: `RT` is an alias for `PromptingTools.Experimental.RAGTools`

Simple start directly with the `RAGResult`:
```julia
# set up the text/RAGResult
context = [
    "This is a test context.", "Another context sentence.", "Final piece of context."]
answer = "This is a test answer. It has multiple sentences."
rag = RT.RAGResult(; context, final_answer=answer, question="")

# print the HTML
print_html(rag)
```

Low-level control by creating our `AnnotatedNode`:
```julia
# prepare your HTML styling
styler_kwargs = (;
    default_styler=RT.HTMLStyler(),
    low_styler=RT.HTMLStyler(styles="color:magenta", classes=""),
    medium_styler=RT.HTMLStyler(styles="color:blue", classes=""),
    high_styler=RT.HTMLStyler(styles="", classes=""))

# annotate the text
context = [
    "This is a test context.", "Another context sentence.", "Final piece of context."]
answer = "This is a test answer. It has multiple sentences."

parent_node = RT.annotate_support(
    RT.TrigramAnnotater(), answer, context; add_sources=false, add_scores=false, styler_kwargs...)

# print the HTML
print_html(parent_node)

# or to accumulate more nodes
io = IOBuffer()
print_html(io, parent_node)
```
"""
function print_html(io::IO, parent_node::AbstractAnnotatedNode)
    print(io, "<div>")
    for node in PreOrderDFS(parent_node)
        ## print out text only for leaf nodes (ie, with no children)
        if isempty(node.children)
            # create HTML style new lines
            content = replace(node.content, "\n" => "<br>")
            if node.style isa HTMLStyler
                # HTML styler -> wrap each token into a span with requested styling
                style_str = isempty(node.style.styles) ? "" :
                            " style=\"$(node.style.styles)\""
                class_str = isempty(node.style.classes) ? "" :
                            " class=\"$(node.style.classes)\""
                if isempty(class_str) && isempty(style_str)
                    print(io, content)
                else
                    print(io,
                        "<span", style_str, class_str, ">$(content)</span>")
                end
            else
                # print plain text
                print(io, content)
            end
        end
    end
    print(io, "</div>")
    return nothing
end

# utility for RAGResult
function print_html(io::IO, rag::AbstractRAGResult; add_sources::Bool = false,
        add_scores::Bool = false, default_styler = HTMLStyler(),
        low_styler = HTMLStyler(styles = "color:magenta", classes = ""),
        medium_styler = HTMLStyler(styles = "color:blue", classes = ""),
        high_styler = HTMLStyler(styles = "", classes = ""), styler_kwargs...)

    # Create the annotation
    parent_node = annotate_support(
        TrigramAnnotater(), rag; add_sources, add_scores, default_styler,
        low_styler, medium_styler, high_styler, styler_kwargs...)

    # Print the HTML
    print_html(io, parent_node)
end

# Non-io dispatch
function print_html(
        rag_or_parent_node::Union{AbstractAnnotatedNode, AbstractRAGResult}; kwargs...)
    io = IOBuffer()
    print_html(io, rag_or_parent_node; kwargs...)
    String(take!(io))
end