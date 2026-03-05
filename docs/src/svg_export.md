# SVG Export

JSXGraph.jl supports exporting boards as static SVG images via `save()` or `save_svg()`.

## Requirements

SVG export is provided via a **package extension** that depends on
[`NodeJS_22_jll`](https://github.com/JuliaBinaryWrappers/NodeJS_22_jll.jl).
Node.js v22 is automatically downloaded as a Julia artifact — no system
installation needed. On first SVG export, the `jsdom` npm package is
installed in a package-local directory (`.node_deps/`).

```julia
using Pkg
Pkg.add("NodeJS_22_jll")
```

## Usage

### Export via `save()`

Load `NodeJS_22_jll`, then the `save()` function dispatches on the file extension:

```julia
using JSXGraph
using NodeJS_22_jll  # activates SVG export extension

b = board("myboard", xlim=(-5, 5), ylim=(-5, 5)) do
    point(1, 2; name="A")
    circle(point(0, 0), 3; strokeColor="blue")
end

# HTML export (always available)
save("plot.html", b)

# SVG export (requires NodeJS_22_jll)
save("plot.svg", b)
```

### Direct SVG export

```julia
save_svg("plot.svg", b)
```

## Supported Formats

| Extension | Format | Backend |
|-----------|--------|---------|
| `.html`   | Self-contained HTML page | Built-in |
| `.svg`    | Scalable Vector Graphics | NodeJS_22_jll + jsdom |

Unsupported extensions (e.g. `.png`, `.pdf`) raise an `ErrorException`.

## API Reference

```@docs
save_svg
```

## How It Works

1. A Node.js script is generated that creates a virtual DOM using jsdom
2. The JSXGraph library is injected into the virtual DOM
3. The board is initialized with all elements
4. The resulting SVG element is extracted from the DOM
5. The SVG is written to the output file with proper XML headers

Node.js is provided by `NodeJS_22_jll` (Julia artifact, no system dependency).

## Troubleshooting

**"SVG export requires the NodeJS_22_jll package"**: Load it first:
```julia
using NodeJS_22_jll
```

**jsdom installation fails**: Try installing manually:
```sh
cd ~/.julia/packages/JSXGraph/<hash>/.node_deps
~/.julia/artifacts/<nodejs_hash>/bin/npm install jsdom
```
