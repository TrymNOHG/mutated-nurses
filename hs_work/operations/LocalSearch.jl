module LocalSearch
using ..Models, ..Split
using Random

export local_search!


function compute_true_duration(route_segment::Vector{Int}, depot::Depot, patients::Vector{Patient}, time_matrix)
    current_time = 0.0
    total_time_warp = 0.0
    prev = 1  # Depot index

    for customer in route_segment
        # Travel time from previous location to current customer
        travel_time = time_matrix(prev, customer + 1)
        arrival_time = current_time + travel_time

        # Customer time window constraints
        start_time = patients[customer].start_time
        end_time = patients[customer].end_time - patients[customer].care_time

        # Time warp (late arrival)
        if arrival_time > end_time
            time_warp = arrival_time - end_time
            total_time_warp += time_warp
            arrival_time = end_time  # Clamp to end_time
        end

        # Waiting time (early arrival)
        if arrival_time < start_time
            waiting_time = start_time - arrival_time
            arrival_time = start_time
        else
            waiting_time = 0.0
        end

        # Departure time after service
        current_time = arrival_time + patients[customer].care_time
        prev = customer + 1
    end

    # Return to depot
    return_to_depot_time = time_matrix(prev, 1)
    total_duration = current_time + return_to_depot_time + total_time_warp

    return total_duration, total_time_warp
end


function route_cost(route::Vector{Int}, gene::Gene, patients::Vector{Patient}, max_duration, penaltyDuration, penaltyCap::Float32, penaltyTW, depot::Depot, time_matrix)
    route_segment = route
    # Compute true duration and time warps for this segment
    true_duration, time_warp = compute_true_duration(route_segment, depot, patients, time_matrix)

    # Calculate load (unchanged)
    load = 0
    for customer in route
        load += patients[customer].demand
    end
    # Calculate violations
    capacity_violation = max(0.0f0, load - depot.nurse_cap)
    duration_violation = max(0.0f0, true_duration - max_duration)

    # Total cost: travel time (or true duration) + penalties
    # cost = true_duration + penaltyCap * capacity_violation + penaltyDuration * duration_violation
    cost = true_duration + penaltyCap * capacity_violation + penaltyDuration * duration_violation + penaltyTW * time_warp

    return cost
end 

function is_improving_2opt(gene::Gene, route::Vector{Int}, i::Int, j::Int, patients::Vector{Patient}, depot::Depot, penaltyDuration, penaltyCap, penaltyTW, time_matrix)
    # Current configuration cost
    original_cost = route_cost(route, gene, patients, depot.return_time, penaltyDuration, penaltyCap, penaltyTW, depot, time_matrix)
    
    # Create reversed segment
    # new_route = reverse(route[i:j])
    new_route = [route[1:i-1]; reverse(route[i:j]); route[j+1:end]]

    # New configuration cost
    new_cost = route_cost(new_route,gene,patients, depot.return_time, penaltyDuration, penaltyCap, penaltyTW, depot, time_matrix)
    
    return new_cost < original_cost
end

function local_search!(gene::Gene, depot::Depot, patients::Vector{Patient}, penaltyDuration, penaltyCap::Float32, penaltyTW,tau::Int, gamma_wt, gamma_tw, time_matrix)
    # 1. Compute neighbors using gamma_hat metric
    neighbors = compute_neighbors(gene, patients, tau, gamma_wt, gamma_tw,time_matrix)
    
    # 2. Process routes in two phases
    # Phase 1 : Local search for new routes
    improved = true
    while improved
        improved = false
        # improved |= n1_moves!(gene, neighbors, depot, patients, penaltyDuration, penaltyCap, penaltyTW, time_matrix, gene.new_routes) 
        # improved |= n2_moves!(gene, neighbors, depot, patients, penaltyDuration, penaltyCap, penaltyTW, time_matrix, gene.new_routes) 
        for route_idx in gene.new_routes
            route = gene.gene_r[route_idx]
            improved |= apply_2opt!(gene, route, neighbors, patients,depot, penaltyDuration, penaltyCap, penaltyTW, time_matrix)
        end
        # improved |= apply_inter_route_moves!(gene, neighbors, depot, patients, penaltyDuration, penaltyCap, penaltyTW, time_matrix)
    end

    # Phase 2 local search in old routes
    improved = true
    while improved
        improved = false
        route_indicies = Vector{Int}()
        for indc in 1:length(gene.gene_r)
            if indc in gene.new_routes
                continue
            else
                push!(route_indicies, indc)
            end
        end
        improved |= n1_moves!(gene, neighbors, depot, patients, penaltyDuration, penaltyCap, penaltyTW, time_matrix, route_indicies) 
        for route_idx = 1:length(gene.gene_r)
            if route_idx in gene.new_routes
                continue
            else
                route = gene.gene_r[route_idx]
                improved |= apply_2opt!(gene, route, neighbors, patients,depot, penaltyDuration, penaltyCap, penaltyTW, time_matrix)
            end
        end
        improved |= apply_inter_route_moves!(gene, neighbors, depot, patients, penaltyDuration, penaltyCap, penaltyTW, time_matrix)
    end


    cost_r = 0.0
    for route in gene.gene_r
        cost_r += route_cost(route, gene, patients, depot.return_time, penaltyDuration, penaltyCap, penaltyTW, depot, time_matrix)
    end
    gene.fitness = -cost_r
