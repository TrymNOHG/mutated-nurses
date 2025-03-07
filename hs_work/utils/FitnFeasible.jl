module FitnFeasible

using ..Split
using ..Models

export generic_fitness, check_feasible


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



end