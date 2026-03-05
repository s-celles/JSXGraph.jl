# Element types and constructors

"""
$(TYPEDEF)

Represents a JavaScript function string for use in JSXGraph element parents.

$(TYPEDFIELDS)
"""
struct JSFunction
    "JavaScript function code string"
    code::String
end

"""
$(TYPEDEF)

Represents a single JSXGraph element that can be placed on a board.

Each element has a type name (e.g., "point", "line"), parent arguments,
and visual/behavioral attributes that are passed to `board.create()`.

$(TYPEDFIELDS)
"""
struct JSXElement <: AbstractJSXElement
    "JSXGraph element type (e.g., \"point\", \"line\", \"circle\")"
    type_name::String
    "Positional arguments for board.create()"
    parents::Vector{Any}
    "Visual and behavioral attributes"
    attributes::Dict{String,Any}
end

"""
$(SIGNATURES)

Create a JSXGraph element with the given type name, parents, and keyword attributes.
"""
function _create_element(type_name::String, parents, kwargs)
    attrs = resolve_aliases(kwargs)
    attrs = convert_color_values(attrs)
    return JSXElement(type_name, collect(Any, parents), attrs)
end

"""
$(SIGNATURES)

Convert a parent value to its JavaScript string representation.

Handles Numbers, Strings, Vectors/Tuples, JSXElement references, and JSFunction objects.
"""
function parent_to_js(x::Number, elem_ids::Dict)
    return string(x)
end

function parent_to_js(x::String, elem_ids::Dict)
    return JSON.json(x)
end

function parent_to_js(x::AbstractVector, elem_ids::Dict)
    items = [parent_to_js(item, elem_ids) for item in x]
    return "[" * join(items, ",") * "]"
end

function parent_to_js(x::Tuple, elem_ids::Dict)
    items = [parent_to_js(item, elem_ids) for item in x]
    return "[" * join(items, ",") * "]"
end

function parent_to_js(x::JSXElement, elem_ids::Dict)
    id = objectid(x)
    if haskey(elem_ids, id)
        return elem_ids[id]
    end
    error(
        "Element reference not found. Ensure the referenced element is added to the board before elements that depend on it.",
    )
end

function parent_to_js(x::JSFunction, elem_ids::Dict)
    return x.code
end

"""
$(SIGNATURES)

Convert element attributes to a JSON string.
"""
function attrs_to_js(attrs::Dict{String,Any})
    return JSON.json(attrs)
end

# --- Geometric Primitives ---

"""
$(SIGNATURES)

Create a point at coordinates `(x, y)`.
"""
point(x, y; kwargs...) = _create_element("point", (x, y), kwargs)

"""
$(SIGNATURES)

Create a line through two points or defined by other parents.
"""
line(a, b; kwargs...) = _create_element("line", (a, b), kwargs)

"""
$(SIGNATURES)

Create a line segment between two points.
"""
segment(a, b; kwargs...) = _create_element("segment", (a, b), kwargs)

"""
$(SIGNATURES)

Create an arrow from point `a` to point `b`.
"""
arrow(a, b; kwargs...) = _create_element("arrow", (a, b), kwargs)

"""
$(SIGNATURES)

Create a circle with center and radius or point on circle.
"""
function circle(center, radius_or_point; kwargs...)
    _create_element("circle", (center, radius_or_point), kwargs)
end

"""
$(SIGNATURES)

Create an arc from center through two boundary points.
"""
arc(center, p1, p2; kwargs...) = _create_element("arc", (center, p1, p2), kwargs)

"""
$(SIGNATURES)

Create a sector from center through two boundary points.
"""
sector(center, p1, p2; kwargs...) = _create_element("sector", (center, p1, p2), kwargs)

"""
$(SIGNATURES)

Create a polygon through the given vertices.
"""
polygon(points...; kwargs...) = _create_element("polygon", points, kwargs)

"""
$(SIGNATURES)

Create a regular polygon with `n` sides from two points.
"""
function regularpolygon(p1, p2, n; kwargs...)
    _create_element("regularpolygon", (p1, p2, n), kwargs)
end

"""
$(SIGNATURES)

Create an angle defined by three points.
"""
angle(p1, vertex, p2; kwargs...) = _create_element("angle", (p1, vertex, p2), kwargs)

"""
$(SIGNATURES)

Create a conic section through five points.
"""
function conic(p1, p2, p3, p4, p5; kwargs...)
    _create_element("conic", (p1, p2, p3, p4, p5), kwargs)
end

"""
$(SIGNATURES)

Create an ellipse with two foci and a point on the ellipse.
"""
ellipse(f1, f2, p; kwargs...) = _create_element("ellipse", (f1, f2, p), kwargs)

"""
$(SIGNATURES)

Create a parabola with focus and directrix.
"""
function parabola(focus, directrix; kwargs...)
    _create_element("parabola", (focus, directrix), kwargs)
