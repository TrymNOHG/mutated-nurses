module Recombination

export perform_crossover, order_1_crossover!

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
            order_1_crossover!(parent_1, parent_2, survivors, num_patients)
            order_1_crossover!(parent_2, parent_1, survivors, num_patients)
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