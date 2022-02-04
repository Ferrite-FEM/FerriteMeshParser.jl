using FerriteMeshParser
using Documenter

DocMeta.setdocmeta!(FerriteMeshParser, :DocTestSetup, :(using FerriteMeshParser); recursive=true)

makedocs(;
    modules=[FerriteMeshParser],
    authors="Knut Andreas Meyer and contributors",
    repo="https://github.com/KnutAM/FerriteMeshParser.jl/blob/{commit}{path}#{line}",
    sitename="FerriteMeshParser.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://KnutAM.github.io/FerriteMeshParser.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/KnutAM/FerriteMeshParser.jl",
    devbranch="main",
)
