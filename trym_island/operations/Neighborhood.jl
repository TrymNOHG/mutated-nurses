module Neighborhood

export get_centroid, get_all_centroids, get_route_neighborhood, first_apply_neighbor_insert!, best_apply_neighbor_insert!

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
    for route in routes
        push!(centroids, (get_centroid(route, patients)))
    end
    return centroids
end


# Centroids should be cached...

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
        elseif size(neighbors) < 2
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


function first_apply_neighbor_insert!(current_fitness, neighbors, routes, patient_id)
    for centroid_info in neighbors
        route_id = centroid_info[2]
        neighbor_route = routes[route_id]
        for i in size(neighbor_route, 1)
            insert!(neighbor_route, patient_id, i)
            new_fitness = nurse_fitness(routes, ...) # I need to add the actual calculation of new fitness
            if new_fitness < current_fitness
                return true # Mutation was successful.
            end
            deleteat!(neighbor_route, i)
        end # Insert patient into every spot in the first closest neighbor. If an improvement occurs, immediately accept it.
    end
    return false
end

function best_apply_neighbor_insert!(current_fitness, neighbors, routes, patient_id)
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
            new_fitness = nurse_fitness(routes, ...) # I need to add the actual calculation of new fitness
            if new_fitness < best_insertion[1]
                best_insertion = (new_fitness, route_id, i)
            end
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