module Population

import Random.Xoshiro

export init_permutation, init_bitstring

# Function to initialize different encodings such as bitstring, permutation, etc.

function init_permutation(individual_size::Integer, pop_size::Integer)
    return [randperm!(Xoshiro(), individual_size) for _ in 1:pop_size]
end

function init_bitstring(individual_size::Integer, pop_size::Integer)
    return [bitrand(Xoshiro(), num_bits) for _ in 1:pop_size]
end

end