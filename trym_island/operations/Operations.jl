module Operations

    export Neighborhood, ParentSelection, PermutationMutation, Population, Recombination, re_init

    include("Neighborhood.jl")
    using .Neighborhood

    include("ParentSelection.jl")
    include("Population.jl")

    using .ParentSelection, .Population


    include("PermutationMutation.jl")
    using .PermutationMutation

    include("Recombination.jl")
    using .Recombination

end