module Recombination

export perform_crossover!, order_1_crossover!, PMX!, gen_edge_table, TBX!, edge_3_crossover!, IB_X

using ..Operations
using ..Models


import Random.shuffle!

function perform_crossover!(parent_ids, population, patients, num_patients, travel_time_table, depot, cross_rate, time_pen, num_time_pen)
    """
    This function performs one-point cross-over on a list of parents. To increase
    the randomness associated with recombination, the parents list is shuffled before
    two parents are drawn.
    """
    current_index = 1

    shuffle!(parent_ids)
    while current_index < size(parent_ids, 1)
        parent_1, parent_2 = parent_ids[current_index:current_index+1]
        parent_1 = population.genes[parent_1].gene_r
        parent_2 = population.genes[parent_2].gene_r
        if rand() < cross_rate
            child_gene = IB_X(travel_time_table, patients, parent_1, parent_2, depot, 5)
            child = get_gene_from_2d_arr(population.pop_id, child_gene, patients, travel_time_table, time_pen, num_time_pen)
            push!(population.genes, child)
            push!(population.fitness_array, child.fitness)
            # println("child1.fitness")
            # println(child.fitness)
            child_gene_2 = IB_X(travel_time_table, patients, parent_2, parent_1, depot, 5)
            child_2 = get_gene_from_2d_arr(population.pop_id, child_gene_2, patients, travel_time_table, time_pen, num_time_pen)
            push!(population.genes, child_2)
            push!(population.fitness_array, child_2.fitness)
            # println("child2.fitness")
            # println(child_2.fitness)
            # TBX!(parent_1, parent_2, survivors, num_patients)
            # TBX!(parent_2, parent_1, survivors, num_patients)
            # PMX!(parent_1, parent_2, survivors, num_patients)
            # PMX!(parent_1, parent_2, survivors, num_patients)
            # edge_3_crossover!(parent_1, parent_2, survivors, num_patients)
            # edge_3_crossover!(parent_2, parent_1, survivors, num_patients)
            # order_1_crossover!(parent_1, parent_2, survivors, num_patients)
            # order_1_crossover!(parent_2, parent_1, survivors, num_patients)
        else
            push!(population.genes, parent_1)
            push!(survivors, parent_2)
        end
        current_index += 2
    end
end

# TODO: test differnet crossover methods
# TODO: implement repair functionality for crossover

function order_1_crossover!(parent_1, parent_2, survivors, num_patients)
    split_index_1 = rand(1:num_patients)
    split_index_2 = rand(1:num_patients)
    interval = (min(split_index_1, split_index_2), max(split_index_1, split_index_2))

    child_values = [0 for _ in 1:num_patients]
    segment = parent_1.values[interval[1]:interval[2]]
    child_values[interval[1]:interval[2]] = segment
    parent_2_index = (interval[2] % num_patients) + 1
    child_index = parent_2_index

    while child_index < interval[1] || child_index > interval[2]

        potential_val = parent_2.values[parent_2_index]
        in_seg = false
        for val in segment
            if potential_val == val
                in_seg = true
                break
            end
        end

        if in_seg == false
            child_values[child_index] = potential_val
            child_index = (child_index % num_patients) + 1
        end
        
        parent_2_index = (parent_2_index % num_patients) + 1 # Could make into if statements if modulo costs too much

    end 

    # Could easily make two children just by using different route indices


    child = Solution(child_values, parent_1.indices)
    push!(survivors, child)
end

function hash_index(list_2, result, start_index)
    for i in 1:size(list_2, 1)
        if list_2[i] == result[start_index]
            return i
        end
    end
    throw(Error(""))
    return 0
end


function PMX!(parent_1, parent_2, survivors, num_patients)
    split_index_1 = rand(1:num_patients)
    split_index_2 = rand(1:num_patients)
    interval = (min(split_index_1, split_index_2), max(split_index_1, split_index_2))

    child_values = [0 for _ in 1:num_patients]
    segment = parent_1.values[interval[1]:interval[2]]
    child_values[interval[1]:interval[2]] = segment

    for i in interval[1]:interval[2]
        if parent_2.values[i] ∉ segment
            # println(i)
            # println(parent_2.values[i])
            index = i
            while interval[1] <= index <= interval[2]
                index = hash_index(parent_2.values, child_values, index)
                # println(index)
            end
            child_values[index] = parent_2.values[i]
        end
    end

    j = 1
    for i in 1:size(child_values, 1)
        while interval[1] <= j <= interval[2]
            j += 1
        end
        if j > size(parent_2.values, 1)
            break
        end
        if parent_2.values[j] in segment
            j += 1
        elseif child_values[i] == 0
            child_values[i] = parent_2.values[j]
            j += 1
        end
    end

    child = Solution(child_values, parent_1.indices)
    push!(survivors, child)
