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

local function StackContains( stack, node )

    for _, item in ipairs( stack ) do
        if item == node then
            return true
        end
    end

    return false
end

function GraphNode:DetectCycles()

    local index = 1
    local index_table = {}
    local lowlink_table = {}
    local stack = {}
    local cycle_table = {}

    function strongconnect( node )
        -- Set the depth index for v to the smallest unused index
        index_table[ node ] = index
        lowlink_table[ node ] = index
        index = index + 1
        table.insert( stack, 1, node )

        -- Consider successors of v
        for next_node in pairs( node.To ) do

            if index_table[ next_node ] == nil then
                -- Successor w has not yet been visited; recurse on it
                strongconnect( next_node )
                lowlink_table[ node ] = math.min(lowlink_table[ node ], lowlink_table[ next_node ] )
            elseif StackContains( stack, next_node ) then
                -- Successor w is in stack S and hence in the current SCC
                lowlink_table[ node ] = math.min(lowlink_table[ node ], index_table[ next_node ] )
            end
        end

        -- If v is a root node, pop the stack and generate an SCC
        if lowlink_table[ node ] == index_table[ node ] then
            local cycle = {}
            local next_node

            repeat
                next_node = table.remove( stack, 1 )
                table.insert( cycle, next_node )
            until next_node == node

            if #cycle > 1 then
                table.insert( cycle_table, cycle )
            end
        end
    end

    for node in self:WalkNodes() do
        if index_table[ node ] == nil then
            strongconnect( node )
        end
    end

    return cycle_table
end