end

function compute_neighbors(gene::Gene, patients::Vector{Patient} , tau::Int,gamma_wt, gamma_tw, time_matrix)
    neighbors = Dict{Int, Vector{Int}}()
    sequence = gene.sequence
    
    for u in sequence
        gamma_values = []
        for v in sequence
            u == v && continue  # Skip self-pairs
            # Calculate symmetric gamma_hat
            gamma_uv = compute_correlation(u, v, patients,gamma_wt, gamma_tw, time_matrix)
            gamma_vu = compute_correlation(v, u, patients,gamma_wt, gamma_tw, time_matrix)
            gamma_hat = min(gamma_uv, gamma_vu)
            
            push!(gamma_values, (v, gamma_hat))
        end
        
        # Sort by correlation and keep top tau neighbors
        sort!(gamma_values, by=x->x[2])
        neighbors[u] = [v for (v, _) in gamma_values[1:min(tau, length(gamma_values))]]
    end
    
    neighbors
end

function compute_correlation(u::Int, v::Int, patients::Vector{Patient}, gamma_wt, gamma_tw, time_matrix)
    u_data = patients[u]
    v_data = patients[v]
    
    # Get travel time with depot offset adjustment
    δ_ij = time_matrix(u+1, v+1)
    τ_i = u_data.care_time
    
    # Calculate waiting time component
    waiting_time = max(v_data.start_time - (τ_i + δ_ij + u_data.end_time), 0)
    
    # Calculate time warp component
    time_warp = max((u_data.start_time + τ_i + δ_ij) - v_data.end_time, 0)
    
    # Combine components using weights
    δ_ij + gamma_wt * waiting_time + gamma_tw * time_warp
end

function apply_2opt!(gene::Gene, route::Vector{Int}, neighbors, patients,depot::Depot, penaltyDuration, penaltyCap, penaltyTW, time_matrix)
    improved = false
    n = length(route)
    
    for i in 1:n-1
        for j in i+1:n
            # Only consider neighbors in tau
            route[i] ∈ neighbors[route[j]] || continue
            
            # Check if reversing segment improves cost
            if is_improving_2opt(gene, route, i, j, patients,depot, penaltyDuration, penaltyCap, penaltyTW, time_matrix)
                reverse!(route, i,j)
                improved = true

            end
        end
    end
    improved
end

function n1_moves!(gene::Gene, neighbors, depot::Depot, patients::Vector{Patient}, penaltyDuration, penaltyCap, penaltyTW, time_matrix, route_indicies::Vector{Int}) # N1 is swap and relocate, Swap two disjoint visit sequences,  containing between 0 and 2 visits. Combine this with the reversal of one or both sequences.
    improved = false
    all_routes = gene.gene_r
    random_r1_array = shuffle(route_indicies)
    random_r2_array = shuffle(route_indicies)
    r_c_2 = factorial(big(length(all_routes))) / (2 * factorial(big(length(all_routes) - 2)))
    routes_to_explore = 0.05*r_c_2
    routes_explored = 0
    for r1 in random_r1_array
        for r2 in random_r2_array
                (new_r1, new_r2), swapped = apply_swap_and_relocate(all_routes[r1], all_routes[r2], neighbors, patients, gene, depot, penaltyDuration, penaltyCap, penaltyTW, time_matrix)
                if swapped
                    gene.gene_r[r1] = new_r1
                    gene.gene_r[r2] = new_r2
                    improved = true
                end
                routes_explored +=1
                if routes_explored > routes_to_explore
                    break
                end
        end
    end
    improved
end

# function apply_swap_and_relocate(route1::Vector{Int}, route2::Vector{Int}, neighbors, patients::Vector{Patient}, gene::Gene, depot::Depot, penaltyDuration, penaltyCap, penaltyTW, time_matrix)
#     best_delta = Inf
#     best_move = nothing
    
#     # Consider all possible subsequence swaps
#     for i in 1:length(route1), j in 1:length(route2)
#         route1[i] ∈ neighbors[route2[j]] || continue
        
#         # Calculate cost difference
#         original_cost = route_cost(route1, gene, patients, depot.return_time, penaltyDuration, penaltyCap, penaltyTW, depot, time_matrix) +
#                         route_cost(route2, gene, patients, depot.return_time, penaltyDuration, penaltyCap, penaltyTW, depot, time_matrix)
        
#         # Create new routes
#         new_route1 = [route1[1:i-1]; route2[j:end]]
#         new_route2 = [route2[1:j-1]; route1[i:end]]
        
