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
	#include <algorithm>
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
            && ( 
                std::find_if( swizzle.begin(), swizzle.end(), is_not_rgba ) == swizzle.end()
                || std::find_if( swizzle.begin(), swizzle.end(), is_not_xyzw ) == swizzle.end()
                );
    }
    
    HLSLParserListener
        * Listener;
    std::set<std::string>
        TypeTable;
}

translation_unit
	: global_declaration* technique* EOF
	;
	
global_declaration
    : variable_declaration {ast_assign();}
	| texture_declaration {ast_assign();}
	| sampler_declaration {ast_assign();}
	| struct_definition {ast_assign();}
	| function_declaration {ast_assign();}
	;
	
technique
    : {ast_push("technique");} TECHNIQUE Name=ID {ast_addvalue($Name.text);} LCURLY pass* RCURLY {ast_assign();}
    ;
    
pass
    : {ast_push("pass");} PASS Name=ID {ast_addvalue($Name.text);} LCURLY shader_definition* RCURLY {ast_assign();}
    ;

shader_definition
    : {ast_push("shader_call");} TYPE=( VERTEX_SHADER|PIXEL_SHADER ) {ast_addvalue($TYPE.text);} 
    ASSIGN COMPILE SHADER_TYPE=ID {ast_addvalue($SHADER_TYPE.text);} 
    FUNCTION_NAME=ID {ast_addvalue($FUNCTION_NAME.text);} 
    LPAREN shader_argument_list? RPAREN SEMI {ast_assign();}
    //LPAREN argument_expression_list?{ast_assign();} RPAREN SEMI
    ;
    
shader_argument_list
    : constant_expression {ast_assign();}( COMMA constant_expression {ast_assign();} )*
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
    :  {ast_push();} lvalue_expression{ast_assign();} assignment_operator{ast_setname($assignment_operator.text + "_statement");} expression{ast_assign();}  SEMI 
    ;
    
pre_modify_statement
    : pre_modify_expression SEMI {ast_setname( "pre_modify_statement" );}
    ;

pre_modify_expression
    : {ast_push("pre_modify");} self_modify_operator{ast_addvalue($self_modify_operator.text);} lvalue_expression{ast_assign();}
    ;

post_modify_statement
    : post_modify_expression SEMI {ast_setname( "post_modify_statement" );}
    ;

post_modify_expression
    : {ast_push("post_modify");}lvalue_expression {ast_assign();} self_modify_operator {ast_addvalue($self_modify_operator.text);}
    ;

self_modify_operator
    : PLUSPLUS 
    | MINUSMINUS 
    ;
  
block_statement
    : {ast_push("block");}LCURLY (statement{ast_assign();})* RCURLY
    ;
  
expression_statement
    : expression SEMI
    ;
    
if_statement
    : IF LPAREN {ast_push("if");ast_push("if_block");} expression {ast_assign();} RPAREN statement{ast_assign();ast_assign();}  
        ( ELSE IF LPAREN {ast_push("else_if_block");}expression {ast_assign();} RPAREN statement {ast_assign();ast_assign();} )* 
        ( ELSE {ast_push("else_block");} statement {ast_assign();ast_assign();} )?
    ;

iteration_statement
    : WHILE {ast_push("while");} LPAREN expression{ast_assign();} RPAREN statement{ast_assign();}
    | FOR LPAREN {ast_push("for");}( assignment_statement | variable_declaration ){ast_assign();}
        equality_expression{ast_assign();} SEMI modify_expression{ast_assign();} RPAREN statement{ast_assign();}
    | DO {ast_push("do_while");}statement{ast_assign();} WHILE LPAREN expression{ast_assign();} RPAREN SEMI
    ;
  
modify_expression
    : (lvalue_expression assignment_operator ) =>
        lvalue_expression assignment_operator expression
    | pre_modify_expression
    | post_modify_expression
    ;
    
jump_statement
    : BREAK SEMI {ast_push("break");}
    | CONTINUE SEMI  {ast_push("continue");}
    | RETURN {ast_push("return");} ( expression {ast_assign();} )? SEMI 
    | DISCARD SEMI  {ast_push("discard");}
    ;
   
lvalue_expression
    : variable_expression ( postfix_suffix )? 
    ;

