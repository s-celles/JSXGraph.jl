# SVG Export

JSXGraph.jl supports exporting boards as static SVG images via `save()` or `save_svg()`.

## Requirements

SVG export uses **Node.js** and **jsdom** to render JSXGraph boards headlessly.
On first use, `jsdom` is automatically installed in a package-local directory (`.node_deps/`).

- [Node.js](https://nodejs.org/) must be available on your `PATH`
- npm (bundled with Node.js) is used for jsdom installation

## Usage

### Export via `save()`

The `save()` function dispatches on the file extension:

```julia
using JSXGraph

b = board("myboard", xlim=(-5, 5), ylim=(-5, 5)) do
    point(1, 2; name="A")
    circle(point(0, 0), 3; strokeColor="blue")
end

# HTML export
save("plot.html", b)

# SVG export
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
| `.svg`    | Scalable Vector Graphics | Node.js + jsdom |

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

## Troubleshooting

**Node.js not found**: Install Node.js from <https://nodejs.org/> or via your package manager:
- macOS: `brew install node`
- Ubuntu/Debian: `sudo apt install nodejs npm`

**jsdom installation fails**: Try installing manually:
```sh
cd ~/.julia/packages/JSXGraph/<hash>/.node_deps
npm install jsdom
```
