#ifndef HLSLCONVERTER
#define HLSLCONVERTER

    extern "C" 
    {
        #include <lua.h>
    }
    
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