using Test

ArithmeticSum(a₁,Δ,n) = return (n+1)*(a₁ + (a₁+n*Δ))/2

SlowSum(a₁,Δ,n) = sum([a₁+Δ*i for i ∈ 0:n])

@testset "ArithmeticSum" begin
    @test ArithmeticSum(1,1,14) == SlowSum(1,1,14)
    @test ArithmeticSum(5,1,10) == SlowSum(5,1,10)
    @test ArithmeticSum(2,3,14) == SlowSum(2,3,14)
end