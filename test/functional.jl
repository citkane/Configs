@testset "Environment" begin
    
    @info "Set, get and delete ENV keys"
    ENV["CONFIGS_FOO"] = "test"
    @test Configs.parseenvkey("CONFIGS_FOO", false) === "test"
    @test ENV["CONFIGS_FOO"] === "test"
    @test_nowarn Configs.deleteenvkey!("CONFIGS_FOO")
    @test_nowarn Configs.deleteenvkey!("CONFIGS_NOTTHERE")
    @test !haskey(ENV, "CONFIGS_FOO")
    @test Configs.parseenvkey("CONFIGS_FOO", false) === false

    @info "Initialises, sets and gets"
    
    @test_nowarn initconfig(; configs_directory = normpath(joinpath(pwd(), "configs")))
    @test_throws Configs.Configserror initconfig()
    @test_nowarn setconfig!("a.test.int", 100)
    @test_nowarn setconfig!("a.test.float", 100.00)
    @test_nowarn setconfig!("a.test.true", true)
    @test_nowarn setconfig!("a.test.false", false)
    @test_nowarn setconfig!("a.test.val", "test")
    @test_nowarn setconfig!("otherstuff.defaultmessage", "test")
    @test_nowarn setconfig!("otherstuff.empty", """{
        "test": {
            "newpath": "test",
            "newarray": ["one", 1] 
        }
    }""")
    @test_nowarn setconfig!("otherstuff.tuples", (; foo = (1,2,3)))
    @test_nowarn setconfig!("otherstuff.tuples.bar", [1,2,3])
    @test_nowarn setconfig!("otherstuff.tuples.foobar", (1,2,3))
    @test_nowarn setconfig!("otherstuff.dict", Dict(:foo => "bar"))
    @test getconfig("a.test.val") === "test"
    @test getconfig("database.credentials.password") === "supersecret"
    @test getconfig("otherstuff.defaultmessage") === "test"
    @test getconfig("otherstuff.empty.test.newpath") === "test"
    @test getconfig("otherstuff.dict.foo") === "bar"
    @test isequal(getconfig("otherstuff.tuples.bar"), (1,2,3))
    @test isequal(getconfig("otherstuff.tuples.foo"), (1,2,3))
    @test isequal(getconfig("otherstuff.tuples.foobar"), (1,2,3))

    @info "Errors if no key"
    @test_throws Configs.Configserror getconfig("nogo.error")

    @info "Checks for hasconfig"
    @test !hasconfig("nogo.error")
    @test hasconfig("a.test.val")
end

@testset "imutability" begin
    @info "Cannot set after get"
    @test_throws Configs.Configserror setconfig!("nogo", "error")
    @info "The config is immutable"
    parselib(value) = (value isa Number || value isa String)
    function parselib(branch::NamedTuple)
        for value in branch
            parselib(value)
        end
    end
    function parselib(branch::Tuple)
        for value in branch
            parselib(value)
        end
    end
    parselib(Configs.state.immutable)
end