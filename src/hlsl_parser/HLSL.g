grammar HLSL;

options {
    backtrack = true;
    language = Cpp;
}

@lexer::traits 
{
    #include <sstream>

    class HLSLLexer; class HLSLParser;

    class HLSLLexerTraits : public antlr3::Traits< HLSLLexer, HLSLParser > 
    {
        public:
                                               
        static int ConvertToInt32( const std::string & type )
        {
            int 
                return_value;
        
            std::istringstream( type ) >> return_value;

            return return_value;
        }
    };

    typedef HLSLLexerTraits HLSLParserTraits;
}

@parser::includes
{
    #include "HLSLLexer.hpp"
    #include "HLSLParserListener.h"
    #include <iostream>
	#include <string>
   
    struct Parameter
    {
		std::string
			Type,
			Name,
			Semantic;
	};
	
	struct SamplerParameter
	{
	    std::string
	        Name,
	        Value;
	};
}

@parser::members
{
    HLSLParserListener
        * Listener;
}

translation_unit
	:	global_declaration* technique*
	;
	
global_declaration
	:	type_definition
	|	variable_declaration
	|	function
	;
	
technique
	:	'technique' ID LEFT_CURLY { Listener->StartTechnique( $ID.text ); } ( pass )* RIGHT_CURLY { Listener->EndTechnique(); }
	;

pass 	:	'pass' ID { Listener->StartPass( $ID.text ); } LEFT_CURLY vertex_shader_definition pixel_shader_definition RIGHT_CURLY { Listener->EndPass(); }
	;
	
vertex_shader_definition
	:	'VertexShader' '=' 'compile' 'vs_3_0' ID '(' ')' ';' { Listener->SetVertexShader( $ID.text ); };
        
pixel_shader_definition
	:    'PixelShader' '=' 'compile' 'ps_3_0' ID '(' ')' ';'{ Listener->SetPixelShader( $ID.text ); };

type_definition
	:	'struct' ID LEFT_CURLY { Listener->StartTypeDefinition( $ID.text ); } field_declaration+ RIGHT_CURLY ';' { Listener->EndTypeDefinition(); }
	;
	
variable_declaration
	:	type variable_declaration_body[ $type.text ] ( ',' variable_declaration_body[ $type.text ] )* ';'
	| 	texture_type ID ';' { Listener->Print( $texture_type.text + " \"" + $ID.text + "\"\n" ); }
	|	sampler;
	
variable_declaration_body [ StringType type_name ] @init{ int array_count = 0; }
	: ID ( '[' INT ']' { array_count = $INT.int; }  )? ( '=' initializer_list ) ? 
	{ Listener->DeclareVariable( type_name, $ID.text, array_count, $initializer_list.text ); }
	;
	
sampler	@init{ std::vector<SamplerParameter> parameter_table; }
	:	sampler_type ID LEFT_CURLY ( sampler_parameter {parameter_table.push_back( $sampler_parameter.parameter ); } )* RIGHT_CURLY ';' 
	{ Listener->DeclareSampler( $sampler_type.text, $ID.text, parameter_table ); }
	;
	
sampler_type 
	:	'sampler2D'
	;
	
sampler_parameter returns [ SamplerParameter parameter ]
	:	'Texture' '=' '<' ID '>' ';' { parameter.Name = "texture"; parameter.Value = $ID.text; }
	|	name=ID '=' value=ID ';' { parameter.Name = $name.text; parameter.Value = $value.text; }
	; 
number_type	
	:	'float'
	|	'float2'
	|	'float3'
	|	'float4'
	|	'float1x1'
	|	'float1x2'
	;
	
texture_type
	:	'Texture'
	;

type	:	number_type
	|	ID
	;
	
field_declaration
	: 	type ID ':' semantic ';' { Listener->AddField( $type.text, $ID.text, $semantic.text ); }
	;
	
semantic 
	:	'POSITION'
	|	'TEXCOORD0'
	| 	'COLOR0'
	;
	
function 
		@init{ std::vector<Parameter> parameter_table; }
	:
		type ID '(' 
			( first = parameter_declaration { parameter_table.push_back( $first.parameter ); }
			( ',' other = parameter_declaration { parameter_table.push_back( $other.parameter ); } )* )? 
			')' ( ':' semantic )? '{' 
			{ Listener->StartFunction( $type.text, $ID.text, parameter_table, $semantic.text ); }
			statement* 
			
			{ Listener->EndFunction(); }
			'}';
	
parameter_declaration returns [ Parameter parameter ]
	:	type ID {parameter.Type = $type.text; parameter.Name = $ID.text;} ( ':' semantic { parameter.Semantic = $semantic.text; } )?
	;

statement
	:	variable_declaration
	|	'return' exp ';' { Listener->ProcessReturnStatement( $exp.text ); }
	| 	variable assignment_operator_name exp { Listener->Print( $statement.text ); } ';'
	|	exp { Listener->Print( $exp.text ); } ';'
	;
	
exp
    :
	right_value ( operator_name right_value )*
	;
	
right_value : 
	constructor
	| function_call
	| variable
	| number
	;
	
assignment_operator_name
    :
    '='
    | '+='
    | '-='
    | '*='
    | '/='
    ;
    	
operator_name
	:
	'+'
	| '-'
	| '*'
	| '/'
	;
	
variable 
	:	variable_fragment ( '.' variable_fragment )*
	;

variable_fragment
    :   ID ( '[' INT ']' )?
    ;
	
function_call
	:	ID '(' ( exp ( ',' exp )* )? ')'
	;
	
constructor 
	:	number_type '(' exp  ( ',' exp )* ')' 
	;
	
initializer_list 
	:
	'{' number ( ',' number )* '}'
	;
	
ID  :	('a'..'z'|'A'..'Z'|'_') ('a'..'z'|'A'..'Z'|'0'..'9'|'_')*
    ;

number	
	:	FLOAT
	|	INT
	;

INT :	'0'..'9'+
    ;

FLOAT_NUMBER
    :   ('0'..'9')+ '.' ('0'..'9')* EXPONENT? 
    |   '.' ('0'..'9')+ EXPONENT?
    |   ('0'..'9')+ EXPONENT
    ;
    
FLOAT 
    : FLOAT_NUMBER 'f'?  { setText( $FLOAT_NUMBER.text ); }
    ;

COMMENT
    :   '//' ~('\n'|'\r')* '\r'? '\n' {$channel=HIDDEN;}
    |   '/*' ( options {greedy=false;} : . )* '*/' {$channel=HIDDEN;}
    ;

WS  :  (' '|'\r'|'\t'|'\u000C'|'\n') {$channel=HIDDEN;}
    ;

STRING
    :  '"' ( ESC_SEQ | ~('\\'|'"') )* '"'
    ;

fragment
EXPONENT : ('e'|'E') ('+'|'-')? ('0'..'9')+ ;

fragment
HEX_DIGIT : ('0'..'9'|'a'..'f'|'A'..'F') ;

fragment
ESC_SEQ
    :   '\\' ('b'|'t'|'n'|'f'|'r'|'\"'|'\''|'\\')
    |   OCTAL_ESC
    ;

fragment
OCTAL_ESC
    :   '\\' ('0'..'3') ('0'..'7') ('0'..'7')
    |   '\\' ('0'..'7') ('0'..'7')
    |   '\\' ('0'..'7')
    ;

LEFT_CURLY
	:	'{'
	;

RIGHT_CURLY
	:	'}'
	;
