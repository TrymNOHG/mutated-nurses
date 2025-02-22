module Population

import Random.Xoshiro
import Random.randperm!
import Random.shuffle!

export init_permutation, init_bitstring, init_permutation_specific

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
    println(nurse_ids)
    return shuffle!(Xoshiro(), nurse_ids)
end


# Easiest implementation first
function gen_perm_individual(num_nurses::Integer, num_patients::Integer)
    """
    This function generates an individual where the genotype consists of an n-vector of variable vectors. n is the number of nurses. The sum of the sizes of the variable 
    vectors equals the number of patients. Furthermore, the entries in the vectors form a set of patient ids.
    """
    nurses = [[] for _ in 1:num_nurses]
    patients = [i for i in 1:num_patients]
    while size(patients, 1) > 0
        nurse_id = rand(1:num_nurses)
        push!(nurses[nurse_id], pop!(patients))
    end
    return nurses
end

function init_permutation_general(individual_size::Integer, pop_size::Integer)
    return [randperm!(Xoshiro(), individual_size) for _ in 1:pop_size]
end

function init_permutation_specific(num_nurses::Integer, num_patients::Integer, pop_size::Integer)
    return [gen_perm_individual(num_nurses, num_patients) for _ in 1:pop_size]
end

function init_bitstring(individual_size::Integer, pop_size::Integer)
    return [bitrand(Xoshiro(), num_bits) for _ in 1:pop_size]
end

end