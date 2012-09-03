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
    using std::string;
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
	:	'VertexShader' '=' 'compile' 'vs_3_0' ID '(' shader_definition_parameter_list? ')' ';' { Listener->SetVertexShader( $ID.text ); };
        
pixel_shader_definition
	:    'PixelShader' '=' 'compile' 'ps_3_0' ID '(' shader_definition_parameter_list? ')' ';'{ Listener->SetPixelShader( $ID.text ); };

shader_definition_parameter_list
	: shader_definition_parameter ',' shader_definition_parameter_list
	| shader_definition_parameter
	;
	
shader_definition_parameter 
	: number
	| 'true'
	| 'false'
	;

type_definition
	:	'struct' ID LEFT_CURLY { Listener->StartTypeDefinition( $ID.text ); } field_declaration+ RIGHT_CURLY ';' { Listener->EndTypeDefinition(); }
	;
	
variable_declaration
	:	(variable_qualifier)? type variable_declaration_body[ $type.text ] ( ',' variable_declaration_body[ $type.text ] )* ';'
	|   type variable_declaration_body[ $type.text ] ( ',' variable_declaration_body[ $type.text ] )* ';'
	| 	texture_type ID ';' { Listener->Print( $texture_type.text + " \"" + $ID.text + "\"\n" ); }
	|	sampler;
	
variable_qualifier
	: 
	'shared'
	| 'const'
	;

variable_declaration_body [ StringType type_name ] @init{ int array_count = 0; }
	: ID ( '[' INT ']' { array_count = $INT.int; }  )? ( '=' initializer_list ) ? 
	{ Listener->DeclareVariable( type_name, $ID.text, array_count, $initializer_list.list ); }
	;
	
sampler	@init{ std::vector<SamplerParameter> parameter_table; }
	:	sampler_type ID ( '=' 'sampler_state' )? LEFT_CURLY ( sampler_parameter {parameter_table.push_back( $sampler_parameter.parameter ); } )* RIGHT_CURLY ';' 
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
	|	'texture2D'
	;

type	:	number_type
	|	ID
	;
	
field_declaration
	: 	type ID ':' semantic ';' { Listener->AddField( $type.text, $ID.text, $semantic.text ); }
	;
	
semantic 
	:	'POSITION'
	|	'NORMAL'
	|	'TEXCOORD0'
	|	'TEXCOORD1'
	|	'TEXCOORD2'
	|	'TEXCOORD3'
	| 	'COLOR0'
	| 	'COLOR1'
	| 	'COLOR2'
	| 	'COLOR3'
	|	'VPOS'
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
	:	( parameter_qualifier )? type ID {parameter.Type = $type.text; parameter.Name = $ID.text;} ( ':' semantic { parameter.Semantic = $semantic.text; } )?
	;
	
parameter_qualifier
	: 'uniform'
	;

statement
	:	variable_declaration
	|	'return' exp ';' { Listener->ProcessReturnStatement( $exp.text ); }
	| 	variable '=' exp { Listener->Print( $statement.text ); } ';'
	| 	variable assignment_operator_name exp 
	    { Listener->Print( 
	        $variable.text + " = " 
	        + $variable.text 
	        + $assignment_operator_name.operator_name 
	        + $exp.text );  
	    } ';'
	|	exp { Listener->Print( $exp.text ); } ';'
	| 	if_statement { Listener->Print( $if_statement.text ); } 
	| 	do_while_statement { Listener->Print( $do_while_statement.text ); } 
	;
	
if_statement
	:	'if' '(' exp ')' '{' statement* '}' 
		( 'elseif' '(' exp ')' '{' statement* '}' )* 
		( 'else' '{' statement* '}' ) ?
	;
	
do_while_statement : 
	'do' '{' statement* '}' 'while' '(' exp ')' ';' 
	;

exp
    :
    ( '-'? '(' exp ')'| right_value ) ( ( binary_operator | comparison_operator ) exp )*
	;
	
right_value 
	: 
	prefix_unary_operator? right_value_without_swizzle ( '.' SWIZZLE )? postfix_unary_operator?
	;
	
right_value_without_swizzle
	:
	constructor
	| function_call
	| variable
	| number
	;
	
SWIZZLE
	: ('x'|'y'|'z'|'w')+
	| ('r'|'g'|'b'|'a')+
	;
	
assignment_operator_name returns [string operator_name]
    :
    '+=' { operator_name = "+"; }
    | '-=' { operator_name = "-"; }
    | '*=' { operator_name = "*"; }
    | '/=' { operator_name = "/"; }
    ;
    	
binary_operator
	:
	'+'
	| '-'
	| '*'
	| '/'
	;
	
comparison_operator
	:
	'=='
	| '!='
	|'>'
	|'>='
	| '<'
	| '<='
	;

prefix_unary_operator
	:
	'-'
	| '--'
	| '++'
	;
	
postfix_unary_operator
	:
	'--'
	| '++' 
	;
	
variable options{ k=2; greedy=false; }
	:	variable_fragment ( '.' variable_fragment )* ( '.' SWIZZLE )?
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
	
initializer_list returns [string list] @init{ std::ostringstream list_stream; } 
	:
	number { list = $number.text; }
	| '(' type ')' exp { list = $type.text + '(' + $exp.text + ')'; }
	| '{' first=number{ list_stream << $first.text; } ( ',' other=number { list_stream << ", " << $other.text; } )* '}' { list = list_stream.str(); }
	;
	
ID  :	('a'..'z'|'A'..'Z'|'_') ('a'..'z'|'A'..'Z'|'0'..'9'|'_')*
    ;

number	
	:	FLOAT 
	|	INT
	;

INT :	'0'..'9'+
    ;
    
FLOAT 
    : FLOAT_NUMBER 'f'?  { std::string float_text = $FLOAT_NUMBER.text; if( float_text[float_text.length()-1] == '.' ) float_text += '0'; setText( float_text ); }
    ;
    
fragment
FLOAT_NUMBER
    :   ('-')?('0'..'9')+ '.' ('0'..'9')* EXPONENT? 
    |   ('-')?'.' ('0'..'9')+ EXPONENT?
    |   ('-')?('0'..'9')+ EXPONENT
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
