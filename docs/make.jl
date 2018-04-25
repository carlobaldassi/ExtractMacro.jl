using Documenter, ExtractMacro

makedocs(
    modules  = [ExtractMacro],
    format   = :html,
    sitename = "ExtractMacro.jl",
    pages    = Any[
        "Home" => "index.md",
       ]
    )

deploydocs(
    repo   = "github.com/carlobaldassi/ExtractMacro.jl.git",
    target = "build",
    deps = nothing,
    make = nothing,
    julia  = "0.6"
)
