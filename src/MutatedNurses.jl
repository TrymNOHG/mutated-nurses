module MutatedNurses

include("models/Config.jl")

include("Pipeline.jl")
using .Pipeline

include("operations/PermutationMutation.jl")
using .PermutationMutation

include("operations/ParentSelection.jl")
using .ParentSelection

include("operations/Population.jl")
using .Population


sga_pipeline = [
    # VectorFunction{Vector{Vector{Int}}}(step_in_ea) # Parent Selection

]

config = Config(
    genotype_size=10,    
    pop_size=1000, 
    num_gen=50, 
    cross_rate=0.1, 
    mutate_rate=0.01, 
    history_dir="./src/logs/kp/"
)

train(
    pop_init=init_permutation,
    config=config,
    pipeline=sga_pipeline
)


end