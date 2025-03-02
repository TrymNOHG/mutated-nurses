mutable struct Population
    gene_length::Integer
    genes::Vector{Vector{Integer}}       # Contains all the individuals in the population
    fitness_array::Vector{Integer}      # Contains fitness of each individual 
    feas_genes::Vector{Vector{Integer}}      # Array of feasible individuals
    infeas_genes::Vector{Vector{Integer}}        # Array of infeasible individuals
    mu::Int     # mu is the max number of solutions in one generations
    lambda::Int     # lambda is the max number of offsprings which can be created before selection for next generation begins
end