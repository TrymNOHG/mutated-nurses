include("models/Models.jl")
using .Models
include("utils/NurseReader.jl")
using .NurseReader
include("operations/Split.jl")
using .Split
include("operations/Crossover.jl")
using .Crossovers
include("utils/EAprogress.jl")
using .EAprogress
include("utils/FitnFeasible.jl")
using .FitnFeasible
using DataFrames, BenchmarkTools, Statistics, Serialization
init_mu = 10
init_lambda = 3
max_iter = 10


# Code to cache training files
filepath = "train\\train_1.json"
save_path = "ser_train/serialized_data_1.bin"
@time extract_nurse_data(filepath, save_path)

# load_path = "ser_train/serialized_data_0.bin"
# depot, patients, tt_tuple, n_col = load_data(load_path)
# const TT_TUPLE = tt_tuple  # Make global constant
# const N_COL = n_col        # for type stability
# @inline function time_matrix(i::Int, j::Int)
#     @inbounds TT_TUPLE[(i-1)*N_COL + j]
#     TT_TUPLE[(i-1)*N_COL + j]
# end

# Main Evo Alg Loop

# for gen_iter in 1:max_iter
#     penaltyCapacity::Float32 = penaltyCap4Split(tt_tuple, patients)

#     if gen_iter == 1
#         global genetic_pool = pop_init(init_mu, init_lambda, n_col-1, depot, patients,penaltyCapacity, time_matrix)
#         curr_pop_size = length(genetic_pool.genes)
#         for sample in 1:curr_pop_size
#             curr_gene = genetic_pool.genes[sample]
#             is_feasible = check_feasible(curr_gene, patients, depot)
#             if is_feasible
#                 push!(genetic_pool.feas_genes, sample)
#             else
#                 push!(genetic_pool.infeas_genes, sample)
#             end
#         end
#     end

#     for child_nb in 1:genetic_pool.lambda
#         parent_1, parent_2 = binary_tournament(genetic_pool)
#         child_gene_seq = o1cross(parent_1, parent_2)
        
#     end

# end            

