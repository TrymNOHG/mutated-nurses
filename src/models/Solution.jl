struct Solution
    values::Vector{Int}   # This list is essentially an ordered set of patient ids.
    indices::Vector{Int} # This list contains the cut-off between different routes, essentially differentiating between nurses. Therefore, it can never be longer than 8.
end