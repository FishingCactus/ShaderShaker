local i

GLSLGenerator = {

    ["ProcessAst"] = function( ast )
        for _, value in ipairs( ast ) do
            
            if GLSLGenerator[ "process_" .. value.name ] == nil then
                error( "No printer for ast node '" .. value.name .. "' in HLSL printer", 1 )
            end

            i = 0
            ShaderPrint( GLSLGenerator[ "process_" .. value.name ]( value ) .. '\n' )
            
        end
    
    end,
    
    ["ProcessNode"] = function( node )
    
        if GLSLGenerator[ "process_" .. node.name ] == nil then
            error( "No printer for ast node '" .. node.name .. "' in HLSL printer", 1 )
        end

        return GLSLGenerator[ "process_" .. node.name ]( node );
    
    end,

}

RegisterPrinter( GLSLGenerator, "glsl", "glfx" )