using FerriteMeshParser
using Documenter

const is_ci = get(ENV, "CI", "false") == "true"

include("generate.jl")
GENERATEDEXAMPLES = [
    joinpath("examples", f) for f in (
        "compact_tension.md",
        "user_element.md",
    )
]

DocMeta.setdocmeta!(FerriteMeshParser, :DocTestSetup, :(using FerriteMeshParser); recursive = true)

makedocs(;
    authors = "Knut Andreas Meyer and contributors",
    repo = "https://github.com/Ferrite-FEM/FerriteMeshParser.jl/blob/{commit}{path}#{line}",
    sitename = "FerriteMeshParser.jl",
    format = Documenter.HTML(;
        prettyurls = is_ci,
        canonical = "https://Ferrite-FEM.github.io/FerriteMeshParser.jl",
        assets = String[],
    ),
    pages = [
        "Home" => "index.md",
        "Examples" => GENERATEDEXAMPLES,
    ],
)

deploydocs(;
    repo = "github.com/Ferrite-FEM/FerriteMeshParser.jl",
    devbranch = "main",
    push_preview = true,
)
