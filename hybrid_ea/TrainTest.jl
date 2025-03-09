module TrainTest

include("Modules.jl")
using .Modules

include("utils/NurseReader.jl")
using .NurseReader

using CSV


# extract_nurse_data("./data/train/train_9.json", "./data/bin/serialized_train_9.bin")
depot, patients, tt_tuple, n_col= load_data("./data/bin/serialized_train_9.bin")
const TT_TUPLE = tt_tuple  # Make global constant
const N_COL = n_col        # for type stability
@inline function time_matrix(i::Int, j::Int)
    @inbounds TT_TUPLE[(i-1)*N_COL + j]
    TT_TUPLE[(i-1)*N_COL + j]
end


function run()
    NUM_GEN = 50000
    cross_rate = 1.0
    pop_size = 10
    growth_size = 2
    time_pen = 2
    num_time_pen = 1.5
    num_patients = size(patients, 1)

    # Init pop
    population = @time init_population(patients, num_patients, depot.num_nurses, pop_size, growth_size, time_matrix, depot.nurse_cap, depot.return_time)


    current_gen = 0 
    # Evolutionary loop
    while current_gen < NUM_GEN
        # Parent Selection:
        # parent_ids = select_parents(population) # Try first with roulette and then stochastic universal sampling
        parent_ids = tournament_select(population, time_matrix, patients, depot, 2) # Try first with roulette and then stochastic universal sampling
            
        # Recombination and mutation based on which pop it is...
        perform_crossover!(parent_ids, population, patients, num_patients, time_matrix, depot, cross_rate, time_pen, num_time_pen) # Need to improve this.

        # TODO: implement mutation
        for individual in population.genes
            EE_M!(individual,  patients, time_matrix)
        end

        # Combine children and parents
        # Remove n_p individuals using eval
        # Collect fitness array again


        # # Survivor selection:
        # # Remove the n_p worst from the pop using eval. (Currently, I am using the fitness function instead of eval...)
        while size(population.genes, 1) > pop_size
            worst_gene_id = argmax(population.fitness_array)
            deleteat!(population.genes, worst_gene_id)
            deleteat!(population.fitness_array, worst_gene_id)
        end
        
        # re_init(r_min_1, num_patients, travel_time_table, patients)

        println("-------------")
        println("Best fitness:")
        println(minimum(population.fitness_array))
        println("Average fitness:")
        println(sum(population.fitness_array)/size(population.fitness_array, 1))
        println("Worst fitness:")
        println(maximum(population.fitness_array))
        println("-------------")

        
        # Check if pop_2 contains new best feasible solution
        # If so, migration will occur with some extra mutation shenanigans

        # Re-order the best solution to try and make it better.

        current_gen += 1
    end

    # Use RC_M to try and locally improve the best solution.
    # for pop in population
    println(population.genes[rand(1:size(population.genes, 1))].gene_r)
    println(minimum(population.fitness_array))
    println(population.genes[argmin(population.fitness_array)].gene_r)
    # end
    
end

run()
# println(solomon_seq_heur(size(patients, 1), depot.num_nurses, time_matrix, patients, depot.nurse_cap, depot.return_time))


end