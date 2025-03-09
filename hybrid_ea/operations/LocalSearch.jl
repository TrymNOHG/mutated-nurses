module LocalSearch

using ..Operations

export LNS!

function LNS!(r, individual, patients, travel_time_table)
    constrained_variables = remove!(r, individual, patients, travel_time_table)
    insert_var!(individual, constrained_variables, patients, travel_time_table)
    # Insertion based on heuristics (most constrained variable and least constraining value)
    # Maybe some modification of Farthest insertion heuristic
end

function remove!(r, individual, patients, travel_time_table)
    # removes list of patients 
    constrained_variables = []

    ### High Travel Time Removal ###
    # Considerations: 
    # Should the travel time of i be just the sum of the time from i-1 to i + i to i+1? 
    # Should the travel time be the "cost of insertion"?
    remove_by_insert_cost!(r, individual, travel_time_table, constrained_variables)
    ###################################

    
    return constrained_variables
end

function remove_by_insert_cost!(r, individual, travel_time_table, constrained_variables)
    insertion_costs = []
    for (i, route) in enumerate(individual)
        if size(route, 1) == 0
            continue
        end
        # from = 1
        from = route[1] + 1
        for j in 2:size(route, 1) - 1
            to = route[j] + 1
            insert_cost = travel_time_table(from, to) + travel_time_table(to, route[j+1]) - travel_time_table(from, route[j+1])
            push!(insertion_costs, (insert_cost, i, j))
            from = to
        end
        # insert_cost = travel_time_table(from, route[end] + 1) + travel_time_table(route[end] + 1, 1) - travel_time_table(from, 1)
        # push!(insertion_costs, (insert_cost, i, size(route, 1)))
    end

    sort!(insertion_costs, by=x->x[1], rev=true)

    deletion_values = []
    for info in insertion_costs[1:r]
        i = info[2]
        j = info[3]
        push!(constrained_variables, individual[i][j])
        push!(deletion_values, (i, j))
    end

    sort!(deletion_values, by=x->x[2], rev=true)
    for ind in deletion_values
        deleteat!(individual[ind[1]], ind[2])
    end


end

function remove_by_relatedness!()

end

function relatedness()
    # What metrics do I want to use to score the relatedness?
end

function insert_var!(routes, constrained_variables, patients, travel_time_table)
    # Could test with different discrepancies in the search (i.e., different allowable re-insertions for a given variable)
    found_solution = false
    while !found_solution
        patient_list = constrained_variables

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
            # println(insertion_patient_info)
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
end


end