end

function gen_edge_table(parent_1_vals, parent_2_vals)
    edge_table = [[] for _ in 1:size(parent_1_vals, 1)]
    for i in 1:size(parent_1_vals, 1)
        left_index = i > 1 ? i - 1 : size(parent_1_vals, 1) 
        right_index = i < size(parent_1_vals, 1) ? i + 1 : 1
        p_1_left = parent_1_vals[left_index]
        p_1_right = parent_1_vals[right_index]
        p_2_left = parent_2_vals[left_index]
        p_2_right = parent_2_vals[right_index]
        push!(edge_table[parent_1_vals[i]], p_1_left)
        push!(edge_table[parent_1_vals[i]], p_1_right)
        push!(edge_table[parent_2_vals[i]], p_2_left)
        push!(edge_table[parent_2_vals[i]], p_2_right)
    end
    return edge_table
end

function add_edge!(results, edge_table, index)
    push!(results, index)
    for edges in edge_table
        deleted = 0
        for i in 1:size(edges, 1)
            if edges[i-deleted] == index
                deleteat!(edges, i-deleted)
                deleted += 1
            end
        end
    end
end

function find_common_edge(edges)
    for (i, val) in enumerate(edges)
        if i < size(edges, 1)
            for other_val in edges[i+1:end]
                if val == other_val 
                    # Then, common edge found.
                    return true, val
                end
            end
        end
    end
    return false, 0
end

function find_shortest_list(edge_table, edges)
    candidates = []
    shortest_length = 4
    for val in edges
        len = length(Set{Int32}(edge_table[val]))
        if len < shortest_length
            candidates = [val]
            shortest_length = len
        elseif len == shortest_length
            push!(candidates, val)
        end
    end
    return candidates
end

function edge_3_crossover!(parent_1, parent_2, survivors, num_patients)
    # Need to implement the detection/representation of common edges better.
    edge_table = gen_edge_table(parent_1.values, parent_2.values)
    current_index = rand(1:num_patients)
    result = []
    add_edge!(result, edge_table, current_index)
    while size(result, 1) < num_patients
        edges = edge_table[current_index]
        if size(edges, 1) == 0
            current_index = rand(1:num_patients) # Seems like it can take a while to find the last value...
            continue
        end
        is_common_edge, val = find_common_edge(edges)
        if is_common_edge == true
            current_index = val
        else
            # No common edge, then find entry with shortest list, else random
            shortest_list_candidates = find_shortest_list(edge_table, edges)
            current_index = shortest_list_candidates[rand(1:size(shortest_list_candidates, 1))]
        end
        add_edge!(result, edge_table, current_index)
    end

    # Random -> Shortest_list (from random's edges) -> Common Edge
    child = Solution(result, parent_1.indices)
    push!(survivors, child)
end

function TBX!(parent_1, parent_2, survivors, num_patients)
    # Naive/slow implementation
    split_index_1 = rand(1:num_patients)
    split_index_2 = rand(1:num_patients)
    interval = (min(split_index_1, split_index_2), max(split_index_1, split_index_2))

    child_values = parent_2.values[1:end]
    child_values[interval[1]:interval[2]] = parent_1.values[interval[1]:interval[2]]

    xover_map = [i for i in 1:num_patients]
    shuffle!(xover_map)

    for i in 1:size(child_values, 1)
        child_values[i] =  child_values[i] * num_patients + xover_map[i]
    end

    values = child_values[1:end]
    sort!(values)
    for i in 1:size(values, 1)
        for j in 1:size(child_values, 1)
            if child_values[j] == values[i]
                child_values[j] = i
            end
        end 
    end

    child = Solution(child_values, parent_1.indices)
    push!(survivors, child)

end

