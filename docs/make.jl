using Documenter, ExtractMacro

makedocs(
    modules  = [ExtractMacro],
    format = Documenter.HTML(prettyurls = "--local" ∉ ARGS),
    sitename = "ExtractMacro.jl",
    pages    = Any[
        "Home" => "index.md",
       ]
    )

deploydocs(
    repo   = "github.com/carlobaldassi/ExtractMacro.jl.git",
)
