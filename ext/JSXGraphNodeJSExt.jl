module JSXGraphNodeJSExt

using JSXGraph
using NodeJS_22_jll: NodeJS_22_jll

"""
    _ensure_jsdom()

Ensure jsdom is installed in the package-local node_modules directory.
Installs it automatically on first use via the JLL-provided npm.
"""
function _ensure_jsdom()
    deps_dir = JSXGraph._node_modules_dir()
    jsdom_dir = joinpath(deps_dir, "node_modules", "jsdom")
    if isdir(jsdom_dir)
        return  # already installed
    end
    mkpath(deps_dir)
    @info "Installing jsdom for SVG export (one-time setup)..."
    cmd = Cmd(`$(NodeJS_22_jll.npm_path) install --prefix $deps_dir jsdom`; dir=deps_dir)
    run(pipeline(cmd; stdout=devnull, stderr=devnull); wait=true)
    if !isdir(jsdom_dir)
        error("Failed to install jsdom. Try manually: `cd $deps_dir && npm install jsdom`")
    end
    @info "jsdom installed successfully."
end

function JSXGraph.save_svg(filename::String, board::JSXGraph.Board)
    _ensure_jsdom()

    script = JSXGraph._svg_export_script(board)
    deps_dir = JSXGraph._node_modules_dir()

    # Write script to a temp file
    script_path = tempname() * ".js"
    try
        write(script_path, script)

        # Run JLL node with NODE_PATH pointing to our local node_modules
        node_modules = joinpath(deps_dir, "node_modules")
        env = copy(ENV)
        env["NODE_PATH"] = node_modules

        output = IOBuffer()
        errors = IOBuffer()
        cmd = Cmd(`$(NodeJS_22_jll.node_path) $script_path`; env=env)
        run(pipeline(cmd; stdout=output, stderr=errors); wait=true)

        svg_content = String(take!(output))
        err_content = String(take!(errors))

        if isempty(svg_content)
            error("SVG export produced no output. Errors:\n$err_content")
        end

        open(filename, "w") do io
            write(io, svg_content)
        end
    finally
        rm(script_path; force=true)
    end
    return filename
end

end # module JSXGraphNodeJSExt
