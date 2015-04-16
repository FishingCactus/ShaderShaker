HLSLGenerator9 = {

    ["process_technique"] = function( node )

        output = 'technique ' .. node[ 1 ] .. '\n' .. '{' .. '\n'

        -- add passes

        for _, field in ipairs( node ) do

            if _ ~= 1 then

                output = output .. HLSLGenerator.ProcessNode( field ) .. '\n'
            end

        end

        return output .. '}'

    end,

    ["process_pass"] = function( node )

        local prefix = string.rep( [[    ]], 1 )

        output = prefix .. 'pass ' .. node[ 1 ] .. '\n' .. prefix .. '{' .. '\n'

        -- add shader calls
        for _, field in ipairs( node ) do

            if _ ~= 1 then

                output = output .. HLSLGenerator.ProcessNode( field ) .. '\n'
            end

        end

        return output .. '    }'

    end,

    ["process_shader_call"] = function( node )

        local prefix = string.rep( [[    ]], 2 )

        output = prefix .. node[ 1 ] .. ' = compile ' .. node[ 2 ] .. ' ' .. node[ 3 ] .. '('

        if node[ 4 ] ~= nil then
            output = output .. ' '
            output = output .. HLSLGenerator.ProcessNode( node[ 4 ] )
            output = output .. ' '
        end

        return output .. ');'

    end,

    ["process_call"] = function( node )

        local prefix = string.rep( [[    ]], i )
        local output = prefix
        local index
        local previous_i = i

        output = node[ 1 ] .. '('

        if node[ 2 ] ~= nil then
            output = output .. ' '
            output = output .. HLSLGenerator.ProcessNode( node[ 2 ] )
            output = output .. ' '
        end

        i = previous_i

        return output .. ')'

    end,

    ["process_struct_definition"] = function( node )
        output = 'struct ' .. node[ 1 ] .. '\n{\n'

        for index, field in ipairs( node ) do

            if index ~= 1 then

                output = output .. field[1][1] .. ' ' .. field[2][1]

                if field[3] ~= nil then
                    output = output .. ' : ' .. field[3][1]
                end

                output = output .. ';\n'
            end

        end

        output = output .. '};'
        return output

    end,

    ["process_texture_declaration"] = function( node )
        return node[ 1 ][ 1 ] .. ' ' .. node[ 2 ] .. ';'
    end,

    ["process_sampler_declaration"] = function( node )
        local prefix = string.rep( [[    ]], 1 )

        output = node[ 1 ][ 1 ] .. ' ' .. node[ 2 ] .. '\n{\n'

        output = output .. prefix .. 'Texture = <' .. node[ 3 ][ 1 ] .. '>;\n'

        if options.export_sampler_filter_semantic then
            for _, field in ipairs( node ) do
                if _ > 3 then
                    output = output .. prefix .. field[ 1 ] .. ' = ' .. field[ 2 ] .. ';\n'
                end
            end
        end

        output = output .. '};'

        return output;
    end,

    ["process_constructor"] = function( node )

        return node[ 1 ][ 1 ] .. '(' .. HLSLGenerator.ProcessNode( node[ 2 ] ) .. ')'

    end,

    ["process_function"] = function( function_node )

        local output = ""
        local prefix = string.rep( [[    ]], i )
        local previous_i = i

        i = i + 1

        local result = {}
        local get_result_value = function ( key ) return result[ key ][ 1 ] or "" end
        local get_generated_result_value = function ( key ) if result[ key ] then return HLSLGenerator.ProcessNode( result[ key ] ) else return "" end end

        for index, node in ipairs( function_node ) do
            result[ node.name ] = node
        end

        output = prefix .. get_result_value( "type" ) .. ' ' .. get_result_value( "ID" ) .. "("
        local argument_list = get_generated_result_value( "argument_list" )

        if argument_list ~= "" then
            output = output .. '\n' .. argument_list .. " \n"
        end

        output = output .. ")" .. get_generated_result_value( "semantic" ) .. "\n"
        output = output .. "{\n" .. get_generated_result_value( "function_body" ) .. "\n}"

        i = previous_i

        return output

    end,

    ["process_function_body"] = function( function_body_node )

        local output = ""

        for _, statement in ipairs( function_body_node ) do
            output = output .. HLSLGenerator.ProcessNode( statement ) .. '\n'
        end

        return output
    end,

    ["process_argument_expression_list"] = function( argument_list )

        local result = {}

        for index,argument in ipairs( argument_list ) do
            result[ index ] = HLSLGenerator.ProcessNode( argument )
        end

        return table.concat( result, ', ' );

    end,

    ["process_argument_list"] = function( argument_list )
        local output
        local result = {}
        local prefix = string.rep( [[    ]], i )

        for index,argument in ipairs( argument_list ) do
            result[ index ] = HLSLGenerator.process_argument( argument )
        end

        return prefix .. table.concat( result, ',\n' .. prefix );
    end,

    ["process_argument"] = function( argument )

        local result = {}
        local get_result_value = function ( key ) return result[ key ] or "" end

        for index, value in ipairs( argument ) do
            result[ argument[ index ].name ] = argument[ index ][ 1 ]
        end

        local output = get_result_value( "input_modifier" ) .. " "
                     .. get_result_value( "modifier" ) .. " "
                     .. get_result_value( "type" ) .. " "
                     .. get_result_value( "ID" )

        local semantic = get_result_value( "semantic" )

        if semantic == "" then
            semantic = get_result_value( "user_semantic" )
        end

        if semantic ~= "" then
            output = output .. " : " .. semantic
        end

        return output
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
            local sub_index = 2

            if index ~= 4 then
                output = output .. ',\n'
            end

            output = output .. prefix .. node[ index ][ 1 ]

            while node[index][ sub_index ] ~= nil do
                local sub_output = HLSLGenerator.ProcessNode( node[ index ][ sub_index ] )
                local sub_key_name = node[ index ][ sub_index ].name

                if sub_key_name ~= "annotations" and sub_key_name ~= "user_semantic" and sub_key_name ~= "semantic" and sub_key_name ~= "size" then
                    output = output .. " = "
                end

                output = output .. sub_output
                sub_index = sub_index + 1
            end

            index = index + 1
        end

        i = previous_i

        return output .. ';'
    end,

    ["process_postfix"] = function( node )

        return HLSLGenerator.ProcessNode( node[ 1 ] ) .. '.' .. HLSLGenerator.ProcessNode( node[ 2 ] )

    end,

    ["process_swizzle"] = function( node )

        return HLSLGenerator.ProcessNode( node[ 1 ] ) .. '.' .. node[ 2 ]

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
        local output = node[ 1 ]

        -- node[ 2 ] can be an index (eg foo[3])
        if node[ 2 ] ~= nil then
            output = output .. HLSLGenerator.ProcessNode( node[ 2 ] )
        end

        return output
    end,

    ["process_literal"] = function( node )
        return node[ 1 ]
    end,

    ["process_bool_literal"] = function( node )
        return node[ 1 ]
    end,

    ["process_float_literal"] = function( node )
        return node[ 1 ]
    end,

    ["process_int_literal"] = function( node )
        return node[ 1 ]
    end,

    ["process_initial_value_table"] = function( node )
        local result= {}

        for _, value in ipairs( node ) do
            result[ _ ] = HLSLGenerator.ProcessNode( value )
        end

        return '{' .. table.concat( result, ', ' ) .. '}';
    end,

    [ "process_cast" ] = function( node )
        return '(' .. HLSLGenerator.ProcessNode( node[1] ) .. ')' .. HLSLGenerator.ProcessNode( node[2] )
    end,

    [ "process_type" ] = function( node )
        local output = ""

        output = node[1]

        if node[ 2 ] then
            output = output .. HLSLGenerator.ProcessNode( node[2] )
        end

        return output
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

        local f = HLSLGenerator.ProcessNode( node[1] )

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

    [ "process_=_expression" ] = function( node )
        local prefix = string.rep([[    ]], i )

        return prefix .. HLSLGenerator.ProcessNode( node[ 1 ] ) .. ' = ' .. HLSLGenerator.ProcessNode( node[ 2 ] )
    end,
    [ "process_-=_expression" ] = function( node )
        local prefix = string.rep([[    ]], i )

        return prefix .. HLSLGenerator.ProcessNode( node[ 1 ] ) .. ' -= ' .. HLSLGenerator.ProcessNode( node[ 2 ] )
    end,
    [ "process_*=_expression" ] = function( node )
        local prefix = string.rep([[    ]], i )

        return prefix .. HLSLGenerator.ProcessNode( node[ 1 ] ) .. ' *= ' .. HLSLGenerator.ProcessNode( node[ 2 ] )
    end,
        [ "process_+=_expression" ] = function( node )
        local prefix = string.rep([[    ]], i )

        return prefix .. HLSLGenerator.ProcessNode( node[ 1 ] ) .. ' += ' .. HLSLGenerator.ProcessNode( node[ 2 ] )
    end,
    [ "process_/=_expression" ] = function( node )
        local prefix = string.rep([[    ]], i )

        return prefix .. HLSLGenerator.ProcessNode( node[ 1 ] ) .. ' /= ' .. HLSLGenerator.ProcessNode( node[ 2 ] )
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

        return prefix .. HLSLGenerator.ProcessNode( node[1] ) .. node[2] .. ";"
    end,

    [ "process_unary_!" ] = function( node )

        local node_1 = HLSLGenerator.ProcessNode( node[ 1 ] )
        local output = '!'

        if GetOperatorPrecedence( '!' ) < GetOperatorPrecedence( node[ 1 ].name ) then
            output = output .. '(' .. node_1 .. ')'
        else
            output = output .. node_1
        end

        return output
    end,

    [ "process_unary_-" ] = function( node )

        local node_1 = HLSLGenerator.ProcessNode( node[ 1 ] )
        local output = '-'

        if GetOperatorPrecedence( '!' ) < GetOperatorPrecedence( node[ 1 ].name ) then
            output = output .. '(' .. node_1 .. ')'
        else
            output = output .. node_1
        end

        return output
    end,

    [ "process_annotations" ] = function( node )
        local output = "< "

        for _, statement in ipairs( node ) do
            output = output .. HLSLGenerator.ProcessNode( statement )
        end

        return output .. " >"
    end,

    [ "process_entry" ] = function( node )
        local output = node[ 1 ] .. " " .. node[ 2 ] .. " = "

        if node[ 3 ][ 1 ] ~= nil then
            output = output .. HLSLGenerator.ProcessNode( node[ 3 ] )
        else
            output = output .. node[ 3 ]
        end

        return output .. ";"
    end,

    [ "process_user_semantic" ] = function( node )
        return " : " .. node[ 1 ]
    end,

    [ "process_semantic" ] = function( node )
        return " : " .. node[ 1 ]
    end,

    [ "process_size" ] = function( node )
        return "[" .. node[ 1 ] .. "]"
    end,

    [ "process_expression_statement" ] = function( node )
        return HLSLGenerator.ProcessNode( node[ 1 ] ) .. ";"
    end,

    [ "process_index" ] = function( node )
        return "[" .. HLSLGenerator.ProcessNode( node[ 1 ] ) .. "]"
    end,
}

local function AddOperator( operator )

    local operator_precedence = GetOperatorPrecedence( operator )
    HLSLGenerator9[ "process_" .. operator ] = function( node )

        local node_1 = HLSLGenerator.ProcessNode( node[ 1 ] )
        local node_2 = HLSLGenerator.ProcessNode( node[ 2 ] )
        local output

        if operator_precedence < GetOperatorPrecedence( node[ 1 ].name ) then
            output = '(' .. node_1 .. ')'
        else
            output = node_1
        end

        output = output .. ' ' .. operator .. ' '

        if operator_precedence < GetOperatorPrecedence( node[ 2 ].name ) then
            output = output .. '(' .. node_2 .. ')'
        else
            output = output .. node_2
        end

        return output
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