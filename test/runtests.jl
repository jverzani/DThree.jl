sc## tests of the plotting functions
using DThree
using DataFrames
using RDatasets
using Base.Dates

## plot
plot(sin, 0, pi) |> browse
plot([sin, cos], 0, pi) |> browse
plot([sin, u -> cos(u) > 0 ? 0 : NaN], 0, 2pi) |> browse

## scatter
iris = dataset("datasets", "iris")
scatterChart(iris) |> browse     # no grouping
scatterChart(iris, :Species) |> browse #  group by species
scatterChart(iris[3:5], :Species) |> browse

## bar
barChart([1,2,3], ["2007", "2010", "2012"]) |> browse

## stackedAreaChart
five_days = [Dates.Day(k) for k in 1:5]
d = DataFrame(x= vcat(now() + five_days, now() + five_days), y = rand(10), f=vcat(rep("a",5), rep("b", 5)))
stackedAreaChart(d, :f)  |> browse
