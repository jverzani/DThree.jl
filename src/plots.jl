## module Plots 

## Deprecated...

## use nvd3.org javascript to make graphics
## pluses: easy to make
## minuses: not really composable. For example, no way to add scatter and plot, plot and plot,...
## so no plot! type functions

## Deprecate... using Plots is more flexible

export tickFormat
export plot, scatter


## Type to hold D3 commands
type D3Plot
    q
    receiver
    D3Plot() = new([""], "chart")
end

# Co-opt the REPL display
Base.display(::Base.REPL.REPLDisplay, ::MIME"text/plain", p::D3Plot) = display(_display, p)
function Base.writemime(io::IO, ::MIME"text/html", x::D3Plot)
    tpl = Mustache.template_from_file(Pkg.dir("DThree", "tpl", "d3.html"))
    Mustache.render(io, tpl, Dict(:script=>get(x), :title=>"Graphic"))
end


function browse(x::D3Plot; style="")
    f = tempname() * ".html"
    io = open(f, "w")
    writemime(io, "text/html", x)
    close(io)
    open_browser_window(f)
end



import Base.push!, Base.get, Base.*

push!(x::D3Plot, cmd::AbstractString) = push!(x.q, cmd)
push!(x::D3Plot, cmd::D3) = push!(x.q, cmd.render())
push!(x::D3Plot) = cmd -> push!(x, cmd)  ## d3... |> push!(q)
## p * cmd; not p = p*cmd
*(p::D3Plot, x::D3) = push!(p, x.render())
*(p::D3Plot, x::AbstractString) = push!(p, x)


function nv_addGraph(x::D3Plot)
    x.q = ["", "nv.addGraph(function() {", x.q[2:end]..., "nv.utils.windowResize(chart.update)", "return chart;});" ]
end

function get(x::D3Plot)
    if length(x.q) > 1
        out = join(x.q[2:end], "\n")
    else
        out = ""
    end
    out
end
clear(x::D3Plot) =  x.q=[""]

_recycle(xs, n) = [xs[mod1(i, length(xs))] for i in 1:n]

## return tickFormat based on variable type
"""

Customize format of ticks on axis.

Example `plot(..., tickformat = tickFormat(1.0))`
"""
tickFormat(x::Real) = D3().format(",.02f")
tickFormat(x::Integer) = D3().format(",.r")
tickFormat(x::DateTime) = asis("function(d) { return d3.time.format('%x')(new Date(d))}")

tickFormat{T}(x::Vector{T}) = tickFormat(x[1])
tickFormat{T}(x::DataArray{T}) = tickFormat(x[1])
tickFormat(x) = tickFormat(collect(x))



## do we convert time to seconds for display? Only if a time
iftime(x::Any) = x
iftime(x::DateTime) = (x - DateTime(1970,1,1,0,0,0)).value
iftime{T}(x::DataArray{T}) = iftime(x[1])


## Some utilities
function _labels(q::D3Plot;
                main::AbstractString="",
                x::AbstractString="",
                y::AbstractString="")

    d3 = D3()
    d3.receiver(q.receiver).__("xAxis").axisLabel(x)     |> push!(q)
    d3.receiver(q.receiver).__("yAxis").axisLabel(y)     |> push!(q)
end

## Set tickFormat for axis based on element type.
## use `nothing` to not customize the format
function _tickFormat(q::D3Plot, x=nothing, y=nothing)
    d3 = D3()
    x != nothing && d3.receiver(q.receiver).__("xAxis").tickFormat(x)     |> push!(q)
    y != nothing && d3.receiver(q.receiver).__("yAxis").tickFormat(y)     |> push!(q)
end

"show legend?"
legend(q::D3Plot, flag::Bool=true) = D3()._("showLegend",flag) |> push!(q)

"use interactive guideline"
guideline(q::D3Plot, flag::Bool=true) = D3()._("useInteractiveGuideline",flag) |> push!(q)


function _showDist(q::D3Plot, x::Bool=true, y::Bool=true)
    D3()._("showDistX",x)._("showDistY",y) |> push!(q)
