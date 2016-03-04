using DThree

## Make scatter plot
x = linspace(0, 2*pi, 50)
y = cos(x)
dataset = "[" * join(["[$x,$y]" for (x,y) in zip(x,y)], ", ") * "]"
    width, height = 600, 400
    padding = 30

    p = D3Plot()
    d3 =D3()

    p * d3.var("svg").select("body").append("svg").attr("width", width).attr("height", height)
    ## scales
    p * d3.var("xScale").scale_linear().domain([min(x),max(x)]*1.1).range([0, width])
    p* d3.var("yScale").scale_linear().domain([min(y),max(y)]*1.1).range([height, 0])
    ## axes
    p * d3.var("xAxis").svg_axis().scale(asis("xScale")).orient("bottom")
    p * d3.receiver("svg").append("g").attr("class", "axis").attr("transform", "translate(0,$(height - padding))").call(asis("xAxis"))
    p * d3.var("yAxis").svg_axis().scale(asis("yScale")).orient("left").ticks(5)
    p * d3.receiver("svg").append("g").attr("class", "axis").attr("transform", "translate($padding, 0)").call(asis("yAxis"))

    p * d3.receiver("svg").selectAll("circle").data(asis(dataset)).enter().append("circle").
      attr("cx", asis("function(d) {return xScale(d[0])}")).
      attr("cy", asis("function(d) {return yScale(d[1])}")).
      attr("r", 5)


    

style = "
.axis path,
.axis line {
    fill: none;
    stroke: black;
    shape-rendering: crispEdges;
}

.axis text {
    font-family: sans-serif;
    font-size: 11px;
}
"

    browse(p, style=style)
