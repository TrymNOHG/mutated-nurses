using Base

@kwdef struct Config
    genotype_size::Integer
    pop_size::Integer
    num_gen::Integer
    cross_rate::Float16
    mutate_rate::Float16
    history_dir::String
end