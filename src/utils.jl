struct Configserror <:Exception
    msg::String
end

function deleteenvkey!(key::String)
    if haskey(ENV, key)
        delete!(ENV, key)
    end
end

function parseenvkey(key::String, value::Union{String, Number, Bool})
    haskey(ENV, key) ? ENV[key] : value
end

function parsecustomenv!(tree::Dict, key::String, value)
    haskey(ENV, value) ? (tree[key] = ENV[value]) : delete!(tree, key)
end
function parsecustomenv!(tree::Dict)
    for (key, value) in tree
        isa(value, Dict) ? parsecustomenv!(tree[key]) : parsecustomenv!(tree, key, value)
    end
end


makeimmutable(value) = value 
function makeimmutable(array::Array)
    shadow = Array{Any, 1}()
    for value in array
        push!(shadow, makeimmutable(value))
    end
    tuple(shadow...)
end
function makeimmutable(dict::Dict)
    shadow = Dict{Symbol, Any}()
    for key in keys(dict)
        shadow[Symbol(key)] = makeimmutable(dict[key])
    end
    (; shadow...)
end

function override!(baseconf::Dict, newconf::Dict)
    for (key, value) in newconf
        isa(value, Dict) && isempty(value) && continue
        !isa(value, Dict) && (baseconf[key] = value; continue)
        (!haskey(baseconf, key) || !isa(baseconf[key], Dict)) && (baseconf[key] = Dict{String, Any}())
        override!(baseconf[key], value)
    end
end

function readconffile(directory::String, file::String)::Dict{String, Any}
    filepath = joinpath(directory, file)
    splitfile = splitext(file)
    ext = splitfile[2]
    if ext === ".json"
        conf = JSON.parsefile(filepath)
    elseif ext === ".yml"
        conf = YAML.load_file(filepath)
        conf = json(conf)
        conf = JSON.parse(conf)
    elseif ext === ".jl"
        conf = include(filepath)
        conf = json(conf)
        conf = JSON.parse(conf)
    end
    filename = splitext(file)[1]
    filename === "custom-environment-variables" && parsecustomenv!(conf)
    conf
end

function getconffiles(path::String)::Array{String, 1}
    !isdir(path) && (path = joinpath(pwd(), path))
    !isdir(path) && throw(Configserror("no such config directory: " * path))
    readdir(path)
end

function parseconfigs(deployment_key::String, configs_directory::String)
    configs_order = [
        "default.json",
        "default.yml",
        "default.jl",
        "custom-environment-variables.json",
        "custom-environment-variables.yml",
        "custom-environment-variables.jl"
    ]
    configs_directory = parseenvkey("CONFIGS_DIRECTORY", configs_directory)
    deployment_key = parseenvkey("DEPLOYMENT_KEY", deployment_key)
    
    configs_hasfiles = getconffiles(configs_directory)
    configs_files = filter((file)-> file in configs_hasfiles, configs_order)
    deployment = parseenvkey(deployment_key, false)
    
    if deployment != false        
        deployment = lowercase(deployment)
        possiblefiles = [deployment*".json", deployment*".yml", deployment*".jl"]
        possiblefiles = intersect(possiblefiles, configs_hasfiles)
        length(possiblefiles) > 0 && insert!(configs_files, 2, possiblefiles[1])
    end
    (; files = configs_files, directory = configs_directory, )
end

function configpathtodict(path::String, value)::Dict{String, Any}
    path === "" && throw(Configserror("a path is required to set a config"))
    subpaths = split(path, ".")
    base = Dict{String, Any}()
    ref = base
    for i in eachindex(subpaths)
        subpath = subpaths[i]
        length(subpaths) === i && (ref[subpath] = value; return base)
        ref[subpath] = Dict{String, Any}()
        ref = ref[subpath]
    end
end

function parseconfigpath(tree::NamedTuple, path::String)   
    paths = split(path, ".")
    key = Symbol(paths[1])
    length(paths) === 1 && haskey(tree, key) && return tree[key]
    (!haskey(tree, key) || !isa(tree[key], NamedTuple)) && throw(Configserror("no such config: " * path))
    key = Symbol(popfirst!(paths))
    parseconfigpath(tree[key], join(paths, "."))
end