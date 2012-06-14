#include "HLSLParserListener.h"
#include "HLSLParser.hpp"




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

// Function

void HLSLParserListener::StartFunction(
    const std::string & type, 
    const std::string & name, 
    const std::vector<Parameter> & parameter_table,
    const std::string & semantic 
    )
{
    std::vector<Parameter>::const_iterator
        parameter,
        end;
    std::ostringstream
        parameter_list,
        input_table;
    bool
        it_has_input_definition,
        it_is_first_parameter;

    end = parameter_table.end();
    it_has_input_definition = false;
    it_is_first_parameter = true;

    for( parameter = parameter_table.begin(); parameter != end; ++parameter )
    {
        if( parameter->Semantic.empty() )
        {
            std::map<std::string, std::shared_ptr<TypeDefinition> >::const_iterator
                type;

            type = TypeTable.find( parameter->Type );

            if( type != TypeTable.end() )
            {
                const TypeDefinition
                    & type_definition = *type->second;

                for( size_t field_index = 0; field_index < type_definition.FieldTable.size(); ++field_index )
                {
                    input_table << "InputAttribute( \"" 
                        << type_definition.FieldTable[ field_index ].Name << "\", \""
                        << type_definition.FieldTable[ field_index ].Type << "\", \"" 
                        << type_definition.FieldTable[ field_index ].Semantic << "\" )\n";
                    it_has_input_definition = true;
                }
            }
            else
            {
                if( !it_is_first_parameter )
                {
                    parameter_list << ", ";
                }

                it_is_first_parameter = false;

                parameter_list << parameter->Name;

                //:TODO: Check argument type 
                
            }
        }
        else
        {
            input_table << "InputAttribute( \"" << parameter->Name << "\", \"" << parameter->Type << "\", \"" << parameter->Semantic << "\" )\n";
            it_has_input_definition = true;
        }
    }


    ShaderOutput << "function " << name << "(";
    
    ShaderOutput << ")\n";

    if( it_has_input_definition )
    {
        ShaderOutput << "DefineInput()\n";
        ShaderOutput << input_table.str();
        ShaderOutput << "EndInput()\n";
    }

    if( !semantic.empty() )
    {
        ShaderOutput << "__output = DefineStructure( \"__output\"  )\n";

        ShaderOutput << "StructureAttribute( \"value\", \"" 
            << type << "\", \"" 
            << semantic << "\" )\n";

        ShaderOutput << "EndStructure()\n";

        ItHasASimpleReturnValue = true;
    }
    else
    {
        ItHasASimpleReturnValue = false;
    }

}

/*
std::map<std::string, std::shared_ptr<TypeDefinition> >::const_iterator
return_type;

return_type = TypeTable.find( type );

assert( return_type != TypeTable.end() );

const TypeDefinition
& type_definition = *return_type->second;

ShaderOutput << "DefineStructure( \"" <<  << "\" )\n";

for( size_t field_index = 0; field_index < type_definition.FieldTable.size(); ++field_index )
{
ShaderOutput << "StructureAttribute( \"" 
<< type_definition.FieldTable[ field_index ].Name << "\", \""
<< type_definition.FieldTable[ field_index ].Type << "\", \"" 
<< type_definition.FieldTable[ field_index ].Semantic << "\" )\n";
}

ShaderOutput << "EndStructure()\n";
*/

// ~~

void HLSLParserListener::EndFunction()
{
    ShaderOutput << "end\n";
}

// ~~

void HLSLParserListener::ProcessReturnStatement(
    const std::string & return_statement
    )
{
    if( ItHasASimpleReturnValue )
    {
        ShaderOutput << "__output.value = " << return_statement << std::endl;
        ShaderOutput << "return __output" << std::endl;
    }
    else
    {
        ShaderOutput << "return " << return_statement << std::endl;
    }
}

// ~~

void HLSLParserListener::Print( 
    const std::string & text 
    )
{
    ShaderOutput << text << "\n";
}