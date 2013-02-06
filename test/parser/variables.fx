float
    scalar_float,
    scalar_float_with_value = 0.5f;
float2
    vector2_float,
    vector2_float_with_value = { 0.5f, 1.0f };
float3
    vector3_float,
    vector3_float_with_value = { 0.0f, -1.0f, -1.0f };
float4
    vector4_float,
    vector4_float_with_value = { 0.0f, -1.0f, -1.0f, -2.5f };
float4x4
    matrix4_float;
int
	scalar_int,
	scalar_int_with_value = 5;
shared float
    shared_variable;
const int
    const_variable;

float4
    vector4_float,
    vector4_float_with_value = { 0.0f, -1.0f, -1.0f, -2.5f };

float 
    casting_test = (float) some_variable;
float 
    boneWeights[4] = (float[4])input.BoneWeights;

bool 
    ItUsesDiffuseColor 
        < 
        string UIName = "Use diffuse color"; 
        > = false;

float4 AmbientLightColor3DSMax 
    < 
    string UIWidget = "Color"; 
    string UIName = "3DSMax Global Lighting"; 
    > = { 0.047f, 0.047f, 0.07f, 1.0f };

float4 AmbientLightColor3DSMax : COLOR0
    < 
    string UIWidget = "Color"; 
    string UIName = "3DSMax Global Lighting"; 
    > = { 0.047f, 0.047f, 0.07f, 1.0f };

float4x4 WorldITXf : WorldInverseTranspose 
    < 
    string UIWidget="None"; 
    >;

float4x3 
    BoneTable[ 64 ];

float Kr 
    < 
    string UIWidget = "slider"; 
    string UIName = "Reflection Strength"; 
    float UIMin = 0.0; 
    float UIMax = 1.0; 
    float UIStep = 0.01; 
    > = 1.0;

texture2D SpecularTexture : DIFFUSE 
    < 
    string ResourceName = "default_color.dds"; 
    string UIName = "Specular Texture"; 
    string ResourceType = "2D"; 
    >; 

sampler2D SpecularTextureSampler = sampler_state 
    { 
        Texture = <SpecularTexture>; 
        AddressU = Wrap; 
        AddressV = Wrap; 
        FILTER = MIN_MAG_MIP_LINEAR; 
    };

float3 Light1Position3DSMax : POSITION 
    < 
    string UIName = "Light 1 position"; 
    string Object = "PointLight"; 
    string Space = "World"; 
    int refID = 1; 
    > = { 1.0, 0.0, 0.0 }; 

struct LightStruct
{
    float3 LightVector;
    float4 LightColor;
};

struct VS_INPUT
{
    float3 Position         : POSITION;
    int4   BoneIndices      : BLENDINDICES;
    float4 BoneWeights      : BLENDWEIGHT;
    float3 Normal           : NORMAL;
    float3 Tangent          : TANGENT;
    float3 Binormal         : BINORMAL;
    float2 DiffuseTexCoord0  : TEXCOORD0;
    float2 DiffuseTexCoord1  : TEXCOORD1;
    float3 Color            : TEXCOORD2;
    float3 Color            : COLOR0;
    float3 Color            : VPOS;
};