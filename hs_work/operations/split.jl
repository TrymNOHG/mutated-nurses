module Split

using ..Models: Patient, Depot, Gene  # Access types from parent scope
include("../data_structs/Dequeue.jl")
import .Dequeue

export split2routes, splitbellman

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
        end_time = patients[customer].end_time

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

function cost_of_route(p::Int, i::Int, gene::Gene, patients::Vector{Patient}, max_duration, penaltyDuration, penaltyCap::Float32, penaltyTW, depot::Depot, time_matrix)
    # Extract the route segment (p+1 to i)
    if p == 0
        route_segment = gene.sequence[1:i]
    else
        route_segment = gene.sequence[p+1:i]
    end

    # Compute true duration and time warps for this segment
    true_duration, time_warp = compute_true_duration(route_segment, depot, patients, time_matrix)

    # Calculate load (unchanged)
    load = p == 0 ? gene.sum_load[i] : gene.sum_load[i] - gene.sum_load[p]

    # Calculate violations
    capacity_violation = max(0.0f0, load - depot.nurse_cap)
    duration_violation = max(0.0f0, true_duration - max_duration)

    # Total cost: travel time (or true duration) + penalties
    cost = true_duration + penaltyCap * capacity_violation + penaltyDuration * duration_violation
    # cost = true_duration + penaltyCap * capacity_violation + penaltyDuration * duration_violation + penaltyTW * time_warp

    return cost
end 


function split2routes(gene::Gene, depot::Depot, nbPatients::Int, penaltyCap::Float32)
    potential = fill(1.e30, depot.num_nurses, nbPatients)
    pred = fill(0, depot.num_nurses, nbPatients)
    queue = Dequeue.TrivialDeque(nbPatients + 1, 1)
    MY_EPSILON::Float32 = 0.00001

    # Initialize for k=1: cost of one nurse serving first i patients
    for i in 1:nbPatients
        load = gene.sum_load[i]
        violation = max(load - depot.nurse_cap, 0.0)
        potential[1, i] = gene.d0_x[1] + gene.sum_dist[i] + gene.dx_0[i] + penaltyCap * violation
        pred[1, i] = 0  # No predecessor; starts from depot
    end

    # Adjusted propagate: use k-1 for k > 1
    @inline function propagate(p::Int, j::Int, k::Int)
        if k == 1 && p == 0
            # Shouldn’t reach here with new initialization, but kept for clarity
            return gene.d0_x[1] + gene.sum_dist[j] + gene.dx_0[j] + penaltyCap * max(gene.sum_load[j] - depot.nurse_cap, 0.0)
        else
            return potential[k-1, p] + gene.d0_x[p+1] + (gene.sum_dist[j] - gene.sum_dist[p+1]) + gene.dx_0[j] + penaltyCap * max(gene.sum_load[j] - gene.sum_load[p] - depot.nurse_cap, 0.0)
        end
    end

    @inline function dominates(p::Int, j::Int, k::Int)
        # Use k-1 and correct penalty to violation
        load_violation = max(gene.sum_load[j] - gene.sum_load[p] - depot.nurse_cap, 0.0)
        return (potential[k-1, j] + gene.d0_x[j+1]) > (potential[k-1, p] + gene.d0_x[p+1] + (gene.sum_dist[j+1] - gene.sum_dist[p+1]) + penaltyCap * load_violation)
    end

    @inline function dominatesRight(p::Int, j::Int, k::Int)
        load_violation = max(gene.sum_load[j] - gene.sum_load[p] - depot.nurse_cap, 0.0)
        return potential[k-1, j] + gene.d0_x[j+1] < potential[k-1, p] + gene.d0_x[p+1] + (gene.sum_dist[j+1] - gene.sum_dist[p+1]) + penaltyCap * load_violation + MY_EPSILON
    end

    # Main loop starting from k=2
    for k in 2:depot.num_nurses
        Dequeue.reset!(queue, k-1)  # Start with p = k-1
        Dequeue.push_back!(queue, k-1)  # Ensure queue isn’t empty
        for i in k:nbPatients
            if Dequeue.size(queue) < 1
                break
            end
            p = Dequeue.get_front(queue)
            potential[k, i] = propagate(p, i, k)
            pred[k, i] = p

            if i < nbPatients
                if !dominates(Dequeue.get_back(queue), i, k)
                    while Dequeue.size(queue) > 0 && dominatesRight(Dequeue.get_back(queue), i, k)
                        Dequeue.pop_back!(queue)
                    end
                    Dequeue.push_back!(queue, i)
                end
                while Dequeue.size(queue) > 1 && propagate(Dequeue.get_front(queue), i+1, k) > propagate(Dequeue.get_next_front(queue), i+1, k) - MY_EPSILON
                    Dequeue.pop_front!(queue)
                end
            end
        end
    end

    if potential[depot.num_nurses, nbPatients] > 1.e29
        throw("ERROR : no Split solution has been propagated until the last node")
    end

    minCost::Float32 = potential[depot.num_nurses, nbPatients]
    nbRoutes::Int = depot.num_nurses
    for k in 1:depot.num_nurses
        if potential[k, nbPatients] < minCost
            minCost = potential[k, nbPatients]
            nbRoutes = k
        end
    end

    # Reconstruct routes
    e = nbPatients
    for k in nbRoutes:-1:1
        b = pred[k, e]
        for ii in (b+1):e  # b+1 because b is last patient of previous route
            push!(gene.gene_r[k], gene.sequence[ii])
        end
        e = b
    end
    filter!(x -> !isempty(x), gene.gene_r)       # Removing the empty routes
    gene.fitness = -minCost
    return gene.fitness
end


function splitbellman(gene::Gene, depot::Depot, patients::Vector{Patient}, nbPatients::Int, penaltyCap::Float32, max_duration, penaltyDuration, penaltyTW, time_matrix)
    maxVehicles = depot.num_nurses

    # Initialize DP tables
    potential = fill(1.0f30, maxVehicles, nbPatients)  # Minimum cost for k vehicles up to i patients
    pred = fill(0, maxVehicles, nbPatients)            # Predecessor index for backtracking

    # Fill the DP table
    for k in 1:maxVehicles
        for i in k:nbPatients
            if k == 1
                # One vehicle serves all patients from 1 to i
                potential[k, i] = cost_of_route(0, i, gene, patients, max_duration, penaltyDuration, penaltyCap, penaltyTW, depot, time_matrix)
                pred[k, i] = 0
            else
                # Find the minimum cost by trying all possible split points p
                min_cost = 1.0f30
                best_p = -1
                for p in (k-1):(i-1)
                    cost = potential[k-1, p] + cost_of_route(p, i, gene, patients, max_duration, penaltyDuration, penaltyCap, penaltyTW,depot, time_matrix)
                    if cost < min_cost
                        min_cost = cost
                        best_p = p
                    end
                end
                potential[k, i] = min_cost
                pred[k, i] = best_p
            end
        end
    end

    # Find the optimal number of vehicles
    minCost = 1.0f30
    nbRoutes = 0
    for k in 1:maxVehicles
        if potential[k, nbPatients] < minCost
            minCost = potential[k, nbPatients]
            nbRoutes = k
        end
    end

    # Reconstruct the routes
    temp_routes = Vector{Vector{Int}}()
    e = nbPatients
    for k in nbRoutes:-1:1
        b = pred[k, e]
        route = gene.sequence[b+1:e]
        push!(temp_routes, route)
        e = b
    end
    gene.gene_r = reverse(temp_routes)

    # Set fitness as the negative of the total cost (for maximization in genetic algorithms)
    gene.fitness = -minCost

    return gene.fitness
end


end