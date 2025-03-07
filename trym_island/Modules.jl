module Modules

include("./models/Models.jl")
include("./operations/Operations.jl")

using .Models, .Operations


export Models, Operations
export Gene, ModelPop
export init_populations, calculate_cost, select_parents


end