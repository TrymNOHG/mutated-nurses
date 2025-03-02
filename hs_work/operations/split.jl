# module split

# include("../models/Patient.jl")
# include("../models/Depot.jl")
# include("../models/Gene.jl")
# include("../data_structs/Dequeue.jl")
# import .Dequeue

# export split2routes

module split

using ..Models: Patient, Depot, Gene  # Access types from parent scope
include("../data_structs/Dequeue.jl")
import .Dequeue

export split2routes

function split2routes(gene::Gene, depot::Depot, nbPatients::Int, penaltyCap::Float32)
    potential = fill(1.e30, depot.num_nurses, nbPatients)
    pred = fill(0, depot.num_nurses, nbPatients)
    queue = Dequeue.TrivialDeque(nbPatients + 1, 1)
    MY_EPSILON::Float32 = 0.00001

    # Initialize for k=1: cost of one nurse serving first i patients
    for i in 1:nbPatients
        load = gene.sum_load[i]
        violation = max(load - depot.nurse_cap, 0.0)
        potential[1, i] = gene.d0_x[1] + gene.sum_dist[i] + gene.dx_0[i] + penaltyCap * violation
        pred[1, i] = 0  # No predecessor; starts from depot
    end

    # Adjusted propagate: use k-1 for k > 1
    @inline function propagate(p::Int, j::Int, k::Int)
        if k == 1 && p == 0
            # Shouldn’t reach here with new initialization, but kept for clarity
            return gene.d0_x[1] + gene.sum_dist[j] + gene.dx_0[j] + penaltyCap * max(gene.sum_load[j] - depot.nurse_cap, 0.0)
        else
            return potential[k-1, p] + gene.d0_x[p+1] + (gene.sum_dist[j] - gene.sum_dist[p+1]) + gene.dx_0[j] + penaltyCap * max(gene.sum_load[j] - gene.sum_load[p] - depot.nurse_cap, 0.0)
        end
    end

    @inline function dominates(p::Int, j::Int, k::Int)
        # Use k-1 and correct penalty to violation
        load_violation = max(gene.sum_load[j] - gene.sum_load[p] - depot.nurse_cap, 0.0)
        return (potential[k-1, j] + gene.d0_x[j+1]) > (potential[k-1, p] + gene.d0_x[p+1] + (gene.sum_dist[j+1] - gene.sum_dist[p+1]) + penaltyCap * load_violation)
    end

    @inline function dominatesRight(p::Int, j::Int, k::Int)
        load_violation = max(gene.sum_load[j] - gene.sum_load[p] - depot.nurse_cap, 0.0)
        return potential[k-1, j] + gene.d0_x[j+1] < potential[k-1, p] + gene.d0_x[p+1] + (gene.sum_dist[j+1] - gene.sum_dist[p+1]) + penaltyCap * load_violation + MY_EPSILON
    end

    # Main loop starting from k=2
    for k in 2:depot.num_nurses
        Dequeue.reset!(queue, k-1)  # Start with p = k-1
        Dequeue.push_back!(queue, k-1)  # Ensure queue isn’t empty
        for i in k:nbPatients
            if Dequeue.size(queue) < 1
                break
            end
            p = Dequeue.get_front(queue)
            potential[k, i] = propagate(p, i, k)
            pred[k, i] = p

            if i < nbPatients
                if !dominates(Dequeue.get_back(queue), i, k)
                    while Dequeue.size(queue) > 0 && dominatesRight(Dequeue.get_back(queue), i, k)
                        Dequeue.pop_back!(queue)
                    end
                    Dequeue.push_back!(queue, i)
                end
                while Dequeue.size(queue) > 1 && propagate(Dequeue.get_front(queue), i+1, k) > propagate(Dequeue.get_next_front(queue), i+1, k) - MY_EPSILON
                    Dequeue.pop_front!(queue)
                end
            end
        end
    end

    if potential[depot.num_nurses, nbPatients] > 1.e29
        throw("ERROR : no Split solution has been propagated until the last node")
    end

    minCost::Float32 = potential[depot.num_nurses, nbPatients]
    nbRoutes::Int = depot.num_nurses
    for k in 1:depot.num_nurses
        if potential[k, nbPatients] < minCost
            minCost = potential[k, nbPatients]
            nbRoutes = k
        end
    end

    # Reconstruct routes
    e = nbPatients
    for k in nbRoutes:-1:1
        b = pred[k, e]
        for ii in (b+1):e  # b+1 because b is last patient of previous route
            push!(gene.gene_r[k], gene.sequence[ii])
        end
        e = b
    end
    gene.fitness = -minCost

    return gene.fitness
end
end