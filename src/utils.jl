struct Configserror <:Exception
    msg::String
end

function deleteenvkey!(key::String)
    if haskey(ENV, key)
        delete!(ENV, key)
    end
end

function parseenvkey(key::String, value)
    haskey(ENV, key) ? ENV[key] : value
end

function parsecustomenv!(tree::Dict, key::String, value)
    haskey(ENV, value) ? (tree[key] = ENV[value]) : delete!(tree, key)
end

@memoize Dict{Tuple{Dict}, Nothing} function parsecustomenv!(tree::Dict)
    for (key, value) in tree
        value isa Dict ? parsecustomenv!(tree[key]) : parsecustomenv!(tree, key, value)
    end
end


makeimmutable(value) = value 
@memoize function makeimmutable(array::Array)
    shadow = Array{Any, 1}()
    for value in array
        push!(shadow, makeimmutable(value))
    end
    tuple(shadow...)
end
@memoize function makeimmutable(dict::Dict)
    shadow = Dict{Symbol, Any}()
    for key in keys(dict)
        shadow[Symbol(key)] = makeimmutable(dict[key])
    end
    (; shadow...)
end

@memoize Dict{Tuple{Dict{String,Any}, Dict{String,Any}}, Nothing} function override!(baseconf::Dict, newconf::Dict)
    for (key, value) in newconf
        if value isa Dict
            if haskey(baseconf, key) && baseconf[key] isa Dict
                override!(baseconf[key], newconf[key])
            else
                baseconf[key] = Dict{String, Any}();
                override!(baseconf[key], newconf[key])
            end
        else
            baseconf[key] = value
        end
    end
end

function getfiles(path::String, retry::Bool = false)
    try
        readdir(path)
    catch err
        if retry
            throw(Configserror("no such config directory: " * path))
        else
            getfiles(joinpath(pwd(), path), true)
        end
    end
end
function readconffile(directory::String, file::String)
    filepath = joinpath(directory, file)
    splitfile = splitext(file)
    if splitfile[2] === ".json"
        open(filepath, "r") do filecontent
            conf = String(read(filecontent))
            return JSON.parse(conf)
        end
    elseif splitfile[2] === ".yml"
        conf = YAML.load_file(filepath)
        conf = json(conf)
        return JSON.parse(conf)
    elseif splitfile[2] === ".jl"
        conf = include(filepath)
        conf = json(conf)
        return JSON.parse(conf)
    end
end

function parseconfigs(deployment_key::String, configs_directory::String)::NamedTuple
    configs_order = copy(configs_defaultorder)
    configs_directory = parseenvkey("CONFIGS_DIRECTORY", configs_directory)
    deployment_key = parseenvkey("DEPLOYMENT_KEY", deployment_key)
    configs_files = getfiles(configs_directory)
    deployment = parseenvkey(deployment_key, false)
    filter!((file)-> file in configs_files, configs_order)
    if deployment != false
        deployment = lowercase(deployment)
        for ext in [".json", ".yml", ".jl"]
            filename = deployment*ext
            filename in configs_files && (insert!(configs_order, 2, filename); break)
        end
    end
    (; order = configs_order, directory = configs_directory, )
end

@memoize Dict{Tuple{String, Any}, Dict{String, Any}} function pathtodict(path::String, value)::Dict{String, Any}
    path === "" && throw(Configserror("a path is required to set a config"))
    subpaths = split(path, ".")
    base = Dict{String, Any}()
    ref = base
    for i in eachindex(subpaths)
        subpath = subpaths[i]
        if length(subpaths) === i
            ref[subpath] = value
            return base
        else
            ref[subpath] = Dict{String, Any}()
        end
        ref = ref[subpath]
    end
end

@memoize Dict{Tuple{NamedTuple, String}, Any} function parseconfigpath(tree::NamedTuple, path::String)
    try
        paths = split(path, ".")
        length(paths) === 1 && return tree[Symbol(paths[1])]
        key = popfirst!(paths)
        parseconfigpath(tree[Symbol(key)], join(paths, "."))
    catch err
        throw(Configserror("no such config: " * path))
    end
end