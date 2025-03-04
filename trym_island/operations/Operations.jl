module Operations

    export Neighborhood, ParentSelection, PermutationMutation, Population, Recombination

    include("Neighborhood.jl")
    include("ParentSelection.jl")
    include("PermutationMutation.jl")
    include("Population.jl")
    include("Recombination.jl")
end