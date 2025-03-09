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


# extract_nurse_data("./data/train/train_9.json", "./data/bin/serialized_train_9.bin")
depot, patients, tt_tuple, n_col= load_data("./data/bin/serialized_train_9.bin")
const TT_TUPLE = tt_tuple  # Make global constant
const N_COL = n_col        # for type stability
@inline function time_matrix(i::Int, j::Int)
    @inbounds TT_TUPLE[(i-1)*N_COL + j]
    TT_TUPLE[(i-1)*N_COL + j]
end


function run()
    NUM_GEN = 1000
    cross_rate = 1.0
    pop_size = 10
    growth_size = 5
    time_pen = 2
    num_time_pen = 1.5
    num_patients = size(patients, 1)

    # Init pop
    init_pop = @time init_populations(patients, num_patients, depot.num_nurses, pop_size, growth_size, time_matrix, depot.nurse_cap, depot.return_time)

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

    best_fitness = minimum(populations[1].fitness_array)
    lack_of_change = 0
    current_gen = 0 
    # Evolutionary loop
    while current_gen < NUM_GEN
        for (i, pop) in enumerate(populations)  # Embarrasingly Parallelizable Here. So, try and do something with that... add Threads.@threads
            # Parent Selection:
            for individual in pop.genes
                if size(collect(Iterators.flatten(individual.gene_r)), 1) > 100 || length(Set(collect(Iterators.flatten(individual.gene_r)))) < 100
                    throw("before parent")
                end
            end
            parent_ids = select_parents(pop) # Try first with roulette and then stochastic universal sampling
                
            for individual in pop.genes
                if size(collect(Iterators.flatten(individual.gene_r)), 1) > 100 || length(Set(collect(Iterators.flatten(individual.gene_r)))) < 100
                    throw("before parent")
                end
            end

            # Recombination and mutation based on which pop it is...
            perform_crossover!(parent_ids, pop, patients, num_patients, time_matrix, depot, cross_rate, time_pen, num_time_pen) # Need to improve this.

            for individual in pop.genes
                if size(collect(Iterators.flatten(individual.gene_r)), 1) > 100
                    println(collect(Iterators.flatten(individual.gene_r)))
                    println(sort(collect(Iterators.flatten(individual.gene_r))))
                    throw("after xo")
                end
                if length(Set(collect(Iterators.flatten(individual.gene_r)))) < 100
                    throw("after xo uniqueness")
                end
            end

            # TODO: implement mutation
            for individual in pop.genes
                EE_M!(individual,  patients, time_matrix)
                LNS!(10, individual.gene_r, patients, time_matrix, depot) # Need to recalculate the fitness score then.
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

            # if minimum(populations[1].fitness_array) == best_fitness
            #     lack_of_change += 0.5
            #     if lack_of_change == 15
            #         best_individual_id = argmin(populations[1].fitness_array)
            #         populations[1].genes[1] = populations[1].genes[best_individual_id]
            #         populations[1].fitness_array[1] = populations[1].fitness_array[best_individual_id]
            #         for i in 2:size(populations[1].genes, 1)
            #             populations[1].genes[i] = re_init2(num_patients, time_matrix, patients, depot)
            #             populations[1].fitness_array[i] = distance(populations[1].genes[i].gene_r, time_matrix)
            #         end
            #         lack_of_change = 1
            #     end
            # end
           

        end

        println("-------------")
        println("Pop 1:")
        println("Best fitness:")
        println(minimum(populations[1].fitness_array))
        println("Average fitness:")
        println(sum(populations[1].fitness_array)/size(populations[1].fitness_array, 1))
        println("Worst fitness:")
        println(maximum(populations[1].fitness_array))
        println("Pop 2:")
        println("Best fitness:")
        println(minimum(populations[2].fitness_array))
        println("Average fitness:")
        println(sum(populations[2].fitness_array)/size(populations[2].fitness_array, 1))
        println("Worst fitness:")
        println(maximum(populations[2].fitness_array))
        println("-------------")
        
        # Check if pop_2 contains new best feasible solution
        # If so, migration will occur with some extra mutation shenanigans

        # Re-order the best solution to try and make it better.

        current_gen += 1
    end

    # Use RC_M to try and locally improve the best solution.
    for pop in populations
        println(pop.genes[rand(1:size(pop.genes, 1))].gene_r)
        println(pop.pop_id)
        println(minimum(pop.fitness_array))
        println(pop.genes[argmin(pop.fitness_array)].gene_r)
    end
    
end

run()
# println(solomon_seq_heur(size(patients, 1), depot.num_nurses, time_matrix, patients, depot.nurse_cap, depot.return_time))


end