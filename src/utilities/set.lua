Set = {}
Set.mt = {}
Set.mt.__index = Set

function Set.new (t)
    local set = {}
    for _, l in ipairs(t) do set[l] = true end
    setmetatable(set, Set.mt)
    return set
end

function Set.union (a,b)
    local res = Set.new{}
    for k in pairs(a) do res[k] = true end
    for k in pairs(b) do res[k] = true end
    return res
end

function Set.intersection( a, b )
    local res = Set.new{}
    for k in pairs(a) do
        res[k] = b[k]
    end
    return res
end

function Set.contains( set, item )
    return set[ item ] == true;
end

function Set.insert( set, item )
    set[ item ] = true;
end

function Set.remove( set, item )
    set[ item ] = nil;
end

function Set.pop( set )
    for key, _ in pairs( set ) do
        set[ key ] = nil
        return key
    end
end

function Set.tostring (set)
    local s = "{"
    local sep = ""
    for e in pairs(set) do
        s = s .. sep .. e
        sep = ", "
    end
    return s .. "}"
end

function Set.print (s)
    print(Set.tostring(s))
end