using Documenter, MutatedNurses

makedocs(sitename="MutatedNurses")
deploydocs(
    repo = "github.com/TrymNOHG/mutated-nurses.git",
    push_preview = true # Optional: Preview before merging
)
