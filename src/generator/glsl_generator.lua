local i

local technique_name = ""

local vertex_shaders = {}
local pixel_shaders = {}

local struct_name_table = {}
local attribute_table = {}
local varying_table = {}
local uniform_table = {}

local current_function_name = ""
local alias_by_function = {}

GLSLGenerator = {

    ["ProcessNode"] = function( node )
    
        if GLSLGenerator[ "process_" .. node.name ] == nil then
            error( "No printer for ast node '" .. node.name .. "' in HLSL printer", 1 )
        end

        return GLSLGenerator[ "process_" .. node.name ]( node );
    
    end,

    ["ProcessAst"] = function( ast )
        local 
            output = "<Shader>\n"
            
        for node in NodeOfType( ast, "struct_definition" ) do
            table.insert( struct_name_table, Structure_GetName( node ) )
        end

        GLSLGenerator[ "ProcessShadersDeclaration" ]( ast )
        
        output = output .. GLSLGenerator[ "ProcessShadersDefinition" ]( ast )
        
        output = output .. "<Technique name=\"" .. technique_name .. "\">\n"
        
        table.foreach( vertex_shaders, function( k, v ) output = output .. "<VS name=\"" .. v .. "\" />\n" end )
        table.foreach( pixel_shaders, function( k, v ) output = output .. "<PS name=\"" .. v .. "\" />\n" end )
        
        output = output .. "</Technique>\n"
        
        output = output .. "</Shader>"
        
        ShaderPrint( output )
    end,
    
    ["ProcessShadersDeclaration"] = function( node )
        GLSLGenerator[ "process_techniques" ]( node )
    end,
    
    ["ProcessShadersDefinition"] = function( node )
    
        local
            output = ""
        
        for child_node in NodeOfType( node, 'function' ) do
        
            local
                node_name = ""
            local
                function_name = child_node[ 2 ][ 1 ]
        
            for index, value in pairs( vertex_shaders ) do
                if value == function_name then
                        node_name = "VertexShader"
                    break
                end
            end
            if node_name == "" then
                for index, value in pairs( pixel_shaders ) do
                    if value == function_name then
                            node_name = "PixelShader"
                        break
                    end
                end
            end
            
            output = output .. "<" .. node_name .. " name=\"" .. function_name  .. "\">\n"
            
            output = output .. GLSLGenerator[ "Process" .. node_name ]( node, function_name )
            
            output = output .. "<" .. node_name .. "/>\n"
        end
        
        return output
        
    end,
    
    [ "ProcessVertexShader" ] = function ( ast, function_name )
        local output = "<![CDATA[\n\n"
        local function_node = Function_GetNodeFromId( ast, function_name )
        local function_body_node = Function_GetBody( function_node )
        
        current_function_name = Function_GetName( function_node )
            
        output = output .. GLSLGenerator[ "ProcessVertexShaderAttributesDeclaration" ]( ast, function_name ) .. "\n"
        output = output .. GLSLGenerator[ "ProcessVertexShaderVaryingDeclaration" ]( ast, function_name ) .. "\n"
            
        output = output .. "void main()\n{\n"
        
        --output = output .. GLSLGenerator[ "process_function_body" ]( function_body_node )
        
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
                local
                    structure_members = Structure_GetMembers( ast, argument_type )
                    
                for index, member in ipairs( structure_members ) do
                    local
                        attribute = {
                                [ "name" ] = Field_GetName( member ),
                                [ "type" ] = Field_GetType( member ),
                                [ "semantic" ] = Field_GetSemantic( member ),
                            }
                    table.insert( attribute_table, attribute )
                end
            else
                local
                    attribute = {
                            [ "name" ] = Argument_GetName( argument ),
                            [ "type" ] = Argument_GetType( argument ),
                            [ "semantic" ] = Argument_GetSemantic( argument ),
                        }
                table.insert( attribute_table, attribute )
            end
        end
        
        for index, attribute in ipairs( attribute_table ) do
            output = output .. GLSL_Helper_GetAttribute( attribute )
        end

        return output
    end,
    
     [ "ProcessVertexShaderVaryingDeclaration" ] = function ( ast, function_name )
        
        local output = ""
        local function_node = Function_GetNodeFromId( ast, function_name )
        local function_return_type = Function_GetReturnType( function_node )
            
        if Type_IsAStructure( ast, function_return_type ) then
            local
                structure_members = Structure_GetMembers( ast, function_return_type )
                
            for index, member in ipairs( structure_members ) do
                local
                    attribute = {
                            [ "name" ] = Field_GetName( member ),
                            [ "type" ] = Field_GetType( member ),
                            [ "semantic" ] = Field_GetSemantic( member ),
                        }
                table.insert( varying_table, attribute )
            end
        else
            local
                attribute = {
                        [ "name" ] = "",
                        [ "type" ] =function_return_type,
                        [ "semantic" ] = "",
                    }
            table.insert( varying_table, attribute )
        end
        
        for index, varying in ipairs( varying_table ) do
            output = output .. GLSL_Helper_GetVarying( varying )
        end

        return output
    end,
    
    [ "ProcessPixelShader" ] = function ( node )
        local
            output = "<![CDATA[\n\n"
            
        output = output .. GLSLGenerator[ "ProcessPixelShaderUniformsDeclaration" ]( ast, function_name ) .. "\n"
        output = output .. GLSLGenerator[ "ProcessPixelShaderVaryingsDeclaration" ]( ast ) .. "\n"

        output = output .. "void main()\n{\n"
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
    
    [ "ProcessPixelShaderUniformsDeclaration" ] = function ( ast )
        
        local output = ""
        
        return output
    end,
    
    ["process_techniques"] = function( node )    
        
        local output = ""

        for child_node in NodeOfType( node, 'technique' ) do
            output = output .. GLSLGenerator[ "process_technique" ]( child_node )
        end
        
        return output
    
    end,
    
    ["process_technique"] = function( node )
        
        technique_name = Technique_GetName( node )

        for index, pass_node in ipairs( node ) do        
            if index > 1 then
                GLSLGenerator[ "process_pass" ]( pass_node )
            end        
        end
        
        return ""
    end,
    
    ["process_pass"] = function( node )
        
        for index, shader_call_node in ipairs( node ) do        
            if index > 1 then
                GLSLGenerator[ "process_shader_call" ]( shader_call_node )
            end        
        end
        
    end,
    
    ["process_shader_call"] = function( node )
    
        if ShaderCall_GetType( node ) == "VertexShader" then
            table.insert( vertex_shaders, ShaderCall_GetName( node ) )
        else
            table.insert( pixel_shaders, ShaderCall_GetName( node ) )
        end
        
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
        
        for i, struct_name in ipairs( struct_name_table ) do
            if struct_name == type then
                --alias_by_function[ current_function_name ]
            end
        end
        
        --if Type_IsAStructure( type, 
        -- for i, attribute in ipairs( attribute_table ) do
            -- if attribute[ "type" ] == type
        -- then
        
        return output
    end,
}

RegisterPrinter( GLSLGenerator, "glsl", "glfx" )