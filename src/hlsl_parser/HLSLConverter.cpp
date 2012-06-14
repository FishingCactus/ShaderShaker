#include "HLSLConverter.h"
#include "HLSLLexer.hpp"
#include "HLSLParser.hpp"


int HLSLConverter::ConvertHLSLToSSL(
    lua_State * lua_state
    )
{
    HLSLConverter
        converter;
        
    converter.ConvertToShaderShakerLanguage( lua_tostring( lua_state, -1 ) );
    
    lua_pushstring( lua_state, converter.GetConvertedCode().c_str() );
    OutputDebugString( converter.GetConvertedCode().c_str() );
    
    return 1;   
}

void HLSLConverter::ConvertToShaderShakerLanguage(
    const std::string & filename
    )
{
    HLSLLexerTraits::InputStreamType input( (ANTLR_UINT8*)filename.c_str(), ANTLR_ENC_8BIT);
    HLSLLexer lexer(&input); // TLexerNew is generated by ANTLR
    HLSLLexerTraits::TokenStreamType token_stream(ANTLR_SIZE_HINT, lexer.get_tokSource() );
    HLSLParser parser(&token_stream); // TParserNew is generated by ANTLR3

    parser.Listener = &Listener;
    parser.translation_unit();
}