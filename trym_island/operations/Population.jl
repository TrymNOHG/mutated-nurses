module Population

import Random.Xoshiro
import Random.randperm!
import Random.shuffle!

using ..Neighborhood
using ..ParentSelection

export init_permutation, init_bitstring, init_permutation_specific, repair!, is_feasible, re_init

# Feasible solutions for initial populations are first generated using a sequential insertion heuristic in which customers are inserted in 
# random order at randomly chosen insertion positions within routes. This strategy is fast and simple while ensuring unbiased solution generation. 
# The initialization procedure then proceeds as follows:

function init_rand_pop(num_patients, num_nurses)
    gene_r = [[] for _ in 1:num_nurses]
    patients_list = [i for i in 1:num_patients]
    shuffle!(patients_list)
    for i in patients_list
        push!(gene_r[rand(1:num_nurses)], i)
    end
    return gene_r
end

function init_populations(patients, num_patients, num_nurses, mu, n_p)
    populations = [init_rand_pop(num_patients, num_nurses) for _ in 1:2]
    for pop in populations
        for _ in 1:n_p
            # Apparently the next steps:
            # Generate a new solution Sj using the EE_M mutator (defined in Section 2.3.2)
            # Add Sj in Pop_x
            solution = EE_M(pop[rand(1:size(pop, 1))], patients)
            push!(pop, solution)
        end
        # Higher eval indicates worse individual
        # r_m - constant
        gamma = 1
        time_pen = 1
        num_time_pen = 1
        scores = []
        
        for (i, individual) in enumerate(pop)
            value = eval(individual, patients, travel_time_table, num_patients, r_m, gamma, time_pen, num_time_pen) 
            push!(scores, (value, i))
        end

        sort!(scores, by=x->x[1], rev=true)
        n_p_worst = scores[1:n_p]
        sort!(n_p_worst, by=x->x[2], rev=true) # So that removing the individuals does not affect the other individuals' indices.
        
        for instance in n_p_worst
            deleteat!(pop, instance[2])
        end            
    end
    # Additional steps:
    # Determine Rmin, the minimum number of tours associated with a feasible solution in Pop1 or Pop2. Replicate (if needed) best feasible solution (Rmin routes) in Pop1.
    # Replace Pop1 individuals with Rmin-route solutions using the procedure RI(Rmin).
    # Replace Pop2 members with Rmin-1 -route solutions using the procedure RI(Rmin-1).

end

function calculate_cost(route, patients, travel_time_table)
    """
    This function calculates the cost of a given route. If the route contains time window violation, then that is also notified.
    Output is therefore: cost, violates
    """
    from = 1
    time = 0
    for patient_id in route
        to = patient_id + 1
        time += travel_time_table(from, to)
        if time < patients[patient_id].start_time
            time = patients[patient_id].start_time + patients[patient_id].care_time
            from = to
        elseif patients[patient_id].start_time <= time <= patients[patient_id].end_time - patients[patient_id].care_time
            time += patients[patient_id].care_time
            from = to
        else
            println(route)
            println(time)
            return -1, true
        end
    end
    time += travel_time_table(from, 1) # Return to depot
    return time, false
end

function regret_cost(patient_id, neighbors, routes, travel_time_table, patients)
    min_insert_r  = []
    for centroid_info in neighbors
        route_id = Int(centroid_info[2])
        neighbor_route = routes[route_id]
        min_insert_cost = (typemax(Int32), 0) # Fitness, position

        current_route_cost, time_violation = calculate_cost(neighbor_route, patients, travel_time_table)
        if time_violation
            throw(Error("Time violation should not occur here"))
        end

        for i in 1:size(neighbor_route, 1)+1 # Need to check insertion at end as well.
            # Need to re-evaluate the whole route because an insertion could ruin for the patients...
            insert!(neighbor_route, i, patient_id)
            cost, time_violation = calculate_cost(neighbor_route, patients, travel_time_table)
            insert_cost = cost - current_route_cost
            if !time_violation && insert_cost < min_insert_cost[1]
                min_insert_cost = (insert_cost, i)
            end
            deleteat!(neighbor_route, i)
        end

        push!(min_insert_r, (min_insert_cost[1], min_insert_cost[2], route_id)) # Fitness, position, route_id
    end
    
    # With two neighborhood routes, the regret value essentially becomes the regret value of the max - min.
    # min_cost_neigh = minimum(first.(min_insert_r))
    # regret_cost = 0
    # for cost, route_id, position in min_insert_r
    #     regret_cost += cost - min_cost_neigh
    # end
    if minimum(first.(min_insert_r)) == typemax(Int32) # This would mean that the patient has no insertion positions that do not violate the time constraint...
        return -1, (), true
    end
    total_regret_cost = maximum(first.(min_insert_r)) - minimum(first.(min_insert_r))
    return total_regret_cost, min_insert_r[argmin(min_insert_r)], false
