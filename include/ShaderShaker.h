#ifndef SHADER_SHAKER_H
    #define SHADER_SHAKER_H

    #ifdef __cplusplus
        extern "C"{
    #endif

    struct ShaderShakerContext;

    ShaderShakerContext * ShaderShakerCreateContext( const char * output_file );
    ShaderShakerContext * ShaderShakerCreateContextWithLanguage( const char * language );
    void ShaderShakerDestroyContext( ShaderShakerContext * );
    void ShaderShakerSetFlag( ShaderShakerContext * context, const char * flag, bool value );
    bool ShaderShakerLoadShaderFile( ShaderShakerContext * context, const char * filename, const char * replace_shader_file_name );

    #ifdef __cplusplus
        };
    #endif
    

#endif
