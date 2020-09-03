testobject(val) = Dict("tree" => Dict(
    "val" => val
))

@info "deleteenvkey!"
@test !haskey(ENV, "FOOTEST")
@test_nowarn Configs.deleteenvkey!("FOOTEST")
ENV["FOOTEST"] = "foo"
@test_nowarn Configs.deleteenvkey!("FOOTEST")
@test !haskey(ENV, "FOOTEST")

@info "parseenvkey"
@test Configs.parseenvkey("FOOTEST", "nope") === "nope"
ENV["FOOTEST"] = "yep"
@test Configs.parseenvkey("FOOTEST", "nope") === "yep"
Configs.deleteenvkey!("FOOTEST")

@info "parsecustomenv!"
foo = testobject("FOOTEST")
@test_nowarn Configs.parsecustomenv!(foo)
@test isequal(foo, Dict("tree" => Dict()))
foo = testobject("FOOTEST")
ENV["FOOTEST"] = "yep"
@test_nowarn Configs.parsecustomenv!(foo)
@test isequal(foo, testobject("yep"))
Configs.deleteenvkey!("FOOTEST")

@info "makeimmutable"
isimmutable = @test_nowarn Configs.makeimmutable(testobject(["one", Dict("one" => 1)]))
@test isequal(isimmutable, (tree = (val = ("one", (one = 1,)),),))

@info "override!"
base = Dict()
add = testobject("test")
@test_nowarn Configs.override!(base, add)
@test isequal(base, add)
add = Dict("foo" => ["one", "two"], "bar" => 2, "tree" => Dict("added" => 2))
@test_nowarn Configs.override!(base, add)
@test isequal(base, Dict{Any,Any}("bar" => 2,"tree" => Dict{Any,Any}("val" => "test","added" => 2),"foo" => ["one", "two"]))

@info "getfiles"
@test_throws Configs.Configserror Configs.getfiles("foobar")
@test_nowarn Configs.getfiles("configs")
@test_nowarn Configs.getfiles(joinpath(pwd(), "configs"))

@info "readconffile"
@test_nowarn Configs.readconffile(joinpath(pwd(), "configs"), "default.yml")
file = Configs.readconffile(joinpath(pwd(), "configs"), "default.yml")
@test file isa Dict
@test file["database"]["connection"]["port"] === 3600

@info "parseconfigs"
@test_nowarn Configs.parseconfigs("dev", "configs")
@test_throws Configs.Configserror Configs.parseconfigs("dev", "badconfigs")
ENV["DEPLOYMENT"] = "sTaGiNg"
conf = Configs.parseconfigs("DEPLOYMENT", "configs")
@test isequal(conf.order, ["default.yml", "staging.jl", "custom-environment-variables.json"])

@info "pathtodict"
@test_nowarn Configs.pathtodict("one,two.three", "test")
dict = Configs.pathtodict("one.two.three", "test")
@test dict isa Dict{String, Any}
@test dict["one"]["two"]["three"] === "test"

@info "parseconfigpath"
testtuple = (; one=(; two = "test"))
@test_nowarn Configs.parseconfigpath(testtuple, "one.two")
@test_throws Configs.Configserror Configs.parseconfigpath(testtuple, "one.two.foo")
@test Configs.parseconfigpath(testtuple, "one.two") === "test"

