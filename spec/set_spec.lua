dofile "src/utilities/set.lua"

describe("Set", function()
    local default_empty_set
    local default_filled_set

    before_each(function()
        default_empty_set = Set.new{}
        default_filled_set = Set.new{ "hello", "world" }
    end)

    it("returns whether the item is contained", function()

        assert.is_true( default_filled_set:contains( "hello" ) )
        assert.is_true( default_filled_set:contains( "world" ) )
        assert.is_false( default_empty_set:contains( "hello" ) )
    end)

    it("removes item", function()
        default_filled_set:remove( "hello" )
        assert.is_false( default_filled_set:contains( "hello" ) )
        assert.is_true( default_filled_set:contains( "world" ) )
    end)

    it("inserts item", function()
        default_filled_set:insert( "another" )
        default_empty_set:insert( "another2" )
        assert.is_true( default_filled_set:contains( "another" ) )
        assert.is_true( default_empty_set:contains( "another2" ) )
    end)

    it("can intersect set", function()
        local smaller_set = Set.new{ "hello", "universe" }
        local result = default_filled_set:intersection( smaller_set )
        assert.is_true( result:contains( "hello" ) )
        assert.is_false( result:contains( "world" ) )
        assert.is_false( result:contains( "universe" ) )

        local result2 = smaller_set:intersection( default_filled_set )

        assert.is_true( result2:contains( "hello" ) )
        assert.is_false( result2:contains( "world" ) )
        assert.is_false( result2:contains( "universe" ) )
    end)

    it("can make union set", function()
        local smaller_set = Set.new{ "hello", "universe" }
        local result = default_filled_set:union( smaller_set )
        assert.is_true( result:contains( "hello" ) )
        assert.is_true( result:contains( "world" ) )
        assert.is_true( result:contains( "universe" ) )

        local result2 = smaller_set:union( default_filled_set )

        assert.is_true( result2:contains( "hello" ) )
        assert.is_true( result2:contains( "world" ) )
        assert.is_true( result2:contains( "universe" ) )
    end)

    it("pops item", function()
        local result = default_filled_set:pop()
        assert.is_false( default_filled_set:contains( result ) )
        assert.is_true( result == "hello" or result == "world" )
    end)

end)