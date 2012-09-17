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
    static bool is_not_rgba( const char value )
    {
        return value != 'r' && value != 'g' && value != 'b' && value != 'a';
    }
    
    static bool is_not_xyzw( const char value )
    {
        return value < 'x' || value > 'w';
    }
    
    static bool IsValidSwizzle( const std::string & swizzle )
    {
        return 
            swizzle.size() <= 4
            && std::find_if( swizzle.begin(), swizzle.end(), is_not_rgba ) == swizzle.end()
            && std::find_if( swizzle.begin(), swizzle.end(), is_not_xyzw ) == swizzle.end();     
    }
    
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
	
// Statements

statement
    : ( lvalue_expression assignment_operator ) => assignment_statement
    | ( lvalue_expression self_modify_operator ) => post_modify_statement
    | variable_declaration
    | pre_modify_statement
    | expression_statement
    | block_statement
    | if_statement
    | iteration_statement
    | jump_statement
    | SEMI
    ;
  
assignment_statement
    :  lvalue_expression assignment_operator expression SEMI 
    ;
    
pre_modify_statement
    : pre_modify_expression SEMI 
    ;

pre_modify_expression
    : self_modify_operator lvalue_expression 
    ;

post_modify_statement
    : post_modify_expression SEMI 
    ;

post_modify_expression
    : lvalue_expression self_modify_operator 
    ;

self_modify_operator
    : PLUSPLUS 
    | MINUSMINUS 
    ;
  
block_statement
    : LCURLY (statement)* RCURLY
    ;
  
expression_statement
    : expression SEMI
    ;
    
if_statement
    : IF LPAREN expression RPAREN statement ( ELSE IF LPAREN expression RPAREN statement )* ( ELSE statement )?
    ;

iteration_statement
    : WHILE LPAREN expression RPAREN statement
    | FOR LPAREN ( assignment_statement | variable_declaration )
        equality_expression SEMI modify_expression RPAREN statement
    | DO statement WHILE LPAREN expression RPAREN SEMI
    ;
  
modify_expression
    : (lvalue_expression assignment_operator ) =>
        lvalue_expression assignment_operator expression
    | pre_modify_expression
    | post_modify_expression
    ;
    
jump_statement
    : BREAK SEMI
    | CONTINUE SEMI
    | RETURN ( expression )? SEMI
    | DISCARD SEMI
    ;
   
lvalue_expression
    : variable_expression ( postfix_suffix )? 
    ;

variable_expression
    : ID ( LBRACKET expression RBRACKET )? 
    ;

expression
    : conditional_expression 
    ;
  
conditional_expression
    : logical_or_expression ( QUESTION expression COLON conditional_expression )?
    ;

logical_or_expression
    : exclusive_or_expression ( OR exclusive_or_expression )*
    ;

logical_and_expression
    : ( NOT )? inclusive_or_expression ( AND ( NOT )? inclusive_or_expression )*
    ;

inclusive_or_expression
    : exclusive_or_expression (BITWISE_OR exclusive_or_expression )*
    ;

exclusive_or_expression
  : and_expression ( BITWISE_XOR and_expression )*
  ;

and_expression
    : equality_expression ( BITWISE_AND equality_expression )*
    ;

equality_expression
    : relational_expression ( (EQUAL|NOT_EQUAL) relational_expression )*
    ;

relational_expression
    : shift_expression ( (LT_TOKEN|GT|LTE|GTE) shift_expression )*
    ;

shift_expression
    : additive_expression ( (BITWISE_SHIFTL|BITWISE_SHIFTR) additive_expression )*
    ;

additive_expression
    : multiplicative_expression ( (PLUS|MINUS) multiplicative_expression )*
    ;

multiplicative_expression
    : cast_expression ( (MUL|DIV|MOD) cast_expression )*
    ;

cast_expression
    : LBRACKET type RBRACKET cast_expression
    | unary_expression
    ;

unary_expression
    : (PLUS|MINUS) unary_expression
    | postfix_expression
    ;