end

"""
$(SIGNATURES)

Create a hyperbola with two foci and a point on the hyperbola.
"""
hyperbola(f1, f2, p; kwargs...) = _create_element("hyperbola", (f1, f2, p), kwargs)

# --- Analytic Elements ---

"""
Helper to convert a function or expression to a JSFunction.
"""
function _to_jsfunction(f::Function)
    return JSFunction(julia_to_js(f))
end

function _to_jsfunction(expr::Expr)
    return JSFunction(julia_to_js(expr))
end

function _to_jsfunction(x)
    return x
end

"""
$(SIGNATURES)

Create a function graph element from a Julia function or expression.
"""
function functiongraph(f; kwargs...)
    jsf = _to_jsfunction(f)
    return _create_element("functiongraph", (jsf,), kwargs)
end

"""
$(SIGNATURES)

Create a parametric curve from `fx(t)`, `fy(t)` over `[t_start, t_end]`.
"""
function curve(fx, fy, t_start, t_end; kwargs...)
    jsfx = _to_jsfunction(fx)
    jsfy = _to_jsfunction(fy)
    return _create_element("curve", (jsfx, jsfy, t_start, t_end), kwargs)
end

"""
$(SIGNATURES)

Create an implicit curve from a function `f(x, y) = 0`.
"""
function implicitcurve(f; kwargs...)
    jsf = _to_jsfunction(f)
    return _create_element("implicitcurve", (jsf,), kwargs)
end

"""
$(SIGNATURES)

Create an inequality region from a line element.
"""
inequality(line_elem; kwargs...) = _create_element("inequality", (line_elem,), kwargs)

"""
$(SIGNATURES)

Create a tangent line at a glider point.
"""
tangent(glider_elem; kwargs...) = _create_element("tangent", (glider_elem,), kwargs)

"""
$(SIGNATURES)

Create a normal line at a glider point.
"""
normal(glider_elem; kwargs...) = _create_element("normal", (glider_elem,), kwargs)

"""
$(SIGNATURES)

Create an integral of a curve between bounds `a` and `b`.
"""
function integral(curve_elem, a, b; kwargs...)
    _create_element("integral", (curve_elem, a, b), kwargs)
end

"""
$(SIGNATURES)

Create the derivative of a curve element.
"""
derivative(curve_elem; kwargs...) = _create_element("derivative", (curve_elem,), kwargs)

"""
$(SIGNATURES)

Create a Riemann sum visualization.
"""
function riemannsum(f, n, type; a=-5, b=5, kwargs...)
    jsf = _to_jsfunction(f)
    return _create_element("riemannsum", (jsf, n, type, a, b), kwargs)
end

"""
$(SIGNATURES)

Create a slope field visualization.
"""
function slopefield(f; kwargs...)
    jsf = _to_jsfunction(f)
    return _create_element("slopefield", (jsf,), kwargs)
end

"""
$(SIGNATURES)

Create a vector field visualization.
"""
function vectorfield(f; kwargs...)
    jsf = _to_jsfunction(f)
    return _create_element("vectorfield", (jsf,), kwargs)
end

# --- Interactive Elements ---

"""
$(SIGNATURES)

Create a slider between positions `pos1` and `pos2` with `range` `[min, start, max]`.
"""
function slider(pos1, pos2, range; kwargs...)
    _create_element("slider", (pos1, pos2, range), kwargs)
end

"""
$(SIGNATURES)

Create a checkbox at position `(x, y)` with the given label.
"""
checkbox(x, y, label; kwargs...) = _create_element("checkbox", (x, y, label), kwargs)

"""
$(SIGNATURES)

Create a text input at position `(x, y)` with initial value and label.
"""
function input(x, y, value, label; kwargs...)
    _create_element("input", (x, y, value, label), kwargs)
end

"""
$(SIGNATURES)

Create a button at position `(x, y)` with label and handler.
"""
function button(x, y, label, handler; kwargs...)
    _create_element("button", (x, y, label, handler), kwargs)
end

"""
$(SIGNATURES)

Create a glider point on a curve element at initial position `(x, y)`.
"""
glider(x, y, curve_elem; kwargs...) = _create_element("glider", (x, y, curve_elem), kwargs)

"""
$(SIGNATURES)

Create a tape measure between two points.
"""
tapemeasure(p1, p2; kwargs...) = _create_element("tapemeasure", (p1, p2), kwargs)

"""
$(SIGNATURES)

Create a text element at position `(x, y)` with the given content.
"""
text(x, y, content; kwargs...) = _create_element("text", (x, y, content), kwargs)

"""
$(SIGNATURES)

Create an image element from a URL at the given corner with dimensions.
"""
image(url, corner, dims; kwargs...) = _create_element("image", (url, corner, dims), kwargs)
