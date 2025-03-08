module Population

import Random.Xoshiro
import Random.randperm!
import Random.shuffle!

using ..Operations

export init_permutation, init_bitstring, init_permutation_specific, repair!, is_feasible, re_init, init_populations, calculate_cost, init_seq_heur_pop, solomon_seq_heur

function init_rand_pop(num_patients, num_nurses)
    gene_r = [[] for _ in 1:num_nurses]
    patients_list = [i for i in 1:num_patients]
    shuffle!(patients_list)
    for i in patients_list
        push!(gene_r[rand(1:num_nurses)], i)
    end
    return gene_r
end

function solomon_seq_heur(num_patients, num_nurses, travel_time_table, patients, nurse_cap, latest_return)
    """
    This function is inspired by Solomon's insertion heuristic method described in his paper 
    "Algorithms for the Vehicle Routing and Scheduling Problems with Time Window Constraints". Essentially, it utilizes a spatio-temporal heuristic
    for deciding which patients to feasibly insert in a route. Once a route can no longer be extended, a new route is started.

    Potential changes:
    - Initialize a random number of routes with patients in order to increase diversity.
    """
    patient_list = [i for i in 1:num_patients]
    shuffle!(patient_list)
    routes = [[pop!(patient_list)]]
    current_route = routes[1]
    while size(routes, 1) <= num_nurses || size(patient_list, 1) > 0

        # Find best insertion place and heuristic value
        # Find best customer with best heuristic value and insert customer. Rinse and repeat.
        candidates = []
        for (i, patient_id) in enumerate(patient_list)
            best_insertion = (typemax(Int32), -1)
            if size(current_route, 1) == 0 # Not the best approach...
                time = travel_time_table(1, patient_id+1)
                if time < best_insertion[1]
                    best_insertion = (travel_time_table(1, patient_id+1), 1, patient_id, i)
                end
            else
                for j in 1:size(current_route, 1) # Look at all insertions
                    insert!(current_route, j, patient_id)
                    objective_time, time_violation, demand, return_time = calculate_cost(current_route, patients, travel_time_table) # Maybe should allow infeasible here?
                    deleteat!(current_route, j)
                    if time_violation || demand > nurse_cap || return_time > latest_return # Insertion is only feasible if all hard constraints are satisfied.
                        continue
                    else
                        if objective_time < best_insertion[1]
                            best_insertion = (objective_time, j, patient_id, i)
                        end
                    end
                end
            end
            if best_insertion[1] != typemax(Int32)
                push!(candidates, best_insertion)
            end
        end
        if size(candidates, 1) == 0 || rand() < 0.3
            if size(routes, 1) == num_nurses
                break
            else
                push!(routes, [])
                current_route = routes[end]
            end
        else
            sort!(candidates, by=x->x[1])
            insert!(current_route, candidates[1][2], candidates[1][3])
            deleteat!(patient_list, candidates[1][4])
        end
    end

    # Hopefully, it does not get to this point...
    if size(patient_list, 1) > 0
        # Here, I could do something similar to the re-initialization and insert the patients with the highest regret first to try and increase chances of feasible solution...
        violation_patients = []
        centroids = get_all_centroids(routes, patients)
        while size(patient_list, 1) > 0
            regret_costs = []
            i = 1
            while i <= size(patient_list, 1)
                patient_id = patient_list[i]
                closest_neighbors = get_route_neighborhood(size(centroids, 1), centroids, 0, patients[patient_id]) # Allows more than just 2 route neighbors
                cost, insertion_pos, time_violation = regret_cost(patient_id, closest_neighbors, routes, travel_time_table, patients)
                if time_violation
                    deleteat!(patient_list, i)
                    push!(violation_patients, patient_id)
                    i -= 1
                else
                    push!(regret_costs, (cost, insertion_pos, patient_id, i))
                end
                i += 1
            end
            
            if size(regret_costs, 1) == 0
                break
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
        
        # Deal with the final stubborn patients... (won't get feasible solution at this point)
        for patient in violation_patients
            push!(routes[rand(1:size(routes, 1))], patient)
        end
        # Try and insert them
    end

    return routes
