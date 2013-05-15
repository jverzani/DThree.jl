## tests of the plotting functions
using DThree
using DataFrames
using Calendar
using RDatasets

## plot
plot(sin, 0, pi) | browse
plot([sin, cos], 0, pi) | browse
plot([sin, u -> cos(u) > 0 ? 0 : NaN], 0, 2pi) | browse

## scatter
iris = data("datasets", "iris")[2:6]
scatterChart(iris) | browse     # no grouping
scatterChart(iris, "Species") | browse #  group by species
scatterChart(iris[3:5], "Species") | browse

## bar
barChart([1,2,3], ["2007", "2010", "2012"]) | browse

## stackedAreaChart
d = DataFrame(x= [now() + days(1:5), now() + days(1:5)], y = rand(10), f=[rep("a",5), rep("b", 5)])
stackedAreaChart(d, "f")  | browse
