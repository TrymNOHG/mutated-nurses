module EAprogress

using ..Models
using Random
using ..Split

export penaltyCap4Split, pop_init

function penaltyCap4Split(tt_tuple::Tuple, patients::Vector{Patient})
    maxDist::Float32 = maximum(tt_tuple)
    dem_list = Vector{Int}()
    dem = 0
    for pat in patients
        dem = Int(pat.demand)
        push!(dem_list, dem)
    end
    maxdem = maximum(dem_list)
    return penaltyCapacity::Float32 = max(0.1f0, min(1000.0f0, (maxDist / Float32(maxdem))))    
end

@inline function random_pop(number_genes::Integer, gene_size::Integer)
    return [shuffle(1:gene_size) for _ in 1:number_genes]
end

function pop_init(init_mu::Int, init_lambda::Int, seq_len::Int, depot::Depot, patients::Vector{Patient}, penaltyCapacity::Float32, time_matrix)
    genetic_pool = Population(
    seq_len,  # gene_length = number of patients
    [Gene(
        Vector{Int}(),               # sequence
        0.0,                         # fitness
        Vector{Vector{Int}}(),       # gene_r
        zeros(Int, seq_len),         # d0_x - use zeros() instead of Vector constructor with 0.0
        zeros(Float32, seq_len),     # dx_0
        zeros(Float32, seq_len),     # dnext
        zeros(Int, seq_len),         # sum_load
        zeros(Float32, seq_len),     # sum_dist
        zeros(Float32, seq_len)      # sum_service
    ) for _ in 1:init_mu],
    fill(-Inf, init_mu),  # fitness_array
    Vector{Int}[],  # feas_genes
    Vector{Int}[],  # infeas_genes
    init_mu,
    init_lambda
    )
    genetic_pool.gene_length = seq_len
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
            x == 1 ? curr_gene.sum_service[x] = patients[pat_id].care_time : urr_gene.sum_service[x] = curr_gene.sum_service[x-1] + patients[pat_id].care_time
        end
    end

    for (iter,curr_gene) in enumerate(genetic_pool.genes)
        fitnes_rec = 0
        fitnes_rec = split2routes(curr_gene, depot, genetic_pool.gene_length, penaltyCapacity)
        genetic_pool.fitness_array[iter] = fitnes_rec
        # break
    end

    return genetic_pool
end

end