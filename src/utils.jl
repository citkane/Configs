struct Configserror <:Exception
    msg::String
end

function deleteenvkey!(key::String)
    try
        delete!(ENV, key)
    catch err
    end
end

function parseenvkey(key::String, value)
    try
        return ENV[key]
    catch err
        return value
    end
end

function parsecustomenv!(tree::Dict, key::String, value)
    try
        tree[key] = ENV[value]
    catch err
        delete!(tree, key)
    end
end

function parsecustomenv!(tree::Dict)
    for (key, value) in tree
        value isa Dict ? parsecustomenv!(tree[key]) : parsecustomenv!(tree, key, value)
    end
end

tosymbol(value) = value
tosymbol(dict::Dict) = Dict(Symbol(key) => value for (key, value) in dict)

immutable(value) = value
function immutable(array::Array)
    shadow = []
    for value in array
        push!(shadow, immutable(value))
    end
    tuple(shadow...)
end

function immutable(dict::Dict)
    shadow = Dict()
    dict = tosymbol(dict)
    for (key, value) in dict
        shadow[key] = immutable(dict[key])      
    end
    (; shadow...)
end

function override!(baseconf::Dict, newconf::Dict)
    for (key, value) in newconf
        if value isa Dict
            if haskey(baseconf, key) && baseconf[key] isa Dict
                override!(baseconf[key], newconf[key])
            else
                baseconf[key] = Dict();
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
            getfiles(joinpath(pwd(), path) |> normpath, true)
        end
    end
end