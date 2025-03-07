module Fitness

export pop_1_fitness, pop_2_fitness, evaluate

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
        return objective_time + CV
    else
        return CV
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

function distance(gene_r, travel_time_table)
    total_time = 0
    for (i, route) in enumerate(gene_r)
        from = 1 # Depot if depot is 1
        for (_, patient_id) in enumerate(route)
            to = patient_id + 1 # Plus 1 to account for the depot 
            total_time += travel_time_table(from,to)
            from = to
        end
        to = 1 # Return to depot
        total_time += travel_time_table(from,to)
    end

    # If we use the total_time, then this is a minimization optimization problem. Keep this in mind.
    return total_time
end

# function nurse_fitness(individual, travel_time_table, patients, depot)
#     # Constraints:
#     #   Soft:
#     #       - Late return       (Added as a penalty)
#     #       - Capacity exceeded (Added as a penalty)
#     #   Hard:
#     #       - Patient time-windows are met (Should be dealt with prior to coming to this function)
#     #       - Each patient is only visited once (encoded)

#     # TODO: add wait time to nurse_time

#     total_time = 0
#     objective_value = 0
#     for i in 0:size(individual.indices, 1)
#         if i == 0
#             route = individual.values[1:individual.indices[1] - 1]
#         elseif i == size(individual.indices, 1)
#             route = individual.values[individual.indices[i]:end]
#         else
#             route = individual.values[individual.indices[i]:individual.indices[i+1] - 1]
#         end

#         nurse_time = 0
#         nurse_demand = 0

#         from = 1 # Depot if depot is 1
#         for patient_id in route
#             to = patient_id + 1 # Plus 1 to account for the depot 
#             wait_time = 0
#             nurse_time += travel_time_table[from][to] + patients[patient_id].care_time + wait_time # Duration
#             nurse_demand += patients[patient_id].demand
#             objective_value += travel_time_table[from][to]
#             from = to
#         end
#         to = 1 # Return to depot
#         nurse_time += travel_time_table[from][to]
#         objective_value += travel_time_table[from][to]

#         if nurse_time > depot.return_time
#             nurse_time *= 5            # Penalty for late return
#         end

#         if nurse_demand > depot.nurse_cap      # Penalty for exceeding nurse capacity
#             nurse_time *= 5
#         end

#         total_time += nurse_time
#     end

#     feasible, multiplier = is_feasible(individual, patients, depot, travel_time_table)
#     total_time *= multiplier

#     # If we use the total_time, then this is a minimization optimization problem. Keep this in mind.
#     return total_time, objective_value

# end

# function simple_nurse_fitness(individual, travel_time_table)
#     # At first, the fitness function will solely contain the total time travelled given the routes for all the nurses
#     # Therefore, I will need to gather the routes to calculate this.
#     total_time = 0
#     for (i, route) in enumerate(individual)
#         from = 1 # Depot if depot is 1
#         for (_, patient_id) in enumerate(route)
#         to = patient_id + 1 # Plus 1 to account for the depot 
#             total_time += travel_time_table[from][to]
#             from = to
#         end
#         to = 1 # Return to depot
#         total_time += travel_time_table[from][to]
#     end

#     # If we use the total_time, then this is a minimization optimization problem. Keep this in mind.
#     return total_time
# end

end