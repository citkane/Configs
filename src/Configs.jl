__precompile__()

module Configs

    using JSON
    include("utils.jl")
    export  get,
            set,
            init

    config_env = convert(Dict, ENV)
    config_dictionary = nothing
    config_order = [
        "default.json",
        "custom-environment-variables.json"
    ]

    function init(; config_key = "ENVIRONMENT", config_directory = joinpath(pwd(), "config"))
        global config_dictionary = Dict()
        config_directory = getenv("CONFIG_DIRECTORY", config_directory)
        config_key = getenv("CONFIG_KEY", config_key)
        config_files = getfiles(config_directory)
        environment = Base.get(config_env, config_key, false)
        if environment != false
            println(environment)
            insert!(config_order, 2, lowercase(environment) * ".json")
        end
        filter!((file)-> file in config_files, config_order)

        for file in config_order
            open(joinpath(config_directory, file), "r") do filepath
                file_content = String(read(filepath))
                newtree = JSON.parse(file_content)
                if file === "custom-environment-variables.json"
                    getenv!(newtree)
                end
                compressenv!(newtree)
                merge!(config_dictionary, newtree)
            end
        end
        symboldict!(config_dictionary)
    end

    function get(path::String = "")
        global config_dictionary
        config_dictionary === nothing && init()
        config_dictionary isa Dict && (config_dictionary = immutable(config_dictionary))
        path === "" && return config_dictionary
        subpaths = split(path, ".")
        ref = config_dictionary
        for subpath in subpaths
            subpath = Symbol(subpath)
            if ref isa NamedTuple && haskey(ref, subpath)
                ref = ref[subpath]
            else
                error("no such config: " * path)
            end
        end
        return ref
    end

    function set(path::String, value)
        path === "" && error("a path is required to set a config")
        config_dictionary === nothing && init()
        config_dictionary isa NamedTuple && error("""config is immutable. Please set all values before calling "get" """)
        subpaths = split(path, ".")
        ref = config_dictionary
        for i in eachindex(subpaths)
            subpath = Symbol(subpaths[i])
            length(subpaths) === i && return (ref[subpath] = value)
            !haskey(ref, subpath) && (ref[subpath] = Dict())
            ref = ref[subpath]            
        end
    end
end