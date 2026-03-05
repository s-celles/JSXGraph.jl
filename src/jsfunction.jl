# Julia-to-JavaScript conversion

"""
Mapping of Julia math function names to JavaScript `Math.*` equivalents.
"""
const MATH_FUNCTIONS = Dict{Symbol,String}(
    :sin => "Math.sin",
    :cos => "Math.cos",
    :tan => "Math.tan",
    :asin => "Math.asin",
    :acos => "Math.acos",
    :atan => "Math.atan",
    :sinh => "Math.sinh",
    :cosh => "Math.cosh",
    :tanh => "Math.tanh",
    :exp => "Math.exp",
    :log => "Math.log",
    :log10 => "Math.log10",
    :log2 => "Math.log2",
    :sqrt => "Math.sqrt",
    :abs => "Math.abs",
    :floor => "Math.floor",
    :ceil => "Math.ceil",
    :round => "Math.round",
    :sign => "Math.sign",
    :min => "Math.min",
    :max => "Math.max",
)

"""
Mapping of Julia math constants to JavaScript equivalents.
"""
const MATH_CONSTANTS = Dict{Symbol,String}(
    :pi => "Math.PI", :π => "Math.PI", :ℯ => "Math.E"
)

"""
Mapping of known Julia math functions (as `Function` objects) to their symbol names.
"""
const FUNCTION_TO_SYMBOL = Dict{Function,Symbol}(
    sin => :sin,
    cos => :cos,
    tan => :tan,
    asin => :asin,
    acos => :acos,
    atan => :atan,
    sinh => :sinh,
    cosh => :cosh,
    tanh => :tanh,
    exp => :exp,
    log => :log,
    log10 => :log10,
    log2 => :log2,
    sqrt => :sqrt,
    abs => :abs,
    floor => :floor,
    ceil => :ceil,
    round => :round,
    sign => :sign,
    min => :min,
    max => :max,
)

"""
$(SIGNATURES)

Convert a Julia expression to a JavaScript string.

Handles arithmetic operators, math functions (→ `Math.*`), power (→ `Math.pow`),
constants (π → `Math.PI`), and lambda expressions.
"""
function julia_to_js(expr::Expr)
    if expr.head == :call
        return _call_to_js(expr)
    elseif expr.head == :->
        return _lambda_to_js(expr)
    elseif expr.head == :block
        # Strip LineNumberNodes, convert last expression
        exprs = filter(e -> !(e isa LineNumberNode), expr.args)
        return julia_to_js(exprs[end])
    else
        return string(expr)
    end
end

function julia_to_js(s::Symbol)
    if haskey(MATH_CONSTANTS, s)
        return MATH_CONSTANTS[s]
    end
    return string(s)
end

function julia_to_js(n::Number)
    return string(n)
end

function julia_to_js(x::QuoteNode)
    return julia_to_js(x.value)
end

"""
$(SIGNATURES)

Convert a Julia `Function` to a JavaScript function string.

For known math functions (sin, cos, etc.), produces `function(x){return Math.sin(x);}`.
"""
function julia_to_js(f::Function)
    if haskey(FUNCTION_TO_SYMBOL, f)
        sym = FUNCTION_TO_SYMBOL[f]
        js_name = MATH_FUNCTIONS[sym]
        return "function(x){return $(js_name)(x);}"
    end
    error("Cannot convert unknown function $(f) to JavaScript. Use an expression instead.")
end

const INFIX_OPS = Set([:+, :-, :*, :/, :%])

function _call_to_js(expr::Expr)
    func = expr.args[1]

    # Power → Math.pow
    if func == :^
        base = julia_to_js(expr.args[2])
        exp = julia_to_js(expr.args[3])
        return "Math.pow($(base), $(exp))"
    end

    # Unary minus
    if func == :- && length(expr.args) == 2
        arg = julia_to_js(expr.args[2])
        return "-$(arg)"
    end

    # Infix operators
    if func isa Symbol && func in INFIX_OPS
        args_js = [julia_to_js(a) for a in expr.args[2:end]]
        return join(args_js, " $(func) ")
    end

    # Math functions
    if func isa Symbol && haskey(MATH_FUNCTIONS, func)
        js_func = MATH_FUNCTIONS[func]
        args_js = [julia_to_js(a) for a in expr.args[2:end]]
        return "$(js_func)($(join(args_js, ", ")))"
    end

    # Generic function call
    args_js = [julia_to_js(a) for a in expr.args[2:end]]
    return "$(func)($(join(args_js, ", ")))"
end

function _lambda_to_js(expr::Expr)
    params = expr.args[1]
    body = expr.args[2]

    # Handle single parameter
    param_str = if params isa Symbol
        string(params)
    elseif params isa Expr && params.head == :tuple
        join([string(p) for p in params.args], ", ")
    else
        string(params)
    end

    body_js = julia_to_js(body)
    return "function($(param_str)){return $(body_js);}"
end
