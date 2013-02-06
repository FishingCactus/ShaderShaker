Texture SourceTexture1;
Texture1D SourceTexture2;
Texture1DArray SourceTexture3;
Texture2D SourceTexture4;
Texture2DArray SourceTexture5;
Texture3D SourceTexture6;
TextureCube SourceTexture7;

texture SourceTexture1;
texture1D SourceTexture2;
texture1DArray SourceTexture3;
texture2D SourceTexture4;
texture2DArray SourceTexture5;
texture3D SourceTexture6;
textureCube SourceTexture7;

sampler2D SourceTextureSampler
{ 
    Texture = <SourceTexture1>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = LINEAR;
};