end

function _margins(q::D3Plot, d::Dict)
    e = Dict()
    for key in [:left, :top, :right, :bottom]
        if (haskey(d, key) && d[key] != nothing) e[key] = d[key] end
    end
    
    length(e) > 0 && D3()._("margin", JSON.json(e)) |> push!(q)

end



datum(q::D3Plot, d::AsIs) = D3().data(d) |> push!(q)

function dict_from_dfrow(df::DataFrame)
    d = Dict{AbstractString, Any}()
    for nm in names(df)
        d[string(nm)] = df[1,nm]
    end
    d
end

## values from a data frame
values_from_df(df::DataFrame) = [dict_from_dfrow(df[i,:]) for i in 1:size(df)[1]]

##################################################


## mave a variable `var` of type `models.lineChart`. Other values pushed onto `var`
function line_chart(q::D3Plot, var="chart", receiver="nv")
    D3().var(var).receiver("nv").__("models")._("lineChart")  |> push!(q)
end


## create data for lineType
## basically push everything down to data frame stye which has
## d,:f to split into groups and d for just a single line.

## dataframe. No grouping variable
## legend and colors are scalar
function create_datum(::Type{Val{:lineType}},
                      d::DataFrame,
                      f::Void,
                      vars=[:x, :y];
                      legend=":x",
                      color="blue",
                      area::Bool=false
                      kwargs...)



    data = [Dict(:values=>values_from_df(d), 
	         :key=>legend, 
	         :color=>color,
                 :area=>area)
            ]

            
    data |> JSON.json |> asis
end

## dataframe with grouping by f
function create_datum(::Type{Val{:lineType}},
                      d::DataFrame,
                      f::Symbol,
                      vars=[:x, :y];
                      legend=Dict(),  # d[level] = "text"
                      colors=Dict(),  # d[level] = :color,
                      area = Dict()
                      kwargs...)   
    ## who should group_by, but instead do this manually

    fs = d[f]
    levels = sort(unique(fs))

    if isa(legend, Vector)
        legs = copy(legend)
        legend = Dict()
        [legend[level] = legs[mod1(i, length(legs))] for (i, level) in enumerate(levels)]
    else
        for level in levels
            if !haskey(legend, level)  legend[level] = string(level)  end
        end
    end

    if isa(colors, Vector)
        cols = copy(colors)
        colors = Dict()
        [colors[level] = cols[mod1(i, length(cols))] for (i, level) in enumerate(levels)]
    else
        for (i, level) in enumerate(levels)
            if !haskey(colors, level) colors[level] = fifty_shades(i)  end
        end
    end

    if isa(area, Vector)
        ars = copy(area)
        area = Dict()
        [area[level] = ars[mod1(i, length(cols))] for (i, level) in enumerate(levels)]
    else
        for (i, level) in enumerate(levels)
            if !haskey(area, level) area[level] = false  end
        end
    end


    
    data = [Dict(:values=>values_from_df(d[fs .== level, vars]), 
	         :key=>legend[level], 
	         :color=>colors[level],
                 :area => area[level]
                 )
            for level in levels
            ]

            
    data |> JSON.json |> asis
end


function create_datum{T<:Real, S<:Real}(::Type{Val{:lineType}},
                                        xs::Vector{T},
                                        ys::Vector{S};
                                        kwargs...
                                        )

    d = DataFrame(x=xs, y=ys)
    create_datum(Val{:lineType},
                 d, nothing, [:x, :y];
                 kwargs...)

end

## lineTtype for multiple values specified with a factor
## legend and cols are dictionaries with keys as factors
function create_datum{T<:Real, S<:Real}(::Type{Val{:lineType}},
                                        xs::Vector{T}, ys::Vector{S},
                                        fs::Vector;
                                        kwargs...
                                        )

    d = DataFrame(x=xs, y=ys, f=fs)

    create_datum(Val{:lineType},
                 d, :f, [:x, :y];
                 kwargs...)
                 
end