function IB_X(travel_time_table, patients, parent_1, parent_2, depot, k=2)
    unassigned_patients = Set{Int32}()
    r_1 = [] # Will contain k routes from parent_1
    distances = []
    for (i, route) in enumerate(parent_1)
        if size(route, 1) == 0
            continue
        end
        push!(distances, (route_distance(route, travel_time_table)/size(route, 1), route))
    end
    
    for _ in 1:k
        max_intra_route_dist = argmax(distances) # Max distance between children
        push!(r_1, distances[max_intra_route_dist][2])
        deleteat!(distances, max_intra_route_dist)
    end

    for remain_route in distances
        union!(unassigned_patients, remain_route[2]) # This adds all the patients not included in parent 1's route.
    end

    # The set of unassigned patients is the set_of_patients\patients_in_chosen_routes

    # Get the centroids of the selected routes
    parent_1_centroids = [get_centroid(route, patients) for route in r_1]

    parent_2_centroids = get_all_centroids(parent_2, patients)

    ### MINIMIZING LOCAL INTER-CENTROID DISTANCE ###
    # Essentially, include parent 2 routes that are the closest to r_1s' centroids, individually.

    r_2 = []
    r_2_added = [] # Containing indices
    for p1_centroid in parent_1_centroids
        inter_dist = []
        for (j, p2_centroid) in enumerate(parent_2_centroids)
            push!(inter_dist, (sqrt((p2_centroid[1] - p1_centroid[1])^2 + (p2_centroid[2] - p1_centroid[2])^2), j))
        end
        sort!(inter_dist, rev=true)
        is_added = false
        while !is_added
            parent_2_route_id = inter_dist[end][2]
            if parent_2_route_id in r_2_added
                pop!(inter_dist)
            else
                push!(r_2, parent_2[parent_2_route_id])
                push!(r_2_added, parent_2_route_id)
                is_added = true
            end
        end
    end

    unassigned_patients_2 = Set{Int32}()

    for i in size(parent_2, 1)
        if i ∉ r_2_added
            union!(unassigned_patients_2, parent_2[i])
        end
    end

    ######################################################

    ### MINIMIZING AVERAGE INTER-CENTROID DISTANCE ###

    # avg_centroid_dist = []
    # for p2_centroid in parent_2_centroids
    #     sum_distance = 0
    #     for p1_centroid in parent_1_centroids
    #         sum_distance += sqrt((p2_centroid[1] - p1_centroid[1])^2 + (p2_centroid[2] - p1_centroid[2])^2)
    #     end
    #     push!(avg_centroid_dist, (sum_distance / k, p2_centroid[3])) # Index refers to route from parent_2
    # end

    # # I want to select k routes from parent_2 that are the closest to the routes in parent_1_centroids.
    # # I.e., least average distance between centroids

    # r_2 = [] # Will contain k routes from parent_2 that are in the neighborhood of r_1
    # for _ in 1:k
    #     min_inter_route_dist = argmin(avg_centroid_dist) # min distance between children
    #     push!(r_2, parent_2[avg_centroid_dist[min_inter_route_dist][2]])
    #     deleteat!(avg_centroid_dist, min_inter_route_dist)
    # end

    ######################################################


   

    r_1_flatten = collect(Iterators.flatten(r_1))
    r_2_flatten = collect(Iterators.flatten(r_2))
    r_2_flatten = setdiff(r_2_flatten, r_1_flatten)

    unassigned_patients = setdiff(unassigned_patients, Set{Int32}(r_2_flatten))
    unassigned_patients_2 = setdiff(unassigned_patients_2, Set{Int32}(r_1_flatten))

    unassigned = union(unassigned_patients, unassigned_patients_2)

    # println(unassigned)
    # println(r_1)
    # println(r_2)

    # Random removal first, then try based on largest travel time between consecutive patients, (since we are trying to minimize total travel time and not total time, wait time is not a great heuristic).

    for (i, route) in enumerate(r_1)
        ind_to_remove = Vector{Int}()
        for i in size(route, 1)
            if rand() < 0.1 # Tweak this...
                push!(ind_to_remove, i)
                if route[i] ∉ r_2_flatten
                    push!(unassigned, route[i])
                end
            end
        end
        if size(route, 1) == size(ind_to_remove, 1)
            deleteat!(r_1, i)
        elseif size(ind_to_remove, 1) == 0
            continue
        else
            delete_at_indices!(route, ind_to_remove)
        end
    end

    # Use r_2 flatten to draw candidates...
    
    current_route_id = 1
    current_route = r_1[current_route_id]
    while size(r_2_flatten, 1) > 0 && size(r_1, 1) <= depot.num_nurses
        candidates = []
        for (i, patient_id) in enumerate(r_2_flatten)
            insertions = []
            if size(current_route, 1) == 0
                time = travel_time_table(1, patient_id+1)
                push!(insertions,  (travel_time_table(1, patient_id+1), 1, patient_id, i))
            else
                for j in 1:size(current_route, 1) # Look at all insertions
                    insert!(current_route, j, patient_id)
                    objective_time, time_violation, demand, return_time = calculate_cost(current_route, patients, travel_time_table) # Maybe should allow infeasible here?
                    deleteat!(current_route, j)
                    if time_violation || demand > depot.nurse_cap || return_time > depot.return_time # Insertion is only feasible if all hard constraints are satisfied.
                        continue
                    else
                        push!(insertions,  (objective_time, j, patient_id, i))
                    end
                end
            end
            if size(insertions, 1) == 0 # No feasible insertions
                if size(r_1, 1) == depot.num_nurses
                    break
                else
                    if current_route_id == size(r_1, 1)
                        push!(r_1, [])
                    end
                    current_route_id += 1
                    current_route = r_1[current_route_id]
                end
            else
                # Choose stochastically from the best 3 insertions. Could add preference based on how good the fitness is...
                sort!(insertions, by=x->x[1])
                insertion = insertions[min(size(insertions, 1), rand(1:5))]
                insert!(current_route, insertion[2], insertion[3])
                deleteat!(r_2_flatten, insertion[4])
            end
        end
    end

    # println("Hi")
    # println(length(Set(collect(Iterators.flatten(r_1)))))
    # println(sort(collect(Iterators.flatten(r_1))))
    union!(unassigned, r_2_flatten)
    # println(sort(collect(unassigned)))
    # println()
    
    violations = nearest_neighbor_insert!(r_1, unassigned, patients, travel_time_table, depot.nurse_cap, depot.return_time, depot.num_nurses)
    return violations ? parent_1 : r_1

