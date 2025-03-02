# include("models/Gene.jl")
# include("models/Population.jl")
include("models/Models.jl")
using .Models
include("utils/NurseReader.jl")
using .NurseReader
include("operations/population_init.jl")
using .PopInit
include("operations/split.jl")
using .split
include("operations/crossover.jl")
using .crossovers

using DataFrames, BenchmarkTools, Statistics, Serialization
init_mu = 10
init_lambda = 3
maxdem = 0
# filepath = "train\\train_0.json"
# save_path = "ser_train/serialized_data_0.bin"
# @time extract_nurse_data(filepath, save_path)

depot, patients, tt_tuple, n_col = load_data("ser_train/serialized_data_0.bin")
# time_matrix = let t=tt_tuple, c=n_col
#     (i, j) -> @inbounds t[(i-1)*c + j]
# end
const TT_TUPLE = tt_tuple  # Make global constant
const N_COL = n_col        # for type stability
@inline function time_matrix(i::Int, j::Int)
    @inbounds TT_TUPLE[(i-1)*N_COL + j]
    TT_TUPLE[(i-1)*N_COL + j]
end

genetic_pool = Population(
    n_col - 1,  # gene_length = number of patients
    [Gene(
        Vector{Int}(),               # sequence
        0.0,                         # fitness
        Vector{Vector{Int}}(),       # gene_r
        zeros(Int, n_col-1),         # d0_x - use zeros() instead of Vector constructor with 0.0
        zeros(Float32, n_col-1),     # dx_0
        zeros(Float32, n_col-1),     # dnext
        zeros(Int, n_col-1),         # sum_load
        zeros(Float32, n_col-1)      # sum_dist
    ) for _ in 1:init_mu],
    fill(-Inf, init_mu),  # fitness_array
    Vector{Int}[],  # feas_genes
    Vector{Int}[],  # infeas_genes
    init_mu,
    init_lambda
)

genetic_pool.gene_length = n_col-1
all_init_genes = random_pop(genetic_pool.mu, genetic_pool.gene_length)


for (g_no, gene_seq) in enumerate(all_init_genes)
    curr_gene = genetic_pool.genes[g_no]
    curr_gene.sequence = gene_seq
    curr_gene.fitness = -Inf
    curr_gene.gene_r = [Vector{Int}() for _ in 1:depot.num_nurses]
    for (x,pat_id) in enumerate(curr_gene.sequence)
        curr_gene.d0_x[x] = time_matrix(1,pat_id)
        curr_gene.dx_0[x] = time_matrix(pat_id,1)
        x == genetic_pool.gene_length ? curr_gene.dnext[x] = -Inf : curr_gene.dnext[x] = time_matrix(pat_id, curr_gene.sequence[x+1])
        x == 1 ? curr_gene.sum_load[x] = patients[pat_id].demand : curr_gene.sum_load[x] = curr_gene.sum_load[x-1] + patients[pat_id].demand
        x == 1 ? curr_gene.sum_dist[x] = 0 : curr_gene.sum_dist[x] = curr_gene.sum_dist[x-1] + curr_gene.dnext[x-1]
    end
end


maxDist::Float32 = maximum(tt_tuple)
dem_list = Vector{Int}()
dem = 0
for pat in patients
    dem = Int(pat.demand)
    push!(dem_list, dem)
end
maxdem = maximum(dem_list)
penaltyCapacity::Float32 = max(0.1f0, min(1000.0f0, (maxDist / Float32(maxdem))))

@time for (iter,curr_gene) in enumerate(genetic_pool.genes)
    fitnes_rec = 0
    fitnes_rec = split2routes(curr_gene, depot, genetic_pool.gene_length, penaltyCapacity)
    genetic_pool.fitness_array[iter] = fitnes_rec
    # break
end
println("-----------------")
route_dem = 0
demand_violation = 0
routes_checked = 0
sum_demand = 0
final_sample_value = 0
route_list = zeros(init_mu)     # contains number of routes per gene
@time for sample in 1:init_mu
    global route_list[sample] = 0
    for (iter,route) in enumerate(genetic_pool.genes[sample].gene_r)
        if route == []
            continue
        end
        route_dem = 0
        for client_id in route
            route_dem += patients[client_id].demand
        end
        global routes_checked += 1
        route_list[sample] +=1
        global sum_demand += route_dem
        if route_dem>depot.nurse_cap
            # println("Nurs capacity violated, idx: ", iter, ". Total demand on route: ", route_dem)
            global demand_violation += 1
        end
    end
    global final_sample_value = sample
end

# println("Total Demand Violations: ", demand_violation)
# println("Total routes checked: ", routes_checked)
# println("Average demand: ", sum_demand/routes_checked)
# println("Route list: ", route_list)
# println(final_sample_value)
println(genetic_pool.fitness_array)