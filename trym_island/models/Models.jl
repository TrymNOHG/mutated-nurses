module Models

include("Patient.jl")
include("Depot.jl")
include("Gene.jl")
include("Population.jl")

const ModelPop = Models.Population
export Patient, Depot, Gene, ModelPop

end