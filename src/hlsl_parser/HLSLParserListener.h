#ifndef HLSLPARSERLISTENER
#define HLSLPARSERLISTENER

#include <string>
#include <sstream>
#include <vector>
#include <map>
#include <set>
struct Parameter;
struct SamplerParameter;

class HLSLParserListener
{
public:

    HLSLParserListener();
    
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

    // ~~

    void ProcessReturnStatement(
        const std::string & return_statement
        );
        
    // ~~

    void DeclareVariable(
        const std::string & type,
        const std::string & name,
        const int array_item_count, // 0 means not an array
        const std::string & initializer
        );
        
    // ~~
        
    void DeclareSampler(
        const std::string & type,
        const std::string & name,
        const std::vector<SamplerParameter> & parameter
        );

    // ~~

    void Print( 
        const std::string & text 
        );
        
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
    
    bool IsSimpleType(
        const std::string & type
        ) const;

    std::ostringstream
        ShaderOutput;
    std::map<std::string, TypeDefinition* >
        TypeTable;
    std::set<std::string>
        SimpleTypeTable;
    TypeDefinition
        * CurrentType;
    bool
        ItHasASimpleReturnValue;
    
};


#endif