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

function pop_init(init_mu::Int, init_lambda::Int, seq_len::Int, depot::Depot, patients::Vector{Patient}, penaltyCapacity::Float32, penaltyDuration, penaltyTW,nbClose::Int, nbElite::Int, calc_biased_fitness, time_matrix)
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
    fill(-Inf, init_mu),  # biased_fitness_array
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
    calc_biased_fitness(genetic_pool, genetic_pool.infeas_genes,nbClose,nbElite)
    calc_biased_fitness(genetic_pool, genetic_pool.feas_genes, nbClose,nbElite)
    return genetic_pool
end

function binary_tournament(genetic_pool::Population)
    curr_pop_size = length(genetic_pool.genes)
    
    # Randomly select 4 candidate indices (allowing duplicates)
    possible_parents = rand(1:curr_pop_size, 4)
    
    # Process first pair (parents 1 and 2)
    parent_a, parent_b = possible_parents[1], possible_parents[2]
    if genetic_pool.biased_fitness_array[parent_a] <= genetic_pool.biased_fitness_array[parent_b]
        p1, not_p1 = parent_a, parent_b
    else
        p1, not_p1 = parent_b, parent_a
    end
    
    # Calculate selection probabilities for first pair
    sum_fit1 = genetic_pool.biased_fitness_array[p1] + genetic_pool.biased_fitness_array[not_p1]
    prob_p1 = sum_fit1 ≈ 0.0 ? 0.5 : (1 - (genetic_pool.biased_fitness_array[p1] / sum_fit1))
    f1 = rand() < prob_p1 ? p1 : not_p1

    # Process second pair (parents 3 and 4)
    parent_c, parent_d = possible_parents[3], possible_parents[4]
    if genetic_pool.biased_fitness_array[parent_c] >= genetic_pool.biased_fitness_array[parent_d]
        p2, not_p2 = parent_c, parent_d
    else
        p2, not_p2 = parent_d, parent_c
    end
    
    # Calculate selection probabilities for second pair
    sum_fit2 = genetic_pool.biased_fitness_array[p2] + genetic_pool.biased_fitness_array[not_p2]
    prob_p2 = sum_fit2 ≈ 0.0 ? 0.5 : (1 - (genetic_pool.biased_fitness_array[p2] / sum_fit2))
    f2 = rand() < prob_p2 ? p2 : not_p2

    return f1, f2
end

end