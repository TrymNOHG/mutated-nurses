module TrainTest

include("models/Config.jl")

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
        50,                 # Population size
        50,                 # Number of generations
        0.1,                # Cross-over rate
        0.01,               # Mutate rate
        "./src/logs/kp/"    # History directory
    )
        
    population = init_permutation_specific(depot.num_nurses, config.genotype_size, config.pop_size)    # Initialize population.

    # println(population[1])

    # println(total_patients)
    # Objective function : Minimize the total travel time of all nurses
    # Constraints: 
    # - within time window of patients
    # - back at depot within time
    # - other stuff

    # I will perform two types of recombination:
    # - 1. Of the 4 first bits, signifying the nurse id.
    # - 2. Of the 4 last bits, signifying the route index.

    # Simple generational stop condition

    # current_gen = 0
    # while current_gen < config.num_gen
    #     # Select Parents
    #     parents = tournament_select(
    #         population,             # Population 
    #         10,                     # Number of parents selected (lambda)
    #         10,                     # k - Number of participants in the tournament
    #         travel_time_table       # The time it takes to travel between patients
    #     )
        
    #     # Recombination
    #     # Mutate
    #     # Survivor Selection

    #     current_gen += 1
    # end



end

run()

end