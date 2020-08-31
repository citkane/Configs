using Configs
using Test

@testset "Unit tests" begin
    include("./unit.jl")
end
@testset "Functional tests" begin
    include("./functional.jl")
end


