#ifndef HLSLPARSERLISTENER
#define HLSLPARSERLISTENER

struct Parameter;
struct SamplerParameter;
#include <string>

extern "C"
{
    #include <lua.h>
}

class HLSLParserListener
{
public:

    HLSLParserListener( lua_State * state );
    
    void PushNode();
    void PushNode( const char * name );
    void AddValue( const std::string & value );
    void SetKeyValue( const std::string & key, const std::string & value );
    void Assign();
    void PopNode();
    
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

#endif