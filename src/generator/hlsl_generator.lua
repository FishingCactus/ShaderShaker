local i
HLSLGenerator = {

    ["ProcessAst"] = function( ast )
        for _, value in ipairs( ast ) do
            
            if HLSLGenerator[ "process_" .. value.name ] == nil then
                error( "No printer for ast node '" .. value.name .. "' in HLSL printer", 1 )
            end

            i = 0
            ShaderPrint( HLSLGenerator[ "process_" .. value.name ]( value ) .. '\n' )
            
        end
    
    end,
    
    ["ProcessNode"] = function( node )
    
        if HLSLGenerator[ "process_" .. node.name ] == nil then
            error( "No printer for ast node '" .. node.name .. "' in HLSL printer", 1 )
        end

        return HLSLGenerator[ "process_" .. node.name ]( node );
    
    end,
    
    ["process_struct_definition"] = function( node )
        output = 'struct ' .. node[ 1 ] .. '\n{\n'
        
        for _, field in ipairs( node ) do
        
            if _ ~= 1 then
                
                output = output .. field[1][1] .. ' ' .. field[2]
                
                if field[3] ~= nil then
                    output = output .. ' : ' .. field[3][1]
                end
                
                output = output .. ';\n'
            end
        
        end
        
        output = output .. '}'
        return output
    
    end,
    
    ["process_function"] = function( function_node )
    
        local output
        local function_body_index
        local prefix = string.rep( [[    ]], i )
        local previous_i = i
        
        i = i + 1
        
        output = prefix .. function_node[ 1 ][ 1 ] .. ' ' .. function_node[ 2 ][ 1 ]
        
        if function_node[ 3 ].name == "argument_list" then
            function_body_index = 4
            output = output .. '(\n' .. HLSLGenerator.process_argument_list( function_node[ 3 ] ) .. '\n' .. prefix
        else
            output = output .. '('
            function_body_index = 3
        end
        
        output = output .. ')\n' .. prefix .. '{\n'
        
        for _, statement in ipairs( function_node[ function_body_index ] ) do
        
            output = output .. HLSLGenerator.ProcessNode( statement ) .. '\n'
        end
        
        i = previous_i

        return output .. prefix .. '}\n'
        
    end,
    
    ["process_argument_list"] = function( argument_list )
        local output
        local result = {}
        local prefix = string.rep( [[    ]], i )
        
        for _,argument in ipairs( argument_list ) do
            result[ _ ] = HLSLGenerator.process_argument( argument )
        end
        
        return prefix .. table.concat( result, ',\n' .. prefix );
    end,
    
    ["process_argument"] = function( argument )

        return argument[ 1 ][ 1 ] .. ' ' .. argument[ 2 ][ 1 ]
    end,
    
    [ "process_variable_declaration" ] = function( node )

        local prefix = string.rep( [[    ]], i )
        local output = prefix
        local index
        local previous_i = i
        
        if #node[1] ~= 0 then
            output = output .. table.concat( node[1], ' ' ) .. ' ';
        end
        
        if #node[2] ~= 0 then
            output = output .. table.concat( node[2], ' ' ) .. ' ';
        end
        
        output = output .. node[3][1] .. '\n'
        i = i +1
        index = 4
        while node[index] ~= nil do
        
            local prefix = string.rep( [[    ]], i )
            
            if index ~= 4 then
                output = output .. ',\n'
            end
            
            output = output .. prefix .. node[ index ][ 1 ]
            
            if node[ index ][2] ~= nil then
                output = output .. '=' .. HLSLGenerator.ProcessNode( node[ index ][ 2 ] )
            end
            
            index = index + 1
        end
        
        i = previous_i
        
        return output .. ';'
    end,
    
    ["process_return"] = function( node )
        local prefix = string.rep( [[    ]], i )
        if #node == 0 then
            return prefix .. 'return;'
        else
            return prefix .. 'return ' .. HLSLGenerator.ProcessNode( node[ 1 ] ) .. ';'
        end
    end,
    
    ["process_break"] = function( node )
        local prefix = string.rep( [[    ]], i )
        return prefix .. 'break;'
    end,
    
    ["process_variable"] = function( node )
        return node[ 1 ]
    end,
    
    ["process_literal"] = function( node )
        return node[ 1 ]
    end,
    
    ["process_initial_value_table"] = function( node )
        local result= {}
        
        for _, value in ipairs( node ) do
            result[ _ ] = HLSLGenerator.ProcessNode( value )
        end
        
        return '{' .. table.concat( result, ', ' ) .. '}';
    end,
    
    ["process_cast"] = function( node )
    
        return '(' ..node[1][1] .. ')' .. HLSLGenerator.ProcessNode( node[2] )
    end,
    
    -- If statement
    
    ["process_if"] = function( node )
    
        local output = ''
    
        for _, block in ipairs( node ) do
            output = output .. HLSLGenerator.ProcessNode( block )
        end
        
        return output
    end,
    
    ["process_if_block"] = function( node )
        local prefix = string.rep( [[    ]], i )
        local previous_i = i
        
        i = i + 1
        
        local output = prefix .. 'if (' .. HLSLGenerator.ProcessNode( node[1] ) .. ')\n'
        
        output = output .. HLSLGenerator.ProcessNode( node[ 2 ] )
        
        i = previous_i
        
        return output .. '\n'
    end,
    
    ["process_else_if_block"] = function( node )
        local prefix = string.rep( [[    ]], i )
        local previous_i = i
        
        i = i + 1
        
        local output = prefix .. 'else if (' .. HLSLGenerator.ProcessNode( node[1] ) .. ')\n'
        
        output = output .. HLSLGenerator.ProcessNode( node[ 2 ] )
        
        i = previous_i
        
        return output .. '\n'
    end,
    
     ["process_else_block"] = function( node )
        local prefix = string.rep( [[    ]], i )
        local previous_i = i
        
        i = i + 1
        
        local output = prefix .. 'else\n'
        
        output = output .. HLSLGenerator.ProcessNode( node[ 1 ] )
        
        i = previous_i
        
        return output .. '\n'
    end,
    
    [ "process_for" ] = function( node )
        local previous_i = i
        local prefix = string.rep([[    ]], i )
        
        i = 0
        
        local output = prefix .. 
            'for( ' .. HLSLGenerator.ProcessNode( node[1] ) 
            .. HLSLGenerator.ProcessNode( node[2] ) .. ';' 
            .. HLSLGenerator.ProcessNode( node[3] ) .. ')\n'
            
        i = previous_i + 1
        output = output .. HLSLGenerator.ProcessNode( node[4] )
            
        i = previous_i
        
        return output
    end,
    
    [ "process_do_while" ] = function( node )
        local previous_i = i
        local prefix = string.rep([[    ]], i )
        
        i = i + 1
        
        local output = prefix .. 'do\n'
            
        output = output .. HLSLGenerator.ProcessNode( node[1] )
        output = output .. 'while( ' .. HLSLGenerator.ProcessNode( node[2] ) .. ' );\n'
            
        i = previous_i
        
        return output
        
    end,
    
    [ "process_while" ] = function( node )
        local previous_i = i
        local prefix = string.rep([[    ]], i )
        
        i = i + 1
        
        output = prefix .. 'while( ' .. HLSLGenerator.ProcessNode( node[1] ) .. ' )\n'
        output = output .. HLSLGenerator.ProcessNode( node[2] ) .. '\n'
            
        i = previous_i
        
        return output
        
    end,
    
    [ "process_block" ] = function( node )
        local previous_i = i
        local prefix = string.rep([[    ]], i - 1 )
        
        local output = prefix .. '{\n'
        
        for _, statement in ipairs( node ) do
            output = output .. HLSLGenerator.ProcessNode( statement ) .. '\n'
        end
        
        output = output .. prefix .. '}'
        
        return output
    end,
    
    [ "process_=" ] = function( node )
        return HLSLGenerator.ProcessNode( node[ 1 ] ) .. ' = ' .. HLSLGenerator.ProcessNode( node[ 2 ] )
    end,
    
    [ "process_=_statement" ] = function( node )
        local prefix = string.rep([[    ]], i )
        
        return prefix .. HLSLGenerator.ProcessNode( node[ 1 ] ) .. ' = ' .. HLSLGenerator.ProcessNode( node[ 2 ] ) .. ';'
    end,
    [ "process_-=_statement" ] = function( node )
        local prefix = string.rep([[    ]], i )
        
        return prefix .. HLSLGenerator.ProcessNode( node[ 1 ] ) .. ' -= ' .. HLSLGenerator.ProcessNode( node[ 2 ] ) .. ';'
    end,
    [ "process_*=_statement" ] = function( node )
        local prefix = string.rep([[    ]], i )
        
        return prefix .. HLSLGenerator.ProcessNode( node[ 1 ] ) .. ' *= ' .. HLSLGenerator.ProcessNode( node[ 2 ] ) .. ';'
    end,
        [ "process_+=_statement" ] = function( node )
        local prefix = string.rep([[    ]], i )
        
        return prefix .. HLSLGenerator.ProcessNode( node[ 1 ] ) .. ' += ' .. HLSLGenerator.ProcessNode( node[ 2 ] ) .. ';'
    end,
    [ "process_/=_statement" ] = function( node )
        local prefix = string.rep([[    ]], i )
        
        return prefix .. HLSLGenerator.ProcessNode( node[ 1 ] ) .. ' /= ' .. HLSLGenerator.ProcessNode( node[ 2 ] ) .. ';'
    end,
    
    [ "process_pre_modify" ] = function( node )
        return node[1] .. HLSLGenerator.ProcessNode( node[2] )
    end,
    
    [ "process_post_modify" ] = function( node )
        return HLSLGenerator.ProcessNode( node[1] ) .. node[2]
    end,
    
    [ "process_pre_modify_statement" ] = function( node )
        local prefix = string.rep([[    ]], i )
        
        return prefix .. node[1] .. HLSLGenerator.ProcessNode( node[2] )
    end,
    
    [ "process_post_modify_statement" ] = function( node )
        local prefix = string.rep([[    ]], i )
        
        return prefix .. HLSLGenerator.ProcessNode( node[1] ) .. node[2]
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
AddOperator( '==' )
AddOperator( '||' )
AddOperator( '&&' )
AddOperator( '&' )
AddOperator( '|' )
AddOperator( '<' )
AddOperator( '>' )
AddOperator( '<=' )
AddOperator( '>=' )
AddOperator( '!=' )

RegisterPrinter( HLSLGenerator, "hlsl", "fx" )