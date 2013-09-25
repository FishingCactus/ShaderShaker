//

grammar HLSL;

options {
    backtrack = true;
    language = Cpp;
}

@lexer::traits
{
    #include <sstream>

    class HLSLLexer; class HLSLParser;

    template<class ImplTraits>
    class HLSLUserTraits : public antlr3::CustomTraitsBase<ImplTraits> {};

    class HLSLLexerTraits : public antlr3::Traits< HLSLLexer, HLSLParser, HLSLUserTraits >
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

    extern void ( *read_file_content_callback )( void * content, size_t & size, const char * );

    ANTLR_BEGIN_NAMESPACE()

    template<>
    class FileUtils< TraitsBase< HLSLUserTraits > > : public FileUtils< TraitsBase< CustomTraitsBase > >
    {
    public:
        typedef TraitsBase< HLSLUserTraits > ImplTraits;

        template<typename InputStreamType>
        static ANTLR_UINT32 AntlrRead8Bit(InputStreamType* input, const ANTLR_UINT8* fileName)
        {
            if ( read_file_content_callback )
            {
                size_t
                    length;
                void
                    * content;

                read_file_content_callback( NULL, length, ( const char * ) fileName );

                if ( !length )
                {
                    return ANTLR_FAIL;
                }

                content = InputStreamType::AllocPolicyType::alloc( length );
                read_file_content_callback( content, length, ( const char * ) fileName );

                input->set_data( (unsigned char*) content );
                input->set_sizeBuf( length );

                input->set_isAllocated( true );

                return  ANTLR_SUCCESS;
            }
            else
            {
                return FileUtils< TraitsBase< CustomTraitsBase > >::AntlrRead8Bit( input, fileName );
            }
        }
    };

    ANTLR_END_NAMESPACE()

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
        return value < 'w' || value > 'z';
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
    : {ast_push("shader_call");} Type=( VERTEX_SHADER|PIXEL_SHADER ) {ast_addvalue($Type.text);}
    ASSIGN COMPILE ShaderType=ID {ast_addvalue($ShaderType.text);}
    FunctionName=ID {ast_addvalue($FunctionName.text);}
    LPAREN shader_argument_list RPAREN SEMI {ast_assign();}
    ;

shader_argument_list
    : ( {ast_push("argument_expression_list");}shader_argument {ast_assign();}( COMMA shader_argument {ast_assign();} )* {ast_assign();} )?
    ;

shader_argument
    : constant_expression
    | constructor
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
    : {ast_push("expression_statement");} expression SEMI{ast_assign();}
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
        {ast_push();} lvalue_expression {ast_assign();} assignment_operator {ast_setname($assignment_operator.text + "_expression");} expression {ast_assign();}
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
    :  logical_and_expression ( {ast_push("||");ast_swap();ast_assign();} OR logical_and_expression {ast_assign();} )*
    ;

logical_and_expression
    : inclusive_or_expression ( AND {ast_push("&&"); ast_swap(); ast_assign();} inclusive_or_expression {ast_assign();} )*
    ;

inclusive_or_expression
    : exclusive_or_expression ( BITWISE_OR  {ast_push("|"); ast_swap(); ast_assign();} exclusive_or_expression{ast_assign();} )*
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
    : shift_expression ( op=(LT_TOKEN|GT_TOKEN|LTE|GTE){ast_push($op.text);ast_swap();ast_assign();} shift_expression{ast_assign();} )?
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
    : {ast_push("cast");}LPAREN type ( LBRACKET INT{ast_push("size"); ast_addvalue($INT.text); ast_assign(); }RBRACKET )? {ast_assign();} RPAREN cast_expression{ast_assign();}
    | unary_expression
    ;

unary_expression
    : op=(PLUS|MINUS|NOT|BITWISE_NOT){ast_push( "unary_" + $op.text);} unary_expression {ast_assign();}
    | postfix_expression
    ;

postfix_expression
    : primary_expression ( postfix_suffix )?
    ;

postfix_suffix
    : DOT swizzle { ast_push("swizzle");ast_swap();ast_assign();ast_addvalue($swizzle.text);}
    | DOT { ast_push("postfix");ast_swap();ast_assign();} primary_expression {ast_assign();} ( postfix_suffix )?
    ;

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
    : {ast_push("constructor");}type{ast_assign();} LPAREN argument_expression_list RPAREN
    ;

call_expression
    : {ast_push("call");}ID{ast_addvalue($ID.text);} LPAREN argument_expression_list RPAREN
    ;

argument_expression_list
    : ( {ast_push("argument_expression_list");}expression{ast_assign();} ( COMMA expression {ast_assign();} )* {ast_assign();} )?
    ;

// Function

function_declaration
    : { ast_push("function"); } storage_class* ( PRECISE )?
        ( type { ast_assign(); }| VOID_TOKEN {ast_push("type");ast_addvalue("void");ast_assign();} )
        ID{ ast_push("ID"); ast_addvalue($ID.text); ast_assign();}
        LPAREN ( {ast_push("argument_list");} argument_list {ast_assign();})? RPAREN
        ( COLON semantic )?
    LCURLY
        {ast_push("function_body");}( statement {ast_assign();} )*{ast_assign();}
    RCURLY
	;

argument_list
    : argument {ast_assign();} ( COMMA argument {ast_assign();} )*
    ;

argument
    : {ast_push("argument");} input_modifier? ( type_modifier {ast_push("modifier"); ast_addvalue($type_modifier.text); ast_assign();})? type{ast_assign();}
        Name=ID{ast_push("ID");ast_addvalue($ID.text);ast_assign();}
        ( COLON semantic )?
        ( INTERPOLATION_MODIFIER )? ( ASSIGN initial_value {ast_assign();} )?
    ;

input_modifier
    : modifier=( IN_TOKEN | OUT_TOKEN | INOUT | UNIFORM ) {ast_push("input_modifier");ast_addvalue($modifier.text);ast_assign();}
    ;

// Texture & sampler

texture_type
    :
    TEXTURE
    | TEXTURE1D
    | TEXTURE1DARRAY
    | TEXTURE2D
    | TEXTURE2DARRAY
    | TEXTURE3D
    | TEXTURECUBE
    ;

texture_declaration
    : t=texture_type ID
    {ast_push("texture_declaration");ast_push("type");ast_addvalue($t.text);ast_assign();ast_addvalue($ID.text);}
    ( COLON semantic ) ?
    ( { ast_push( "annotations" ); } annotations {ast_assign();} ) ?
    SEMI
    ;

sampler_declaration
    : {ast_push("sampler_declaration");}t=SAMPLER_TYPE{ast_push("type");ast_addvalue($t.text);ast_assign();}
        Name=ID{ast_addvalue($Name.text);} ( ASSIGN SAMPLER_TYPE )? LCURLY (sampler_body{ast_assign();})* RCURLY SEMI
    ;

sampler_body
    : TEXTURE ASSIGN LT_TOKEN ID GT_TOKEN SEMI { ast_push("texture");ast_addvalue($ID.text);}
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
    : {ast_push("variable");}ID{ast_addvalue($ID.text);}( LBRACKET INT{ast_push("size"); ast_addvalue($INT.text); ast_assign(); } RBRACKET )?
        ( COLON semantic ) ?
        ( COLON packoffset )?
        ( COLON register_rule ) ?
        ( { ast_push( "annotations" ); } annotations {ast_assign();} ) ?
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
    : LT_TOKEN annotation_entry* GT_TOKEN
    ;

annotation_entry
    :
    Type=( STRING_TYPE | SCALAR_TYPE ) ID {ast_push("entry");ast_addvalue($Type.text); ast_addvalue($ID.text); }
    ASSIGN ( STRING { ast_addvalue($STRING.text); } | literal_value {ast_assign();} ) SEMI {ast_assign();}
    ;

initial_value
    :
    expression
    | LCURLY {ast_push( "initial_value_table");}expression {ast_assign();} ( COMMA expression {ast_assign();} )* RCURLY
    ;

type
    : ( intrinsic_type | user_defined_type | SAMPLER_TYPE ) { ast_push("type"); ast_addvalue($type.text); }
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
        ( {ast_push("field");} INTERPOLATION_MODIFIER? type{ast_assign();} MemberName=ID{ast_push("ID");ast_addvalue($MemberName.text);ast_assign();}
            ( COLON semantic )? SEMI {ast_assign();} )+
    RCURLY SEMI
    ;

constant_expression
    : (ID) => variable_expression
    | literal_value
    ;

literal_value
    :  value=( FLOAT | INT | TRUE_TOKEN | FALSE_TOKEN )  { ast_push("literal"); ast_addvalue($value.text); }
    ;

semantic
    : SEMANTIC {ast_push("semantic"); ast_addvalue($SEMANTIC.text); ast_assign();}
    | ID {ast_push("user_semantic"); ast_addvalue($ID.text); ast_assign();}
    ;

SEMANTIC
    : 'POSITION' ('0'..'8')?
    | 'POSITIONT'
    | 'NORMAL' ('0'..'8')?
    | 'SV_POSITION'
    | 'COLOR' ('0'..'8')?
    | 'TEXCOORD' ('0'..'8')?
    | 'TESSFACTOR' ('0'..'8')?
    | 'PSIZE' ('0'..'8')?
    | 'DEPTH' ('0'..'8')?
    | 'VPOS'
    | 'VFACE'
    | 'FOG'
    | 'DIFFUSE'
    | 'TANGENT' ('0'..'8')?
    | 'BINORMAL' ('0'..'8')?
    | 'BLENDINDICES' ('0'..'8')?
    | 'BLENDWEIGHT' ('0'..'8')?
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
BITWISE_NOT:        '~';
XOR:                '^^';
LT_TOKEN:           '<';
LTE:                '<=';
GT_TOKEN:                 '>';
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

TEXTURE:            T 'exture';
TEXTURE1D:          T 'exture1D';
TEXTURE1DARRAY:     T 'exture1DArray';
TEXTURE2D:          T 'exture2D';
TEXTURE2DARRAY:     T 'exture2DArray';
TEXTURE3D:          T 'exture3D';
TEXTURECUBE:        T 'extureCube';


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

STRING_TYPE
    : 'string'
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

fragment
    T
    : 't' | 'T'
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

