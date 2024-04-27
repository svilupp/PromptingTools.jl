## Parsing error detection
function isparsed(ex::Expr)
    parse_error = Meta.isexpr(ex, :toplevel) && !isempty(ex.args) &&
                  Meta.isexpr(ex.args[end], (:error, :incomplete))
    return !parse_error
end
function isparsed(ex::Nothing)
    return false
end
function isparseerror(err::Exception)
    return err isa Base.Meta.ParseError ||
           (err isa ErrorException && startswith(err.msg, "syntax:"))
end
function isparseerror(err::Nothing)
    return false
end

## Parsing Helpers
JULIA_EXPR_HEADS = [
    :block,
    :quote,
    :call,
    :macrocall,
    :(=),
    :function,
    :for,
    :if,
    :while,
    :let,
    :try,
    :catch,
    :finally,
    :method,
    :tuple,
    :array,
    :index,
    :ref,
    :.,
    :do,
    :curly,
    :typed_vcat,
    :typed_hcat,
    :typed_vcat,
    :comprehension,
    :generator,
    :kw,
    :where
]
# Checks if the provided expression `ex` has some hallmarks of Julia code. Very naive!
# Serves as a quick check to avoid trying to eval output cells (```plaintext ... ```)
is_julia_expr(ex::Any) = false
function is_julia_expr(ex::Expr)
    ## Expression itself
    Meta.isexpr(ex, JULIA_EXPR_HEADS) && return true
    ## Its arguments
    for arg in ex.args
        Meta.isexpr(arg, JULIA_EXPR_HEADS) && return true
    end
    ## Nothing found...
    return false
end

# Remove any given macro expression from the expression tree, used to remove tests
function remove_macro_expr!(expr, sym::Symbol = Symbol("@testset"))
    if expr isa Expr && expr.head == :macrocall && !isempty(expr.args) &&
       expr.args[1] == sym
        return Expr(:block)
    elseif expr isa Expr && !isempty(expr.args)
        expr.args = filter(
            x -> !(x isa Expr && x.head == :macrocall && !isempty(x.args) &&
                   x.args[1] == sym),
            expr.args)
        foreach(x -> remove_macro_expr!(x, sym), expr.args)
    end
    expr
end

# Remove testsets and sets from the expression tree
function remove_test_items_from_expr!(expr)
    # Focus only on the three most common test macros 
    expr = remove_macro_expr!(expr, Symbol("@test"))
    expr = remove_macro_expr!(expr, Symbol("@test_throws"))
    return expr
end
function remove_all_tests_from_expr!(expr)
    # Focus only on the three most common test macros 
    expr = remove_macro_expr!(expr, Symbol("@testset"))
    expr = remove_test_items_from_expr!(expr)
    return expr
end

# Utility to identify the module name in a given expression (to evaluate subsequent calls in it)
function extract_module_name(expr)
    if isa(expr, Expr) && expr.head == :module
        return expr.args[2] # The second argument is typically the module name
    elseif isa(expr, Expr) && !isempty(expr.args)
        output = extract_module_name.(expr.args)
        for item in output
            if !isnothing(item)
                return item
            end
        end
    end
    nothing
end
