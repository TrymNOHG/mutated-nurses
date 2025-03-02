module crossovers

using ..Models: Patient, Depot, Gene 
using StatsBase: sample
using Random

export o1cross

function o1cross(a::Vector{Int}, b::Vector{Int}; rng=Random.GLOBAL_RNG)
    # NOTE: Slow
    indices = sample(rng, 2:length(a)-1, 2, replace=false, ordered=true)
    # Selected part from `a`
    chosen = a[indices[1]:indices[2]]
    # Values not copied from `a`
    rem_vals = vcat(a[begin:indices[1]-1], a[indices[2]+1:end])

    # Using the same order as in `b`, copy those values in rem_vals
    r = [v for v in vcat(b[indices[2]+1:end], b[begin:indices[2]]) if v in rem_vals]

    # Break down into slices
    s2 = r[begin:length(a)-indices[2]]
    s1 = r[length(s2)+1:end]

    # Returned individual is a concatenation of the slices and selected part from `a`
    return vcat(s1, chosen, s2)
end



end