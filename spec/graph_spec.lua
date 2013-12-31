dofile "src/utilities/set.lua"
dofile "src/utilities/graph.lua"

describe("GraphNode", function()

  it("detect cycles in the graph only if there is some", function()
        local a_node, b_node, c_node, d_node, e_node

        a_node = GraphNode.new()
        b_node = GraphNode.new()
        c_node = GraphNode.new()
        d_node = GraphNode.new()

        a_node:AddTarget( b_node )
        b_node:AddTarget( c_node )
        c_node:AddTarget( d_node )

        assert.are.equals( 0, #a_node:DetectCycles() )

        d_node:AddTarget( a_node )

        assert.are.equals( 1, #a_node:DetectCycles() )
    end)

end)