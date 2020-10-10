using Test, Configs
ENV["DEPLOYMENT"] = "sTaGiNg"
ENV["DATABASE_PASSWORD"] = "supersecret"
@testset "Unit tests" begin
    include("./unit.jl")
end
@testset "Functional tests" begin
    include("./functional.jl")
end