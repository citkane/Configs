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

function parsecustomenv!(tree::Dict)
    for (key, value) in tree
        value isa Dict ? parsecustomenv!(tree[key]) : parsecustomenv!(tree, key, value)
    end
end

tosymbol(value) = value
tosymbol(dict::Dict) = Dict{Symbol, Any}(Symbol(key) => value for (key, value) in dict)

makeimmutable(value) = value
function makeimmutable(array::Array)
    shadow = Array{Any, 1}()
    for value in array
        push!(shadow, makeimmutable(value))
    end
    tuple(shadow...)
end

function makeimmutable(dict::Dict)
    shadow = Dict()
    dict = tosymbol(dict)
    for (key, value) in dict
        shadow[key] = makeimmutable(dict[key])      
    end
    (; shadow...)
end

function override!(baseconf::Dict, newconf::Dict)
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

function pathtodict(path::String, value)::Dict{String, Any}
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