using Documenter
using VacancyChains

DocMeta.setdocmeta!(VacancyChains, :DocTestSetup, :(using VacancyChains); recursive=true)

makedocs(
    sitename = "VacancyChains.jl",
    modules = [VacancyChains],
    authors = "Simone Santoni",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true",
        canonical = "https://simoneSantoni.github.io/VacancyChains.jl",
        edit_link = "main",
        assets = ["assets/custom.css"],
    ),
    repo = "https://github.com/simoneSantoni/VacancyChains.jl/blob/{commit}{path}#{line}",
    pages = [
        "Home" => "index.md",
        "Getting Started" => "getting_started.md",
        "User Guide" => [
            "Moves and Data" => "guide/moves.md",
            "Chain Reconstruction" => "guide/chains.md",
            "Exploratory Analysis" => "guide/eda.md",
            "Estimation" => "guide/estimation.md",
        ],
        "API Reference" => [
            "Types" => "api/types.md",
            "Estimation" => "api/estimation.md",
            "Visualization" => "api/visualization.md",
        ],
        "References" => "references.md",
    ],
    warnonly = [:missing_docs, :docs_block],
)

deploydocs(
    repo = "github.com/simoneSantoni/VacancyChains.jl.git",
    devbranch = "main",
    versions = [
        "stable" => "dev",
        "dev" => "dev",
    ],
    push_preview = true,
)