## create data from functions
## lineType should this be a parameter to dispatch on?
function create_datum(::Type{Val{:lineType}},
                      fs::Vector{Function},
                      from::Real, to::Real;
                      kwargs...
                      )
    
    
    m = length(fs)
    n = 151

    xs = linspace(from, to, n)
    d = DataFrame(x=repmat(xs, m))
    d[:y] = vcat([map(f, xs) for f in fs]...)
    d[:f] = repmat(map(string, fs), 1, n)'[:]


    
    create_datum(Val{:lineType},
                 d, :f, [:x, :y];
                 kwargs...)
    
end


## parametric t -> (f, g)
function create_datum(::Type{Val{:lineType}},
                      f::Function, g::Function,
                      from::Real, to::Real;
                      kwargs...
                      )

    ts = linspace(from, to, 250)
    xs = map(f, ts)
    ys = map(g, ts)

    create_datum(Val{:lineType}, xs, ys;
                 kwargs...)
end


## Main function
## `args...`, `kwargs...` passed to `create_datum`
## other arguments for customizing graphic
function _line_chart(args...;
                     selector="#chart svg",
                     labels=["x", "y"],
                     tickformat = [tickFormat(1.0), tickFormat(1.0)],
                     margins=Dict(:left=>nothing, :top=>nothing, :right=>nothing, :bottom=>nothing),
                     raise::Bool=true,
                     kwargs...)
    
   
    ## produce data from fs, return value in asis
    ## legend and color values are embedded in the data
    data = create_datum(Val{:lineType}, args...; kwargs...)
    
    d3 = D3()
    q = D3Plot()

    ## http://nvd3.org/ghpages/line.html
    line_chart(q)
    _labels(q, x=labels[1], y=labels[2])
    _tickFormat(q, tickformat...)
    _margins(q, margins)
    

    
    d3.select(selector).datum(data).transition().duration(500).call(asis("chart")) |> push!(q)

    nv_addGraph(q)
    raise && scf()
    q
end



## plot interface

# plot(xs, ys)
# plot(xs, ys, fs)
# plot(fn, a, b)
# plot(fns, a, b)
# plot(d, f, labels=[:x, :y])

"""

Plot a dot-to-dot graph. Can have several interfaces:

`plot(xs, ys)`:    plot `(x,y)`, connect dots
`plot(xs, ys, fs)` plot `(x,y)` for each group defined by `fs`, connect dots
`plot(f, from, to)` plot `y =f(x)` over domain `[from, to]`.
`plot([fs], from to)` plot `y=f_i(x)` over domain `[from, to]` for each `f` in `fs`
`plot(d, nothing, vars=[:x, :y])` plot `xs` `ys` defined in data frame `d`
`plot(d, :f, vars=[:x, :y])` group data by `:f`, then for each group make line chart.

The multiple line chart functions take `legend` and `colors` as a dictionary or vector of suitable length.

The single line hcart functions, take `legend` and `colors` as scalars.

"""
function plot(xs::Union{Range, Vector}, ys::Union{Range, Vector};
              labels=["x", "y"],
              selector="#chart svg",
              kwargs...)
    _line_chart(collect(xs), collect(ys);
                labels=labels, selector=selector,
                kwargs...)
end


function plot(xs::Union{Range, Vector}, ys::Union{Range, Vector}, fs::Vector;
              labels=["x", "y"],
              selector="#chart svg",
              kwargs...
              )

    _line_chart(collect(xs), collect(ys), fs;
                labels=labels, selector=selector,
                kwargs...)
end


plot(f::Function, from::Real, to::Real; kwargs...) = plot([f], from, to; kwargs...)

function plot(fs::Vector, from::Real, to::Real;
              labels=["x", "y"],
              selector="#chart svg",
              kwargs...
              )

    _line_chart(fs, from, to;
                labels=labels,
                selector=selector,
                kwargs...)
end

## parametric plot
function plot(f::Function, g::Function, from::Real, to::Real;
              labels=["x", "y"],
              selector="#chart svg",
              kwargs...)
    
      _line_chart(d, f, vars;
                labels=labels,
                selector=selector,
                kwargs...)
