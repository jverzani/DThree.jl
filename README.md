


Simple interface to `d3` (http://d3js.org) and nvd3 (http://nvd3.org/) `JavaScript` libraries for chart making.

This package for `Julia` provides a simple interface for using d3 syntax within `julia`.

It isn't very clever, basically it takes a `d3` command like:

```
d3.selectAll("p").style("color", "white")
```

And turns it into a `julia` call like:


```
d3.selectAll("p").style("color", "white")
```

(Only after)
```
using DThree
d3 = D3()
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

The `q` object has `*` overloaded (it should be `*!` as it modifies `q` when used) to build up commands, similar to how `+` is used with `R`'s `ggplot` interface. This object has the `browse` method which is used to paste the commands into a web page and open them up with the default browser. Embedding the commands into a web page would be straightforward.



## plotting functions

Like the `GoogleCharts` package, some off-the-shelf charts can be produced from a simple function call:

```
plot(sin, 0, pi) | browse	      ## simple graph

plot([sin, cos], 0, pi) | browse      ## pair of graphs

iris = data("datasets", "iris")[2:6]  ## using RDatasets
scatterChart(iris, "Species") | browse  ## scatter plots by group

barChart([1,2,3], ["2007", "2010", "2012"]) | browse  ## simple bar chart

d = DataFrame(x= [now() + days(1:5), now() + days(1:5)], y = rand(10), f=[rep("a",5), rep("b", 5)])
stackedAreaChart(d, "f")  | browse    ## stacked area chart grouped by factor f
```
