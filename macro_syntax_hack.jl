# The below script is inspired by the SGLang syntax.
#
# It mocks the functions and objects from PromptingTools.jl
# It takes `gen()` in the code and rewrites into `MockGenerate()|>run!` expression.
# Integration into PT would be simply to replace the MockGenerate with AIGenerate and add the getproperty overload for lazy AICall structs.
#
#
### Example:
# @sgl.function
# def tip_suggestion(s):
#     s += (
#         "Here are two tips for staying healthy: "
#         "1. Balanced Diet. 2. Regular Exercise.\n\n"
#     )
#
#     forks = s.fork(2)
#     for i, f in enumerate(forks):
#         f += f"Now, expand tip {i+1} into a paragraph:\n"
#         f += sgl.gen(f"detailed_tip", max_tokens=256, stop="\n\n")
#
#     s += "Tip 1:" + forks[0]["detailed_tip"] + "\n"
#     s += "Tip 2:" + forks[1]["detailed_tip"] + "\n"
#     s += "In summary" + sgl.gen("summary")

using MacroTools

@kwdef mutable struct MockGenerate
    variable::Symbol
    prompt::String = "{{$variable}}"
    args::Any
    kwargs::Any
    output::Union{Nothing, String} = nothing
end
function MockGenerate(variable::Symbol, args...; kwargs...)
    return MockGenerate(; variable, args, kwargs)
end
function Base.var"*"(s::AbstractString, m::MockGenerate)
    m.prompt = s * " " * m.prompt
    return m
end
function Base.var"*"(m::MockGenerate, s::AbstractString)
    m.prompt = m.prompt * " " * s
    return m
end
function Base.var"*"(m1::MockGenerate, m2::MockGenerate)
    if !isnothing(m1.output)
        m1 |> run!
    end
    m2.prompt = render(m) * " " * m2.prompt
    return m2
end
function Base.getindex(m::MockGenerate, s::Symbol)
    if s == m.variable
        return m.output
    else
        return getproperty(m, s)
    end
end
function render(m::MockGenerate)
    return replace(m.prompt, "{{$(m.variable)}}" => m.output)
end

m = MockGenerate(:my_stuff)
"hello you" * m
m * "What?"
m.prompt

m2 = MockGenerate(:summary)
m * "In summary:" * m2

function mockgenerate(prompt)
    # Placeholder for AI model integration
    @info "Generating text from prompt: $prompt"
    return "This is a generated text."
end
function run!(m::MockGenerate)
    prompt = split(m.prompt, "{{$(m.variable)}}")[begin] |> strip
    m.output = mockgenerate(prompt)
    return m
end
run!(m) # run the generation
m.output # output of generation
m[:my_stuff] # get only the output of generation
render(m)
# hello you This is a generated text. hello you

macro aimodel(func)
    # Decompose the function into its AST
    func_ast = MacroTools.splitdef(func)

    # Process the body of the function
    func_ast[:body] = process_body(func_ast[:body])

    # Recompose the function from the modified AST
    return MacroTools.combinedef(func_ast)
end

# Helper function to process the body of the function
function process_body(body)
    return process_expr(body)
end

# Recursive function to process expressions in the function body
function process_expr(expr)
    if typeof(expr) == Expr
        if expr.head == :call && expr.args[1] == :gen
            # Transform `gen` call into `MockGenerate` instance followed by `|> run!`
            return Expr(:call, :(|>), transform_gen_call(expr), :run!)
        else
            # Recursively process each argument of the expression
            return Expr(expr.head, map(process_expr, expr.args)...)
        end
    else
        return expr
    end
end

# Helper function to transform `gen` call into `MockGenerate` instance
function transform_gen_call(gen_call)
    variable = gen_call.args[2]
    args = gen_call.args[3:end]
    return Expr(:call, :MockGenerate, variable, args...)
end

## This works, however, having the symbol as the first argument is inconvenient and not mapping to current PromptingTools signature (reserved for prompt templates)
## Solution is to use something like `-->` to indicate the variable name to capture
@aimodel function tip_suggestion()
    s = "Here are two tips for staying healthy: 1. Balanced Diet. 2. Regular Exercise.\n\n"

    forks = []
    for i in 1:2
        detailed_tip = copy(s) * "Now, expand tip $(i) into a paragraph:\n" *
                       gen(:detailed_tip, max_tokens = 256, stop = "\n\n")
        push!(forks, detailed_tip)
    end

    s *= "Tip 1:" * forks[1][:detailed_tip] * "\n"
    s *= "Tip 2:" * forks[2][:detailed_tip] * "\n"
    s *= "In summary" * gen("summary")
end

#################
## Changes needed
# - capture variable name as obj --> var
# - make it accessible in the scope with `:var` (needed if there is uninterruptible chain of * * * * without any form etc)
# - ensure aicall accumulates memory properly
#
## Desired syntax (notice the `-->` it informs)
@aimodel function tip_suggestion()
    s = "Here are two tips for staying healthy: 1. Balanced Diet. 2. Regular Exercise.\n\n"

    forks = []
    for i in 1:2
        detailed_tip = copy(s) * "Now, expand tip $(i) into a paragraph:\n" *
                       gen(max_tokens = 256, stop = "\n\n") --> detailed_tip
        push!(forks, detailed_tip)
    end

    s *= "Tip 1:" * forks[1][:detailed_tip] * "\n"
    s *= "Tip 2:" * forks[2][:detailed_tip] * "\n"
    s *= "In summary" * gen("summary")
end

### Extras 

ctx = AIContext() # default context like models, API kwargs, etc
# Usage 1
tip = tip_suggestion()# uses default context

# Usage 2
ctx = AIContext()
tip_suggestion(ctx) # provide context explicitly

# # Questions on Agents
# - How to write unconstrained agent cycles?
# - How to provide tool choice / routing decision?