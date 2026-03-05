using Test
using JSXGraph
using Colors

@testset "JSXGraph.jl" begin
    @testset "Core Types" begin
        @test isabstracttype(AbstractJSXElement)
        @test isconcretetype(Board)
        @test !(Board <: AbstractJSXElement)

        # Board constructor
        b = Board("test", AbstractJSXElement[], Dict{String,Any}())
        @test b.id == "test"
        @test b.elements == AbstractJSXElement[]
        @test b.options == Dict{String,Any}()

        # Board field types
        @test fieldtype(Board, :id) == String
        @test fieldtype(Board, :elements) == Vector{AbstractJSXElement}
        @test fieldtype(Board, :options) == Dict{String,Any}
    end

    @testset "Colors Extension" begin
        using Colors
        ext = Base.get_extension(JSXGraph, :JSXGraphColorsExt)
        @test ext !== nothing
    end

    @testset "Unitful Extension" begin
        using Unitful
        ext = Base.get_extension(JSXGraph, :JSXGraphUnitfulExt)
        @test ext !== nothing
    end

    @testset "Tables Extension" begin
        using Tables
        ext = Base.get_extension(JSXGraph, :JSXGraphTablesExt)
        @test ext !== nothing
    end

    @testset "Observables Extension" begin
        using Observables
        ext = Base.get_extension(JSXGraph, :JSXGraphObservablesExt)
        @test ext !== nothing
    end

    @testset "Board Keyword Constructor" begin
        # Default options
        b1 = Board("b1")
        @test b1.id == "b1"
        @test b1.options["axis"] == true
        @test isempty(b1.elements)
        @test !isempty(b1.options)

        # Custom bounding box from xlim/ylim
        b2 = Board("b2", xlim=(-10, 10), ylim=(-5, 5))
        @test b2.options["boundingbox"] == [-10, 5, 10, -5]

        # Grid and dimensions
        b3 = Board("b3", grid=true, width=600, height=400)
        @test b3.options["grid"] == true
        @test b3.options["width"] == 600
        @test b3.options["height"] == 400

        # Auto-generated id when empty
        b4 = Board("", xlim=(-5, 5), ylim=(-5, 5))
        @test !isempty(b4.id)

        # Default elements and options
        b5 = Board("b5")
        @test isempty(b5.elements)
        @test !isempty(b5.options)
    end

    @testset "Options Mapping" begin
        # JS options output
        js_str = JSXGraph.board_options_to_js(
            Dict{String,Any}("axis" => true, "boundingbox" => [-5, 5, 5, -5])
        )
        @test occursin("\"axis\"", js_str)
        @test occursin("true", js_str)
        @test occursin("boundingbox", js_str)

        # CSS-only options should NOT be in JS output
        js_str2 = JSXGraph.board_options_to_js(
            Dict{String,Any}(
                "axis" => true, "width" => 500, "height" => 500, "background" => "#ffffff"
            ),
        )
        @test !occursin("\"width\"", js_str2)
        @test !occursin("\"height\"", js_str2)
        @test !occursin("\"background\"", js_str2)

        # Unknown keys pass through to JS
        js_str3 = JSXGraph.board_options_to_js(Dict{String,Any}("keepAspectRatio" => true))
        @test occursin("keepAspectRatio", js_str3)
        @test occursin("true", js_str3)

        # Extract CSS options
        css = JSXGraph.extract_css_options(
            Dict{String,Any}(
                "width" => 600, "height" => 400, "background" => "#ccc", "axis" => true
            ),
        )
        @test css["width"] == 600
        @test css["height"] == 400
        @test css["background"] == "#ccc"
        @test !haskey(css, "axis")
    end

    @testset "HTML Generation" begin
        board = Board("test")

        # Returns a String
        result = html_string(board)
        @test result isa String

        # Full page output
        @test occursin("<!DOCTYPE html>", result)
        @test occursin("<div id=\"test\"", result)
        @test occursin("jxgbox", result)
        @test occursin("JXG.JSXGraph.initBoard", result)
        @test occursin("boundingbox", result)

        # Fragment mode
        frag = html_string(board; full_page=false)
        @test !occursin("<!DOCTYPE", frag)

        # Convenience functions
        @test html_page(board) == html_string(board; full_page=true)
        @test html_fragment(board) == html_string(board; full_page=false)

        # Grid option passes through
        board_grid = Board("test_grid", grid=true)
        html_grid = html_string(board_grid)
        @test occursin("\"grid\"", html_grid)
        @test occursin("true", html_grid)
    end

    @testset "Asset Loading" begin
        # Version constant
        @test JSXGRAPH_VERSION == "1.12.2"

        # JS artifact content
        js_content = JSXGraph.jsxgraph_js()
        @test !isempty(js_content)
        @test occursin("JSXGraph", js_content)

        # CSS artifact content
        css_content = JSXGraph.jsxgraph_css()
        @test !isempty(css_content)
        @test occursin("jxgbox", css_content)

        # Inline HTML embeds full JS (output should be large)
        inline_html = html_string(Board("test"))
        @test length(inline_html) > 100_000

        # Inline HTML contains style tag with CSS
        @test occursin("<style>", inline_html)
    end

    @testset "CDN Mode" begin
        # CDN output returns a String
        cdn_html = html_string(Board("test"); asset_mode=:cdn)
        @test cdn_html isa String

        # Contains CDN references
        @test occursin("cdn.jsdelivr.net", cdn_html)
        @test occursin("<script", cdn_html)
        @test occursin("src=", cdn_html)
        @test occursin("<link rel=", cdn_html)

        # CDN output is small (no embedded JS)
        @test length(cdn_html) < 10_000

        # CDN is at least 80% smaller than inline
        inline_html = html_string(Board("test"); asset_mode=:inline)
        @test length(cdn_html) < 0.2 * length(inline_html)

        # Invalid mode throws ArgumentError
        @test_throws ArgumentError html_string(Board("test"); asset_mode=:invalid)
    end

    @testset "HTML MIME Display" begin
        board = Board("test")
        html = sprint(show, MIME("text/html"), board)

        # Returns non-empty string
        @test !isempty(html)

        # Fragment mode (no DOCTYPE)
        @test !occursin("<!DOCTYPE", html)

        # CDN mode
        @test occursin("cdn.jsdelivr.net", html)

        # Contains div with jxgbox class
        @test occursin("<div id=", html)
        @test occursin("jxgbox", html)

        # Contains initBoard
        @test occursin("JXG.JSXGraph.initBoard", html)

        # Contains CDN script src and link tags
        @test occursin("<script", html)
        @test occursin("src=", html)
        @test occursin("<link rel=", html)
    end

    @testset "Unique Display IDs" begin
        board = Board("test")

        # Two display calls produce different div IDs
        html1 = sprint(show, MIME("text/html"), board)
        html2 = sprint(show, MIME("text/html"), board)

        # Extract display IDs
        m1 = match(r"id=\"(jxg_[a-zA-Z0-9]+)\"", html1)
        m2 = match(r"id=\"(jxg_[a-zA-Z0-9]+)\"", html2)
        @test m1 !== nothing
        @test m2 !== nothing
        @test m1[1] != m2[1]

        # Original board.id should NOT appear as div id
        @test !occursin("id=\"test\"", html1)

        # Display IDs match expected pattern (jxg_ + 12 chars)
        @test length(m1[1]) == 16  # "jxg_" (4) + 12 chars
    end

    @testset "Plain Text Display" begin
        board = Board("test")
        txt = sprint(show, MIME("text/plain"), board)

        # Contains board ID
        @test occursin("Board(\"test\"", txt)

        # Contains element count
        @test occursin("0 elements", txt)

        # Contains dimensions
        @test occursin("500x500px", txt)

        # Custom xlim/ylim
        board2 = Board("b2", xlim=(-10, 10), ylim=(-5, 5))
        txt2 = sprint(show, MIME("text/plain"), board2)
        @test occursin("x=[-10,10]", txt2) || occursin("x=[-10, 10]", txt2)
        @test occursin("y=[-5,5]", txt2) || occursin("y=[-5, 5]", txt2)

        # Single line (no embedded newlines)
        @test !occursin("\n", rstrip(txt))
    end

    @testset "Fragment Embedding" begin
        board = Board("test")
        html = sprint(show, MIME("text/html"), board)

        # No full page wrappers
        @test !occursin("<html>", html)
        @test !occursin("<body>", html)

        # CDN mode output is compact (under 2000 bytes)
        @test length(html) < 2000

        # Contains all necessary fragment elements
        @test occursin("<link", html)
        @test occursin("<script", html)
        @test occursin("<div", html)
        @test occursin("initBoard", html)
    end

    @testset "Pluto Compatibility" begin
        board = Board("test")
        html = sprint(show, MIME("text/html"), board)

        # No <style> tags (Pluto's DOMPurify strips them)
        @test !occursin("<style>", html)

        # Uses CDN <link> for CSS instead
        @test occursin("<link rel=", html)

        # Inline styles on div via style= attribute
        @test occursin("style=", html)

        # Unique IDs per call (same as Unique Display IDs test)
        html2 = sprint(show, MIME("text/html"), board)
        id1 = match(r"id=\"(jxg_[a-zA-Z0-9]+)\"", html)[1]
        id2 = match(r"id=\"(jxg_[a-zA-Z0-9]+)\"", html2)[1]
        @test id1 != id2
    end

    @testset "DefaultApplication Extension" begin
        using DefaultApplication
        ext = Base.get_extension(JSXGraph, :JSXGraphDefaultApplicationExt)
        @test ext !== nothing
    end

    @testset "JSXElement Type" begin
        @test JSXElement <: AbstractJSXElement
        @test isconcretetype(JSXElement)

        # Constructor
        el = JSXElement("point", Any[1, 2], Dict{String,Any}())
        @test el.type_name == "point"
        @test el.parents == Any[1, 2]
        @test el.attributes == Dict{String,Any}()

        # JSFunction
        jf = JSFunction("function(x){return x;}")
        @test jf.code == "function(x){return x;}"
    end

    @testset "Geometric Primitives" begin
        # Point
        p = point(2, 3)
        @test p isa JSXElement
        @test p.type_name == "point"
        @test p.parents == Any[2, 3]

        # Point with attributes
        p2 = point(2, 3; color="red", size=4)
        @test p2.attributes["strokeColor"] == "red"
        @test p2.attributes["size"] == 4

        # Line with element references
        p1 = point(-1, 0)
        p3 = point(1, 0)
        l = line(p1, p3)
        @test l.type_name == "line"
        @test l.parents[1] === p1
        @test l.parents[2] === p3

        # Circle
        c = circle(p1, 3)
        @test c.type_name == "circle"
        @test c.parents[1] === p1
        @test c.parents[2] == 3

        # All 14 geometric primitives return correct type_name
        @test segment(p1, p3).type_name == "segment"
        @test arrow(p1, p3).type_name == "arrow"
        @test arc(p1, p3, point(0, 1)).type_name == "arc"
        @test sector(p1, p3, point(0, 1)).type_name == "sector"
        @test polygon(p1, p3, point(0, 1)).type_name == "polygon"
        @test regularpolygon(p1, p3, 5).type_name == "regularpolygon"
        @test JSXGraph.angle(p1, point(0, 0), p3).type_name == "angle"
        @test conic(p1, p3, point(0, 1), point(1, 1), point(-1, 1)).type_name == "conic"
        @test ellipse(p1, p3, point(0, 2)).type_name == "ellipse"
        @test parabola(p1, l).type_name == "parabola"
        @test hyperbola(p1, p3, point(0, 2)).type_name == "hyperbola"
    end

    @testset "Element JS Rendering" begin
        # Board with one point
        b = Board("test_el")
        p = point(1, 2)
        push!(b.elements, p)
        html = html_string(b)
        @test occursin("create('point'", html)
        @test occursin("[1,2]", html)

        # Two elements rendered in order
        b2 = Board("test_el2")
        p1 = point(0, 0)
        p2 = point(3, 4)
        push!(b2.elements, p1)
        push!(b2.elements, p2)
        html2 = html_string(b2)
        idx1 = findfirst("el_001", html2)
        idx2 = findfirst("el_002", html2)
        @test idx1 !== nothing
        @test idx2 !== nothing
        @test first(idx1) < first(idx2)

        # Element references: line referencing points
        b3 = Board("test_el3")
        pa = point(-1, 0)
        pb = point(1, 0)
        l = line(pa, pb)
        push!(b3.elements, pa)
        push!(b3.elements, pb)
        push!(b3.elements, l)
        html3 = html_string(b3)
        @test occursin("create('line'", html3)
        @test occursin("el_001", html3)
        @test occursin("el_002", html3)

        # Attributes appear as JSON
        b4 = Board("test_el4")
        p = point(1, 2; color="blue", size=5)
        push!(b4.elements, p)
        html4 = html_string(b4)
        @test occursin("\"strokeColor\"", html4)
        @test occursin("\"blue\"", html4)

        # text/plain display shows element count
        b5 = Board("test_el5")
        push!(b5.elements, point(0, 0))
        push!(b5.elements, point(1, 1))
        txt = sprint(show, MIME("text/plain"), b5)
        @test occursin("2 elements", txt)
    end

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

    @testset "Analytic Elements" begin
        # functiongraph with Julia function
        fg = functiongraph(sin)
        @test fg isa JSXElement
        @test fg.type_name == "functiongraph"
        @test length(fg.parents) == 1
        @test fg.parents[1] isa JSFunction

        # functiongraph with expression
        fg2 = functiongraph(:(x -> x^2))
        @test fg2.type_name == "functiongraph"
        @test fg2.parents[1] isa JSFunction

        # curve
        c = curve(cos, sin, 0, 2π)
        @test c isa JSXElement
        @test c.type_name == "curve"

        # derivative references another element
        d = derivative(fg)
        @test d.type_name == "derivative"
        @test d.parents[1] === fg

        # HTML output contains JS function
        b = Board("test_fg")
        push!(b, fg)
        html = html_string(b)
        @test occursin("create('functiongraph'", html)
        @test occursin("Math.sin", html)

        # All 11 analytic constructors
        p1 = point(0, 0)
        l = line(p1, point(1, 0))
        gl = glider(0, 0, fg)
        @test implicitcurve(:(x -> x^2 + 1)).type_name == "implicitcurve"
        @test inequality(l).type_name == "inequality"
        @test tangent(gl).type_name == "tangent"
        @test normal(gl).type_name == "normal"
        @test integral(fg, -1, 1).type_name == "integral"
        @test derivative(fg).type_name == "derivative"
        @test riemannsum(sin, 10, "lower").type_name == "riemannsum"
        @test slopefield(:(x -> x^2)).type_name == "slopefield"
        @test vectorfield(:(x -> x^2)).type_name == "vectorfield"

        # functiongraph with attributes
        fg3 = functiongraph(sin; color="red", strokeWidth=3)
        @test fg3.attributes["strokeColor"] == "red"
        @test fg3.attributes["strokeWidth"] == 3
    end

    @testset "Interactive Elements" begin
        # Slider
        s = slider([0, -3], [4, -3], [1, 2, 5])
        @test s isa JSXElement
        @test s.type_name == "slider"
        @test length(s.parents) == 3

        # Slider with attributes
        s2 = slider([0, -3], [4, -3], [1, 2, 5]; name="a")
        @test s2.attributes["name"] == "a"

        # Text
        t = text(0, 4, "Hello")
        @test t isa JSXElement
        @test t.type_name == "text"
        @test t.parents == Any[0, 4, "Hello"]

        # HTML with slider
        b = Board("test_slider")
        push!(b, s)
        html = html_string(b)
        @test occursin("create('slider'", html)

        # All 8 interactive constructors
        fg = functiongraph(sin)
        @test checkbox(0, 0, "Show").type_name == "checkbox"
        @test input(0, 0, "val", "Label").type_name == "input"
        @test button(0, 0, "Click", "handler()").type_name == "button"
        @test glider(0, 0, fg).type_name == "glider"
        @test tapemeasure([0, 0], [1, 1]).type_name == "tapemeasure"
        @test text(0, 0, "hi").type_name == "text"
        @test image("url.png", [0, 0], [1, 1]).type_name == "image"
    end

    @testset "Composition & Transformation Elements" begin
        p1 = point(0, 0)
        p2 = point(1, 0)
        p3 = point(0, 1)
        l = line(p1, p2)
        fg = functiongraph(sin)

        # --- group ---
        g = group(p1, p2, p3)
        @test g isa JSXElement
        @test g.type_name == "group"
        @test length(g.parents) == 3
        @test g.parents[1] === p1
        @test g.parents[2] === p2
        @test g.parents[3] === p3

        # group with attributes
        g2 = group(p1, p2; color="red")
        @test g2.attributes["strokeColor"] == "red"

        # --- transformation ---
        # Translation
        t = transformation("translate", 2, 3)
        @test t isa JSXElement
        @test t.type_name == "transformation"
        @test t.parents[1] == Any[2, 3]
        @test t.parents[2] == "translate"

        # Rotation around origin
        t2 = transformation("rotate", π/4)
        @test t2.type_name == "transformation"
        @test t2.parents[1] == Any[π/4]
        @test t2.parents[2] == "rotate"

        # Rotation around a point
        t3 = transformation("rotate", π/4, 1, 1)
        @test t3.type_name == "transformation"
        @test t3.parents[1] == Any[π/4, 1, 1]
        @test t3.parents[2] == "rotate"

        # Scale
        t4 = transformation("scale", 2, 3)
        @test t4.type_name == "transformation"
        @test t4.parents[2] == "scale"

        # --- reflection ---
        r = reflection(l)
        @test r isa JSXElement
        @test r.type_name == "reflection"
        @test r.parents[1] === l

        # reflection with attributes
        r2 = reflection(l; visible=false)
        @test r2.attributes["visible"] == false

        # --- rotation ---
        rot = rotation(p1, π/4)
        @test rot isa JSXElement
        @test rot.type_name == "rotation"
        @test rot.parents[1] === p1
        @test rot.parents[2] == π/4

        # --- translation ---
        tr = translation(2, 3)
        @test tr isa JSXElement
        @test tr.type_name == "translation"
        @test tr.parents == Any[2, 3]

        # --- grid ---
        gr = grid()
        @test gr isa JSXElement
        @test gr.type_name == "grid"
        @test isempty(gr.parents)

        # grid with attributes
        gr2 = grid(; majorStep=[1, 1])
        @test gr2.attributes["majorStep"] == [1, 1]

        # --- axis ---
        ax = axis(p1, p2)
        @test ax isa JSXElement
        @test ax.type_name == "axis"
        @test ax.parents[1] === p1
        @test ax.parents[2] === p2

        # axis with attributes
        ax2 = axis(p1, p2; name="x")
        @test ax2.attributes["name"] == "x"

        # --- ticks ---
        tk = ticks(ax, 1.0)
        @test tk isa JSXElement
        @test tk.type_name == "ticks"
        @test tk.parents[1] === ax
        @test tk.parents[2] == 1.0

        # ticks without distance
        tk2 = ticks(ax)
        @test tk2.type_name == "ticks"
        @test length(tk2.parents) == 1

        # ticks with attributes
        tk3 = ticks(ax, 2.0; minorTicks=4, drawLabels=true)
        @test tk3.attributes["minorTicks"] == 4
        @test tk3.attributes["drawLabels"] == true

        # --- legend ---
        fg2 = functiongraph(cos)
        leg = legend(fg, fg2; labels=["sin", "cos"])
        @test leg isa JSXElement
        @test leg.type_name == "legend"
        @test length(leg.parents) == 2
        @test leg.parents[1] === fg
        @test leg.parents[2] === fg2
        @test leg.attributes["labels"] == ["sin", "cos"]

        # --- HTML rendering ---
        b = Board("test_comp_trans")
        p_origin = point(0, 0)
        p_xdir = point(1, 0)
        push!(b, p_origin, p_xdir)
        push!(b, gr)
        push!(b, axis(p_origin, p_xdir))
        html = html_string(b)
        @test occursin("create('grid'", html)
        @test occursin("create('axis'", html)

        # All 9 composition/transformation constructors produce correct type_name
        @test group(p1).type_name == "group"
        @test transformation("translate", 1, 0).type_name == "transformation"
        @test reflection(l).type_name == "reflection"
        @test rotation(p1, π).type_name == "rotation"
        @test translation(1, 0).type_name == "translation"
        @test grid().type_name == "grid"
        @test axis(p1, p2).type_name == "axis"
        @test ticks(ax).type_name == "ticks"
        @test legend(fg).type_name == "legend"
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

    @testset "Attribute Aliases" begin
        # color → strokeColor
        p = point(1, 2; color="red")
        @test p.attributes["strokeColor"] == "red"
        @test !haskey(p.attributes, "color")

        # linewidth → strokeWidth
        p2 = point(1, 2; linewidth=3)
        @test p2.attributes["strokeWidth"] == 3

        # fillcolor → fillColor
        p3 = point(1, 2; fillcolor="blue")
        @test p3.attributes["fillColor"] == "blue"

        # opacity → strokeOpacity + fillOpacity
        p4 = point(1, 2; opacity=0.5)
        @test p4.attributes["strokeOpacity"] == 0.5
        @test p4.attributes["fillOpacity"] == 0.5

        # alpha → same as opacity
        p5 = point(1, 2; alpha=0.5)
        @test p5.attributes["strokeOpacity"] == 0.5
        @test p5.attributes["fillOpacity"] == 0.5

        # label → name
        p6 = point(1, 2; label="A")
        @test p6.attributes["name"] == "A"

        # legend → withLabel
        p7 = point(1, 2; legend=true)
        @test p7.attributes["withLabel"] == true

        # linestyle → dash
        p8 = point(1, 2; linestyle="dashed")
        @test p8.attributes["dash"] == "dashed"

        # markersize → size
        p9 = point(1, 2; markersize=6)
        @test p9.attributes["size"] == 6

        # linecolor → strokeColor
        p10 = point(1, 2; linecolor="green")
        @test p10.attributes["strokeColor"] == "green"
    end

    @testset "Alias Precedence" begin
        # Native JSXGraph name wins over alias
        p = point(1, 2; color="red", strokeColor="blue")
        @test p.attributes["strokeColor"] == "blue"

        # Passthrough: unrecognized keywords pass through
        p2 = point(1, 2; keepAspectRatio=true)
        @test p2.attributes["keepAspectRatio"] == true

        # Native JSXGraph attributes still work directly
        p3 = point(1, 2; strokeColor="red")
        @test p3.attributes["strokeColor"] == "red"
    end

    @testset "Aliases Across Element Types" begin
        # Geometric elements
        c = circle(point(0, 0), 3; color="green", linewidth=2)
        @test c.attributes["strokeColor"] == "green"
        @test c.attributes["strokeWidth"] == 2

        # Analytic elements
        fg = functiongraph(sin; color="blue")
        @test fg.attributes["strokeColor"] == "blue"

        # Interactive elements
        s = slider([0, -3], [4, -3], [1, 2, 5]; color="purple")
        @test s.attributes["strokeColor"] == "purple"

        # HTML output contains JSXGraph-native names
        b = Board("test_aliases")
        push!(b, point(1, 2; color="red", markersize=6))
        html = html_string(b)
        @test occursin("\"strokeColor\"", html)
        @test occursin("\"size\"", html)
    end

    @testset "Colors.jl Integration" begin
        # color_to_css for RGB
        css = JSXGraph.color_to_css(RGB(1, 0, 0))
        @test css isa String
        @test startswith(css, "#")

        # color_to_css for RGBA
        css_rgba = JSXGraph.color_to_css(RGBA(0, 0, 1, 0.5))
        @test css_rgba isa String
        @test occursin("rgba", css_rgba)

        # color_to_css for HSL
        css_hsl = JSXGraph.color_to_css(HSL(120, 1.0, 0.5))
        @test css_hsl isa String
        @test startswith(css_hsl, "#")

        # Point with RGB color → attributes contain string
        p = point(1, 2; color=RGB(1, 0, 0))
        @test p.attributes["strokeColor"] isa String

        # Point with RGBA color → attributes contain rgba string
        p2 = point(1, 2; color=RGBA(0, 0, 1, 0.5))
        @test occursin("rgba", p2.attributes["strokeColor"])

        # fillcolor with colorant
        p3 = point(1, 2; fillcolor=colorant"dodgerblue")
        @test p3.attributes["fillColor"] isa String

        # HTML output contains valid CSS, not Julia types
        b = Board("test_colors")
        push!(b, point(1, 2; color=RGB(1, 0, 0)))
        html = html_string(b)
        @test occursin("#", html)
        @test !occursin("RGB{", html)
    end

    @testset "Short Aliases" begin
        # col → strokeColor
        p = point(1, 2; col="green")
        @test p.attributes["strokeColor"] == "green"

        # lw → strokeWidth
        p2 = point(1, 2; lw=2)
        @test p2.attributes["strokeWidth"] == 2

        # ms → size
        p3 = point(1, 2; ms=10)
        @test p3.attributes["size"] == 10

        # ls → dash
        p4 = point(1, 2; ls="dotted")
        @test p4.attributes["dash"] == "dotted"

        # fill → fillColor
        p5 = point(1, 2; fill="yellow")
        @test p5.attributes["fillColor"] == "yellow"

        # Full alias wins over short alias
        p6 = point(1, 2; col="red", color="blue")
        @test p6.attributes["strokeColor"] == "blue"
    end
end
