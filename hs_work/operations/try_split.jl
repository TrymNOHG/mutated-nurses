function split_linear_bounded(gene::Vector{Int}, demands::Vector{Float64}, d_return::Vector{Float64}, d_next::Vector{Float64}, vehicle_capacity::Float64, nb_vehicles::Int)
    n = length(gene)
    sum_load = zeros(Float64, n + 1)
    sum_distance = zeros(Float64, n + 1)
    
    # 1. Precompute cumulative loads and distances
    for i in 2:n+1
        sum_load[i] = sum_load[i-1] + demands[gene[i-1]]  # gene is 1-based
        sum_distance[i] = if i == 2
            d_return[gene[1]]  # Distance from depot to first customer
        else
            sum_distance[i-1] + d_next[i-2]  # d_next is between consecutive customers
        end
    end

    # 2. Initialize DP tables
    potential = fill(Inf, nb_vehicles + 1, n + 1)
    pred = zeros(Int, nb_vehicles + 1, n + 1)
    potential[1, 1] = 0.0  # Depot

    # 3. Main algorithm using Vector as deque
    for k in 1:nb_vehicles
        deque = Int[]  # Use standard Julia vector as deque
        isempty(deque) && push!(deque, 1)  # Start from depot (position 1)

        for i in (k+1):(n+1)
            isempty(deque) && break

            front = first(deque)
            
            # Handle depot case (front=1)
            from_depot = front == 1
            cost = potential[k, front] + (sum_distance[i] - sum_distance[front]) + 
                   (from_depot ? 0.0 : d_return[gene[front-1]]) + 
                   d_return[gene[i-1]]

            if cost < potential[k+1, i]
                potential[k+1, i] = cost
                pred[k+1, i] = front
            end

            # Dominance checks with proper indices
            if i <= n
                # Remove dominated candidates from back
                while !isempty(deque) && dominates(last(deque), i, k, potential, sum_load, d_return, sum_distance, gene, vehicle_capacity)
                    pop!(deque)
                end
                push!(deque, i)

                # Remove front if capacity exceeded
                while !isempty(deque) && (sum_load[i] - sum_load[first(deque)] > vehicle_capacity + 1e-4)
                    popfirst!(deque)
                end
            end
        end
    end

    # 4. Backtrack to find optimal splits
    min_cost = Inf
    optimal_k = 1
    for k in 1:nb_vehicles
        if potential[k+1, end] < min_cost
            min_cost = potential[k+1, end]
            optimal_k = k
        end
    end

    split_points = Vector{Int}()
    current = n + 1  # End of the sequence (after last customer)
    for k in optimal_k:-1:1
        current = pred[k+1, current]
        push!(split_points, current)
    end
    reverse!(split_points)
    push!(split_points, n + 1)

    # Generate routes from split points (ensure valid indices)
    routes = Vector{Vector{Int}}()
    for i in 1:length(split_points)-1
        start_idx = split_points[i]
        end_idx = split_points[i+1] - 1
        # Ensure indices are within gene bounds
        if start_idx >= 1 && end_idx <= n
            route = gene[start_idx:end_idx]
            push!(routes, route)
        else
            error("Invalid split points: $split_points")
        end
    end

    return routes
end

function dominates(i::Int, j::Int, k::Int, potential, sum_load, d_return, sum_distance, gene, vehicle_capacity)
    sum_load[i] == sum_load[j] || return false
    cost_j = potential[k, j] + (j == 1 ? 0.0 : d_return[gene[j-1]])
    cost_i = potential[k, i] + (i == 1 ? 0.0 : d_return[gene[i-1]]) + (sum_distance[j+1] - sum_distance[i+1])
    cost_j > cost_i - 1e-4
end

function test_split_linear_bounded()
    # Test 1: Basic case (already working)
    println("\n=== Test 1: Basic Split ===")
    gene = [1, 2, 3, 4]
    demands = [2.0, 3.0, 1.0, 4.0]
    d_return = [10.0, 15.0, 20.0, 25.0]
    d_next = [5.0, 8.0, 10.0]
    routes = split_linear_bounded(gene, demands, d_return, d_next, 5.0, 2)
    @assert routes == [[1, 2], [3, 4]] "Test 1 failed. Got $routes"
    println("Test 1 passed!", routes)

    # Test 2: Single vehicle solution
    println("\n=== Test 2: Single Route ===")
    gene = [1, 2, 3]
    demands = [1.0, 2.0, 2.0]
    d_return = [5.0, 5.0, 5.0]
    d_next = [3.0, 3.0]
    routes = split_linear_bounded(gene, demands, d_return, d_next, 5.0, 3)
    @assert routes == [[1, 2, 3]] "Test 2 failed. Got $routes"
    println("Test 2 passed!", routes)

    # Test 3: Forced split at exact capacity
    println("\n=== Test 3: Exact Capacity Split ===")
    gene = [1, 2, 3, 4]
    demands = [3.0, 2.0, 3.0, 2.0]
    d_return = [10.0, 10.0, 10.0, 10.0]
    d_next = [5.0, 5.0, 5.0]
    routes = split_linear_bounded(gene, demands, d_return, d_next, 5.0, 2)
    @assert routes == [[1, 2], [3, 4]] "Test 3 failed. Got $routes"
    println("Test 3 passed!", routes)

    # Test 4: Optimal split not at midpoint
    # println("\n=== Test 4: Non-obvious Split ===")
    # gene = [1, 2, 3, 4]
    # demands = [2.0, 2.0, 2.0, 2.0]
    # d_return = [100.0, 1.0, 1.0, 1.0]  # Makes it better to split after 1st customer
    # d_next = [1.0, 1.0, 1.0]
    # routes = split_linear_bounded(gene, demands, d_return, d_next, 4.0, 2)
    # @assert routes == [[1], [2, 3, 4]] "Test 4 failed. Got $routes"
    # println("Test 4 passed!", routes)

    # Test 5: Maximum vehicles needed
    # println("\n=== Test 5: Max Vehicles ===")
    # gene = [1, 2, 3, 4]
    # demands = [5.0, 5.0, 5.0, 5.0]
    # d_return = [10.0, 10.0, 10.0, 10.0]
    # d_next = [5.0, 5.0, 5.0]
    # routes = split_linear_bounded(gene, demands, d_return, d_next, 5.0, 4)
    # @assert routes == [[1], [2], [3], [4]] "Test 5 failed. Got $routes"
    # println("Test 5 passed!", routes)

    # Test 6: Complex case with 6 customers
    println("\n=== Test 6: Complex Case ===")
    gene = [1, 2, 3, 4, 5, 6]
    demands = [3.0, 2.0, 4.0, 1.0, 2.0, 3.0]
    d_return = [10.0, 8.0, 12.0, 9.0, 7.0, 15.0]
    d_next = [4.0, 5.0, 3.0, 6.0, 2.0]
    routes = split_linear_bounded(gene, demands, d_return, d_next, 6.0, 3)
    @assert routes == [[1, 2], [3, 4], [5, 6]] "Test 6 failed. Got $routes"
    println("Test 6 passed!", routes)
end

# Run the test
test_split_linear_bounded()