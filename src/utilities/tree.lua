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