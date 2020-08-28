using Configs
using Test

@testset "Environment" begin
    @info "Verify that ENV has been copied to a dictionary"
    @test Configs.config_env isa Dict
    @info "Confirm that the default conf directory is pointing to ./conf in <project root>"
    defaultpath = joinpath(pwd(), "../conf") |> normpath
    @test defaultpath === Configs.config_directory

end
@testset "Files" begin

end
