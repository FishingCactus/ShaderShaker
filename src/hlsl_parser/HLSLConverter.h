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
    
        void ConvertToShaderShakerLanguage(
            const std::string & filename
            );
            
        std::string GetConvertedCode() const
        {
            return "";
        }
            
            
        static int ConvertHLSLToSSL(
            lua_State * lua_state
            );
            
    private:
    
        HLSLParserListener
            Listener;
    
    };

#endif