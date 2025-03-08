
module PermutationMutation 

import Random.rand
import Random.randperm!
import Random.shuffle!
import Random.Xoshiro

using ..Operations

export pop_swap_mut!, pop_insert_mut!, pop_scramble_mut!, pop_scramble_seg_mut!, route_mutation!, inversion_mut!, EE_M, EE_M!

function pop_replace!(genotype::Vector{Int64}, i_1, i_2)
    """
    This mutation essentially switches which patient receives care from which doctor. In other words, it will take the whole (nurse_id x route index) and swap it
    for another patient's value.
    """
    temp = genotype[i_1]
    genotype[i_1] = genotype[i_2]
    genotype[i_2] = temp
end

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

function inversion_mut!(genotype::Vector{Int64}, mutation_rate::Float16)
    if rand() < mutation_rate

        rand_1 = rand(1:size(genotype, 1))
        rand_2 = rand(1:size(genotype, 1))
        start_index = min(rand_1, rand_2)
        end_index = max(rand_1, rand_2)
        reverse!(genotype, start_index, end_index)
    end
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

function EE_M!(individual, patients, travel_time_table) # ::Gene
    
    centroids = []
    for route in individual.gene_r
        push!(centroids, (get_centroid(route, patients)))
    end

    for (route_index, route) in enumerate(individual.gene_r)
        for (i, patient_id) in enumerate(route)
            # println(route)
            neighbors = get_route_neighborhood(centroids, route_index, patients[patient_id])
            # neighbors = get_route_neighborhood(10, centroids, route_index, patients[patient_id])
            old_cost, _ = calculate_cost(route, patients, travel_time_table)
            deleteat!(route, i) 
            new_cost, _ = calculate_cost(route, patients, travel_time_table)
            removal_reward = new_cost - old_cost
            new_route, is_better_solution = first_apply_neighbor_insert!(removal_reward, neighbors, individual.gene_r, patient_id, patients, travel_time_table)
            if is_better_solution == false
                insert!(route, i, patient_id) # No better position...
            else
                return new_route
            end
        end
    end
    return gene_r
end

# TODO:
# Integrate the individual data type into this
# Make this EE_M return the solution instead of directly changing it.

function EE_M(gene_r, patients, travel_time_table) # ::Gene
    
    centroids = []
    for route in gene_r
        push!(centroids, (get_centroid(route, patients)))
    end

    # println(gene_r)
    for (route_index, route) in enumerate(gene_r)
        for (i, patient_id) in enumerate(route)
            # println(route)
            neighbors = get_route_neighborhood(centroids, route_index, patients[patient_id])
            # neighbors = get_route_neighborhood(10, centroids, route_index, patients[patient_id])
            old_cost, _ = calculate_cost(route, patients, travel_time_table)
            deleteat!(route, i) 
            new_cost, _ = calculate_cost(route, patients, travel_time_table)
            removal_reward = new_cost - old_cost
            new_route, is_better_solution = first_apply_neighbor_insert!(removal_reward, neighbors, gene_r[1:end], patient_id, patients, travel_time_table)
            if is_better_solution == false
                insert!(route, i, patient_id) # No better position...
            else
                return new_route
            end
        end
    end
    return gene_r
end

# sequence::Vector{Int}       # Sequence of the gene, represents an individual from population
# fitness::Float32        # Fitness value of the Gene
# gene_r::Vector{Vector{Int}}     # Contains the sequence splitted into routes / patient routes divided into nurses
# d0_x::Vector{Float32}       # Array containg d0x for each patient in the sequence in respective order. d0x represents distance from deport to patient x
# dx_0::Vector{Float32}       # Array containg dx0 for each patient in the sequence in respective order. dx0 represents distance from patient x to deport
# dnext::Vector{Float32}      # Array containg dnext for each patient in resp order. dnext is distance of xth patient to (x+1)th paient in the gene sequence
# sum_load::Vector{Int}       # Summation of demand till and including the xth patient in the sequence
# sum_dist::Vector{Float32}  

end