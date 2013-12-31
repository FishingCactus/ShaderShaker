dofile "src/utilities/set.lua"
dofile "src/utilities/graph.lua"

describe("GraphNode", function()

    local a_node, b_node, c_node, d_node

    before_each(function()
        a_node = GraphNode.new()
        b_node = GraphNode.new()
        c_node = GraphNode.new()
        d_node = GraphNode.new()

        a_node:AddTarget( b_node )
        b_node:AddTarget( c_node )
        c_node:AddTarget( d_node )
    end)

    it("walks node pre-depth first", function()
        local expected_walk
        expected_walk = { a_node, b_node, c_node, d_node }

        local index = 1

        for node in a_node:WalkNodes() do
            assert.are.equals( expected_walk[ index ], node )
            index = index + 1
        end
    end)

    it("walks node depth first", function()
        local expected_walk
        expected_walk = { d_node, c_node, b_node, a_node }

        local index = 1

        for node in a_node:WalkNodesDepthFirst() do
            assert.are.equals( expected_walk[ index ], node )
            index = index + 1
        end
    end)

    it("detect cycles in the graph only if there is some", function()

        assert.are.equals( 0, #a_node:DetectCycles() )

        d_node:AddTarget( a_node )

        assert.are.equals( 1, #a_node:DetectCycles() )
    end)

end)