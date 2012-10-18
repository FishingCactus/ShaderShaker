struct VS_OUTPUT
{
    float4 Position   : SV_POSITION; 
    float4 Diffuse    : COLOR0;
    float2 TextureUV  : TEXCOORD0;
};

VS_OUTPUT RenderSceneVS( float4 vPos : POSITION,
                         float3 vNormal : NORMAL,
                         float2 vTexCoord0 : TEXCOORD,

                        in const float2 vpos,
                        out const float3 world_space_view_vector,

                        uniform int nNumLights,
                        uniform bool bTexture,
                        uniform bool bAnimate 
                        )
{
    VS_OUTPUT Output;

    const float d = 1.0;
    const float e = 2.0;
    const float f = 3.0;

    output.Position.x = d + e;

    HelloWorld( d, e );
    Blah( d + e );

    return Output;
}

// ~~

technique Default
{
    pass P0
    {
        VertexShader = compile vs_3_0 vs();
        PixelShader = compile ps_3_0 ps( false, 123 );
    }
    pass P1
    {
        VertexShader = compile vs_3_0 vs1();
        PixelShader = compile ps_3_0 ps1();
    }
}