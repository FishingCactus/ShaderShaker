#ifndef SHADER_SHAKER_H
    #define SHADER_SHAKER_H

    #ifdef __cplusplus
        extern "C"{
    #endif

    struct ShaderShakerContext;

    ShaderShakerContext * ShaderShakerCreateContext( int argc, const char** argv );
    void ShaderShakerDestroyContext( ShaderShakerContext * );
    bool ShaderShakerLoadShaderFile( ShaderShakerContext * context );

    #ifdef __cplusplus
        };
    #endif
    

#endif
