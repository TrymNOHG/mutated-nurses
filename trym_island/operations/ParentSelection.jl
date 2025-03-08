module ParentSelection

using CSV
using DataFrames
using DataStructures

export tournament_select, select_parents

using ..Models
using ..Operations
# using ...Modules
# include("../models/Models.jl")
# using .Models

function select_parents(population)
    fitness_probs = sigma_select(population, 2)
    return roulette_wheel_select(fitness_probs, population.lambda)
    # return stochastic_universal_sampling(population, fitness_scores, num_parents)
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
            println("Objective value fell under 1000 for:")
            println(is_feasible(individual, patients, depot, travel_time_table))
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
                actual_solution.append(route)
            end
            println(actual_solution)
        end
        push!(fitness_scores, individ_fitness)
        total_fitness += individ_fitness
    end

    # for i in 1:size(fitness_scores, 1)
    #     fitness_scores[i][1] /= total_fitness
    # end

    return fitness_scores, total_fitness
end

function sigma_select(population::ModelPop, c=2)
    output_file = population.log_dir * "/temp.csv"
    fitness_scores = population.fitness_array[1:end] # Create a copy
    total_fitness = 0
    for fitness in fitness_scores
        total_fitness += fitness
    end
    # println(fitness_scores)
    # println("Mean")
    mean = total_fitness / size(fitness_scores, 1)
    # println(mean)
    # println("STD")
    std = sqrt(sum([(fitness - mean)^2 for fitness in fitness_scores]) / size(fitness_scores, 1))
    # println(std)

    best_solution = [minimum(fitness_scores), population.genes[argmin(fitness_scores)].gene_r] # CHANGE BASED ON MAXIMIZATION OR MINIMIZATION PROBLEM!!!

    # Log
    df = DataFrame(Max=maximum(fitness_scores), Min=best_solution[1], Mean=mean)
    CSV.write(output_file, df, append=isfile(output_file))

    new_fitness_tot = 0
    for i in 1:size(fitness_scores, 1)
        fitness_scores[i] = max(fitness_scores[i] - (mean - c * std), 0)
        new_fitness_tot += fitness_scores[i]
    end

    for i in 1:size(fitness_scores,1)
        fitness_scores[i] = fitness_scores[i] / new_fitness_tot
    end

    # Fix this function...

    return fitness_scores
end

function roulette_wheel_select(fitness_scores, num_parents)
    parent_ids = []
    while num_parents > 0
        rand_num = rand()
        sum_prob = 0
        for (i, fitness_prob) in enumerate(fitness_scores)
            if sum_prob <= rand_num <= sum_prob + fitness_prob
                push!(parent_ids, i)
            else
                sum_prob += fitness_prob
            end
        end
        num_parents -= 1
    end
    return parent_ids
end

function stochastic_universal_sampling(population, fitness_scores, num_parents) # Currently with replacement, allowing multiple of same parent
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




end