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

@info "immutable"
immutable = @test_nowarn Configs.immutable(testobject(["one", Dict("one" => 1)]))
@test isequal(immutable, (tree = (val = ("one", (one = 1,)),),))

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

