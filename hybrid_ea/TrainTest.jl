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
    NUM_GEN = 500
    cross_rate = 1.0
    mutate_rate = 0.3
    pop_size = 100
    growth_size = 20
    time_pen = 2
    num_time_pen = 1.5
    num_patients = size(patients, 1)

    # Init pop
    population = @time init_population(patients, num_patients, pop_size, growth_size, time_matrix, depot)

    current_gen = 0 
    best_fitness = minimum(population.fitness_array)
    lack_of_change = 0
    println("Start")
    # Evolutionary loop
    while current_gen < NUM_GEN
        # Parent Selection:
        # parent_ids = select_parents(population) # Try first with roulette and then stochastic universal sampling
        parent_ids = tournament_select(population, time_matrix, patients, depot, 2) # Try first with roulette and then stochastic universal sampling
            
        println("Before crossover:")
        for individual in population.genes
            if size(collect(Iterators.flatten(individual.gene_r)), 1) < 100
                throw("Bruh")
            end
        end
            
        # Recombination and mutation based on which pop it is...
        perform_crossover!(parent_ids, population, patients, num_patients, time_matrix, depot, cross_rate, time_pen, num_time_pen) # Need to improve this.

        println("After crossover:")
        for individual in population.genes
            if size(collect(Iterators.flatten(individual.gene_r)), 1) < 100
                println(sort(collect(Iterators.flatten(individual.gene_r))))
                throw("Bruh")
            end
        end
 

        # TODO: implement other mutations...
        for individual in population.genes
            if rand() < mutate_rate
                EE_M!(individual,  patients, time_matrix)
            end
            if size(collect(Iterators.flatten(individual.gene_r)), 1) < 100
                throw("EEM bruh")
            end
            # Try re-insertion mutation
            # Try some other mutations
            # LNS!(15, individual.gene_r, patients, time_matrix, depot) # Need to recalculate the fitness score then.
            if size(collect(Iterators.flatten(individual.gene_r)), 1) < 100
                throw("LNS bruh")
            end
        end

        # println("After mutation crossover:")
        # for individual in population.genes
        #     if size(collect(Iterators.flatten(individual.gene_r)), 1) < 100
        #         throw("Bruh")
        #     end
        # end


        # Re-calculate fitness array
        for (i, individual) in enumerate(population.genes)
            fitness_val = distance(individual.gene_r, time_matrix)
            population.fitness_array[i] = fitness_val
        end

        # # Survivor selection:
        # # Remove the n_p worst from the pop using eval. (Currently, I am using the fitness function instead of eval...)
        while size(population.genes, 1) > pop_size # Elitism...
            worst_gene_id = argmax(population.fitness_array)
            deleteat!(population.genes, worst_gene_id)
            deleteat!(population.fitness_array, worst_gene_id)
        end
        
        # re_init(r_min_1, num_patients, time_matrix, patients)

        println("-------------")
        println("Best fitness:")
        println(minimum(population.fitness_array))
        println("Average fitness:")
        println(sum(population.fitness_array)/size(population.fitness_array, 1))
        println("Worst fitness:")
        println(maximum(population.fitness_array))
        println("-------------")

        if minimum(population.fitness_array) == best_fitness
            lack_of_change += 1
            if lack_of_change == 15
                best_individual_id = argmin(population.fitness_array)
                population.genes[1] = population.genes[best_individual_id]
                population.fitness_array[1] = population.fitness_array[best_individual_id]
                for i in 2:size(population.genes, 1)
                    population.genes[i] = re_init(num_patients, time_matrix, patients, depot)
                    population.fitness_array[i] = distance(population.genes[i].gene_r, time_matrix)
                end
                lack_of_change = 1
            end
        end
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