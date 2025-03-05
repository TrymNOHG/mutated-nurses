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

# function check_feasible(curr_gene::Gene, patients::Vector{Patient}, depot::Depot)
#     for route in curr_gene.gene_r
#         route_dem = 0
#         for client_id in route
#             route_dem += patients[client_id].demand
#         end
#         if route_dem > depot.nurse_cap
#             return false
#         end
#     end
#     return true
# end

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
            customer_end = patients[customer].end_time
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
            current_time += tr + wait_time + patients[customer].care_time
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



# function check_feasible(curr_gene::Gene, patients::Vector{Patient}, depot::Depot, time_matrix)
#     for route in curr_gene.gene_r
#         if isempty(route)
#             continue  # Skip empty routes, though typically not expected
#         end
        
#         # Initialize accumulators
#         route_dem = 0.0f0      # Total demand for capacity check
#         route_duration = 0.0f0  # Total duration for duration check
        
#         # Travel from depot to first patient
#         first_pat = route[1]
#         route_duration += time_matrix(1, first_pat)
        
#         # Process each patient in the route
#         for i in 1:length(route)
#             pat_id = route[i]
#             # Add patient's demand and service time
#             route_dem += patients[pat_id].demand
#             route_duration += patients[pat_id].care_time
            
#             # Add travel time to next patient if not the last one
#             if i < length(route)
#                 next_pat = route[i + 1]
#                 route_duration += time_matrix(pat_id, next_pat)
#             end
#         end
        
#         # Travel back to depot from last patient
#         last_pat = route[end]
#         route_duration += time_matrix(last_pat, 1)
        
#         # Check both constraints
#         if route_dem > depot.nurse_cap || route_duration > depot.return_time
#             return false
#         end
#     end
#     return true
# end

end