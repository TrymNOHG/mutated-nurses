module TrainTest

include("models/Models.jl")
using .Models

include("operations/Operations.jl")
using .Operations

include("utils/NurseReader.jl")
using .NurseReader

using CSV

# extract_nurse_data("./train/train_0.json", "./trym_island/bin_train/serialized_train_0.bin")
depot, patients, tt_tuple, n_col= load_data("./trym_island/bin_train/serialized_train_9.bin")
const TT_TUPLE = tt_tuple  # Make global constant
const N_COL = n_col        # for type stability
@inline function time_matrix(i::Int, j::Int)
    @inbounds TT_TUPLE[(i-1)*N_COL + j]
    TT_TUPLE[(i-1)*N_COL + j]
end


function run()
    config = Config(
        size(patients, 1),  # Genotype size
        100,                 # Population size
        1000,                 # Number of generations
        0.9,                # Cross-over rate
        0.01,               # Mutate rate
        "./src/logs/kp/"    # History directory
    )
        
    population = init_permutation_specific(depot.num_nurses, config.genotype_size, config.pop_size)    # Initialize population.
    for individual in population
        repair!(individual, patients, travel_time_table)
    end

    current_gen = 0
    while current_gen < config.num_gen
        # Select Parents
        println(current_gen + 1)
        println("Parent Selection")
        parents = tournament_select(
            population,             # Population 
            size(population, 1),                     # Number of parents selected (lambda)
            2,                     # k - Number of participants in the tournament
            travel_time_table,       # The time it takes to travel between patients
            patients,               # Patient information
            depot                   # Depot info
        )
        
        println("Recombination")
        survivors = perform_crossover(parents, config.genotype_size, config.cross_rate)

        # Recombination
        # Mutate
        println("Mutation")
        for solution in survivors
            # pop_insert_mut!(solution.values, config.mutate_rate)
            inversion_mut!(solution.values, config.mutate_rate)
            # pop_scramble_seg_mut!(solution.values, config.mutate_rate)
            if rand() < 0.001
                route_mutation!(solution.indices,  config.genotype_size, config.mutate_rate)
            end
        end

        # Survivor Selection
        population = survivors

        current_gen += 1
    end


end

# run()
# routes = re_init(depot.num_nurses, size(patients, 1), time_matrix, patients)
# println(routes)
# println(size(collect(Iterators.flatten(routes)), 1))

# println(init_seq_heur_pop(size(patients, 1), depot.num_nurses, time_matrix, patients))

pop_size = 10000
growth_size = 100
populations = init_populations(patients, size(patients, 1), depot.num_nurses, pop_size, growth_size, time_matrix, depot.nurse_cap)

end