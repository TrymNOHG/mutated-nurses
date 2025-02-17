
module Pipeline

export VectorFunction, run_pipeline

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

function train(population::Vector{T}, pipeline::Vararg{VectorFunction{Vector{T}}}, generations::Integer)
    gen = 0

    log_uuid = string(uuid1())
    output_file = config.history_dir * log_uuid * ".csv"
    # best_individual = Stats(BitVector(), 0.0)

    while gen < generations
        population = run_pipeline(population)
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