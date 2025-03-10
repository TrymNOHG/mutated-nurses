module TrainTest

include("Modules.jl")
using .Modules


# include("models/Models.jl")
# using .Models

# include("operations/Operations.jl")
# using .Operations

include("utils/NurseReader.jl")
using .NurseReader

using CSV

if length(ARGS) < 1
    error("Please provide the path to the serialized data file as an argument.")
end

# extract_nurse_data("./data/train/train_9.json", "./data/bin/serialized_train_9.bin")
depot, patients, tt_tuple, n_col= load_data("../hs_work/ser_train/"*ARGS[1])
const TT_TUPLE = tt_tuple  # Make global constant
const N_COL = n_col        # for type stability
@inline function time_matrix(i::Int, j::Int)
    @inbounds TT_TUPLE[(i-1)*N_COL + j]
    TT_TUPLE[(i-1)*N_COL + j]
end

println("Running 2 island approach")

function run()
    NUM_GEN = 5
    cross_rate = 1.0
    pop_size = 20
    growth_size = 1
    time_pen = 2
    num_time_pen = 1.5
    num_patients = size(patients, 1)

    # Init pop
    init_pop = @time init_populations(patients, num_patients, depot.num_nurses, pop_size, growth_size, time_matrix, depot.nurse_cap, depot.return_time)

    # for pop in init_pop
    #     for gene in pop
    #         println(gene)
    #     end
    # end
    # throw(Error())
    populations = []
    for (i, pop) in enumerate(init_pop)
        popu = []
        fitness_array = []
        best_id = 0
        best_fitness = typemax(Int32)
        for (j, individual) in enumerate(pop)
            gene_r = individual
            sequence = collect(Iterators.flatten(gene_r))
            fitness_val, time_violation = fitness(i, gene_r, patients, time_matrix, time_pen, num_time_pen) # Use the 
            if time_violation
                println("Time violation?!")
            end
            if fitness_val < best_fitness && !time_violation
                best_id = j
                best_fitness = fitness_val
            end
            push!(fitness_array, fitness_val)
            push!(popu, Gene(
                sequence,
                fitness_val,
                gene_r,
                [],
                [],
                [],
                [],
                []
            ))
        end
        println(best_fitness)
        println(pop[best_id])
        push!(populations, ModelPop(
            i,
            num_patients,
            popu,
            fitness_array,
            best_id,
            [],
            [],
            pop_size,
            growth_size,
            "./trym_island/logs"
        ))
    end

    current_gen = 0 
    # Evolutionary loop
    while current_gen < NUM_GEN
        for (i, pop) in enumerate(populations)  # Embarrasingly Parallelizable Here. So, try and do something with that... add Threads.@threads
            # Parent Selection:
            parent_ids = select_parents(pop) # Try first with roulette and then stochastic universal sampling
                
            # Recombination and mutation based on which pop it is...
            perform_crossover!(parent_ids, pop, patients, num_patients, time_matrix, depot, cross_rate, time_pen, num_time_pen) # Need to improve this.

            # TODO: implement mutation
            for individual in pop.genes
                EE_M!(individual,  patients, time_matrix)
            end

            # Combine children and parents
            # Remove n_p individuals using eval
            # Collect fitness array again


            # Survivor selection:
            # Remove the n_p worst from the pop using eval. (Currently, I am using the fitness function instead of eval...)
            while size(pop.genes, 1) > pop_size
                worst_gene_id = argmax(pop.fitness_array)
                deleteat!(pop.genes, worst_gene_id)
                deleteat!(pop.fitness_array, worst_gene_id)
            end
           
            println("-------------")
            println("Pop 1:")
            println("Best fitness:")
            println(maximum(populations[1].fitness_array))
            println("Average fitness:")
            println(sum(populations[1].fitness_array)/size(populations[1].fitness_array, 1))
            println("Worst fitness:")
            println(minimum(populations[1].fitness_array))
            println("Pop 2:")
            println("Best fitness:")
            println(maximum(populations[2].fitness_array))
            println("Average fitness:")
            println(sum(populations[2].fitness_array)/size(populations[2].fitness_array, 1))
            println("Worst fitness:")
            println(minimum(populations[2].fitness_array))
            println("-------------")

        end
        
        # Check if pop_2 contains new best feasible solution
        # If so, migration will occur with some extra mutation shenanigans

        # Re-order the best solution to try and make it better.

        current_gen += 1
    end

    open("../input_4_hgdacKool.txt", "a") do file
        for (rank, idx) in enumerate(top_indices)
            # Print to console
            # println("Rank #$rank (Gene Index: $idx)")
            # println("Biased Fitness: $(genetic_pool.biased_fitness_array[idx])")
            # println("Actual Fitness: $(genetic_pool.fitness_array[idx])")
            # println("Routes:")
            # println(genetic_pool.genes[idx].gene_r)
            # println("--------------------------")
            
            # Write to file using println
            println(file, genetic_pool.genes[idx].gene_r)
    
        end
    end

    # Use RC_M to try and locally improve the best solution.
    # for pop in populations
    #     println(pop.genes[rand(1:size(pop.genes, 1))].gene_r)
    #     println(pop.pop_id)
    #     println(minimum(pop.fitness_array))
    #     println(pop.genes[argmin(pop.fitness_array)].gene_r)
    # end
    
end

run()
# println(solomon_seq_heur(size(patients, 1), depot.num_nurses, time_matrix, patients, depot.nurse_cap, depot.return_time))


end