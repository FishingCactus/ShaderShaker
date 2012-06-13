#include "HLSLParserListener.h"




void HLSLParserListener::StartTechnique(
    const std::string & technique
    )
{
    ShaderOutput << "technique " << technique << std::endl << "{" << std::endl;
}

void HLSLParserListener::EndTechnique()
{
    ShaderOutput << "};" << std::endl;
}

void HLSLParserListener::StartPass(
    const std::string & pass_name
    )
{

}

void HLSLParserListener::EndPass()
{

}
    
void HLSLParserListener::SetVertexShader(
    const std::string& vertex_shader_name
    )
{

}
    
void HLSLParserListener::SetPixelShader(
    const std::string& vertex_shader_name
    )
{

}