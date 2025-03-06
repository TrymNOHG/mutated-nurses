module Operations

    # export Neighborhood, ParentSelection, PermutationMutation, Population, Recombination, re_init, init_populations
    export init_permutation, init_bitstring, init_permutation_specific, repair!, is_feasible, re_init, init_populations, calculate_cost, init_seq_heur_pop
    export tournament_select, nurse_fitness, simple_nurse_fitness, evaluate
    export pop_swap_mut!, pop_insert_mut!, pop_scramble_mut!, pop_scramble_seg_mut!, route_mutation!, inversion_mut!, EE_M, EE_M!
    export get_centroid, get_all_centroids, get_route_neighborhood, first_apply_neighbor_insert!, best_apply_neighbor_insert!


    include("Neighborhood.jl")
    include("PermutationMutation.jl")
    include("ParentSelection.jl")
    include("Population.jl")
    include("Recombination.jl")

    using .ParentSelection, .Population, .PermutationMutation, .Neighborhood, .Recombination

end