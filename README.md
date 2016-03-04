


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

By default, strings are quoted. To stop that, wrap the string in
`asis` (like `R`'s `I` operator). This is necessary when the argument
refers to a `JavaScript` object.


## Blink

This package also borrows the figure manipulation tools of `Immerse`
and the HTML windows of `Blink` to create canvases to manipulate. The
basic idea would follow from this example

```
using DThree
style = """

.chart div {
  font: 10px sans-serif;
  background-color: steelblue;
  text-align: right;
  padding: 3px;
  margin: 1px;
  color: white;
  }
"""
  
w = figure()
DThree.empty_page(w, style=style) # loads D3 libraries

d3 = D3()
d3.var("p").select("body").selectAll("p").
    data([4, 8, 15, 16, 23, 42]).
    text(asis"function(d) { return d; }") |> js
d3.receiver("p").enter().append("p").
	text(asis"function(d) { return d; }") |> js

d3.receiver("p")._("exit")._("remove") |> js
```

```
using DThree
w = figure()
DThree.empty_page(w) # loads D3 libraries

d3 = D3()
d3.select("body").
    style("color", "black").
    style("background-color", "white") |> js
d3.select("body").append("div")        |> js

d3.select("div").
    data([4, 8, 15, 16, 23, 42]).
	  enter().append("div").
  style("width", asis"""function(d) { return d * 10 + "px"; }""").
  text(asis"""function(d) { return d; }""")  |> js
	
"""
