function getenv!(tree::Dict, key::String, value)
    try
        tree[key] = ENV[value]
    catch err
        delete!(tree, key)
    end
end

function getenv!(tree::Dict)
    for (key, value) in tree
        value isa Dict ? getenv!(tree[key]) : getenv!(tree, key, value)
    end
end

function getenv(key::String, value::String)
    newvalue = Base.get(config_env, key, false)
    newvalue === false ? value : newvalue
end

function compressenv!(tree::Dict, parent::Dict, parent_key::String)
    for (key, value) in tree
        value isa Dict && compressenv!(tree[key], tree, key)
    end
    length(keys(tree)) === 0 && delete!(parent, parent_key)
end

function compressenv!(tree::Dict)
    for (key, value) in tree
        value isa Dict && compressenv!(tree[key], tree, key)
    end
end

tosymbol(value) = value
tosymbol(dict::Dict) = Dict(Symbol(key) => tosymbol(value) for (key, value) in dict)
function symboldict!(dict::Dict)
    for (key, value) in dict
        symkey = Symbol(key)
        dict[symkey] = pop!(dict, key)
        dict[symkey] = tosymbol(dict[symkey])
    end
end

immutable(value, shadow::Dict) = value
function immutable(dict::Dict, shadow::Dict = Dict())
    for (key, value) in dict
        val = immutable(dict[key], Dict())
        shadow[key] = val       
    end
    (; shadow...)
end

function getfiles(path::String, retry::Bool = false)
    try
        readdir(path)
    catch err
        if retry
            error("no such config directory: " * path)
        else
            getfiles(joinpath(pwd(), path), true)
        end
    end
end