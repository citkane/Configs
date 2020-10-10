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
const state = Confstate(false, false, NamedTuple(), Dict())
const defaultpath = normpath(joinpath(dirname(Base.active_project()), "configs"))

"""
    initconfig(; <keyword arguments>)
Optionally override the configs environment.

Automatically called on first [`getconfig`](@ref), [`hasconfig`](@ref) or [`setconfig!`](@ref)

Can only be called once.

Alternatively, set the corresponding `ENV` variables `DEPLOYMENT_KEY` or `CONFIGS_DIRECTORY` to preference

## Arguments
- `deployment_key::String`: The `ENV` key that defines the intended deployment (eg. production, staging, etc.)  
Default: `DEPLOYMENT`
- `configs_directory::String`: The directory containing config definitions  
May be relative to project root or absolute  
Default: `configs`

"""
function initconfig(; deployment_key = "DEPLOYMENT", configs_directory = defaultpath)
    state.init && throw(Configserror("configs has already been initialised"))
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
    makeconfig!(state, value)
end
function setconfig!(path::String, value::String)
    try
        value = JSON.parse(value)
    catch err
    end
    value = configpathtodict(path, value)
    makeconfig!(state, value)
end
"""
    setconfig!(x, y)
Sets a configuration value `y` for given configuration path `x`

Can not be called after initial calls to [`getconfig`](@ref) or [`hasconfig`](@ref)
"""
function setconfig!(path::String, value::Union{Tuple, Array, NamedTuple, Dict})
    value = json(value) |> JSON.parse
    value = configpathtodict(path, value)
    makeconfig!(state, value)
end

"""
    getconfig([x])
Returns a configuration value for given configuration path x

The returned value may be absolute or a `NamedTuple`, which can be further accessed with the syntax:  
`value.x.y`

"""
@memoize Dict{Tuple{String}, Any} function getconfig(path::String = "")
    !state.init && initconfig()
    !state.isimmutable && (
        state.immutable= makeimmutable(state.configs);
        state.isimmutable = true
    )
    path === "" && return state.immutable
    parseconfigpath(state.immutable, path)
end

"""
    hasconfig(x)
Returns a `Bool` indicating if the given path `x` exists.

"""
@memoize Dict{Tuple{String}, Any} function hasconfig(path::String)::Bool
    path === "" && throw(Configserror("a path is required to query a config"))
    try
        getconfig(path)
        true
    catch err
        false
    end
end

include("utils.jl")
end