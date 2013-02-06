float3
    LightDirection0;
    
float4 RenderSceneVS()
{
    float3
        light_direction;
        
    light_direction = normalize( -LightDirection0 );
}