
module Pipeline

include("models/Config.jl")


export VectorFunction, train, run_pipeline

struct VectorFunction{T}
    f::Function
end

function (vec_func::VectorFunction{Vector{T}})(v::Vector{T})::Vector{T} where {T}
    """
    This callable struct is used to enforce homogenous io datatype.
    """
    result = vec_func.f(v)
    @assert result isa Vector{T} "Function's from the pipeline must return the same datatype."
    return result
end

function run_pipeline(population::Vector{T}, pipeline::Vararg{VectorFunction{Vector{T}}}) where {T}  #Assumes that the function outputs the new vector of genotypes
    """
    This method creates the general pipeline.
    """
    for func in pipeline
        population = func(population)
    end
    return population
end

function run_pipeline(population::Vector{T}, pipeline::Vector{VectorFunction{Vector{T}}}) where {T}  #Assumes that the function outputs the new vector of genotypes
    """
    This method creates the general pipeline.
    """
    for func in pipeline
        population = func(population)
    end
    return population
end

function train(; pop_init::Function, pipeline::Vector{VectorFunction{Vector{T}}}, config) where {T}
    gen = 0
    population = pop_init(config.genotype_size, config.pop_size)

    log_uuid = string(uuid1())
    output_file = config.history_dir * log_uuid * ".csv"
    # best_individual = Stats(BitVector(), 0.0)

    while gen < config.num_gen
        population = run_pipeline(population, pipeline)
        gen += 1
    end

    # println(best_individual)
    
    # df = CSV.read(output_file, DataFrame)
    # for name in names(df)
    #     plot!(df[!, name], label=name)
    # end
    # savefig(config.history_dir * log_uuid  * "-graph.png")

end

end