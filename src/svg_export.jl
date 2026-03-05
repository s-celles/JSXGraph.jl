"""
SVG export support for JSXGraph boards (REQ-ECO-011).

Uses Node.js + jsdom to render JSXGraph boards headlessly and extract the SVG output.
"""

"""
    _NODE_MODULES_DIR

Directory where Node.js dependencies (jsdom) are installed for SVG export.
"""
const _NODE_MODULES_DIR = Ref{String}("")

function _node_modules_dir()
    if isempty(_NODE_MODULES_DIR[])
        _NODE_MODULES_DIR[] = joinpath(dirname(dirname(@__FILE__)), ".node_deps")
    end
    return _NODE_MODULES_DIR[]
end

"""
    _find_node() -> String

Find the `node` executable on the system PATH. Throws an error with instructions if not found.
"""
function _find_node()::String
    node = Sys.which("node")
    if node === nothing
        error(
            "Node.js is required for SVG export but was not found on PATH.\n" *
            "Install Node.js from https://nodejs.org/ or via your package manager.\n" *
            "On macOS: `brew install node`\n" *
            "On Ubuntu: `sudo apt install nodejs npm`"
        )
    end
    return node
end

"""
    _find_npm() -> String

Find the `npm` executable on the system PATH. Throws an error with instructions if not found.
"""
function _find_npm()::String
    npm = Sys.which("npm")
    if npm === nothing
        error(
            "npm is required for SVG export but was not found on PATH.\n" *
            "Install Node.js (which includes npm) from https://nodejs.org/"
        )
    end
    return npm
end

"""
    _ensure_jsdom()

Ensure jsdom is installed in the package-local node_modules directory.
Installs it automatically on first use.
"""
function _ensure_jsdom()
    deps_dir = _node_modules_dir()
    jsdom_dir = joinpath(deps_dir, "node_modules", "jsdom")
    if isdir(jsdom_dir)
        return  # already installed
    end
    npm = _find_npm()
    mkpath(deps_dir)
    @info "Installing jsdom for SVG export (one-time setup)..."
    cmd = Cmd(`$npm install --prefix $deps_dir jsdom`; dir=deps_dir)
    result = run(pipeline(cmd; stdout=devnull, stderr=devnull); wait=true)
    if !isdir(jsdom_dir)
        error("Failed to install jsdom. Try manually: `cd $deps_dir && npm install jsdom`")
    end
    @info "jsdom installed successfully."
end

"""
    _render_board_js_string(board::Board) -> String

Generate the JavaScript code for a board as a string (without HTML wrapping).
"""
function _render_board_js_string(board::Board)::String
    return sprint(render_board_js, board)
end

"""
    _svg_export_script(board::Board) -> String

Generate a Node.js script that renders the board headlessly and prints the SVG to stdout.
"""
function _svg_export_script(board::Board)::String
    jsxgraph_code = jsxgraph_js()
    board_js = _render_board_js_string(board)

    # Extract board dimensions from options
    opts = merge_with_defaults(board.options)
    css_opts = extract_css_options(opts)
    w = css_opts["width"]
    h = css_opts["height"]

    return """
    const { JSDOM } = require('jsdom');

    const html = `<!DOCTYPE html><html><head></head><body>
    <div id="$(board.id)" style="width:$(w)px;height:$(h)px;"></div>
    </body></html>`;

    const dom = new JSDOM(html, {
        pretendToBeVisual: true,
        runScripts: 'dangerously',
        resources: 'usable',
    });

    const window = dom.window;
    const document = window.document;

    // Suppress console output from JSXGraph (goes to stderr instead)
    const origConsole = { ...console };
    console.log = (...args) => process.stderr.write(args.join(' ') + '\\n');
    console.warn = (...args) => process.stderr.write('WARN: ' + args.join(' ') + '\\n');
    console.error = (...args) => process.stderr.write('ERR: ' + args.join(' ') + '\\n');

    // Polyfill browser APIs that jsdom doesn't support
    if (!window.SVGElement) {
        window.SVGElement = window.Element;
    }
    if (!window.IntersectionObserver) {
        window.IntersectionObserver = class { observe() {} unobserve() {} disconnect() {} };
    }
    if (!window.matchMedia) {
        window.matchMedia = () => ({ matches: false, addListener: () => {}, removeListener: () => {} });
    }

    // Inject JSXGraph
    const scriptEl = document.createElement('script');
    scriptEl.textContent = $(JSON.json(jsxgraph_code));
    document.head.appendChild(scriptEl);

    // Inject board initialization
    const boardScript = document.createElement('script');
    boardScript.textContent = $(JSON.json(board_js));
    document.head.appendChild(boardScript);

    // Extract SVG
    setTimeout(() => {
        const container = document.getElementById('$(board.id)');
        if (!container) {
            process.stderr.write('ERROR: Board container not found\\n');
            process.exit(1);
        }
        const svg = container.querySelector('svg');
        if (!svg) {
            process.stderr.write('ERROR: No SVG element found in board\\n');
            process.exit(1);
        }

        // Add XML namespace and viewBox if missing
        svg.setAttribute('xmlns', 'http://www.w3.org/2000/svg');
        svg.setAttribute('xmlns:xlink', 'http://www.w3.org/1999/xlink');
        if (!svg.getAttribute('viewBox')) {
            svg.setAttribute('viewBox', '0 0 $(w) $(h)');
        }

        // Output standalone SVG
        const svgString = '<?xml version="1.0" encoding="UTF-8"?>\\n' + svg.outerHTML;
        process.stdout.write(svgString);
        process.exit(0);
    }, 100);
    """
end

"""
    save_svg(filename::String, board::Board)

Export a board as a static SVG image file.

Requires Node.js to be installed on the system. On first use, automatically
installs the `jsdom` npm package in a package-local directory.

# Arguments
- `filename::String`: Output file path (should end in `.svg`)
- `board::Board`: The board to export

# Examples
```julia
board = Board("myboard", xlim=(-5,5), ylim=(-5,5))
push!(board, point(1, 2; name="A"))
push!(board, circle(point(0, 0), 3))
save("plot.svg", board)
```
"""
function save_svg(filename::String, board::Board)
    node = _find_node()
    _ensure_jsdom()

    script = _svg_export_script(board)
    deps_dir = _node_modules_dir()

    # Write script to a temp file
    script_path = tempname() * ".js"
    try
        write(script_path, script)

        # Run node with NODE_PATH pointing to our local node_modules
        node_path = joinpath(deps_dir, "node_modules")
        env = copy(ENV)
        env["NODE_PATH"] = node_path

        output = IOBuffer()
        errors = IOBuffer()
        cmd = Cmd(`$node $script_path`; env=env)
        proc = run(pipeline(cmd; stdout=output, stderr=errors); wait=true)

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
