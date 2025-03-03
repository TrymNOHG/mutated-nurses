module Recombination

export perform_crossover, order_1_crossover!, PMX!, gen_edge_table, TBX!

import Random.shuffle!

include("../models/Solution.jl")

function perform_crossover(parents, num_patients, cross_rate)
    """
    This function performs one-point cross-over on a list of parents. To increase
    the randomness associated with recombination, the parents list is shuffled before
    two parents are drawn.
    """
    current_index = 1
    survivors = []

    shuffle!(parents)
    # println("Number of parents: ")
    # println(size(parents, 1))
    while current_index < size(parents, 1)
        parent_1, parent_2 = parents[current_index:current_index+1]
        if rand() < cross_rate
            # TBX!(parent_1, parent_2, survivors, num_patients)
            # TBX!(parent_2, parent_1, survivors, num_patients)
            PMX!(parent_1, parent_2, survivors, num_patients)
            PMX!(parent_1, parent_2, survivors, num_patients)
            # order_1_crossover!(parent_1, parent_2, survivors, num_patients)
            # order_1_crossover!(parent_2, parent_1, survivors, num_patients)
        else
            push!(survivors, parent_1)
            push!(survivors, parent_2)
        end
        current_index += 2
    end

    return survivors
end

# TODO: test differnet crossover methods
# TODO: implement repair functionality for crossover

function order_1_crossover!(parent_1, parent_2, survivors, num_patients)
    split_index_1 = rand(1:num_patients)
    split_index_2 = rand(1:num_patients)
    interval = (min(split_index_1, split_index_2), max(split_index_1, split_index_2))

    child_values = [0 for _ in 1:num_patients]
    segment = parent_1.values[interval[1]:interval[2]]
    child_values[interval[1]:interval[2]] = segment
    parent_2_index = (interval[2] % num_patients) + 1
    child_index = parent_2_index

    while child_index < interval[1] || child_index > interval[2]

        potential_val = parent_2.values[parent_2_index]
        in_seg = false
        for val in segment
            if potential_val == val
                in_seg = true
                break
            end
        end

        if in_seg == false
            child_values[child_index] = potential_val
            child_index = (child_index % num_patients) + 1
        end
        
        parent_2_index = (parent_2_index % num_patients) + 1 # Could make into if statements if modulo costs too much

    end 

    # Could easily make two children just by using different route indices


    child = Solution(child_values, parent_1.indices)
    push!(survivors, child)
end

function hash_index(list_2, result, start_index)
    for i in 1:size(list_2, 1)
        if list_2[i] == result[start_index]
            return i
        end
    end
    throw(Error(""))
    return 0
end


function PMX!(parent_1, parent_2, survivors, num_patients)
    split_index_1 = rand(1:num_patients)
    split_index_2 = rand(1:num_patients)
    interval = (min(split_index_1, split_index_2), max(split_index_1, split_index_2))

    child_values = [0 for _ in 1:num_patients]
    segment = parent_1.values[interval[1]:interval[2]]
    child_values[interval[1]:interval[2]] = segment

    for i in interval[1]:interval[2]
        if parent_2.values[i] ∉ segment
            # println(i)
            # println(parent_2.values[i])
            index = i
            while interval[1] <= index <= interval[2]
                index = hash_index(parent_2.values, child_values, index)
                # println(index)
            end
            child_values[index] = parent_2.values[i]
        end
    end

    j = 1
    for i in 1:size(child_values, 1)
        while interval[1] <= j <= interval[2]
            j += 1
        end
        if j > size(parent_2.values, 1)
            break
        end
        if parent_2.values[j] in segment
            j += 1
        elseif child_values[i] == 0
            child_values[i] = parent_2.values[j]
            j += 1
        end
    end

    child = Solution(child_values, parent_1.indices)
    push!(survivors, child)
end

function gen_edge_table(parent_1_vals, parent_2_vals)
    edge_table = [[] for _ in 1:size(parent_1_vals, 1)]
    for i in 1:size(parent_1_vals, 1)
        left_index = i > 1 ? i - 1 : size(parent_1_vals, 1) 
        right_index = i < size(parent_1_vals, 1) ? i + 1 : 1
        # println(parent_1_vals[i])
        # println(i)
        # println(left_index)
        # println(parent_1_vals[left_index])
        # println(parent_1_vals[right_index])
        p_1_left = parent_1_vals[left_index]
        p_1_right = parent_1_vals[right_index]
        p_2_left = parent_1_vals[left_index]
        p_2_right = parent_1_vals[right_index]
        # if 
        push!(edge_table[parent_1_vals[i]], )
        push!(edge_table[parent_1_vals[i]], parent_1_vals[right_index])
        push!(edge_table[parent_2_vals[i]], parent_2_vals[left_index])
        push!(edge_table[parent_2_vals[i]], parent_2_vals[right_index])
    end
    println(edge_table)
end

function edge_3_crossover!(parent_1, parent_2, survivors, num_patients)
#     1. Construct the edge table
# 2. Pick an initial element at random and put it in the offspring
# 3. Set the variable current element = entry
# 4. Remove all references to current element from the table
# 5. Examine list for current element
# • If there is a common edge, pick that to be the next element
# • Otherwise pick the entry in the list which itself has the shortest list
# • Ties are split at random
# 6. In the case of reaching an empty list, the other end of the offspring is examined for extension; otherwise a new element is chosen at random

    child = Solution(child_values, parent_1.indices)
    push!(survivors, child)
end

function TBX!(parent_1, parent_2, survivors, num_patients)
    # Naive/slow implementation
    split_index_1 = rand(1:num_patients)
    split_index_2 = rand(1:num_patients)
    interval = (min(split_index_1, split_index_2), max(split_index_1, split_index_2))

    child_values = parent_2.values[1:end]
    child_values[interval[1]:interval[2]] = parent_1.values[interval[1]:interval[2]]

    xover_map = [i for i in 1:num_patients]
    shuffle!(xover_map)

    for i in 1:size(child_values, 1)
        child_values[i] =  child_values[i] * num_patients + xover_map[i]
    end

    values = child_values[1:end]
    sort!(values)
    for i in 1:size(values, 1)
        for j in 1:size(child_values, 1)
            if child_values[j] == values[i]
                child_values[j] = i
            end
        end 
    end

    child = Solution(child_values, parent_1.indices)
    push!(survivors, child)

end

function bitstring_crossover!(parent_1, parent_2, survivors)
    split_index = trunc(Int, (rand() * (individual_length - 2))) + 2
    child_1 = BitVector()
    child_2 = BitVector()
    for i in 1:individual_length
        if i < split_index
            push!(child_1, parent_1[i])
            push!(child_2, parent_2[i])
        else
            push!(child_1, parent_2[i])
            push!(child_2, parent_1[i])
        end
    end
    current_index += 2
    push!(survivors, child_1)
    push!(survivors, child_2)
end

end