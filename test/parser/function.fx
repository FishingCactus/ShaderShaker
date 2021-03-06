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

    return Output;
}

float4 PSMain(
    const VS_OUTPUT input,
    in float2 vpos              : VPOS,
    
    uniform const bool it_has_rim,
    uniform const bool it_uses_light_prepass,
    uniform const bool it_uses_color_overlay,
    uniform const bool it_uses_fog,
    uniform const bool it_uses_forward_lights
    ) : COLOR0
{

}

// ~~

technique Default
{
    pass P0
    {
        VertexShader = compile vs_3_0 RenderSceneVS( 3, true, true );
        PixelShader = compile ps_3_0 PSMain();
    }
}