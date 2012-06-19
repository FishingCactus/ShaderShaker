
function tex2D( texture, texcoord )
    
    if texture.type ~= "texture2D" and texture.type ~= "sampler" then 
        error( "Wrong texture, expect texture2D or sampler got " .. texture.type, 2 )
    end
    
    if texcoord.type ~= "float2" then
        error( "Wrong coordinate type, expect float2 got " .. texcoord.type, 2 )
    end
    
    local result = { type = "float4", node="Function", name="tex2D", arguments={texcoord, texture} };
    
    Language.AttachVectorMetatable( result );
    
    return result;
end

function lerp( a, b, factor )

    if a.type ~= b.type then 
        error( "Both values should have the same type ( " .. a.type .. " and " .. b.type " )", 2 )
    end
    
    if not Language.IsNumber( factor ) or factor.type ~= "float"  then
        error( "Wrong factor type, expect float got " .. factor.type, 2 )
    end
    
    local result = { type = a.type, node="Function", name="lerp", arguments={a, b, factor} };
    
    Language.AttachVectorMetatable( result );
    
    return result;

    
end