float
    scalar_float,
    scalar_float_with_value = 0.5f;
float2
    vector2_float,
    vector2_float_with_value = { 0.5f, 1.0f };

struct VS_OUTPUT
{
    float4 Position   : SV_POSITION; 
    float4 Diffuse    : COLOR0;
    float2 TextureUV  : TEXCOORD0;
};

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
    const float g = 40 + scalar_float_with_value;

    output.Position.x = d + e;

    return Output;
}

// ~~

technique Default
{
    pass P0
    {
        VertexShader = compile vs_3_0 RenderSceneVS( 1, true, false );
    }
}