function WalkTree( parent_node, node_function )

	if parent_node == nil or type( parent_node ) ~= "table" then
        return
    end
    
    for child_node_index=1, #parent_node do
        local child_node = parent_node[ child_node_index ]
        WalkTree( child_node, node_function )
        node_function( child_node, parent_node, child_node_index )
    end
end

function IterateTableByKeyOrder( t, sort_function )
    local a = {}
  
    for n in pairs( t ) do 
        table.insert( a, n ) 
    end
    
    table.sort( a, sort_function )
    
    local i = 0      -- iterator variable
    local iter = function ()   -- iterator function
        i = i + 1
        if a[i] == nil then 
            return nil
        else 
            return a[i], t[a[i]]
        end
    end
  
    return iter
end