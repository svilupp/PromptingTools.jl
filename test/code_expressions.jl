using PromptingTools: AICode, isparsed, isparseerror, is_julia_code, is_julia_expr
using PromptingTools: remove_all_tests_from_expr!,
                      remove_test_items_from_expr!, remove_macro_expr!, extract_module_name

@testset "is_julia_expr" begin
    # Valid Julia Expressions
    @test is_julia_expr(:(x = 1)) == true
    @test is_julia_expr(:(x === y)) == true
    @test is_julia_expr(:(for i in 1:10
        println(i)
    end)) == true
    @test is_julia_expr(:(function foo()
        return 42
    end)) == true
    @test is_julia_expr(:(if x > 0
        println("positive")
    end)) == true

    # Invalid Expressions
    @test is_julia_expr(:(12345)) == false

    # Nested Expressions
    @test is_julia_expr(:(begin
        x = 1
        y = 2
    end)) == true

    # Non-Expr Types
    @test is_julia_expr(42) == false
    @test is_julia_expr("string") == false
    @test is_julia_expr([1, 2, 3]) == false
end

@testset "remove_macro_expr!" begin
    # Test with @testset macro
    expr = Meta.parseall("""
    @testset "Example Tests" begin
        x = 1 + 1
        @test x == 2
    end
    y = 3 + 3
    """)
    expected = Meta.parseall("y = 3 + 3")
    result = remove_macro_expr!(expr)
    @test result.args[end] == expected.args[end]

    # Test with nested @testset
    expr = Meta.parseall("""
    @testset "Outer Test" begin
        @testset "Inner Test" begin
            x = 1 + 1
        end
        y = 2 + 2
    end
    """)
    expected = Meta.parseall("") # All expressions are removed
    result = remove_macro_expr!(expr)
    # 1.9 parser eats the empty row, 1.10 retains it
    @test length(result.args) == 1 || result == expected

    # Test without @testset
    expr = Meta.parseall("z = 4 + 4")
    expected = Meta.parseall("z = 4 + 4")
    result = remove_macro_expr!(expr)
    @test result == expected

    # Test with different macro
    expr = Meta.parseall("@chain x begin; end")
    expected = Meta.parseall("@chain x begin; end")
    result = remove_macro_expr!(expr, Symbol("@test"))
    @test result == expected
end

@testset "remove_all_tests_from_expr!" begin
    # Test with both @testset and @test macros
    expr = Meta.parseall("""
    @testset "Example Tests" begin
        x = 1 + 1
        @test x == 2
    end
    @test x == 2
    @test_throws AssertionError func(1)
    y = 3 + 3
    """)
    expected = Meta.parseall("y = 3 + 3")
    result = remove_all_tests_from_expr!(expr)
    @test result.args[end] == expected.args[end]
end
@testset "remove_test_items_from_expr!" begin
    # Remove @test macros
    expr = Meta.parseall("""
    @testset "Example Tests" begin
        x = 1 + 1
        @test x == 2
        @test y == 2
    end
    @test x == 2
    @test_throws AssertionError func(1)
    y = 3 + 3
    """)
    expected = Meta.parseall("""
    @testset "Example Tests" begin
        x = 1 + 1
    end
    y = 3 + 3
    """)
    result = remove_test_items_from_expr!(expr)
    @test result.args[end] == expected.args[end]
end

@testset "extract_module_name" begin
    # Test with a valid module expression
    module_expr = Meta.parse("module MyTestModule\nend")
    @test extract_module_name(module_expr) == :MyTestModule

    # Test with an expression that is not a module
    non_module_expr = Meta.parse("x = 1 + 1")
    @test extract_module_name(non_module_expr) === nothing

    # In a nested expression tree
    module_expr = Meta.parseall("module MyTestModule\nfoo()=\"hello\"\nend")
    @test extract_module_name(module_expr) == :MyTestModule

    # Test with an empty expression
    empty_expr = Meta.parse("")
    @test extract_module_name(empty_expr) === nothing
end

@testset "isparsed, isparseerror" begin
    ## isparsed
    @test isparsed(:(x = 1)) == true
    # parse an incomplete call
    @test isparsed(Meta.parseall("(")) == false
    # parse an error call
    @test isparsed(Meta.parseall("+-+-+--+")) == false
    # nothing
    @test isparsed(nothing) == false
    # Validate that we don't have false positives with error
    @test isparsed(Meta.parseall("error(\"s\")")) == true

    ## isparseerror
    @test isparseerror(nothing) == false
    @test isparseerror(ErrorException("syntax: unexpected \"(\" in argument list")) == true
    @test isparseerror(Base.Meta.ParseError("xyz")) == true

    # AICode
    cb = AICode("(")
    @test isparsed(cb) == false
    cb = AICode("a+1")
    @test isparsed(cb) == true
end
