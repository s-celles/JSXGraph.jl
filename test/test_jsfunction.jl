@testset "Julia to JS Conversion" begin
    # Basic arithmetic
    @test julia_to_js(:(x + 1)) == "x + 1"
    @test julia_to_js(:(x - 1)) == "x - 1"
    @test julia_to_js(:(x * 2)) == "x * 2"
    @test julia_to_js(:(x / 2)) == "x / 2"

    # Math functions → Math.*
    @test julia_to_js(:(sin(x))) == "Math.sin(x)"
    @test julia_to_js(:(cos(x))) == "Math.cos(x)"
    @test julia_to_js(:(exp(x))) == "Math.exp(x)"
    @test julia_to_js(:(sqrt(x))) == "Math.sqrt(x)"
    @test julia_to_js(:(log(x))) == "Math.log(x)"
    @test julia_to_js(:(abs(x))) == "Math.abs(x)"

    # Power → Math.pow
    @test julia_to_js(:(x^2)) == "Math.pow(x, 2)"

    # Constants
    @test julia_to_js(:pi) == "Math.PI"
    @test julia_to_js(:π) == "Math.PI"
    @test julia_to_js(:ℯ) == "Math.E"

    # Lambda
    @test julia_to_js(:(x -> sin(x) + x^2)) ==
        "function(x){return Math.sin(x) + Math.pow(x, 2);}"

    # Nested calls
    @test julia_to_js(:(cos(x) * exp(-x))) == "Math.cos(x) * Math.exp(-x)"

    # Unary minus
    @test julia_to_js(:(-x)) == "-x"

    # Numbers
    @test julia_to_js(:(3.14)) == "3.14"
    @test julia_to_js(:(42)) == "42"

    # Function objects
    @test julia_to_js(sin) == "function(x){return Math.sin(x);}"
    @test julia_to_js(cos) == "function(x){return Math.cos(x);}"
end

@testset "@jsf Macro" begin
    # Lambda → JSFunction
    f = @jsf x -> sin(x)
    @test f isa JSFunction
    @test f.code == "function(x){return Math.sin(x);}"

    # Complex expression
    f2 = @jsf x -> sin(x) + x^2
    @test f2.code == "function(x){return Math.sin(x) + Math.pow(x, 2);}"

    # Multi-argument lambda
    f3 = @jsf (x, y) -> x^2 + y^2
    @test f3.code == "function(x, y){return Math.pow(x, 2) + Math.pow(y, 2);}"

    # Constants
    f4 = @jsf x -> x * π
    @test occursin("Math.PI", f4.code)

    # Nested math functions
    f5 = @jsf x -> cos(x) * exp(-x)
    @test f5.code == "function(x){return Math.cos(x) * Math.exp(-x);}"

    # Use with functiongraph
    fg = functiongraph(@jsf x -> x^2)
    @test fg isa JSXElement
    @test fg.parents[1] isa JSFunction
    @test occursin("Math.pow", fg.parents[1].code)

    # Simple expression (not lambda)
    f6 = @jsf sin(x) + cos(x)
    @test f6 isa JSFunction
    @test f6.code == "Math.sin(x) + Math.cos(x)"
end

@testset "@jsf Unsupported Constructs" begin
    # try/catch
    @test_throws ArgumentError @macroexpand @jsf try
        sin(x)
    catch
        0
    end

    # for loop
    @test_throws ArgumentError @macroexpand @jsf for i in 1:10
        i
    end

    # while loop
    @test_throws ArgumentError @macroexpand @jsf while true
        0
    end

    # comprehension
    @test_throws ArgumentError @macroexpand @jsf [x^2 for x in 1:10]

    # Multi-statement body
    @test_throws ArgumentError @macroexpand @jsf x -> begin
        a = sin(x)
        a + 1
    end
end
