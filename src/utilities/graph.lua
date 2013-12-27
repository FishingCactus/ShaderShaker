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