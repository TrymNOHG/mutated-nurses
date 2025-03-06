# mutable struct Gene
#     """
#     Here 'x' would signify the xth patient. For example, if seq = [3,1,2]. Then patiend_id=3 is the 1st patient, patiend_id=1 is second and so on..
#     Therefore, as dnext[1] means distance between 1st and 2nd patient, it would be distance between patiend_id 3 and patiend_id 1.
#     Same logic follows for whereever 'x' is used.
#     """
#     sequence::Vector{Int}       # Sequence of the gene, represents an individual from population
#     fitness::Float32        # Fitness value of the Gene
#     gene_r::Vector{Vector{Int}}     # Contains the sequence splitted into routes / patient routes divided into nurses
#     d0_x::Vector{Float32}       # Array containg d0x for each patient in the sequence in respective order. d0x represents distance from deport to patient x
#     dx_0::Vector{Float32}       # Array containg dx0 for each patient in the sequence in respective order. dx0 represents distance from patient x to deport
#     dnext::Vector{Float32}      # Array containg dnext for each patient in resp order. dnext is distance of xth patient to (x+1)th paient in the gene sequence
#     sum_load::Vector{Int}       # Summation of demand till and including the xth patient in the sequence
#     sum_dist::Vector{Float32}       # Summation of dist-k,k+1 from k = 1 till k = x-1. Here dist-k,k+1 means distance to go from kth patient to k+1th patient
#     sum_service::Vector{Float32}    # # Cumulative service time from patient 1 to x
# end

mutable struct Gene
    """
    Here 'x' would signify the xth patient. For example, if seq = [3,1,2]. Then patiend_id=3 is the 1st patient, patiend_id=1 is second and so on..
    Therefore, as dnext[1] means distance between 1st and 2nd patient, it would be distance between patiend_id 3 and patiend_id 1.
    Same logic follows for whereever 'x' is used.
    """
    sequence::Vector{Int}       # Sequence of the gene, represents an individual from population
    fitness::Float32        # Fitness value of the Gene
    gene_r::Vector{Vector{Int}}     # Contains the sequence splitted into routes / patient routes divided into nurses
    sum_load::Vector{Int}       # Summation of demand till and including the xth patient in the sequence
end