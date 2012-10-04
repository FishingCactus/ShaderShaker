i = 0

local technique_name = ""

vertex_shaders = {}
pixel_shaders = {}

structures_table = {}
attributes_table = {}
varying_table = {}
uniform_table = {}

current_function = {}
variables_table = {}
constants_table = {}
textures_table = {}
samplers_table = {}
sampler_to_texture = {}
argument_to_varying = {}

GLSLGenerator = {

    ["ProcessNode"] = function( node )
    
        if GLSLGenerator[ "process_" .. node.name ] == nil then
            error( "No printer for ast node '" .. node.name .. "' in GLSL printer", 1 )
        end

        return GLSLGenerator[ "process_" .. node.name ]( node );
    
    end,

    ["ProcessAst"] = function( ast )
        local 
            output = "<Shader>\n"
            
        GLSLGenerator.ProcessStructureDefinitions( ast )
        GLSLGenerator.ProcessConstants( ast )
        
        GLSLGenerator.ProcessShadersDeclaration( ast )        
        output = output .. GLSLGenerator.ProcessShadersDefinition( ast )
        
        output = output .. "<Technique name=\"" .. technique_name .. "\">\n"
        
        table.foreach( vertex_shaders, function( k, v ) output = output .. "<VS name=\"" .. v .. "\" />\n" end )
        table.foreach( pixel_shaders, function( k, v ) output = output .. "<PS name=\"" .. v .. "\" />\n" end )
        
        output = output .. "</Technique>\n"        
        output = output .. "</Shader>"
        
        ShaderPrint( output )
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
    
    ["ProcessShadersDefinition"] = function( node )
    
        local output = ""
        
        for child_node in NodeOfType( node, 'function' ) do
        
            local node_name = ""
            local function_name = child_node[ 2 ][ 1 ]
            local shader_type = ""
        
            for index, value in pairs( vertex_shaders ) do
                if value == function_name then
                        node_name = "VertexShader"
                        shader_type = "VS"
                    break
                end
            end
            if node_name == "" then
                for index, value in pairs( pixel_shaders ) do
                    if value == function_name then
                            node_name = "PixelShader"
                            shader_type = "PS"
                        break
                    end
                end
            end
            
            if node_name ~= "" then            
                output = output .. "<" .. node_name .. " name=\"" .. function_name  .. "\">\n"
                
                current_function = Function_GetProperties( child_node )
                current_function[ "shader_type" ] = shader_type
                current_function[ "is_shader" ] = true
                
                output = output .. GLSLGenerator[ "Process" .. node_name ]( node, function_name )
                
                current_function = {}
                
                output = output .. "<" .. node_name .. "/>\n"
            end
        end
        
        return output
        
    end,
    
    [ "ProcessVertexShader" ] = function ( ast, function_name )
        local output = "<![CDATA[\n\n"
        local function_node = Function_GetNodeFromId( ast, function_name )
        local function_argument_list_node = Function_GetArgumentList( function_node )
        local function_body_node = Function_GetBody( function_node )
        
        output = output .. GLSLGenerator.ProcessShaderUniformsDeclaration( ast, function_name ) .. "\n"
        output = output .. GLSLGenerator.ProcessVertexShaderAttributesDeclaration( ast, function_name ) .. "\n"
        output = output .. GLSLGenerator.ProcessVertexShaderVaryingDeclaration( ast, function_name ) .. "\n"
        output = output .. GLSLGenerator.ProcessShaderCalledFunctions( ast, function_name ) .. "\n"
            
        output = output .. "void main()\n{\n"
        
        GLSLGenerator.ProcessVertexShaderArgumentList( function_argument_list_node )
        
        output = output .. GLSLGenerator.process_function_body( function_body_node )
        
        output = output .. "\n}\n"            
        output = output .. "\n\n]]>\n"
        
        return output
    end,
    
    [ "ProcessVertexShaderAttributesDeclaration" ] = function ( ast, function_name )
        local
            output = ""
        local
            function_node = Function_GetNodeFromId( ast, function_name )
        local
            function_arguments = Function_GetArguments( function_node )
            
        for input_type_index, argument in ipairs( function_arguments ) do
            local
                argument_type = Argument_GetType( argument )
        
            if Type_IsAStructure( ast, argument_type ) then
            
                for i, structure in ipairs( structures_table ) do
                    if structure.type == argument_type then
                        for j, field in ipairs( structure.members ) do
                            table.insert( attributes_table, field )
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
                table.insert( attributes_table, attribute )
            end
        end
        
        for index, attribute in ipairs( attributes_table ) do
            output = output .. GLSL_Helper_GetAttribute( attribute )
        end

        return output
    end,
    
     [ "ProcessVertexShaderVaryingDeclaration" ] = function ( ast, function_name )
        
        local output = ""
        local function_node = Function_GetNodeFromId( ast, function_name )
        local function_return_type = Function_GetReturnType( function_node )
            
        if Type_IsAStructure( ast, function_return_type ) then
            
            for i, structure in ipairs( structures_table ) do
                if structure.type == function_return_type then
                    for j, field in ipairs( structure.members ) do
                        table.insert( varying_table, field )
                    end
                end
            end
            
        else
        
            table.insert( varying_table, 
                            {
                                name = "",
                                type =function_return_type,
                                semantic = "",
                            } )
        end
        
        for index, varying in ipairs( varying_table ) do
            output = output .. GLSL_Helper_GetVarying( varying )
        end

        return output
    end,
    
    [ "ProcessPixelShader" ] = function ( ast, function_name )
        local
            output = "<![CDATA[\n\n"
        
        local function_node = Function_GetNodeFromId( ast, function_name )
        local function_argument_list_node = Function_GetArgumentList( function_node )
        local function_body_node = Function_GetBody( function_node )
            
        output = output .. GLSLGenerator.ProcessShaderUniformsDeclaration( ast, function_name ) .. "\n"
        output = output .. GLSLGenerator.ProcessPixelShaderVaryingsDeclaration( ast ) .. "\n"
        output = output .. GLSLGenerator.ProcessShaderCalledFunctions( ast, function_name ) .. "\n"

        output = output .. "void main()\n{\n"
        
        GLSLGenerator.ProcessPixelShaderArgumentList( function_argument_list_node )
        output = output .. GLSLGenerator.process_function_body( function_body_node )
        
        
        output = output .. "\n}\n"
        output = output .. "\n\n]]>\n"
        
        return output
    end,
    
    [ "ProcessPixelShaderVaryingsDeclaration" ] = function ( ast )
        
        local output = ""        
        
        for index, varying in ipairs( varying_table ) do
            output = output .. GLSL_Helper_GetVarying( varying )
        end

        return output
    end,
    
    [ "ProcessShaderUniformsDeclaration" ] = function ( ast )
        
        local output = ""
        
        for i, constant in ipairs( constants_table ) do
            output = output .. GLSL_Helper_GetUniformFromConstant( constant )
        end
        
        for i, sampler in ipairs( samplers_table ) do
            output = output .. GLSL_Helper_GetUniformFromSampler( sampler.type, sampler_to_texture[ sampler.name ] )
        end
        
        return output
    end,
    
    [ "ProcessShaderCalledFunctions" ] = function( ast, function_name )
    
        local output = ""
        local called_functions = Function_GetCalledFunctions( ast, function_name )
        
        for i, called_function_name in ipairs( called_functions ) do
            output = output .. GLSLGenerator.ProcessFunction( ast, called_function_name )
        end
    
        return output
    
    end,
    
    [ "ProcessFunction" ] = function( ast, function_name )
    
        local output = ""

        local function_node = Function_GetNodeFromId( ast, function_name )
        
        output = output .. GLSLGenerator.ProcessNode( function_node )
    
        return output
    
    end,
    
    ["process_techniques"] = function( node )    
        
        local output = ""

        for child_node in NodeOfType( node, 'technique' ) do
            output = output .. GLSLGenerator.process_technique( child_node )
        end
        
        return output
    
    end,
    
    ["process_technique"] = function( node )
        
        technique_name = Technique_GetName( node )

        for index, pass_node in ipairs( node ) do        
            if index > 1 then
                GLSLGenerator.process_pass( pass_node )
            end        
        end
        
        return ""
    end,
    
    ["process_pass"] = function( node )
        
        for index, shader_call_node in ipairs( node ) do        
            if index > 1 then
                GLSLGenerator.process_shader_call( shader_call_node )
            end        
        end
        
    end,
    
    ["process_shader_call"] = function( node )
    
        local name = ShaderCall_GetName( node )

        if ShaderCall_GetType( node ) == "VertexShader" then
            for i, v in ipairs( vertex_shaders ) do
                if v == name then
                    return
                end
            end
            
            table.insert( vertex_shaders, name )
        else
            for i, v in ipairs( pixel_shaders ) do
                if v == name then
                    return
                end
            end

            table.insert( pixel_shaders, name )
        end
        
    end,
    
    [ "ProcessVertexShaderArgumentList" ] = function( node )
        for i, argument in ipairs( node ) do
            local type = Argument_GetType( argument )
            local name = Argument_GetName( argument )
            
            for i, structure in ipairs( structures_table ) do
                if structure.type == type then
                                    
                    table.insert( variables_table,
                                    {
                                        name = name,
                                        type = type
                                    } )
                    
                    return ""
                end
            end
        
        end
    end,
    
    [ "ProcessPixelShaderArgumentList" ] = function( node )
        
        for argument_node in NodeOfType( node, "argument", false ) do
            local name = Argument_GetName( argument_node )
            local type = Argument_GetType( argument_node )
            local semantic = Argument_GetSemantic( argument_node )
            
            for i, varying in ipairs( varying_table ) do
                if semantic == varying.semantic and type == varying.type then
                    argument_to_varying.name  = GLSL_Helper_GetVaryingPrefix() .. varying.name
                end
            end
        end
        
        return ""
    end,
    
    [ "process_argument_list" ] = function( argument_list )
        local output
        local result = {}
        local prefix = string.rep( [[    ]], i )
        
        for index,argument in ipairs( argument_list ) do
            result[ index ] = GLSLGenerator.process_argument( argument )
        end
        
        return prefix .. table.concat( result, ',\n' .. prefix );
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
        local output = ""
        local type = Variable_GetType( node )
        local name = Variable_GetName( node )
        
        for i, structure in ipairs( structures_table ) do
            if structure.type == type then
            
                table.insert( variables_table, 
                                {
                                    name = name,
                                    type = type
                                } )                
                return ""
            end
        end
        
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
        
        output = output .. GLSL_Helper_ConvertIntrinsic( node[3][1] ) .. '\n'
        i = i +1
        index = 4
        while node[index] ~= nil do
        
            local prefix = string.rep( [[    ]], i )
            
            if index ~= 4 then
                output = output .. ',\n'
            end
            
            output = output .. prefix .. node[ index ][ 1 ]
            
            --if node[ index ][2] ~= nil then
                --output = output .. '=' .. GLSLGenerator.ProcessNode( node[ index ][ 2 ] )
            --end
            
            index = index + 1
        end
        
        i = previous_i
        
        return output .. ';'
    end,
    
    [ "process_=_statement" ] = function( node )
        local prefix = string.rep([[    ]], 1 )
        
        return prefix .. GLSLGenerator.ProcessNode( node[ 1 ] ) .. ' = ' .. GLSLGenerator.ProcessNode( node[ 2 ] ) .. ';'
    end,
    
    [ "process_constructor" ] = function( node )        
        return GLSL_Helper_ConvertIntrinsic( node[ 1 ][ 1 ] ) .. '(' .. GLSLGenerator.ProcessNode( node[ 2 ] ) .. ')'
    end,
    
    [ "process_return" ] = function( node )
        if #node == 0 then
            return 'return;'
        elseif current_function.is_shader then
            -- this check is to avoid the classic "return output;" of HLSL (with "output" being an instance of a structure definition)
            for i, variable in ipairs( variables_table ) do
                if variable.name == node[ 1 ][ 1 ] then
                    return ''
                end
            end
            
            local assignment = GLSL_Helper_GetShaderOutputReplacement( current_function.shader_type, current_function.semantic, "" )
            
            if assignment ~= "" then
                return assignment .. " = " .. GLSLGenerator.ProcessNode( node[ 1 ] ) .. ';'
            end
            
            return 'return ' .. GLSLGenerator.ProcessNode( node[ 1 ] ) .. ';'
        else
            return 'return ' .. GLSLGenerator.ProcessNode( node[ 1 ] ) .. ';'
        end
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
                                                for l, varying in ipairs( varying_table ) do
                                                    if varying.semantic == field.semantic then
                                                        return GLSL_Helper_GetVaryingPrefix() .. varying.name
                                                    end
                                                end
                                            end
                                        end
                                        
                                        return replacement
                                    elseif structure.is_input then
                                    
                                        for l, attribute in ipairs( attributes_table ) do
                                            if attribute.semantic == field.semantic then
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
        return sampler_to_texture[ node[ 1 ] ]
            or argument_to_varying[ node[ 1 ] ]
            or node[ 1 ]
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
        local output = 'if (' .. GLSLGenerator.ProcessNode( node[1] ) .. ')\n'
        
        output = output .. GLSLGenerator.ProcessNode( node[ 2 ] )
        
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
        
        for _, statement in ipairs( node ) do
            output = output .. GLSLGenerator.ProcessNode( statement ) .. '\n'
        end
        
        output = output .. '}'
        
        return output
    end,
    
    ["process_function"] = function( function_node )
    
        local output
        local function_body_index
        
        current_function = Function_GetProperties( function_node )
        
        output = function_node[ 1 ][ 1 ] .. ' ' .. function_node[ 2 ][ 1 ]
        
        if function_node[ 3 ].name == "argument_list" then
            function_body_index = 4
            output = output .. '(\n' .. GLSLGenerator.process_argument_list( function_node[ 3 ] ) .. '\n'
        else
            output = output .. '('
            function_body_index = 3
        end
        
        output = output .. ')\n' .. '{\n'
        
        for _, statement in ipairs( function_node[ function_body_index ] ) do
        
            output = output .. GLSLGenerator.ProcessNode( statement ) .. '\n'
        end
        
        return output .. '}\n\n'
        
    end,
    
    ["process_initial_value_table"] = function( function_node )
    
        return ""
        
    end,
    
    [ "process_post_modify_statement" ] = function( node )
        local prefix = string.rep([[    ]], i )
        
        return prefix .. GLSLGenerator.ProcessNode( node[1] ) .. node[2]
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

RegisterPrinter( GLSLGenerator, "glsl", "glfx" )