end

function init_seq_heur_pop(num_patients, num_nurses, travel_time_table, patients)
    patient_list = [i for i in 1:num_patients]
    shuffle!(patient_list)
    routes = [[pop!(patient_list)] for i in 1:num_nurses]

    # Sequential heuristic approach now.
    # Improvement: Could select next patient based on heuristics, currently random.
    violation_patients = []
    centroids = get_all_centroids(routes, patients)
    for patient_id in patient_list
        closest_neighbors = get_route_neighborhood(num_nurses, centroids, 0, patients[patient_id]) 
        cost, insertion_pos, time_violation = regret_cost(patient_id, closest_neighbors, routes, travel_time_table, patients) # Overhead, change later...
        if time_violation
            deleteat!(patient_list, i)
            push!(violation_patients, patient_id)
            continue
        end
        position = insertion_pos[2]
        route_id = insertion_pos[3]
        insert!(routes[route_id], position, patient_id)
        # deleteat!(patient_list, i)
        
        # Once I have inserted, I can update the centroid for the route inserted into.
        centroids[route_id] = (get_centroid(routes[route_id], patients))
    end

    for patient_id in violation_patients
        push!(routes[rand(1:num_nurses)], patient_id)
    end

    return routes
end

function init_populations(patients, num_patients, num_nurses, mu, n_p, travel_time_table, capacity, latest_return)
    # populations = [[init_seq_heur_pop(num_patients, num_nurses, travel_time_table, patients) for _ in 1:mu] for _ in 1:2]
    populations = [[solomon_seq_heur(num_patients, num_nurses, travel_time_table, patients, capacity, latest_return) for _ in 1:mu] for _ in 1:2]
    for pop in populations
        for _ in 1:n_p
            solution = EE_M(pop[rand(1:size(pop, 1))], patients, travel_time_table)
            push!(pop, solution)
        end
        # Higher eval indicates worse individual
        total_demand = 0
        for patient in patients
            total_demand += patient.demand
        end
        total_capacity = num_nurses * capacity
        r_m = total_demand / total_capacity
        gamma = 1
        time_pen = 1
        num_time_pen = 1
        scores = []
        
        for (i, individual) in enumerate(pop)
            value = evaluate(individual, patients, travel_time_table, num_patients, r_m, gamma, time_pen, num_time_pen) 
            push!(scores, (value, i))
        end

        sort!(scores, by=x->x[1], rev=true)
        n_p_worst = scores[1:n_p]
        sort!(n_p_worst, by=x->x[2], rev=true) # So that removing the individuals does not affect the other individuals' indices.
        
        for instance in n_p_worst
            deleteat!(pop, instance[2])
        end            
    end

    # I am looking for the minimum number of nurses needed for a feasible/viable solution. Assumption here is that fewer nurses generally means shorter travel time.
    best_individual, r_min_1 = r_min(populations[1], patients, travel_time_table)
    best_individual_2, r_min_2 = r_min(populations[2], patients, travel_time_table)

    populations[1][1] = r_min_2 < r_min_1 ? best_individual_2 : best_individual
    r_min_1 = min(r_min_1, r_min_2)

    # Here, I re-initialize the pop_1 with r_min nurses in an effort to construct fewer routes (generally more optimal). All but the best solution is re-initialized.
    for i in 2:size(populations[1], 1)
        populations[1][i] = re_init(r_min_1, num_patients, travel_time_table, patients)
    end

    # I do the same thing here for pop_2 but with less routes. All individuals will be replaced in this population.
    for i in 1:size(populations[2], 1)
        populations[2][i] = re_init(r_min_1-1, num_patients, travel_time_table, patients)
    end
    
    return populations
end

