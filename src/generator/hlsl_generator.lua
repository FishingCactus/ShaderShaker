HLSLGenerator = {

    ["ProcessAst"] = function( ast )
        for _, value in ipairs( ast ) do
            
            if HLSLGenerator[ "process_" .. value.name ] == nil then
                error( "No printer for ast node '" .. value.name .. "' in HLSL printer", 1 )
            end

            
            ShaderPrint( HLSLGenerator[ "process_" .. value.name ]( value ) )
            
        end
    
    end,
    
    ["ProcessNode"] = function( node )
    
        if HLSLGenerator[ "process_" .. node.name ] == nil then
                error( "No printer for ast node '" .. node.name .. "' in HLSL printer", 1 )
        end

        return HLSLGenerator[ "process_" .. node.name ]( node );
    
    end,
    
    
    ["process_function"] = function( function_node )
    
        local output
        local function_body_index
        
        output = function_node[ 1 ][ 1 ] .. " " .. function_node[ 2 ][ 1 ] .. "(\n"
        
        if function_node[ 3 ].name == "argument_list" then
            function_body_index = 4
            output = output .. HLSLGenerator.process_argument_list( function_node[ 3 ] )
        else
            fuction_body_index = 3
        end
        
        output = output .. ")\n{\n"
        
        for _, statement in ipairs( function_node[ function_body_index ] ) do
        
            output = output .. HLSLGenerator.ProcessNode( statement ) .. "\n"
        end

        return output .. "}\n"
        
    end,
    
    ["process_argument_list"] = function( argument_list )
        local output
        local result = {}
        
        for _,argument in ipairs( argument_list ) do
            result[ _ ] = HLSLGenerator.process_argument( argument )
        end
        
        return table.concat( result, ',\n' );
    end,
    
    ["process_argument"] = function( argument )
    
        return argument[ 1 ][ 1 ] .. ' ' .. argument[ 2 ][ 1 ]
    end,
    
    [ "process_variable_declaration" ] = function( node )
            
        local output = node[1][1] .. '\n'
        
        local index = 2
        
        while node[index] ~= nil do
        
            if index ~= 2 then
                output = output .. ',\n'
            end
            
            output = output .. node[ index ][ 1 ]
            
            if node[ index ][2] ~= nil then
                output = output .. '=' .. HLSLGenerator.ProcessNode( node[ index ][ 2 ] )
            end
            
            index = index + 1
        end
        return output .. ';'
    end,
    
    ["process_return"] = function( node )
        if #node == 0 then
            return 'return;'
        else
            return 'return ' .. HLSLGenerator.ProcessNode( node[ 1 ] ) .. ';'
        end
    end,
    
    ["process_variable"] = function( node )
        return node[ 1 ]
    end,
    
    ["process_literal"] = function( node )
        return node[ 1 ]
    end
}

local function AddOperator( operator )

    HLSLGenerator[ "process_" .. operator ] = function( node )
        return '(' .. HLSLGenerator.ProcessNode( node[ 1 ] ) .. ') ' .. operator .. ' (' .. HLSLGenerator.ProcessNode( node[ 2 ] ) .. ')'
    end
end
AddOperator( '+' )
AddOperator( '-' )
AddOperator( '*' )
AddOperator( '/' )

RegisterPrinter( HLSLGenerator, "hlsl", "fx" )