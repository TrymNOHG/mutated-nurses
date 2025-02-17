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
        depot.num_nurse,    # Genotype size
        size(patients, 1),  # Population size
        50,                 # Number of generations
        0.1,                # Cross-over rate
        0.01,               # Mutate rate
        "./src/logs/kp/"    # History directory
    )
        
    population = init_permutation(depot.num_nurse, size(patients, 1))     # Initialize population.

    # Objective function : Minimize the total travel time of all nurses
    # Constraints: 
    # - within time window of patients
    # - back at depot within time
    # - other stuff

    # I will perform two types of recombination:
    # - 1. Of the 4 first bits, signifying the nurse id.
    # - 2. Of the 4 last bits, signifying the route index.

    # Simple generational stop condition

    current_gen = 0
    while current_gen < config.num_gen
        # Select Parents
        parents = select_parents(population, )
        # Recombination
        # Mutate
        # Survivor Selection

        current_gen += 1
    end



end


function decode(patient_value::Int)
    nurse_num = patient_value >> 4
    number_in_route = patient_value & 0b1111
    return nurse_num, number_in_route
end

population = init_permutation_specific(5, 10, 1)

println(population)

for patient in population[1]
    println(decode(patient))
end





end