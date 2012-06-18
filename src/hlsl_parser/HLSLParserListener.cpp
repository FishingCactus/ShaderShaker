#include "HLSLParserListener.h"
#include "HLSLParser.hpp"


HLSLParserListener::HLSLParserListener()
{
    SimpleTypeTable.insert( "float" );
    SimpleTypeTable.insert( "float2" );
    SimpleTypeTable.insert( "float3" );
    SimpleTypeTable.insert( "float4" );
    SimpleTypeTable.insert( "float1x1" );
    SimpleTypeTable.insert( "float1x2" );
    SimpleTypeTable.insert( "float1x3" );
    SimpleTypeTable.insert( "float1x4" );
    SimpleTypeTable.insert( "float2x1" );
    SimpleTypeTable.insert( "float2x2" );
    SimpleTypeTable.insert( "float2x3" );
    SimpleTypeTable.insert( "float2x4" );
    SimpleTypeTable.insert( "float3x1" );
    SimpleTypeTable.insert( "float3x2" );
    SimpleTypeTable.insert( "float3x3" );
    SimpleTypeTable.insert( "float3x4" );
    SimpleTypeTable.insert( "float4x1" );
    SimpleTypeTable.insert( "float4x2" );
    SimpleTypeTable.insert( "float4x3" );
    SimpleTypeTable.insert( "float4x4" );
    SimpleTypeTable.insert( "int" );
}

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
    CurrentType = new TypeDefinition;

    TypeTable[ type_name ] = CurrentType;
}

// ~~

void HLSLParserListener::EndTypeDefinition()
{
    CurrentType = 0;
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
            std::map<std::string, TypeDefinition* >::const_iterator
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

void HLSLParserListener::DeclareVariable(
    const std::string & type,
    const std::string & name,
    const int array_item_count, // 0 means not an array
    const std::string & initializer
    )
{
    if( IsSimpleType( type ) )
    {
        ShaderOutput << "local " << name << " = " << type << "( " << initializer << " )" << std::endl;
    }
    else
    {
        std::map<std::string, TypeDefinition* >::const_iterator
            return_type;

        return_type = TypeTable.find( type );

        assert( return_type != TypeTable.end() );

        const TypeDefinition
            & type_definition = *return_type->second;

        ShaderOutput << "local " << name << " = " << "DefineStructure( \"" << name << "\" )\n";

        for( size_t field_index = 0; field_index < type_definition.FieldTable.size(); ++field_index )
        {
            ShaderOutput << "StructureAttribute( \"" 
                << type_definition.FieldTable[ field_index ].Name << "\", \""
                << type_definition.FieldTable[ field_index ].Type << "\", \"" 
                << type_definition.FieldTable[ field_index ].Semantic << "\" )\n";
        }

        ShaderOutput << "EndStructure()\n";
    }
}

// ~~

void HLSLParserListener::Print( 
    const std::string & text 
    )
{
    ShaderOutput << text << "\n";
}

// ~~

bool HLSLParserListener::IsSimpleType(
    const std::string & type
    ) const
{
    return SimpleTypeTable.find( type ) != SimpleTypeTable.end();
}


