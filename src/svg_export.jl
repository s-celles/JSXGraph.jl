"""
SVG export support for JSXGraph boards (REQ-ECO-011).

The actual implementation lives in `ext/JSXGraphNodeJSExt.jl` and is loaded
automatically when `NodeJS_22_jll` is available. The core module provides
the script generation utilities and a stub `save_svg` that errors with
instructions when the extension is not loaded.
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

Requires `NodeJS_22_jll` to be installed. Add it with:

```julia
using Pkg; Pkg.add("NodeJS_22_jll")
```

Then load it before calling `save_svg`:

```julia
using NodeJS_22_jll
save("plot.svg", board)
```

# Arguments
- `filename::String`: Output file path (should end in `.svg`)
- `board::Board`: The board to export
"""
function save_svg end
