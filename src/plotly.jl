## use is diffrent than plots
## using DThree, Plots # no using Plots; plotly()
## plot(sin, 0, 2pi)
## figure()
## plot(cos, 0, 2pi)
## plot!(sin)

using Plots
plotly()
PlotlyPackage = Plots.PlotlyPackage

function html_head(plt::Plots.PlottingObject{PlotlyPackage})
    "<script src=\"$(Pkg.dir("Plots","deps","plotly-latest.min.js"))\"></script>\n" *
    "<script src=\"https://cdnjs.cloudflare.com/ajax/libs/d3/3.5.16/d3.min.js\"></script>"
end


# ----------------------------------------------------------------

Base.display(::Base.REPL.REPLDisplay, ::MIME"text/plain", p::Plots.PlottingObject{PlotlyPackage}) = display(_display, p)


function Base.writemime(io::IO, ::MIME"text/html", plt::Plots.PlottingObject{PlotlyPackage})
  write(io, html_head(plt) * Plots.html_body(plt))
end