end

function plot(d::DataFrame, f::Union{Void, Symbol}, vars=[:x, :y];
              labels=["x", "y"],
              selector="#chart svg",
              kwargs...)

    _line_chart(d, f, vars;
                labels=labels,
                selector=selector,
                kwargs...)
end

function plot(f::Function, g::Function, a::Real, b::Real;
              labels=["x", "y"],
              selector="#chart svg",
              kwargs...)
    _line_chart(f, g, a, b;
                labels=labels,
                selector=selector,
                kwargs...)
end

##################################################

function scatter_chart(q::D3Plot, var="chart", receiver="nv")
    D3().var(var).receiver("nv").__("models")._("scatterChart")  |> push!(q)
end


## scatter chart
## shapes = ['circle', 'cross', 'triangle-up', 'triangle-down', 'diamond', 'square'],

## dataframe. No grouping variable
## legend and colors are scalar
function create_datum(::Type{Val{:scatterType}},
                      d::DataFrame,
                      f::Void,
                      vars=[:x, :y];
                      legend=":x",
                      colors=[:blue],
                      shapes=[:circle]
                      kwargs...)



    data = [Dict(:values=>values_from_df(d), 
	         :key=>legend, 
	         :color=>color,
                 :area=>area)
            ]

            
    data |> JSON.json |> asis
end

## dataframe with grouping by f
function create_datum(::Type{Val{:lineType}},
                      d::DataFrame,
                      f::Symbol,
                      vars=[:x, :y];
                      legend=Dict(),  # d[level] = "text"
                      colors=Dict(),  # d[level] = :color,
                      area = Dict()
                      kwargs...)   
    ## who should group_by, but instead do this manually

    fs = d[f]
    levels = sort(unique(fs))

    if isa(legend, Vector)
        legs = copy(legend)
        legend = Dict()
        [legend[level] = legs[mod1(i, length(legs))] for (i, level) in enumerate(levels)]
    else
        for level in levels
            if !haskey(legend, level)  legend[level] = string(level)  end
        end
    end

    if isa(colors, Vector)
        cols = copy(colors)
        colors = Dict()
        [colors[level] = cols[mod1(i, length(cols))] for (i, level) in enumerate(levels)]
    else
        for (i, level) in enumerate(levels)
            if !haskey(colors, level) colors[level] = fifty_shades(i)  end
        end
    end

    if isa(area, Vector)
        ars = copy(area)
        area = Dict()
        [area[level] = ars[mod1(i, length(cols))] for (i, level) in enumerate(levels)]
    else
        for (i, level) in enumerate(levels)
            if !haskey(area, level) area[level] = false  end
        end
    end


    
    data = [Dict(:values=>values_from_df(d[fs .== level, vars]), 
	         :key=>legend[level], 
	         :color=>colors[level],
                 :area => area[level]
                 )
            for level in levels
            ]

            
    data |> JSON.json |> asis
end






function create_datum{T<:Real,S<:Real}(::Type{Val{:scatterType}},
                                       xs::Vector{T},
                                       ys::Vector{S};
                                       legend="y",
                                       colors=["blue"],
                                       sizes=[1],
                                       shapes=["circle"]
                                       )

    
    ## recycle colors, sizes, shapes if not arrays
    colors = recycle(colors, length(xs))
    sizes  = recycle(sizes, length(xs))
    shapes = recycle(shapes, length(xs))

    d = DataFrame(x=xs, y=ys, color=colors, size=sizes, shape=shapes)
    data = [Dict(:values => values_from_df(d),
                 :key => legend)]
    
    data |> JSON.json |> asis
end