#         # Check feasibility
#         new_cost = route_cost(new_route1, gene, patients, depot.return_time, penaltyDuration, penaltyCap, penaltyTW, depot, time_matrix) +
#                    route_cost(new_route2, gene, patients, depot.return_time, penaltyDuration, penaltyCap, penaltyTW, depot, time_matrix)
        
#         if new_cost < original_cost
#             delta = new_cost - original_cost
#             if delta < best_delta
#                 best_delta = delta
#                 best_move = (new_route1, new_route2)
#             end
#         end
#     end
    
#     # Return new routes if improvement found
#     if best_move !== nothing
#         return (best_move[1], best_move[2]), true
#     else
#         return (route1, route2), false
#     end
# end

function apply_inter_route_moves!(gene, neighbors, depot, patients, penaltyDuration, penaltyCap, penaltyTW, time_matrix)
    improved = false
    routes = gene.gene_r
    
    for r1 in 1:length(routes), r2 in r1+1:length(routes)
        # Swap move
        (new_r1, new_r2), swapped = apply_swap_and_relocate(routes[r1], routes[r2], neighbors, patients, gene, depot, penaltyDuration, penaltyCap, penaltyTW, time_matrix)
        if swapped
            gene.gene_r[r1] = new_r1
            gene.gene_r[r2] = new_r2
            improved = true
            # println("Did some swapping bitch")
        end
        
        # Relocate move
        (new_r1_reloc, new_r2_reloc), relocated = apply_relocate_move(routes[r1], routes[r2], neighbors, patients, gene, depot, penaltyDuration, penaltyCap, penaltyTW, time_matrix)
        if relocated
            gene.gene_r[r1] = new_r1_reloc
            gene.gene_r[r2] = new_r2_reloc
            improved = true
            # println("Did some relocating bitch")
        end
    end
    
    improved
end

function apply_swap_and_relocate(route1::Vector{Int}, route2::Vector{Int}, neighbors, patients::Vector{Patient}, gene::Gene, depot::Depot, penaltyDuration, penaltyCap, penaltyTW, time_matrix)
    best_delta = Inf
    best_move = nothing
    
    # Consider all possible subsequence swaps
    for i in 1:length(route1), j in 1:length(route2)
        route1[i] ∈ neighbors[route2[j]] || continue
        
        # Calculate cost difference
        original_cost = route_cost(route1, gene, patients, depot.return_time, penaltyDuration, penaltyCap, penaltyTW, depot, time_matrix) +
                        route_cost(route2, gene, patients, depot.return_time, penaltyDuration, penaltyCap, penaltyTW, depot, time_matrix)
        
        # Create new routes
        new_route1 = [route1[1:i-1]; route2[j:end]]
        new_route2 = [route2[1:j-1]; route1[i:end]]
        
        # Check feasibility
        new_cost = route_cost(new_route1, gene, patients, depot.return_time, penaltyDuration, penaltyCap, penaltyTW, depot, time_matrix) +
                   route_cost(new_route2, gene, patients, depot.return_time, penaltyDuration, penaltyCap, penaltyTW, depot, time_matrix)
        
        if new_cost < original_cost
            delta = new_cost - original_cost
            if delta < best_delta
                best_delta = delta
                best_move = (new_route1, new_route2)
            end
        end
    end
    
    # Return new routes if improvement found
    if best_move !== nothing
        return (best_move[1], best_move[2]), true
    else
        return (route1, route2), false
    end
end

function apply_relocate_move(source::Vector{Int}, target::Vector{Int}, neighbors, patients::Vector{Patient}, gene::Gene, depot::Depot, penaltyDuration, penaltyCap, penaltyTW, time_matrix)
    best_delta = Inf
    best_move = nothing
    
    for i in 1:length(source), j in 1:length(target)
        source[i] ∈ neighbors[target[j]] || continue
        
        # Create new routes
        new_source = deleteat!(copy(source), i)
        new_target = insert!(copy(target), j, source[i])
        
        # Check cost
        new_cost = route_cost(new_source, gene, patients, depot.return_time, penaltyDuration, penaltyCap, penaltyTW, depot, time_matrix) +
                   route_cost(new_target, gene, patients, depot.return_time, penaltyDuration, penaltyCap, penaltyTW, depot, time_matrix)
        original_cost = route_cost(source, gene, patients, depot.return_time, penaltyDuration, penaltyCap, penaltyTW, depot, time_matrix) +
                        route_cost(target, gene, patients, depot.return_time, penaltyDuration, penaltyCap, penaltyTW, depot, time_matrix)
        
        if new_cost < original_cost
            delta = new_cost - original_cost
            if delta < best_delta
                best_delta = delta
                best_move = (new_source, new_target)
            end
        end
    end
    
    # Return new routes if improvement found
    if best_move !== nothing
        return (best_move[1], best_move[2]), true
    else
        return (source, target), false
    end
end


end