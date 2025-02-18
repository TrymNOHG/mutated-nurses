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


include("../src/operations/ParentSelection.jl")
using .ParentSelection

include("../src/utils/NurseReader.jl")
using .NurseReader


@testset "NurseFitnessEasy" begin
    individual = Vector{Int}([0])  # Nurse 0 goes from depot to patient 1 and then back to depot
    depot, patients, travel_time_table = extract_nurse_data("./train/train_0.json")
    expected_fitness = travel_time_table[1][2] + travel_time_table[2][1]
    actual_fitness = nurse_fitness(individual, travel_time_table)
    @test nurse_fitness(individual, travel_time_table) == expected_fitness
end

@testset "NurseFitnessMedium" begin
    individual = Vector{Int}([0, 1])  # Nurse 0 goes from depot to patient 1 and then back to depot
    depot, patients, travel_time_table = extract_nurse_data("./train/train_0.json")
    expected_fitness = travel_time_table[1][2] + travel_time_table[2][3] + travel_time_table[3][1]
    actual_fitness = nurse_fitness(individual, travel_time_table)
    @test nurse_fitness(individual, travel_time_table) == expected_fitness
end