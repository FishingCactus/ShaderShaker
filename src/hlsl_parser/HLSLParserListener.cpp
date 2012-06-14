#include "HLSLParserListener.h"




void HLSLParserListener::StartTechnique(
    const std::string & technique
    )
{
    ShaderOutput << "technique " << "{" << std::endl;
    ShaderOutput << "\tname = \"" << technique << "\",\n";
}

void HLSLParserListener::EndTechnique()
{
    ShaderOutput << "}" << std::endl;
}

void HLSLParserListener::StartPass(
    const std::string & /*pass_name*/
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
    ShaderOutput << "\tvs = " << vertex_shader_name << "(),\n";
}
    
void HLSLParserListener::SetPixelShader(
    const std::string& vertex_shader_name
    )
{
    ShaderOutput << "\tps = " << vertex_shader_name << "(),\n";
}

void HLSLParserListener::StartTypeDefinition(
    const std::string & type_name
    )
{
    CurrentType = std::shared_ptr<TypeDefinition>( new TypeDefinition );

    TypeTable[ type_name ] = CurrentType;
}

// ~~

void HLSLParserListener::EndTypeDefinition()
{
    CurrentType.reset();
}

// ~~

void HLSLParserListener::AddField(
    const std::string & type,
    const std::string & name,
    const std::string & semantic
    )
{
    FieldDefinition
        field_definition;

    field_definition.Type = type;
    field_definition.Name = name;
    field_definition.Semantic = semantic,

    CurrentType->FieldTable.push_back( field_definition );
}