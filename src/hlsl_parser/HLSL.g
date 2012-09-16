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
	#include <set>

}

@parser::members
{
    HLSLParserListener
        * Listener;
    std::set<std::string>
        TypeTable;
}

translation_unit
	: global_declaration* EOF
	;
	
global_declaration
	: variable_declaration
	| struct_definition
	| function_declaration
	;
	
// Function

function_declaration 
    : storage_class* ( PRECISE )? ReturnValue=type Name=ID '(' argument_list ')' ( ':' SEMANTIC )?
    '{'
        //[StatementBlock]
    '}'
	;
	
argument_list
    : argument ( ',' argument )* 
    ;
    
argument
    : input_modifier? type Name=ID ( ':' SEMANTIC )? ( INTERPOLATION_MODIFIER )? ( '=' initial_value )?
    ;
    
input_modifier
    : IN
    | OUT
    | INOUT
    | UNIFORM
    ;

// Variables

variable_declaration
    : storage_class* type_modifier* type 
        variable_declaration_body ( ',' variable_declaration_body )* ';'
	;
	
variable_declaration_body
    : ID ( '[' INT ']' )?
        ( ':' SEMANTIC ) ?
        ( ':' packoffset )?
        ( ':' register_rule ) ?
        annotations ?
        ( '=' initial_value ) ?
    ;
	 
storage_class
    : EXTERN
    | NOINTERPOLATION
    | PRECISE
    | SHARED
    | GROUPSHARED
    | STATIC
    | UNIFORM
    | VOLATILE
    ;
    
type_modifier
    : 'const'
    | 'row_major'
    | 'column_major'
    ;

packoffset
    :;
    
register_rule
    :;

annotations
    :;
        
initial_value
    : constant_expression
    | '{' constant_expression ( ',' constant_expression )* '}'
    ;
    
type
    : intrinsic_type 
    | user_defined_type
    ;
   
intrinsic_type 
    : MATRIX_TYPE
    | VECTOR_TYPE
    | SCALAR_TYPE
    ;
    
user_defined_type // :TODO: validates that it's a valid type
    : ID  { TypeTable.find( $ID.text) != TypeTable.end() }? => 
    ;
    
struct_definition
    : 'struct' Name=ID { TypeTable.insert( $Name.text ); } 
    '{'
        ( INTERPOLATION_MODIFIER? intrinsic_type MemberName=ID  ( ':' SEMANTIC )? ';' )+ 
    '}' ';'
    ;

constant_expression
  : //(ID) => variable_expression
  //| 
  literal_value ;

literal_value
  : FLOAT
  | INT
  ;

SEMANTIC
    : 'POSITION'
    | 'NORMAL'
    | 'SV_POSITION'
    | 'COLOR' ('0'..'4')?
    | 'TEXCOORD' ('0'..'8')?
    ;
  

EXTERN:             'extern';
NOINTERPOLATION:    'nointerpolation';
PRECISE:            'precise';
SHARED:             'shared';
GROUPSHARED:        'groupshared';
STATIC:             'static';
UNIFORM:            'uniform';
VOLATILE:           'volatile';
IN:                 'in';
OUT:                'out';
INOUT:              'inout';
    
INTERPOLATION_MODIFIER  
    : 'linear'
    | 'centroid'
    | 'nointerpolation'
    | 'noperspective'
    | 'sample'
    ;
    
MATRIX_TYPE
    : VECTOR_TYPE 'x' INDEX
    ;
    
VECTOR_TYPE
    : SCALAR_TYPE INDEX
    ;
    
SCALAR_TYPE
    : 'bool'
    | 'int'
    | 'float'
    | 'double'
    ;
    
ID  :	('a'..'z'|'A'..'Z'|'_') ('a'..'z'|'A'..'Z'|'0'..'9'|'_')*
    ;

INT :	'0'..'9'+
    ;
    
FLOAT 
    : FLOAT_NUMBER 'f'?
    ;
    
fragment 
INDEX
    :  '1' | '2' | '3' | '4'
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
    
