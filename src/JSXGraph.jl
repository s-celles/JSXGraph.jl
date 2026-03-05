module JSXGraph

using DocStringExtensions
using JSON
using Artifacts
using Random: randstring

export AbstractJSXElement, Board
export JSXElement, JSFunction
export JSXGRAPH_VERSION
export html_string, html_page, html_fragment
export open_in_browser

# Element constructors
export point, line, segment, arrow, circle, arc, sector
export polygon, regularpolygon, angle, conic, ellipse, parabola, hyperbola
export functiongraph, curve, implicitcurve, inequality
export tangent, normal, integral, derivative, riemannsum, slopefield, vectorfield
export slider, checkbox, input, button, glider, tapemeasure, text, image

# Composition and convenience
export plot, julia_to_js

include("types.jl")
include("aliases.jl")
include("elements.jl")
include("jsfunction.jl")
include("composition.jl")
include("assets.jl")
include("options.jl")
include("html.jl")
include("display.jl")

end # module JSXGraph
