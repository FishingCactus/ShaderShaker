#include "HLSLParserListener.h"
#include "HLSLParser.hpp"


HLSLParserListener::HLSLParserListener( lua_State * state ) : State( state )
{

}

void HLSLParserListener::PushNode()
{
    lua_checkstack( State, 1 );
    lua_newtable( State );
}

void HLSLParserListener::PushNode( const char * name )
{
    lua_checkstack( State, 3 );
    lua_newtable( State );
    lua_pushstring( State, "name" );
    lua_pushstring( State, name );
    lua_rawset( State, -3 );
}

void HLSLParserListener::AddValue( const std::string & value )
{
    int
        index;

    lua_checkstack( State, 3 );

    assert( lua_istable( State, -1 ) );

    #if LUA_VERSION_NUM >= 502
        lua_len( State, -1 );
        index = lua_tointeger( State, -1 );
        lua_pop( State, 1 );
    #else
        index = lua_objlen( State, -1 );
    #endif

    lua_pushstring( State, value.c_str() );
    lua_rawseti( State, -2, index + 1 );
}

void HLSLParserListener::SetKeyValue( const std::string & key, const std::string & value )
{
    lua_checkstack( State, 3 );

    assert( lua_istable( State, -1 ) );
    lua_pushstring( State, key.c_str() );
    lua_pushstring( State, value.c_str() );
    lua_rawset( State, -3 );
}

void HLSLParserListener::Assign()
{
    int
        index;

    lua_checkstack( State, 3 );

    assert( lua_istable( State, -2) );

    #if LUA_VERSION_NUM >= 502
        lua_len( State, -2 );
        index = lua_tointeger( State, -1 );
        lua_pop( State, 1 );
    #else
        index = lua_objlen( State, -2 );
    #endif

    lua_rawseti( State, -2, index + 1 );
}

void HLSLParserListener::PopNode()
{
    lua_pop( State, 1 );
}

void HLSLParserListener::SwapTopNodes()
{
    lua_pushvalue(State, -2 );
    lua_remove(State, -3 );
}