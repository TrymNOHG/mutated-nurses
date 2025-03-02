include("models/Population.jl")
include("utils/NurseReader.jl")
using .NurseReader
include("operations/population_init.jl")
using .PopInit
# include("operations/split.jl")
# using .split

using DataFrames, BenchmarkTools, Statistics, Serialization

genetic_pool = Population(
    0,      # gene_length = 0 is the size of one gene, basically equal to number of patients
    Vector{Vector{Integer}}(),  # genes
    Vector{Integer}(),          # fitness_array
    Vector{Vector{Integer}}(),  # feas_genes
    Vector{Vector{Integer}}(),  # infeas_genes
    100,                          # mu
    20                           # lambda
)

# filepath = "train\\train_0.json"
# save_path = "ser_train/serialized_data_0.bin"
# extract_nurse_data(filepath, save_path)

depot, patients, tt_tuple, n_col = load_data("ser_train/serialized_data_0.bin")
# time_matrix = let t=tt_tuple, c=n_col
#     (i, j) -> @inbounds t[(i-1)*c + j]
# end
const TT_TUPLE = tt_tuple  # Make global constant
const N_COL = n_col        # for type stability
@inline function time_matrix(i::Int, j::Int)
    @inbounds TT_TUPLE[(i-1)*N_COL + j]
end

genetic_pool.gene_length = n_col-1
genetic_pool.genes = random_pop(genetic_pool.mu, genetic_pool.gene_length)
