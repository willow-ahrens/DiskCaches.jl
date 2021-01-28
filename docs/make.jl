using DiskCaches
using Documenter

makedocs(;
    modules=[DiskCaches],
    authors="Peter Ahrens",
    repo="https://github.com/peterahrens/DiskCaches.jl/blob/{commit}{path}#L{line}",
    sitename="DiskCaches.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://peterahrens.github.io/DiskCaches.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/peterahrens/DiskCaches.jl",
)
