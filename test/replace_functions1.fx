float3 GetPosition(
    float x,
    float y,
    float z,
    float w
    )
{
    return float3( x, y, z );
}

float4 GetPosition(
    float x,
    float y,
    float z
    )
{
    return float4( x, y, z, 0.0f );
}

float3 GetStrangePosition(
    float x,
    float y,
    float z
    )
{
    return float3( x, y, z ) * 10.0f;
}

float3 GetPosition(
    float x,
    float y,
    float z
    )
{
    return float3( x, y, z ) * 2.0f;
}