## BlinkDisplay
##
## Use Blink for a standalone display
## The following window management is 
## shamelessly copied from Tim Holy's GadflyDisplay in Immerse.jl

## closefig with mouse needs a callback...
## closefig should decrement list.

export figure, scf, gcf, closefig, closeall
export figure_size, figure_position, figure_raise, figure_floating, figure_title, figure_title!

type BlinkDisplay <: Display
    figs::Dict{Int,Blink.AtomShell.Window}
    fig_order::Vector{Int}
    current_fig::Int
    next_fig::Int

    BlinkDisplay() = new(Dict{Int,Blink.AtomShell.Window}(), Int[], 0, 1)
end

const _display = BlinkDisplay()


"""
`figure(;name="Figure \$n", width=400, height=400)` creates a new
figure window for displaying plots.

`figure(n)` raises the `n`th figure window and makes it the current
default plotting window, and returns the
"""
function figure(;name::AbstractString="Figure $(nextfig(_display))",
                 width::Integer=660,    # TODO: make configurable
                height::Integer=500)
    i = nextfig(_display)
    w = Blink.Window(Blink.@d(:show => false))
    empty_page(w)
    size(w, width, height)
    title(w, name)
    addfig(_display, i, w)
    front(w)
    w
end

function figure(i::Integer; displayfig::Bool = true)
    switchfig(_display, i)
    w = curfig(_display)
    front(w)
    w
end


function addfig(d::BlinkDisplay, i::Int, fig)
    @assert !haskey(d.figs,i)
    d.figs[i] = fig
    push!(d.fig_order, i)
    while haskey(d.figs,d.next_fig)
        d.next_fig += 1
    end
    d.current_fig = i
end

hasfig(d::BlinkDisplay, i::Int) = haskey(d.figs,i)

function switchfig(d::BlinkDisplay, i::Int)
    haskey(d.figs,i) && (d.current_fig = i)
end

function getfig(d::BlinkDisplay, i::Int)
    haskey(d.figs,i) ? d.figs[i] : error("no figure with index $i")
end

function curfig(d::BlinkDisplay)
    cur = d.current_fig
    if !active(d.figs[cur])
        cur = cur + 1
        cur > length(d.figs) && return figure()
    end
    d.figs[cur]
end

## keep trying, but not if not alive
function nextfig(d::BlinkDisplay)
    i = d.next_fig
    !haskey(d.figs, i) && return i
    while(!active(d.figs[i]))
        i = i + 1
        i > length(d.figs) && break
    end
    i
end

function dropfig(d::BlinkDisplay, i::Int)
    haskey(d.figs,i) || return
    delete!(d.figs, i)
    splice!(d.fig_order, findfirst(d.fig_order,i))
    d.next_fig = min(d.next_fig, i)
    d.current_fig = isempty(d.fig_order) ? 0 : d.fig_order[end]
end

gcf() = _display.current_fig

"`scf()` (\"show current figure\") raises (makes visible) the current figure"
scf() = gcf() > 0 && front(figure(gcf()))


"""


`closefig(n)` closes the `n`th figure window.

`closefig()` closes the current figure window.
"""
closefig() = closefig(_display.current_fig)

function closefig(i::Integer)
    ## XXX Should closefig remove from _display? Clear up Resources XXX
    fig = getfig(_display,i)
    close(fig)
    _display.current_fig = _display.next_fig
    _display.next_fig = _display.current_fig  + 1
end

"`closeall()` closes all existing figure windows."
closeall() = (map(closefig, keys(_display.figs)); nothing)

## Some Blink specific things we can do to windows
"Adjust size of figure, defaulting to current one"
figure_size(w::Integer, h::Integer, figure_number=gcf()) = size(figure(figure_number), w,h)

"set position of figure"
figure_position(x::Integer, y::Integer, figure_number=gcf()) = position(figure(figure_number), x, y)

"Raise figure"
figure_raise(figure_number=gcf()) = front(figure(figure_number))

"Set if figure is always on top."
figure_floating(flag::Bool=true, figure_number=gcf()) = floating(figure(figure_number), flag)

"Set title of figure"
figure_title(figure_number=gcf()) = title(figure(figure_number))
figure_title!(str::AbstractString, figure_number=gcf()) = title(figure(figure_number), str)

##################################################



function Base.display(d::BlinkDisplay, plt)
    isempty(d.figs) && figure()
    ## need to sleep or make asychronous...
    w = curfig(d)
    scf()
    
    code = "Plotly.newPlot(PLOT, $(Plots.get_series_json(plt)), $(Plots.get_plot_json(plt)));"
    Blink.js(w, DThree.JSString(code))
end



## Make a web page
## from Plots.jl
function open_browser_window(filename::AbstractString)
    @osx_only   return run(`open $(filename)`)
    @linux_only return run(`xdg-open $(filename)`)
    @windows_only return run(`$(ENV["COMSPEC"]) /c start $(filename)`)
    warn("Unknown OS... cannot open browser window.")
end



