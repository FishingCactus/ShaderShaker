local OperatorPrecedence = {
    
    ['/'] = 1,
    ['%'] = 1,
    ['*'] = 2,
    ['+'] = 3,
    ['-'] = 3,
    ['>>'] = 4,
    ['<<'] = 4,
    ['>'] = 5,
    ['<'] = 5,
    ['>='] = 5,
    ['<='] = 5,
    ['=='] = 6,
    ['!='] = 6,
    ['&'] = 7,
    ['^'] = 8,
    ['|'] = 9,
    ['&&'] = 11,
    ['||'] = 12,
}


function GetOperatorPrecedence( operator )

    return OperatorPrecedence[ operator ] or 0

end

local function _GetNodeOfType( node, type_name )
    
    for _, child_node in ipairs( node ) do
        
        if type( child_node ) == 'table' then        
            if child_node.name == type_name then
                coroutine.yield( child_node )
            end
            
            _GetNodeOfType( child_node, type_name );
        end
        
    end
    
    
end
 
function NodeOfType( node, type_name )
    local co = coroutine.create(function () _GetNodeOfType( node, type_name ) end)
      
    return function ()   -- iterator
        local code, res = coroutine.resume(co)
        return res
    end
end

