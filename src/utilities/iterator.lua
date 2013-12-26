function ripairs( table )
    local function ripairs_it( table, index )
        index = index - 1
        local value = table[ index ]
        if value == nil then return nil end
        return index, value
    end

    return ripairs_it, table, #table+1
end