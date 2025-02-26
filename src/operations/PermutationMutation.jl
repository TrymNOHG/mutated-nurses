
module PermutationMutation 

import Random.rand
import Random.randperm!
import Random.shuffle!
import Random.Xoshiro

export pop_swap_mut!, pop_insert_mut!, pop_scramble_mut!, pop_scramble_seg_mut!, route_mutation!

function pop_replace!(genotype::Vector{Int64}, i_1, i_2)
    """
    This mutation essentially switches which patient receives care from which doctor. In other words, it will take the whole (nurse_id x route index) and swap it
    for another patient's value.
    """
    temp = genotype[i_1]
    genotype[i_1] = genotype[i_2]
    genotype[i_2] = temp
end

# Create a function that swaps nurses intra population and repairs the broken routes.

function pop_swap_mut!(genotype::Vector{Int64}, mutation_rate::Float16)
    for (i, value) in enumerate(genotype)
        if rand() < mutation_rate
            swap_index = rand(1:size(genotype, 1))
            while swap_index == i
                swap_index = rand(1:size(genotype, 1))
            end
            pop_replace!(genotype, i, swap_index)
        end
    end
end

function pop_insert_mut!(genotype::Vector{Int64}, mutation_rate::Float16)
    for (i, value) in enumerate(genotype)
        if rand() < mutation_rate
            insert_index = rand(1:size(genotype, 1))
            pop_replace!(genotype, i, insert_index)
        end
    end
end 

function pop_scramble_mut!(genotype::Vector{Int64}, mutation_rate::Float16)
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
    shuffle!(Xoshiro(), values)
    
    for i in 1:size(indices, 1)
        genotype[indices[i]] = values[i]
    end
end 

function pop_scramble_seg_mut!(genotype::Vector{Int64}, mutation_rate::Float16)
    """
    This function collects a random segment of values, shuffles it, and inserts it back into the genotype.
    """
    if rand() < mutation_rate

        rand_1 = rand(1:size(genotype, 1))
        rand_2 = rand(1:size(genotype, 1))
        
        start_index = min(rand_1, rand_2)
        end_index = max(rand_1, rand_2)

        segment = genotype[start_index:end_index]
            
        shuffle!(Xoshiro(), segment)
    
        genotype[start_index:end_index] = segment
    end
end 

function inversion_mut(genotype::Vector{Int64}, mutation_rate::Float16)
end 

function route_mutation!(indices::Vector{Int64}, num_patients::Int64, mutate_rate::Float16)
    if rand() < mutate_rate
        indices[1] = rand(1:indices[2]-1)
    end
    
    for i in 2:size(indices, 1)-1
        if rand() < mutate_rate
            indices[i] = rand(indices[i-1] + 1:indices[i+1] - 1)
        end
    end
    if rand() < mutate_rate
        indices[end] = rand(indices[end-1] + 1:num_patients)
    end
end


end