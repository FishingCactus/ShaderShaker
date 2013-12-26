void simple( out float4 result : DiffuseColor, in float2 texcoord : DiffuseTexCoord )
{
    result = tex2D( tex, texcoord );
}

float4 simple2( in float2 texcoord : DiffuseTexCoord ) : DiffuseColor
{
    return tex2D( tex, texcoord );
}

void simple3( inout float4 result : DiffuseColor, in float2 texcoord : DiffuseTexCoord )
{
    result += tex2D( tex, texcoord );
}