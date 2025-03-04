module ParentSelection

using CSV
using DataFrames
using DataStructures

export tournament_select, nurse_fitness, simple_nurse_fitness

include("./Population.jl")
using .Population

function select_parents!(population, num_parents, output_file, best_individual)
    fitness_scores, best_of_pop = sigma_select(population, output_file, 2)
    if best_of_pop[1] > best_individual.fitness
        best_individual.fitness = best_of_pop[1]
        best_individual.genotype = best_of_pop[2]
    end
    return stochastic_universal_sampling(population, fitness_scores, num_parents)
end


function pop_fitness(population::Vector{T}, travel_time_table, patients, depot, fitness_func::Function) where {T}
    """
    This method takes a naive approach to parent selection by solely using the probability distribution given the fitness scores.
    """
    fitness_scores = Vector{Float32}() 
    total_fitness = 0
    for (i, individual) in enumerate(population)
        individ_fitness, objective_value = fitness_func(individual, travel_time_table, patients, depot)
        if objective_value < 4000
            println(individ_fitness)
        end
        if objective_value < 2000
            feasible, _, _ = is_feasible(individual, patients, depot, travel_time_table)
            # print(individual)
            # throw(Error(""))
            if feasible
                println("Objective value fell under 1000 for:")
                println()
                println(individual)
                actual_solution = []
                for i in 0:size(individual.indices, 1)
                    if i == 0
                        route = individual.values[1:individual.indices[1] - 1]
                    elseif i == size(individual.indices, 1)
                        route = individual.values[individual.indices[i]:end]
                    else
                        route = individual.values[individual.indices[i]:individual.indices[i+1] - 1]
                    end
                    push!(actual_solution, route)
                end
                println(actual_solution)
            end
        end
        push!(fitness_scores, individ_fitness)
        total_fitness += individ_fitness
    end

    # for i in 1:size(fitness_scores, 1)
    #     fitness_scores[i][1] /= total_fitness
    # end

    return fitness_scores, total_fitness
end

function sigma_select(population::Vector{T}, fitness_func::Function, c=2) where {T}
    fitness_scores = Vector{Vector{Float32}}() 
    total_fitness = 0
    for (i, individual) in enumerate(population)
        individ_fitness = fitness_func(individual)
        push!(fitness_scores, [individ_fitness, i])
        total_fitness += individ_fitness
    end

    mean = total_fitness / size(population, 1)
    std = sqrt(sum([(fitness - mean)^2 for (fitness, index) in fitness_scores]) / size(population, 1))

    best_of_pop = [minimum(fitness_scores)[1], population[Integer(minimum(fitness_scores)[2])]] # REMEMBER TO CHANGE BASED ON MAXIMIZATION OR MINIMIZATION PROBLEM!!!

    df = DataFrame(Max=maximum(fitness_scores)[1], Min=best_of_pop[1], Mean=mean)

    CSV.write(output_file, df, append=isfile(output_file))

    new_fitness_tot = 0
    for i in 1:size(fitness_scores,1)
        fitness_scores[i][1] = max(fitness_scores[i][1] - (mean - c * std), 0)
        new_fitness_tot += fitness_scores[i][1]
    end

    for i in 1:size(fitness_scores,1)
        fitness_scores[i][1] = 1 - (fitness_scores[i][1] / new_fitness_tot)
    end

    return fitness_scores, best_of_pop
end

function roulette_wheel_select(population, fitness_scores, num_parents)
    parents = []
    while num_parents > 0
        rand_num = rand()
        sum_prob = 0
        for (fitness_prob, i) in fitness_scores
            if rand_num >= sum_prob && rand_num <= sum_prob + fitness_prob
                push!(parents, population[Integer(i)])
            else
                sum_prob += fitness_prob
            end
        end
        num_parents -= 1
    end
    return parents
end

