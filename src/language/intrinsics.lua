
function tex2D( texcoord, texture )
	
	if texture.type ~= "texture_2d" then 
		error( "Wrong texture, expect texture_2d got " .. texture.type, 2 )
	end
	
	if texcoord.type ~= "float2" then
		error( "Wrong coordinate type, expect float2 got " .. texcoord.type, 2 )
	end
	
	local result = { type = "float4", node="function", name="tex2D", arguments={texcoord, texture} };
	
	Language.AttachVectorMetatable( result );
	
	return result;
end