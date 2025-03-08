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
    NUM_GEN = 10
    pop_size = 10
    growth_size = 2
    time_pen = 1
    num_time_pen = 1.5

    # Init pop
    init_pop = @time init_populations(patients, size(patients, 1), depot.num_nurses, pop_size, growth_size, time_matrix, depot.nurse_cap, depot.return_time)

    IB_X(time_matrix, patients, init_pop[1][1], init_pop[1][2], depot, 2)
    
    throw(Error(""))

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
                println(time_violation)
                best_id = j
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
            size(patients, 1),
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
            for i in 1:growth_size
                
                # Parent Selection:
                parent_ids = select_parents(pop)
                # Try first with roulette and then stochastic universal sampling
                
                # Handle different islands using the pop_id under the ModelPop datatype

                # Recombination and mutation based on which pop it is...
            
            end
            # Survivor selection:
            # Remove the n_p worst from the pop using eval.
        end
        
        # Check if pop_2 contains new best feasible solution
        # If so, migration will occur with some extra mutation shenanigans

        # Re-order the best solution to try and make it better.

        current_gen += 1
    end
    
end

run()
# println(solomon_seq_heur(size(patients, 1), depot.num_nurses, time_matrix, patients, depot.nurse_cap, depot.return_time))


end