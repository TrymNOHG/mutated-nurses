module MutatedNurses

include("operations/PermutationMutation.jl")
using .PermutationMutation

include("Pipeline.jl")
using .Pipeline

function docs_example()
    """
    This function solely serves as an example for documentation and should be removed at a later point in time.
    """
end

end