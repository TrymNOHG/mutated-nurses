module FitnFeasible

using ..Split
using ..Models

export generic_fitness, check_feasible

function generic_fitness(gene::Vector{Integer}, time_matrix::Vector{Vector{Integer}}, patient_demands::Vector{Integer}, nurse_cap::Integer, nurse_n::Integer)
    # Would calculate fitness of gene based on the travel time.
    routes = split2routes(gene, time_matrix, patient_demands, nurse_cap, nurse_no)
    total_time = 0
    for route in routes
        route_len = length(route)
        for i in 1:route_len
            patient_id = route[i]
            prev_patiend_id = 1
            if i == 1
                total_time += time_matrix[1,patient_id]
            
            elseif i == route_len
                total_time += time_matrix[patient_id,1]
            
            else
                total_time += time_matrix[prev_patiend_id+1,patient_id+1]

            end
            prev_patiend_id = patient_id
        end
    end
    return -total_time
end

function check_feasible(curr_gene::Gene, patients::Vector{Patient}, depot::Depot)
    for route in curr_gene.gene_r
        route_dem = 0
        for client_id in route
            route_dem += patients[client_id].demand
        end
        if route_dem > depot.nurse_cap
            return false
        end
    end
    return true
end


end