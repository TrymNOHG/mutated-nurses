module Neighborhood

export get_centroid, get_all_centroids, get_route_neighborhood, first_apply_neighbor_insert!, best_apply_neighbor_insert!

using ..Operations

function get_centroid(route, patients)
    sum_x = 0
    sum_y = 0
    for patient in route
        sum_x += patients[patient].x_coord
        sum_y += patients[patient].y_coord
    end
    avg_x = sum_x / (size(route, 1) + 1) # + 1 due to depot
    avg_y = sum_y / (size(route, 1) + 1) # + 1 due to depot
    return avg_x, avg_y
end

function get_all_centroids(routes, patients)
    centroids = []
    depot_neighbor = false
    for route in routes
        if size(route, 1) == 0
            if !depot_neighbor
                push!(centroids, (0, 0))
                depot_neighbor = true
            end
            continue
        end
        push!(centroids, (get_centroid(route, patients)))
    end
    return centroids
end

# The route neighborhood could also be found relative to the distances given by the time matrix.
# The average distance between all of the patients in a route and the patient in question could be used as a metric!
# Ok, so two ideas: 1. closes patients' routes. 2. average distance to each patient + depot (only once)
# Centroids should be cached...
function get_route_neighborhood(n_routes, centroids, patient_route_id, patient)
    """
    This function produces the n closest route neighbors given a certain patient. This is calculated using the distance between the centroids of routes 
    (average over x and y for all nodes). The output follows the format: [[shortest_dist, route_id],[second_shortest, route_id_2]].
    """
    neighbors = [] # Shortest distance will be kept at end of list
    for (centroid_id, centroid) in enumerate(centroids) 
        if centroid_id == patient_route_id
            continue
        end
        distance = sqrt((centroid[1] - patient.x_coord)^2 + (centroid[2] - patient.y_coord)^2)
        push!(neighbors, (distance, centroid_id))
    end
    sort!(neighbors, by=x->x[1])
    neighbors = neighbors[1:n_routes]
    return neighbors
end

function get_route_neighborhood(centroids, patient_route_id, patient)
    """
    This function produces the 2 closest route neighbors given a certain patient. This is calculated using the distance between the centroids of routes 
    (average over x and y for all nodes). The output follows the format: [[shortest_dist, route_id],[second_shortest, route_id_2]].
    """
    neighbors = [] # Shortest distance will be kept at end of list
    for (centroid_id, centroid) in enumerate(centroids) 
        if centroid_id == patient_route_id
            continue
        end
        distance = sqrt((centroid[1] - patient.x_coord)^2 + (centroid[2] - patient.y_coord)^2)
        if size(neighbors, 1) < 1
            push!(neighbors, [distance, centroid_id])
        elseif size(neighbors, 1) < 2
            if distance < neighbors[1][1]
                push!(neighbors, neighbors[1])
                neighbors[1] = [distance, centroid_id]
            else
                push!(neighbors, [distance, centroid_id])
            end
        elseif distance < neighbors[2][1]
            if distance > neighbors[1][1]
                neighbors[2] = [distance, centroid_id]
            else
                neighbors[2] = neighbors[1]
                neighbors[1] = [distance, centroid_id]
            end
        end
    end
    return neighbors
end


# All I need for this method is change in time of the route the patient was removed from
function first_apply_neighbor_insert!(removal_reward, neighbors, routes, patient_id, patients, travel_time_table)
    """
        The removal reward parameter essentially provides the decrease in time the nurse initially assigned to the patient spend now that 
        the patient is no longer part of the route. 
        If the reduced time for removal + cost of insertion < 0 (and insertion is feasible), then do this.
    """
    for centroid_info in neighbors
        route_id = Int(centroid_info[2])
        neighbor_route = routes[route_id]
        current_cost_of_route, _ = calculate_cost(neighbor_route, patients, travel_time_table)
        # println(neighbor_route)
        for i in 1:size(neighbor_route, 1)
            # println(neighbor_route)
            insert!(neighbor_route, i, patient_id)
            new_cost_of_route, feasible = calculate_cost(neighbor_route, patients, travel_time_table)
            insert_cost = new_cost_of_route - current_cost_of_route
            if removal_reward - insert_cost < 0
                return routes, true # Mutation was a success.
            end
            deleteat!(neighbor_route, i)
        end # Insert patient into every spot in the first closest neighbor. If an improvement occurs, immediately accept it.
    end
    return routes, false
end

function best_apply_neighbor_insert!(current_fitness, neighbors, routes, patient_id, patients, travel_time_table)
    """
    This function attempts to insert a patient in every position in its two neighbors. Here, a "best-apply" approach is taken, where all positions will be evaluated against each
    other and the best will be chosen. The output value of function indicates whether a better position was found.
    """
    best_insertion = (current_fitness, 0, 0) # Fitness, route_id, position
    for centroid_info in neighbors
        route_id = centroid_info[2]
        neighbor_route = routes[route_id]
        for i in size(neighbor_route, 1)
            insert!(neighbor_route, patient_id, i)
            # new_fitness = nurse_fitness(routes, ...) # I need to add the actual calculation of new fitness
            # if new_fitness < best_insertion[1]
            #     best_insertion = (new_fitness, route_id, i)
            # end
            deleteat!(neighbor_route, i) 
        end
    end
    if best_insertion[1] < current_fitness
        insert!(routes[best_insertion[2]], patient_id, best_insertion[3])
        return true
    end
    return false
end


# for (i, route) in enumerate(routes)
#     value = travel_time_table[route[end]][next_patient] + travel_time_table[next_patient][1] - travel_time_table[route[end]][1] + 1 * size(route, 1)
#     if value < best_val
#         choice = i
#         best_val = value
#     end
# end


end