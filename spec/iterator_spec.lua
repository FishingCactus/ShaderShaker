dofile "src/utilities/iterator.lua"

describe("Iterator", function()

    it("iterates in reverse order using ripairs", function()
        local array = { 7, 6, 5, 4, 3, 2, 1 }
        local index_reference = 7

        for index, value in ripairs( array ) do
            assert.are.equals( index_reference, index )
            assert.are.equals( array[ index_reference ], value )

            index_reference = index_reference - 1
        end

        assert.are.equals( index_reference, 0 )
    end)

end)