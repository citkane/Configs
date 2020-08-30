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
    @test_nowarn Configs.set!("a.test.val", "test")
    testval = @test_nowarn Configs.get("a.test.val")
    @test testval === "test"
    Configs.resetconfigs!()
    @test_throws Configs.Configserror Configs.get("a.test.val")
    testval = @test_nowarn Configs.get("otherstuff.defaultmessage")
    @test testval === "Hello new user"
    Configs.resetconfigs!()

    @info "Initialise custom env"
    init = @test_nowarn Configs.init(; deployment_key=customkey, configs_directory=customdir)
    @test init.configs_directory === customdir
    @test init.deployment_key === customkey

    @info "Initialise defaults"
    init = @test_nowarn Configs.init()
    @test init.configs_directory === defaultpath
    @test init.deployment_key === defaultkey

    @info "Initialise custom ENV"
    ENV["DEPLOYMENT_KEY"] = customkey
    ENV["CONFIGS_DIRECTORY"] = customdir
    init = @test_nowarn Configs.init()
    @test init.configs_directory === customdir
    @test init.deployment_key === customkey
    Configs.deleteenvkey!("DEPLOYMENT_KEY")
    Configs.deleteenvkey!("CONFIGS_DIRECTORY")
end

@testset "Parsing" begin
    instance = Configs.init()
    @info "Has configs as a dictionary"
    @test Configs.configs isa Dict

    @info "Has parsed default files"
    @test isequal(instance.configs_order, ["default.json", "custom-environment-variables.json"])

    @info "Parses custom ENVIRONMENT files"
    ENV["DEPLOYMENT"] = "staging"
    instance = Configs.init()
    @test isequal(instance.configs_order, ["default.json", "staging.json", "custom-environment-variables.json"])
    delete!(ENV, "DEPLOYMENT")
    ENV["DEPLOYMENT_KEY"] = customkey
    ENV[customkey] = "StAgInG"
    instance = Configs.init()
    @test isequal(instance.configs_order, ["default.json", "staging.json", "custom-environment-variables.json"])
    delete!(ENV, "DEPLOYMENT_KEY")
    delete!(ENV, customkey)
end

@testset "Sets, gets and has configs" begin
    testval = "testval"
    @info "Sets and overwrites all levels"
    @test_nowarn Configs.set!("test", testval)
    @test_nowarn Configs.set!("test.branch", testval)
    @test_nowarn Configs.set!("test", testval)
    @test_nowarn Configs.set!("test2.branch.leaf", testval)

    @info "Gets custom sets"
    @test Configs.get("test") === testval
    @test Configs.get("test2.branch.leaf") === testval

    @info "Cannot set! after get"
    @test_throws Configs.Configserror Configs.set!("nogo", "error")

    @info "Loads default with no DEPLOYMENT"
    instance = Configs.init()
    @test isequal(instance.configs_order, ["default.json", "custom-environment-variables.json"])
    @test Configs.get("database.connection.url") === "http://localhost"
    @test Configs.get("database.connection.port") === 3600
    @test Configs.get("otherstuff.defaultmessage") === "Hello new user"

    @info "Merges deployment config"
    ENV["DEPLOYMENT"] = "staging"
    Configs.init()
    @test Configs.get("database.connection.url") === "https://secureserver.me/staging"
    @test Configs.get("database.connection.port") === 3601
    @test Configs.get("database.credentials.password") === ""
    @test Configs.get("otherstuff.defaultmessage") === "Hello new user"

    @info "Merges custom ENV variable"
    ENV["DATABASE_PASSWORD"] = "supersecret"
    instance = Configs.init()
    @test Configs.get("database.connection.url") === "https://secureserver.me/staging"
    @test Configs.get("database.connection.port") === 3601
    @test Configs.get("database.credentials.password") === "supersecret"
    @test Configs.get("otherstuff.defaultmessage") === "Hello new user"

    @info "Returns true false for has"
    @test Configs.has("database")
    @test Configs.has("database.connection.port")
    @test !Configs.has("notthere")
    @test !Configs.has("notthere.branch")
    @test !Configs.has("notthere.branch.leaf")
    @test !Configs.has("database.branch")
    @test !Configs.has("database.branch.leaf")
    @test !Configs.has("database.connection.leaf")
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