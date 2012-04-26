
Texture2D "DiffuseTexture"

ItHasDiffuseTexture = true

function VertexShader()
	
	DefineInput()
		InputAttribute( "Position", "float3", "POSITION" );
		InputAttribute( "TexCoord", "float2", "TEXCOORD0" );
		InputAttribute( "Color", "float4", "COLOR0" );
	EndInput()
	
	DefineOutput()
		OutputAttribute( "Position", "float4", "POSITION" );
		OutputAttribute( "TexCoord", "float2", "TEXCOORD0" );
		OutputAttribute( "Color", "float4", "COLOR0" );
	EndOutput()
	
	a = float4_new( 1, 0, 0, 0 );
	b = float4_new( 0, 1, 2, 3 );
	
	output.Position = a.zxxy;
	output.Color = 2 * input.Color;
	output.TexCoord = input.TexCoord.xy
	
	return output;
end

function PixelShader()
	
	DefineInput()
		InputAttribute( "TexCoord", "float2", "TEXCOORD0" );
		InputAttribute( "Color", "float4", "COLOR0" );
	EndInput()
	
	DefineOutput()
		OutputAttribute( "Color", "float4", "COLOR0" );
	EndOutput()
	
	output.Color = input.Color * tex2D( input.TexCoord, DiffuseTexture ); 
	return output;
end

technique{
	name = "Default",
	vs = VertexShader(),
	ps = PixelShader()
}