using Documenter, MutatedNurses

makedocs(
    sitename="MutatedNurses",
    format=Documenter.HTML(),
    authors="Trym H.G., Hryadyansh S.",
    modules=[MutatedNurses],
    pages=[
        "Home" => "index.md"
    ]
)

deploydocs(
    repo = "github.com/TrymNOHG/mutated-nurses.git",
    devbranch="master",
    push_preview = true # Optional: Preview before merging
)
