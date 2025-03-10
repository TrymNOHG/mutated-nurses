module Recombination

export perform_crossover, order_1_crossover!, PMX!, gen_edge_table, TBX!, edge_3_crossover!

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
            # PMX!(parent_1, parent_2, survivors, num_patients)
            # PMX!(parent_1, parent_2, survivors, num_patients)
            edge_3_crossover!(parent_1, parent_2, survivors, num_patients)
            edge_3_crossover!(parent_2, parent_1, survivors, num_patients)
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
        p_1_left = parent_1_vals[left_index]
        p_1_right = parent_1_vals[right_index]
        p_2_left = parent_2_vals[left_index]
        p_2_right = parent_2_vals[right_index]
        push!(edge_table[parent_1_vals[i]], p_1_left)
        push!(edge_table[parent_1_vals[i]], p_1_right)
        push!(edge_table[parent_2_vals[i]], p_2_left)
        push!(edge_table[parent_2_vals[i]], p_2_right)
    end
    return edge_table
end

function add_edge!(results, edge_table, index)
    push!(results, index)
    for edges in edge_table
        deleted = 0
        for i in 1:size(edges, 1)
            if edges[i-deleted] == index
                deleteat!(edges, i-deleted)
                deleted += 1
            end
        end
    end
end

function find_common_edge(edges)
    for (i, val) in enumerate(edges)
        if i < size(edges, 1)
            for other_val in edges[i+1:end]
                if val == other_val 
                    # Then, common edge found.
                    return true, val
                end
            end
        end
    end
    return false, 0
end

function find_shortest_list(edge_table, edges)
    candidates = []
    shortest_length = 4
    for val in edges
        len = length(Set{Int32}(edge_table[val]))
        if len < shortest_length
            candidates = [val]
            shortest_length = len
        elseif len == shortest_length
            push!(candidates, val)
        end
    end
    return candidates
end

function edge_3_crossover!(parent_1, parent_2, survivors, num_patients)
    # Need to implement the detection/representation of common edges better.
    edge_table = gen_edge_table(parent_1.values, parent_2.values)
    current_index = rand(1:num_patients)
    result = []
    add_edge!(result, edge_table, current_index)
    while size(result, 1) < num_patients
        edges = edge_table[current_index]
        if size(edges, 1) == 0
            current_index = rand(1:num_patients) # Seems like it can take a while to find the last value...
            continue
        end
        is_common_edge, val = find_common_edge(edges)
        if is_common_edge == true
            current_index = val
        else
            # No common edge, then find entry with shortest list, else random
            shortest_list_candidates = find_shortest_list(edge_table, edges)
            current_index = shortest_list_candidates[rand(1:size(shortest_list_candidates, 1))]
        end
        add_edge!(result, edge_table, current_index)
    end

    # Random -> Shortest_list (from random's edges) -> Common Edge
    child = Solution(result, parent_1.indices)
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