function stochastic_universal_sampling(population, fitness_scores, num_parents)
    parents = []
    init_rand_num = rand()
    prob_slice = 1/num_parents
    probs = [(init_rand_num + prob_slice * i)%1 for i in 1:num_parents]
    sort!(probs)

    sum_prob = 0
    prob_index = 1
    for (fitness_prob, i) in fitness_scores
        while prob_index < size(probs, 1) + 1 && probs[prob_index] >= sum_prob && probs[prob_index] <= sum_prob + fitness_prob
            push!(parents, population[Integer(i)])
            prob_index += 1
        end
        sum_prob += fitness_prob
    end
    return parents
end

function tournament_select(population, num_parents::Integer, k::Integer, travel_time_table, patients, depot)
    chosen_parents = []
    fitness_scores, total_fitness = pop_fitness(population, travel_time_table, patients, depot, nurse_fitness) # (id_of_individual, fitness_score)
    num_parents_chosen = 0
    while num_parents_chosen < num_parents
        # Perform sampling and comparison
        sample = [rand(1:size(population, 1)) for _ in 1:k] # Sampling with Replacement (could also do without at a later point...)
        winner = (typemax(Int32), nothing)
        for i in sample
            fitness = fitness_scores[i]
            if fitness < winner[1]                  # Deterministic probability since the most fit individual from the sample is chosen.
                winner = (fitness, population[i])
            end
        end
        push!(chosen_parents, winner[2]) 
        # println(winner[1])
        num_parents_chosen += 1
    end
    # println(chosen_parents)

    return chosen_parents
end

function nurse_fitness(individual, travel_time_table, patients, depot)
    # Constraints:
    #   Soft:
    #       - Late return       (Added as a penalty)
    #       - Capacity exceeded (Added as a penalty)
    #   Hard:
    #       - Patient time-windows are met (Should be dealt with prior to coming to this function)
    #       - Each patient is only visited once (encoded)

    # TODO: add wait time to nurse_time

    total_time = 0
    objective_value = 0
    for i in 0:size(individual.indices, 1)
        if i == 0
            route = individual.values[1:individual.indices[1] - 1]
        elseif i == size(individual.indices, 1)
            route = individual.values[individual.indices[i]:end]
        else
            route = individual.values[individual.indices[i]:individual.indices[i+1] - 1]
        end

        nurse_time = 0
        nurse_demand = 0

        from = 1 # Depot if depot is 1
        for patient_id in route
            to = patient_id + 1 # Plus 1 to account for the depot 
            wait_time = 0
            nurse_time += travel_time_table[from][to] + patients[patient_id].care_time + wait_time # Duration
            nurse_demand += patients[patient_id].demand
            objective_value += travel_time_table[from][to]
            from = to
        end
        to = 1 # Return to depot
        nurse_time += travel_time_table[from][to]
        objective_value += travel_time_table[from][to]

        if nurse_time > depot.return_time
            nurse_time *= 10            # Penalty for late return
        end

        if nurse_demand > depot.nurse_cap      # Penalty for exceeding nurse capacity
            nurse_time *= 10
        end

        total_time += nurse_time
    end

    feasible, multiplier, total_time = is_feasible(individual, patients, depot, travel_time_table)
    total_time *= multiplier

    # If we use the total_time, then this is a minimization optimization problem. Keep this in mind.
    return total_time, objective_value

end

function simple_nurse_fitness(individual, travel_time_table)
    # At first, the fitness function will solely contain the total time travelled given the routes for all the nurses
    # Therefore, I will need to gather the routes to calculate this.
    total_time = 0
    for (i, route) in enumerate(individual)
        from = 1 # Depot if depot is 1
        for (_, patient_id) in enumerate(route)
        to = patient_id + 1 # Plus 1 to account for the depot 
            total_time += travel_time_table[from][to]
            from = to
        end
        to = 1 # Return to depot
        total_time += travel_time_table[from][to]
    end

    # If we use the total_time, then this is a minimization optimization problem. Keep this in mind.
    return total_time
end


end