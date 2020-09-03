using Test, Configs

# @show initconfig()
#=
@btime setconfig!("otherstuff.defaultmessage.number", 100.0)

@btime setconfig!("otherstuff.defaultmessage.number1", 100)

@btime setconfig!("otherstuff.defaultmessage.array", [1,2,3])

@btime setconfig!("otherstuff.defaultmessage.text", "test")

@btime setconfig!("otherstuff.defaultmessage.text1", """{
    "test": {
        "newpath": "test",
        "newarray": ["one", 1] 
    }
}""")
@show getconfig("otherstuff.defaultmessage.number")
@show getconfig("otherstuff.defaultmessage.number1")
@show getconfig("otherstuff.defaultmessage.array")
@show getconfig("otherstuff.defaultmessage.text")
@show getconfig("otherstuff.defaultmessage.text1")
=#

@testset "Unit tests" begin
    include("./unit.jl")
end
@testset "Functional tests" begin
    include("./functional.jl")
end

@test_nowarn Configs.benchmark()