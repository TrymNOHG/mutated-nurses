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
include("operations/LocalSearch.jl")
using .LocalSearch
using DataFrames, BenchmarkTools, Statistics, Serialization
init_mu = 25
init_lambda = 40
max_iter = 100


# Code to cache training files  
filepath = "train/train_1.json"
save_path = "ser_train/serialized_data_test_1.bin"
@time extract_nurse_data(filepath, save_path)


load_path = "ser_train/serialized_data_test_1.bin"
depot, patients, tt_tuple, n_col = load_data(load_path)
const TT_TUPLE = tt_tuple  # Make global constant
const N_COL = n_col        # for type stability
@inline function time_matrix(i::Int, j::Int)
    @inbounds TT_TUPLE[(i-1)*N_COL + j]
    TT_TUPLE[(i-1)*N_COL + j]
end

function delete_at_indices!(arr::AbstractVector, indices_to_delete::AbstractVector{Int})
    # Sort the indices in reverse order to avoid index shifting issues
    sorted_indices = sort(indices_to_delete, rev=true)

    # Delete elements at the specified indices
    for index in sorted_indices
        deleteat!(arr, index)
    end

    return arr
end


# Main Evo Alg Loop

# Note, when you update penalties, update the fitness of all solutions.

nbClose = 3
nbElite = 8
penaltyCapacity::Float32 = penaltyCap4Split(tt_tuple, patients)
penaltyDuration = 1
penaltyTW = 1
tau = 40
gamma_wt = .2
gamma_tw = 1
global all_child = Vector{Gene}()
fitness_gen = Vector{Float32}()
global no_feasible = 0
gen_iter = 1
for gen_iter in 1:max_iter
# while no_feasible < 1
    global all_child = Vector{Gene}()
    if gen_iter == 1
        global genetic_pool = pop_init(init_mu, init_lambda, n_col-1, depot, patients,penaltyCapacity,penaltyDuration,penaltyTW,nbClose,nbElite, calc_biased_fitness, time_matrix)
        curr_pop_size = length(genetic_pool.genes)
        for sample in 1:curr_pop_size
            curr_gene = genetic_pool.genes[sample]
            is_feasible = check_feasible(curr_gene, patients, depot, time_matrix)
            if is_feasible == 0
                push!(genetic_pool.feas_genes, sample)
            else
                push!(genetic_pool.infeas_genes, sample)
            end
        end
    end
    for child_nb in 1:genetic_pool.lambda
        is_unique = false
        while is_unique == false
            parent_1, parent_2 = binary_tournament(genetic_pool)
            p1_seq = genetic_pool.genes[parent_1].sequence
            p2_seq = genetic_pool.genes[parent_2].sequence
            child_gene_seq = o1cross(p1_seq, p2_seq)
            child_gene = Gene(
                child_gene_seq,               # sequence
                0.0,                         # fitness
                Vector{Vector{Int}}(),       # gene_r
                zeros(Int, n_col-1),    # sum_load
                Vector{Int}()         
            )
            child_gene.fitness = -Inf
            child_gene.gene_r = [Vector{Int}() for _ in 1:depot.num_nurses]
            for (x,pat_id) in enumerate(child_gene.sequence)
                x == 1 ? child_gene.sum_load[x] = patients[pat_id].demand : child_gene.sum_load[x] = child_gene.sum_load[x-1] + patients[pat_id].demand
            end
            fitnes_rec = 0
            fitnes_rec = splitbellman(child_gene, depot, patients, genetic_pool.gene_length, penaltyCapacity, depot.return_time, penaltyDuration, penaltyTW, time_matrix)
            for (route_itr, route) in enumerate(child_gene.gene_r)
                if (route in genetic_pool.genes[parent_1].gene_r) || (route in genetic_pool.genes[parent_2].gene_r)
                    continue
                else
                    push!(child_gene.new_routes,route_itr)
                end
            end

            local_search!(child_gene, depot, patients, penaltyDuration, penaltyCapacity, penaltyTW, tau, gamma_wt, gamma_tw, time_matrix)
            filter!(x -> !isempty(x), child_gene.gene_r)
            unique_child = true
            for i in genetic_pool.genes
                if unique_child == false
                    break
                end
                if child_gene.gene_r == i.gene_r
                    unique_child = false
                end
            end
            for i in all_child
                if unique_child == false
                    break
                end
                if child_gene.gene_r == i.gene_r
                    unique_child = false
                end
            end
            if unique_child
                push!(all_child, child_gene)
                is_unique = true
            end
        end
    end
    for (idx,child) in enumerate(all_child)
        push!(genetic_pool.genes, child)
        push!(genetic_pool.fitness_array, child.fitness)
    end

    curr_pop_size = length(genetic_pool.genes)
    genetic_pool.feas_genes = Vector{Int}[]
    genetic_pool.infeas_genes = Vector{Int}[]
    for sample in 1:curr_pop_size
        curr_gene = genetic_pool.genes[sample]
        is_feasible = check_feasible(curr_gene, patients, depot, time_matrix)
        if is_feasible == 0
            push!(genetic_pool.feas_genes, sample)
        else
            push!(genetic_pool.infeas_genes, sample)
        end
    end

    genetic_pool.biased_fitness_array = fill(-Inf, length(genetic_pool.genes))
    calc_biased_fitness(genetic_pool, genetic_pool.infeas_genes, nbClose,nbElite)
    calc_biased_fitness(genetic_pool, genetic_pool.feas_genes, nbClose,nbElite)
        
    min_indicies = partialsortperm(genetic_pool.biased_fitness_array, 1:genetic_pool.lambda)
    delete_at_indices!(genetic_pool.genes, min_indicies)
    delete_at_indices!(genetic_pool.fitness_array, min_indicies)

    curr_pop_size = length(genetic_pool.genes)
    genetic_pool.feas_genes = Vector{Int}[]
    genetic_pool.infeas_genes = Vector{Int}[]
    for sample in 1:curr_pop_size
        curr_gene = genetic_pool.genes[sample]
        is_feasible = check_feasible(curr_gene, patients, depot, time_matrix)
        if is_feasible == 0
            push!(genetic_pool.feas_genes, sample)
        else
            push!(genetic_pool.infeas_genes, sample)
        end
    end

    genetic_pool.biased_fitness_array = fill(-Inf, length(genetic_pool.genes))
    calc_biased_fitness(genetic_pool, genetic_pool.infeas_genes, nbClose,nbElite)
    calc_biased_fitness(genetic_pool, genetic_pool.feas_genes, nbClose,nbElite)
    
    push!(fitness_gen, maximum(genetic_pool.fitness_array))
    println("Gen number: ", gen_iter)
    println("Feasible sol: ", genetic_pool.feas_genes)
    println("In-Feasible sol: ", (genetic_pool.infeas_genes))
    println("Max fitness: ", maximum(genetic_pool.fitness_array))
    println("-----------------")
    global no_feasible = length(genetic_pool.feas_genes)
    gen_iter += 1 
end            
# println(genetic_pool.infeas_genes)
# println(genetic_pool.feas_genes)
# println(fitness_gen)


for (idx,curr_gene) in enumerate(genetic_pool.genes)
    println("Gene: ",idx)
    println(curr_gene.fitness)
    println(curr_gene.gene_r)
    println("---------")
end