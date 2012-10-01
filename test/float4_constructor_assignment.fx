// ~~

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

// ~~

VS_TEXTURED_OUTPUT vs(
    VS_TEXTURED_INPUT input
    )
{
    VS_TEXTURED_OUTPUT
        output;
        
    output.Position = float4( input.Position, 0, 1 );
    output.TextureCoordinate = input.TextureCoordinate;
    
    return output;
}