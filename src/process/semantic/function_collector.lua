local function ArgumentAdapter( argument_node )
    return {
        Node = argument_node,
        GetModifier = function( self )
            if self.Node[ 1 ].name == "input_modifier" then
                return self.Node[ 1 ][ 1 ]
            else
                return nil
            end
        end,
        GetSemantic = function( self )

            for _, item in ipairs( self.Node ) do
                if item.name == 'semantic' or item.name == 'user_semantic' then
                    return item[ 1 ]
                end
            end

            return nil
        end
    }
end

function IsSemantic( tag )
    return tag == 'semantic' or tag == 'user_semantic'
end

local IsSemantic = IsSemantic

local function ExtractSemanticFromArgument( input, output, argument )
    local arg = ArgumentAdapter( argument )

    local modifier = arg:GetModifier()
    local semantic = arg:GetSemantic()

    if argument[ 1 ].name == "input_modifier" and IsSemantic( argument[ 4 ].name ) then

        if modifier == 'in' then
            table.insert( input, semantic )
        elseif modifier == 'out' then
            table.insert( output, semantic )
        elseif modifier =='inout' then
            table.insert( input, semantic )
            table.insert( output, semantic )
        end

        return true
    elseif IsSemantic( argument[ 3 ].name ) then
        table.insert( output, semantic )
    else
        return false
    end
end

local function ExtractSemanticFromFunction( function_node )
    local input = {}
    local output = {}

    assert( function_node[ 1 ].name == 'type' )

    if function_node[ 1 ][ 1 ] ~= 'void' then

        if IsSemantic( function_node[ 4 ].name ) then
            table.insert( output, function_node[ 4 ][ 1 ] )
        else
            print( 'missing semantic, should be internal function returning' )
            return {}, {}
        end
    end

    local arguments = function_node[ 3 ]

    for _, argument in ipairs( arguments ) do
        ExtractSemanticFromArgument( input, output, argument )
    end

    return input,output
end

local function FillSemanticMap( map, function_name, semantic_table )

    for _, semantic in ipairs( semantic_table ) do

        local semantic_table = map[ semantic ] or {}
        table.insert( semantic_table, function_name )
        map[ semantic ] = semantic_table
    end
end

function CreateSemanticTableFromAst( ast )

    local input_map, output_map, function_map

    input_map = {}
    output_map = {}
    function_map = {}

    local ast_function_node, ast_function_index
    for ast_function_node, ast_function_index in NodeOfType( ast, "function", false ) do
        local function_name = ast_function_node[ 2 ][ 1 ]
        local input, output = ExtractSemanticFromFunction( ast_function_node )

        function_map[ function_name ] = { input = input, output = output }

        FillSemanticMap( input_map, function_name, input )
        FillSemanticMap( output_map, function_name, output );
    end

    return input_map, output_map, function_map
end