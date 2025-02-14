
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

end