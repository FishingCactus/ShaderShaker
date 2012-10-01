local i
local vertex_shaders = {}
local pixel_shaders = {}

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

        output = output .. GLSLGenerator[ "ProcessShadersDeclaration" ]( ast )
        
        output = output .. GLSLGenerator[ "ProcessShadersDefinition" ]( ast )
        
        output = output .. "</Shader>"
        
        ShaderPrint( output )
    end,
    
    ["ProcessShadersDeclaration"] = function( node )
        return  GLSLGenerator[ "process_techniques" ]( node )
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
            
            output = output .. "<" .. node_name .. "/>\n"
        end
        
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
        local 
            prefix = string.rep( [[    ]], 1 )
        local
            output = prefix .. "<Technique name=\"" .. node[ 1 ] .. "\">\n"

        for index, pass_node in ipairs( node ) do        
            if index > 1 then
                output = output .. GLSLGenerator[ "process_pass" ]( pass_node )            
            end        
        end
        
        output = output .. prefix .. "</Technique>\n"
        
        return output
    end,
    
    ["process_pass"] = function( node )
        -- pass_name = node[ 1 ]
        
        local output = ""

        for index, shader_call_node in ipairs( node ) do        
            if index > 1 then
                output = output .. GLSLGenerator[ "process_shader_call" ]( shader_call_node )
            end        
        end
        
        return output    
    end,
    
    ["process_shader_call"] = function( node )
    
        local prefix = string.rep( [[    ]], 2 )
        local output = prefix
        
        if node[ 1 ] == "VertexShader" then
            output = output .. "<VS "
            table.insert( vertex_shaders, node[ 3 ] )
        else
            output = output .. "<PS "
            table.insert( pixel_shaders, node[ 3 ] )
        end
        
        output = output .. "name=\"" .. node[ 3 ] .. "\" />\n"       
        
        return output    
    end,
}

RegisterPrinter( GLSLGenerator, "glsl", "glfx" )