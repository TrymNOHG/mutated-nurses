module FitnFeasible

using ..Split
using ..Models

export generic_fitness, check_feasible, constrain_cal, calc_biased_fitness

function broken_pair_distance(indiv1::Int, indiv2::Int, genetic_pool::Population)
    # Create successor/predecessor maps for both individuals
    function get_successor_predecessor(sequence)
        succ = Dict{Int,Int}()
        pred = Dict{Int,Int}()
        for i in 1:length(sequence)-1
            succ[sequence[i]] = sequence[i+1]
            pred[sequence[i+1]] = sequence[i]
        end
        return succ, pred
    end

    succ1, pred1 = get_successor_predecessor(genetic_pool.genes[indiv1].sequence)
    succ2, pred2 = get_successor_predecessor(genetic_pool.genes[indiv1].sequence)

    differences = 0
    nbClients = genetic_pool.gene_length
    # Check all clients (assuming clients are numbered 1:nbClients)
    for j in 1:nbClients
        # Check successor relationship
        if haskey(succ1, j) && haskey(succ2, j)
            if succ1[j] != succ2[j] && succ1[j] != pred2[j]
                differences += 1
            end
        end
        
        # Check predecessor relationship
        if haskey(pred1, j) 
            if pred1[j] == 0 && (pred2.get(j, -1) != 0 || succ2.get(j, -1) != 0)
                differences += 1
            elseif haskey(pred2, j) && pred1[j] != pred2[j] && pred1[j] != succ2[j]
                differences += 1
            end
        end
    end
    
    # Normalize by number of clients
    return differences / nbClients
end

function get_descending_ranks(values::Vector{T}) where T <: Real
    sorted_indices = sortperm(values, rev=true)  # Sort descending
    ranks = zeros(Int, length(values))
    for (rank, idx) in enumerate(sorted_indices)
        ranks[idx] = rank  # Assign rank to original position
    end
    return ranks
end

function calc_biased_fitness(genetic_pool::Population, subpopulation::Vector{Int}, nbClose::Int, nbElite::Int)
    subpopulation_cost = [genetic_pool.genes[i].fitness for i in subpopulation]

    subpopulation_diversity = zeros(Float64, length(subpopulation))
    
    for (idx_i, i) in enumerate(subpopulation)
        div_cont = 0.0
        distances = []
        
        for (idx_j, j) in enumerate(subpopulation)
            idx_i == idx_j && continue
            dist = broken_pair_distance(i, j, genetic_pool)
            push!(distances, (dist, j))
        end
        
        sort!(distances, by = x -> x[1])
        div_cont = sum(d[1] for d in distances[1:min(nbClose, length(distances))])
        
        subpopulation_diversity[idx_i] = div_cont / nbClose
    end
    
    subpop_cost_rank = get_descending_ranks(subpopulation_cost)
    subpop_diver_rank = get_descending_ranks(subpopulation_diversity)

    if length(subpopulation) == 1
        for (idx_i, i) in enumerate(subpopulation)
            bf = 0
            genetic_pool.biased_fitness_array[i] = bf_p
        end        
    else
        for (idx_i, i) in enumerate(subpopulation)
            fit_p = subpop_cost_rank[idx_i]
            fit_d = subpop_diver_rank[idx_i]
            bf_p = fit_p + ( 1 - (nbElite/length(subpopulation)) )*fit_d
            genetic_pool.biased_fitness_array[i] = bf_p
        end
    end
end


function constrain_cal(curr_gene::Gene, depot::Depot, patients::Vector{Patient}, time_matrix)
    total_tw = 0
    duration_array = Vector{Float32}()
    tw_array = Vector{Float32}()
    cap_array = Vector{Int}()
    routes = curr_gene.gene_r
    for route in routes
        prev = 1
        current_time = 0
        route_tw = 0
        total_cap = 0
        for customer in route
            customer_req = patients[customer].demand
            total_cap += customer_req
            customer_start = patients[customer].start_time
            customer_end = patients[customer].end_time - patients[customer].care_time
            tr = current_time + time_matrix(prev, customer+1)
            if tr > customer_end
                tw_induced = tr-customer_end
                total_tw += tw_induced
                route_tw += tw_induced
                tr = customer_end
            end
            if tr < customer_start
                wait_time = customer_start - tr
            else
                wait_time = 0
            end
            current_time = tr + wait_time + patients[customer].care_time
            prev = customer+1
        end
        tr_depot = current_time + time_matrix(prev, 1)
        route_dur = tr_depot + route_tw
        push!(duration_array, route_dur)
        push!(tw_array, route_tw)
        push!(cap_array, total_cap)

        # Vidal's work dosent consider going late to depot as time wrap
        # if tr_depot > depot.return_time
        #     tw_induced = tr_depot - depot.return_time
        #     total_tw += tw_induced
        # end
    end
    return tw_array, duration_array, cap_array
end

function check_feasible(curr_gene::Gene, patients::Vector{Patient}, depot::Depot, time_matrix)
    tw_array, duration_array, cap_array = constrain_cal(curr_gene, depot, patients, time_matrix)

    if any(cap_array .> depot.nurse_cap)  # Check if any duration violation exists
        return 1
    elseif any(duration_array .> depot.return_time)  # Check if any capacity violation exists
        return 2
    elseif any(tw_array .> 0)  # Check if any time window violation exists
        return 3
    else
        return 0  # No violations
    end
end



end