struct VS_OUTPUT
{
    float4 Position   : SV_POSITION; 
    float4 Diffuse    : COLOR0;
    float2 TextureUV  : TEXCOORD0;
};

float3 GetPosition(
    float x,
    float y,
    float z
    )
{
    return float3( x, y, z );
}

void HelloWorld(
	float in_data
	)
{
	float r = in_data * in_data;
}

float Blah(
	float d,
	float e
	)
{
	return d * e;
}

// ~~

VS_OUTPUT RenderSceneVS( float4 vPos : POSITION,
                         float3 vNormal : NORMAL,
                         float2 vTexCoord0 : TEXCOORD,
                         uniform int nNumLights,
                         uniform bool bTexture,
                         uniform bool bAnimate )
{
    VS_OUTPUT Output;

    const float d = 1.0;
    const float e = 2.0;
    const float f = 3.0;

    output.Position.x = d + e;

    output.Position = float4( GetPosition( d, e, f ), 0.0f );
    
    HelloWorld( Blah( d + e ) );

    return Output;
}

// ~~

technique Default
{
    pass P0
    {
        VertexShader = compile vs_3_0 RenderSceneVS( 0, false, false );
    }
}