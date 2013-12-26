local function GetDifference( first_table, second_table )

    local result = ShallowCopy( first_table )

    for _, semantic in ipairs( second_table ) do
        for index, semantic2 in ipairs( result ) do
            if semantic == semantic2 then
                table.remove( result, index )
                break;
            end
        end
    end

    return result
end

local function GetMatchingFunction( semantic, semantic_data, used_function_table )

    for _, data in ripairs( semantic_data ) do

        local output_table = data.map.output[ semantic ]

        if output_table ~= nil and used_function_table ~= output_table[ 1 ] then
            return output_table[ 1 ], data.map.func[ output_table[ 1 ] ]
        end
    end

    return

end

function GenerateShader( output_semantic, semantic_data )

    local open_semantic_table, closed_semantic_table, used_function_table;

    open_semantic_table = ShallowCopy( output_semantic )
    closed_semantic_table = {}
    used_function_table= {}

    while #open_semantic_table do

        local current_semantic = table.remove( open_semantic_table, 1 )
        local function_name, function_data = GetMatchingFunction( current_semantic, semantic_data, used_function_table )

        if function_name == nil then
            print( "Unable to find a function for semantic " .. current_semantic .. ", aborting" )
            return
        end

        used_function_table[ function_name ] = true

        local semantic_to_close_table = GetDifference( function_data.output, function_data.input )

        for _, semantic in ipairs( semantic_to_close_table ) do
            table.insert( closed_semantic_table, semantic )
        end

        for _, semantic in ipairs( function_data.input ) do
            table.insert( open_semantic_table, semantic )
        end

        print( "Open : " .. table.tostring( open_semantic_table ) )
        print( "Closed : " .. table.tostring( closed_semantic_table ) )

    end

end