function calculate_cost(route, patients, travel_time_table)
    """
    This function calculates the cost of a given route. If the route contains time window violation, then that is also notified.
    Output is therefore: Objective time, time_violation, total demand, return_time
    """
    if size(route, 1) == 0
        return 0, false, false, false
    end

    from = 1
    time = 0
    demand = 0
    objective_time = 0
    for patient_id in route
        to = patient_id + 1
        time += travel_time_table(from, to)
        objective_time += travel_time_table(from, to)
        demand += patients[patient_id].demand
        if time < patients[patient_id].start_time
            time = patients[patient_id].start_time + patients[patient_id].care_time
            from = to
        elseif patients[patient_id].start_time <= time <= patients[patient_id].end_time - patients[patient_id].care_time
            time += patients[patient_id].care_time
            from = to
        else
            # Time violation
            return -1, true, -1, -1
        end
    end
    time += travel_time_table(from, 1) # Return to depot
    objective_time += travel_time_table(from, 1)
    return objective_time, false, demand, time
end

function regret_cost(patient_id, neighbors, routes, travel_time_table, patients)
    min_insert_r  = []
    for centroid_info in neighbors
        route_id = Int(centroid_info[2])
        neighbor_route = routes[route_id]
        min_insert_cost = (typemax(Int32), 0) # Fitness, position

        current_route_cost, time_violation, _, _ = calculate_cost(neighbor_route, patients, travel_time_table)
        if time_violation
            throw(Error("Time violation should not occur here"))
        end

        for i in 1:size(neighbor_route, 1)+1 # Need to check insertion at end as well.
            # Need to re-evaluate the whole route because an insertion could ruin for the patients...
            # Could use a variation of Clarke and Wright's savings algorithm instead of checking the whole path cost... 
            insert!(neighbor_route, i, patient_id)
            cost, time_violation, _, _ = calculate_cost(neighbor_route, patients, travel_time_table)
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
    found_solution = false
    while !found_solution
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
                # closest_neighbors = get_route_neighborhood(5, centroids, 0, patients[patient_id]) # Allows more than just 2 route neighbors, which could be interesting to look at 
                closest_neighbors = get_route_neighborhood(centroids, 0, patients[patient_id]) 
                cost, insertion_pos, time_violation = regret_cost(patient_id, closest_neighbors, routes, travel_time_table, patients)
                if time_violation
                    deleteat!(patient_list, i)
                    push!(violation_patients, patient_id)
                    # i -= i == 1 ? 1 : 2
                    i -= 1
                else
                    push!(regret_costs, (cost, insertion_pos, patient_id, i))
                end
                i += 1
            end

            # The patients with the highest regret costs are inserted first, since they will have fewer good options later.
            if size(regret_costs, 1) == 0
                break
            end
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
        if size(patient_list, 1) > 0
            continue
        end

        return routes
    end
    # Now to handle the infeasible patients...
    # Need extended insertion regret cost function...
    # Test the function and see if I get any violations at all from this construction...
end

function r_min(pop, patients, travel_time_table)
    # Find the minimum number of routes from all the feasible solutions in the population.
    # Check if a route is empty, then this indicates a route is not needed.
    feasible_individuals = [] # Will contain (r_min_val, objective_function_val)
    # println("Population")
    # println(pop)
    # println(pop[1])
    for (i, individual) in enumerate(pop)
        total_time = 0
        feasible_solution = true
        r_min_individual = 0
        for route in individual
            if size(route, 1) == 0
                continue
            end
            time, time_violation, _, _ = calculate_cost(route, patients, travel_time_table)
            total_time += time
            r_min_individual += 1
            if time_violation
                feasible_solution = false
                break
            end
        end
        if feasible_solution
            push!(feasible_individuals, (r_min_individual, total_time, i))
        end

        # Check if it is feasible.
        # Check its objective function (specific to the population)?
        # Check its number of routes (making sure to not include empty routes in the number)
    end

    # Sort all individuals by their number of routes, then perform a second ordering based on their fitness. Choose the individual with the smallest r_min but best fitness (lowest time).
    sort!(feasible_individuals, by=x->(x[1], x[2]))
    # println(feasible_individuals)
    r_min_val = feasible_individuals[1][1]
    best_individual = feasible_individuals[1][3]
    return pop[best_individual], r_min_val
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
        for (i, patient) in enumerate(route)
            demand += patients[patient].care_time
            to = patient + 1
            time += travel_time_table(from, to)
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