HLSLGenerator11 = {
    ["process_sampler_declaration"] = function( node )
        local prefix = string.rep( [[    ]], 1 )
        local sampler_conversion_table = {
            ["sampler2D"] = "SamplerState"
        }

        output = sampler_conversion_table[node[ 1 ][ 1 ]] .. ' ' .. node[ 2 ] .. '\n{\n'

        --output = output .. prefix .. 'Texture = <' .. node[ 3 ][ 1 ] .. '>;\n'
        
        if options.export_sampler_filter_semantic then
            local has_semantic = false
            for _, field in ipairs( node ) do
                if _ > 3 then
                    has_semantic = true
                    break
                end
            end
            
            if has_semantic then
                output = output .. prefix .. "Filter = MIN_MAG_MIP_LINEAR;\n"
            end
        end

        output = output .. '};'

        return output;
    end,

    ["process_struct_definition"] = function( node )
        output = 'struct ' .. node[ 1 ] .. '\n{\n'
        
        local change_color_output_semantic = node[ 1 ] == "PS_OUTPUT"    

        for index, field in ipairs( node ) do

            if index ~= 1 then

                output = output .. field[1][1] .. ' ' .. field[2][1]

                if field[3] ~= nil then
                    local semantic = field[3][1]
                    
                    if change_color_output_semantic and string.starts( field[3][1], "COLOR" ) then
                        local semantic_number = field[3][1]:sub(6)
                        semantic = "SV_Target" .. semantic_number
                    end
                    output = output .. ' : ' .. semantic
                end

                output = output .. ';\n'
            end

        end

        output = output .. '};'
        return output

    end,

    ["process_call"] = function( node )
        local prefix = string.rep( [[    ]], i )
        local output = prefix
        local index
        local previous_i = i
        
        if node[ 1 ] == "tex2D" then
            local sampler_name = node[2][1][1]
            local texture_name = sampler_name:sub( 1, string.len( sampler_name ) - 7 )
            local uv_name = node[2][2][1]
            
            output = output .. texture_name .. ".Sample(" .. sampler_name .. "," .. uv_name .. ")"
        else
            output = node[ 1 ] .. '('

            if node[ 2 ] ~= nil then
                output = output .. ' '
                output = output .. HLSLGenerator.ProcessNode( node[ 2 ] )
                output = output .. ' '
            end
            
            output = output .. ")"
        end
        
        i = previous_i

        return output

    end,
    
    ["process_technique"] = function( node )

        output = 'technique11 ' .. node[ 1 ] .. '\n' .. '{' .. '\n'

        -- add passes

        for _, field in ipairs( node ) do

            if _ ~= 1 then

                output = output .. HLSLGenerator.ProcessNode( field ) .. '\n'
            end

        end

        return output .. '}'

    end,
    
    ["process_shader_call"] = function( node )

        local prefix = string.rep( [[    ]], 2 )
        local shader_model = { 
            ["VertexShader"] = "vs_5_0", 
            ["PixelShader"] = "ps_5_0" 
        }

        output = prefix .. node[ 1 ] .. ' = compile ' .. shader_model[node[1]] .. ' ' .. node[ 3 ] .. '('

        if node[ 4 ] ~= nil then
            output = output .. ' '
            output = output .. HLSLGenerator.ProcessNode( node[ 4 ] )
            output = output .. ' '
        end

        return output .. ');'

    end,
}