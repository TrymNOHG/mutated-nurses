include("Gene.jl")
mutable struct Population
    gene_length::Int        # Equal to number of clients
    genes::Vector{Gene}       # Contains all the individuals in the population
    fitness_array::Vector{Float32}      # Contains fitness of each individual
    biased_fitness_array::Vector{Float32}      # Contains fitness of each individual 
    feas_genes::Vector{Int}      # Array of feasible individuals
    infeas_genes::Vector{Int}       # Array of infeasible individuals
    mu::Int     # mu is the max number of solutions in one generations
    lambda::Int     # lambda is the max number of offsprings which can be created before selection for next generation begins
end