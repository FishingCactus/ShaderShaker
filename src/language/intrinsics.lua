
function tex2D( texcoord, texture )
	
	if texture.type ~= "texture2D" then 
		error( "Wrong texture, expect texture2D got " .. texture.type, 2 )
	end
	
	if texcoord.type ~= "float2" then
		error( "Wrong coordinate type, expect float2 got " .. texcoord.type, 2 )
	end
	
	local result = { type = "float4", node="Function", name="tex2D", arguments={texcoord, texture} };
	
	Language.AttachVectorMetatable( result );
	
	return result;
end