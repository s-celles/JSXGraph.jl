# Board composition operators

"""
$(SIGNATURES)

Add one or more elements to a board (mutating). Returns the board.
"""
function Base.push!(board::Board, elem::AbstractJSXElement)
    push!(board.elements, elem)
    return board
end

function Base.push!(board::Board, elems::AbstractJSXElement...)
    for elem in elems
        push!(board.elements, elem)
    end
    return board
end

"""
$(SIGNATURES)

Create a new board with the element added (non-mutating).

The original board is unchanged.
"""
function Base.:+(board::Board, elem::AbstractJSXElement)
    new_elements = copy(board.elements)
    push!(new_elements, elem)
    return Board(board.id, new_elements, copy(board.options))
end

"""
$(SIGNATURES)

Create a board with a function graph in a single call.

# Arguments
- `f`: Julia function or expression to plot
- `domain`: x-axis range as `(xmin, xmax)`
- Additional keyword arguments are passed to the `functiongraph` element
"""
function plot(f, domain::Tuple{Real,Real}; kwargs...)
    xmin, xmax = domain
    if xmin == xmax
        throw(ArgumentError("Domain must have non-zero width, got ($xmin, $xmax)"))
    end
    board = Board(""; xlim=(xmin, xmax))
    fg = functiongraph(f; kwargs...)
    push!(board, fg)
    return board
end
