module Population

import Random.Xoshiro
import Random.randperm!
import Random.shuffle!

include("../models/Solution.jl")

export init_permutation, init_bitstring, init_permutation_specific, repair!, is_feasible, gen_heuristic_perm_individual

# Function to initialize different encodings such as bitstring, permutation, etc.

function gen_route_individual(num_nurses::Integer, num_patients::Integer)
    nurse_ids = Vector{Integer}([])
    num_patients_per_nurse = num_patients ÷ num_nurses
    rest = num_patients % num_nurses
    for id in 0:num_nurses-1
        id <<= 4
        for index in 0:num_patients_per_nurse - 1
            # println(id | index)
            push!(nurse_ids, id | index)
        end
        if rest > 0
            push!(nurse_ids, id | num_patients_per_nurse)
            rest -= 1
        end
    end
    # println(nurse_ids)
    return shuffle!(Xoshiro(), nurse_ids)
end


# Easiest implementation first
# function gen_perm_individual(num_nurses::Integer, num_patients::Integer)
#     """
#     This function generates an individual where the genotype consists of an n-vector of variable vectors. n is the number of nurses. The sum of the sizes of the variable 
#     vectors equals the number of patients. Furthermore, the entries in the vectors form a set of patient ids.
#     """
#     nurses = [[] for _ in 1:num_nurses]
#     patients = [i for i in 1:num_patients]
#     while size(patients, 1) > 0
#         nurse_id = rand(1:num_nurses)
#         push!(nurses[nurse_id], pop!(patients))
#     end
#     return nurses
# end

function gen_perm_individual(num_nurses::Integer, num_patients::Integer)
    """
    This function generates an individual where the genotype consists of an n-vector of variable vectors. n is the number of nurses. The sum of the sizes of the variable 
    vectors equals the number of patients. Furthermore, the entries in the vectors form a set of patient ids.
    """
    patients = [i for i in 1:num_patients]
    shuffle!(patients)
    avg_route = num_patients ÷ num_nurses
    nurse_indices = []
    current = 0
    for i in 1:num_nurses-1
        current += rand(1:avg_route)
        push!(nurse_indices, current)
    end

    return Solution(patients, nurse_indices)
end


function gen_heuristic_perm_individual(num_nurses::Integer, num_patients::Integer, travel_time_table)
    """
    This function generates an individual where the genotype consists of an n-vector of variable vectors. n is the number of nurses. The sum of the sizes of the variable 
    vectors equals the number of patients. Furthermore, the entries in the vectors form a set of patient ids.
    """
    patients = [i for i in 1:num_patients]
    shuffle!(patients)

    nurse_indices = [i+1 for i in 1:num_nurses-1]
    routes = []
    for i in 1:num_nurses
        push!(routes, [pop!(patients)])
    end

    while size(patients, 1) > 0
        next_patient = pop!(patients)
        choice = 0
        best_val = typemax(Int32)

        for (i, route) in enumerate(routes)
            value = travel_time_table[route[end]][next_patient] + travel_time_table[next_patient][1] - travel_time_table[route[end]][1] + 1 * size(route, 1)
            if value < best_val
                choice = i
                best_val = value
            end
        end
        push!(routes[choice], next_patient)
        for i in choice:num_nurses-1
            nurse_indices[i] += 1
        end
    end
    patients = collect(Iterators.flatten(routes))
    return Solution(patients, nurse_indices)
end

function init_permutation_general(individual_size::Integer, pop_size::Integer)
    return [randperm!(Xoshiro(), individual_size) for _ in 1:pop_size]
end

function init_permutation_specific(num_nurses::Integer, num_patients::Integer, pop_size::Integer, travel_time_table)
    return [gen_perm_individual(num_nurses, num_patients) for _ in 1:pop_size]
end

function init_bitstring(individual_size::Integer, pop_size::Integer)
    return [bitrand(Xoshiro(), num_bits) for _ in 1:pop_size]
end

function repair!(individual, patients, travel_time_table)
    """
    Does not repair all currently
    """
    # Check if within time window
    # println(size(individual, 1))
    for i in 0:size(individual.indices, 1)
        if i == 0
            route = individual.values[1:individual.indices[1] - 1]
        elseif i == size(individual.indices, 1)
            route = individual.values[individual.indices[i]:end]
        else
            route = individual.values[individual.indices[i]:individual.indices[i+1] - 1]
        end
        violations = locate_violations!(route, patients, travel_time_table)
        # Is it best to try and organize the violations before trying to insert them into the route again? What is faster?
        # Start off with brute-force
        # Could do some smart interval scheduling things later...
        persistent_violations = []
        while size(violations, 1) > 0 
            current_violation = pop!(violations)
            persist = true
            for (i, patient) in enumerate(route)
                insert!(route, i, current_violation)
                new_violations = locate_violations!(route, patients, travel_time_table)
                if size(new_violations, 1) == 0
                    persist = false
                    break
                end
            end
            if persist == true
                insert!(route, size(route, 1), current_violation)
                new_violations = locate_violations!(route, patients, travel_time_table)
                if size(new_violations, 1) != 0
                    push!(persistent_violations, current_violation)
                end
            end
        end
        push!(route, persistent_violations...)
        # println(persistent_violations)
    end
end

function locate_violations!(route, patients, travel_time_table)
    violations = []
    time = 0
    from = 1
    for (i, patient) in enumerate(route)
        to = i + 1
        time += travel_time_table[from][to]
        if time < patients[patient].start_time
            time = patients[patient].start_time + patients[patient].care_time
            from = to
        elseif patients[patient].start_time <= time <= patients[patient].end_time - patients[patient].care_time
            time += patients[patient].care_time
            from = to
        else
            push!(violations, route[i])
            deleteat!(route, i)
            time -= travel_time_table[from][to]
        end
    end
    return violations
end



# Go through the current route and collect all violations
# at the same time build a list of the earliest?
# Linearly try and insert the violations into the route in order to fulfill the time-window constraint.

function is_feasible(individual, patients, depot, travel_time_table)
    # if length(Set(individual.values)) != size(patients, 1)
    #     return false
    # end
    multiplier = 1

    total_time = 0 
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
                multiplier += 2
                # return false
            end
        end
        total_time += travel_time_table[from][1] + time
        if demand > depot.nurse_cap || time > depot.return_time
            multiplier += 2
        end
    end

    return multiplier == 1, multiplier, total_time
    # Check demand
    # Check scheduling
    # Check return time
    # Could also check that each patient is only visited once (but this is a bit unnecessary)
end

function correct_format(solution)
    actual_solution = []
    for i in 0:size(individual.indices, 1)
        if i == 0
            route = individual.values[1:individual.indices[1] - 1]
        elseif i == size(individual.indices, 1)
            route = individual.values[individual.indices[i]:end]
        else
            route = individual.values[individual.indices[i]:individual.indices[i+1] - 1]
        end
        actual_solution.append(route)
    end
    println(actual_solution)
end

end