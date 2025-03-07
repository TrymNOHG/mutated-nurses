module EAprogress

using ..Models
using Random
using ..Split

export penaltyCap4Split, pop_init, binary_tournament

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

function pop_init(init_mu::Int, init_lambda::Int, seq_len::Int, depot::Depot, patients::Vector{Patient}, penaltyCapacity::Float32, penaltyDuration, penaltyTW, time_matrix)
    genetic_pool = Population(
    seq_len,  # gene_length = number of patients
    [Gene(
            Vector{Int}(), 
            0.0, 
            Vector{Vector{Int}}(), 
            zeros(Int, seq_len), 
            Vector{Int}()  
        ) for _ in 1:init_mu],
    fill(-Inf, init_mu),  # fitness_array
    Vector{Int}[],  # feas_genes
    Vector{Vector{Int}}[],  # infeas_genes
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
            x == 1 ? curr_gene.sum_load[x] = patients[pat_id].demand : curr_gene.sum_load[x] = curr_gene.sum_load[x-1] + patients[pat_id].demand
        end
    end

    for (iter,curr_gene) in enumerate(genetic_pool.genes)
        fitnes_rec = 0
        # fitnes_rec = split2routes(curr_gene, depot, genetic_pool.gene_length, penaltyCapacity)
        fitnes_rec = splitbellman(curr_gene, depot, patients, genetic_pool.gene_length, penaltyCapacity, depot.return_time, penaltyDuration, penaltyTW, time_matrix)
        genetic_pool.fitness_array[iter] = fitnes_rec
        # break
    end

    return genetic_pool
end

function binary_tournament(genetic_pool::Population)
    curr_pop_size = length(genetic_pool.genes)
    possible_parents = Vector{Int}()
    p1::Int = -1
    p2::Int = -1
    for i in 1:4
        poss_par = rand(1:curr_pop_size)
        push!(possible_parents, poss_par)
    end
    genetic_pool.fitness_array[possible_parents[1]] >= genetic_pool.fitness_array[possible_parents[2]] ? p1 = possible_parents[1] : p1 = possible_parents[2]
    genetic_pool.fitness_array[possible_parents[3]] >= genetic_pool.fitness_array[possible_parents[4]] ? p2 = possible_parents[3] : p2 = possible_parents[4]
    return p1, p2
end

end