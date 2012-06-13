#ifndef HLSLPARSERLISTENER
#define HLSLPARSERLISTENER

#include <string>
#include <sstream>

class HLSLParserListener
{
public:
    
    // Techique
    
    void StartTechnique(
        const std::string & technique_name
        );
        
    void EndTechnique();
    
    // Pass
    
    void StartPass(
        const std::string & pass_name
        );
        
    void EndPass();
    
    void SetVertexShader(
        const std::string& vertex_shader_name
        );
    
    void SetPixelShader(
        const std::string& vertex_shader_name
        );
        
    // Accessors
        
    std::string GetShaderOuput() const 
    {
        return ShaderOutput.str();
    }
        
private:

    std::ostringstream
        ShaderOutput;
    
};


#endif