module Operations

    export Neighborhood, ParentSelection, PermutationMutation, Population, Recombination, re_init

    include("Neighborhood.jl")
    using .Neighborhood

    include("Population.jl")
    using .Population

    include("ParentSelection.jl")
    using .ParentSelection

    include("PermutationMutation.jl")
    using .PermutationMutation


    include("Recombination.jl")
    using .Recombination

end