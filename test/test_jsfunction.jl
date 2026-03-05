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
