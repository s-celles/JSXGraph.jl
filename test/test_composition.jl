@testset "Board Composition" begin
    # push! adds element and returns board
    b = Board("comp1")
    p = point(1, 2)
    result = push!(b, p)
    @test result === b
    @test length(b.elements) == 1
    @test b.elements[1] === p

    # push! variadic
    b2 = Board("comp2")
    p1 = point(0, 0)
    p2 = point(1, 1)
    push!(b2, p1, p2)
    @test length(b2.elements) == 2

    # + returns new board, original unchanged
    b3 = Board("comp3")
    p = point(1, 2)
    new_b = b3 + p
    @test length(b3.elements) == 0
    @test length(new_b.elements) == 1
    @test new_b.elements[1] === p

    # + chains correctly
    b4 = Board("comp4")
    p1 = point(0, 0)
    p2 = point(1, 1)
    p3 = point(2, 2)
    result = b4 + p1 + p2 + p3
    @test length(result.elements) == 3
    @test length(b4.elements) == 0

    # Board with elements added via + generates valid HTML
    b5 = Board("comp5")
    result = b5 + point(1, 2) + point(3, 4)
    html = html_string(result)
    @test occursin("create('point'", html)
    @test occursin("el_001", html)
    @test occursin("el_002", html)
end

@testset "High-Level Plot" begin
    # Returns a Board
    b = plot(sin, (-5, 5))
    @test b isa Board

    # Has exactly one functiongraph element
    @test length(b.elements) == 1
    @test b.elements[1].type_name == "functiongraph"

    # Bounding box x-range matches domain
    bb = b.options["boundingbox"]
    @test bb[1] == -5  # xmin
    @test bb[3] == 5   # xmax

    # Passes attributes to element
    b2 = plot(sin, (-5, 5); color="red")
    @test b2.elements[1].attributes["strokeColor"] == "red"

    # Zero-width domain throws error
    @test_throws ArgumentError plot(sin, (0, 0))

    # HTML output contains JS function
    html = html_string(b)
    @test occursin("Math.sin", html)
    @test occursin("create('functiongraph'", html)
end
