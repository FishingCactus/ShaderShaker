#ifndef HLSLCONVERTER
#define HLSLCONVERTER

    #if defined( SHADERSHAKER_FORCE_EXTERN_C ) || !defined( SHADERSHAKER_AS_SOURCE )
    extern "C"
    {
    #endif
        #include <lua.h>
    #if defined( SHADERSHAKER_FORCE_EXTERN_C ) || !defined( SHADERSHAKER_AS_SOURCE )
    }
    #endif

    #include <string>
    #include "HLSLParserListener.h"

    class HLSLConverter
    {
    public:
    
        HLSLConverter( lua_State * state ) : Listener( state )
        {
        
        }
    
        void LoadAst(
            const std::string & filename
            );
            
        static int ParseAst(
            lua_State * lua_state
            );
            
    private:
    
        HLSLParserListener
            Listener;
    
    };

#endif