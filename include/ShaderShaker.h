#ifndef SHADER_SHAKER_H
    #define SHADER_SHAKER_H

    #ifdef __cplusplus
        extern "C"{
    #endif

    struct ShaderShakerContext;

    ShaderShakerContext * ShaderShakerCreateContext( int argc, const char* const * argv );
    ShaderShakerContext * ShaderShakerCreateContextWithLanguage( const char * language );
    void ShaderShakerDestroyContext( ShaderShakerContext * context );
    const char * ShaderShakerGetProcessedCode( ShaderShakerContext * context, int file_index );
    bool ShaderShakerLoadShaderFile( ShaderShakerContext * context );


    #ifdef __cplusplus
        };
    #endif
    

#endif
