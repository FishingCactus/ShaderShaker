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

        if output_table ~= nil then

            for _, function_name in ipairs( output_table ) do

                if not used_function_table:contains( function_name ) then
                    return function_name, data.map.func[ function_name ]
                end
            end
        end
    end
end

function GenerateShader( output_semantic, semantic_data )

    local open_semantic_table, closed_semantic_table, used_function_table
    local node_table, output_node_table

    node_table = {}
    output_node_table = {}

    for _, semantic in ipairs( output_semantic ) do
        local node = GraphNode.new{ semantic = { semantic }, name = "return" }
        node_table[ semantic ] = node
        output_node_table[ semantic ] = node;
    end

    open_semantic_table = Set.new( output_semantic )
    closed_semantic_table = Set.new{}
    used_function_table= Set.new{}

    while true do

        local current_semantic = open_semantic_table:pop()

        if current_semantic == nil then break end

        local function_name, function_data = GetMatchingFunction( current_semantic, semantic_data, used_function_table )

        if function_name == nil then
            print( "Unable to find a function for semantic " .. current_semantic .. ", aborting" )
            return
        end

        used_function_table:insert( function_name )

        local semantic_to_close_table = Set.new( GetDifference( function_data.output, function_data.input ) )
        local node = GraphNode.new{ semantic = { function_data.output }, name = function_name, data = function_data }

        for _, semantic in ipairs( function_data.output ) do
            --Create dependency with semantic user
            node_table[ semantic ]:AddTarget( node )
        end

        for semantic in pairs( semantic_to_close_table ) do

            closed_semantic_table:insert( semantic )
            node_table[ semantic ] = nil
        end

        open_semantic_table = Set.new( GetDifference( open_semantic_table, semantic_to_close_table ) )

        for _, semantic in ipairs( function_data.input ) do
            -- Update function node that waits for an input
            node_table[ semantic ] = node
            open_semantic_table:insert( semantic )
        end

        print( "Open : " .. Set.tostring( open_semantic_table ) )
        print( "Closed : " .. Set.tostring( closed_semantic_table ) )

    end

end