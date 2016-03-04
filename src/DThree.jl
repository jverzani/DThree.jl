#__precompile__(true)
## Code to make writing of d3 javascript d3-like.



module DThree

import Base.getindex, Base.push!

using JSON
using Mustache
using Blink

export asis, @asis_str, D3, browse
export js, loadurl, loadfile


type AsIs
    x
end
asis(x) = AsIs(x)
macro asis_str(x)
    asis(x)
end




## D3 instances can chain commands with interface nearly same as d3.js
## d3.selectAll("p").style("color","#00f").render()
## render passes JavaScript to browser. If you want to assign to variable name, pass as argument.
## If method not defined, then can do something like d3._(:selectAll, "p"). ...
## by default this uses JavaScript d3 object as receiver. This can be changed with d3.receiver("chart"). ...
## arguments are converted via to_json, except:
## * functions are treated as callbacks into julia. These are asynchronous.
## * use asis"x" or asis("x") to treat object "as is". This is needed to quote JavaScript functions
## TODO: PyCall this baby so members can be added from a list of symbols
type D3
    cmd
    _var
    var
    receiver
    eval_js
    render
    _
    __
    select
    selectAll
    data
    datum
    enter
    append
    style
    color
    attr
    text
    domain
    range
    rangeRoundBounds
    scale_linear
    scale_ordinal
    scale_category10
    time_scale
    svg_axis
    svg_line
    svg_area
    scale
    ticks
    tickFormat
    format
    axisLabel
    orient
    call
    max
    transition
    duration
    function D3()
        this = new("d3", nothing)        

        tmp = tempname() * ".html"

        ## for setting var nm = ...
        this.var      = (value::Union{Void, AbstractString}) -> begin this._var = value; this end
        
        ## for setting reciever.meth1(...).meth2. ... where default is d3.
        this.receiver = (value::AbstractString) -> begin this.cmd = value; this end

        ## return JavaScript as string, reset cmd
        this.render = () -> begin
            out = this.cmd
            if !isa(this._var, Void)
                out = "var $(this._var) = " * out * ";"
            end
            this.receiver("d3")
            this.var(nothing)
            return(out)
        end
        this._ = (meth, args...) ->  begin
            cmd = this.cmd
            meth = replace(string(meth), r"_", ".")
            args = map(u -> prep(u), args)
            args = join(args, ", ")
            this.cmd = "$(this.cmd).$meth($args)"
            this
        end
        this.__ = (prop) -> begin # add a property
            this.cmd = "$(this.cmd).$prop"
            this
        end
        ## generate in @eval map meth by replacing _ with symbol(replace("scale_linear", "_", "."))
        this.select    = (args...) -> this._(:select, args...)
        this.selectAll = (args...) -> this._(:selectAll, args...)
        this.data      = (args...) -> this._(:data, args...)
        this.datum     = (args...) -> this._(:datum, args...)
        this.enter     = (args...) -> this._(:enter, args...)
        this.append    = (args...) -> this._(:append, args...)
        this.style     = (args...) -> this._(:style, args...)
        this.color     = (args...) -> this._(:color, args...)
        this.attr      = (args...) -> this._(:attr, args...)
        this.text      = (args...) -> this._(:text, args...)
        this.domain    = (args...) -> this._(:domain, args...)
        this.range     = (args...) -> this._(:range, args...)
        this.rangeRoundBounds     = (args...) -> this._(:rangeRoundBands, args...)
        this.scale_linear = (args...) -> this._("scale.linear", args...)
        this.scale_ordinal = (args...) -> this._("scale.ordinal", args...)
        this.scale_category10 = (args...) -> this._("scale.category10", args...)
        this.time_scale= (args...) -> this._("time.scale", args...)
        this.svg_axis  = (args...) -> this._("svg.axis", args...)
        this.svg_line  = (args...) -> this._("svg.line", args...)
        this.svg_area  = (args...) -> this._("svg.area", args...)
        this.scale     = (args...) -> this._(:scale, args...)
        this.ticks     = (args...) -> this._(:ticks, args...)
        this.tickFormat= (args...) -> this._(:tickFormat, args...)
        this.format    = (args...) -> this._(:format, args...)
        this.axisLabel= (args...) -> this._(:axisLabel, args...)
        this.orient    = (args...) -> this._(:orient, args...)
        this.call      = (args...) -> this._(:call, args...)
        this.max       = (args...) -> this._(:max, args...)
        this.transition= (args...) -> this._(:transition, args...)
        this.duration  = (args...) -> this._(:duration, args...)
        
        this
    end
end



## used for easier? access D3()[:one](2)[:three]("three") ...
getindex(x::D3, i::Symbol) = (args...) -> x._(i, args...)

prep(x::Any) = json(x)
prep(x::AsIs) = string(x.x)
## NEED prep(d3, x::Function) to callback into `julia`
prep(x::D3) = prep(asis(x.render()))




include("colors.jl")
include("display.jl")
include("blink.jl")
#include("plots.jl")
include("plotly.jl")





end ## module
