struct VS_TEXTURED_INPUT
{
    float2 Position : POSITION;
    float2 TextureCoordinate : TEXCOORD0;
};

struct VS_TEXTURED_OUTPUT
{
    float4 Position : POSITION;
    float2 TextureCoordinate : TEXCOORD0;
};

VS_TEXTURED_OUTPUT vs(
    VS_TEXTURED_INPUT input,
    uniform float2 toto
    )
{
    VS_TEXTURED_OUTPUT
        output;
        
    output.Position = float4( input.Position, 0, 1 );
    output.TextureCoordinate = input.TextureCoordinate * toto;
    
    return output;
}

float4 pixel_shader_common(
    float2 texture_coordinate : TEXCOORD0,
    uniform bool it_use_shadow_mask
    )
{
    float4
        result = { 0.0f, 0.0f, 0.0f, 0.0f };

    return result;
}

// ~~

float4 ps(
    float2 texture_coordinate : TEXCOORD0,
    uniform bool it_use_shadow_mask
   ) : COLOR0
{
    return pixel_shader_common( texture_coordinate, it_use_shadow_mask );
}

// ~~

float4 ps_with_water(
    float2 texture_coordinate : TEXCOORD0,
    float2 vpos : VPOS,
    uniform bool it_use_shadow_mask
   ) : COLOR0
{
    float4
        color_multiplier;

    return color_multiplier * pixel_shader_common( texture_coordinate, it_use_shadow_mask );
}

// ~~

technique Default
{
    pass P0
    {
        VertexShader = compile vs_3_0 vs();
        PixelShader = compile ps_3_0 ps( false );
    }
}

// ~~

technique DefaultWithShadowMap
{
    pass P0
    {
        VertexShader = compile vs_3_0 vs();
        PixelShader = compile ps_3_0 ps( true );
    }
}

// ~~

technique DefaultWithShadowMapAndWater
{
    pass P0
    {
        VertexShader = compile vs_3_0 vs( float2( 0.5f, 1.5 * 2.0f ) );
        PixelShader = compile ps_3_0 ps_with_water( true );
    }
}
