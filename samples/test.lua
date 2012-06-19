
Texture2D "DiffuseTexture"

Constant( "float4", "DiffuseColor" ) 
Constant( "float4x4", "Projection" )
Constant( "float4x4", "WorldView" )

ItHasDiffuseTexture = true

function VertexShader()
	
	DefineInput()
		InputAttribute( "Position", "float3", "POSITION" );
		InputAttribute( "TexCoord", "float2", "TEXCOORD0" );
		InputAttribute( "Color", "float4", "COLOR0" );
	EndInput()
	
	local output = DefineStructure(  "output" )
		StructureAttribute( "Position", "float4", "POSITION" );
		StructureAttribute( "TexCoord", "float2", "TEXCOORD0" );
		StructureAttribute( "Color", "float4", "COLOR0" );
	EndStructure()
	
	b = float4( 0, 1, 2, 3 );
	
	local wvp = Projection * WorldView;
	output.Position =  wvp * float4( input.Position, 1 );
	output.Color = 2 * b * DiffuseColor * input.Color;
	output.TexCoord = input.TexCoord.xy
	
	return output;
end

function PixelShader()
	
	DefineInput()
		InputAttribute( "TexCoord", "float2", "TEXCOORD0" );
		InputAttribute( "Color", "float4", "COLOR0" );
	EndInput()
	
	local output = DefineStructure( "output" )
		StructureAttribute( "Color", "float4", "COLOR0" );
	EndStructure()
	
	output.Color = input.Color * tex2D( DiffuseTexture, input.TexCoord ); 
	return output;
end

technique{
	name = "Default",
	vs = VertexShader(),
	ps = PixelShader()
}