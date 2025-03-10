module Fitness

export pop_1_fitness, pop_2_fitness, evaluate, route_distance, fitness, distance

function fitness(pop_id, gene_r, patients, travel_time_table, time_pen, num_time_pen)
    CV = 0
    time_violations = 0
    objective_time = 0
    for route in gene_r
        time = 0
        from = 1 # Depot if depot is 1
        for patient_id in route
            to = patient_id + 1 # Plus 1 to account for the depot 
            time += travel_time_table(from,to)
            objective_time += travel_time_table(from,to)
            late = max(0, time - (patients[patient_id].end_time-patients[patient_id].care_time)) 
            CV += time_pen * late
            if late > 0
                time_violations += 1
            end
            time += patients[patient_id].care_time
            from = to
        end
        objective_time += travel_time_table(from,1)
    end
    CV += num_time_pen * time_violations

    if pop_id == 1
        return objective_time + CV, time_violations != 0
    else
        return CV, time_violations != 0
    end
end

function calc_temporal_constraint(gene_r, patients, travel_time_table, time_pen, num_time_pen)
    CV = 0
    time_violations = 0
    for route in gene_r
        time = 0
        from = 1 # Depot if depot is 1
        for patient_id in route
            to = patient_id + 1 # Plus 1 to account for the depot 
            time += travel_time_table(from,to)
            late = max(0, time - (patients[patient_id].end_time-patients[patient_id].care_time)) 
            CV += time_pen * late
            if late > 0
                time_violations += 1
            end
            time += patients[patient_id].care_time
            from = to
        end
    end
    CV += num_time_pen * time_violations
end

# r_m = total_demand / total_capacity (How capacity constraint is included)
# gamma is a user-defined parameter
function evaluate(gene_r, patients, travel_time_table, num_patients, r_m, gamma, time_pen, num_time_pen) 

    E_i = size(gene_r, 1) - r_m + distance(gene_r, travel_time_table) * gamma
    CV = calc_temporal_constraint(gene_r, patients, travel_time_table, time_pen, num_time_pen) 

    return E_i + CV
end

function route_distance(route, travel_time_table)
    total_time = 0
    from = 1 # Depot if depot is 1
    for (_, patient_id) in enumerate(route)
        to = patient_id + 1 # Plus 1 to account for the depot 
        total_time += travel_time_table(from,to)
        from = to
    end
    to = 1 # Return to depot
    total_time += travel_time_table(from,to)
    return total_time
end

function distance(gene_r, travel_time_table)
    total_time = 0
    for (i, route) in enumerate(gene_r)
        total_time += route_distance(route, travel_time_table)
    end
    # If we use the total_time, then this is a minimization optimization problem. Keep this in mind.
    return total_time
end

end