function create_datum(::Type{Val{:scatterType}},
                      d::DataFrame,
                      f::Void;
                      vars=[1,2], #[:x, :y], ...
                      color=["blue"],
                      sizes=[1],
                      shapes=["circle"],
                      kwargs...
                      )
    m = size(d)[1]

    colors = _recycle(color, m)
    sizes = _recycle(sizes, m)
    shapes = _recycle(shapes, m)
    
    df = DataFrame()
    df[:x] = d[vars[1]]
    df[:y] = d[vars[2]]
    df[:color] = colors
    df[:size] = sizes
    df[:shape] = shapes
    
    
    data = [Dict(
                :color  => color,
                :values => [values_from_df(df)]
                )]
    data |> JSON.json |> asis
end


function create_datum(::Type{Val{:scatterType}},
                      d::DataFrame,
                      f::Symbol;
                      vars=[1,2], #[:x, :y], ...
                      legend=AbstractString[],
                      colors=[],
                      sizes=[],
                      shapes=[]
                      )


    df = DataFrame()
    df[:x] = d[vars[1]]
    df[:y] = d[vars[2]]
    
    levels = sort(unique(d[f]))
    nlevels = length(levels)

    # group attributes
    colors = length(colors) == 0 ? map(fifty_shades, 1:nlevels)  : _recycle(colors, nlevels)
    sizes  = length(sizes)  == 0 ? [1 for _ in 1:nlevels]        : _recycle(sizes, nlevels)
    shapes = length(shapes) == 0 ? ["circle" for _ in 1:nlevels] : _recycle(shapes, nlevels)
    legend = length(legend) == 0 ? [string(_) for _ in levels]   : _recycle(legend, nlevels)
    

    data = [Dict(:values => [Dict(:x=>d[d[:f] .== level, vars[1]][j],
                                 :y=>d[d[:f] .== level, vars[2]][j],
                                 :color => colors[i],
                                 :shape => shapes[i],
                                 :size => sizes[i]) for j in 1:sum(d[:f] .== level)],
                 :key    => legend[i])
            for (i, level) in enumerate(levels)]
    
    data |> JSON.json |> asis

end


## DRY THIS UP: scatter and line differe just by call to a {val}
function _scatter_chart(args...;
               selector="#chart svg",
               labels=["x", "y"],
               tickformat = [tickFormat(1.0), tickFormat(1.0)],
               margins=Dict(:left=>nothing, :top=>nothing, :right=>nothing, :bottom=>nothing),
               kwargs...)

   
    ## produce data from fs, return value in asis
    ## legend and color values are embedded in the data
    data = create_datum(Val{:scatterType}, args...; kwargs...)
    
    d3 = D3()
    q = D3Plot()
    
    ## http://nvd3.org/ghpages/line.html
    scatter_chart(q)
    _labels(q, x=labels[1], y=labels[2])
    _tickFormat(q, tickformat...)
    _margins(q, margins)
    _showDist(q, true, true)
    

    
    d3.select(selector).datum(data).transition().duration(500).call(asis("chart")) |> push!(q)

    nv_addGraph(q)
    q
end

               
# scatter(xs, ys)
# scatter(xs, ys, fs)
# scatter(d, f, labels=[:x,:y])

function scatter(xs::Union{Range, Vector}, ys::Union{Range, Vector};
                 labels=["x", "y"],
                 selector="#chart svg",
                 legend="y",
                 colors="blue",
                 kwargs...
                 )
    
    _scatter_chart(collect(xs), collect(ys);
                   labels=labels, selector=selector,
                   legend=legend, colors=colors,
                   kwargs...)
end



## scatterChart. 
## data frame with columns x, y and  grouping variable. Also can have columns shape, size
scatterChart(x::DataFrame; args...)  = scatterChart(x, nothing, args...)
function scatterChart(x::DataFrame, f::Union{Void, Symbol};
                      selector = "#chart svg", # in web template
                      labels=nothing,    #  axis
                      legend=nothing,    # when grouping
                      colors=nothing
                      )

    ## get data from x
    function df_to_data(x::Union{DataFrame, SubDataFrame};
                        key=nothing, color=nothing)
        function do_row(i)
            a = Dict(:x => iftime(x[i,1]), :y => x[i, 2]) # now add size and shape?
