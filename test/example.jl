using Test
using CSV

ArithmeticSum(a₁,Δ,n) = return (n+1)*(a₁ + (a₁+n*Δ))/2

SlowSum(a₁,Δ,n) = sum([a₁+Δ*i for i ∈ 0:n])

@testset "ArithmeticSum" begin
    @test ArithmeticSum(1,1,14) == SlowSum(1,1,14)
    @test ArithmeticSum(5,1,10) == SlowSum(5,1,10)
    @test ArithmeticSum(2,3,14) == SlowSum(2,3,14)
end

include("../src/Pipeline.jl")
using .Pipeline

@testset "GenericPipeline" begin
    individual = Vector{Int}([1])  
    population = Vector{Vector{Int}}([individual])
    function step_in_ea(pop::Vector{Vector{Int}})
        pop!(pop)
        result = pop
        return result
    end
    step_1 = VectorFunction{Vector{Vector{Int}}}(step_in_ea)
    @test run_pipeline(population, step_1) == Vector{Vector{Int}}([])
end

include("../src/models/Solution.jl")

include("../src/operations/ParentSelection.jl")
using .ParentSelection

include("../src/operations/Recombination.jl")
using .Recombination

include("../src/operations/Population.jl")
using .Population

include("../src/utils/NurseReader.jl")
using .NurseReader


@testset "NurseFitnessEasy" begin
    route = Vector{Int}([1])  # Depot to Patient 1 to Depot
    individual = Vector{Vector{Int}}([route])
    depot, patients, travel_time_table = extract_nurse_data("./train/train_0.json")
    expected_fitness = travel_time_table[1][2] + travel_time_table[2][1]
    actual_fitness = simple_nurse_fitness(individual, travel_time_table)
    @test actual_fitness == expected_fitness
end

@testset "NurseFitnessMedium" begin
    route = Vector{Int}([1, 2])  # Depot to Patient 1 to Patient 2 to Depot
    individual = Vector{Vector{Int}}([route])
    depot, patients, travel_time_table = extract_nurse_data("./train/train_0.json")
    expected_fitness = travel_time_table[1][2] + travel_time_table[2][3] + travel_time_table[3][1]
    actual_fitness = simple_nurse_fitness(individual, travel_time_table)
    @test actual_fitness == expected_fitness
end

# @testset "RepairRoute" begin
#     route = Vector{Int}([1])  # Depot to Patient 1 to Depot
#     individual = Vector{Vector{Int}}([route])
#     depot, patients, travel_time_table = extract_nurse_data("./train/train_0.json")
#     repair!(individual, patients, travel_time_table)
# end

@testset "OneOrderCrossover" begin
    individual_1 = Solution([1,2,3,4,5,6,7,8,9], [5])
    individual_2 = Solution([9,3,7,8,2,6,5,1,4], [3])
    survivors = []
    order_1_crossover!(individual_1, individual_2, survivors, 9)
    @test survivors[1].values == [3,8,2,4,5,6,7,1,9]
    @test survivors[1].indices == [5]
end