module MutatedNurses

include("operations/PermutationMutation.jl")
using .PermutationMutation

include("Pipeline.jl")
using .Pipeline

include("ParentSelection.jl")
using .ParentSelection

sga_pipeline = [
    VectorFunction{Vector{Vector{Int}}}(step_in_ea) # Parent Selection

]

end