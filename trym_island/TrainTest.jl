module TrainTest

include("models/Models.jl")
using .Models

include("operations/Operations.jl")
using .Operations

include("utils/NurseReader.jl")
using .NurseReader

using CSV

# extract_nurse_data("./data/test/test_2.json", "./data/bin/serialized_test_2.bin")
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

    # Init pop
    init_pop = @time init_populations(patients, size(patients, 1), depot.num_nurses, pop_size, growth_size, time_matrix, depot.nurse_cap, depot.return_time)

    populations = []
    for pop in init_pop
        popu = []
        for individual in pop
            gene_r = individual
            sequence = collect(Iterators.flatten(gene_r))
            fitness = 0
            time_violation = false
            for route in individual
                cost, time_violation, _, _ = calculate_cost(route, patients, time_matrix)
                fitness += cost
                if time_violation
                    break
                end
            end
            push!(popu, Gene(
                sequence,
                fitness,
                gene_r,
                [],
                [],
                [],
                [],
                []
            ))
        end
    end
    # clear!(init_pop)

    println(populations[1])
    throw(Error(""))
    current_gen = 0 
    # Evolutionary loop
    while current_gen < NUM_GEN
        for (i, pop) in enumerate(populations)  # Embarrasingly Parallelizable Here. So, try and do something with that... add Threads.@threads
            for i in 1:growth_size

                # Parent Selection:
                roulette_wheel_select(population, fitness_scores, num_parents)
                # Try first with roulette and then stochastic universal sampling
                if i == 1
                    # Handle island 1
                else
                    # Handle island 2
                end
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