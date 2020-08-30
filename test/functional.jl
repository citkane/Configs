@testset "Environment" begin
    @info "Set, get and delete ENV keys"
    ENV["CONFIGS_FOO"] = "test"
    @test Configs.parseenvkey("CONFIGS_FOO", false) === "test"
    @test ENV["CONFIGS_FOO"] === "test"
    @test_nowarn Configs.deleteenvkey!("CONFIGS_FOO")
    @test_nowarn Configs.deleteenvkey!("CONFIGS_NOTTHERE")
    @test !haskey(ENV, "CONFIGS_FOO")
    @test Configs.parseenvkey("CONFIGS_FOO", false) === false

    @info "Initialises on set and get"
    @test_nowarn setconfig!("a.test.val", "test")
    testval = @test_nowarn getconfig("a.test.val")
    @test testval === "test"
    Configs.resetconfigs!()
    @test_throws Configs.Configserror getconfig("a.test.val")
    testval = @test_nowarn getconfig("otherstuff.defaultmessage")
    @test testval === "Hello new user"
    Configs.resetconfigs!()

    @info "Initialise custom env"
    init = @test_nowarn initconfig(; deployment_key=customkey, configs_directory=customdir)
    @test init.configs_directory === customdir
    @test init.deployment_key === customkey

    @info "Initialise defaults"
    init = @test_nowarn initconfig()
    @test init.configs_directory === defaultpath
    @test init.deployment_key === defaultkey

    @info "Initialise custom ENV"
    ENV["DEPLOYMENT_KEY"] = customkey
    ENV["CONFIGS_DIRECTORY"] = customdir
    init = @test_nowarn initconfig()
    @test init.configs_directory === customdir
    @test init.deployment_key === customkey
    Configs.deleteenvkey!("DEPLOYMENT_KEY")
    Configs.deleteenvkey!("CONFIGS_DIRECTORY")
end

@testset "Parsing" begin
    instance = initconfig()
    @info "Has configs as a dictionary"
    @test Configs.configs isa Dict

    @info "Has parsed default files"
    @test isequal(instance.configs_order, ["default.json", "custom-environment-variables.json"])

    @info "Parses custom ENVIRONMENT files"
    ENV["DEPLOYMENT"] = "staging"
    instance = initconfig()
    @test isequal(instance.configs_order, ["default.json", "staging.json", "custom-environment-variables.json"])
    delete!(ENV, "DEPLOYMENT")
    ENV["DEPLOYMENT_KEY"] = customkey
    ENV[customkey] = "StAgInG"
    instance = initconfig()
    @test isequal(instance.configs_order, ["default.json", "staging.json", "custom-environment-variables.json"])
    delete!(ENV, "DEPLOYMENT_KEY")
    delete!(ENV, customkey)
end

@testset "Sets, gets and has configs" begin
    testval = "testval"
    @info "Sets and overwrites all levels"
    @test_nowarn setconfig!("test", testval)
    @test_nowarn setconfig!("test.branch", testval)
    @test_nowarn setconfig!("test", testval)
    @test_nowarn setconfig!("test2.branch.leaf", testval)

    @info "Gets custom sets"
    @test getconfig("test") === testval
    @test getconfig("test2.branch.leaf") === testval

    @info "Cannot set! after get"
    @test_throws Configs.Configserror setconfig!("nogo", "error")

    @info "Loads default with no DEPLOYMENT"
    instance = initconfig()
    @test isequal(instance.configs_order, ["default.json", "custom-environment-variables.json"])
    @test getconfig("database.connection.url") === "http://localhost"
    @test getconfig("database.connection.port") === 3600
    @test getconfig("otherstuff.defaultmessage") === "Hello new user"

    @info "Merges deployment config"
    ENV["DEPLOYMENT"] = "staging"
    initconfig()
    @test getconfig("database.connection.url") === "https://secureserver.me/staging"
    @test getconfig("database.connection.port") === 3601
    @test getconfig("database.credentials.password") === ""
    @test getconfig("otherstuff.defaultmessage") === "Hello new user"

    @info "Merges custom ENV variable"
    ENV["DATABASE_PASSWORD"] = "supersecret"
    instance = initconfig()
    @test getconfig("database.connection.url") === "https://secureserver.me/staging"
    @test getconfig("database.connection.port") === 3601
    @test getconfig("database.credentials.password") === "supersecret"
    @test getconfig("otherstuff.defaultmessage") === "Hello new user"

    @info "Returns true false for has"
    @test hasconfig("database")
    @test hasconfig("database.connection.port")
    @test !hasconfig("notthere")
    @test !hasconfig("notthere.branch")
    @test !hasconfig("notthere.branch.leaf")
    @test !hasconfig("database.branch")
    @test !hasconfig("database.branch.leaf")
    @test !hasconfig("database.connection.leaf")
end
@testset "imutability" begin
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
    parselib(Configs.configs)
end