end

function nearest_neighbor_insert!(r_1, unassigned, patients, travel_time_table, nurse_cap, latest_return, num_nurses)
    """
    The guiding heuristic used to insert is the distance from an unassigned patient to its nearest patient, and using the respective route in r_1.
    """
    violation_patients = false
    for patient in unassigned
        # println(patient)
        distances = []
        for (i, route) in enumerate(r_1)
            for other_patient in route
                push!(distances, (travel_time_table(patient+1, other_patient+1), i))
            end
        end

        sort!(distances, by=x->x[2], rev=true)
        inserted = false
        while size(distances, 1) > 0
            route_to_use = r_1[pop!(distances)[2]]
            best_insertion = (typemax(Int32), -1)
            for i in 1:size(route_to_use, 1)
                insert!(route_to_use, i, patient)
                objective_time, time_violation, demand, return_time = calculate_cost(route_to_use, patients, travel_time_table) # Maybe should allow infeasible here?
                deleteat!(route_to_use, i)
                if time_violation || demand > nurse_cap || return_time > latest_return # Insertion is only feasible if all hard constraints are satisfied.
                    continue
                else
                    if objective_time < best_insertion[1]
                        best_insertion = (objective_time, i)
                    end
                end
            end
            if best_insertion[1] != typemax(Int32)
                insert!(route_to_use, best_insertion[2], patient)
                inserted = true
                break
            end
        end
        if !inserted && size(r_1, 1) < num_nurses
            push!(r_1, [patient])
        elseif !inserted
            violation_patients = true
        end
            
    end
    return violation_patients
end

function delete_at_indices!(arr::AbstractVector, indices_to_delete::AbstractVector{Int})
    # Sort the indices in reverse order to avoid index shifting issues
    sorted_indices = sort(indices_to_delete, rev=true)

    # Delete elements at the specified indices
    for index in sorted_indices
        deleteat!(arr, index)
    end

    return arr
end

function get_gene_from_2d_arr(pop_id, arr, patients, travel_time_table, time_pen, num_time_pen)
    # fitness_val, violates = fitness(pop_id, arr, patients, travel_time_table, time_pen, num_time_pen)
    fitness_val = distance(arr, travel_time_table)
    return Gene(
                collect(Iterators.flatten(arr)),
                fitness_val,
                arr,
                [],
                [],
                [],
                [],
                []
    )
end


end