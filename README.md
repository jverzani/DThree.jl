


Simple interface to `d3` (http://d3js.org) and nvd3 (http://nvd3.org/) `JavaScript` libraries for chart making.

This package for `Julia` provides a simple interface for using d3 syntax within `julia`.

It isn't very clever, basically it takes a `d3` command like:

```
d3.selectAll("p").style("color", "white")
```

And turns it into a `julia` call like:


```
using DThree
d3 = D3()
d3.selectAll("p").style("color", "white")
```

Okay, you might guess the style. This just pieces together a string of `JavaScript` that will get inserted into a web page. The `render` method creates the code.

The implementation is pretty stupid, it just makes fields named after the main methods and creates a function when the object is instantiated. The functions return a `D3` instance so they can be chained, as above.

If the field isn't present, then the interface can look one of two ways:

```
d3[:selectAll]("p")._("color", "white") ## two ways [:symbol](args...) or _("meth", args...)
```

By default, strings are quoted. To stop that, wrap the string in `I` (like `R`'s as-is operator). This is necessary when the argument refers to a `JavaScript` object.

The `nvd3` code makes it easy to use `d3` to produce graphics. The `functionChart` function basically does this

```
f,a,b = sin, 0, pi
x = linspace(a, b, 250)
data = [{values=>[{:x=>x, :y=>f(x)} for x in x], :key=>"Sine"}] | JSON.to_json | I

d3 = D3()
q = D3Plot()

## cf. http://nvd3.org/ghpages/line.html

## var chart = nv.models.lineChart();
q * d3.var("chart").receiver("nv")._("models.lineChart")    

## chart.xAxis.axisLabel("x").tickFormat(d3.format(",.02"));
q * d3.receiver("chart.xAxis").axisLabel("x").tickFormat(D3().format(",.02f"))       

## chart.yAxis.axisLabel("y").tickFormat(d3.format(",.02"));
q * d3.receiver("chart.yAxis").axisLabel("y").tickFormat(D3().format(",.02f"))

##  d3.select("#chart svg").datum(data).transition().duration(500).call(chart);
q * d3.select("#chart svg").datum(data).transition().duration(500).call(I("chart"))

DThree.nv_addGraph(q) ## wrap in a function
browse(q)             ## open chart in a browser
```

The `q` object has `*` overloaded (it should be `*!` as it modifies `q` when used) to build up commands, similar to how `+` is used with `R`'s `ggplot` interface. This object has the `browse` method which is used to past the commands into a web page and open them up with the default browser. Embedding the commands into a web page would be straightforward.



## plotting functions

Like the `GoogleCharts` package, some off-the-shelf charts can be produced from a simple function call:

```
plot(sin, 0, pi) | browse
plot(sin, 0, pi) | browse
iris = data("datasets", "iris")[2:6]  ## using RDatasets
scatterChart(iris, "Species") | browse
barChart([1,2,3], ["2007", "2010", "2012"]) | browse
d = DataFrame(x= [now() + days(1:5), now() + days(1:5)], y = rand(10), f=[rep("a",5), rep("b", 5)])
stackedAreaChart(d, "f")  | browse
```

The first of these produces this graphic:


<link href="https://raw.github.com/novus/nvd3/master/src/nv.d3.css" media="all" rel="stylesheet" type="text/css" />
<script type="text/javascript" src="http://code.jquery.com/jquery-1.9.1.min.js"></script>
<script src="http://cdnjs.cloudflare.com/ajax/libs/d3/2.10.0/d3.v2.min.js" charset="utf-8"></script>
<script src="http://nvd3.org/lib/fisheye.js" charset="utf-8"></script>
<script src="https://raw.github.com/novus/nvd3/master/nv.d3.js" charset="utf-8"></script>

<div id='chart'><svg style='height:500px'></svg></div>

<script>
$(document).ready(function() {
nv.addGraph(function() {
var chart = nv.models.stackedAreaChart().x(function(d) {return d[0]}).y(function(d) {return d[1]}).clipEdge(true);
chart.xAxis.showMaxMin(false).tickFormat(function(d) { return d3.time.format('%x')(new Date(d))})
chart.yAxis.tickFormat(d3.format(",.02f"))
d3.select("#chart svg").datum([{"key":"a","values":[[1.368672069234e12,0.06609182360191879],[1.368758469234e12,0.8632879573792165],[1.368844869234e12,0.6739644438656134],[1.368931269234e12,0.7122692953773826],[1.369017669234e12,0.3719229987265451]]},{"key":"b","values":[[1.368672069262e12,0.5427898009563044],[1.368758469262e12,0.10809955903755553],[1.368844869262e12,0.37920864988534553],[1.368931269262e12,0.9835455951617929],[1.369017669262e12,0.9999928743280255]]}]).transition().duration(500).call(chart)
nv.utils.windowResize(chart.update)
return chart;});
});
</script>
