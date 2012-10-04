local
    semantic_attribute_to_name = {
        POSITION = "Position",
        TEXCOORD0 = "TextureCoordinate",
    }

local
    intrinsic_types_table = { 
        float2 = "vec2", 
        float3 = "vec3", 
        float4 = "vec4",
    }
    
local
    shader_output_replacement_table = {
        VS = {
            POSITION = "gl_Position"
        },
        PS = {
            COLOR0 = "gl_FragColor"
        },
    }
    
function GLSL_Helper_GetNameFromSemanticAttribute( semantic_name )
    return semantic_attribute_to_name[ semantic_name ] or semantic_name
end

function GLSL_Helper_ConvertIntrinsic( hlsl_intrinsic )
    return intrinsic_types_table[ hlsl_intrinsic ] or hlsl_intrinsic
end

function GLSL_Helper_GetShaderOutputReplacement( shader_type, semantic, default_value )
    return shader_output_replacement_table[ shader_type ][ semantic ] or default_value
end

function GLSL_Helper_GetAttribute( attribute )
    
    local output = ""
    local attribute_semantic = attribute.semantic

    output =  "attribute " .. GLSL_Helper_ConvertIntrinsic( attribute.type ) .. " "
    
    if attribute_semantic ~= "" then
        output = output .. GLSL_Helper_GetNameFromSemanticAttribute( attribute_semantic )
    else
        output = output .. attribute.name
    end
    
    return output .. ";\n"
end

function GLSL_Helper_GetVarying( varying )
    
    local output = ""
    local varying_semantic = varying.semantic
    local varying_name = varying.name
    local name = ""
    local name_from_semantic = ""

    if varying_semantic ~= "" then
        name_from_semantic = GLSL_Helper_GetNameFromSemanticAttribute( varying_semantic )
    end
    
    output =  "varying " .. GLSL_Helper_ConvertIntrinsic( varying.type ) .. " "
    
    if varying_semantic ~= "" and varying_semantic ~= name_from_semantic then
        name = name_from_semantic
    elseif varying_name ~= "" then
        name = varying_name
    else
        output = output .. "vertex_shader_output"
    end
    
    return output .. GLSL_Helper_GetVaryingPrefix() .. name .. ";\n"
end

function GLSL_Helper_GetVaryingPrefix( )
    return "vary_"
end

function GLSL_Helper_GetUniformFromConstant( constant )    
    return "uniform " .. GLSL_Helper_ConvertIntrinsic( constant.type ) .. " " .. constant.name .. ";\n"
end

function GLSL_Helper_GetUniformFromSampler( sampler_type, texture_name  )
    return "uniform " .. sampler_type .. " " .. texture_name .. ";\n"
end