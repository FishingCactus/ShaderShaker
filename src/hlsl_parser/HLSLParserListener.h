#ifndef HLSLPARSERLISTENER
#define HLSLPARSERLISTENER

#include <string>
#include <sstream>
#include <vector>
#include <map>
struct Parameter;

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


    // Types

    void StartTypeDefinition(
        const std::string & type_name
        );

    // ~~

    void EndTypeDefinition();

    // ~~

    void AddField(
        const std::string & type,
        const std::string & name,
        const std::string & semantic
        );

    // Function

    void StartFunction(
        const std::string & type, 
        const std::string & name, 
        const std::vector<Parameter> & parameter_table,
        const std::string & semantic 
        );

    // ~~

    void EndFunction();
        
    // Accessors
        
    std::string GetShaderOuput() const 
    {
        return ShaderOutput.str();
    }
        
private:

    struct FieldDefinition
    {
        std::string 
            Type,
            Name,
            Semantic;
    };

    struct TypeDefinition
    {
        std::vector< FieldDefinition >
            FieldTable;
    };

    std::ostringstream
        ShaderOutput;
    std::map<std::string, std::shared_ptr<TypeDefinition> >
        TypeTable;
    std::shared_ptr<TypeDefinition>
        CurrentType;
    
};


#endif