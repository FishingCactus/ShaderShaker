texture2D DiffuseTexture : DIFFUSE < string ResourceName = "default_color.dds"; string UIName = "Diffuse Texture"; string ResourceType = "2D"; >;
sampler2D DiffuseTextureSampler = sampler_state { Texture = <DiffuseTexture>; AddressU = Wrap; AddressV = Wrap; FILTER = MIN_MAG_MIP_LINEAR; };

// -- PIXEL SHADER

void ApplyDiffuseTexture(
    inout float4 diffuse : DiffuseColor,
    in float2 texture_coordinate : DiffuseTexcoord
    )
{
    result *= tex2D( DiffuseTextureSampler, texture_coordinate );
}
