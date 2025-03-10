# mutable struct Gene
#     """
#     Here 'x' would signify the xth patient. For example, if seq = [3,1,2]. Then patiend_id=3 is the 1st patient, patiend_id=1 is second and so on..
#     Therefore, as dnext[1] means distance between 1st and 2nd patient, it would be distance between patiend_id 3 and patiend_id 1.
#     Same logic follows for whereever 'x' is used.
#     """
#     sequence::Vector{Int}       # Sequence of the gene, represents an individual from population
#     fitness::Float32        # Fitness value of the Gene
#     gene_r::Vector{Vector{Int}}     # Contains the sequence splitted into routes / patient routes divided into nurses
#     sum_load::Vector{Int}       # Summation of demand till and including the xth patient in the sequence
# end

mutable struct Gene
    sequence::Vector{Int}        # Patient sequence
    fitness::Float32             # Fitness score
    gene_r::Vector{Vector{Int}}  # Current routes (after Split)
    sum_load::Vector{Int}        # Cumulative demand
    new_routes::Vector{Int}      # Indexes of routes modified in this generation
end