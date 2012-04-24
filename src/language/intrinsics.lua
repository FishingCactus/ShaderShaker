
function tex2D( texcoord, sampler )

	assert( texcoord.type == "float2" );
	assert( sampler.type == "texture" );

	local result = { type = "float4", node="function", name="tex2D", arguments={texcoord, sampler} };
	
	Language.AttachVectorMetatable( result );
	
	return result;
end