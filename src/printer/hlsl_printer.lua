HLSL = HLSL or {}


function HLSL.GetDeclaration( declaration )
    return declaration.variable_type .. " " .. declaration.name .. ";\n"
end

function HLSL.GetCallFunction( call_function )
    local code
    
    code = call_function.variable .. " = " .. call_function.name .. "( "
    
    for i,v in ipairs( call_function.arguments ) do
    
        if i ~= 1 then
            code = code .. ", "
        end
        
        if type(v) == "table" and ( v.type == "Texture" or v.type == "Sampler" )  then
            
            code = code .. v.name

            if v.type == "Texture" then
                code = code .. "Sampler"
            end
        else
            code = code .. v
        end
    end
    
    code = code .. " );\n" 
    
    return code 
end

function HLSL.GetSwizzle( swizzle )
    
    return swizzle.variable .. " = " .. swizzle.arguments[ 1 ] .. "." .. swizzle.arguments[ 2 ] .. ";\n"

end

HLSL.OperationTable = {
    mul = "*",
    add = "+",
    sub = "-",
    div = "/"
}

function HLSL.GetOperation( operation )
    
    assert( #( operation.arguments ) == 2 )
    
    return operation.variable .. " = " .. operation.arguments[ 1 ] .. " " .. HLSL.OperationTable[ operation.operation ] .. " " .. operation.arguments[ 2 ] .. ";\n"; 
end

function HLSL.GetAssignment( assignment )

    if type( assignment.value ) == "table" then
        return assignment.variable .. " = " .. assignment.variable_type .. "(" .. table.concat( assignment.value, "," ) .. ");\n"
    else
        return assignment.variable .. " = " .. assignment.value .. ";\n"
    end
end

function HLSL.GenerateStructure( prefix, input_definition, function_name )

    ShaderPrint( "struct " .. prefix .. "_" .. function_name .. "\n{\n" )
    
    for name, description in pairs( input_definition ) do
        ShaderPrint( 1, description.type .. " " .. name .. " : " .. description.semantic .. ";\n" )
    end
    
    ShaderPrint( "\n};\n" )
end

function HLSL.GenerateConstants( constants )

    for constant, value in pairs( constants ) do
        ShaderPrint( value.type .. " " .. constant ..";\n" );
    end
end

HLSL.SamplerFromTexture = {
    texture2D = "sampler2D"
}

function HLSL.GenerateTextures( textures )

    for texture, value in pairs( textures ) do
        ShaderPrint( value.type .. " " .. texture ..";\n" );
        
        --ShaderPrint( HLSL.SamplerFromTexture[ value.type ] .. " " .. texture .. "Sampler = sampler_state\n{\n" )
        --ShaderPrint( 1, "Texture = <" .. texture .. ">;\n" )
        --ShaderPrint( "};\n" )
    end
end

function HLSL.GenerateSamplers( samplers )

    for sampler, value in pairs( samplers ) do
        ShaderPrint( value.type .. " " .. sampler .. " = sampler_state\n{\n" )
        ShaderPrint( 1, "Texture = <" .. value.texture.name .. ">;\n" )
        -- :TODO: Print other parameters
        ShaderPrint( "};\n" )
    end
end

function HLSL.GetConstructor( constructor )

    local code = constructor.variable .. " = " .. constructor.constructor_type .. " ( "
    
    for _, value in ipairs( constructor.arguments ) do
    
        if _ ~= 1 then
            code = code .. ", "
        end
        
        code = code .. value    
    end
    
    code = code .. " );\n" 
    
    return code;
end

function HLSL.PrintFunctionPrologue( representation, function_name )
    
    HLSL.GenerateConstants( representation.constant )
    HLSL.GenerateTextures( representation.texture )
    HLSL.GenerateSamplers( representation.sampler )
    HLSL.GenerateStructure( "INPUT", representation.input, function_name )
    HLSL.GenerateStructure( "OUTPUT", representation.output, function_name )
    
    ShaderPrint( "OUTPUT_" .. function_name .. " " .. function_name .. " ( INPUT_" .. function_name .. " input )\n{\n" )
    ShaderPrint( 1, "OUTPUT_" .. function_name .. " output;\n" )

end

function HLSL.PrintFunctionEpilogue( representation, function_name )
    ShaderPrint( 1, "return output;\n}\n\n" )
end

function HLSL.PrintCode( representation )
    for i,v in ipairs( representation.code ) do
    
        if HLSL[ "Get" .. v.type ] == nil then
            error( "No printer for type " .. v.type .. " in HLSL printer", 1 )
        end
        
        ShaderPrint( 1, HLSL[ "Get" .. v.type ]( v ) )
    end
end

function HLSL.PrintTechnique( technique_name, vertex_shader_name, pixel_shader_name )
    
    ShaderPrint( "technique " .. technique_name .. "\n{" )
    ShaderPrint( 1, "pass P0\n" )
    ShaderPrint( 1, "{\n" )
    ShaderPrint( 2, "VertexShader = compile vs_3_0 " .. vertex_shader_name .. "();\n" )
    ShaderPrint( 2, "PixelShader = compile ps_3_0 " .. pixel_shader_name .. "();\n" )
    ShaderPrint( 1, "}" )
    ShaderPrint( "\n}" )

end

RegisterPrinter( HLSL, "hlsl", "fx" )