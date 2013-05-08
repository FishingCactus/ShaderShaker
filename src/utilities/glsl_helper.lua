local
    semantic_attribute_to_name = {
        POSITION = "Position",
        TEXCOORD0 = "TextureCoordinate",
        TEXCOORD1 = "TextureCoordinate",
        VPOS = "ScreenCoordinates",
        COLOR0 = "Color"
    }

local
    intrinsic_types_table = { 
        float2 = "vec2", 
        float3 = "vec3", 
        float4 = "vec4",
        float4x4 = "mat4x4",
        float4x3 = "mat4x3",
        tex2D = "texture2D",
        texCUBE = "textureCube",
        fmod = "mod",
        lerp = "mix",
        saturate = function( str ) return "clamp( " .. str .. ", 0.0, 1.0)" end
    }
    
local
    intrinsic_types_with_precision = {
        float = true,
        vec2 = true,
        vec3 = true,
        vec4 = true,
        mat2 = true,
        mat3 = true,
        mat4 = true
    }
    
local
    shader_output_replacement_table = {
        VertexShader = {
            POSITION = "gl_Position"
        },
        PixelShader = {
            COLOR = "gl_FragColor",
            COLOR0 = "gl_FragColor",
            COLOR1 = "gl_FragData[ 0 ]"
        },
    }
    
local
    shader_input_replacement_table = {
        VertexShader = {
            
        },
        PixelShader = {
            VPOS = "gl_FragCoord"
        },
    }
    
function GLSL_Helper_PrefixIntrinsicWithPrecision( intrinsic, precision )
    if intrinsic_types_with_precision[ intrinsic ] then
        return precision .. " " .. intrinsic
    end
    
    return intrinsic
end
    
function GLSL_Helper_GetNameFromSemanticAttribute( semantic_name )
    return semantic_attribute_to_name[ semantic_name ] or semantic_name
end

function GLSL_Helper_ConvertIntrinsic( hlsl_intrinsic )
    return intrinsic_types_table[ hlsl_intrinsic ] or hlsl_intrinsic
end

function GLSL_Helper_GetShaderOutputReplacement( shader_type, semantic, default_value )
    return shader_output_replacement_table[ shader_type ][ semantic ] or default_value
end

function GLSL_Helper_GetShaderInputReplacement( shader_type, semantic, default_value )
    if shader_type and semantic then
        return shader_input_replacement_table[ shader_type ][ semantic ] or default_value
    end
    
    return default_value
end

function GLSL_Helper_GetAttribute( attribute )
    
    local output = ""
    local attribute_semantic = attribute.semantic

    output =  "attribute " .. GLSL_Helper_ConvertIntrinsic( attribute.type ) .. " "
    
    --[[
    if attribute_semantic ~= "" then
        output = output .. GLSL_Helper_GetNameFromSemanticAttribute( attribute_semantic )
    else
    ]]--
        output = output .. attribute.name
    --end
    
    return output .. ";\n"
end

function GLSL_Helper_GetVarying( varying, precision )
    
    precision = precision or ""

    local output = ""
    local varying_semantic = varying.semantic
    local varying_name = varying.name
    local name = ""
    local name_from_semantic = ""

    --[[
    if varying_semantic ~= "" then
        name_from_semantic = GLSL_Helper_GetNameFromSemanticAttribute( varying_semantic )
    end
    ]]--
    output =  "varying " .. GLSL_Helper_PrefixIntrinsicWithPrecision( GLSL_Helper_ConvertIntrinsic( varying.type ), precision ) .. " "
    
    --if varying_semantic ~= "" and varying_semantic ~= name_from_semantic then
        --name = name_from_semantic
    --else
    if varying_name ~= "" then
        name = varying_name
    else
        output = output .. "vertex_shader_output"
    end
    
    return output .. GLSL_Helper_GetVaryingPrefix() .. name .. ";\n"
end

function GLSL_Helper_GetVaryingPrefix( )
    return "vary_"
end

function GLSL_Helper_GetUniformFromConstant( constant, precision )    
    precision = precision or ""
    
    return "uniform " .. GLSL_Helper_PrefixIntrinsicWithPrecision( GLSL_Helper_ConvertIntrinsic( constant.type ), precision ) .. " " .. constant.name .. ";\n"
end

function GLSL_Helper_GetUniformFromSampler( sampler_type, texture_name  )
    return "uniform " .. sampler_type .. " " .. texture_name .. ";\n"
end

function GLSL_Helper_ConvertIntrinsicFunctions( ast_node )

    for i, node in ipairs( ast_node ) do
        
        if node.name then        
            if node.name == "call" then
            
                local function_name = Call_GetName( node )
        
                if function_name == "mul" then
            
                    local args = {}
                    local mul_arg_list = node[ 2 ]
                    local new_node = { name = "*" }
                    
                    for k, variable_node in ipairs( mul_arg_list ) do
                        if k == 3 then
                            error( "mul can only accept 2 arguments", 1 )
                        end
                        
                        GLSL_Helper_ConvertIntrinsicFunctions( node )
                        
                        table.insert( new_node, variable_node )
                    end
                    
                    new_node = { name = "()", new_node }
                    
                    ast_node[ i ] = new_node
            
                end
            
            end
        
            GLSL_Helper_ConvertIntrinsicFunctions( node )
            
        end
        
    end

end

function GLSL_Helper_ConvertInitialValueTables( root_node )

    for i, node in ipairs( root_node ) do
        
        if node.name then        
            if node.name == "variable_declaration" then
            
                local variable_type = Variable_GetType( node )
                
                for j, variable_node in ipairs( node ) do
                
                    local initial_value_table_node = variable_node[ 2 ]
                
                    if initial_value_table_node ~= nil and initial_value_table_node.name == "initial_value_table" then
                    
                        local new_node = { name = "constructor", { name = "type", variable_type } }
                        local argument_expression_list = { name = "argument_expression_list" }
                        
                        for k, initial_value_node in ipairs( initial_value_table_node ) do
                            table.insert( argument_expression_list, initial_value_node )
                        end
                        
                        table.insert( new_node, argument_expression_list )
                        
                        variable_node[ 2 ] = new_node
                        
                        local t = ""
                    
                    end
                
                end
            
            end
        
            GLSL_Helper_ConvertInitialValueTables( node )
            
        end
        
    end

end

function GLSL_Helper_GetStructureMembersUsedInFunction( function_body_node, structure_parameter_name )

    local result = {}

    for child_node in NodeOfType( function_body_node, 'postfix' ) do    
        if child_node[ 1 ][ 1 ] == structure_parameter_name then
            result[ child_node[ 2 ][ 1 ] ] = true
        end    
    end
    
    return result

end