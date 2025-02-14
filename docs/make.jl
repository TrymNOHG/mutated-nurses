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
    branch = "gh-pages", 
    devbranch="master",
    deploy_config=Documenter.GitHubActions(),
    git_authors=["yourusername"],
    target="build",
    push_preview = true,
    token=ENV["GITHUB_AUTH"]  
)
