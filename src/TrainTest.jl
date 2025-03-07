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

include("operations/Recombination.jl")
using .Recombination

using CSV

depot, patients, travel_time_table = extract_nurse_data("./train/train_9.json")

# Mutations already implemented: swap_mut, insert_mut, scramble_mut, scramble_seg_mut


# In the first go, I will be using tournament selection

function run()
    config = Config(
        size(patients, 1),  # Genotype size
        350,                 # Population size
        2000,                 # Number of generations
        0.9,                # Cross-over rate
        0.01,               # Mutate rate
        "./src/logs/kp/"    # History directory
    )
        
    population = init_permutation_specific(depot.num_nurses, config.genotype_size, config.pop_size, travel_time_table)    # Initialize population.
    # for individual in population
    #     repair!(individual, patients, travel_time_table)
    # end
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

        # println(nurse_fitness(population[1], travel_time_table, patients, depot.return_time, depot.nurse_cap))
        
        println("Recombination")
        survivors = perform_crossover(parents, config.genotype_size, config.cross_rate)

        # Recombination
        # Mutate
        println("Mutation")
        # pop_swap_mut, pop_insert_mut, pop_scramble_mut, pop_scramble_seg_mut
        for solution in survivors
            # pop_insert_mut!(solution.values, config.mutate_rate)
            # repair!(solution, patients, travel_time_table)
            # inversion_mut!(solution.values, config.mutate_rate)
            pop_scramble_seg_mut!(solution.values, config.mutate_rate)
            if rand() < 0.001
                route_mutation!(solution.indices,  config.genotype_size, config.mutate_rate)
            end
        end

        # fitnesses = []
        # for (i, individual) in enumerate(parents)
        #     push!(fitnesses, (nurse_fitness(individual, travel_time_table, patients, depot)[1], individual))
        # end
        # sort!(fitnesses, by=x->x[1])

        # Survivor Selection
        population = survivors
        # population[1:10] = last.(fitnesses)[1:10]
        # println(population[1:10])
        current_gen += 1
    end


    # repair(population[1], patients, travel_time_table)

end

run()

end