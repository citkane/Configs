using Configs
using Test
defaultpath = "configs"
defaultkey = "DEPLOYMENT"
customdir = "customconfigs"
customkey = "CUSTOM"

@testset "Unit tests" begin
    include("./unit.jl")
end
@testset "Functional tests" begin
    include("./functional.jl")
end