variable_expression
    : {ast_push("variable");} ID{ast_addvalue($ID.text);}( LBRACKET {ast_push("index");}expression {ast_assign();ast_assign();}RBRACKET )? 
    ;

expression
    : conditional_expression 
    ;
  
conditional_expression
    : logical_or_expression ( { ast_push("inline_if");ast_swap();ast_assign();} QUESTION expression{ast_assign();} COLON conditional_expression {ast_assign();} )?
    ;

logical_or_expression
    :  exclusive_or_expression ( {ast_push("||");ast_swap();ast_assign();} OR logical_or_expression {ast_assign();} )*
    ;

logical_and_expression
    : not_expression ( AND {ast_push("&&"); ast_swap(); ast_assign();} not_expression {ast_assign();} )*
    ;
    
not_expression 
    : NOT {ast_push( "!" );} inclusive_or_expression {ast_assign();} 
    | inclusive_or_expression;

inclusive_or_expression
    : exclusive_or_expression ( BITWISE_OR  {ast_push("|"); ast_swap(); ast_assign();} inclusive_or_expression{ast_assign();} )*
    ;

exclusive_or_expression
  : and_expression ( BITWISE_XOR  {ast_push("^"); ast_swap(); ast_assign();} and_expression{ast_assign();})*
  ;

and_expression
    : equality_expression ( BITWISE_AND {ast_push("&"); ast_swap(); ast_assign();} equality_expression {ast_assign();})*
    ;

equality_expression
    : relational_expression (op=(EQUAL|NOT_EQUAL) {ast_push($op.text);ast_swap();ast_assign();} relational_expression{ast_assign();} )*
    ;

relational_expression
    : shift_expression ( op=(LT_TOKEN|GT|LTE|GTE){ast_push($op.text);ast_swap();ast_assign();} shift_expression{ast_assign();} )?
    ;

shift_expression
    : additive_expression (op=(BITWISE_SHIFTL|BITWISE_SHIFTR){ast_push($op.text);ast_swap();ast_assign();} additive_expression{ast_assign();} )*
    ;

additive_expression
    : multiplicative_expression ( op=(PLUS|MINUS){ast_push($op.text);ast_swap();ast_assign();} multiplicative_expression{ast_assign();} )*
    ;

multiplicative_expression
    : cast_expression ( op=(MUL|DIV|MOD) {ast_push($op.text);ast_swap();ast_assign();} cast_expression{ast_assign();} )*
    ;

cast_expression
    : {ast_push("cast");}LPAREN type {ast_assign();} RPAREN cast_expression{ast_assign();}
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
    : DOT swizzle { ast_push("swizzle");ast_swap();ast_assign();ast_addvalue($swizzle.text);}
    | ( DOT { ast_push("postfix");ast_swap();ast_assign();} primary_expression {ast_assign();} )+ ;
  
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
    : constructor
    | call_expression
    | variable_expression
    | literal_value
    | LPAREN expression RPAREN
    ;
    
constructor 
    : {ast_push("constructor");}type{ast_assign();} LPAREN argument_expression_list{ast_assign();} RPAREN
    ;
  
call_expression
    : {ast_push("call");}ID{ast_addvalue($ID.text);} LPAREN argument_expression_list{ast_assign();} RPAREN
    ;

argument_expression_list
    : ( {ast_push("argument_expression_list");}expression{ast_assign();} ( COMMA expression {ast_assign();} )* )? 
    ;
  
// Function

function_declaration 
    : { ast_push("function"); } storage_class* ( PRECISE )? 
        ( type { ast_assign(); }| VOID_TOKEN {ast_push("type");ast_addvalue("void");ast_assign();} ) 
        ID{ ast_push("ID"); ast_addvalue($ID.text); ast_assign();} 
        LPAREN ( {ast_push("argument_list");} argument_list {ast_assign();})? RPAREN ( COLON SEMANTIC )?
    LCURLY
        {ast_push("function_body");}( statement {ast_assign();} )*{ast_assign();}
    RCURLY
	;
	
argument_list
    : argument {ast_assign();} ( COMMA argument {ast_assign();} )* 
    ;
    
argument
    : {ast_push("argument");} input_modifier? type{ast_assign();} 
        Name=ID{ast_push("ID");ast_addvalue($ID.text);ast_assign();} 
        ( COLON SEMANTIC {ast_push("semantic");ast_addvalue($SEMANTIC.text);ast_assign();} )? 
        ( INTERPOLATION_MODIFIER )? ( ASSIGN initial_value {ast_assign();} )?
    ;
    
