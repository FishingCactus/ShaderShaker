local prefix_index

current_technique = ""
technique_name = ""
wanted_technique = ""

techniques = {}

vertex_shaders = {}
pixel_shaders = {}
helper_functions = {}
processed_shaders = {}

structures_table = {}

current_function = {}
variables_table = {}
constants_table = {}
textures_table = {}
samplers_table = {}
sampler_to_texture = {}
argument_to_varying = {}

function prefix()
    return string.rep( [[    ]], prefix_index )
end

GLSLGenerator = {

    ["ProcessNode"] = function( node )
    
        if GLSLGenerator[ "process_" .. node.name ] == nil then
            error( "No printer for ast node '" .. node.name .. "' in GLSL printer", 1 )
        end

        return GLSLGenerator[ "process_" .. node.name ]( node );
    
    end,

    ["PreprocessAst"] = function( ast )
    
        GLSL_Helper_ConvertIntrinsicFunctions( ast )
    
    end,
    
    ["ProcessAst"] = function( ast, technique )
        local output = "<Shader>\n"
        local technique_count = 0
        local technique_name = ""
                
        prefix_index = 1
        
        GLSLGenerator.PreprocessAst( ast )
        
        --[[
        for technique_node in NodeOfType( ast, "technique", false ) do
            technique_count = technique_count + 1
            technique_name = Technique_GetName( technique_node )
        end
        
        if technique_count == 0 then
            error( "No techniques were found in the shader", 1 )
        elseif technique_count > 1 and ( technique == nil or string.len( technique ) == 0 ) then
            error( "Multiple techniques were found in the shader, but you didn't specify which one to process. You can use the -t argument", 1 )
        end        
            
        if technique == nil then        
            wanted_technique = technique_name
        else
            wanted_technique = technique
        end
        
        if wanted_technique == nil or wanted_technique == "" then
            error( "There is an error while processing techniques", 1 )
        end
        ]]--
        
        GLSLGenerator.ProcessStructureDefinitions( ast )
        GLSLGenerator.ProcessConstants( ast )
        
        GLSLGenerator.ProcessShadersDeclaration( ast )
        GLSLGenerator.ProcessHelperFunctions( ast )
        
        for technique, params in pairs( techniques ) do
        
            current_technique = technique
            output = output .. GLSLGenerator.ProcessShaderDefinition( ast, "VertexShader", params.VertexShader.name ) 
            output = output .. GLSLGenerator.ProcessShaderDefinition( ast, "PixelShader", params.PixelShader.name ) 
        
        end
        
        for technique_name, shaders in pairs( techniques ) do
            output = output .. "\n" .. prefix() .. "<Technique name=\"" .. technique_name .. "\">\n"
        
            prefix_index = prefix_index + 1
            
            output = output .. prefix() .. "<VS name=\"" .. shaders.VertexShader.new_name .. "\" />\n"
            output = output .. prefix() .. "<VS name=\"" .. shaders.PixelShader.new_name .. "\" />\n"
            
            prefix_index = prefix_index - 1
            
            output = output .. prefix() .. "</Technique>\n"        
        end
        
        output = output .. "</Shader>"
        
        ShaderPrint( output )
    end,
    
    [ "ProcessHelperFunctions" ] = function( ast_node )
        for child_node in NodeOfType( ast_node, 'function' ) do
        
            local node_name = ""
            local function_name = child_node[ 2 ][ 1 ]
            local shader_type = ""
        
            for index, value in pairs( vertex_shaders ) do
                if value == function_name then
                    return
                end
            end
            for index, value in pairs( pixel_shaders ) do
                if value == function_name then
                    return
                end
            end
            
            error( "TODO", 1 )
            
            helper_functions[ function_name ] = GLSLGenerator.process_function( child_node )
            local t = ""
        end
    end,
    
    ["ProcessConstants"] = function( ast_node )    
        GLSLGenerator.ProcessConstantVariableDeclarations( ast_node )
        GLSLGenerator.ProcessConstantTextures( ast_node )
        GLSLGenerator.ProcessConstantTextureSamplers( ast_node )
    end,
    
    ["ProcessConstantVariableDeclarations"] = function( ast_node )
    
        for node in NodeOfType( ast_node, "variable_declaration", false ) do
            local type = Variable_GetType( node )
            
            for variable_node in NodeOfType( node, "variable", false ) do
                table.insert( constants_table, { name = variable_node[ 1 ], type = type } )
            end
        end
    
    end,
    
    ["ProcessConstantTextures"] = function( ast_node )
    
        for node in NodeOfType( ast_node, "texture_declaration", false ) do
            table.insert( textures_table, { name = Texture_GetName( node ), type = Texture_GetType( node ) } )
        end
    
    end,
    
    ["ProcessConstantTextureSamplers"] = function( ast_node )
    
        for node in NodeOfType( ast_node, "sampler_declaration", false ) do
            local name = Sampler_GetName( node )
            table.insert( samplers_table, { name = name, type = Sampler_GetType( node ) } )
            sampler_to_texture[ name ] = Sampler_GetTexture( node )
        end
    
    end,
    
    ["ProcessStructureDefinitions"] = function( ast_node )
        
        for node in NodeOfType( ast_node , "struct_definition" ) do
            local structure_name = Structure_GetName( node )
            local ends_with = function( name, end_string ) return string.sub( name, -string.len( end_string ) ) == end_string end
            local is_input = ends_with( structure_name, "INPUT" )
            local is_output = ends_with( structure_name, "OUTPUT" )
            local shader_type = string.sub( structure_name, 1, 2 )
            local structure_members = {}
            
            if shader_type == "VS" then
                shader_type = "VertexShader"
            else
                shader_type = "PixelShader"
            end
            
            for index, member in ipairs( Structure_GetMembers( node, argument_type ) ) do
            
                table.insert( structure_members, 
                                {
                                    name = Field_GetName( member ),
                                    type = Field_GetType( member ),
                                    semantic = Field_GetSemantic( member ),
                                } )
            end
            
            table.insert( structures_table, 
                            {
                                type = structure_name,
                                shader_type = shader_type,
                                is_input = is_input,
                                is_output = is_output,
                                members = structure_members
                            } )
        end
        
    end,

    ["ProcessShadersDeclaration"] = function( node )
        GLSLGenerator.process_techniques( node )
    end,
    
    ["ProcessShaderDefinition"] = function( node, shader_type, shader_name )
    
        local output = ""
        local shader_new_name = shader_name
        
        for child_node in NodeOfType( node, 'function' ) do
        
            local function_name = child_node[ 2 ][ 1 ]
            
            if function_name == shader_name then
            
                current_function = Function_GetProperties( child_node )
                current_function.shader_type = shader_type
                current_function.is_shader = true
                
                prefix_index = prefix_index + 1
                
                output = output .. GLSLGenerator[ "Process" .. shader_type ]( node, function_name )
                
                prefix_index = prefix_index - 1
                
                current_function = {}
                
                break
                
            end
        end
        
        for constant_name, constant_value in pairs( techniques[ current_technique ][ shader_type ].constants ) do
            shader_new_name = shader_new_name .. "_" .. constant_name .. "_" .. constant_value
        end
        
        techniques[ current_technique ][ shader_type ].new_name = shader_new_name
        
        if processed_shaders[ shader_new_name ] then
            return ""
        end
        
        processed_shaders[ shader_new_name ] = true
        
        output = prefix() .. "<" .. shader_type .. " name=\"" .. shader_new_name  .. "\">\n" .. output .. prefix() .. "</" .. shader_type .. ">\n"
        
        return output
        
    end,
    
    [ "ProcessVertexShader" ] = function ( ast, function_name )
        local output = prefix() .. "<![CDATA[\n"
        local function_node = Function_GetNodeFromId( ast, function_name )
        local function_argument_list_node = Function_GetArgumentList( function_node )
        local function_body_node = Function_GetBody( function_node )
        local called_functions_output = ""
        local function_body_output = ""
        
        GLSLGenerator.FillVertexShaderAttributesTable( ast, function_name )
        GLSLGenerator.FillVertexShaderVaryingMembersTable( ast, function_name )
        
        called_functions_output = GLSLGenerator.ProcessShaderCalledFunctions( ast, function_name )
        
        prefix_index = prefix_index + 1
        
        GLSLGenerator.ProcessVertexShaderArgumentList( function_name, function_argument_list_node )
        
        function_body_output = GLSLGenerator.process_function_body( function_body_node )
        
        prefix_index = prefix_index - 2
        
        output = output .. GLSLGenerator.OutputShaderUniformsDeclaration( function_name ) .. "\n"
        output = output .. GLSLGenerator.OutputVertexShaderAttributesDeclaration( function_name ) .. "\n"
        output = output .. GLSLGenerator.OutputVaryingMembersDeclaration( function_name ) .. "\n"
        output = output .. called_functions_output .. "\n"
        output = output .. prefix() .. "void main()\n" .. prefix() .. "{"
        output = output .. function_body_output        
        output = output .. prefix() .. "}\n"        
        output = output .. prefix() .. "]]>\n"
        
        return output
    end,
    
    [ "FillVertexShaderAttributesTable" ] = function ( ast, function_name )
        local function_node = Function_GetNodeFromId( ast, function_name )
        local function_arguments = Function_GetArguments( function_node )
            
        for input_type_index, argument in ipairs( function_arguments ) do
            local
                argument_type = Argument_GetType( argument )
        
            if Type_IsAStructure( ast, argument_type ) then
            
                for i, structure in ipairs( structures_table ) do
                    if structure.type == argument_type then
                        for j, field in ipairs( structure.members ) do
                            table.insert( techniques[ current_technique ].VertexShader.attributes, field )
                        end
                    end
                end
                
            else
                local
                    attribute = {
                            name = Argument_GetName( argument ),
                            type = Argument_GetType( argument ),
                            semantic = Argument_GetSemantic( argument ),
                        }
                table.insert( techniques[ current_technique ].VertexShader.attributes, attribute )
            end
        end
        
        
    end,
    
    [ "OutputVertexShaderAttributesDeclaration" ] = function( function_name )
        local output = ""
        
        for attribute_name, attribute in pairs( techniques[ current_technique ].VertexShader.used_attributes ) do
            output = output .. prefix() .. GLSL_Helper_GetAttribute( attribute )
        end

        return output
    end,
    
     [ "FillVertexShaderVaryingMembersTable" ] = function ( ast, function_name )
        
        local function_node = Function_GetNodeFromId( ast, function_name )
        local function_return_type = Function_GetReturnType( function_node )
            
        if Type_IsAStructure( ast, function_return_type ) then
            
            for i, structure in ipairs( structures_table ) do
                if structure.type == function_return_type then
                    for j, field in ipairs( structure.members ) do                        
                        table.insert( techniques[ current_technique ].VaryingMembersTable, field )
                    end
                end
            end
            
        else
        
            table.insert( techniques[ current_technique ].VaryingMembersTable, 
                            {
                                name = "",
                                type = function_return_type,
                                semantic = "",
                            } )
        end
        
    end,
    
    [ "OutputVaryingMembersDeclaration" ] = function( function_name )
        local output = ""
        
        for varying_member_name, varying_member in pairs( techniques[ current_technique ].UsedVaryingMembersTable ) do
            output = output .. prefix() .. GLSL_Helper_GetVarying( varying_member )
        end
        
        return output
        
    end,
    
    [ "ProcessPixelShader" ] = function ( ast, function_name )
        local output = prefix() .. "<![CDATA[\n"
        
        local function_node = Function_GetNodeFromId( ast, function_name )
        local function_argument_list_node = Function_GetArgumentList( function_node )
        local function_body_node = Function_GetBody( function_node )
            
        output = output .. GLSLGenerator.OutputShaderUniformsDeclaration( function_name ) .. "\n"
        output = output .. GLSLGenerator.OutputVaryingMembersDeclaration( function_name ) .. "\n"
        output = output .. GLSLGenerator.ProcessShaderCalledFunctions( ast, function_name ) .. "\n"

        output = output .. prefix() .. "void main()\n" .. prefix() .. "{\n"
        
        --prefix_index = prefix_index + 1
        
        GLSLGenerator.ProcessPixelShaderArgumentList( function_name, function_argument_list_node )
        output = output .. GLSLGenerator.process_function_body( function_body_node )
        
        --prefix_index = prefix_index - 1
        
        output = output .. prefix() .. "}\n"
        output = output .. prefix() .. "]]>\n"
        
        return output
    end,
    
    [ "OutputShaderUniformsDeclaration" ] = function ( function_name )
        
        local output = ""
        
        for i, constant in ipairs( constants_table ) do
            for j, uniform in ipairs( techniques[ current_technique ][ current_function.shader_type ].uniforms ) do
                if uniform == constant.name then
                    output = output .. prefix() .. GLSL_Helper_GetUniformFromConstant( constant )
                end
            end
        end
        
        for i, sampler in ipairs( samplers_table ) do
            for j, uniform in ipairs( techniques[ current_technique ][ current_function.shader_type ].uniforms ) do
                if uniform == sampler.name then
                    output = output .. prefix() .. GLSL_Helper_GetUniformFromSampler( sampler.type, sampler_to_texture[ sampler.name ] )
                end
            end
        end
        
        return output
    end,
    
    [ "ProcessShaderCalledFunctions" ] = function( ast, function_name )
    
        local output = ""
        local called_functions = Function_GetCalledFunctions( ast, function_name )
        
        for i, called_function_name in ipairs( called_functions ) do
            output = output .. prefix() .. GLSLGenerator.ProcessFunction( ast, called_function_name )
        end
    
        return output
    
    end,
    
    [ "ProcessFunction" ] = function( ast, function_name )
    
        local function_node = Function_GetNodeFromId( ast, function_name )
        
        return GLSLGenerator.ProcessNode( function_node )
    
    end,
    
    ["process_techniques"] = function( node )        
        for child_node in NodeOfType( node, 'technique' ) do
            GLSLGenerator.process_technique( child_node )
        end    
    end,
    
    ["process_technique"] = function( node )
    
        local technique_name = Technique_GetName( node )
        
        if wanted_technique and wanted_technique ~= "" then
            if name ~= wanted_technique then
                return
            end
        end
        
        techniques[ technique_name  ] = 
            { 
                VertexShader = 
                { 
                    name = "", 
                    new_name = "", 
                    attributes = {},
                    used_attributes = {},
                    constants = {},
                    uniforms = {}
                }, 
                PixelShader = 
                { 
                    name = "", 
                    new_name = "",
                    attributes = {},
                    constants = {},
                    uniforms = {}
                },
                VaryingMembersTable = {},
                UsedVaryingMembersTable = {}
            }

        for index, pass_node in ipairs( node ) do        
            if index > 1 then
                GLSLGenerator.process_pass( pass_node, technique_name )
            end        
        end
        
    end,
    
    ["process_pass"] = function( node, technique_name )
        
        for index, shader_call_node in ipairs( node ) do        
            if index > 1 then
                GLSLGenerator.process_shader_call( shader_call_node, technique_name )
            end        
        end
        
    end,
    
    ["process_shader_call"] = function( node, technique_name )
    
        local shader_name = ShaderCall_GetName( node )
        local vs_or_ps = ""

        if ShaderCall_GetType( node ) == "VertexShader" then
            techniques[ technique_name ].VertexShader.name = shader_name
            vs_or_ps = "VertexShader"

            for i, v in ipairs( vertex_shaders ) do
                if v == shader_name then
                    return
                end
            end
            
            table.insert( vertex_shaders, shader_name )
        else
            techniques[ technique_name ].PixelShader.name = shader_name
            vs_or_ps = "PixelShader"
            
            for i, v in ipairs( pixel_shaders ) do
                if v == name then
                    return
                end
            end

            table.insert( pixel_shaders, shader_name )
        end
        
        GLSLGenerator.ProcessShaderCallArgumentExpressionList( node, technique_name, vs_or_ps, shader_name )
        
    end,
    
    [ "ProcessShaderCallArgumentExpressionList" ] = function( node, technique_name, vs_or_ps, shader_name )
    
        local name = ShaderCall_GetName( node )
        local argument_expression_list = ShaderCall_GetArgumentExpressionList( node )
        local constants = {}        
        
        if argument_expression_list then
            for i, argument in ipairs( argument_expression_list ) do
                constants[ i ] = GLSLGenerator.ProcessNode( argument )                
            end        
        end
    
        techniques[ technique_name ][ vs_or_ps ].constants = constants
        
    end,
    
    [ "ProcessVertexShaderArgumentList" ] = function( function_name, node )
    
        local index_constant_argument = 1
        
        for i, argument in ipairs( node ) do
            local type = Argument_GetType( argument )
            local name = Argument_GetName( argument )
            local found = false
            
            for j, structure in ipairs( structures_table ) do
                if structure.type == type then
                                    
                    table.insert( variables_table,
                                    {
                                        name = name,
                                        type = type
                                    } )
                                    
                    found = true
                    
                    break
                end
            end
            
            if not found then
                if techniques[ current_technique ].VertexShader.constants[ index_constant_argument ] then
                    techniques[ current_technique ].VertexShader.constants[ name ] = techniques[ current_technique ].VertexShader.constants[ index_constant_argument ]
                    techniques[ current_technique ].VertexShader.constants[ index_constant_argument ] = nil
                    index_constant_argument = index_constant_argument + 1
                end
            end
        
        end
    end,
    
    [ "ProcessPixelShaderArgumentList" ] = function( function_name, node )
        
        local index_constant_argument = 1
        
        for i, argument in ipairs( node ) do
            local name = Argument_GetName( argument )
            local type = Argument_GetType( argument )
            local semantic = Argument_GetSemantic( argument )
            local found = false
            
            for j, varying_member in ipairs( techniques[ current_technique ].VaryingMembersTable ) do
                if semantic == varying_member.semantic and type == varying_member.type then
                    techniques[ current_technique ].UsedVaryingMembersTable[ varying_member.name ] = varying_member
                    argument_to_varying[ name ] = GLSL_Helper_GetVaryingPrefix() .. varying_member.name
                    found = true
                end
            end
            
            if not found and ( not semantic or semantic == "" )then
                if techniques[ current_technique ].PixelShader.constants[ index_constant_argument ] then
                    techniques[ current_technique ].PixelShader.constants[ name ] = techniques[ current_technique ].PixelShader.constants[ index_constant_argument ]
                    techniques[ current_technique ].PixelShader.constants[ index_constant_argument ] = nil
                    index_constant_argument = index_constant_argument + 1
                end
            end
        end
    end,
    
    [ "process_argument_list" ] = function( argument_list )
        local output
        local result = {}
        
        for index,argument in ipairs( argument_list ) do
            result[ index ] = GLSLGenerator.process_argument( argument )
        end
        
        prefix_index = prefix_index + 1
        
        output = prefix() .. table.concat( result, ',\n' .. prefix() );
        
        prefix_index = prefix_index - 1
        
        return output
    end,
    
    ["process_argument"] = function( argument )

        local output = argument[ 1 ][ 1 ] .. ' ' .. argument[ 2 ][ 1 ]
        
        if #argument > 2 then
            for i=3, #argument do
                if argument[i].name == "semantic" then
                    --output = output .. ':' .. argument[i][1]
                end
            end
        end
        
        return output
    end,
    
    [ "process_function_body" ] = function( node )
        local output = ""
        
        for index, statement in ipairs( node ) do        
            output = output .. GLSLGenerator.ProcessNode( statement ) .. '\n'
        end
        
        return output
    end,
    
    [ "process_variable_declaration" ] = function( node )
        prefix_index = prefix_index + 1
        
        local output = prefix()
        local type = Variable_GetType( node )
        local name = Variable_GetName( node )
        
        for i, structure in ipairs( structures_table ) do
            if structure.type == type then
            
                table.insert( variables_table, 
                                {
                                    name = name,
                                    type = type
                                } )                
                prefix_index = prefix_index - 1
                
                return ""
            end
        end
        
        local index
        
        if #node[1] ~= 0 then
            output = output .. table.concat( node[1], ' ' ) .. ' ';
        end
        
        if #node[2] ~= 0 then
            output = output .. table.concat( node[2], ' ' ) .. ' ';
        end
        
        output = output .. GLSL_Helper_ConvertIntrinsic( node[3][1] ) .. ' '
        
        index = 4
        while node[index] ~= nil do
        
            if index ~= 4 then
                output = output .. ',\n'
            end
            
            output = output .. node[ index ][ 1 ]
            
            if node[ index ][2] ~= nil then
                output = output .. '=' .. GLSLGenerator.ProcessNode( node[ index ][ 2 ] )
            end
            
            index = index + 1
            
        end
        
        prefix_index = prefix_index - 1
        
        return output .. ';'
    end,
    
    [ "process_=_statement" ] = function( node )
        return prefix() .. GLSLGenerator.ProcessNode( node[ 1 ] ) .. ' = ' .. GLSLGenerator.ProcessNode( node[ 2 ] ) .. ';'
    end,
    
    [ "process_constructor" ] = function( node )        
        return GLSL_Helper_ConvertIntrinsic( node[ 1 ][ 1 ] ) .. '(' .. GLSLGenerator.ProcessNode( node[ 2 ] ) .. ')'
    end,
    
    [ "process_return" ] = function( node )
        local output = ""
        
        prefix_index = prefix_index + 1;
        
        if #node == 0 then
            output = 'return;'
        elseif current_function.is_shader then
            -- this check is to avoid the classic "return output;" of HLSL (with "output" being an instance of a structure definition)
            for i, variable in ipairs( variables_table ) do
                if variable.name == node[ 1 ][ 1 ] then
                    return ''
                end
            end
            
            local assignment = GLSL_Helper_GetShaderOutputReplacement( current_function.shader_type, current_function.semantic, "" )
            
            if assignment ~= "" then
                output = assignment .. " = " .. GLSLGenerator.ProcessNode( node[ 1 ] ) .. ';'
            else
                output = 'return ' .. GLSLGenerator.ProcessNode( node[ 1 ] ) .. ';'
            end
        else
            output = 'return ' .. GLSLGenerator.ProcessNode( node[ 1 ] ) .. ';'
        end
        
        output = prefix() .. output
    
        prefix_index = prefix_index - 1
        
        return output
    end,
    
    ["process_postfix"] = function( node )
    
        if node[ 1 ].name == "variable" and node[ 2 ].name == "variable" then
        
            local left = node[ 1 ][ 1 ]
            local right = node[ 2 ][ 1 ]
            
            for i, variable in ipairs( variables_table ) do
                if variable.name == left then
                    for j, structure in ipairs( structures_table ) do
                        if variable.type == structure.type then
                            for k, field in ipairs( structure.members ) do
                                if right == field.name then
                                
                                    if structure.is_output then
                                        local replacement = GLSL_Helper_GetShaderOutputReplacement( structure.shader_type, field.semantic, field.name )
                                        
                                        if replacement == field.name then
                                            if structure.is_output then
                                                for l, varying_member in ipairs( techniques[ current_technique ].VaryingMembersTable ) do
                                                    if varying_member.semantic == field.semantic then
                                                        techniques[ current_technique ].UsedVaryingMembersTable[ varying_member.name ] = varying_member
                                                        return prefix() .. GLSL_Helper_GetVaryingPrefix() .. varying_member.name
                                                    end
                                                end
                                            end
                                        end
                                        
                                        return prefix() .. replacement
                                    elseif structure.is_input then
                                    
                                        for l, attribute in ipairs( techniques[ current_technique ].VertexShader.attributes ) do
                                            if attribute.semantic == field.semantic then
                                                techniques[ current_technique ].VertexShader.used_attributes[ attribute.name ] = attribute
                                                return attribute.name
                                            end
                                        end
                                        
                                        return field.name
                                        
                                    end
                                    
                                    return field.name
                                end
                            end
                        end
                    end
                end
            end
        
        end       
        
        return GLSLGenerator.ProcessNode( node[ 1 ] ) .. '.' .. GLSLGenerator.ProcessNode( node[ 2 ] )

    end,
    
    ["process_argument_expression_list"] = function( argument_list )

        local result = {}
        
        for index,argument in ipairs( argument_list ) do
            result[ index ] = GLSLGenerator.ProcessNode( argument )
        end
        
        return table.concat( result, ', ' );

    end,
    
    ["process_literal"] = function( node )
        return node[ 1 ]
    end,
    
    ["process_variable"] = function( node )
        local set = false
        local value = ""
        
        if current_function.shader_type ~= "" then
            value = techniques[ current_technique ][ current_function.shader_type ].constants[ node[ 1 ] ]
            if value then
                return value
            end
        end
        
        local output = sampler_to_texture[ node[ 1 ] ]
                or argument_to_varying[ node[ 1 ] ]
                or node[ 1 ]
                
        if current_function.shader_type ~= "" then
            for i, constant_value in ipairs( constants_table ) do
                if constant_value.name == output then
                    table.insert( techniques[ current_technique ][ current_function.shader_type ].uniforms, output )
                    return output
                end
            end
            
            for i, texture_value in ipairs( textures_table ) do
                if texture_value.name == output then
                    table.insert( techniques[ current_technique ][ current_function.shader_type ].uniforms, output )
                    return output
                end
            end
        end
                
        return output
    end,
    
    ["process_call"] = function( node )
        local intrinsic = GLSL_Helper_ConvertIntrinsic( node[ 1 ] )
        local output = ""
        local output2 = ""

        if node[ 2 ] ~= nil then
            output2 = ' ' .. GLSLGenerator.ProcessNode( node[ 2 ] ) .. ' '
        end
        
        if type( intrinsic ) == "function" then
            return intrinsic( output2 )
        else
            return intrinsic .. '( ' .. output2 .. ')'
        end
    end,
    
    [ "process_/=_statement" ] = function( node )
        return GLSLGenerator.ProcessNode( node[ 1 ] ) .. ' /= ' .. GLSLGenerator.ProcessNode( node[ 2 ] ) .. ';'
    end,
    
    [ "process_+=_statement" ] = function( node )
        return GLSLGenerator.ProcessNode( node[ 1 ] ) .. ' += ' .. GLSLGenerator.ProcessNode( node[ 2 ] ) .. ';'
    end,
    
    ["process_swizzle"] = function( node )        
        return GLSLGenerator.ProcessNode( node[ 1 ] ) .. '.' .. node[ 2 ]
    end,
    
    [ "process_*=_statement" ] = function( node )
        return GLSLGenerator.ProcessNode( node[ 1 ] ) .. ' *= ' .. GLSLGenerator.ProcessNode( node[ 2 ] ) .. ';'
    end,
    
    [ "process_-=_statement" ] = function( node )
        return GLSLGenerator.ProcessNode( node[ 1 ] ) .. ' -= ' .. GLSLGenerator.ProcessNode( node[ 2 ] ) .. ';'
    end,
    
    [ "process_!" ] = function( node )
    
        local node_1 = GLSLGenerator.ProcessNode( node[ 1 ] )
        local output = '!'
        
        if GetOperatorPrecedence( '!' ) < GetOperatorPrecedence( node[ 1 ].name ) then
            output = output .. '(' .. node_1 .. ')'
        else
            output = output .. node_1
        end
        
        return output
    end,
    
     ["process_if"] = function( node )
    
        local output = ''
    
        for _, block in ipairs( node ) do
            output = output .. GLSLGenerator.ProcessNode( block )
        end
        
        return output
    end,
    
    [ "process_if_block"] = function( node )
        local output = prefix() .. 'if ( ' .. GLSLGenerator.ProcessNode( node[1] ) .. ' )\n'
        
        output = output .. prefix() .. GLSLGenerator.ProcessNode( node[ 2 ] )
        
        return output .. '\n'
    end,
    
    ["process_else_if_block"] = function( node )
        local output = 'else if (' .. GLSLGenerator.ProcessNode( node[1] ) .. ')\n'
        
        output = output .. GLSLGenerator.ProcessNode( node[ 2 ] )
        
        return output .. '\n'
    end,
    
     ["process_else_block"] = function( node )
        
        local output = 'else\n'
        
        output = output .. GLSLGenerator.ProcessNode( node[ 1 ] )
        
        return output .. '\n'
    end,
    
    [ "process_for" ] = function( node )
        local output = 
            'for( ' .. GLSLGenerator.ProcessNode( node[1] ) 
            .. GLSLGenerator.ProcessNode( node[2] ) .. ';' 
            .. GLSLGenerator.ProcessNode( node[3] ) .. ')\n'
            
        output = output .. GLSLGenerator.ProcessNode( node[4] )
        
        return output
    end,
    
    [ "process_do_while" ] = function( node )
        local output = 'do\n'
            
        output = output .. GLSLGenerator.ProcessNode( node[1] )
        output = output .. 'while( ' .. GLSLGenerator.ProcessNode( node[2] ) .. ' );\n'
        
        return output
        
    end,
    
    [ "process_while" ] = function( node )
        output = 'while( ' .. GLSLGenerator.ProcessNode( node[1] ) .. ' )\n'
        output = output .. GLSLGenerator.ProcessNode( node[2] ) .. '\n'
            
        return output
        
    end,
    
    [ "process_block" ] = function( node )
        local output = "{\n"
        
        prefix_index = prefix_index + 1
        
        for _, statement in ipairs( node ) do
            output = output .. GLSLGenerator.ProcessNode( statement ) .. '\n'
        end
        
        prefix_index = prefix_index - 1
        
        output = output .. prefix() .. '}'
        
        return output
    end,
    
    ["process_function"] = function( function_node )
    
        local output
        local function_body_index
        local previous_function = current_function
        
        current_function = Function_GetProperties( function_node )
        
        output = function_node[ 1 ][ 1 ] .. ' ' .. function_node[ 2 ][ 1 ]
        
        if function_node[ 3 ].name == "argument_list" then
            function_body_index = 4
            output = output .. '(\n' .. GLSLGenerator.process_argument_list( function_node[ 3 ] ) .. '\n'
        else
            output = output .. '('
            function_body_index = 3
        end
        
        output = output .. prefix() .. ')\n' .. prefix() .. '{\n'
        
        for _, statement in ipairs( function_node[ function_body_index ] ) do
        
            output = output .. GLSLGenerator.ProcessNode( statement ) .. '\n'
        end
        
        current_function = previous_function
        
        return output .. prefix() .. '}\n\n'
        
    end,
    
    ["process_initial_value_table"] = function( function_node )
    
        return ""
        
    end,
    
    [ "process_post_modify_statement" ] = function( node )
        return GLSLGenerator.ProcessNode( node[1] ) .. node[2]
    end,
}

local function AddOperator( operator )

    local operator_precedence = GetOperatorPrecedence( operator )
    GLSLGenerator[ "process_" .. operator ] = function( node )
    
        local node_1 = GLSLGenerator.ProcessNode( node[ 1 ] )
        local node_2 = GLSLGenerator.ProcessNode( node[ 2 ] )
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

local function AddUnaryOperator( operator )
    GLSLGenerator[ "process_unary_" .. operator ] = function( node )
        return operator .. GLSLGenerator.ProcessNode( node[ 1 ] )
    end
end

AddUnaryOperator( '+' )
AddUnaryOperator( '-' )
AddUnaryOperator( '!' )
AddUnaryOperator( '~' )

RegisterPrinter( GLSLGenerator, "glsl", "glfx" )