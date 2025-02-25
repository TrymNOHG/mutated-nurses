module TrainTest

include("models/Config.jl")
include("models/Solution.jl")

include("utils/NurseReader.jl")
using .NurseReader

include("Pipeline.jl")
using .Pipeline

include("operations/PermutationMutation.jl")
using .PermutationMutation

include("operations/ParentSelection.jl")
using .ParentSelection

include("operations/Population.jl")
using .Population

using CSV

depot, patients, travel_time_table = extract_nurse_data("./train/train_0.json")

# Mutations already implemented: swap_mut, insert_mut, scramble_mut, scramble_seg_mut


# In the first go, I will be using tournament selection

function run()
    config = Config(
        size(patients, 1),  # Genotype size
        10000,                 # Population size
        1,                 # Number of generations
        0.1,                # Cross-over rate
        0.01,               # Mutate rate
        "./src/logs/kp/"    # History directory
    )
        
    population = init_permutation_specific(depot.num_nurses, config.genotype_size, config.pop_size)    # Initialize population.
    for individual in population
        repair!(individual, patients, travel_time_table)
    end
    # println(population[1])

    # println(total_patients)
    # Objective function : Minimize the total travel time of all nurses
    # Constraints: 
    # - within time window of patients
    # - back at depot within time
    # - other stuff

    # Simple generational stop condition

    current_gen = 0
    while current_gen < config.num_gen
        # Select Parents
        parents = tournament_select(
            population,             # Population 
            size(population, 1),                     # Number of parents selected (lambda)
            4,                     # k - Number of participants in the tournament
            travel_time_table,       # The time it takes to travel between patients
            patients,               # Patient information
            depot.return_time,       # Depot return time
            depot.nurse_cap         # Nurse capacity
        )
        
        println(nurse_fitness(population[1], travel_time_table, patients, depot.return_time, depot.nurse_cap))
        
        # Recombination


        # Mutate
        # population = 
        # Survivor Selection

        current_gen += 1
    end


    # repair(population[1], patients, travel_time_table)

end

run()

# route = Vector{Int}([5, 4, 3, 2, 1])  # Depot to Patient 1 to Depot
# individual = Solution([5, 4, 3, 2, 1], [2, 3])
# depot, patients, travel_time_table = extract_nurse_data("./train/train_0.json")
# repair!(individual, patients, travel_time_table)

end