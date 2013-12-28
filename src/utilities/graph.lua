GraphNode={}
local GraphNode = GraphNode
GraphNode.mt = {}
GraphNode.mt.__index = GraphNode

function GraphNode.new( data )
    local node = {}
    node.Data = data
    node.From = Set.new{}
    node.To = Set.new{}
    setmetatable(node, GraphNode.mt)
    return node
end

function GraphNode:AddTarget( node )
    if getmetatable( node ) ~= GraphNode.mt then
        error( "attempt to AddTarget with a non-node value", 2 )
    end

    self.To:insert( node )
    node.From:insert( self )
end

function GraphNode:WalkNodes()

    local node_table = {}
    local processed_node_table = Set.new{}

    node_table[ 1 ] = self

    return function()

        while #node_table > 0 do

            local current_node = table.remove( node_table, 1 )

            if not processed_node_table:contains( current_node )  then

                for value in pairs( current_node.To ) do
                    table.insert( node_table, value )
                end

                processed_node_table:insert( current_node )

                return current_node
            end
        end

        return nil
    end
end

function GraphNode:WalkNodesDepthFirst()

    local processed_node_table = Set.new{}
    local node_stack = {}
    local child_index_stack = {}

    node_stack[ 1 ] = self
    child_index_stack[ 1 ] = nil

    return function()

        while #node_stack > 0 do

            local current_node = node_stack[ 1 ]
            local child_index = child_index_stack[ 1 ]

            while 1 do

                local child_node = next( current_node.To, child_index )
                if child_node == nil then

                    table.remove( node_stack, 1 )
                    table.remove( child_index_stack, 1 )
                    return current_node
                else

                    child_index = child_node

                    if not processed_node_table:contains( child_node )  then

                        processed_node_table:insert( current_node )

                        child_index_stack[ 1 ] = child_index

                        while 1 do

                            local child = next( child_node.To )

                            if child == nil then
                                return child_node
                            else
                                table.insert( node_stack, 1, child_node )
                                table.insert( child_index_stack, 1, child )

                                child_node = child
                            end

                        end

                        return child_node
                    end
                end
            end
        end

        return nil
    end
end