##            a["size"] = haskey(x[1,:], "size") ? x[1,"size"] : 0.5
##            if haskey(x[1,:], "shape")
##                shape = x[1,"shape"]
##                a[:shape] = isa(shape, Integer) ? shapes[1 + shape % length(shapes)] : shape
##            end
            a
        end
        
        key = (key == nothing ? "group" : key)
        color = (color == nothing ? "#ff00ff" : color)

       Dict(:key=>key,
        :color=> color,
        :values=>[do_row(i) for i in 1:nrow(x)]
       )
    end


    if isa(f, Void)
         data = [df_to_data(x)] |> JSON.json |> asis
    else
        gp = groupby(x, f)
        ## need colors, legend key, ...
        if isa(legend, Void)
            legend = [gp[i][1,f] for i in 1:length(gp)]
        end
        if isa(colors, Void)
            colors = map(fifty_shades, 1:length(gp))
        end
            
        data = [df_to_data(gp[i], key=legend[i], color=colors[i]) for i in 1:length(gp)] |> JSON.json |> asis
    end

    labels = (isa(labels, Void) ? names(x)[1:2] : labels)

    d3 = D3()
    q = D3Plot()

    ## http://nvd3.org/ghpages/scatter.html
    d3.var("chart").receiver("nv")._("models.scatterChart")._("showDistX", true)._("showDistY",true).color(D3().scale_category10().range()) |> push!(q)
    d3.receiver("chart.xAxis").axisLabel(labels[1]).tickFormat(tickFormat(x[1])) |> push!(q)
    d3.receiver("chart.yAxis").axisLabel(labels[2]).tickFormat(tickFormat(x[2])) |> push!(q)
    d3.select(selector).datum(data).transition().duration(500).call(asis("chart")) |> push!(q)

    nv_addGraph(q)
    q
end


function barChart{S <: Real, T <: AbstractString}(xs::Vector{S}, labels::Vector{T};
                                          selector = "#chart svg", # in web template
                                          colors=nothing, #  which are needed?
                                          legend=nothing)

    if isa(legend, Void) legend = "Nothing" end
    
    data = [Dict(:key =>legend,
             :values => [Dict(:value=>iftime(x), :label => label) for (x,label) in zip(xs, labels)]
                 )] |> JSON.json |> asis
    
    
    d3 = D3()
    q = D3Plot()

    ## http://nvd3.org/ghpages/discreteBar.html
    d3.var("chart").receiver("nv")._("models.discreteBarChart").
    _("x", asis("function(d) {return d.label}")).
    _("y", asis("function(d) {return d.value}"))[:staggerLabels](true)[:tooltips](false)[:showValues](true)  |> push!(q)

  
    d3.select(selector).datum(data).transition().duration(500).call(asis("chart"))  |> push!(q)

    nv_addGraph(q)
    q
end

## x =DataFrame(xvar=.., yvar=..., ..., f=factor)
function stackedAreaChart(x::DataFrame, f::Symbol;
                          selector="#chart svg",
                          labels = nothing
                          )

    gp = groupby(x, f)
    legend = [gp[i][1,f] for i in 1:length(gp)]

    
    data = [Dict(:key => legend[i],
             :values => [[iftime(x),y] for (x,y) in zip(gp[i][1], gp[i][2])]
            ) for i in 1:length(gp)] |> JSON.json |> asis


    
    d3 = D3()
    q = D3Plot()

    ## http://nvd3.org/ghpages/stackedArea.html
    d3.var("chart").receiver("nv")._("models.stackedAreaChart").
    _("x", asis("function(d) {return d[0]}")).
    _("y", asis("function(d) {return d[1]}"))[:clipEdge](true)  |> push!(q)

    d3.receiver("chart.xAxis")[:showMaxMin](false).tickFormat(tickFormat(gp[1][1][1])) |> push!(q)
    d3.receiver("chart.yAxis").tickFormat(tickFormat(gp[1][2][1])) |> push!(q)
    d3.select(selector).datum(data).transition().duration(500).call(asis("chart")) |> push!(q)

    
    nv_addGraph(q)
    q

end


## end (modlue)
