include("Gene.jl")
mutable struct Population
    pop_id::Int                             # ID of pop, important for island model
    gene_length::Int                        # Equal to number of clients
    genes::Vector{Gene}                     # Contains all the individuals in the population
    fitness_array::Vector{Float32}          # Contains fitness of each individual 
    best_feasible::Int                      # Id in genes of best feasible solution
    feas_genes::Vector{Vector{Int}}         # Array of feasible individuals
    infeas_genes::Vector{Vector{Int}}       # Array of infeasible individuals
    mu::Int                                 # mu is the max number of solutions in one generations
    lambda::Int                             # lambda is the max number of offsprings which can be created before selection for next generation begins
    log_dir::String                         # Log directory
end