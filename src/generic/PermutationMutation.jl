import Random.rand
import Random.Xoshiro

module PermutationMutation 

export swap_mut, insert_mut, scramble_mut, scramble_seg_mut

function replace!(genotype::Vector{Integer}, i_1, i_2)
    temp = genotype[i_1]
    genotype[i_1] = genotype[i_2]
    genotype[i_2] = temp
end

function swap_mut!(genotype::Vector{Integer}, mutation_rate::Float32)
    for (i, value) in enumerate(genotype)
        if rand() < mutation_rate
            swap_index = Integer(rand()*(size(genotype, 1)-1)) + 1
            while swap_index == i
                swap_index = Integer(rand()*(size(genotype, 1)-1)) + 1
            end
            replace!(genotype, i, swap_index)
        end
    end
end

function insert_mut!(genotype::Vector{Integer}, mutation_rate::Float32)
    for (i, value) in enumerate(genotype)
        if rand() < mutation_rate
            insert_index = Integer(rand()*size(genotype, 1)) + 1
            replace!(genotype, i, swap_index)
        end
    end
end 

function scramble_mut!(genotype::Vector{Integer}, mutation_rate::Float32)
    """
    This function collects a random group of values, shuffles them, and inserts them back into the genotype.
    """
    values = []
    indices = []
    for (i, value) in enumerate(genotype)
        if rand() < mutation_rate
            push!(values, value)
            push!(indices, i)
        end
    end
    randperm!(Xoshiro(123), values)
    
    for i in 1:size(indices, 1)
        genotype[indices[i]] = values[i]
    end
end 

function scramble_seg_mut!(genotype::Vector{Integer}, mutation_rate::Float32)
    """
    This function collects a random segment of values, shuffles it, and inserts it back into the genotype.
    """

    rand_1 = Integer(rand()*size(genotype, 1))
    rand_2 = Integer(rand()*size(genotype, 1))
    
    start_index = min(rand_1, rand_2)
    end_index = max(rand_1, rand_2)

    segment = genotype[start_index:end_index]
        
    randperm!(Xoshiro(123), segment)
    
    j = 0
    for i in start_index:end_index
        genotype[i] = segment[j]
        j += 1
    end

end 

function inversion_mut(genotype::Vector{Integer}, mutation_rate::Float32)
end 


end