postfix_expression
    : primary_expression ( postfix_suffix )? 
    ;
  
postfix_suffix
    : ( DOT swizzle )
    | ( DOT primary_expression )+ ;
  
swizzle
    : ID { IsValidSwizzle( $ID.text ) }?
    ;
  
assignment_operator
    : ASSIGN
    | MUL_ASSIGN
    | DIV_ASSIGN
    | ADD_ASSIGN
    | SUB_ASSIGN
    | BITWISE_AND_ASSIGN
    | BITWISE_OR_ASSIGN
    | BITWISE_XOR_ASSIGN
    | BITWISE_SHIFTL_ASSIGN
    | BITWISE_SHIFTR_ASSIGN
    ;
  
primary_expression
    //: constructor
    : variable_expression
    | call_expression
    | literal_value
    | LPAREN expression RPAREN
    ;
  
call_expression
    : ID LPAREN argument_expression_list RPAREN
    ;

argument_expression_list
    : ( expression ( COMMA expression )* )? 
    ;
  
// Function

function_declaration 
    : storage_class* ( PRECISE )? ReturnValue=( type | VOID_TOKEN ) Name=ID LPAREN (argument_list)? RPAREN ( COLON SEMANTIC )?
    LCURLY
        statement*
    RCURLY
	;
	
argument_list
    : argument ( COMMA argument )* 
    ;
    
argument
    : input_modifier? type Name=ID ( COLON SEMANTIC )? ( INTERPOLATION_MODIFIER )? ( ASSIGN initial_value )?
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
        variable_declaration_body ( COMMA variable_declaration_body )* SEMI
	;
	
variable_declaration_body
    : ID ( LBRACKET INT RBRACKET )?
        ( COLON SEMANTIC ) ?
        ( COLON packoffset )?
        ( COLON register_rule ) ?
        annotations ?
        ( ASSIGN initial_value ) ?
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
    | LCURLY constant_expression ( COMMA constant_expression )* RCURLY
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
    LCURLY
        ( INTERPOLATION_MODIFIER? intrinsic_type MemberName=ID  ( COLON SEMANTIC )? SEMI )+ 
    RCURLY SEMI
    ;

constant_expression
  : (ID) => variable_expression
  | literal_value ;

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
  
SEMI:               ';';
COMMA:              ',';
COLON:              ':';
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
BREAK:              'break';
CONTINUE:           'continue';
RETURN:             'return';
DISCARD:            'discard';
DO:                 'do';
WHILE:              'while';
IF:                 'if';
ELSE:               'else';
FOR:                'for';
LBRACKET:           '[';
RBRACKET:           ']';
LPAREN:             '(';
RPAREN:             ')';
LCURLY:             '{';
RCURLY:             '}';
DOT:                '.';
ASSIGN:             '=';
MUL_ASSIGN:         '*=';
DIV_ASSIGN:         '/=';
ADD_ASSIGN:         '+=';
SUB_ASSIGN:         '-=';
BITWISE_AND_ASSIGN: '&=';
BITWISE_OR_ASSIGN:  '|=';
BITWISE_XOR_ASSIGN: '^=';
BITWISE_SHIFTL_ASSIGN: '<<=';
BITWISE_SHIFTR_ASSIGN: '>>=';
QUESTION:           '?';
MUL:                '*';
DIV:                '/';
PLUSPLUS:           '++';
MINUSMINUS:         '--';
PLUS:               '+';
MINUS:              '-';
MOD:                '%';
EQUAL:              '==';
NOT_EQUAL:          '!=';
AND:                '&&';
OR:                 '||';
NOT:                '!';
XOR:                '^^';
LT_TOKEN:           '<';
LTE:                '<=';
GT:                 '>';
GTE:                '>=';
BITWISE_AND:        '&';
BITWISE_OR:         '|';
BITWISE_XOR:        '^';
BITWISE_SHIFTL:     '<<';
BITWISE_SHIFTR:     '>>';
VOID_TOKEN:               'void';
    
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
    
