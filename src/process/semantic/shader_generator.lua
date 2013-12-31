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

local function TreeToString( node )

    for current_node in node:WalkNodesDepthFirst() do
        print( current_node.Data.name .. " with " .. table.tostring( current_node.Data.semantic ) )
        print( "    linked to ")
        for link in pairs( current_node.To ) do
            print( "    " .. link.Data.name )
        end
    end
end

local function CheckInputArgument( variable_table, argument )
    local semantic = argument:GetSemantic()
    local type = argument:GetType()
    local existing_type = variable_table[ semantic ]

    if existing_type == nil then
        error( "Variable " .. semantic .. " is used without being defined" )
    end

    print( 'checking ' .. semantic .. ' with type ' .. type .. ' and existing type ' .. ( existing_type or '' ))

    if existing_type == 'unknown' then
        variable_table[ semantic ] = type
    elseif type ~= existing_type then
        error( "Error while matching argument type for semantic " .. semantic .. ": Expected " .. type .. ", got " .. existing_type )
    end
end

local function ParseOutputArgument( variable_table, argument )
    local semantic = argument:GetSemantic()
    local type = argument:GetType()
    local existing_type = variable_table[ semantic ]

    print( 'Parsing ' .. semantic .. ' with type ' .. type .. ' and existing type ' .. ( existing_type or '' ))


    if existing_type ~= nil then
        error( "Variable " .. semantic .. " already exists" )
    end

    variable_table[ semantic ] = type
end

local function ParseArgumentList( variable_table, argument_list )
    for _, argument in ipairs( argument_list ) do
        local arg = ArgumentAdapter( argument )

        local modifier = arg:GetModifier()
        local semantic = arg:GetSemantic()

        if semantic == nil then
            error( "Trying to parse argument list with non-semantic argument" )
        end

        if argument[ 1 ].name == "input_modifier" then

            if modifier == 'in' or modifier =='inout' then
                CheckInputArgument( variable_table, arg )
            elseif modifier == 'out' then
                ParseOutputArgument( variable_table, arg )
            else
                error( "Unknown modifier " .. modifier )
            end
        else
            CheckInputArgument( variable_table, arg )
        end
    end
end

local function GatherVariables( variable_table, current_node )

    local function_data = current_node.Data

    if function_data.name == 'input' then
        -- not a real function, but a helper to get data from vertex data or interpolators
        variable_table[ function_data.semantic[ 1 ] ] = 'unknown' -- we don't know the type yet
    elseif function_data.name == 'return' then
        -- returning helper. If PS, should check the semantic is COLORx or DEPTH
        local variable_type = variable_table[ function_data.semantic[ 1 ] ]

        if variable_type == nil then
            error( "Trying to return variable " .. function_data.semantic[ 1 ] .. " but it does not seem defined")
        end
    else

        local argument_list = Function_GetArgumentList( function_data.data.ast_node )

        if argument_list ~= nil then
            ParseArgumentList( variable_table, argument_list )
        end
    end
end

local function GenerateVariableDeclarationAST( variable_table )
    local variable_declaration_table = {}

    for variable, type in pairs( variable_table ) do

        local variable_declaration =
            {
                name = "variable_declaration",
                {name ="storage" },
                {name = "modifier"},
                {name = "type", type},
                {name = "variable", variable}
            }

        table.insert( variable_declaration_table, variable_declaration )
    end

    return variable_declaration_table
end

local function GenerateMainFunction( root_node )

    local variable_table = {}
    local ast_node = {}

    for current_node in root_node:WalkNodesDepthFirst() do
        GatherVariables( variable_table, current_node )
    end

    return GenerateVariableDeclarationAST( variable_table )

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
            -- no function found to generate semantic, should come from input
            local node = GraphNode.new{ semantic = { current_semantic }, name = "input" }
            node_table[ current_semantic ]:AddTarget( node )
            node_table[ current_semantic ] = node
        else

            used_function_table:insert( function_name )

            local semantic_to_close_table = Set.new( GetDifference( function_data.output, function_data.input ) )
            local node = GraphNode.new{ semantic = function_data.output, name = function_name, data = function_data }

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
        end

        print( "Open : " .. Set.tostring( open_semantic_table ) )
        print( "Closed : " .. Set.tostring( closed_semantic_table ) )

    end

    print( TreeToString( output_node_table[ output_semantic[ 1 ] ] ) )

    return GenerateMainFunction( output_node_table[ output_semantic[ 1 ] ] )
end