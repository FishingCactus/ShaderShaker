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

    if( semantic.empty() )
    {
        std::map<std::string, std::shared_ptr<TypeDefinition> >::const_iterator
            return_type;

        return_type = TypeTable.find( type );

        assert( return_type != TypeTable.end() );
        
        const TypeDefinition
            & type_definition = *return_type->second;

        ShaderOutput << "DefineOutput()\n";

        for( size_t field_index = 0; field_index < type_definition.FieldTable.size(); ++field_index )
        {
            ShaderOutput << "OutputAttribute( \"" 
                << type_definition.FieldTable[ field_index ].Name << "\", \""
                << type_definition.FieldTable[ field_index ].Type << "\", \"" 
                << type_definition.FieldTable[ field_index ].Semantic << "\" )\n";
        }

        ShaderOutput << "EndOutput()\n";
    }
    else
    {
        ShaderOutput << "DefineOutput()\n";

        ShaderOutput << "OutputAttribute( \"result\", " 
                << type << "\", \"" 
                << semantic << "\" )\n";

        ShaderOutput << "EndOutput()\n";
    }

}

// ~~

void HLSLParserListener::EndFunction()
{

    ShaderOutput << "end\n";
}