end

function re_init(num_nurses, num_patients, travel_time_table, patients)
    """
    This function acts to create feasible (or near feasible) individuals. It helps increase the diversity and quality of the population, especially considering
    the time window constraint. 
    It essentially works like this:
        1. Provide each nurse with one patient randomly.
        2. Loop the following until not possible anymore:
            - Calculate every patients regret cost based on the principle of minimum insertion into a 2-route neighborhood.
            - Set aside the patients who no matter what, violate the time constraint.
            - Find the patient with the highest regret cost and insert them into the minimum insertion cost position.
        3. Deal with the stubborn violation patients by running an extended insertion regret cost thing.
    
    Potential improvements:
        - There are a lot of places for improvements. There are some embarrasingly parallelizable snippets, as well as places where caching should definitely be leveraged.
    """
    patient_list = [i for i in 1:num_patients]
    shuffle!(patient_list)
    routes = [[pop!(patient_list)] for i in 1:num_nurses]

    violation_patients = []
    centroids = get_all_centroids(routes, patients)

    while size(patient_list, 1) > 0
        regret_costs = []
        i = 1
        while i <= size(patient_list, 1)
            patient_id = patient_list[i]
            closest_neighbors = get_route_neighborhood(centroids, 0, patients[patient_id]) 
            cost, insertion_pos, time_violation = regret_cost(patient_id, closest_neighbors, routes, travel_time_table, patients)
            if time_violation
                deleteat!(patient_list, i)
                push!(violation_patients, patient_id)
                i -= 2
            else
                push!(regret_costs, (cost, insertion_pos, patient_id, i))
            end
            i += 1
        end

        # The patients with the highest regret costs are inserted first, since they will have fewer good options later.
        insertion_patient_info = regret_costs[argmax(regret_costs)]
        position = insertion_patient_info[2][2]
        route_id = insertion_patient_info[2][3]
        patient_id = insertion_patient_info[3]
        i = insertion_patient_info[4]
        # Insert in locations that minimize cost and do not violate time-window constraint.
        insert!(routes[route_id], position, patient_id)
        deleteat!(patient_list, i)
        
        # Once I have inserted, I can update the centroid for the route inserted into.
        centroids[route_id] = (get_centroid(routes[route_id], patients))
        
    end 

    return routes

    # Now to handle the infeasible patients...
    # Need extended insertion regret cost function...
    # Test the function and see if I get any violations at all from this construction...
end

function is_feasible(individual, patients, depot, travel_time_table)
    # if length(Set(individual.values)) != size(patients, 1)
    #     return false
    # end
    multiplier = 1

    for i in 0:size(individual.indices, 1)
        if i == 0
            route = individual.values[1:individual.indices[1] - 1]
        elseif i == size(individual.indices, 1)
            route = individual.values[individual.indices[i]:end]
        else
            route = individual.values[individual.indices[i]:individual.indices[i+1] - 1]
        end
        time = 0
        demand = 0
        from = 1
        # println()
        for (i, patient) in enumerate(route)
            # println(patient)
            # println(patients[patient])
            demand += patients[patient].care_time
            to = i + 1
            time += travel_time_table[from][to]
            if time < patients[patient].start_time
                time = patients[patient].start_time + patients[patient].care_time
                from = to
            elseif patients[patient].start_time <= time <= patients[patient].end_time - patients[patient].care_time
                time += patients[patient].care_time
                from = to
            else
                # println(time)
                # println("Time window violation")
                multiplier += 1
                # return false
            end
        end
        if demand > depot.nurse_cap || time > depot.return_time
            multiplier += 0.5
        end
    end

    return multiplier == 1, multiplier
    # Check demand
    # Check scheduling
    # Check return time
    # Could also check that each patient is only visited once (but this is a bit unnecessary)
end



end