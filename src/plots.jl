## return tickFormat based on variable type
tickFormat(x::Real) = D3().format(",.02f")
tickFormat(x::Integer) = D3().format(",.r")
tickFormat(x::CalendarTime) = I("function(d) { return d3.time.format('%x')(new Date(d))}")

tickFormat{T}(x::Vector{T}) = tickFormat(x[1])
tickFormat{T}(x::DataArray{T}) = tickFormat(x[1])

## do we convert time to seconds for display? Only if a time
iftime(x::Any) = x
iftime(x::CalendarTime) = x.millis
iftime{T}(x::DataArray{T}) = iftime(x[1])





## A functionPlot
## pass in vector of functions
## returns a D3Plot object for displaying through browse
function functionChart(fs::Vector{Function},from::Real, to::Real;
                       selector = "#chart svg", # in web template
                       labels=nothing,    # ["x", "y"]
		       legend=nothing,    # map(string, fs)
		       colors=nothing)    # from gray scale
    
   

    if isa(labels, Nothing)
        labels = ["x","y"]
    end
    if isa(legend, Nothing)
        legend =  map(u -> replace(u, "# ", ""), map(string, fs))
    end
    if isa(colors, Nothing)
        ## need better choice...
        ind = linspace(5, 45, length(fs)) | ifloor
        colors = fifty_shades_of_gray[ind]
    end

    ## produce data from fs, return value in I
    x = linspace(from, to, 250)
    data = [{values=>[{"x"=>x,"y"=>fs[i](x)} for x in x], 
	     "key"=>legend[i], 
	     "color"=>colors[i]} for i in 1:length(fs)
            ] | JSON.to_json | I
    
    d3 = D3()
    q = D3Plot()

    ## http://nvd3.org/ghpages/line.html
    q * d3.var("chart").receiver("nv")._("models.lineChart")
    q * d3.receiver("chart.xAxis").axisLabel(labels[1]).tickFormat(tickFormat(x))
    q * d3.receiver("chart.yAxis").axisLabel(labels[2]).tickFormat(tickFormat(x))
    q * d3.select(selector).datum(data).transition().duration(500).call(I("chart"))

    nv_addGraph(q)
    q
end

## plot interface
plot(f::Function, a::Real, b::Real, args...) = functionChart([f], a, b, args...)
plot{T <: Function}(fs::Vector{T}, a::Real, b::Real, args...) = functionChart(fs, a, b, args...)
    




## scatterChart. 
## data frame with columns x, y and  grouping variable. Also can have columns shape, size
scatterChart(x::DataFrame; args...)  = scatterChart(x, nothing, args...)
function scatterChart(x::DataFrame, f::Union(Nothing, String);
                      selector = "#chart svg", # in web template
                      labels=nothing,    #  axis
                      legend=nothing,    # when grouping
                      colors=nothing
                      )

    ## get data from x
    function df_to_data(x::Union(DataFrame, SubDataFrame);
                        key=nothing, color=nothing)
        function do_row(i)
            a = {:x => iftime(x[i,1]), :y => x[i, 2]} # now add size and shape?
            a["size"] = haskey(x[1,:], "size") ? x[1,"size"] : 0.5
            if haskey(x[1,:], "shape")
                shape = x[1,"shape"]
                a[:shape] = isa(shape, Integer) ? shapes[1 + shape % length(shapes)] : shape
            end
            a
        end
        
        key = (key == nothing ? "group" : key)
        color = (color == nothing ? "#ff00ff" : color)

       {:key=>key,
        :color=> color,
        :values=>[do_row(i) for i in 1:nrow(x)]
       }
    end


    if isa(f, Nothing)
         data = [df_to_data(x)] | JSON.to_json | I
    else
        gp = groupby(x, f)
        ## need colors, legend key, ...
        if isa(legend, Nothing)
            legend = [gp[i][1,f] for i in 1:length(gp)]
        end
        if isa(colors, Nothing)
            ind = linspace(5, 45, length(gp)) | ifloor
            colors = fifty_shades_of_gray[ind]
        end
            
        data = [df_to_data(gp[i], key=legend[i], color=colors[i]) for i in 1:length(gp)] | JSON.to_json | I
    end

    labels = (isa(labels, Nothing) ? colnames(x)[1:2] : labels)

    d3 = D3()
    q = D3Plot()

    ## http://nvd3.org/ghpages/scatter.html
    q * d3.var("chart").receiver("nv")._("models.scatterChart")._("showDistX", true)._("showDistY",true).color(D3().scale_category10().range())
    q * d3.receiver("chart.xAxis").axisLabel(labels[1]).tickFormat(tickFormat(x[1]))
    q * d3.receiver("chart.yAxis").axisLabel(labels[2]).tickFormat(tickFormat(x[2]))
    q * d3.select(selector).datum(data).transition().duration(500).call(I("chart"));

    nv_addGraph(q)
    q
end


function barChart{S <: Real, T <: String}(xs::Vector{S}, labels::Vector{T};
                                          selector = "#chart svg", # in web template
                                          colors=nothing, #  which are needed?
                                          legend=nothing)

    if isa(legend, Nothing) legend = "Nothing" end
    
    data = [{:key =>legend,
             :values => [{:value=>iftime(x), :label => label} for (x,label) in zip(xs, labels)]
             }] | JSON.to_json | I
    
    
    d3 = D3()
    q = D3Plot()

    ## http://nvd3.org/ghpages/discreteBar.html
    q * d3.var("chart").receiver("nv")._("models.discreteBarChart").
    _("x", I("function(d) {return d.label}")).
    _("y", I("function(d) {return d.value}"))[:staggerLabels](true)[:tooltips](false)[:showValues](true)

  
    q * d3.select(selector).datum(data).transition().duration(500).call(I("chart"));

    nv_addGraph(q)
    q
end

## x =DataFrame(xvar=.., yvar=..., ..., f=factor)
function stackedAreaChart(x::DataFrame, f::String;
                          selector="#chart svg",
                          labels = nothing
                          )

    gp = groupby(x, f)
    legend = [gp[i][1,f] for i in 1:length(gp)]

    
    data = [{:key => legend[i],
             :values => [[iftime(x),y] for (x,y) in zip(gp[i][1], gp[i][2])]
            } for i in 1:length(gp)] | JSON.to_json | I


    
    d3 = D3()
    q = D3Plot()

    ## http://nvd3.org/ghpages/stackedArea.html
    q * d3.var("chart").receiver("nv")._("models.stackedAreaChart").
    _("x", I("function(d) {return d[0]}")).
    _("y", I("function(d) {return d[1]}"))[:clipEdge](true)

    q * d3.receiver("chart.xAxis")[:showMaxMin](false).tickFormat(tickFormat(gp[1][1][1]))
    q * d3.receiver("chart.yAxis").tickFormat(tickFormat(gp[1][2][1]))
    q * d3.select(selector).datum(data).transition().duration(500).call(I("chart"));

    
    nv_addGraph(q)
    q

end
