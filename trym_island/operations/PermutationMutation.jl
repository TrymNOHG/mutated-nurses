
module PermutationMutation 

import Random.rand
import Random.randperm!
import Random.shuffle!
import Random.Xoshiro

export pop_swap_mut!, pop_insert_mut!, pop_scramble_mut!, pop_scramble_seg_mut!, route_mutation!, inversion_mut!

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

function get_centroid(route, patients)
    sum_x = 0
    sum_y = 0
    for patient in route
        sum_x += patients[patient].x_coord
        sum_y += patients[patient].y_coord
    end
    avg_x = sum_x / size(route, 1)
    avg_y = sum_y / size(route, 1)
    return avg_x, avg_y
end

# Centroids should be cached...

# Missing from EE_M:
# Actual fitness function used.

function EE_M!(individual, patients) # ::Gene
    centroids = []
    for route in individual.gene_r
        push!(centroids, (get_centroid(route, patients)))
    end

    for (route_index, route) in enumerate(individual.gene_r)
        for (i, patient_id) in enumerate(route)
            # Finds 2 closest tours based on minimum distance to centroids
            neighbors = [] # Shortest distance will be kept at end of list
            patient = patients[patiend_id]
            for (centroid_id, centroid) in enumerate(centroids) 
                if centroid_id == route_index
                    continue
                end
                distance = sqrt((centroid[1] - patient.x_coord)^2 + (centroid[2] - patient.y_coord)^2)
                if size(neighbors, 1) < 1
                    push!(neighbors, [distance, centroid_id])
                elseif size(neighbors) < 2
                    if distance < neighbors[1][1]
                        push!(neighbors, neighbors[1])
                        neighbors[1] = [distance, centroid_id]
                    else
                        push!(neighbors, [distance, centroid_id])
                    end
                elseif distance < neighbors[2][1]
                    if distance > neighbors[1][1]
                        neighbors[2] = [distance, centroid_id]
                    else
                        neighbors[2] = neighbors[1]
                        neighbors[1] = [distance, centroid_id]
                    end
                end
            end

            current_fitness = individual.fitness
            deleteat!(route, i) # Remove patient from its current route
            better_solution = false
            for centroid_info in neighbors
                route_id = centroid_info[2]
                neighbor_route = individual.gene_r[route_id]
                for i in size(neighbor_route, 1)
                    insert!(neighbor_route, patiend_id, i)
                    new_fitness = 1234 # I need to add the actual calculation of new fitness
                    if new_fitness < current_fitness
                        better_solution = true # Mutation was successful.
                        break
                    end
                    deleteat!(neighbor_route, i) # Remove patient from the neighbor route
                end
                if better_solution == true
                    break
                end
                # Insert patient into every spot in the first closest neighbor. If an improvement occurs, immediately accept it.
            end
            if better_solution == false
                insert!(route, patient_id, i) # No better position...
            end

        end
    end
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