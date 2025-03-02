function split_linear_bounded(gene, demands, distances, vehicle_capacity, nb_vehicles)
    # Number of customers
    n = length(gene)
    
    # Precompute cumulative sums
    # sumLoad[1] = 0, sumLoad[2] = demands[gene[1]], ..., sumLoad[n+1] = total demand
    sumLoad = zeros(Float64, n + 1)
    for i in 1:n
        sumLoad[i + 1] = sumLoad[i] + demands[gene[i]]
    end
    
    # sumDistance[1] = 0, sumDistance[2] = d[gene[1],gene[2]], ..., sumDistance[n] = sum of distances up to gene[n-1]
    sumDistance = zeros(Float64, n)
    sumDistance[1] = 0.0
    for i in 1:n-1
        sumDistance[i + 1] = sumDistance[i] + distances[gene[i], gene[i + 1]]
    end
    
    # Initialize DP arrays
    # potential[k+1, i+1] represents k routes up to i customers (k: 0 to nb_vehicles, i: 0 to n)
    potential = fill(Inf, nb_vehicles + 1, n + 1)
    pred = fill(-1, nb_vehicles + 1, n + 1)
    potential[1, 1] = 0.0  # 0 routes, 0 customers
    
    # Dominance check functions
    function dominates(i, j, k)
        if sumLoad[i + 1] != sumLoad[j + 1]
            return false
        end
        return potential[k + 1, j + 1] + distances[0, gene[j + 1]] > 
               potential[k + 1, i + 1] + distances[0, gene[i + 1]] + 
               (sumDistance[j + 1] - sumDistance[i + 1]) - 1e-6
    end
    
    function dominatesRight(i, j, k)
        return potential[k + 1, j + 1] + distances[0, gene[j + 1]] < 
               potential[k + 1, i + 1] + distances[0, gene[i + 1]] + 
               (sumDistance[j + 1] - sumDistance[i + 1]) + 1e-6
    end
    
    # Main algorithm loop
    for k in 0:nb_vehicles - 1
        queue = [k]  # Start with predecessor k
        for i in k + 1:n
            pred_val = queue[1]
            a = pred_val + 1  # Start of route
            b = i             # End of route
            cost_route = distances[1, gene[a]] + 
                        (sumDistance[b] - sumDistance[a]) + 
                        distances[gene[b], 1]
            potential[k + 2, i + 1] = potential[k + 1, pred_val + 1] + cost_route
            pred[k + 2, i + 1] = pred_val
            
            if i < n  # Update queue for next position
                # Remove dominated predecessors from back
                while !isempty(queue) && dominatesRight(queue[end], i, k)
                    pop!(queue)
                end
                # Add i if not dominated
                if isempty(queue) || !dominates(queue[end], i, k)
                    push!(queue, i)
                end
                # Remove front if capacity exceeded for next position
                while !isempty(queue) && sumLoad[i + 2] - sumLoad[queue[1] + 1] > vehicle_capacity + 1e-6
                    popfirst!(queue)
                end
            end
        end
    end
    
    # Find optimal number of routes
    min_cost = Inf
    best_k = 0
    for k in 1:nb_vehicles
        if potential[k, n + 1] < min_cost
            min_cost = potential[k, n + 1]
            best_k = k
        end
    end
    if best_k == 0
        error("No feasible solution found")
    end
    
    # Backtrack to get starting indices
    solution = Int[]
    cour = n
    k = best_k
    while k >= 1
        next_cour = pred[k, cour + 1]
        push!(solution, next_cour + 1)
        cour = next_cour
        k -= 1
    end
    reverse!(solution)
    
    # Build routes
    routes = Vector{Vector{Int}}()
    start = 1
    for i in 1:best_k
        end_idx = (i < best_k) ? solution[i + 1] - 1 : n
        push!(routes, gene[start:end_idx])
        start = end_idx + 1
    end
    
    return routes
end

gene = [2, 3, 1, 4]
demands = [0, 10, 20, 15, 25]  # demands[0] is depot, demands[1] is customer 1, etc.
distances = [  # Symmetric distance matrix
    0 10 15 20 25;
   10  0 35 25 15;
   15 35  0 30 20;
   20 25 30  0 10;
   25 15 20 10  0
]
vehicle_capacity = 40
nb_vehicles = 2
routes = split_linear_bounded(gene, demands, distances, vehicle_capacity, nb_vehicles)
println(routes)  # e.g., [[2, 3], [1, 4]]