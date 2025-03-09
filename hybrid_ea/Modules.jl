module Modules

include("./models/Models.jl")
include("./operations/Operations.jl")

using .Models, .Operations


export Models, Operations
export Gene, ModelPop
export init_population, calculate_cost, select_parents, tournament_select
export perform_crossover!
export EE_M!
export fitness


end