@testset "SVG Export (REQ-ECO-011)" begin
    # Basic SVG export
    @testset "save_svg produces valid SVG" begin
        b = Board("svg_basic", xlim=(-5, 5), ylim=(-5, 5))
        push!(b, point(1, 2; name="P"))

        tmpfile = tempname() * ".svg"
        try
            result = save_svg(tmpfile, b)
            @test result == tmpfile
            @test isfile(tmpfile)

            content = read(tmpfile, String)
            @test startswith(content, "<?xml")
            @test occursin("<svg", content)
            @test occursin("xmlns=\"http://www.w3.org/2000/svg\"", content)
        finally
            rm(tmpfile; force=true)
        end
    end

    # save() dispatches on .svg extension
    @testset "save() dispatches to SVG for .svg extension" begin
        b = Board("svg_dispatch", xlim=(-5, 5), ylim=(-5, 5))
        push!(b, point(0, 0; name="O"))

        tmpfile = tempname() * ".svg"
        try
            result = save(tmpfile, b)
            @test result == tmpfile
            content = read(tmpfile, String)
            @test startswith(content, "<?xml")
            @test occursin("<svg", content)
        finally
            rm(tmpfile; force=true)
        end
    end

    # SVG with multiple element types
    @testset "SVG with multiple elements" begin
        b = Board("svg_multi", xlim=(-5, 5), ylim=(-5, 5))
        p1 = point(0, 0; name="O")
        p2 = point(3, 4; name="A")
        push!(b, p1)
        push!(b, p2)
        push!(b, line(p1, p2; strokeColor="red"))
        push!(b, circle(p1, 3; strokeColor="blue"))

        tmpfile = tempname() * ".svg"
        try
            save(tmpfile, b)
            content = read(tmpfile, String)
            @test occursin("<svg", content)
            # SVG should contain visual elements
            @test length(content) > 1000
        finally
            rm(tmpfile; force=true)
        end
    end

    # save() errors on unsupported extension
    @testset "save() errors on unsupported extension" begin
        b = Board("svg_err")
        @test_throws ErrorException save(tempname() * ".png", b)
        @test_throws ErrorException save(tempname() * ".pdf", b)
    end

    # save() still works for .html
    @testset "save() still works for .html" begin
        b = Board("svg_html", xlim=(-5, 5), ylim=(-5, 5))
        push!(b, point(1, 1))

        tmpfile = tempname() * ".html"
        try
            save(tmpfile, b)
            content = read(tmpfile, String)
            @test occursin("<!DOCTYPE html>", content)
        finally
            rm(tmpfile; force=true)
        end
    end
end
