module Population

import Random.Xoshiro
import Random.randperm!
import Random.shuffle!

include("../models/Solution.jl")

export init_permutation, init_bitstring, init_permutation_specific, repair!, is_feasible

# Feasible solutions for initial populations are first generated using a sequential insertion heuristic in which customers are inserted in 
# random order at randomly chosen insertion positions within routes. This strategy is fast and simple while ensuring unbiased solution generation. 
# The initialization procedure then proceeds as follows:

function init_rand_pop(num_patients, num_nurses)
    gene_r = [[] for _ in 1:num_nurses]
    patients = [i for i in 1:num_patients]
    shuffle!(patients)
    for i in patients:
        push!(gene_r[rand(1:num_nurses)], i)
    end
    return gene_r
end

function init_populations(num_patients, num_nurses, mu, n_p)
    populations = [init_rand_pop(num_patients, num_nurses) for _ in 1:2]
    for pop in populations
        # Generate two populations seemingly random? 
        for i in 1:n_p
            # Apparently the next steps:
            # Generate a new solution Sj using the EE_M mutator (defined in Section 2.3.2)
            # Add Sj in Pop_x

            # 
        end
        # sequence = collect(Iterators.flatten(gene_r)) # Way to flatten the 2-d array
    end

end

function re_init(num_nurses, num_patients)
    patients = [i for i in 1:num_patients]
    shuffle!(patients)
    routes = [[pop!(paitents)] for i in 1:num_nurses]

    i = 0
    # It seems that all of the remaining patients are ranked according to their regret cost.
    # The patients with the highest regret costs are inserted first, since they will have fewer good options later.

    # TODO:
    # Create function to calculate the regret cost of a given customer.
    # 1. Collect all feasible of these for all remaining patients.
    # 2. Sort based on their regret costs.
    # 3. Insert patient with highest regret cost. Repeat step 1.
    # All patients that currently have infeasible insertions will be collected. Then, an extended insertion regret cost function is applied. 


    while i < size(patients, 1)
        centroids = get_all_centroids(routes)
        closest_neighbors = get_route_neighborhood(centroids, patient_route_id, patient)
        # inserted = best_apply_neighbor_insert!(typemax(Int32), closest_neighbors, routes, patient_id)
        inserted = minimum_insertion_regret(closest_neighbors, routes, patient_id)
        
        if !inserted
            #
        end
    end 

    # Insert in locations that minimize cost and do not violate time-window constraint.
    # Here, it might be smart to keep track of the time window and update it.

end

# Go through the current route and collect all violations
# at the same time build a list of the earliest?
# Linearly try and insert the violations into the route in order to fulfill the time-window constraint.

function is_feasible(individual, patients, depot, travel_time_table)
    # if length(Set(individual.values)) != size(patients, 1)
    #     return false
    # end
    multiplier = 1

    for i in 0:size(individual.indices, 1)
        if i == 0
            route = individual.values[1:individual.indices[1] - 1]
        elseif i == size(individual.indices, 1)
            route = individual.values[individual.indices[i]:end]
        else
            route = individual.values[individual.indices[i]:individual.indices[i+1] - 1]
        end
        time = 0
        demand = 0
        from = 1
        # println()
        for (i, patient) in enumerate(route)
            # println(patient)
            # println(patients[patient])
            demand += patients[patient].care_time
            to = i + 1
            time += travel_time_table[from][to]
            if time < patients[patient].start_time
                time = patients[patient].start_time + patients[patient].care_time
                from = to
            elseif patients[patient].start_time <= time <= patients[patient].end_time - patients[patient].care_time
                time += patients[patient].care_time
                from = to
            else
                # println(time)
                # println("Time window violation")
                multiplier += 1
                # return false
            end
        end
        if demand > depot.nurse_cap || time > depot.return_time
            multiplier += 0.5
        end
    end

    return multiplier == 1, multiplier
    # Check demand
    # Check scheduling
    # Check return time
    # Could also check that each patient is only visited once (but this is a bit unnecessary)
end



end