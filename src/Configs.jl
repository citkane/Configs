__precompile__()

module Configs
    using JSON, YAML, Dates, Memoize, BenchmarkTools
    export  getconfig,
            setconfig!,
            hasconfig,
            initconfig

    const configs_defaultorder = [
        "default.json",
        "default.yml",
        "default.jl",
        "custom-environment-variables.json",
        "custom-environment-variables.yml",
        "custom-environment-variables.jl"
    ]
    const configs = Dict{String, Any}()
    const state = Dict{Symbol, Union{Bool, Dict{String, Any}, NamedTuple}}(
        :init => false,
        :isimmutable => false,
        :immutable => false,
        :configs => configs
    )
    include("utils.jl")
    include("benchmark.jl")
#@memoize Dict{Tuple{String,String}, Nothing} 
    function initconfig(; deployment_key = "DEPLOYMENT", configs_directory = "configs", )
        global state
        state[:init] = true
        conf = parseconfigs(deployment_key, configs_directory)
        for file in conf.order
            newtree = readconffile(conf.directory, file)
            filename = splitext(file)[1]
            filename === "custom-environment-variables" && parsecustomenv!(newtree)
            override!(state[:configs], newtree)
        end
    end



    function setconfig!(path::String, value::Union{Number, Bool})
        value = pathtodict(path, value)
        setconfig!(value)
    end
    function setconfig!(path::String, value::String)
        try
            value = JSON.parse(value)
        catch err
        end
        value = pathtodict(path, value)
        setconfig!(value)
    end
    function setconfig!(path::String, value::Union{Tuple, Array, NamedTuple, Dict})
        value = json(value) |> JSON.parse
        value = pathtodict(path, value)
        setconfig!(value)
    end
    function setconfig!(value::Dict)
        global state
        !state[:init] && initconfig()
        state[:isimmutable] && throw(Configserror("""config is immutable. Please set all values before calling "get" """))
        override!(state[:configs], value)
    end

    function getconfig(path::String = "")
        global state
        !state[:init] && initconfig()
        !state[:isimmutable] && (state[:immutable] = makeimmutable(state[:configs]); state[:isimmutable] = true)
        path === "" && return state[:immutable]
        parseconfigpath(state[:immutable], path)
    end

    function hasconfig(path::String)::Bool
        path === "" && throw(Configserror("a path is required to query a config"))
        try
            getconfig(path)
            true
        catch err
            false
        end
    end
end