input_modifier
    : IN_TOKEN
    | OUT_TOKEN
    | INOUT
    | UNIFORM
    ;

// Texture & sampler

texture_declaration
    : t=TEXTURE_TYPE ID SEMI{ast_push("texture_declaration");ast_push("type");ast_addvalue($t.text);ast_assign();ast_addvalue($ID.text);}
    ;
    
sampler_declaration
    : {ast_push("texture_declaration");}t=SAMPLER_TYPE{ast_push("type");ast_addvalue($t.text);ast_assign();} 
        Name=ID{ast_addvalue($Name.text);} ( ASSIGN SAMPLER_TYPE )? LCURLY (sampler_body{ast_assign();})* RCURLY SEMI
    ;
    
sampler_body
    : 'Texture' ASSIGN '<' ID '>' SEMI { ast_push("texture");ast_addvalue($ID.text);}
    | Name=ID ASSIGN Value=ID SEMI  { ast_push("parameter");ast_addvalue($Name.text);ast_addvalue($Value.text);}
    ;
    
// Variables

variable_declaration
    : {ast_push("variable_declaration");} 
        {ast_push("storage");}(storage_class {ast_addvalue($storage_class.text);} )*{ast_assign();} 
        {ast_push("modifier");} ( type_modifier {ast_addvalue($type_modifier.text);} )* {ast_assign();}
        type{ast_assign();}
        variable_declaration_body{ast_assign();} ( COMMA variable_declaration_body{ast_assign();} )* SEMI
	;
	
variable_declaration_body
    : {ast_push("variable");}ID{ast_addvalue($ID.text);}( LBRACKET INT{ast_set("size", $INT.text);} RBRACKET )?
        ( COLON SEMANTIC {ast_set("semantic", $INT.text);} ) ?
        ( COLON packoffset )?
        ( COLON register_rule ) ?
        annotations ?
        ( ASSIGN initial_value {ast_assign();} ) ?
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
    : 
    expression
    | LCURLY {ast_push( "initial_value_table");}expression {ast_assign();} ( COMMA expression {ast_assign();} )* RCURLY
    ;
    
type
    : ( intrinsic_type | user_defined_type ) { ast_push("type"); ast_addvalue($type.text); }
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
    : STRUCT {ast_push("struct_definition");} Name=ID { TypeTable.insert( $Name.text ); ast_addvalue( $Name.text ); } 
    LCURLY
        ( {ast_push("field");} INTERPOLATION_MODIFIER? type{ast_assign();} MemberName=ID{ast_addvalue($MemberName.text);}  
            ( COLON SEMANTIC {ast_push("semantic"); ast_addvalue($SEMANTIC.text); ast_assign();})? SEMI {ast_assign();} )+ 
    RCURLY SEMI
    ;

constant_expression
    : (ID) => variable_expression
    | literal_value 
    ;
    
literal_value
    :  value=( FLOAT | INT | TRUE_TOKEN | FALSE_TOKEN )  { ast_push("literal"); ast_addvalue($value.text); }
    ;

SEMANTIC
    : 'POSITION'
    | 'NORMAL'
    | 'SV_POSITION'
    | 'COLOR' ('0'..'4')?
    | 'TEXCOORD' ('0'..'8')?
    | 'VPOS'
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
IN_TOKEN:           'in';
OUT_TOKEN:          'out';
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
TECHNIQUE:          'technique';
PASS:               'pass';
VERTEX_SHADER:      'VertexShader';
PIXEL_SHADER:       'PixelShader';
COMPILE:            'compile'; 
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
VOID_TOKEN:         'void';
TRUE_TOKEN:         'true';
FALSE_TOKEN:        'false';
STRUCT:             'struct';

TEXTURE_TYPE
    : 
    'texture'
    | 'texture1D'
    | 'texture1DArray'
    | 'texture2D'
    | 'texture2DArray'
    | 'texture3D'
    | 'textureCube'
    ;
    
SAMPLER_TYPE
    : 'sampler'
    | 'sampler1D'
    | 'sampler2D'
    | 'sampler3D'
    | 'samplerCUBE'
    | 'sampler_state'
    | 'SamplerState'
    ;
    
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
    
