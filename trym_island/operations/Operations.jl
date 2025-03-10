module Operations

    using ..Modules: Models

    include("Neighborhood.jl")
    include("PermutationMutation.jl")
    include("ParentSelection.jl")
    include("Population.jl")
    include("Recombination.jl")
    include("Fitness.jl")
    include("LocalSearch.jl")

    using .ParentSelection, .Population, .PermutationMutation, .Neighborhood, .Fitness, .Recombination, .LocalSearch

    # export Neighborhood, ParentSelection, PermutationMutation, Population, Recombination, re_init, init_populations
    const OpPop = Operations.Population
    export OpPop
    export init_permutation, init_bitstring, init_permutation_specific, repair!, is_feasible, re_init, init_populations, calculate_cost, init_seq_heur_pop, solomon_seq_heur
    export tournament_select, select_parents
    export pop_swap_mut!, pop_insert_mut!, pop_scramble_mut!, pop_scramble_seg_mut!, route_mutation!, inversion_mut!, EE_M, EE_M!
    export get_centroid, get_all_centroids, get_route_neighborhood, first_apply_neighbor_insert!, best_apply_neighbor_insert!
    export fitness, evaluate, route_distance, distance
    export IB_X, perform_crossover!
    export LNS!
    export regret_cost
    export re_init2

end