-- http://lua-users.org/wiki/CopyTable

function DeepCopy( object )
    local lookup_table = {}
    
    local function _copy( object )
        if type( object ) ~= "table" then
            return object
        elseif lookup_table[ object ] then
            return lookup_table[ object ]
        end
        
        local new_table = {}
        lookup_table[ object ] = new_table
        for index, value in pairs( object ) do
            new_table[ _copy( index ) ] = _copy( value )
        end
        
        return setmetatable( new_table, _copy( getmetatable(object) ) )
    end
    
    return _copy( object )
end