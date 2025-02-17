module MutatedNurses

include("models/Config.jl")

include("utils/NurseReader.jl")
using .NurseReader

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
    # VectorFunction{Vector{Vector{Int}}}(step_in_ea) # Recombination
    # VectorFunction{Vector{Vector{Int}}}(step_in_ea) # Mutation
    # VectorFunction{Vector{Vector{Int}}}(step_in_ea) # Survivor selection (return the children), i.e. x -> x

]

depot, patients, travel_time_table = extract_nurse_data("./train/train_0.json")

# config = Config(
#     genotype_size=10,    
#     pop_size=1000, 
#     num_gen=50, 
#     cross_rate=0.1, 
#     mutate_rate=0.01, 
#     history_dir="./src/logs/kp/"
# )

# train(
#     pop_init=init_permutation,
#     config=config,
#     pipeline=sga_pipeline
# )


end