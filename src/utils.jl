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
tosymbol(dict::Dict) = Dict(Symbol(key) => value for (key, value) in dict)

makeimmutable(value) = value
function makeimmutable(array::Array)
    shadow = []
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
            getfiles(joinpath(pwd(), path), true)
        end
    end
end