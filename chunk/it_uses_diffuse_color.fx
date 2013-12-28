float4 DiffuseColor < string UIWidget = "Color"; string UIName = "Diffuse Color"; > = { 1.0f, 1.0f, 1.0f, 1.0f };

void ApplyDiffuseColorOnDiffuse( inout float4 diffuse : DiffuseColor )
{
    diffuse *= DiffuseColor;
}