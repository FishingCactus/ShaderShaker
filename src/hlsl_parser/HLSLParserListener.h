#ifndef HLSLPARSERLISTENER
#define HLSLPARSERLISTENER

struct Parameter;
struct SamplerParameter;
#include <string>
#include <lua.hpp>

class HLSLParserListener
{
public:

    HLSLParserListener( lua_State * state );

    void PushNode();
    void PushNode( const char * name );
    void PushNode( const std::string & name ){ PushNode( name.c_str() ); }
    void AddValue( const std::string & value );
    void SetKeyValue( const std::string & key, const std::string & value );
    void Assign();
    void PopNode();
    void SwapTopNodes();

private:

    lua_State
        * State;

};

#define ast_push(...) Listener->PushNode( __VA_ARGS__ )
#define ast_set( _key_, _value_ ) Listener->SetKeyValue( _key_, _value_ )
#define ast_setname( _value_ ) Listener->SetKeyValue( "name", _value_ )
#define ast_addvalue( _value_ ) Listener->AddValue( _value_ )
#define ast_assign()    Listener->Assign()
#define ast_pop()   Listener->PopNode()
#define ast_swap()   Listener->SwapTopNodes()

#endif