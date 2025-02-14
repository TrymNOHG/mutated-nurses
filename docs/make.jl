using Documenter, MutatedNurses, DotEnv

DotEnv.load!()

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
    branch = "gh-pages", 
    devbranch="master",
    deploy_config=Documenter.GitHubActions(),
    target="build",
    push_preview = true,
)
