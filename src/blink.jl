

## How to insert d3 into a window

"Load d3.js code into current window"
function inject_d3(w::Blink.AtomShell.Window)
    Blink.loadjs!(w, "https://cdnjs.cloudflare.com/ajax/libs/d3/3.5.16/d3.min.js")
end
inject_d3() = inject_d3(figure(gcf()))

## create an empty page for working with
## can't inject d3 into  blank window.
function empty_page(w::Blink.AtomShell.Window=figure(gcf()); kwargs...)
    f = tempname() * ".html"
    io = open(f, "w")
    tpl = Mustache.template_from_file(Pkg.dir("DThree", "tpl", "d3.html"))
    open(f, "w") do io
        Mustache.render(io, tpl; kwargs...)
    end
    loadfile(w, f)
end


"Pass javascript d3 calls to Blink window"
Blink.js(w::Blink.AtomShell.Window, q::D3) = js(w, JSString(q.render()))
Blink.js(q::D3) = js(figure(gcf()), q)


Blink.loadurl(url::AbstractString) = Blink.loadurl(figure(gcf()), url)
Blink.loadfile(fname::AbstractString) = Blink.loadfile(figure(gcf()), fname)

## ## Example
## w = Blink.Window()
## d3 = D3()
## loadurl(w, "http://www.julialang.org") # must!! load something first??
## inject_d3(w) # inject d3 library into page so that it can be manipulated
## js(w, d3.select("body").transition(2000).style("background-color", "black"))

## Example
## d3 = D3()
## w = figure()
## empty_page(w)  # create a blank page to work with with d3 files loaded
## js(w, d3.select("body").transition(2000).style("background-color", "black"))
