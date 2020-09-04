__precompile__()

module Configs
    using JSON, YAML, Dates, Memoize
    export  getconfig,
            setconfig!,
            hasconfig,
            initconfig

    mutable struct Confstate
        init::Bool
        isimmutable::Bool
        immutable::NamedTuple
        configs::Dict{String, Any}
    end
    const state = Confstate(false, false, (;), Dict())

    include("utils.jl")

    "Initialises the config"
    function initconfig(; deployment_key = "DEPLOYMENT", configs_directory = "configs", )
        state.init = true
        conf = parseconfigs(deployment_key, configs_directory)
        len = length(conf.files)
        newtrees = asyncmap(readconffile, fill(configs_directory, len), conf.files)
        for newtree in newtrees
            override!(state.configs, newtree)
        end
    end

    function setconfig!(path::String, value::Union{Number, Bool})
        value = configpathtodict(path, value)
        setconfig!(value)
    end
    function setconfig!(path::String, value::String)
        try
            value = JSON.parse(value)
        catch err
        end
        value = configpathtodict(path, value)
        setconfig!(value)
    end
    function setconfig!(path::String, value::Union{Tuple, Array, NamedTuple, Dict})
        value = json(value) |> JSON.parse
        value = configpathtodict(path, value)
        setconfig!(value)
    end
    function setconfig!(value::Dict)
        global state
        !state.init && initconfig()
        state.isimmutable && throw(Configserror("""config is immutable. Please set all values before calling "get" """))
        override!(state.configs, value)
    end

    @memoize Dict{Tuple{String}, Any} function getconfig(path::String = "")
        !state.init && initconfig()
        !state.isimmutable && (
            state.immutable= makeimmutable(state.configs);
            state.isimmutable = true
        )
        path === "" && return state.immutable
        parseconfigpath(state.immutable, path)
    end

    @memoize Dict{Tuple{String}, Any} function hasconfig(path::String)::Bool
        path === "" && throw(Configserror("a path is required to query a config"))
        try
            getconfig(path)
            true
        catch err
            false
        end
    end
end