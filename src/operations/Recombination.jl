module Recombination

function perform_crossover(parents, cross_rate)
    """
    This function performs one-point cross-over on a list of parents. To increase
    the randomness associated with recombination, the parents list is shuffled before
    two parents are drawn.
    """
    individual_length = size(parents[1], 1) 
    current_index = 1
    survivors = []

    parents = shuffle(parents)
    while current_index + 1 < size(parents, 1)
        parent_1, parent_2 = parents[current_index:current_index+1]
        if rand() < cross_rate
            push!(survivors, parent_1)
            push!(survivors, parent_2)
        else
            
        end
    end

    return survivors
end

# TODO: test differnet crossover methods
# TODO: implement repair functionality for crossover

function permutation_crossover()
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